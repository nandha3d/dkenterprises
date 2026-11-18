<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ErpGstSyncAndFleetMapTest extends TestCase
{
    use DatabaseTransactions;

    private function actingHeaders(int $companyId, ?int $branchId = null): array
    {
        $resolvedBranch = $branchId ?? (int) (Company::find($companyId)?->branches()->orderBy('id')->value('id') ?? 1);

        return [
            'X-Company-ID' => (string) $companyId,
            'X-Branch-ID' => (string) $resolvedBranch,
            'Accept' => 'application/json',
        ];
    }

    public function test_can_delivery_and_tanker_trip_sync_to_erp_and_gst_without_double_counting(): void
    {
        $admin = User::where('name', 'admin')->first() ?? User::find(1);
        $dkHeaders = $this->actingHeaders(3);
        $custGroupId = (int) (DB::table('customer_groups')->orderBy('id')->value('id') ?? 1);

        $customerId = DB::table('customers')->insertGetId([
            'company_id' => 3,
            'customer_group_id' => $custGroupId,
            'name' => 'Madurai Teppakulam Milk Depot',
            'phone_number' => '9842100099',
            'address' => 'East Masi Street',
            'city' => 'Madurai',
            'latitude' => 9.9142,
            'longitude' => 78.1460,
            'credit_limit' => 8000.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $routeId = (int) (DB::table('water_can_routes')->value('id') ?? 1);

        $canRes = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/water/can-deliveries', [
            'route_id' => $routeId,
            'customer_id' => $customerId,
            'cans_delivered' => 10,
            'empty_cans_returned' => 10,
            'can_rate' => 45,
            'payment_mode' => 'Cash',
            'paid_amount' => 450,
            'enforce_anti_cheat' => false,
        ], $dkHeaders);

        $canRes->assertStatus(201)->assertJsonPath('success', true);
        $deliveryId = (int) $canRes->json('data.id');
        $deliveryRow = DB::table('water_can_deliveries')->where('id', $deliveryId)->first();
        $this->assertNotNull($deliveryRow?->sale_id, 'Expected can delivery to create and link ERP sale_id.');

        $this->assertDatabaseHas('sales', [
            'id' => $deliveryRow->sale_id,
            'company_id' => 3,
            'customer_id' => $customerId,
        ]);
        $this->assertDatabaseHas('gst_transaction_projections', [
            'source_type' => 'sale',
            'source_id' => $deliveryRow->sale_id,
            'company_id' => 3,
        ]);
        $gstCanProj = DB::table('gst_transaction_projections')
            ->where('source_type', 'sale')
            ->where('source_id', $deliveryRow->sale_id)
            ->first();
        $this->assertNotNull($gstCanProj);
        $this->assertStringContainsString('22019010', (string) ($gstCanProj->snapshot_json ?? ''));

        // Now verify financials daily_sales_series (days=14) and zero double counting
        $finRes = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/mobile/financials?days=14', $dkHeaders);
        $finRes->assertStatus(200)->assertJsonPath('success', true);
        $series = $finRes->json('data.daily_sales_series');
        $this->assertIsArray($series);
        $this->assertCount(14, $series);

        $todayRow = collect($series)->firstWhere('date', now()->toDateString());
        $this->assertNotNull($todayRow);
        $this->assertGreaterThanOrEqual(450.0, (float) $todayRow['total']);

        // Verify customersList and fleetLive expose financial Paid/Due/Overdue & GPS
        $custRes = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/mobile/customers', $dkHeaders);
        $custRes->assertStatus(200);
        $matchedCust = collect($custRes->json('data'))->firstWhere('id', $customerId);
        $this->assertNotNull($matchedCust);
        $this->assertEqualsWithDelta(450.0, (float) $matchedCust['total_paid'], 0.01);
        $this->assertEqualsWithDelta(0.0, (float) $matchedCust['due_amount'], 0.01);

        $fleetRes = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/mobile/fleet/live?industry=packaged_water', $dkHeaders);
        $fleetRes->assertStatus(200);
        $mapCust = collect($fleetRes->json('data.customers'))->firstWhere('id', $customerId);
        $this->assertNotNull($mapCust);
        $this->assertEquals('paid', $mapCust['payment_status']);
        $this->assertGreaterThanOrEqual(1, (int) ($mapCust['orders_count'] ?? 0));
        $this->assertNotEmpty($mapCust['recent_purchases'] ?? []);
        $this->assertNotEmpty($fleetRes->json('data.can_routes.0.today_summary'));
        $this->assertNotEmpty($fleetRes->json('data.can_routes.0.today_timeline'));

        // Verify customer full history (how much to pay, when/where/how much bought, payment details)
        $custHistRes = $this->actingAs($admin, 'sanctum')->getJson("/api/v1/mobile/customers/{$customerId}/history", $dkHeaders);
        $custHistRes->assertStatus(200)->assertJsonPath('success', true);
        $this->assertEqualsWithDelta(450.0, (float) $custHistRes->json('data.customer.total_paid'), 0.01);
        $this->assertNotEmpty($custHistRes->json('data.purchases'));
        $this->assertNotEmpty($custHistRes->json('data.payments'));
        $this->assertNotEmpty($custHistRes->json('data.timeline'));

        // Verify delivery boy today activity & chronological timeline endpoint
        $driverActRes = $this->actingAs($admin, 'sanctum')->getJson("/api/v1/mobile/fleet/driver-activity?vehicle_type=route&vehicle_id={$routeId}", $dkHeaders);
        $driverActRes->assertStatus(200)->assertJsonPath('success', true);
        $this->assertGreaterThanOrEqual(10, (int) $driverActRes->json('data.today_summary.cans_delivered'));
        $this->assertNotEmpty($driverActRes->json('data.today_timeline'));
    }

    public function test_tanker_trip_sync_and_fleet_ping_gps_disabled_triggers_admin_alert(): void
    {
        $admin = User::where('name', 'admin')->first() ?? User::find(1);
        $tmwsHeaders = $this->actingHeaders(2);
        $tankerId = (int) (DB::table('water_tankers')->value('id') ?? 1);
        $custGroupId = (int) (DB::table('customer_groups')->orderBy('id')->value('id') ?? 1);

        $siteCustomerId = DB::table('customers')->insertGetId([
            'company_id' => 2,
            'customer_group_id' => $custGroupId,
            'name' => 'Madurai Meenakshi Hospital Sump',
            'phone_number' => '9842100088',
            'address' => 'Lake Area Main Road',
            'city' => 'Madurai',
            'latitude' => 9.9390,
            'longitude' => 78.1485,
            'credit_limit' => 25000.00,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $tripRes = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/water/trip-sheets', [
            'tanker_id' => $tankerId,
            'customer_id' => $siteCustomerId,
            'trip_date' => now()->toDateString(),
            'source_plant' => 'Melur RO Plant',
            'delivery_site' => 'Madurai Meenakshi Hospital Sump',
            'water_quantity_litres' => 20000,
            'trip_rate' => 3600,
            'payment_mode' => 'Credit',
            'paid_amount' => 0,
            'status' => 'completed',
        ], $tmwsHeaders);

        $tripRes->assertStatus(201);
        $tripId = (int) $tripRes->json('data.id');
        $tripRow = DB::table('water_tanker_trips')->where('id', $tripId)->first();
        $this->assertNotNull($tripRow?->sale_id, 'Expected completed tanker trip to link ERP sale_id.');

        $this->assertDatabaseHas('gst_transaction_projections', [
            'source_type' => 'sale',
            'source_id' => $tripRow->sale_id,
            'company_id' => 2,
        ]);
        $gstTripProj = DB::table('gst_transaction_projections')
            ->where('source_type', 'sale')
            ->where('source_id', $tripRow->sale_id)
            ->first();
        $this->assertNotNull($gstTripProj);
        $this->assertStringContainsString('22019090', (string) ($gstTripProj->snapshot_json ?? ''));

        // Credit sale should reflect due balance in fleetLive
        $fleetRes = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/mobile/fleet/live?industry=bulk_water', $tmwsHeaders);
        $fleetRes->assertStatus(200);
        $siteMap = collect($fleetRes->json('data.customers'))->firstWhere('id', $siteCustomerId);
        $this->assertNotNull($siteMap);
        $this->assertGreaterThanOrEqual(3600.0, (float) $siteMap['due_amount']);

        // Verify customer history and tanker driver activity timeline endpoints
        $siteHistRes = $this->actingAs($admin, 'sanctum')->getJson("/api/v1/mobile/customers/{$siteCustomerId}/history", $tmwsHeaders);
        $siteHistRes->assertStatus(200)->assertJsonPath('success', true);
        $this->assertGreaterThanOrEqual(3600.0, (float) $siteHistRes->json('data.customer.due_amount'));
        $this->assertNotEmpty($siteHistRes->json('data.purchases'));

        $tankerActRes = $this->actingAs($admin, 'sanctum')->getJson("/api/v1/mobile/fleet/driver-activity?vehicle_type=tanker&vehicle_id={$tankerId}", $tmwsHeaders);
        $tankerActRes->assertStatus(200)->assertJsonPath('success', true);
        $this->assertGreaterThanOrEqual(1, (int) $tankerActRes->json('data.today_summary.trips_completed'));
        $this->assertNotEmpty($tankerActRes->json('data.today_timeline'));

        // Simulate driver disabling GPS on duty -> must store compliance alert notification
        $pingRes = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/mobile/fleet/ping', [
            'vehicle_type' => 'tanker',
            'vehicle_id' => $tankerId,
            'gps_enabled' => false,
            'is_mocked' => false,
        ], $tmwsHeaders);

        $pingRes->assertStatus(200)->assertJsonPath('success', true);
        $this->assertTrue(
            DB::table('notifications')->where('data', 'like', '%GPS%')->exists(),
            'Expected GPS disabled compliance notification in notifications table.'
        );
    }
}
