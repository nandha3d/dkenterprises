<?php

namespace Tests\Feature;

use App\Models\CashRegister;
use App\Models\Customer;
use App\Models\Accounting\JournalEntry;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Product_Sale;
use App\Models\Returns;
use App\Models\Sale;
use App\Models\Table;
use App\Models\User;
use App\Models\Warehouse;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PosApiTest extends TestCase
{
    use DatabaseTransactions;

    private function authAsCompanyOneCashier(): array
    {
        $user = User::find(5) ?? User::find(1);
        Sanctum::actingAs($user, ['*']);

        return [
            'Accept' => 'application/json',
            'X-Company-ID' => '1',
        ];
    }

    public function test_pos_bootstrap_returns_company_catalog_and_tables(): void
    {
        $headers = $this->authAsCompanyOneCashier();
        $table = Table::create([
            'name' => 'Patio Test T-99',
            'number_of_person' => 4,
            'description' => 'Window booth',
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/v1/pos/bootstrap', $headers);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.company_id', 1)
            ->assertJsonPath('data.shift', null)
            ->assertJsonFragment(['name' => $table->name, 'status' => 'available']);
    }

    public function test_pos_bootstrap_strictly_isolates_companies_and_hides_tables_for_water_company(): void
    {
        $admin = User::find(1);
        Sanctum::actingAs($admin, ['*']);

        $response = $this->getJson('/api/v1/pos/bootstrap', [
            'Accept' => 'application/json',
            'X-Company-ID' => '2',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.company_id', 2)
            ->assertJsonPath('data.pos_setting.is_table', false)
            ->assertJsonCount(0, 'data.tables');

        $productIds = collect($response->json('data.products'))->pluck('id')->all();
        $foreignProducts = Product::whereIn('id', $productIds)
            ->where(fn ($q) => $q->whereNull('company_id')->orWhere('company_id', '!=', 2))
            ->count();
        $this->assertSame(0, $foreignProducts);
    }

    public function test_full_erp_pos_shift_hold_resume_split_payment_refund_and_z_report_lifecycle(): void
    {
        $headers = $this->authAsCompanyOneCashier();
        $warehouse = Warehouse::where('company_id', 1)->where('branch_id', 2)->where('is_active', true)->firstOrFail();
        $customer = Customer::withoutGlobalScopes()
            ->where('is_active', true)
            ->where(fn ($q) => $q->where('company_id', 1)->orWhereNull('company_id'))
            ->firstOrFail();

        $product = Product::where('company_id', 1)->where('is_active', true)->firstOrFail();
        $initialWarehouseQty = (float) DB::table('product_warehouse')
            ->where('warehouse_id', $warehouse->id)
            ->where('product_id', $product->id)
            ->sum('qty');
        if ($initialWarehouseQty < 5) {
            DB::table('product_warehouse')->updateOrInsert(
                ['product_id' => $product->id, 'warehouse_id' => $warehouse->id],
                ['qty' => 25, 'created_at' => now(), 'updated_at' => now()]
            );
            $initialWarehouseQty = (float) DB::table('product_warehouse')
                ->where('warehouse_id', $warehouse->id)
                ->where('product_id', $product->id)
                ->sum('qty');
        }

        $table = Table::create([
            'name' => 'Booth B-12',
            'number_of_person' => 2,
            'is_active' => true,
        ]);

        // 1. Open CashRegister shift & reject duplicate open shift
        $openRes = $this->postJson('/api/v1/pos/shifts/open', [
            'cash_in_hand' => 1000.00,
            'warehouse_id' => $warehouse->id,
        ], $headers);
        $openRes->assertStatus(201)
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.cash_in_hand', 1000);

        $registerId = $openRes->json('data.id');

        $dupRes = $this->postJson('/api/v1/pos/shifts/open', [
            'cash_in_hand' => 500.00,
            'warehouse_id' => $warehouse->id,
        ], $headers);
        $dupRes->assertStatus(422);

        // 2. Hold dine-in ticket on Table -> table becomes occupied, stock unchanged
        $holdRes = $this->postJson('/api/v1/pos/orders', [
            'status' => 'held',
            'order_type' => 'dine_in',
            'warehouse_id' => $warehouse->id,
            'customer_id' => $customer->id,
            'table_id' => $table->id,
            'cash_register_id' => $registerId,
            'items' => [
                [
                    'product_id' => $product->id,
                    'qty' => 2,
                    'unit_price' => 150.00,
                    'tax_rate' => 0,
                ],
            ],
        ], $headers);

        $this->assertSame(201, $holdRes->status(), json_encode($holdRes->json()));
        $holdRes->assertJsonPath('data.sale_status', 3)
            ->assertJsonPath('data.sale_status_label', 'held')
            ->assertJsonPath('data.table_id', $table->id);

        $heldId = $holdRes->json('data.id');

        $this->getJson('/api/v1/pos/tables', $headers)
            ->assertOk()
            ->assertJsonFragment([
                'id' => $table->id,
                'status' => 'occupied',
                'held_sale_id' => $heldId,
            ]);

        $qtyAfterHold = (float) DB::table('product_warehouse')
            ->where('warehouse_id', $warehouse->id)
            ->where('product_id', $product->id)
            ->sum('qty');
        $this->assertEqualsWithDelta($initialWarehouseQty, $qtyAfterHold, 0.001);

        // 3. Resume held ticket with split payment (Cash 180 + UPI 120 = 300)
        $resumeRes = $this->postJson("/api/v1/pos/orders/{$heldId}/resume", [
            'status' => 'completed',
            'order_type' => 'dine_in',
            'payments' => [
                ['method' => 'Cash', 'amount' => 180.00],
                ['method' => 'UPI', 'amount' => 120.00],
            ],
        ], $headers);

        $this->assertSame(200, $resumeRes->status(), json_encode($resumeRes->json()));
        $resumeRes->assertJsonPath('data.sale_status', 1)
            ->assertJsonPath('data.payment_status', 4)
            ->assertJsonPath('data.grand_total', 300)
            ->assertJsonPath('data.paid_amount', 300)
            ->assertJsonPath('data.cash_register_id', $registerId);

        // Table should be released once finalized
        $this->getJson('/api/v1/pos/tables', $headers)
            ->assertOk()
            ->assertJsonFragment([
                'id' => $table->id,
                'status' => 'available',
                'held_sale_id' => null,
            ]);

        // Payment rows stamped with cash_register_id
        $payments = Payment::where('sale_id', $heldId)->orderBy('id')->get();
        $this->assertCount(2, $payments);
        $this->assertEquals(180.0, (float) $payments[0]->amount);
        $this->assertEquals('Cash', $payments[0]->paying_method);
        $this->assertEquals($registerId, (int) $payments[0]->cash_register_id);
        $this->assertEquals(120.0, (float) $payments[1]->amount);
        $this->assertEquals('UPI', $payments[1]->paying_method);

        // Stock deducted in product_warehouse
        if (($product->type ?? 'standard') === 'standard') {
            $qtyAfterSale = (float) DB::table('product_warehouse')
                ->where('warehouse_id', $warehouse->id)
                ->where('product_id', $product->id)
                ->sum('qty');
            $this->assertEqualsWithDelta($initialWarehouseQty - 2, $qtyAfterSale, 0.001);
        }

        // Balanced GL Journal Entry posted for the sale
        $saleJournal = JournalEntry::where('reference_type', 'sale')
            ->where('reference_id', $heldId)
            ->first();
        $this->assertNotNull($saleJournal);
        $this->assertEqualsWithDelta((float) $saleJournal->total_debit, (float) $saleJournal->total_credit, 0.01);

        // 4. Partial cash refund (qty = 1 -> Rs 150) & restock
        $refundRes = $this->postJson("/api/v1/pos/orders/{$heldId}/refund", [
            'refund_method' => 'Cash',
            'restock' => true,
            'reason' => 'Customer changed order quantity',
            'cash_register_id' => $registerId,
            'items' => [
                ['product_id' => $product->id, 'qty' => 1],
            ],
        ], $headers);

        $refundRes->assertStatus(201)
            ->assertJsonPath('data.sale_id', $heldId)
            ->assertJsonPath('data.grand_total', 150)
            ->assertJsonPath('data.refund_method', 'Cash');

        $returnId = $refundRes->json('data.return_id');
        $this->assertDatabaseHas('returns', [
            'id' => $returnId,
            'sale_id' => $heldId,
            'cash_register_id' => $registerId,
            'note_type' => 'credit_note',
        ]);

        if (($product->type ?? 'standard') === 'standard') {
            $qtyAfterRefund = (float) DB::table('product_warehouse')
                ->where('warehouse_id', $warehouse->id)
                ->where('product_id', $product->id)
                ->sum('qty');
            $this->assertEqualsWithDelta($initialWarehouseQty - 1, $qtyAfterRefund, 0.001);
        }

        // 5. Verify live X-report on currentShift: cash_in_hand 1000 + cash 180 - return 150 = 1030
        $shiftRes = $this->getJson('/api/v1/pos/shifts/current', $headers);
        $shiftRes->assertOk()
            ->assertJsonPath('data.has_open_shift', true)
            ->assertJsonPath('data.shift.cash_payment', 180)
            ->assertJsonPath('data.shift.upi_payment', 120)
            ->assertJsonPath('data.shift.total_sale_return', 150)
            ->assertJsonPath('data.shift.expected_cash', 1030);

        // 6. Close shift with counted cash = 1020 -> Z-report variance = -10
        $closeRes = $this->postJson('/api/v1/pos/shifts/close', [
            'cash_register_id' => $registerId,
            'actual_cash' => 1020.00,
            'note' => 'Short by Rs 10 loose change',
        ], $headers);

        $closeRes->assertOk()
            ->assertJsonPath('data.status', 'closed')
            ->assertJsonPath('data.expected_cash', 1030)
            ->assertJsonPath('data.actual_cash', 1020)
            ->assertJsonPath('data.variance', -10);

        $this->assertDatabaseHas('cash_registers', [
            'id' => $registerId,
            'status' => 0,
            'closing_balance' => 1030.00,
            'actual_cash' => 1020.00,
        ]);
    }

    public function test_cancel_held_draft_and_reject_cross_company_access(): void
    {
        $headers = $this->authAsCompanyOneCashier();
        $warehouse = Warehouse::where('company_id', 1)->where('branch_id', 2)->where('is_active', true)->firstOrFail();
        $customer = Customer::withoutGlobalScopes()
            ->where('is_active', true)
            ->where(fn ($q) => $q->where('company_id', 1)->orWhereNull('company_id'))
            ->firstOrFail();
        $product = Product::where('company_id', 1)->where('is_active', true)->firstOrFail();

        $holdRes = $this->postJson('/api/v1/pos/orders', [
            'status' => 'held',
            'warehouse_id' => $warehouse->id,
            'customer_id' => $customer->id,
            'items' => [['product_id' => $product->id, 'qty' => 1, 'unit_price' => 90]],
        ], $headers);
        $this->assertSame(201, $holdRes->status(), json_encode($holdRes->json()));
        $heldId = $holdRes->json('data.id');

        $this->deleteJson("/api/v1/pos/orders/{$heldId}/held", [], $headers)
            ->assertOk();

        $this->assertNull(Sale::find($heldId));

        // Company-1-only cashier requesting Company 3 (DK Waters) must be blocked by company.context
        $this->getJson('/api/v1/pos/bootstrap', [
            'Accept' => 'application/json',
            'X-Company-ID' => '3',
        ])->assertStatus(403);
    }
}
