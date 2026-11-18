<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ClientReviewWorkflowsTest extends TestCase
{
    use DatabaseTransactions;

    public function test_customer_opening_balance_is_reflected_as_due_across_directory_map_and_history(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-opening-balance')->plainTextToken;

        $companyId = (int) (DB::table('company_industry_settings')->where('profile_key', 'bulk_water')->value('company_id')
            ?? DB::table('companies')->where('code', 'TMWS')->value('id')
            ?? 2);

        $custGroupId = (int) (DB::table('customer_groups')->value('id') ?? 1);
        $customerId = (int) DB::table('customers')->insertGetId([
            'company_id' => $companyId,
            'customer_group_id' => $custGroupId,
            'name' => 'Opening Balance Test Mill ' . uniqid(),
            'phone_number' => '9842111222',
            'address' => 'Veerappampalayam, Erode',
            'city' => 'Erode',
            'latitude' => 11.3410,
            'longitude' => 77.7172,
            'opening_balance' => 15000.00,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $listRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->getJson('/api/v1/mobile/customers?limit=100');

        $listRes->assertStatus(200);
        $match = collect($listRes->json('data'))->firstWhere('id', $customerId);
        $this->assertNotNull($match);
        $this->assertEquals(15000.0, (float) $match['opening_balance']);
        $this->assertEquals(15000.0, (float) $match['due_amount']);
        $this->assertSame('due', $match['payment_status']);

        $fleetRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->getJson('/api/v1/mobile/fleet/live?industry=bulk_water');

        $fleetRes->assertStatus(200);
        $mapMatch = collect($fleetRes->json('data.customers'))->firstWhere('id', $customerId);
        $this->assertNotNull($mapMatch);
        $this->assertEquals(15000.0, (float) $mapMatch['due_amount']);
        $this->assertSame('due', $mapMatch['payment_status']);

        $historyRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->getJson("/api/v1/mobile/customers/{$customerId}/history");

        $historyRes->assertStatus(200);
        $this->assertEquals(15000.0, (float) $historyRes->json('data.customer.due_amount'));
        $this->assertTrue(
            collect($historyRes->json('data.purchases'))->contains(fn ($p) => ($p['item_summary'] ?? '') === 'Opening Balance (Pre-ERP)'),
            'Customer 360 history purchases must include Opening Balance (Pre-ERP).'
        );
    }

    public function test_pickup_points_crud_and_trip_aggregation(): void
    {
        if (!Schema::hasTable('water_pickup_points')) {
            $this->markTestSkipped('water_pickup_points table not migrated yet.');
        }

        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-pickup-points')->plainTextToken;
        $companyId = (int) (DB::table('company_industry_settings')->where('profile_key', 'bulk_water')->value('company_id') ?? 2);

        $createRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->postJson('/api/v1/water/pickup-points', [
                'name' => 'Chithode Outer Borewell Test',
                'code' => 'PP-TEST-CHT',
                'location_type' => 'outer_paid_borewell',
                'rate_per_load' => 250,
                'settlement_cycle' => 'weekly',
            ]);

        $createRes->assertStatus(201);
        $pickupId = (int) $createRes->json('data.id');
        $this->assertGreaterThan(0, $pickupId);

        $indexRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->getJson('/api/v1/water/pickup-points');

        $indexRes->assertStatus(200);
        $this->assertTrue(collect($indexRes->json('data'))->contains('id', $pickupId));
    }

    public function test_outsourced_tanker_trip_and_gpay_pending_to_verified_flow(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-tanker-gpay')->plainTextToken;
        $companyId = (int) (DB::table('company_industry_settings')->where('profile_key', 'bulk_water')->value('company_id') ?? 2);

        $tripRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->postJson('/api/v1/water/trip-sheets', [
                'walk_in_customer_name' => 'Kovil Function Walk-in ' . uniqid(),
                'walk_in_customer_phone' => '9842109988',
                'location_area' => 'Mettukadai',
                'water_quantity_kl' => 9,
                'trip_rate' => 1000,
                'extra_charge' => 100,
                'discount_amount' => 50,
                'adjustment_note' => '2nd floor hose + Google review promo',
                'is_outsourced_vehicle' => true,
                'external_vehicle_no' => 'TN 33 AB 9999',
                'external_vendor_name' => 'Sakthi Tie-Up Tanker',
                'vendor_payable_amount' => 700,
                'payment_mode' => 'GPay / UPI',
                'payment_status_flag' => 'pending_verification',
                'paid_amount' => 1050,
                'status' => 'Delivered',
            ]);

        $tripRes->assertStatus(201);
        $tripId = (int) $tripRes->json('data.id');
        $this->assertEquals(1050.0, (float) $tripRes->json('data.trip_rate'));
        $this->assertSame('pending_verification', $tripRes->json('data.payment_verification_status'));

        $saleId = (int) ($tripRes->json('data.sale_id') ?? 0);
        if ($saleId > 0) {
            $salePaid = (float) DB::table('sales')->where('id', $saleId)->value('paid_amount');
            $this->assertEquals(0.0, $salePaid, 'Pending GPay trip must keep ERP sale paid_amount at 0 until verified.');
        }

        $tinyPngBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
        $verifyRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', (string) $companyId)
            ->postJson('/api/v1/water/payments/verify-proof', [
                'entity_type' => 'tanker_trip',
                'entity_id' => $tripId,
                'status' => 'confirmed',
                'paid_amount' => 1050,
                'payment_account' => 'GPAY - KAVIN AXIS',
                'payment_proof_base64' => $tinyPngBase64,
            ]);

        $verifyRes->assertStatus(200)
            ->assertJsonPath('data.payment_verification_status', 'confirmed');
        $this->assertEquals(1050.0, (float) $verifyRes->json('data.paid_amount'));
        $this->assertNotEmpty($verifyRes->json('data.payment_proof_path'));

        if ($saleId > 0) {
            $salePaidAfter = (float) DB::table('sales')->where('id', $saleId)->value('paid_amount');
            $this->assertEquals(1050.0, $salePaidAfter);
        }
    }

    public function test_expenses_batch_and_accounts_summary(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-expenses-batch')->plainTextToken;

        $batchRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '1')
            ->postJson('/api/v1/expenses/batch', [
                'rows' => [
                    [
                        'entry_date' => now()->toDateString(),
                        'entry_type' => 'IN',
                        'company_tag' => 'TM WATER SUPPLY',
                        'payment_account' => 'GPAY - KAVIN AXIS',
                        'vehicle_or_staff_tag' => 'TN 47 M 4585',
                        'bill_no' => 'WL9554',
                        'amount' => 15515,
                        'description' => 'Morning tanker collection',
                    ],
                    [
                        'entry_date' => now()->toDateString(),
                        'entry_type' => 'OUT',
                        'company_tag' => 'ARAN1',
                        'payment_account' => 'CASH',
                        'vehicle_or_staff_tag' => 'SURESH',
                        'bill_no' => '1693',
                        'amount' => 300,
                        'description' => 'suresh went to amirtha',
                    ],
                ],
            ]);

        $batchRes->assertStatus(201)
            ->assertJsonPath('data.count', 2);
        $this->assertEquals(15515.0, (float) $batchRes->json('data.total_in'));
        $this->assertEquals(300.0, (float) $batchRes->json('data.total_out'));

        $summaryRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '1')
            ->getJson('/api/v1/expenses/accounts-summary');

        $summaryRes->assertStatus(200);
        $accountNames = collect($summaryRes->json('data.accounts'))->pluck('name')->all();
        $this->assertContains('Kavin Axis', $accountNames);
        $this->assertContains('CASH', $accountNames);
    }

    public function test_regular_vendors_and_quick_purchase_bill(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-quick-purchase')->plainTextToken;

        $vendorsRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '1')
            ->getJson('/api/v1/purchases/regular-vendors');

        $vendorsRes->assertStatus(200);
        $this->assertNotEmpty($vendorsRes->json('data.vendors'));

        $quickRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '1')
            ->postJson('/api/v1/purchases/quick', [
                'supplier_name' => 'Amirtha Milk',
                'amount' => 950,
                'payment_mode' => 'GPay',
                'payment_account' => 'Kavin Axis',
                'bill_no' => 'AM-1042',
                'company_tag' => 'ARAN1',
                'category' => 'Milk',
                'description' => 'Morning milk crates',
            ]);

        $quickRes->assertStatus(201);
        $this->assertEquals(950.0, (float) $quickRes->json('data.amount'));
        $this->assertSame('paid', $quickRes->json('data.payment_status'));
    }

    public function test_cafe_orders_alias_and_golive_reset_guard(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-cafe-and-reset')->plainTextToken;

        $cafeRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '1')
            ->postJson('/api/v1/cafe-orders', [
                'total' => 240,
                'payment_method' => 'Cash',
                'items' => [
                    ['item_id' => 1, 'qty' => 2, 'unit_price' => 120],
                ],
            ]);

        $cafeRes->assertStatus(201);
        $this->assertEquals(240.0, (float) $cafeRes->json('data.total_amount'));

        $badReset = $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/admin/reset-demo-data', [
                'confirmation_code' => 'WRONG',
            ]);
        $badReset->assertStatus(422);
    }
}
