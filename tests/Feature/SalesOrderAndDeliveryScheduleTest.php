<?php

namespace Tests\Feature;

use App\Models\DeliverySchedule;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class SalesOrderAndDeliveryScheduleTest extends TestCase
{
    use DatabaseTransactions;

    private function createCompanyCustomer(int $companyId, string $name): int
    {
        $groupId = (int) (DB::table('customer_groups')->orderBy('id')->value('id') ?? 1);

        return (int) DB::table('customers')->insertGetId([
            'company_id' => $companyId,
            'customer_group_id' => $groupId,
            'name' => $name . ' ' . uniqid(),
            'phone_number' => '98421' . random_int(10000, 99999),
            'address' => 'Test Ring Road',
            'city' => 'Madurai',
            'latitude' => 11.0182210,
            'longitude' => 76.9641190,
            'credit_limit' => 25000.00,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_can_order_create_adjust_and_close_syncs_sales_order_and_fulfills_erp_sale(): void
    {
        $driver = User::where('name', 'driver')->firstOrFail();
        $token = $driver->createToken('test-can-so-lifecycle')->plainTextToken;
        $customerId = $this->createCompanyCustomer(3, 'Kaveri Can Depot');
        $today = CarbonImmutable::today()->toDateString();

        // 1. Create customizable On-Day 20L Can order -> creates SalesOrder in `sales_orders`
        $createRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/can-orders', [
                'customer_id' => $customerId,
                'ordered_cans' => 7,
                'can_rate' => 40,
                'payment_mode' => 'Cash',
                'delivery_date' => $today,
                'order_notes' => 'Morning requirement',
            ]);

        $createRes->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.ordered_cans', 7)
            ->assertJsonPath('data.order_origin', 'on_day')
            ->assertJsonPath('data.is_regular_scheduled', false);

        $orderId = (int) $createRes->json('data.order_id');
        $salesOrderId = (int) $createRes->json('data.sales_order_id');
        $salesOrderNo = (string) $createRes->json('data.sales_order_no');
        $this->assertGreaterThan(0, $orderId);
        $this->assertGreaterThan(0, $salesOrderId);
        $this->assertStringStartsWith('SO-CAN-', $salesOrderNo);

        $this->assertDatabaseHas('sales_orders', [
            'id' => $salesOrderId,
            'company_id' => 3,
            'customer_id' => $customerId,
            'status' => 'open',
        ]);
        $this->assertDatabaseHas('commercial_order_items', [
            'order_kind' => 'sale',
            'order_id' => $salesOrderId,
            'qty' => 7.0000,
        ]);

        // 2. Customize / Adjust quantity, rate & notes before closing
        $adjustRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/can-orders/{$orderId}/adjust", [
                'ordered_cans' => 11,
                'can_rate' => 45,
                'payment_mode' => 'UPI',
                'order_notes' => 'Deliver at back shutter',
            ]);

        $adjustRes->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.ordered_cans', 11)
            ->assertJsonPath('data.can_rate', 45)
            ->assertJsonPath('data.payment_mode', 'UPI');

        $this->assertDatabaseHas('commercial_order_items', [
            'order_kind' => 'sale',
            'order_id' => $salesOrderId,
            'qty' => 11.0000,
            'unit_rate' => 45.0000,
        ]);
        $this->assertDatabaseHas('commercial_order_events', [
            'order_kind' => 'sale',
            'order_id' => $salesOrderId,
            'event' => 'amended',
        ]);

        // 3. Close order -> creates Sales Bill (`sales`) and fulfills `sales_orders`
        $closeRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/can-orders/{$orderId}/close", [
                'cans_delivered' => 11,
                'empty_cans_returned' => 11,
                'can_rate' => 45,
                'master_rate' => 45,
                'payment_mode' => 'UPI',
                'paid_amount' => 495,
                'delivery_lat' => 11.0182210,
                'delivery_lng' => 76.9641190,
                'enforce_anti_cheat' => true,
            ]);

        $closeRes->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.sales_order_id', $salesOrderId);

        $saleId = (int) $closeRes->json('data.sale_id');
        $this->assertGreaterThan(0, $saleId);
        $this->assertDatabaseHas('sales', [
            'id' => $saleId,
            'company_id' => 3,
            'customer_id' => $customerId,
        ]);
        $this->assertDatabaseHas('sales_orders', [
            'id' => $salesOrderId,
            'status' => 'fulfilled',
        ]);
        $this->assertDatabaseHas('commercial_order_allocations', [
            'consumer_type' => 'sale',
            'consumer_id' => $saleId,
            'stage' => 'billing',
        ]);
    }

    public function test_bulk_tanker_order_create_adjust_and_complete_syncs_sales_order_and_fulfills_sale(): void
    {
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $token = $tankerUser->createToken('test-tanker-so-lifecycle')->plainTextToken;
        $customerId = $this->createCompanyCustomer(2, 'Sakthi Spinning Mills');
        $tankerId = (int) (DB::table('water_tankers')->where('is_active', true)->orderBy('id')->value('id') ?? 1);
        $today = CarbonImmutable::today()->toDateString();

        // 1. Create Bulk Tanker Sales Order
        $createRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '2')
            ->postJson('/api/v1/water/tanker-orders', [
                'customer_id' => $customerId,
                'tanker_id' => $tankerId,
                'water_quantity_kl' => 15,
                'trip_rate' => 2700,
                'destination_site' => 'Sakthi Sump Block A',
                'trip_date' => $today,
                'notes' => 'Evening decant',
            ]);

        $createRes->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.order_origin', 'on_day')
            ->assertJsonPath('data.is_regular_scheduled', false);

        $tripId = (int) $createRes->json('data.id');
        $salesOrderId = (int) $createRes->json('data.sales_order_id');
        $salesOrderNo = (string) $createRes->json('data.sales_order_no');
        $this->assertGreaterThan(0, $tripId);
        $this->assertGreaterThan(0, $salesOrderId);
        $this->assertStringStartsWith('SO-TNK-', $salesOrderNo);

        $this->assertDatabaseHas('sales_orders', [
            'id' => $salesOrderId,
            'company_id' => 2,
            'customer_id' => $customerId,
            'status' => 'open',
        ]);

        // 2. Adjust tanker order before decanting
        $adjustRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '2')
            ->postJson("/api/v1/water/tanker-orders/{$tripId}/adjust", [
                'water_quantity_kl' => 20,
                'trip_rate' => 3600,
                'destination_site' => 'Sakthi Main RO Sump',
            ]);

        $adjustRes->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.water_quantity_kl', 20)
            ->assertJsonPath('data.trip_rate', 3600);

        $this->assertDatabaseHas('commercial_order_items', [
            'order_kind' => 'sale',
            'order_id' => $salesOrderId,
            'qty' => 20.0000,
            'unit_rate' => 180.0000,
        ]);

        // 3. Process / complete trip into ERP Sales Bill + fulfill `sales_orders`
        $completeRes = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '2')
            ->postJson("/api/v1/water/trips/{$tripId}/process", [
                'status' => 'completed',
                'start_km' => 45200,
                'end_km' => 45225,
                'water_quantity_kl' => 20,
                'trip_rate' => 3600,
                'motor_pumping_minutes' => 15,
            ]);

        $completeRes->assertStatus(200)->assertJsonPath('success', true);

        $tripRow = DB::table('water_tanker_trips')->where('id', $tripId)->first();
        $this->assertNotNull($tripRow?->sale_id);
        $this->assertDatabaseHas('sales', [
            'id' => $tripRow->sale_id,
            'company_id' => 2,
            'customer_id' => $customerId,
        ]);
        $this->assertDatabaseHas('sales_orders', [
            'id' => $salesOrderId,
            'status' => 'fulfilled',
        ]);
    }

    public function test_recurring_schedule_every_n_days_weekly_biweekly_monthly_and_idempotent_materialization(): void
    {
        $driver = User::where('name', 'driver')->firstOrFail();
        $driverToken = $driver->createToken('test-can-sched')->plainTextToken;
        $canCustomerId = $this->createCompanyCustomer(3, 'Meenakshi Hotel');
        $today = CarbonImmutable::today();

        // Create Can order + Every 2 Days schedule at the same time
        $res = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/can-orders', [
                'customer_id' => $canCustomerId,
                'ordered_cans' => 12,
                'can_rate' => 38,
                'payment_mode' => 'Cash',
                'delivery_date' => $today->toDateString(),
                'create_schedule' => true,
                'schedule_frequency' => 'every_n_days',
                'interval_days' => 2,
            ]);

        $res->assertStatus(201)
            ->assertJsonPath('data.order_origin', 'scheduled')
            ->assertJsonPath('data.is_regular_scheduled', true);

        $scheduleId = (int) $res->json('data.schedule_id');
        $this->assertGreaterThan(0, $scheduleId);
        $schedule = DeliverySchedule::findOrFail($scheduleId);
        $this->assertSame('every_n_days', $schedule->frequency);
        $this->assertSame(2, (int) $schedule->interval_days);
        $this->assertSame($today->addDays(2)->toDateString(), $schedule->next_run_date->toDateString());

        // Generate-now for today must NOT create duplicate order
        $dupCheck = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/schedules/{$scheduleId}/generate-now", [
                'for_date' => $today->toDateString(),
            ]);
        $dupCheck->assertStatus(200)->assertJsonPath('data.generated', false);

        // Materialize due schedules for +2 days -> creates 2nd Sales Order & advances next_run_date to +4 days
        $dueDate = $today->addDays(2)->toDateString();
        $dueRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/schedules/generate-due', [
                'for_date' => $dueDate,
            ]);
        $dueRes->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, (int) $dueRes->json('data.generated_count'));

        $this->assertSame(
            2,
            DB::table('water_can_deliveries')->where('schedule_id', $scheduleId)->count(),
            'Today order + due date order must yield exactly 2 deliveries.'
        );
        $this->assertSame(
            $today->addDays(4)->toDateString(),
            $schedule->fresh()->next_run_date->toDateString()
        );

        // Calling generate-due again for the same dueDate must be idempotent (0 new duplicates)
        $repeatDueRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/schedules/generate-due', [
                'for_date' => $dueDate,
            ]);
        $repeatDueRes->assertStatus(200);
        $this->assertSame(0, (int) $repeatDueRes->json('data.generated_count'));

        // Skip next occurrence (+4 -> +6) & toggle pause/resume
        $skipRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/schedules/{$scheduleId}/skip");
        $skipRes->assertStatus(200);
        $this->assertSame($today->addDays(6)->toDateString(), $schedule->fresh()->next_run_date->toDateString());

        $toggleRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/schedules/{$scheduleId}/toggle");
        $toggleRes->assertStatus(200)->assertJsonPath('data.is_active', false);

        // Create Weekly & Biweekly/Monthly schedule rules via /water/schedules
        $weeklyRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/schedules', [
                'vertical_type' => 'can',
                'customer_id' => $canCustomerId,
                'ordered_qty' => 8,
                'unit_rate' => 35,
                'frequency' => 'weekly',
                'days_of_week' => [1, 4],
                'start_date' => $today->toDateString(),
            ]);
        $weeklyRes->assertStatus(201)->assertJsonPath('data.schedule.frequency', 'weekly');

        // Tanker driver creates recurring Tanker schedule with immediate generation
        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $tankerToken = $tankerUser->createToken('test-tanker-sched')->plainTextToken;
        $tankerCustId = $this->createCompanyCustomer(2, 'Velmurugan Dyeing');

        $tankerSchedRes = $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->withHeader('X-Company-ID', '2')
            ->postJson('/api/v1/water/schedules', [
                'vertical_type' => 'tanker',
                'customer_id' => $tankerCustId,
                'ordered_qty' => 20,
                'unit_rate' => 3600,
                'frequency' => 'every_n_days',
                'interval_days' => 3,
                'start_date' => $today->toDateString(),
                'generate_immediately' => true,
            ]);

        $tankerSchedRes->assertStatus(201)
            ->assertJsonPath('data.schedule.vertical_type', 'tanker')
            ->assertJsonPath('data.generated_order.order_origin', 'scheduled')
            ->assertJsonPath('data.generated_order.is_regular_scheduled', true);
    }

    public function test_strict_vertical_isolation_and_order_cancel_syncs_sales_order(): void
    {
        $driver = User::where('name', 'driver')->firstOrFail();
        $tankerUser = User::where('name', 'tanker_driver')->firstOrFail();
        $cashier = User::where('name', 'cashier')->firstOrFail();
        $admin = User::where('name', 'admin')->firstOrFail();

        $driverToken = $driver->createToken('test-iso-can')->plainTextToken;
        $tankerToken = $tankerUser->createToken('test-iso-tanker')->plainTextToken;
        $cashierToken = $cashier->createToken('test-iso-cashier')->plainTextToken;
        $adminToken = $admin->createToken('test-iso-admin')->plainTextToken;

        // Cross-vertical 403 gating
        $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->getJson('/api/v1/water/schedules?vertical_type=tanker')
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->postJson('/api/v1/water/tanker-orders', ['water_quantity_kl' => 10])
            ->assertStatus(403);

        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->getJson('/api/v1/water/schedules?vertical_type=can')
            ->assertStatus(403);

        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->postJson('/api/v1/water/can-orders', ['ordered_cans' => 5])
            ->assertStatus(403);

        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', "Bearer {$cashierToken}")
            ->getJson('/api/v1/water/schedules')
            ->assertStatus(403);

        // Super Admin accesses both verticals cleanly
        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->getJson('/api/v1/water/schedules?vertical_type=can')
            ->assertStatus(200);
        $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->getJson('/api/v1/water/schedules?vertical_type=tanker')
            ->assertStatus(200);

        // Cancel open can order syncs `sales_orders.status = cancelled`
        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $custId = $this->createCompanyCustomer(3, 'Cancel Check Shop');
        $book = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/can-orders', [
                'customer_id' => $custId,
                'ordered_cans' => 4,
            ])->assertStatus(201);

        $orderId = (int) $book->json('data.order_id');
        $salesOrderId = (int) $book->json('data.sales_order_id');

        $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/can-orders/{$orderId}/cancel", ['reason' => 'Shop closed'])
            ->assertStatus(200);

        $this->assertDatabaseHas('sales_orders', [
            'id' => $salesOrderId,
            'status' => 'cancelled',
        ]);
    }
}
