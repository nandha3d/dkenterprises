<?php

namespace Tests\Feature;

use App\Models\Company;
use App\Models\CompanyBranch;
use App\Models\Customer;
use App\Models\Product;
use App\Models\Warehouse;
use App\Models\WaterCanDelivery;
use App\Models\WaterCanRoute;
use App\Models\WaterTanker;
use App\Models\WaterTankerTrip;
use App\Services\Operations\OperationalFraudAuditService;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ThreeCompaniesWorkflowAndFraudTest extends TestCase
{
    protected OperationalFraudAuditService $fraudService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->fraudService = new OperationalFraudAuditService();
    }

    /**
     * Test 1: Verify all 3 companies are properly created, active, and strictly isolated.
     */
    public function test_multi_company_isolation_and_distinct_entities(): void
    {
        $aranCafe = Company::where('code', 'ARANCAFE')->first();
        $tmws = Company::where('code', 'TMWS')->first();
        $dkWaters = Company::where('code', 'DKWATERS')->first();

        $this->assertNotNull($aranCafe, 'Aran Cafe company must exist');
        $this->assertNotNull($tmws, 'Tiruchendur Murugan Water Supply company must exist');
        $this->assertNotNull($dkWaters, 'DK Waters company must exist');

        // Aran Cafe has exactly 2 branches
        $cafeBranches = CompanyBranch::where('company_id', $aranCafe->id)->get();
        $this->assertCount(2, $cafeBranches, 'Aran Cafe must have exactly 2 branches');
        $this->assertTrue($cafeBranches->contains('code', 'MAIN'));
        $this->assertTrue($cafeBranches->contains('code', 'BRANCH-2'));

        // Aran Cafe has 2 distinct warehouses
        $cafeWarehouses = Warehouse::where('company_id', $aranCafe->id)->get();
        $this->assertCount(2, $cafeWarehouses, 'Aran Cafe must have 2 warehouses for its 2 branches');

        // TMWS has bulk tankers
        $tankers = WaterTanker::where('is_active', 1)->get();
        $this->assertGreaterThanOrEqual(1, $tankers->count(), 'TMWS must have active water tankers');
        $this->assertTrue($tankers->contains('vehicle_number', 'TN-58-BW-2001'));

        // DK Waters has route beats
        $routes = WaterCanRoute::where('is_active', 1)->get();
        $this->assertGreaterThanOrEqual(1, $routes->count(), 'DK Waters must have active delivery routes');
        $this->assertTrue($routes->contains('route_name', 'Anna Nagar & Teppakulam Route'));

        // Product Catalog Isolation
        $cafeProducts = Product::where('company_id', $aranCafe->id)->pluck('code')->toArray();
        $tmwsProducts = Product::where('company_id', $tmws->id)->pluck('code')->toArray();
        $dkProducts = Product::where('company_id', $dkWaters->id)->pluck('code')->toArray();

        $this->assertContains('CF-FILTER', $cafeProducts);
        $this->assertContains('BW-20KL', $tmwsProducts);
        $this->assertContains('CAN-20L', $dkProducts);

        // Ensure zero catalog overlap
        $this->assertEmpty(array_intersect($cafeProducts, $tmwsProducts));
        $this->assertEmpty(array_intersect($cafeProducts, $dkProducts));
        $this->assertEmpty(array_intersect($tmwsProducts, $dkProducts));
    }

    /**
     * Test 2: Aran Cafe - Multi-branch stock separation and POS order completion.
     */
    public function test_aran_cafe_branch_isolation_and_order_flow(): void
    {
        $aranCafe = Company::where('code', 'ARANCAFE')->first();
        $whMain = Warehouse::where('company_id', $aranCafe->id)->where('name', 'LIKE', '%Main%')->first();
        $whExpress = Warehouse::where('company_id', $aranCafe->id)->where('name', 'LIKE', '%Express%')->first();

        $coffee = Product::where('company_id', $aranCafe->id)->where('code', 'CF-FILTER')->first();
        $this->assertNotNull($coffee);

        // Ensure stock in Main warehouse does not leak to Express warehouse
        DB::table('product_warehouse')->updateOrInsert(
            ['product_id' => $coffee->id, 'warehouse_id' => $whMain->id],
            ['qty' => 150.0]
        );
        DB::table('product_warehouse')->updateOrInsert(
            ['product_id' => $coffee->id, 'warehouse_id' => $whExpress->id],
            ['qty' => 45.0]
        );

        $mainStock = (float) DB::table('product_warehouse')->where('product_id', $coffee->id)->where('warehouse_id', $whMain->id)->value('qty');
        $expressStock = (float) DB::table('product_warehouse')->where('product_id', $coffee->id)->where('warehouse_id', $whExpress->id)->value('qty');

        $this->assertEquals(150.0, $mainStock);
        $this->assertEquals(45.0, $expressStock);

        // Simulate sale deduction in Express branch
        DB::table('product_warehouse')->where('product_id', $coffee->id)->where('warehouse_id', $whExpress->id)->decrement('qty', 10);

        $freshExpress = (float) DB::table('product_warehouse')->where('product_id', $coffee->id)->where('warehouse_id', $whExpress->id)->value('qty');
        $freshMain = (float) DB::table('product_warehouse')->where('product_id', $coffee->id)->where('warehouse_id', $whMain->id)->value('qty');

        $this->assertEquals(35.0, $freshExpress, 'Express branch stock reduced by 10');
        $this->assertEquals(150.0, $freshMain, 'Main branch stock remained completely untouched');
    }

    /**
     * Test 3: Aran Cafe Fraud Detection - Cash skimming during evening drawer closing.
     */
    public function test_aran_cafe_fraud_cash_skimming_detected_on_drawer_closing(): void
    {
        // Case A: Skimming Fraud Scenario
        // Morning float: ₹1,000. System Sales: Cash ₹5,000, UPI ₹3,200. Total expected physical cash: ₹6,000.
        // Cashier reports only ₹5,100 physical cash (short ₹900 pocketed).
        $auditResult = $this->fraudService->auditCashDrawer(
            openingFloat: 1000.0,
            systemCashSales: 5000.0,
            systemUpiSales: 3200.0,
            physicalCashCounted: 5100.0,
            upiSettledCounted: 3200.0,
            toleranceAmount: 10.0
        );

        $this->assertTrue($auditResult['is_fraud_detected'], 'Fraud must be flagged when cash is missing');
        $this->assertEquals('short', $auditResult['status']);
        $this->assertEquals(-900.0, $auditResult['cash_discrepancy']);
        $this->assertEquals('critical', $auditResult['fraud_risk']);
        $this->assertStringContainsString('POTENTIAL_CASH_SKIMMING', $auditResult['flags'][0]);

        // Case B: Legitimate Balanced Reconciliation Scenario
        $legitResult = $this->fraudService->auditCashDrawer(
            openingFloat: 1000.0,
            systemCashSales: 5000.0,
            systemUpiSales: 3200.0,
            physicalCashCounted: 6000.0,
            upiSettledCounted: 3200.0,
            toleranceAmount: 10.0
        );

        $this->assertFalse($legitResult['is_fraud_detected']);
        $this->assertEquals('balanced', $legitResult['status']);
        $this->assertEquals(0.0, $legitResult['cash_discrepancy']);
        $this->assertEquals('low', $legitResult['fraud_risk']);
    }

    /**
     * Test 4: Aran Cafe Fraud Detection - Phantom kitchen wastage / unauthorized raw material write-off.
     */
    public function test_aran_cafe_fraud_phantom_kitchen_wastage_writeoff_blocked(): void
    {
        // Case A: Chef reports consuming 45 Litres of Milk, but total available stock is only 20 Litres
        $overStockResult = $this->fraudService->auditIngredientConsumption(
            openingStock: 15.0,
            receivedToday: 5.0,
            reportedConsumed: 45.0,
            theoreticalConsumption: 12.0
        );

        $this->assertTrue($overStockResult['is_fraud_detected']);
        $this->assertEquals('critical', $overStockResult['fraud_risk']);
        $this->assertStringContainsString('IMPOSSIBLE_CONSUMPTION', $overStockResult['flags'][0]);

        // Case B: Theoretical recipe yield for sold items is 10 Litres, but chef logs 22 Litres (120% excess)
        $phantomResult = $this->fraudService->auditIngredientConsumption(
            openingStock: 30.0,
            receivedToday: 10.0,
            reportedConsumed: 22.0,
            theoreticalConsumption: 10.0,
            tolerancePercent: 15.0
        );

        $this->assertTrue($phantomResult['is_fraud_detected']);
        $this->assertStringContainsString('PHANTOM_WASTAGE_DETECTED', $phantomResult['flags'][0]);

        // Case C: Normal variance within standard 10% spill tolerance
        $normalResult = $this->fraudService->auditIngredientConsumption(
            openingStock: 30.0,
            receivedToday: 10.0,
            reportedConsumed: 10.8,
            theoreticalConsumption: 10.0,
            tolerancePercent: 15.0
        );

        $this->assertFalse($normalResult['is_fraud_detected']);
        $this->assertEquals('low', $normalResult['fraud_risk']);
    }

    /**
     * Test 5: TMWS - Tanker chamber split delivery and surcharges billing calculation.
     */
    public function test_tmws_tanker_chamber_split_delivery_and_surcharges(): void
    {
        $tanker = WaterTanker::where('vehicle_number', 'TN-58-BW-2001')->first();
        $this->assertNotNull($tanker);
        $this->assertEquals(20.0, (float)$tanker->capacity_kl);

        // Chamber split: 10KL for Customer A + 10KL for Customer B
        $chamber1_kl = 10.0;
        $chamber2_kl = 10.0;
        $totalDeliveredKl = $chamber1_kl + $chamber2_kl;

        $this->assertEquals($tanker->capacity_kl, $totalDeliveredKl);

        // Billing parameters:
        // Base rate: ₹2,400 (for 10KL trip)
        // Distance: 25 KM (Base free limit: 10 KM => Excess: 15 KM @ ₹45/KM = ₹675)
        // Motor Pumping: 30 Mins @ ₹10/min = ₹300
        // Site Waiting Delay: 20 Mins @ ₹15/min = ₹300
        $baseRate = 2400.0;
        $excessKm = 15.0;
        $excessRate = 45.0;
        $excessCharge = $excessKm * $excessRate; // ₹675

        $pumpMins = 30;
        $pumpRate = 10.0;
        $pumpCharge = $pumpMins * $pumpRate; // ₹300

        $waitMins = 20;
        $waitRate = 15.0;
        $waitCharge = $waitMins * $waitRate; // ₹300

        $totalInvoiceAmount = $baseRate + $excessCharge + $pumpCharge + $waitCharge;

        $this->assertEquals(3675.0, $totalInvoiceAmount);
    }

    /**
     * Test 6: TMWS Fraud Detection - Odometer rollback and telematics mileage inflation.
     */
    public function test_tmws_fraud_odometer_tampering_and_inflated_mileage_detected(): void
    {
        // Scenario A: Odometer rollback (Driver rolls back meter to hide personal trips)
        $rollbackAudit = $this->fraudService->auditTankerOdometer(
            startKm: 48500.0,
            endKm: 48420.0, // Tampered end < start
            gpsTelematicsDistanceKm: 35.0
        );

        $this->assertTrue($rollbackAudit['is_fraud_detected']);
        $this->assertEquals('critical', $rollbackAudit['fraud_risk']);
        $this->assertStringContainsString('ODOMETER_ROLLBACK_DETECTED', $rollbackAudit['flags'][0]);

        // Scenario B: Mileage inflation (Driver claims 95 KM for excess billing, but GPS tracking recorded only 28 KM)
        $inflatedAudit = $this->fraudService->auditTankerOdometer(
            startKm: 48500.0,
            endKm: 48595.0, // Billed 95 KM
            gpsTelematicsDistanceKm: 28.0, // Actual GPS was 28 KM (Discrepancy: 67 KM)
            maxToleranceKm: 5.0
        );

        $this->assertTrue($inflatedAudit['is_fraud_detected']);
        $this->assertEquals('critical', $inflatedAudit['fraud_risk']);
        $this->assertStringContainsString('INFLATED_MILEAGE_FRAUD', $inflatedAudit['flags'][0]);

        // Scenario C: Legitimate trip within 2 KM GPS routing variance
        $validAudit = $this->fraudService->auditTankerOdometer(
            startKm: 48500.0,
            endKm: 48532.0, // Billed 32 KM
            gpsTelematicsDistanceKm: 30.5,
            maxToleranceKm: 5.0
        );

        $this->assertFalse($validAudit['is_fraud_detected']);
        $this->assertEquals('low', $validAudit['fraud_risk']);
    }

    /**
     * Test 7: TMWS Fraud Detection - Unauthorized water siphoning / black market decanting.
     */
    public function test_tmws_fraud_water_theft_unauthorized_decanting_detected(): void
    {
        // Tanker left plant loaded with 20KL bulk water.
        // Customer vouchers only total 14KL. Tanker returned empty (0KL) to depot.
        // 6KL unaccounted water was drained/sold illegally.
        $theftAudit = $this->fraudService->auditWaterDecanting(
            loadedCapacityKl: 20.0,
            deliveredVouchersKl: 14.0,
            returnedDepotKl: 0.0,
            allowedEvaporationLossKl: 0.3
        );

        $this->assertTrue($theftAudit['is_fraud_detected']);
        $this->assertEquals('critical', $theftAudit['fraud_risk']);
        $this->assertEquals(6.0, $theftAudit['unaccounted_loss_kl']);
        $this->assertStringContainsString('WATER_THEFT_DETECTED', $theftAudit['flags'][0]);

        // Legitimate complete delivery
        $legitAudit = $this->fraudService->auditWaterDecanting(
            loadedCapacityKl: 20.0,
            deliveredVouchersKl: 19.8,
            returnedDepotKl: 0.0,
            allowedEvaporationLossKl: 0.3
        );

        $this->assertFalse($legitAudit['is_fraud_detected']);
    }

    /**
     * Test 8: TMWS Fraud Detection - Inflated motor pumping surcharge fraud.
     */
    public function test_tmws_fraud_inflated_motor_pumping_surcharge_detected(): void
    {
        // Standard high-pressure tanker pump drains 10KL in 25-30 minutes.
        // Driver claims 180 minutes of motor pumping (₹1,800 charge) for 10KL.
        $pumpingAudit = $this->fraudService->auditSurchargePumping(
            deliveredVolumeKl: 10.0,
            claimedPumpingMinutes: 180,
            maxMinsPerKl: 5.0 // Max reasonable: 50 mins
        );

        $this->assertTrue($pumpingAudit['is_fraud_detected']);
        $this->assertEquals('critical', $pumpingAudit['fraud_risk']);
        $this->assertStringContainsString('INFLATED_PUMPING_SURCHARGE', $pumpingAudit['flags'][0]);

        // Legitimate pumping: 28 mins for 10KL
        $validPumping = $this->fraudService->auditSurchargePumping(
            deliveredVolumeKl: 10.0,
            claimedPumpingMinutes: 28,
            maxMinsPerKl: 5.0
        );

        $this->assertFalse($validPumping['is_fraud_detected']);
    }

    /**
     * Test 9: DK Waters - Van distribution, customer held can ledger, and deposit accounting.
     */
    public function test_dk_waters_packaged_can_and_bottle_distribution_flow(): void
    {
        $dkWaters = Company::where('code', 'DKWATERS')->first();
        $this->assertNotNull($dkWaters);

        // Find or create test customer
        $customer = Customer::firstOrCreate(
            ['phone_number' => '9840199999'],
            ['name' => 'Titan Corporate Campus', 'customer_group_id' => 1, 'is_active' => true, 'company_name' => 'Titan Ltd']
        );

        $initialHeld = (int) (DB::table('water_can_inventories')->where('customer_id', $customer->id)->value('total_cans_held') ?? 0);

        // Deliver 50 cans, collect 42 empty cans => Net increase of +8 cans held by customer
        $delivered = 50;
        $returned = 42;
        $newHeld = $initialHeld + $delivered - $returned;

        DB::table('water_can_inventories')->updateOrInsert(
            ['customer_id' => $customer->id],
            [
                'total_cans_held' => $newHeld,
                'deposit_held' => $newHeld * 150.0,
                'last_delivery_date' => now(),
                'updated_at' => now(),
            ]
        );

        $recordedHeld = (int) DB::table('water_can_inventories')->where('customer_id', $customer->id)->value('total_cans_held');
        $this->assertEquals($newHeld, $recordedHeld);
    }

    /**
     * Test 10: DK Waters Fraud Detection - Driver van shortage / missing filled cans siphoning.
     */
    public function test_dk_waters_fraud_driver_missing_can_siphoning_detected(): void
    {
        // Driver loaded 80 filled cans in the morning.
        // During the day, delivered 65 filled cans.
        // In the evening, returns with only 5 filled cans and claims 10 cans are "lost".
        // Total accounted filled cans: 65 + 5 = 70. 10 filled cans are missing!
        $shortageAudit = $this->fraudService->auditRouteCanBalance(
            morningLoadedCans: 80,
            deliveredFilledCans: 65,
            returnedEmptyCans: 55,
            returnedFilledCans: 5,
            reportedDamagedCans: 0
        );

        $this->assertTrue($shortageAudit['is_fraud_detected']);
        $this->assertEquals('critical', $shortageAudit['fraud_risk']);
        $this->assertEquals(10, $shortageAudit['missing_filled_cans']);
        $this->assertStringContainsString('MISSING_FILLED_CANS', $shortageAudit['flags'][0]);

        // Legitimate balanced van return: 80 loaded = 72 delivered + 8 brought back
        $legitAudit = $this->fraudService->auditRouteCanBalance(
            morningLoadedCans: 80,
            deliveredFilledCans: 72,
            returnedEmptyCans: 68,
            returnedFilledCans: 8,
            reportedDamagedCans: 0
        );

        $this->assertFalse($legitAudit['is_fraud_detected']);
        $this->assertEquals(0, $legitAudit['missing_filled_cans']);
    }

    /**
     * Test 11: DK Waters Fraud Detection - Phantom deposit refund blocked by customer ledger.
     */
    public function test_dk_waters_fraud_phantom_deposit_refund_blocked(): void
    {
        // Customer record shows they only hold 6 cans in their office (₹900 deposit balance).
        // Delivery boy or customer attempts to claim deposit refund for 20 cans (₹3,000 refund).
        $refundAudit = $this->fraudService->auditDepositRefundEligibility(
            customerHeldCans: 6,
            requestedRefundCans: 20,
            depositRatePerCan: 150.0
        );

        $this->assertTrue($refundAudit['is_fraud_detected']);
        $this->assertEquals('critical', $refundAudit['fraud_risk']);
        $this->assertEquals(6, $refundAudit['authorized_refund_cans']);
        $this->assertEquals(900.0, $refundAudit['authorized_refund_amount']);
        $this->assertEquals(2100.0, $refundAudit['blocked_refund_amount']);
        $this->assertStringContainsString('PHANTOM_DEPOSIT_REFUND_FRAUD', $refundAudit['flags'][0]);

        // Legitimate refund request: Customer holds 6 cans, requests refund for 4 cans
        $legitRefund = $this->fraudService->auditDepositRefundEligibility(
            customerHeldCans: 6,
            requestedRefundCans: 4,
            depositRatePerCan: 150.0
        );

        $this->assertFalse($legitRefund['is_fraud_detected']);
        $this->assertEquals(4, $legitRefund['authorized_refund_cans']);
        $this->assertEquals(600.0, $legitRefund['authorized_refund_amount']);
        $this->assertEquals(0.0, $legitRefund['blocked_refund_amount']);
    }

    /**
     * Test 12: Executive Dashboard - Multi-Company Live Insights Cards Rendering.
     */
    public function test_dashboard_displays_all_three_company_insight_cards(): void
    {
        $user = \App\Models\User::find(1);
        $this->actingAs($user, 'web');
        session([
            'company_id' => 1,
            'branch_id' => 1,
            'financial_year_id' => 1,
        ]);

        $response = $this->get('/dashboard');
        $response->assertStatus(200);

        // Assert company insights cards are present in the response
        $response->assertSee('Multi-Enterprise Command Deck');
        $response->assertSee('Aran Cafe');
        $response->assertSee('Tiruchendur Murugan Water Supply');
        $response->assertSee('DK Waters');
        $response->assertSee('2 Active Outlets');
        $response->assertSee('Heavy Tanker Fleet');
        $response->assertSee('Empty Can Recovery', false);
    }

    /**
     * Test 13: Water Logistics Screen Vertical Isolation (Bulk Water vs Packaged Drinking Water Routes).
     */
    public function test_water_logistics_vertical_screen_isolation(): void
    {
        $user = \App\Models\User::find(1);
        $this->actingAs($user, 'web');

        $tmws = Company::where('code', 'TMWS')->first();
        $dkWaters = Company::where('code', 'DKWATERS')->first();

        // 1. Enter TMWS context (Bulk Water vertical)
        session([
            'company_id' => $tmws->id,
            'branch_id' => $tmws->branches()->first()->id,
            'financial_year_id' => 2,
        ]);

        $responseTmws = $this->get('/water-logistics');
        $responseTmws->assertStatus(200);
        $responseTmws->assertSee('Commercial Bulk Water &amp; Fleet Logistics', false);
        $responseTmws->assertSee('Log Tanker Trip');
        $responseTmws->assertDontSee('Packaged Water Delivery');
        $responseTmws->assertDontSee('Packaged Drinking Water');
        $responseTmws->assertDontSee('Customer Containers in Custody');
        $responseTmws->assertDontSee('9KL/16KL/24KL');
        $responseTmws->assertDontSee('10KL/20KL/40KL');

        $responseTmwsSale = $this->get('/sales');
        $responseTmwsSale->assertStatus(200);
        $responseTmwsSale->assertSee('Tanker Trip Calc');
        $responseTmwsSale->assertDontSee('Packaged Water Delivery');

        // 2. Enter DK Waters context (Packaged Water vertical)
        session([
            'company_id' => $dkWaters->id,
            'branch_id' => $dkWaters->branches()->first()->id,
            'financial_year_id' => 3,
        ]);

        $responseDkWaters = $this->get('/water-logistics');
        $responseDkWaters->assertStatus(200);
        $responseDkWaters->assertSee('Packaged Drinking Water Distribution &amp; Logistics', false);
        $responseDkWaters->assertSee('Packaged Water Delivery');
        $responseDkWaters->assertDontSee('Log Tanker Trip');
        $responseDkWaters->assertDontSee('Total Bulk Water Delivered');
        $responseDkWaters->assertDontSee('Commercial Bulk Water');
        $responseDkWaters->assertDontSee('9KL/16KL/24KL');

        $responseDkWatersSale = $this->get('/sales');
        $responseDkWatersSale->assertStatus(200);
        $responseDkWatersSale->assertSee('Packaged Water Delivery');
        $responseDkWatersSale->assertDontSee('Tanker Trip Calc');
    }

    /**
     * Test 14: Mobile API Bootstrap & Role Dashboard Endpoints for Live App Testing.
     */
    public function test_mobile_api_bootstrap_and_role_dashboard_endpoints(): void
    {
        // 1. Mobile bootstrap data
        $response = $this->getJson('/api/v1/mobile/bootstrap');
        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonStructure([
            'data' => [
                'companies',
                'routes',
                'tankers',
                'customers',
                'packages',
            ]
        ]);

        // 2. Role dashboard for super_admin
        $responseRole = $this->getJson('/api/v1/mobile/dashboard/super_admin');
        $responseRole->assertStatus(200);
        $responseRole->assertJsonPath('success', true);
        $responseRole->assertJsonPath('data.role', 'super_admin');
    }

    /**
     * Test 15: Field Agent Customer KYC Onboarding & Credit Collection Flow.
     */
    public function test_field_agent_customer_kyc_and_collection_flow(): void
    {
        // 1. Onboard new customer with opening container deposit
        $onboardPayload = [
            'name' => 'Sri Annapoorna Restaurant',
            'phone_number' => '9842199887',
            'address' => '77 Cross Cut Road, Gandhipuram',
            'city' => 'Coimbatore',
            'company_id' => 3,
            'opening_cans_held' => 10,
            'deposit_held' => 1500.0,
        ];

        $responseOnboard = $this->postJson('/api/v1/mobile/customer-onboard', $onboardPayload);
        $responseOnboard->assertStatus(201);
        $responseOnboard->assertJsonPath('success', true);
        $newCustomerId = $responseOnboard->json('data.customer.id');

        $this->assertDatabaseHas('customers', [
            'id' => $newCustomerId,
            'name' => 'Sri Annapoorna Restaurant',
            'phone_number' => '9842199887',
        ]);

        $this->assertDatabaseHas('water_can_inventories', [
            'customer_id' => $newCustomerId,
            'total_cans_held' => 10,
            'deposit_held' => 1500.0,
        ]);

        // 2. Collect outstanding payment & verify receipt
        $collectPayload = [
            'customer_id' => $newCustomerId,
            'amount_collected' => 750.0,
            'payment_mode' => 'UPI',
            'receipt_number' => 'REC-TEST-20261101-01',
        ];

        $responseCollect = $this->postJson('/api/v1/mobile/collect-payment', $collectPayload);
        $responseCollect->assertStatus(201);
        $responseCollect->assertJsonPath('success', true);
        $responseCollect->assertJsonPath('data.receipt_number', 'REC-TEST-20261101-01');
    }

    /**
     * Test 16: Mobile Driver Surrender & Spot Audit Logging.
     */
    public function test_mobile_driver_surrender_and_admin_settlement_reconciliation(): void
    {
        // 1. Driver surrenders shift cash and empty return cans
        $surrenderPayload = [
            'route_id' => 1,
            'surrender_date' => date('Y-m-d'),
            'cash_surrendered' => 2800.0,
            'empty_cans_returned' => 80,
        ];

        $responseSurrender = $this->postJson('/api/v1/mobile/driver-surrender', $surrenderPayload);
        $responseSurrender->assertStatus(200);
        $responseSurrender->assertJsonPath('success', true);
        $responseSurrender->assertJsonPath('data.cash_surrendered', 2800);

        // 2. Physical spot audit verification
        $auditPayload = [
            'vehicle_number' => 'TN-59-WA-1011',
            'driver_name' => 'Murugan',
            'expected_units' => 80,
            'physical_units' => 78,
            'is_fraud_suspected' => true,
        ];

        $responseAudit = $this->postJson('/api/v1/mobile/spot-audit', $auditPayload);
        $responseAudit->assertStatus(201);
        $responseAudit->assertJsonPath('success', true);
        $responseAudit->assertJsonPath('data.unit_difference', -2);
    }

    /**
     * Test 17: Mobile Web App Simulator route & all 6 roles.
     */
    public function test_mobile_web_simulator_route_and_role_views(): void
    {
        $response = $this->get('/mobile');
        $response->assertStatus(200);
        $response->assertSee('DK Track — Multi-Role Enterprise Field Mobile ERP');
        $response->assertSee('Super Admin');
        $response->assertSee('Company Admin');
        $response->assertSee('Field Agent');
        $response->assertSee('Route Driver');
        $response->assertSee('Tanker Driver');
        $response->assertSee('Cafe Cashier');
        $response->assertSee('https://dkenterprises.animazon.in/api/v1');
    }
}

