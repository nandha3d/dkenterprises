<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Leave;
use App\Models\Product;
use App\Models\Supplier;
use App\Models\User;
use App\Models\Warehouse;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ErpSecurityAndGapsTest extends TestCase
{
    use DatabaseTransactions;

    private function authAsAdmin(int $companyId = 1): array
    {
        $admin = User::find(1);
        Sanctum::actingAs($admin, ['*']);

        return [
            'Accept' => 'application/json',
            'X-Company-ID' => (string) $companyId,
        ];
    }

    public function test_c08_c34_c32_c33_c36_c06_pos_kds_availability_production_wastage_reorder_and_print_job(): void
    {
        $headers = $this->authAsAdmin(1);
        $product = Product::where('company_id', 1)->where('is_active', true)->firstOrFail();
        $warehouse = Warehouse::where('company_id', 1)->where('is_active', true)->firstOrFail();

        // 1. Create a held POS order so it appears in KDS
        $orderRes = $this->postJson('/api/v1/pos/orders', [
            'status' => 'held',
            'order_type' => 'dine_in',
            'warehouse_id' => $warehouse->id,
            'items' => [
                ['product_id' => $product->id, 'qty' => 2, 'unit_price' => (float) $product->price],
            ],
        ], $headers);
        $orderRes->assertCreated();
        $saleId = (int) $orderRes->json('data.id');

        // 2. C-08: KDS feed & status bump lifecycle
        $kdsRes = $this->getJson('/api/v1/pos/kds', $headers);
        $kdsRes->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonFragment(['id' => $saleId, 'kds_status' => 'new']);

        $bumpRes = $this->postJson("/api/v1/pos/kds/{$saleId}/status", [
            'status' => 'preparing',
            'note' => 'Fired on espresso station',
        ], $headers);
        $bumpRes->assertOk()
            ->assertJsonPath('data.kds_status', 'preparing');

        // 3. C-34: Toggle product 86 availability off & back on
        $toggleOff = $this->patchJson("/api/v1/pos/products/{$product->id}/availability", [
            'is_available' => false,
            'reason' => 'Sold out for morning batch',
        ], $headers);
        $toggleOff->assertOk()
            ->assertJsonPath('data.is_available', false);

        $toggleOn = $this->patchJson("/api/v1/pos/products/{$product->id}/availability", [
            'is_available' => true,
        ], $headers);
        $toggleOn->assertOk()
            ->assertJsonPath('data.is_available', true);

        // 4. C-32: Production batch increments stock
        $beforeQty = (float) ($product->fresh()->qty ?? 0);
        $prodBatch = $this->postJson('/api/v1/pos/production-batches', [
            'warehouse_id' => $warehouse->id,
            'product_id' => $product->id,
            'qty' => 15,
            'note' => 'Morning oven bake #1',
        ], $headers);
        $prodBatch->assertCreated()
            ->assertJsonPath('data.total_qty', 15);
        $this->assertEqualsWithDelta($beforeQty + 15.0, (float) $product->fresh()->qty, 0.01);

        // 5. C-33: Wastage deducts stock
        $wastageRes = $this->postJson('/api/v1/pos/wastage', [
            'warehouse_id' => $warehouse->id,
            'product_id' => $product->id,
            'qty' => 3,
            'reason' => 'Tray drop spoilage',
        ], $headers);
        $wastageRes->assertCreated()
            ->assertJsonPath('data.total_qty', 3);
        $this->assertEqualsWithDelta($beforeQty + 12.0, (float) $product->fresh()->qty, 0.01);

        // 6. C-36: Kitchen Reorder Request create & list
        $reorderCreate = $this->postJson('/api/v1/pos/reorder-requests', [
            'warehouse_id' => $warehouse->id,
            'product_id' => $product->id,
            'qty' => 50,
            'note' => 'Urgent flour & milk restock',
        ], $headers);
        $reorderCreate->assertCreated()
            ->assertJsonPath('data.status', 'pending_po');

        $reorderList = $this->getJson('/api/v1/pos/reorder-requests', $headers);
        $reorderList->assertOk()
            ->assertJsonPath('success', true);

        // 7. C-06 / D-04: Thermal print job payload
        $printRes = $this->postJson("/api/v1/pos/orders/{$saleId}/print-job", [
            'paper_width' => '80mm',
        ], $headers);
        $printRes->assertOk()
            ->assertJsonPath('data.sale_id', $saleId)
            ->assertJsonPath('data.print_count', 1);
        $this->assertNotEmpty($printRes->json('data.receipt_lines'));
    }

    public function test_a14_f03_a33_quotations_convert_credit_limit_and_supplier_payment(): void
    {
        $headers = $this->authAsAdmin(1);
        $product = Product::where('company_id', 1)->where('is_active', true)->firstOrFail();
        $customer = Customer::withoutGlobalScopes()
            ->where('company_id', 1)
            ->where('is_active', true)
            ->first();
        if (!$customer) {
            $customer = Customer::create([
                'customer_group_id' => 1,
                'name' => 'Aran Corporate Client',
                'phone_number' => '9842199999',
                'address' => 'Erode',
                'city' => 'Erode',
                'company_id' => 1,
                'is_active' => true,
            ]);
        }

        // 1. A-14: Create quotation, list it, and convert to commercial sale
        $createQt = $this->postJson('/api/v1/quotations', [
            'customer_id' => $customer->id,
            'product_id' => $product->id,
            'qty' => 10,
            'unit_price' => 45,
            'note' => 'Corporate catering estimate',
        ], $headers);
        $createQt->assertCreated()
            ->assertJsonPath('data.grand_total', 450);
        $quotationId = (int) $createQt->json('data.id');

        $listQt = $this->getJson('/api/v1/quotations', $headers);
        $listQt->assertOk()
            ->assertJsonFragment(['id' => $quotationId]);

        $convertQt = $this->postJson("/api/v1/quotations/{$quotationId}/convert", [], $headers);
        $convertQt->assertCreated()
            ->assertJsonPath('data.quotation_id', $quotationId);
        $this->assertGreaterThan(0, (int) $convertQt->json('data.sale_id'));

        // 2. F-03: Customer credit limit override
        $creditRes = $this->postJson("/api/v1/customers/{$customer->id}/credit-limit", [
            'credit_limit' => 25000,
            'credit_days' => 30,
        ], $headers);
        $creditRes->assertOk()
            ->assertJsonPath('data.credit_limit', 25000)
            ->assertJsonPath('data.credit_days', 30);

        // 3. A-33: Direct supplier payment voucher
        $supplier = Supplier::withoutGlobalScopes()
            ->where('company_id', 1)
            ->where('is_active', true)
            ->first();
        if (!$supplier) {
            $supplier = new Supplier([
                'name' => 'Dairy & Coffee Beans Vendor',
                'company_name' => 'Dairy & Coffee Beans Vendor',
                'phone_number' => '9842188888',
                'address' => 'Erode',
                'city' => 'Erode',
                'is_active' => true,
            ]);
            $supplier->company_id = 1;
            $supplier->save();
        }

        $payRes = $this->postJson("/api/v1/suppliers/{$supplier->id}/pay", [
            'amount' => 1200,
            'paying_method' => 'UPI',
            'note' => 'Weekly milk & coffee beans settlement',
        ], $headers);
        $payRes->assertCreated()
            ->assertJsonPath('data.supplier_id', $supplier->id)
            ->assertJsonPath('data.amount_paid', 1200);
    }

    public function test_a41_g04_t12_hrm_leave_approval_notifications_and_tanker_trip_trail(): void
    {
        $headers = $this->authAsAdmin(2);

        // 1. A-41: Apply leave & approve/reject
        $applyRes = $this->postJson('/api/v1/hrm/leaves', [
            'leave_types' => 'Casual Leave',
            'start_date' => now()->addDays(1)->toDateString(),
            'end_date' => now()->addDays(2)->toDateString(),
            'reason' => 'Family function',
        ], $headers);
        $applyRes->assertCreated();
        $leaveId = (int) $applyRes->json('data.id');

        $approveRes = $this->postJson("/api/v1/hrm/leaves/{$leaveId}/approve", [], $headers);
        $approveRes->assertOk()
            ->assertJsonPath('data.status', 1)
            ->assertJsonPath('data.status_label', 'Approved');

        // 2. G-04: Notifications feed, mark read, and push token registration
        $notifRes = $this->getJson('/api/v1/notifications', $headers);
        $notifRes->assertOk()
            ->assertJsonPath('success', true);

        $readRes = $this->postJson('/api/v1/notifications/low_stock_2/read', [], $headers);
        $readRes->assertOk()
            ->assertJsonPath('data.is_read', true);

        $pushRes = $this->postJson('/api/v1/devices/push-token', [
            'token' => 'fcm_test_device_token_123456',
            'platform' => 'android',
        ], $headers);
        $pushRes->assertOk()
            ->assertJsonPath('data.registered', true);

        // 3. T-12: Tanker trips list & GPS trail
        $tripCreate = $this->postJson('/api/v1/water/trip-sheets', [
            'tanker_id' => 1,
            'source_plant' => 'Main Borewell Station',
            'destination_site' => 'Texvalley Industrial Sump',
            'water_quantity_kl' => 12,
            'trip_rate' => 2400,
            'start_km' => 45100,
            'end_km' => 45128,
        ], $headers);
        $tripCreate->assertCreated();
        $tripId = (int) $tripCreate->json('data.id');

        $tripsList = $this->getJson('/api/v1/water/trips', $headers);
        $tripsList->assertOk()
            ->assertJsonFragment(['id' => $tripId]);

        $trailRes = $this->getJson("/api/v1/water/trips/{$tripId}/trail", $headers);
        $trailRes->assertOk()
            ->assertJsonPath('data.trip_id', $tripId)
            ->assertJsonCount(4, 'data.breadcrumbs');
    }

    public function test_security_tenant_isolation_blocks_cross_company_customer_ledger_and_location_idor(): void
    {
        $headersCompanyOne = $this->authAsAdmin(1);

        // Create or pick a customer belonging to Company 3 (DK Waters)
        $companyThreeCustomerId = (int) DB::table('customers')->insertGetId([
            'customer_group_id' => 1,
            'name' => 'DK Waters Exclusive Stop',
            'phone_number' => '9842177777',
            'address' => 'Perundurai',
            'city' => 'Erode',
            'company_id' => 3,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Attempting to read Company 3 customer's ledger while scoped to Company 1 must return 404
        $ledgerRes = $this->getJson("/api/v1/reports/customers/{$companyThreeCustomerId}/ledger", $headersCompanyOne);
        $ledgerRes->assertNotFound();

        // Attempting to overwrite Company 3 customer's GPS coordinates while scoped to Company 1 must return 404
        $locRes = $this->postJson("/api/v1/mobile/customers/{$companyThreeCustomerId}/location", [
            'latitude' => 11.3410,
            'longitude' => 77.7172,
        ], $headersCompanyOne);
        $locRes->assertNotFound();
    }

    public function test_geofenced_attendance_status_checkin_checkout_and_web_cafe_pos_parity(): void
    {
        $headers = $this->authAsAdmin(1);

        // 1. D-14 / T-09 / C-42: Geofenced Attendance Status & Haversine Distance
        $statusRes = $this->getJson('/api/v1/hrm/attendance/status?latitude=11.3412&longitude=77.7173', $headers);
        $statusRes->assertOk()
            ->assertJsonPath('data.geofence.radius_meters', 150)
            ->assertJsonPath('data.current_location.within_geofence', true)
            ->assertJsonCount(5, 'data.weekly_hours');

        // 2. Check-In inside plant geofence
        $inRes = $this->postJson('/api/v1/hrm/attendance/check-in', [
            'latitude' => 11.3412,
            'longitude' => 77.7173,
            'odometer_km' => 48215,
            'biometric_verified' => true,
            'note' => 'Morning shift check-in verified',
        ], $headers);
        $inRes->assertStatus(201)
            ->assertJsonPath('data.within_geofence', true);

        // 3. Check-Out
        $outRes = $this->postJson('/api/v1/hrm/attendance/check-out', [
            'latitude' => 11.3412,
            'longitude' => 77.7173,
            'odometer_km' => 48290,
            'note' => 'Shift completed',
        ], $headers);
        $outRes->assertOk()
            ->assertJsonPath('data.within_geofence', true);

        // 4. Web Cafe POS storeOrder (/cafe/orders) posts real ERP Sale & Payment
        $admin = User::find(1);
        $warehouse = Warehouse::where('company_id', 1)->where('is_active', true)->firstOrFail();
        $product = Product::where('company_id', 1)->where('is_active', true)->firstOrFail();

        $webPosRes = $this->actingAs($admin)
            ->withSession([
                'company_id' => 1,
                'branch_id' => $warehouse->branch_id ?? 1,
            ])
            ->postJson('/cafe/orders', [
                'warehouse_id' => $warehouse->id,
                'order_type' => 'dine_in',
                'status' => 'held',
                'items' => [
                    [
                        'product_id' => $product->id,
                        'qty' => 2,
                        'unit_price' => 45.0,
                    ],
                ],
            ], $headers);
        $webPosRes->assertStatus(201)
            ->assertJsonPath('data.grand_total', 90);
    }
}

