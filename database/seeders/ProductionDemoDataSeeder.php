<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ProductionDemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $today = now()->toDateString();
        $now = now();

        // ---------------------------------------------------------
        // 1. Aran Cafe (Company 1)
        // ---------------------------------------------------------
        // Update Accounts
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 1, 'name' => 'Cash in Hand'],
            ['account_no' => 'ARANCAFE-CASH', 'total_balance' => 14200.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 1, 'name' => 'HDFC Current Bank'],
            ['account_no' => 'ARANCAFE-BANK', 'total_balance' => 45500.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );

        // Sales for Aran Cafe
        $customerWalkIn = DB::table('customers')->where('company_id', 1)->value('id')
            ?? DB::table('customers')->first()->id;

        $wh1 = DB::table('warehouses')->where('company_id', 1)->value('id') ?? 1;

        $billerId = DB::table('billers')->where('company_id', 1)->value('id');
        if (!$billerId) {
            $billerId = DB::table('billers')->insertGetId([
                'name' => 'Aran Cafe Billing Desk',
                'company_name' => 'Aran Cafe Private Limited',
                'email' => 'billing@arancafe.com',
                'phone_number' => '9842100001',
                'address' => 'Main Cafe, Madurai',
                'city' => 'Madurai',
                'company_id' => 1,
                'is_active' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        $cafeSales = [
            ['reference_no' => 'POS-2026-001', 'grand_total' => 2800.00, 'paid_amount' => 2800.00, 'paying_method' => 'Cash'],
            ['reference_no' => 'POS-2026-002', 'grand_total' => 2950.00, 'paid_amount' => 2950.00, 'paying_method' => 'UPI'],
            ['reference_no' => 'POS-2026-003', 'grand_total' => 5000.00, 'paid_amount' => 5000.00, 'paying_method' => 'Cash'],
            ['reference_no' => 'POS-2026-004', 'grand_total' => 7700.00, 'paid_amount' => 5600.00, 'paying_method' => 'Cash'], // 2100 receivable
        ];

        foreach ($cafeSales as $cs) {
            $existing = DB::table('sales')->where('company_id', 1)->where('reference_no', $cs['reference_no'])->first();
            if (!$existing) {
                $saleId = DB::table('sales')->insertGetId([
                    'reference_no' => $cs['reference_no'],
                    'user_id' => 1,
                    'customer_id' => $customerWalkIn,
                    'biller_id' => $billerId,
                    'warehouse_id' => $wh1,
                    'item' => 2,
                    'total_qty' => 4,
                    'total_discount' => 0,
                    'total_tax' => 0,
                    'total_price' => $cs['grand_total'],
                    'grand_total' => $cs['grand_total'],
                    'order_tax_rate' => 0,
                    'order_tax' => 0,
                    'order_discount' => 0,
                    'shipping_cost' => 0,
                    'sale_status' => 1,
                    'payment_status' => $cs['paid_amount'] == $cs['grand_total'] ? 4 : 2,
                    'paid_amount' => $cs['paid_amount'],
                    'company_id' => 1,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);

                DB::table('payments')->insert([
                    'payment_reference' => 'SPAY-' . $cs['reference_no'],
                    'user_id' => 1,
                    'sale_id' => $saleId,
                    'account_id' => 1,
                    'amount' => $cs['paid_amount'],
                    'change' => 0,
                    'paying_method' => $cs['paying_method'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }

        // Expenses for Aran Cafe
        $catDairy = DB::table('expense_categories')->where('name', 'Kitchen Dairy & Ingredients')->value('id')
            ?? DB::table('expense_categories')->insertGetId(['code' => 'EXP-DAIRY', 'name' => 'Kitchen Dairy & Ingredients', 'is_active' => 1]);

        if (!DB::table('expenses')->where('company_id', 1)->exists()) {
            DB::table('expenses')->insert([
                [
                    'reference_no' => 'EXP-2026-001',
                    'expense_category_id' => $catDairy,
                    'warehouse_id' => $wh1,
                    'account_id' => 1,
                    'user_id' => 1,
                    'amount' => 2200.00,
                    'company_id' => 1,
                    'note' => 'Fresh Dairy Milk Purchase (40L)',
                    'created_at' => $now,
                    'updated_at' => $now,
                ],
                [
                    'reference_no' => 'EXP-2026-002',
                    'expense_category_id' => $catDairy,
                    'warehouse_id' => $wh1,
                    'account_id' => 1,
                    'user_id' => 1,
                    'amount' => 1125.00,
                    'company_id' => 1,
                    'note' => 'White Cane Sugar Stock (25kg)',
                    'created_at' => $now,
                    'updated_at' => $now,
                ],
            ]);
        }

        // ---------------------------------------------------------
        // 2. Tiruchendur Murugan Water Supply (Company 2)
        // ---------------------------------------------------------
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 2, 'name' => 'Cash in Hand'],
            ['account_no' => 'TMWS-CASH', 'total_balance' => 18500.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 2, 'name' => 'SBI Corporate Account'],
            ['account_no' => 'TMWS-BANK', 'total_balance' => 82000.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );

        if (Schema::hasTable('water_tankers') && !DB::table('water_tankers')->exists()) {
            DB::table('water_tankers')->insert([
                ['vehicle_number' => 'TN-58-BW-2001', 'capacity_kl' => 20.0, 'driver_name' => 'Murugan S.', 'driver_phone' => '9842111201', 'is_active' => 1, 'current_odometer_km' => 45200, 'created_at' => $now, 'updated_at' => $now],
                ['vehicle_number' => 'TN-58-BW-4001', 'capacity_kl' => 40.0, 'driver_name' => 'Selvam K.', 'driver_phone' => '9842144001', 'is_active' => 1, 'current_odometer_km' => 78900, 'created_at' => $now, 'updated_at' => $now],
                ['vehicle_number' => 'TN-58-BW-1001', 'capacity_kl' => 10.0, 'driver_name' => 'Arumugam P.', 'driver_phone' => '9842110001', 'is_active' => 1, 'current_odometer_km' => 24100, 'created_at' => $now, 'updated_at' => $now],
            ]);
        }

        if (Schema::hasTable('water_tanker_trips') && !DB::table('water_tanker_trips')->exists()) {
            DB::table('water_tanker_trips')->insert([
                ['trip_number' => 'TMWS-TRIP-2026-001', 'tanker_id' => 1, 'customer_id' => 3, 'trip_date' => $today, 'source_plant' => 'Borewell Plant 1 (Perundurai)', 'destination_site' => 'Texvalley Commercial Complex', 'water_quantity_kl' => 20.0, 'trip_rate' => 3500.0, 'diesel_expense' => 850.0, 'toll_expense' => 120.0, 'driver_batta' => 250.0, 'site_receiver_name' => 'K. Ramanathan', 'status' => 'completed', 'created_at' => $now, 'updated_at' => $now],
                ['trip_number' => 'TMWS-TRIP-2026-002', 'tanker_id' => 2, 'customer_id' => 4, 'trip_date' => $today, 'source_plant' => 'Borewell Plant 2 (Erode)', 'destination_site' => 'The Chennai Silks (Dyeing Unit)', 'water_quantity_kl' => 40.0, 'trip_rate' => 6800.0, 'diesel_expense' => 1400.0, 'toll_expense' => 180.0, 'driver_batta' => 350.0, 'site_receiver_name' => 'M. Palanisamy', 'status' => 'completed', 'created_at' => $now, 'updated_at' => $now],
                ['trip_number' => 'TMWS-TRIP-2026-003', 'tanker_id' => 1, 'customer_id' => 2, 'trip_date' => $today, 'source_plant' => 'Borewell Plant 1 (Perundurai)', 'destination_site' => 'Titan Corporate Campus', 'water_quantity_kl' => 20.0, 'trip_rate' => 3500.0, 'diesel_expense' => 850.0, 'toll_expense' => 120.0, 'driver_batta' => 250.0, 'site_receiver_name' => 'S. Vijay', 'status' => 'completed', 'created_at' => $now, 'updated_at' => $now],
                ['trip_number' => 'TMWS-TRIP-2026-004', 'tanker_id' => 3, 'customer_id' => 5, 'trip_date' => $today, 'source_plant' => 'Borewell Plant 1 (Perundurai)', 'destination_site' => 'Aran Cafe - Central Kitchen', 'water_quantity_kl' => 10.0, 'trip_rate' => 1800.0, 'diesel_expense' => 400.0, 'toll_expense' => 0.0, 'driver_batta' => 200.0, 'site_receiver_name' => 'R. Vignesh', 'status' => 'completed', 'created_at' => $now, 'updated_at' => $now],
            ]);
        }

        // ---------------------------------------------------------
        // 3. DK Waters (Company 3)
        // ---------------------------------------------------------
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 3, 'name' => 'Cash in Hand'],
            ['account_no' => 'DKWATERS-CASH', 'total_balance' => 12800.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 3, 'name' => 'ICICI Current Account'],
            ['account_no' => 'DKWATERS-BANK', 'total_balance' => 38400.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );

        if (Schema::hasTable('water_can_routes') && !DB::table('water_can_routes')->exists()) {
            DB::table('water_can_routes')->insert([
                ['route_name' => 'Perundurai Commercial Beat #1', 'vehicle_no' => 'TN-58-WA-101 (Tata Ace)', 'driver_name' => 'Kumar R.', 'driver_phone' => '9842155101', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
                ['route_name' => 'Erode Tech Park & Ring Road Beat #2', 'vehicle_no' => 'TN-58-WA-102 (Tata Ace)', 'driver_name' => 'Manikandan V.', 'driver_phone' => '9842155102', 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now],
            ]);
        }

        if (Schema::hasTable('water_can_deliveries') && !DB::table('water_can_deliveries')->exists()) {
            DB::table('water_can_deliveries')->insert([
                ['delivery_no' => 'DKW-DEL-2026-001', 'delivery_date' => $today, 'route_id' => 1, 'customer_id' => 5, 'morning_loaded_cans' => 96, 'cans_delivered' => 25, 'empty_cans_returned' => 20, 'can_rate' => 35.0, 'total_amount' => 875.0, 'paid_amount' => 875.0, 'payment_mode' => 'Cash', 'balance_cans_held' => 35, 'status' => 'delivered', 'created_at' => $now, 'updated_at' => $now],
                ['delivery_no' => 'DKW-DEL-2026-002', 'delivery_date' => $today, 'route_id' => 1, 'customer_id' => 2, 'morning_loaded_cans' => 96, 'cans_delivered' => 50, 'empty_cans_returned' => 45, 'can_rate' => 35.0, 'total_amount' => 1750.0, 'paid_amount' => 1750.0, 'payment_mode' => 'UPI', 'balance_cans_held' => 120, 'status' => 'delivered', 'created_at' => $now, 'updated_at' => $now],
                ['delivery_no' => 'DKW-DEL-2026-003', 'delivery_date' => $today, 'route_id' => 2, 'customer_id' => 3, 'morning_loaded_cans' => 110, 'cans_delivered' => 40, 'empty_cans_returned' => 38, 'can_rate' => 35.0, 'total_amount' => 1400.0, 'paid_amount' => 1400.0, 'payment_mode' => 'Corporate Credit', 'balance_cans_held' => 85, 'status' => 'delivered', 'created_at' => $now, 'updated_at' => $now],
                ['delivery_no' => 'DKW-DEL-2026-004', 'delivery_date' => $today, 'route_id' => 2, 'customer_id' => 4, 'morning_loaded_cans' => 110, 'cans_delivered' => 30, 'empty_cans_returned' => 30, 'can_rate' => 35.0, 'total_amount' => 1050.0, 'paid_amount' => 1050.0, 'payment_mode' => 'UPI', 'balance_cans_held' => 60, 'status' => 'delivered', 'created_at' => $now, 'updated_at' => $now],
            ]);
        }

        if (Schema::hasTable('water_can_inventories') && !DB::table('water_can_inventories')->exists()) {
            DB::table('water_can_inventories')->insert([
                ['customer_id' => 2, 'total_cans_held' => 120, 'deposit_held' => 18000.00, 'deposit_rate_per_can' => 150.00, 'last_delivered_at' => $now, 'created_at' => $now, 'updated_at' => $now],
                ['customer_id' => 3, 'total_cans_held' => 85, 'deposit_held' => 12750.00, 'deposit_rate_per_can' => 150.00, 'last_delivered_at' => $now, 'created_at' => $now, 'updated_at' => $now],
                ['customer_id' => 4, 'total_cans_held' => 60, 'deposit_held' => 9000.00, 'deposit_rate_per_can' => 150.00, 'last_delivered_at' => $now, 'created_at' => $now, 'updated_at' => $now],
                ['customer_id' => 5, 'total_cans_held' => 35, 'deposit_held' => 5250.00, 'deposit_rate_per_can' => 150.00, 'last_delivered_at' => $now, 'created_at' => $now, 'updated_at' => $now],
            ]);
        }

        // ---------------------------------------------------------
        // 4. zoloERP Textiles (Company 4)
        // ---------------------------------------------------------
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 4, 'name' => 'Cash in Hand'],
            ['account_no' => 'ZTEX-CASH', 'total_balance' => 35000.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );
        DB::table('accounts')->updateOrInsert(
            ['company_id' => 4, 'name' => 'Indian Bank Current A/c'],
            ['account_no' => 'ZTEX-BANK', 'total_balance' => 150000.00, 'is_active' => 1, 'created_at' => $now, 'updated_at' => $now]
        );
    }
}
