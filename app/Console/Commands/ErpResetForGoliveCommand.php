<?php

namespace App\Console\Commands;

use Database\Seeders\AranMultiBranchSeeder;
use Database\Seeders\TmwsFleetAndPickupPointsSeeder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ErpResetForGoliveCommand extends Command
{
    protected $signature = 'erp:reset-for-golive
        {--force : Confirm clearing demo/test transactional data}
        {--seed-masters : Re-seed clean TMWS/Aran/DK Waters masters after wipe}
        {--keep-customers : Preserve existing non-walk-in customer master records}
        {--wipe-companies : Wipe all companies, branches, vehicles and demo staff for a completely fresh software handover}';

    protected $description = 'Safely wipe demo/test transactional data while preserving ERP master configurations for live client trial.';

    /**
     * Transactional tables cleared during go-live reset (ordered child-first for FK safety).
     *
     * @var array<int, string>
     */
    private const TRANSACTIONAL_TABLES = [
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
    ];

    public function handle(): int
    {
        if (!$this->option('force')) {
            $this->error('Confirmation required: re-run with --force to clear demo/test transactional data.');

            return self::FAILURE;
        }

        $driver = DB::getDriverName();
        $cleared = [];

        $this->setForeignKeyChecks($driver, false);

        try {
            foreach (self::TRANSACTIONAL_TABLES as $table) {
                if (Schema::hasTable($table)) {
                    $deleted = DB::table($table)->delete();
                    $cleared[$table] = $deleted;
                }
            }

            if (Schema::hasTable('water_can_inventories')) {
                if ($this->option('keep-customers')) {
                    $resetFields = array_intersect_key([
                        'total_cans_held' => 0,
                        'deposit_held' => 0,
                        'last_delivery_date' => null,
                        'last_audit_date' => null,
                        'can_variance_detected' => 0,
                        'updated_at' => now(),
                    ], array_flip(Schema::getColumnListing('water_can_inventories')));
                    if (!empty($resetFields)) {
                        DB::table('water_can_inventories')->update($resetFields);
                    }
                    $cleared['water_can_inventories'] = 'balances_reset_to_zero';
                } else {
                    $cleared['water_can_inventories'] = DB::table('water_can_inventories')->delete();
                }
            }

            if (!$this->option('keep-customers') && Schema::hasTable('customers')) {
                $deletedCustomers = DB::table('customers')
                    ->where('id', '!=', 1)
                    ->where('name', '!=', 'Walk-in Customer')
                    ->delete();
                $cleared['customers'] = $deletedCustomers;

                $walkInReset = array_intersect_key([
                    'opening_balance' => 0,
                    'deposit' => 0,
                    'expense' => 0,
                    'updated_at' => now(),
                ], array_flip(Schema::getColumnListing('customers')));
                if (!empty($walkInReset)) {
                    DB::table('customers')
                        ->where(function ($q) {
                            $q->where('id', 1)->orWhere('name', 'Walk-in Customer');
                        })
                        ->update($walkInReset);
                }
            }

            if ($this->option('wipe-companies')) {
                $companyMasterTables = [
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

                foreach ($companyMasterTables as $table) {
                    if (Schema::hasTable($table)) {
                        $cleared[$table] = DB::table($table)->delete();
                    }
                }

                // Completely clear all customers when wiping companies
                if (Schema::hasTable('customers')) {
                    $cleared['customers'] = DB::table('customers')->delete();
                }

                // Purge demo staff/drivers and keep only master Administrator (ID 1)
                if (Schema::hasTable('users')) {
                    DB::table('users')->where('id', '!=', 1)->delete();
                    $userUpdates = [];
                    if (Schema::hasColumn('users', 'company_id')) {
                        $userUpdates['company_id'] = null;
                    }
                    if (Schema::hasColumn('users', 'company_name')) {
                        $userUpdates['company_name'] = null;
                    }
                    if (Schema::hasColumn('users', 'biller_id')) {
                        $userUpdates['biller_id'] = null;
                    }
                    if (Schema::hasColumn('users', 'warehouse_id')) {
                        $userUpdates['warehouse_id'] = null;
                    }
                    if (!empty($userUpdates)) {
                        DB::table('users')->where('id', 1)->update($userUpdates);
                    }
                }
            }
        } finally {
            $this->setForeignKeyChecks($driver, true);
        }

        if ($this->option('seed-masters') && !$this->option('wipe-companies')) {
            $this->info('Re-seeding TMWS fleet, pickup points, and Aran Cafe multi-branch masters...');
            $this->call(TmwsFleetAndPickupPointsSeeder::class);
            $this->call(AranMultiBranchSeeder::class);
        }

        if ($this->option('wipe-companies')) {
            $this->info('All companies, branches, vehicles, demo users and records wiped cleanly for fresh software handover.');
        } else {
            $this->info('ERP demo transactional reset completed successfully.');
        }
        $this->line(sprintf('Processed %d transactional tables (masters preserved).', count($cleared)));

        return self::SUCCESS;
    }

    private function setForeignKeyChecks(string $driver, bool $enabled): void
    {
        if ($driver === 'mysql') {
            DB::statement($enabled ? 'SET FOREIGN_KEY_CHECKS = 1;' : 'SET FOREIGN_KEY_CHECKS = 0;');
        } elseif ($driver === 'sqlite') {
            DB::statement($enabled ? 'PRAGMA foreign_keys = ON;' : 'PRAGMA foreign_keys = OFF;');
        }
    }
}
