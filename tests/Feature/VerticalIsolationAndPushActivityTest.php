<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class VerticalIsolationAndPushActivityTest extends TestCase
{
    use DatabaseTransactions;

    public function test_me_endpoint_normalizes_driver_display_names_and_locks_verticals_for_non_superadmin(): void
    {
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $token = $tankerUser->createToken('test-me-lock')->plainTextToken;

        // Even if X-Company-ID points to company 3 (DK Waters), tanker_driver is strictly locked to TMWS (bulk_water)
        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/me');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertNotEquals('tanker_driver', strtolower((string) $data['user']['name']));
        $this->assertEquals('K. Murugan', $data['user']['name']);
        $this->assertEquals('tanker_driver', $data['user']['username']);
        $this->assertEquals('Bulk Tanker Driver', $data['user']['role_label']);
        $this->assertFalse((bool) $data['can_switch_companies']);
        $this->assertCount(1, $data['companies']);
        $this->assertEquals('bulk_water', $data['companies'][0]['industry']);
    }

    public function test_superadmin_can_access_all_vertical_companies_and_workspace(): void
    {
        $admin = User::where('name', 'admin')->firstOrFail();
        $token = $admin->createToken('test-admin-all')->plainTextToken;

        $meRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/me');

        $meRes->assertStatus(200);
        $this->assertGreaterThan(1, count($meRes->json('data.companies')));
        $this->assertTrue((bool) $meRes->json('data.can_switch_companies'));

        $wsRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/mobile/workspace');
        $wsRes->assertStatus(200);
    }

    public function test_tmws_tanker_driver_attendance_geofence_uses_tmws_plant_never_dk_waters(): void
    {
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $token = $tankerUser->createToken('test-hrm-geofence')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3') // Attempt cross-vertical header spoofing
            ->getJson('/api/v1/hrm/attendance/status');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertStringContainsString('Tiruchendur Murugan Water Supply', $data['geofence']['depot_name']);
        $this->assertStringNotContainsString('DK Waters', $data['geofence']['depot_name']);
        $this->assertEquals('K. Murugan', $data['employee_name']);
    }

    public function test_cross_vertical_api_requests_are_blocked_for_non_superadmin(): void
    {
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $tankerToken = $tankerUser->createToken('test-cross-tanker')->plainTextToken;

        // Tanker driver cannot post 20L can delivery or access workspace
        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->postJson('/api/v1/water/can-deliveries', ['cans_delivered' => 5])
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->getJson('/api/v1/mobile/workspace')
            ->assertStatus(403);

        // Can driver cannot post bulk tanker trip sheet
        $this->app['auth']->forgetGuards();
        $canUser = User::where('name', 'driver')->firstOrFail();
        $canToken = $canUser->createToken('test-cross-can')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$canToken}")
            ->postJson('/api/v1/water/trip-sheets', ['water_quantity_kl' => 10, 'billed_amount' => 1800])
            ->assertStatus(403);
    }

    public function test_driver_activity_generates_push_notifications_for_super_admin_and_marks_all_read(): void
    {
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $tankerToken = $tankerUser->createToken('test-notify-driver')->plainTextToken;

        // Tanker driver checks in and logs a trip
        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->postJson('/api/v1/hrm/attendance/check-in', ['odometer_km' => 45310])
            ->assertStatus(201);

        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->postJson('/api/v1/water/trip-sheets', [
                'destination_site' => 'Perundurai SIPCOT Plant',
                'water_quantity_kl' => 20,
                'billed_amount' => 3500,
                'start_km' => 45310,
                'end_km' => 45345,
            ])
            ->assertStatus(201);

        // Super Admin receives the activity notifications immediately in feed
        $this->app['auth']->forgetGuards();
        $admin = User::where('name', 'admin')->firstOrFail();
        $adminToken = $admin->createToken('test-notify-admin')->plainTextToken;

        $feed = $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->getJson('/api/v1/notifications')
            ->assertStatus(200);

        $titles = collect($feed->json('data.notifications'))->pluck('title')->implode(' | ');
        $this->assertStringContainsString('checked in on shift', $titles);
        $this->assertStringContainsString('Tanker Trip Logged', $titles);
        $this->assertGreaterThanOrEqual(2, (int) $feed->json('data.unread_count'));

        // Mark all read
        $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->postJson('/api/v1/notifications/all/read')
            ->assertStatus(200);
    }
}

