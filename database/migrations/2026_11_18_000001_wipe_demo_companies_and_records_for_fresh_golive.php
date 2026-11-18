<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations to wipe demo companies and records for a fresh software handover.
     */
    public function up(): void
    {
        // Guard against wiping testing fixtures in CI acceptance suites
        if (app()->environment('testing')) {
            return;
        }

        $driver = DB::getDriverName();
        if ($driver === 'mysql') {
            DB::statement('SET FOREIGN_KEY_CHECKS = 0;');
        }

        try {
            $tables = [
                'product_sales',
                'sale_drafts',
                'commercial_order_allocations',
                'commercial_order_items',
                'sales_orders',
                'payments',
                'deposits',
                'sales',
                'product_purchases',
                'purchases',
                'product_returns',
                'returns',
                'purchase_product_return',
                'return_purchases',
                'account_allocations',
                'account_open_items',
                'journal_items',
                'journal_entries',
                'expenses',
                'water_tanker_trips',
                'water_can_deliveries',
                'water_can_plant_intakes',
                'water_can_spot_audits',
                'driver_cash_surrenders',
                'delivery_schedules',
                'fleet_trip_logs',
                'gps_pings',
                'cafe_cash_drawers',
                'cafe_ingredient_usages',
                'cash_registers',
                'gst_transaction_projections',
                'notifications',
                'water_can_inventories',
                'water_tankers',
                'water_pickup_points',
                'water_can_routes',
                'damage_stocks',
                'stock_counts',
                'product_warehouse',
                'product_batches',
                'product_variants',
                'product_adjustments',
                'adjustments',
                'transfers',
                'product_transfer',
                'quotations',
                'product_quotation',
                'quotation_follow_ups',
                'challans',
                'delivery_challans',
                'deliveries',
                'packing_slips',
                'packing_slip_products',
                'material_settlements',
                'principal_job_orders',
                'money_transfers',
                'collection_records',
                'gift_card_recharges',
                'gift_cards',
                'coupons',
                'reward_points',
                'attendances',
                'payrolls',
                'leaves',
                'overtimes',
                'installment_plans',
                'installments',
                'products',
                'categories',
                'brands',
                'warehouses',
                'customers',
                'suppliers',
                'billers',
                'employees',
                'departments',
                'designations',
                'accounts',
                'chart_of_accounts',
                'company_user_branches',
                'company_user',
                'company_branches',
                'company_financial_years',
                'company_capabilities',
                'company_industry_settings',
                'company_menu_switches',
                'company_setup_audits',
                'company_group_admins',
                'company_groups',
                'companies',
                'tax_registrations',
                'document_series',
                'tables',
                'shifts',
                'cafe_raw_materials',
            ];

            foreach ($tables as $t) {
                if (Schema::hasTable($t)) {
                    DB::table($t)->delete();
                }
            }

            if (Schema::hasTable('users')) {
                DB::table('users')->where('id', '!=', 1)->delete();
                DB::table('users')->where('id', 1)->update([
                    'company_id' => null,
                ]);
            }
        } finally {
            if ($driver === 'mysql') {
                DB::statement('SET FOREIGN_KEY_CHECKS = 1;');
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Irreversible fresh slate
    }
};
