<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Services\Platform\CompanyDirectoryService;
use App\Models\Company;
use App\Models\CompanyBranch;

class ThreeCompaniesSeeder extends Seeder
{
    public function run(): void
    {
        DB::statement('SET FOREIGN_KEY_CHECKS = 0;');

        $companyTables = [
            'sales', 'product_sales', 'sale_drafts',
            'purchases', 'product_purchases',
            'returns', 'product_returns', 'return_purchases', 'purchase_product_return',
            'stock_movements', 'stock_movement_lines',
            'journal_entries', 'journal_items', 'account_allocations', 'account_open_items',
            'products', 'product_warehouse', 'product_batches', 'product_variants',
            'customers', 'suppliers',
            'warehouses', 'billers', 'agents', 'areas', 'bill_sundries', 'categories',
            'document_series', 'fiscal_years', 'chart_of_accounts', 'semantic_account_mappings',
            'sale_types', 'purchase_types', 'standard_remarks',
            'company_user', 'company_user_branches', 'company_capabilities',
            'company_industry_settings', 'company_setup_audits', 'company_branches',
            'companies',
            'water_tankers', 'water_tanker_trips', 'water_can_inventories',
            'water_can_routes', 'water_can_deliveries', 'cafe_cash_drawers',
            'cafe_ingredient_usages', 'fleet_vehicles', 'fleet_trip_logs'
        ];

        foreach ($companyTables as $table) {
            if (Schema::hasTable($table)) {
                DB::table($table)->truncate();
            }
        }

        // Ensure default customer group
        if (Schema::hasTable('customer_groups') && !DB::table('customer_groups')->exists()) {
            DB::table('customer_groups')->insert([
                'id' => 1,
                'name' => 'General Customers',
                'percentage' => '0',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Ensure default walk-in customer exists
        if (Schema::hasTable('customers')) {
            DB::table('customers')->insert([
                'id' => 1,
                'customer_group_id' => 1,
                'name' => 'Walk-in Customer',
                'print_name' => 'Walk-in Customer',
                'company_name' => 'Walk-in Customer',
                'email' => 'walkin@store.com',
                'type' => 'regular',
                'phone_number' => '0000000000',
                'address' => 'Counter Retail',
                'city' => 'Madurai',
                'country' => 'India',
                'opening_balance' => 0,
                'is_active' => 1,
                'company_id' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        DB::statement('SET FOREIGN_KEY_CHECKS = 1;');

        $service = app(CompanyDirectoryService::class);
        $groupId = 2; // DK Enterprises group

        // Ensure user 1 exists
        if (!DB::table('users')->where('id', 1)->exists()) {
            DB::table('users')->insert([
                'id' => 1,
                'name' => 'admin',
                'email' => 'admin@gmail.com',
                'password' => bcrypt('admin'),
                'phone' => '12345678',
                'role_id' => 1,
                'biller_id' => null,
                'warehouse_id' => null,
                'is_active' => 1,
                'is_deleted' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!DB::table('company_groups')->where('id', $groupId)->exists()) {
            DB::table('company_groups')->insert([
                'id' => $groupId,
                'code' => 'DK',
                'name' => 'DK Enterprises',
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!DB::table('company_group_admins')->where('company_group_id', $groupId)->where('user_id', 1)->exists()) {
            DB::table('company_group_admins')->insert([
                'company_group_id' => $groupId,
                'user_id' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // -------------------------------------------------------------------------
        // Company 1: Aran Cafe (2 branches)
        // -------------------------------------------------------------------------
        $aran = $service->createCompany(1, [
            'company_group_id' => $groupId,
            'code' => 'ARANCAFE',
            'legal_name' => 'Aran Cafe Private Limited',
            'trade_name' => 'Aran Cafe',
            'industry' => 'cafe_bakery',
            'subtype' => 'bakery_production',
            'city' => 'Madurai',
            'state_code' => '33',
            'base_currency_id' => 1,
            'timezone' => 'Asia/Kolkata',
            'fy_start' => '2026-04-01',
            'fy_end' => '2027-03-31',
            'registration_type' => 'unregistered',
        ]);

        $branch1 = $aran->branches()->first();
        $branch1->update(['name' => 'Main Cafe & Kitchen', 'code' => 'MAIN']);

        $branch2 = $aran->branches()->create([
            'code' => 'BRANCH-2',
            'name' => 'Express Counter & Takeaway',
            'is_active' => true,
        ]);

        // Link admin user to branch2
        DB::table('company_user_branches')->insert([
            'company_id' => $aran->id,
            'user_id' => 1,
            'branch_id' => $branch2->id,
        ]);

        // Warehouse for branch 2
        $aranWh2Id = DB::table('warehouses')->insertGetId([
            'name' => 'Aran Cafe - Express Counter',
            'phone' => '9842100002',
            'email' => 'counter@arancafe.com',
            'address' => 'Bus Stand Express Counter, Madurai',
            'is_active' => 1,
            'company_id' => $aran->id,
            'branch_id' => $branch2->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Units for Aran Cafe
        $unitCupId = DB::table('units')->where('unit_code', 'CUP')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'CUP',
            'unit_name' => 'Cup',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitPcsId = DB::table('units')->where('unit_code', 'PCS')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'PCS',
            'unit_name' => 'Piece',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitKgId = DB::table('units')->where('unit_code', 'KGS')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'KGS',
            'unit_name' => 'Kilogram',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitLtrId = DB::table('units')->where('unit_code', 'LTR')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'LTR',
            'unit_name' => 'Litre',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Categories for Aran Cafe
        $catBevId = DB::table('categories')->insertGetId([
            'name' => 'Beverages',
            'company_id' => $aran->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $catBakId = DB::table('categories')->insertGetId([
            'name' => 'Bakery & Pastry',
            'company_id' => $aran->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $catIngId = DB::table('categories')->insertGetId([
            'name' => 'Raw Ingredients',
            'company_id' => $aran->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $aranProducts = [
            ['code' => 'CF-FILTER', 'name' => 'South Indian Filter Coffee', 'cost' => 12.00, 'price' => 30.00, 'unit_id' => $unitCupId, 'category_id' => $catBevId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'CF-TEA', 'name' => 'Special Masala Tea', 'cost' => 8.00, 'price' => 20.00, 'unit_id' => $unitCupId, 'category_id' => $catBevId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'BK-CROISSANT', 'name' => 'Butter Croissant', 'cost' => 25.00, 'price' => 65.00, 'unit_id' => $unitPcsId, 'category_id' => $catBakId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'BK-BREAD', 'name' => 'Milk Loaf Bread 400g', 'cost' => 22.00, 'price' => 45.00, 'unit_id' => $unitPcsId, 'category_id' => $catBakId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'BK-MUFFIN', 'name' => 'Blueberry Muffin', 'cost' => 20.00, 'price' => 50.00, 'unit_id' => $unitPcsId, 'category_id' => $catBakId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'ING-MILK', 'name' => 'Raw Dairy Milk (Bulk)', 'cost' => 48.00, 'price' => 55.00, 'unit_id' => $unitLtrId, 'category_id' => $catIngId, 'type' => 'standard', 'company_id' => $aran->id],
            ['code' => 'ING-SUGAR', 'name' => 'White Cane Sugar', 'cost' => 38.00, 'price' => 45.00, 'unit_id' => $unitKgId, 'category_id' => $catIngId, 'type' => 'standard', 'company_id' => $aran->id],
        ];

        $aranWh1Id = DB::table('warehouses')->where('company_id', $aran->id)->where('name', '!=', 'Aran Cafe - Express Counter')->value('id');
        foreach ($aranProducts as $p) {
            $pId = DB::table('products')->insertGetId(array_merge($p, [
                'purchase_unit_id' => $p['unit_id'],
                'sale_unit_id' => $p['unit_id'],
                'barcode_symbology' => 'code128',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
            if ($aranWh1Id) {
                DB::table('product_warehouse')->insert([
                    'product_id' => $pId,
                    'warehouse_id' => $aranWh1Id,
                    'company_id' => $aran->id,
                    'qty' => 150,
                    'price' => $p['price'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
            if ($aranWh2Id) {
                DB::table('product_warehouse')->insert([
                    'product_id' => $pId,
                    'warehouse_id' => $aranWh2Id,
                    'company_id' => $aran->id,
                    'qty' => 80,
                    'price' => $p['price'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        // -------------------------------------------------------------------------
        // Company 2: Tiruchendur Murugan Water Supply (Tanker lorry water supply)
        // -------------------------------------------------------------------------
        $tmws = $service->createCompany(1, [
            'company_group_id' => $groupId,
            'code' => 'TMWS',
            'legal_name' => 'Tiruchendur Murugan Water Supply',
            'trade_name' => 'Tiruchendur Murugan Water Supply',
            'industry' => 'bulk_water',
            'subtype' => 'commercial_tankers',
            'city' => 'Madurai',
            'state_code' => '33',
            'base_currency_id' => 1,
            'timezone' => 'Asia/Kolkata',
            'fy_start' => '2026-04-01',
            'fy_end' => '2027-03-31',
            'registration_type' => 'unregistered',
        ]);

        $unitKlId = DB::table('units')->where('unit_code', 'KL')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'KL',
            'unit_name' => 'KiloLitre (1000 Litres)',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitKmId = DB::table('units')->where('unit_code', 'KM')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'KM',
            'unit_name' => 'Kilometer',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitMinId = DB::table('units')->where('unit_code', 'MIN')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'MIN',
            'unit_name' => 'Minute',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $catBulkId = DB::table('categories')->insertGetId([
            'name' => 'Bulk Tanker Water',
            'company_id' => $tmws->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $catSrvId = DB::table('categories')->insertGetId([
            'name' => 'Tanker Logistics Services',
            'company_id' => $tmws->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $tmwsProducts = [
            [
                'code' => 'BW-20KL',
                'name' => '20KL Bulk Water Tanker Load',
                'cost' => 1100.00,
                'price' => 2400.00,
                'unit_id' => $unitKlId,
                'category_id' => $catBulkId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'water_capacity_spec' => '20KL',
                'water_compartment_config' => '2 Chambers (10KL + 10KL)',
                'base_km_limit' => 10,
                'excess_km_rate' => 45.00,
                'motor_pump_rate' => 10.00,
                'waiting_charge_rate' => 15.00,
                'type' => 'standard',
            ],
            [
                'code' => 'BW-40KL',
                'name' => '40KL Heavy Commercial Bulk Water',
                'cost' => 2200.00,
                'price' => 4800.00,
                'unit_id' => $unitKlId,
                'category_id' => $catBulkId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'water_capacity_spec' => '40KL',
                'water_compartment_config' => '3 Chambers (10KL + 10KL + 20KL)',
                'base_km_limit' => 15,
                'excess_km_rate' => 55.00,
                'motor_pump_rate' => 15.00,
                'waiting_charge_rate' => 20.00,
                'type' => 'standard',
            ],
            [
                'code' => 'BW-10KL',
                'name' => '10KL Single Load Bulk Water',
                'cost' => 650.00,
                'price' => 1400.00,
                'unit_id' => $unitKlId,
                'category_id' => $catBulkId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'water_capacity_spec' => '10KL',
                'water_compartment_config' => 'Single Chamber 10KL',
                'base_km_limit' => 8,
                'excess_km_rate' => 40.00,
                'motor_pump_rate' => 8.00,
                'waiting_charge_rate' => 10.00,
                'type' => 'standard',
            ],
            [
                'code' => 'SRV-KM',
                'name' => 'Excess Distance Transit Surcharge',
                'cost' => 0.00,
                'price' => 45.00,
                'unit_id' => $unitKmId,
                'category_id' => $catSrvId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'type' => 'service',
            ],
            [
                'code' => 'SRV-PUMP',
                'name' => 'Heavy Motor Pumping Service Charge',
                'cost' => 0.00,
                'price' => 10.00,
                'unit_id' => $unitMinId,
                'category_id' => $catSrvId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'type' => 'service',
            ],
            [
                'code' => 'SRV-WAIT',
                'name' => 'Customer Site Delay Waiting Surcharge',
                'cost' => 0.00,
                'price' => 15.00,
                'unit_id' => $unitMinId,
                'category_id' => $catSrvId,
                'company_id' => $tmws->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'bulk_water',
                'type' => 'service',
            ],
        ];

        $tmwsWhId = DB::table('warehouses')->where('company_id', $tmws->id)->value('id');
        foreach ($tmwsProducts as $p) {
            $pId = DB::table('products')->insertGetId(array_merge($p, [
                'purchase_unit_id' => $p['unit_id'],
                'sale_unit_id' => $p['unit_id'],
                'barcode_symbology' => 'code128',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
            if ($tmwsWhId) {
                DB::table('product_warehouse')->insert([
                    'product_id' => $pId,
                    'warehouse_id' => $tmwsWhId,
                    'company_id' => $tmws->id,
                    'qty' => 500,
                    'price' => $p['price'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        // Seed 3 Tankers
        if (Schema::hasTable('water_tankers')) {
            DB::table('water_tankers')->insert([
                [
                    'vehicle_number' => 'TN-58-BW-2001',
                    'capacity_kl' => 20.0,
                    'driver_name' => 'K. Ramanathan',
                    'driver_phone' => '9842100001',
                    'is_active' => true,
                    'current_odometer_km' => 45200,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'vehicle_number' => 'TN-58-BW-4001',
                    'capacity_kl' => 40.0,
                    'driver_name' => 'S. Sundaram',
                    'driver_phone' => '9842100002',
                    'is_active' => true,
                    'current_odometer_km' => 78900,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'vehicle_number' => 'TN-58-BW-1001',
                    'capacity_kl' => 10.0,
                    'driver_name' => 'M. Velu',
                    'driver_phone' => '9842100003',
                    'is_active' => true,
                    'current_odometer_km' => 24100,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }

        // -------------------------------------------------------------------------
        // Company 3: DK Waters (Water can supply)
        // -------------------------------------------------------------------------
        $dkw = $service->createCompany(1, [
            'company_group_id' => $groupId,
            'code' => 'DKWATERS',
            'legal_name' => 'DK Waters Private Limited',
            'trade_name' => 'DK Waters',
            'industry' => 'packaged_water',
            'subtype' => 'can_route_distribution',
            'city' => 'Madurai',
            'state_code' => '33',
            'base_currency_id' => 1,
            'timezone' => 'Asia/Kolkata',
            'fy_start' => '2026-04-01',
            'fy_end' => '2027-03-31',
            'registration_type' => 'unregistered',
        ]);

        $unitCanId = DB::table('units')->where('unit_code', 'CAN')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'CAN',
            'unit_name' => 'Water Can (20 Litres)',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $unitBtlId = DB::table('units')->where('unit_code', 'BTL')->value('id') ?? DB::table('units')->insertGetId([
            'unit_code' => 'BTL',
            'unit_name' => 'Bottle',
            'base_unit' => null,
            'operator' => '*',
            'operation_value' => 1,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $catCanWId = DB::table('categories')->insertGetId([
            'name' => 'Packaged Water Cans & Bottles',
            'company_id' => $dkw->id,
            'is_active' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $dkwProducts = [
            [
                'code' => 'CAN-20L',
                'name' => '20L RO Purified Water Can',
                'cost' => 14.00,
                'price' => 35.00,
                'unit_id' => $unitCanId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '20L Can',
                'type' => 'standard',
            ],
            [
                'code' => 'CAN-25L',
                'name' => '25L Premium Mineral Water Can',
                'cost' => 18.00,
                'price' => 45.00,
                'unit_id' => $unitCanId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '25L Can',
                'type' => 'standard',
            ],
            [
                'code' => 'CAN-10L',
                'name' => '10L Handle Water Dispenser Can',
                'cost' => 10.00,
                'price' => 25.00,
                'unit_id' => $unitCanId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '10L Can',
                'type' => 'standard',
            ],
            [
                'code' => 'BTL-1L',
                'name' => '1L Bottled Mineral Water Box (12 pcs)',
                'cost' => 90.00,
                'price' => 180.00,
                'unit_id' => $unitBtlId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '1L Box (12 pcs)',
                'type' => 'standard',
            ],
            [
                'code' => 'BTL-2L',
                'name' => '2L Bottled Mineral Water Box (6 pcs)',
                'cost' => 85.00,
                'price' => 160.00,
                'unit_id' => $unitBtlId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '2L Box (6 pcs)',
                'type' => 'standard',
            ],
            [
                'code' => 'BTL-500ML',
                'name' => '500ml Mini Mineral Water Box (24 pcs)',
                'cost' => 120.00,
                'price' => 240.00,
                'unit_id' => $unitBtlId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => '500ml Box (24 pcs)',
                'type' => 'standard',
            ],
            [
                'code' => 'CAN-DEP',
                'name' => '20L Empty Can Security Deposit (Refundable)',
                'cost' => 150.00,
                'price' => 150.00,
                'unit_id' => $unitCanId,
                'company_id' => $dkw->id,
                'is_water_logistics' => 1,
                'water_vertical_type' => 'packaged_water',
                'water_capacity_spec' => 'Deposit',
                'type' => 'service',
            ],
        ];

        $dkwWhId = DB::table('warehouses')->where('company_id', $dkw->id)->value('id');
        foreach ($dkwProducts as $p) {
            $pId = DB::table('products')->insertGetId(array_merge($p, [
                'purchase_unit_id' => $p['unit_id'],
                'sale_unit_id' => $p['unit_id'],
                'category_id' => $catCanWId,
                'barcode_symbology' => 'code128',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
            if ($dkwWhId) {
                DB::table('product_warehouse')->insert([
                    'product_id' => $pId,
                    'warehouse_id' => $dkwWhId,
                    'company_id' => $dkw->id,
                    'qty' => 500,
                    'price' => $p['price'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        // Seed Routes for DK Waters
        if (Schema::hasTable('water_can_routes')) {
            DB::table('water_can_routes')->insert([
                [
                    'route_name' => 'Anna Nagar & Teppakulam Route',
                    'driver_name' => 'R. Muthu',
                    'driver_phone' => '9842100010',
                    'vehicle_no' => 'TN-58-WA-101 (Tata Ace)',
                    'is_active' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'route_name' => 'KK Nagar & Mattuthavani Route',
                    'driver_name' => 'P. Selvam',
                    'driver_phone' => '9842100020',
                    'vehicle_no' => 'TN-58-WA-102 (Tata Ace)',
                    'is_active' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }

        // Set Company 1 as default for admin user
        DB::table('company_user')->where('user_id', 1)->where('company_id', $aran->id)->update(['is_default' => 1]);
    }
}
