<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class OfflineSyncAndPosParityTest extends TestCase
{
    use DatabaseTransactions;

    public function test_cafe_pos_legacy_mobile_outbox_payload_syncs_and_updates_today_sales(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $token = $user->createToken('test-offline-sync')->plainTextToken;

        // 1. Check baseline sales_today for Aran Cafe (company_id = 1, branch_id = 1)
        $cafeHeaders = [
            'Authorization' => "Bearer {$token}",
            'X-Company-ID' => '1',
            'X-Branch-ID' => '1',
        ];
        $beforeFin = $this->getJson('/api/v1/mobile/financials', $cafeHeaders);

        $beforeFin->assertStatus(200);
        $beforeTodaySales = (float) ($beforeFin->json('data.sales_today') ?? 0);
        $beforeCash = (float) ($beforeFin->json('data.cash_balance') ?? 0);

        // 2. Simulate draining an old queued Cafe POS mutation from Windows SQLite Outbox
        // Notice: uses legacy mobile keys 'grand_total', 'payment_mode', 'order_items'
        $legacyOutboxPayload = [
            'grand_total' => 450.0,
            'payment_mode' => 'Cash',
            'order_items' => [
                ['item_id' => 1, 'qty' => 2, 'price' => 150.0],
                ['item_id' => 2, 'qty' => 1, 'price' => 150.0],
            ],
            'client_timestamp' => now()->toIso8601String(),
        ];

        $syncRes = $this->postJson('/api/v1/cafe/orders', $legacyOutboxPayload, $cafeHeaders + [
            'Idempotency-Key' => 'win-outbox-pos-001',
        ]);

        $syncRes->assertStatus(201);
        $syncRes->assertJsonPath('success', true);
        $saleId = $syncRes->json('data.sale_id');
        $this->assertNotNull($saleId);

        $this->assertDatabaseHas('sales', [
            'id' => $saleId,
            'company_id' => 1,
            'branch_id' => 1,
            'grand_total' => 450.0,
            'paid_amount' => 450.0,
        ]);

        // Also verify branch 2 explicit switch succeeds with aligned warehouse
        $this->postJson('/api/v1/cafe/orders', [
            'grand_total' => 150.0,
            'payment_mode' => 'UPI',
            'order_items' => [['item_id' => 1, 'qty' => 1, 'price' => 150.0]],
        ], [
            'Authorization' => "Bearer {$token}",
            'X-Company-ID' => '1',
            'X-Branch-ID' => '2',
        ])->assertStatus(201);

        // 3. Re-query financials & confirm Today's Sales and Cash in Hand GL reflect the newly synced POS bills
        $afterFin = $this->getJson('/api/v1/mobile/financials?sales_period=today', $cafeHeaders);

        $afterFin->assertStatus(200);
        $afterTodaySales = (float) $afterFin->json('data.sales_today');
        $afterCash = (float) $afterFin->json('data.cash_balance');
        $this->assertEqualsWithDelta($beforeTodaySales + 600.0, $afterTodaySales, 0.01);
        $this->assertEqualsWithDelta($beforeCash + 450.0, $afterCash, 0.01);
    }

    public function test_all_mobile_outbox_endpoints_accept_offline_payload_schemas(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $token = $user->createToken('test-all-outbox')->plainTextToken;
        $headers = [
            'Authorization' => "Bearer {$token}",
            'X-Company-ID' => '3',
        ];

        // 1. Water Can Delivery mobile schema
        $this->postJson('/api/v1/can-deliveries', [
            'customer_name' => 'Walk-in Office',
            'delivered_cans' => 10,
            'returned_empties' => 8,
            'price_per_can' => 35.0,
            'total_amount' => 350.0,
            'payment_mode' => 'Cash',
            'client_timestamp' => now()->toIso8601String(),
        ], $headers)->assertStatus(201);

        // 2. Tanker Trip Sheet mobile schema
        $this->postJson('/api/v1/trip-sheets', [
            'tanker_id' => 1,
            'customer_name' => 'Surya Dyeing Works',
            'water_quantity_litres' => 12000,
            'start_odometer' => 45200,
            'end_odometer' => 45235,
            'motor_pumping_charge' => 250.0,
            'waiting_charge' => 100.0,
            'total_trip_amount' => 2850.0,
            'client_timestamp' => now()->toIso8601String(),
        ], ['Authorization' => "Bearer {$token}", 'X-Company-ID' => '2'])->assertStatus(201);

        // 3. Payment collection with 'amount' key (using company 3 customer)
        $co3CustomerId = DB::table('customers')->where('company_id', 3)->orderBy('id')->value('id');
        $this->postJson('/api/v1/mobile/collect-payment', [
            'customer_id' => $co3CustomerId,
            'amount' => 500.0,
            'payment_mode' => 'UPI',
        ], $headers)->assertStatus(201);

        // Cross-company customer rejection guard (always exercised)
        $co2CustomerId = DB::table('customers')->where('company_id', 2)->orderBy('id')->value('id')
            ?? DB::table('customers')->insertGetId([
                'customer_group_id' => 1,
                'name' => 'Test Co2 Foreign Customer',
                'company_name' => 'Test Co2 Foreign Customer',
                'phone_number' => '9842100088',
                'address' => 'Erode',
                'city' => 'Erode',
                'opening_balance' => 0,
                'is_active' => 1,
                'company_id' => 2,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        $this->postJson('/api/v1/mobile/collect-payment', [
            'customer_id' => $co2CustomerId,
            'amount' => 100.0,
            'payment_mode' => 'Cash',
        ], $headers)->assertStatus(422);

        // 4. Quick Expense with 'category' string
        $this->postJson('/api/v1/expenses', [
            'category' => 'Fuel / Diesel',
            'amount' => 650.0,
            'note' => 'Van diesel refill',
        ], $headers)->assertStatus(201);

        // 5. Plant Intake with 'full_cans_loaded'
        $this->postJson('/api/v1/plant-intakes', [
            'vehicle_no' => 'TN-58-WA-101',
            'empty_cans_handed_over' => 40,
            'full_cans_loaded' => 40,
        ], $headers)->assertStatus(201);

        // 6. Spot Audit with 'physical_jars'
        $this->postJson('/api/v1/mobile/spot-audit', [
            'customer_name' => 'Muthu',
            'system_jars' => 60,
            'physical_jars' => 58,
            'remarks' => 'Checkpoint check',
        ], $headers)->assertStatus(201);

        // 7. Driver Surrender with 'net_cash_surrendered'
        $this->postJson('/api/v1/mobile/driver-surrender', [
            'net_cash_surrendered' => 1500.0,
            'notes' => 'Evening surrender',
        ], $headers)->assertStatus(200);

        // 8. Inventory Stock Count endpoints
        $this->postJson('/api/v1/inventory/stock-count', [
            'items' => [['id' => 1, 'counted' => 25]],
        ], $headers)->assertStatus(201);

        $this->postJson('/api/v1/inventory/stock-count', [
            'items' => [['id' => 1, 'counted' => 25]],
        ], ['Authorization' => "Bearer {$token}", 'X-Company-ID' => '1', 'X-Branch-ID' => '1'])->assertStatus(201);

        // 9. Simplified flat /sales bill with explicit branch context on multi-branch Co 1
        $this->postJson('/api/v1/sales', [
            'customer_name' => 'Counter Walkin',
            'item_name' => 'Filter Coffee',
            'qty' => 2,
            'unit_price' => 45.0,
            'grand_total' => 90.0,
            'paid_amount' => 90.0,
            'payment_mode' => 'UPI',
            'client_timestamp' => now()->toIso8601String(),
        ], ['Authorization' => "Bearer {$token}", 'X-Company-ID' => '1', 'X-Branch-ID' => '1'])->assertStatus(201);
    }

    public function test_cashier_with_single_authorized_branch_posts_cafe_pos_without_branch_header_and_blocks_cross_company(): void
    {
        $cashier = User::where('name', 'cashier')->first();
        if (!$cashier) {
            $this->markTestSkipped('Seeded cashier user not present.');
        }

        $cashierToken = $cashier->createToken('test-cashier-branch')->plainTextToken;
        $cashierRes = $this->postJson('/api/v1/cafe/orders', [
            'grand_total' => 120.0,
            'payment_mode' => 'Cash',
            'order_items' => [['item_id' => 1, 'qty' => 1, 'price' => 120.0]],
        ], ['Authorization' => "Bearer {$cashierToken}", 'X-Company-ID' => '1']);

        $cashierRes->assertStatus(201);
        $this->assertDatabaseHas('sales', [
            'id' => $cashierRes->json('data.sale_id'),
            'user_id' => $cashier->id,
            'company_id' => 1,
            'branch_id' => 2,
        ]);

        $this->postJson('/api/v1/cafe/orders', [
            'grand_total' => 120.0,
            'payment_mode' => 'Cash',
        ], ['Authorization' => "Bearer {$cashierToken}", 'X-Company-ID' => '2'])->assertStatus(403);
    }
}
