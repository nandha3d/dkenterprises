<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class WaterCanOrderWorkflowTest extends TestCase
{
    use DatabaseTransactions;

    public function test_delivery_driver_cannot_close_delivery_without_order_first(): void
    {
        $driver = User::where('name', 'driver')->firstOrFail();
        $token = $driver->createToken('test-order-first-block')->plainTextToken;

        $customerId = (int) DB::table('customers')->where('company_id', 3)->value('id');
        if ($customerId <= 0) {
            $customerId = (int) DB::table('customers')->insertGetId([
                'company_id' => 3,
                'customer_group_id' => (int) (DB::table('customer_groups')->value('id') ?? 1),
                'name' => 'OrderFirst Guard Shop ' . uniqid(),
                'phone_number' => '9842100011',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $res = $this->withHeader('Authorization', "Bearer {$token}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/can-deliveries', [
                'customer_id' => $customerId,
                'cans_delivered' => 7,
                'empty_cans_returned' => 7,
                'can_rate' => 35,
                'payment_mode' => 'Cash',
                'paid_amount' => 245,
            ]);

        $res->assertStatus(422)
            ->assertJsonPath('errors.order_id.0', 'ORDER_FIRST_REQUIRED');

        $this->assertTrue(
            DB::table('notifications')->where('data', 'like', '%Unordered Can Delivery Attempt Blocked%')->exists(),
            'Owner/Admin must receive anti-cheat alert when driver skips Order-First booking.'
        );
    }

    public function test_two_stage_water_can_order_lifecycle_notifies_owner_and_completes_cleanly(): void
    {
        $driver = User::where('name', 'driver')->firstOrFail();
        $driverToken = $driver->createToken('test-can-order-lifecycle')->plainTextToken;

        $custGroupId = (int) (DB::table('customer_groups')->value('id') ?? 1);
        $customerId = (int) DB::table('customers')->insertGetId([
            'company_id' => 3,
            'customer_group_id' => $custGroupId,
            'name' => 'Sri Ganesh Departmental Store ' . uniqid(),
            'phone_number' => '9842177901',
            'latitude' => 11.0182210,
            'longitude' => 76.9641190,
            'credit_limit' => 5000.0,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Even before any route delivery row exists, delivery boy can list this newly active DK Waters customer
        $custList = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/customers?limit=100');
        $custList->assertStatus(200);
        $this->assertTrue(
            collect($custList->json('data'))->contains('id', $customerId),
            'Delivery driver must see all active company-scoped DK Waters customers when booking orders.'
        );

        $admin = User::where('name', 'admin')->firstOrFail();
        $adminToken = $admin->createToken('test-admin-revenue-check')->plainTextToken;

        $beforeRevRes = $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/dashboard/admin');
        $beforeRevRes->assertStatus(200);
        $beforeRevenue = (float) $beforeRevRes->json('data.dk_waters.revenue');
        $this->flushHeaders();

        // Stage 1: Delivery boy books 7 cans order before moving -> notifies Owner
        $createRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson('/api/v1/water/can-orders', [
                'customer_id' => $customerId,
                'ordered_cans' => 7,
                'payment_mode' => 'Cash',
                'can_rate' => 40,
                'order_notes' => 'Customer requested 7 cans morning batch',
            ]);

        $createRes->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.ordered_cans', 7)
            ->assertJsonPath('data.status', 'ordered')
            ->assertJsonPath('data.cans_delivered', 0);

        $orderId = (int) $createRes->json('data.order_id');
        $orderNo = (string) $createRes->json('data.order_no');
        $this->assertGreaterThan(0, $orderId);
        $this->assertStringStartsWith('ORD-', $orderNo);

        // Verify Owner / Super Admin received immediate notification of Sales Order creation
        $this->assertTrue(
            DB::table('notifications')
                ->where('notifiable_id', 1)
                ->where('data', 'like', "%Sales Order Created: 7 Cans%")
                ->exists(),
            'Super Admin must receive immediate notification upon order creation.'
        );

        // Open orders appear in /water/can-orders and /mobile/driver/manifest -> pending_orders
        // and MUST NOT pollute revenue yet
        $openOrdersRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/water/can-orders');
        $openOrdersRes->assertStatus(200);
        $this->assertTrue(collect($openOrdersRes->json('data'))->contains('id', $orderId));

        $manifestRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/driver/manifest');
        $manifestRes->assertStatus(200);
        $this->assertTrue(collect($manifestRes->json('data.pending_orders'))->contains('id', $orderId));

        $midRevRes = $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/dashboard/admin');
        $midRevRes->assertStatus(200);
        $midRevenue = (float) $midRevRes->json('data.dk_waters.revenue');
        $this->assertEquals($beforeRevenue, $midRevenue, 'Open unclosed order must not inflate revenue.');

        // Stage 2: Driver starts moving -> status in_transit & owner notified
        $startRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/can-orders/{$orderId}/start", [
                'latitude' => 11.0182210,
                'longitude' => 76.9641190,
            ]);
        $startRes->assertStatus(200)->assertJsonPath('data.status', 'in_transit');

        $this->assertTrue(
            DB::table('notifications')
                ->where('notifiable_id', 1)
                ->where('data', 'like', "%En Route: 7 Cans%")
                ->exists(),
            'Owner must be notified when delivery boy starts moving.'
        );

        // Stage 3: Driver closes order at customer location (delivered 5 instead of 7 -> checks variance alert too)
        $closeRes = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->postJson("/api/v1/water/can-orders/{$orderId}/close", [
                'cans_delivered' => 5,
                'empty_cans_returned' => 5,
                'can_rate' => 40,
                'master_rate' => 40,
                'payment_mode' => 'Cash',
                'paid_amount' => 200,
                'delivery_lat' => 11.0182210,
                'delivery_lng' => 76.9641190,
                'enforce_anti_cheat' => true,
            ]);

        $closeRes->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.order_id', $orderId)
            ->assertJsonPath('data.ordered_cans', 7)
            ->assertJsonPath('data.cans_delivered', 5)
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.qty_variance', -2);

        $this->assertTrue(
            DB::table('notifications')
                ->where('data', 'like', "%Order Qty Variance ({$orderNo})%")
                ->exists(),
            'Owner must be alerted when delivered cans differ from ordered cans.'
        );

        $afterRevRes = $this->withHeader('Authorization', "Bearer {$adminToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/mobile/dashboard/admin');
        $afterRevRes->assertStatus(200);
        $afterRevenue = (float) $afterRevRes->json('data.dk_waters.revenue');
        $this->assertEqualsWithDelta($beforeRevenue + 200.0, $afterRevenue, 0.01);

        // Order is no longer open
        $remainingOpen = $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '3')
            ->getJson('/api/v1/water/can-orders');
        $this->assertFalse(collect($remainingOpen->json('data'))->contains('id', $orderId));
    }

    public function test_can_orders_endpoints_enforce_vertical_isolation_and_web_portal_renders(): void
    {
        $tanker = User::where('name', 'tanker_driver')->firstOrFail();
        $tankerToken = $tanker->createToken('test-tanker-can-order-403')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$tankerToken}")
            ->postJson('/api/v1/water/can-orders', ['ordered_cans' => 7])
            ->assertStatus(403);

        $driver = User::where('name', 'driver')->firstOrFail();
        $driverToken = $driver->createToken('test-driver-cross-co-403')->plainTextToken;

        // Cross-vertical header spoofing blocked
        $this->withHeader('Authorization', "Bearer {$driverToken}")
            ->withHeader('X-Company-ID', '2')
            ->postJson('/api/v1/water/can-orders', ['ordered_cans' => 7])
            ->assertStatus(403);

        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $webRes = $this->actingAs($driver)->get('/dashboard');
        $webRes->assertStatus(200);
        $webRes->assertSee('Open Can Orders');
        $webRes->assertSee('Create Order');
        $webRes->assertSee('Create Sales Order &amp; Notify Owner', false);
    }
}
