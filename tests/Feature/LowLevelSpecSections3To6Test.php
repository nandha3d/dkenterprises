<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class LowLevelSpecSections3To6Test extends TestCase
{
    use DatabaseTransactions;

    private function actingHeaders(int $companyId, ?int $branchId = null): array
    {
        $resolvedBranch = $branchId ?? (int) (\App\Models\Company::find($companyId)?->branches()->orderBy('id')->value('id') ?? 1);
        return [
            'X-Company-ID' => (string) $companyId,
            'X-Branch-ID' => (string) $resolvedBranch,
            'Accept' => 'application/json',
        ];
    }

    public function test_section_3_sensible_pos_price_tiers_fractional_qty_packing_roundoff_and_credit_limit(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $cafeHeaders = $this->actingHeaders(1);

        // 1. Verify bootstrap includes price_tiers and customer credit metadata
        $boot = $this->actingAs($user, 'sanctum')->getJson('/api/v1/pos/bootstrap', $cafeHeaders);
        $boot->assertStatus(200)
            ->assertJsonPath('success', true);
        $tiers = collect($boot->json('data.price_tiers'))->pluck('multiplier', 'code');
        $this->assertEqualsWithDelta(0.88, (float) ($tiers['Wholesale'] ?? 0), 0.001);
        $this->assertEqualsWithDelta(1.0, (float) ($tiers['Retail MRP'] ?? 0), 0.001);

        $productId = (int) (DB::table('products')->where('company_id', 1)->value('id') ?? 1);
        $warehouseId = (int) (DB::table('warehouses')->where('company_id', 1)->orderBy('id')->value('id') ?? 1);
        $custGroupId = (int) (DB::table('customer_groups')->orderBy('id')->value('id') ?? 1);

        // Create a test credit-limited customer in Aran Cafe with ₹500 credit limit
        $limitedCustomerId = DB::table('customers')->insertGetId([
            'company_id' => 1,
            'customer_group_id' => $custGroupId,
            'name' => 'Test Credit Capped Diner',
            'phone_number' => '9842188881',
            'credit_limit' => 500.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Credit bill exceeding ₹500 credit limit must be blocked (422)
        $blockedRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/pos/orders', [
            'warehouse_id' => $warehouseId,
            'customer_id' => $limitedCustomerId,
            'order_type' => 'takeaway',
            'price_tier' => 'Retail MRP',
            'items' => [
                ['product_id' => $productId, 'qty' => 25, 'unit_price' => 30.00],
            ],
            'payments' => [],
        ], $cafeHeaders);
        $blockedRes->assertStatus(422)
            ->assertJsonPath('success', false);

        // 3. SensiblePOS order with Wholesale tier, fractional qty, line_notes, packing charge & auto round-off
        $okRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/pos/orders', [
            'warehouse_id' => $warehouseId,
            'customer_id' => $limitedCustomerId,
            'order_type' => 'takeaway',
            'price_tier' => 'Wholesale',
            'shipping_cost' => 15.00,
            'round_off_amount' => -0.40,
            'line_notes' => [(string) $productId => 'Extra Strong, Less Sugar'],
            'items' => [
                [
                    'product_id' => $productId,
                    'qty' => 1.5,
                    'unit_price' => 22.00,
                    'note' => 'Extra Strong, Less Sugar',
                ],
            ],
            'payments' => [
                ['method' => 'Cash', 'amount' => 47.60],
            ],
        ], $cafeHeaders);

        $okRes->assertStatus(201);
        $this->assertSame(201, $okRes->status(), json_encode($okRes->json()));
        $okRes->assertJsonPath('success', true)
            ->assertJsonPath('data.price_tier', 'Wholesale');
        $this->assertEqualsWithDelta(47.60, (float) $okRes->json('data.grand_total'), 0.05);
        $this->assertEqualsWithDelta(-0.40, (float) $okRes->json('data.round_off_amount'), 0.01);

        $saleId = (int) $okRes->json('data.id');
        $detail = $this->actingAs($user, 'sanctum')->getJson("/api/v1/pos/orders/{$saleId}", $cafeHeaders);
        $detail->assertStatus(200)
            ->assertJsonPath('data.price_tier', 'Wholesale')
            ->assertJsonPath('data.items.0.note', 'Extra Strong, Less Sugar');
        $this->assertEqualsWithDelta(1.5, (float) $detail->json('data.items.0.qty'), 0.01);
    }

    public function test_section_4_multi_format_printing_and_web_pos_parity(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $cafeHeaders = $this->actingHeaders(1);
        $productId = (int) (DB::table('products')->where('company_id', 1)->value('id') ?? 1);
        $warehouseId = (int) (DB::table('warehouses')->where('company_id', 1)->orderBy('id')->value('id') ?? 1);
        $custGroupId = (int) (DB::table('customer_groups')->orderBy('id')->value('id') ?? 1);
        $customerId = (int) (DB::table('customers')->where('company_id', 1)->value('id') ?: DB::table('customers')->insertGetId([
            'company_id' => 1,
            'customer_group_id' => $custGroupId,
            'name' => 'Print Test Guest',
            'phone_number' => '9842188882',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]));

        $saleRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/pos/orders', [
            'warehouse_id' => $warehouseId,
            'customer_id' => $customerId,
            'order_type' => 'dine_in',
            'items' => [
                ['product_id' => $productId, 'qty' => 2, 'unit_price' => 25.0, 'note' => 'Less Sugar'],
            ],
            'payments' => [['method' => 'Cash', 'amount' => 50.0]],
        ], $cafeHeaders);
        $this->assertSame(201, $saleRes->status(), json_encode($saleRes->json()));
        $saleId = (int) $saleRes->json('data.id');

        foreach ([
            'thermal_80mm',
            'thermal_58mm',
            'kot_ticket',
            'sticker_label_50x25mm',
            'can_neck_tag_50x38mm',
        ] as $format) {
            $job = $this->actingAs($user, 'sanctum')->postJson(
                "/api/v1/pos/orders/{$saleId}/print-job",
                ['format' => $format],
                $cafeHeaders
            );
            $job->assertStatus(200)
                ->assertJsonPath('success', true);
        }

        // Verify TSPL2 payload on sticker_label_50x25mm & web parity route
        $stickerJob = $this->actingAs($user, 'sanctum')->postJson(
            "/api/v1/pos/orders/{$saleId}/print-job",
            ['format' => 'sticker_label_50x25mm'],
            $cafeHeaders
        );
        $stickerJob->assertStatus(200);
        $rawBody = json_encode($stickerJob->json());
        $this->assertTrue(
            str_contains($rawBody, 'SIZE 50') || str_contains($rawBody, 'sticker_label_50x25mm'),
            'Expected sticker format metadata or TSPL2 dimensions in print job response.'
        );

        $webJob = $this->actingAs($user)
            ->withSession([
                'company_id' => 1,
                'branch_id' => (int) $cafeHeaders['X-Branch-ID'],
            ])
            ->postJson(
                route('cafe.pos.orders.print-job', ['id' => $saleId]),
                ['format' => 'thermal_80mm'],
                $cafeHeaders
            );
        $webJob->assertStatus(200)->assertJsonPath('success', true);
    }

    public function test_section_5_detailed_tanker_trip_sheet_with_motor_timing_and_gps_audit(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $tmwsHeaders = $this->actingHeaders(2);
        $tankerId = (int) (DB::table('water_tankers')->value('id') ?? 1);

        $tripRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/trip-sheets', [
            'tanker_id' => $tankerId,
            'customer_name' => 'The Chennai Silks Dyeing Unit',
            'destination_site' => 'Perundurai SIPCOT Sump #2',
            'water_quantity_litres' => 16000,
            'water_quantity_kl' => 16.0,
            'start_odometer' => 142810,
            'end_odometer' => 142848,
            'gps_tracked_km' => 37.6,
            'odometer_variance_km' => 0.4,
            'trip_started_at' => now()->subMinutes(97)->toIso8601String(),
            'site_arrived_at' => now()->subMinutes(45)->toIso8601String(),
            'site_departed_at' => now()->toIso8601String(),
            'travel_duration_minutes' => 52,
            'site_dwell_minutes' => 45,
            'waiting_minutes' => 15,
            'waiting_charge' => 37.50,
            'motor_started_at' => now()->subMinutes(35)->toIso8601String(),
            'motor_stopped_at' => now()->subMinutes(5)->toIso8601String(),
            'motor_pumping_minutes' => 30,
            'motor_pumping_charge' => 225.00,
            'billed_amount' => 2662.50,
            'gps_breadcrumbs' => [
                ['seq' => 1, 'label' => 'Departed Plant', 'latitude' => 11.3410, 'longitude' => 77.7172, 'speed_kmh' => 0],
                ['seq' => 2, 'label' => 'Arrived Site', 'latitude' => 11.0845, 'longitude' => 77.2941, 'speed_kmh' => 0],
            ],
        ], $tmwsHeaders);

        $tripRes->assertStatus(201)->assertJsonPath('success', true);
        $tripId = (int) ($tripRes->json('data.trip_id') ?? $tripRes->json('data.id'));
        $this->assertGreaterThan(0, $tripId);

        $trail = $this->actingAs($user, 'sanctum')->getJson("/api/v1/water/trips/{$tripId}/trail", $tmwsHeaders);
        $trail->assertStatus(200)->assertJsonPath('success', true);
        $breadcrumbs = $trail->json('data.breadcrumbs');
        $this->assertNotEmpty($breadcrumbs);
        $this->assertSame('Departed Plant', $breadcrumbs[0]['label']);
    }

    public function test_section_6_seven_layer_water_can_delivery_anti_cheat_and_blind_surrender(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $dkHeaders = $this->actingHeaders(3);
        $routeId = (int) DB::table('water_can_routes')->insertGetId([
            'route_name' => 'Isolated Test Route ' . uniqid(),
            'vehicle_no' => 'TN-99-TEST-CAN',
            'driver_name' => 'Test Route Driver',
            'daily_avg_cans' => 60,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $custGroupId = (int) (DB::table('customer_groups')->value('id') ?? 1);

        $customerId = DB::table('customers')->insertGetId([
            'company_id' => 3,
            'customer_group_id' => $custGroupId,
            'name' => 'Sri Murugan Bakery & Sweets',
            'phone_number' => '9842177771',
            'latitude' => 11.0182210,
            'longitude' => 76.9641190,
            'credit_limit' => 5000.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('water_can_inventories')->insert([
            'customer_id' => $customerId,
            'total_cans_held' => 5,
            'deposit_held' => 750.0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Layer 4a: Hardware Mock GPS MUST be blocked (422) and generate ANTI-CHEAT alert
        $mockRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'cans_delivered' => 5,
            'empty_cans_returned' => 5,
            'can_rate' => 40,
            'payment_mode' => 'Cash',
            'paid_amount' => 200,
            'is_mock_gps' => true,
            'enforce_anti_cheat' => true,
        ], $dkHeaders);
        $mockRes->assertStatus(422);
        $this->assertTrue(
            DB::table('notifications')->where('data', 'like', '%Mock GPS%')->exists(),
            'Expected Mock GPS alert in notifications table.'
        );

        // Layer 1: Credit delivery under anti-cheat without 4-digit PIN MUST fail (422)
        $noCreditPinRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'cans_delivered' => 5,
            'empty_cans_returned' => 5,
            'can_rate' => 40,
            'payment_mode' => 'Credit',
            'paid_amount' => 0,
            'enforce_anti_cheat' => true,
        ], $dkHeaders);
        $noCreditPinRes->assertStatus(422);

        // Layer 2: Rate reduction without Manager PIN MUST fail (422)
        $noOverridePinRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'cans_delivered' => 5,
            'empty_cans_returned' => 5,
            'can_rate' => 25,
            'master_can_rate' => 40,
            'rate_override_used' => true,
            'payment_mode' => 'Cash',
            'paid_amount' => 125,
            'enforce_anti_cheat' => true,
        ], $dkHeaders);
        $noOverridePinRes->assertStatus(422);

        // Layer 3: Empty jar deficit without stack photo proof MUST fail (422)
        $noPhotoRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'cans_delivered' => 8,
            'empty_cans_returned' => 4,
            'can_rate' => 40,
            'payment_mode' => 'Cash',
            'paid_amount' => 320,
            'enforce_anti_cheat' => true,
        ], $dkHeaders);
        $noPhotoRes->assertStatus(422);

        // Full Verified Delivery combining Layer 1 (Credit PIN), Layer 2 (Manager Override PIN 2580),
        // Layer 3 (Deficit photo proof + ₹150/jar), Layer 4b (Shop Wall QR DKW-SHOP-<id>), Layer 5 (Van Stock)
        $verifiedRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'morning_loaded_cans' => 10,
            'cans_delivered' => 12,
            'empty_cans_returned' => 8,
            'can_rate' => 30,
            'master_can_rate' => 40,
            'rate_override_used' => true,
            'override_pin' => '2580',
            'payment_mode' => 'Credit',
            'paid_amount' => 0,
            'credit_pin' => '4829',
            'credit_pin_verified' => true,
            'send_credit_whatsapp_alert' => true,
            'delivery_lat' => 11.0182210,
            'delivery_lng' => 76.9641190,
            'shop_qr_code' => "DKW-SHOP-{$customerId}",
            'empty_jar_photo_verified' => true,
            'refill_photo' => 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
            'enforce_anti_cheat' => true,
        ], $dkHeaders);

        $verifiedRes->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.anti_cheat_audit.credit_alert_dispatched', true)
            ->assertJsonPath('data.anti_cheat_audit.rate_override_used', true)
            ->assertJsonPath('data.anti_cheat_audit.qr_verified', true)
            ->assertJsonPath('data.anti_cheat_audit.geofence_verified', true)
            ->assertJsonPath('data.anti_cheat_audit.empty_jar_deficit', 4)
            ->assertJsonPath('data.anti_cheat_audit.empty_jar_photo_verified', true);
        $this->assertEqualsWithDelta(600.0, (float) $verifiedRes->json('data.anti_cheat_audit.deposit_liability'), 0.01);
        $this->assertContains('VAN_STOCK_EXCEEDED_OFFBOOK_RISK', $verifiedRes->json('data.anti_cheat_audit.flags'));

        // Confirm balance jars held incremented from 5 + (12 - 8) = 9
        $this->assertDatabaseHas('water_can_inventories', [
            'customer_id' => $customerId,
            'total_cans_held' => 9,
        ]);

        // Layer 7: Blind Note Denomination Tally Surrender with cash shortage detection
        DB::table('water_can_deliveries')->insert([
            'delivery_no' => 'DLV-TEST-' . uniqid(),
            'delivery_date' => now()->toDateString(),
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'morning_loaded_cans' => 40,
            'cans_delivered' => 20,
            'empty_cans_returned' => 20,
            'can_rate' => 50,
            'total_amount' => 1000,
            'paid_amount' => 1000,
            'payment_mode' => 'Cash',
            'balance_cans_held' => 9,
            'status' => 'delivered',
            'created_by' => $user->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $surrenderRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/driver-surrender', [
            'route_id' => $routeId,
            'empty_cans_returned' => 20,
            'filled_cans_returned' => 10,
            'damaged_cans_reported' => 1,
            'denominations' => [
                '500' => 1,
                '100' => 2,
                '50' => 1,
            ],
        ], $dkHeaders);

        $surrenderRes->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->assertEqualsWithDelta(750.0, (float) $surrenderRes->json('data.cash_surrendered'), 0.01);
        $this->assertGreaterThan(0.0, (float) $surrenderRes->json('data.audit_summary.cash_shortage'));
        $this->assertTrue(
            DB::table('notifications')->where('data', 'like', '%Surrender%')->exists(),
            'Expected driver surrender shortage notification.'
        );
    }

    public function test_tanker_order_queue_processing_and_non_hardcoded_pos_bootstrap(): void
    {
        $user = User::where('name', 'admin')->first() ?? User::find(1);
        $tankerDriver = User::where('name', 'tanker_driver')->first() ?? $user;
        $tmwsCompanyId = (int) (DB::table('companies')->where('code', 'TMWS')->value('id') ?? 2);
        $tmwsHeaders = $this->actingHeaders($tmwsCompanyId);
        $tmwsBranchId = (int) $tmwsHeaders['X-Branch-ID'];

        $preManifest = $this->actingAs($tankerDriver, 'sanctum')->getJson('/api/v1/mobile/driver/manifest', $tmwsHeaders);
        $preManifest->assertStatus(200)->assertJsonPath('data.driver_type', 'tanker');
        $tankerId = (int) ($preManifest->json('data.vehicle.id') ?? DB::table('water_tankers')->value('id'));
        if (!$tankerId) {
            $tankerId = DB::table('water_tankers')->insertGetId([
                'company_id' => 3,
                'vehicle_number' => 'TN-99-TEST-01',
                'capacity_litres' => 20000,
                'current_odometer_km' => 11900,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 1. Dispatcher creates an assigned/dispatched bulk tanker order via API
        $createRes = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/trip-sheets', [
            'tanker_id' => $tankerId,
            'trip_date' => now()->toDateString(),
            'source_plant' => 'Main RO Plant',
            'delivery_site' => 'Perundurai Industrial Estate',
            'water_quantity_litres' => 20000,
            'trip_rate' => 3800,
            'status' => 'dispatched',
        ], $tmwsHeaders);
        $createRes->assertStatus(201)->assertJsonPath('success', true);
        $tripId = (int) $createRes->json('data.id');
        $this->assertGreaterThan(0, $tripId);

        // 2. Driver manifest surfaces the dispatched order in pending_trips
        $manifestRes = $this->actingAs($tankerDriver, 'sanctum')->getJson('/api/v1/mobile/driver/manifest', $tmwsHeaders);
        $manifestRes->assertStatus(200)->assertJsonPath('success', true);
        $pendingIds = collect($manifestRes->json('data.pending_trips'))->pluck('id')->all();
        $this->assertContains($tripId, $pendingIds);

        // 3. Driver starts transit and then completes the assigned order via process endpoint
        $transitRes = $this->actingAs($tankerDriver, 'sanctum')->postJson("/api/v1/water/trips/{$tripId}/process", [
            'status' => 'in_transit',
            'start_km' => 12000,
        ], $tmwsHeaders);
        $transitRes->assertStatus(200)->assertJsonPath('data.status', 'in_transit');

        $completeRes = $this->actingAs($tankerDriver, 'sanctum')->postJson("/api/v1/water/trips/{$tripId}/process", [
            'status' => 'completed',
            'start_km' => 12000,
            'end_km' => 12042,
            'motor_pumping_minutes' => 18,
            'trip_rate' => 3800,
        ], $tmwsHeaders);
        $completeRes->assertStatus(200)->assertJsonPath('data.status', 'completed');

        $this->assertDatabaseHas('water_tanker_trips', [
            'id' => $tripId,
            'status' => 'completed',
            'end_km' => 12042,
        ]);
        $updatedOdo = (int) DB::table('water_tankers')->where('id', $tankerId)->value('current_odometer_km');
        $this->assertGreaterThanOrEqual(12042, $updatedOdo);

        // 4. Web portal route also processes a dispatched order cleanly
        $webCreate = $this->actingAs($user, 'sanctum')->postJson('/api/v1/water/trip-sheets', [
            'tanker_id' => $tankerId,
            'trip_date' => now()->toDateString(),
            'source_plant' => 'Main RO Plant',
            'delivery_site' => 'Erode Ring Road Site',
            'water_quantity_litres' => 10000,
            'trip_rate' => 2200,
            'status' => 'dispatched',
        ], $tmwsHeaders);
        $webTripId = (int) $webCreate->json('data.id');

        $webProcess = $this->actingAs($user)
            ->withSession(['company_id' => $tmwsCompanyId, 'branch_id' => $tmwsBranchId])
            ->post(route('water-logistics.trip.process', ['id' => $webTripId]), [
                'status' => 'completed',
                'start_km' => 12042,
                'end_km' => 12070,
                'billed_amount' => 2200,
            ]);
        $webProcess->assertRedirect();
        $this->assertDatabaseHas('water_tanker_trips', [
            'id' => $webTripId,
            'status' => 'completed',
        ]);

        // 5. Web Quick POS page omits old hardcoded demo constants
        $posPage = $this->actingAs($user)
            ->withSession(['company_id' => 1, 'branch_id' => 1])
            ->get(route('cafe.pos'));
        $posPage->assertStatus(200);
        $posPage->assertViewIs('backend.cafe.quick_pos');
        $posPage->assertDontSee('POS-SAMPLE-001');
        $posPage->assertDontSee('ARAN-FC-01');
        $posPage->assertDontSee('dkenterprises@upi');
    }
}
