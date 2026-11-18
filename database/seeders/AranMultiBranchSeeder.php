<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

class AranMultiBranchSeeder extends Seeder
{
    public function run(): void
    {
        $now = now();
        $aranId = $this->resolveCafeCompanyId();

        if ($aranId === null) {
            return;
        }

        // 1. Seed ARAN1 & ARAN2 branches in company_branches
        $branchIds = [];
        if (Schema::hasTable('company_branches')) {
            $branchCols = array_flip(Schema::getColumnListing('company_branches'));
            $branches = [
                'ARAN1' => [
                    'code' => 'ARAN1',
                    'name' => 'Aran Cafe - Shop 1',
                    'branch_type' => 'main',
                    'address' => 'Aran Cafe Shop 1, Erode',
                    'is_active' => true,
                ],
                'ARAN2' => [
                    'code' => 'ARAN2',
                    'name' => 'Aran Cafe - Shop 2',
                    'branch_type' => 'branch',
                    'address' => 'Aran Cafe Shop 2, Erode',
                    'is_active' => true,
                ],
            ];

            foreach ($branches as $code => $data) {
                $existing = DB::table('company_branches')
                    ->where('company_id', $aranId)
                    ->where('code', $code)
                    ->first();

                $payload = array_intersect_key($data + [
                    'company_id' => $aranId,
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $branchCols);

                DB::table('company_branches')->updateOrInsert(
                    ['company_id' => $aranId, 'code' => $code],
                    $payload
                );

                $branchIds[$code] = (int) DB::table('company_branches')
                    ->where('company_id', $aranId)
                    ->where('code', $code)
                    ->value('id');
            }

            // Grant ARAN1 & ARAN2 access to company admins/owners so they can switch freely
            if (Schema::hasTable('company_user') && Schema::hasTable('company_user_branches') && Schema::hasTable('users')) {
                $adminUserIds = DB::table('company_user')
                    ->join('users', 'users.id', '=', 'company_user.user_id')
                    ->where('company_user.company_id', $aranId)
                    ->whereIn('users.role_id', [1, 2])
                    ->pluck('users.id');

                foreach ($adminUserIds as $adminId) {
                    foreach ($branchIds as $branchId) {
                        DB::table('company_user_branches')->updateOrInsert(
                            [
                                'company_id' => $aranId,
                                'user_id' => (int) $adminId,
                                'branch_id' => $branchId,
                            ],
                            ['updated_at' => $now, 'created_at' => $now]
                        );
                    }
                }
            }

            // Ensure document_series exist for ARAN1 & ARAN2 across open fiscal years
            if (Schema::hasTable('document_series') && Schema::hasTable('fiscal_years')) {
                $fyIds = DB::table('fiscal_years')
                    ->where('company_id', $aranId)
                    ->where('is_closed', false)
                    ->pluck('id');
                foreach ($branchIds as $branchId) {
                    foreach ($fyIds as $fyId) {
                        OptechMasterSeeder::seedSeries($aranId, $branchId, (int) $fyId);
                    }
                }
            }
        }

        // 2. Seed corresponding warehouses for ARAN1 & ARAN2
        $warehouseIds = [];
        if (Schema::hasTable('warehouses')) {
            $whCols = array_flip(Schema::getColumnListing('warehouses'));
            $warehouses = [
                'ARAN1' => [
                    'name' => 'Aran Cafe - Shop 1 Warehouse',
                    'phone' => '9842100101',
                    'email' => 'aran1@dkenterprises.animazon.in',
                    'address' => 'Aran Cafe Shop 1, Erode',
                    'is_active' => true,
                ],
                'ARAN2' => [
                    'name' => 'Aran Cafe - Shop 2 Warehouse',
                    'phone' => '9842100102',
                    'email' => 'aran2@dkenterprises.animazon.in',
                    'address' => 'Aran Cafe Shop 2, Erode',
                    'is_active' => true,
                ],
            ];

            foreach ($warehouses as $code => $wh) {
                $branchId = $branchIds[$code] ?? null;
                $match = ['name' => $wh['name']];
                if (isset($whCols['company_id'])) {
                    $wh['company_id'] = $aranId;
                    $match = ['company_id' => $aranId, 'name' => $wh['name']];
                }
                if ($branchId !== null && isset($whCols['branch_id'])) {
                    $wh['branch_id'] = $branchId;
                }

                $existing = DB::table('warehouses')->where($match)->first();
                $payload = array_intersect_key($wh + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $whCols);

                DB::table('warehouses')->updateOrInsert($match, $payload);
                $warehouseIds[$code] = (int) DB::table('warehouses')->where($match)->value('id');
            }
        }

        // 3. Seed branch-scoped staff users (aran1_manager, aran2_manager)
        if (Schema::hasTable('users')) {
            $userCols = array_flip(Schema::getColumnListing('users'));
            $staffRoleId = Schema::hasTable('roles')
                ? (int) (DB::table('roles')->where('name', 'staff')->value('id') ?? 4)
                : 4;

            $managers = [
                'ARAN1' => [
                    'name' => 'aran1_manager',
                    'email' => 'aran1@dkenterprises.animazon.in',
                    'phone' => '9842100101',
                    'password' => 'aran1234',
                ],
                'ARAN2' => [
                    'name' => 'aran2_manager',
                    'email' => 'aran2@dkenterprises.animazon.in',
                    'phone' => '9842100102',
                    'password' => 'aran1234',
                ],
            ];

            foreach ($managers as $code => $mgr) {
                $existingUser = DB::table('users')
                    ->where('name', $mgr['name'])
                    ->orWhere('email', $mgr['email'])
                    ->first();

                if ($existingUser) {
                    $userId = (int) $existingUser->id;
                    $updatePayload = array_intersect_key([
                        'warehouse_id' => $warehouseIds[$code] ?? $existingUser->warehouse_id ?? null,
                        'is_active' => true,
                        'is_deleted' => false,
                        'updated_at' => $now,
                    ], $userCols);
                    DB::table('users')->where('id', $userId)->update($updatePayload);
                } else {
                    $insertPayload = array_intersect_key([
                        'name' => $mgr['name'],
                        'email' => $mgr['email'],
                        'password' => Hash::make($mgr['password']),
                        'phone' => $mgr['phone'],
                        'role_id' => $staffRoleId,
                        'warehouse_id' => $warehouseIds[$code] ?? null,
                        'is_active' => true,
                        'is_deleted' => false,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ], $userCols);
                    $userId = (int) DB::table('users')->insertGetId($insertPayload);
                }

                if (Schema::hasTable('company_user')) {
                    DB::table('company_user')->updateOrInsert(
                        ['company_id' => $aranId, 'user_id' => $userId],
                        ['is_default' => true, 'updated_at' => $now, 'created_at' => $now]
                    );
                }

                if (isset($branchIds[$code]) && Schema::hasTable('company_user_branches')) {
                    // Scope branch-locked manager strictly to their assigned branch
                    DB::table('company_user_branches')
                        ->where('company_id', $aranId)
                        ->where('user_id', $userId)
                        ->where('branch_id', '!=', $branchIds[$code])
                        ->delete();

                    DB::table('company_user_branches')->updateOrInsert(
                        [
                            'company_id' => $aranId,
                            'user_id' => $userId,
                            'branch_id' => $branchIds[$code],
                        ],
                        ['updated_at' => $now, 'created_at' => $now]
                    );
                }
            }
        }

        // 4. Seed 10 regular vendors in suppliers
        if (Schema::hasTable('suppliers')) {
            $supplierCols = array_flip(Schema::getColumnListing('suppliers'));
            $vendors = [
                ['name' => 'Amirtha Milk', 'default_category' => 'Milk', 'phone_number' => '9842101001'],
                ['name' => 'Local Milk Vendor 2', 'default_category' => 'Milk', 'phone_number' => '9842101002'],
                ['name' => 'Sri Murugan Groceries', 'default_category' => 'Groceries', 'phone_number' => '9842101003'],
                ['name' => 'Ice Cream Distributor', 'default_category' => 'Ice Cream', 'phone_number' => '9842101004'],
                ['name' => 'Maida & Bakery Flour Mill', 'default_category' => 'Flour', 'phone_number' => '9842101005'],
                ['name' => 'Pazhamudir Cholai Fruits', 'default_category' => 'Fruits', 'phone_number' => '9842101006'],
                ['name' => 'Onion & Vegetable Wholesale', 'default_category' => 'Vegetables', 'phone_number' => '9842101007'],
                ['name' => 'Chendhur Gas Agency', 'default_category' => 'Commercial LPG', 'phone_number' => '9842101008'],
                ['name' => 'Prabu Auto Spares', 'default_category' => 'Fleet Maintenance', 'phone_number' => '9842101009'],
                ['name' => 'Satha Workshop - Sakthi Auto', 'default_category' => 'Fleet Maintenance', 'phone_number' => '9842101010'],
            ];

            foreach ($vendors as $vendor) {
                $match = ['name' => $vendor['name']];
                $data = [
                    'name' => $vendor['name'],
                    'company_name' => $vendor['name'],
                    'phone_number' => $vendor['phone_number'],
                    'email' => null,
                    'address' => 'Erode',
                    'city' => 'Erode',
                    'default_category' => $vendor['default_category'],
                    'is_regular_vendor' => true,
                    'preferred_payment_mode' => 'Cash',
                    'is_active' => true,
                ];
                if (isset($supplierCols['company_id'])) {
                    $data['company_id'] = $aranId;
                    $match = ['company_id' => $aranId, 'name' => $vendor['name']];
                }

                $existing = DB::table('suppliers')->where($match)->first();
                $payload = array_intersect_key($data + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $supplierCols);

                DB::table('suppliers')->updateOrInsert($match, $payload);
            }
        }

        // 5. Seed the 7 accounting ledger accounts in accounts
        if (Schema::hasTable('accounts')) {
            $accountCols = array_flip(Schema::getColumnListing('accounts'));
            $cashCoaId = Schema::hasTable('chart_of_accounts') && Schema::hasColumn('chart_of_accounts', 'sub_type')
                ? DB::table('chart_of_accounts')->where('company_id', $aranId)->where('sub_type', 'cash')->where('is_active', true)->value('id')
                : null;
            $bankCoaId = Schema::hasTable('chart_of_accounts') && Schema::hasColumn('chart_of_accounts', 'sub_type')
                ? DB::table('chart_of_accounts')->where('company_id', $aranId)->where('sub_type', 'bank')->where('is_active', true)->value('id')
                : null;

            $accounts = [
                ['name' => 'Kavin Axis', 'account_no' => 'DK-KAVIN-AXIS', 'code' => 'KAVIN_AXIS', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'Sasi', 'account_no' => 'DK-SASI', 'code' => 'SASI', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'Axis OD LOAN', 'account_no' => 'DK-AXIS-OD-LOAN', 'code' => 'AXIS_OD_LOAN', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'DeekTex', 'account_no' => 'DK-DEEKTEX', 'code' => 'DEEKTEX', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'Kavin KVB', 'account_no' => 'DK-KAVIN-KVB', 'code' => 'KAVIN_KVB', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'Kavin Canara', 'account_no' => 'DK-KAVIN-CANARA', 'code' => 'KAVIN_CANARA', 'type' => 'Bank Account', 'coa' => $bankCoaId, 'is_default' => false],
                ['name' => 'CASH', 'account_no' => 'DK-CASH', 'code' => 'CASH', 'type' => 'Cash', 'coa' => $cashCoaId, 'is_default' => true],
            ];

            foreach ($accounts as $acct) {
                $match = ['name' => $acct['name']];
                $data = [
                    'name' => $acct['name'],
                    'account_no' => $acct['account_no'],
                    'code' => $acct['code'],
                    'type' => $acct['type'],
                    'initial_balance' => 0,
                    'total_balance' => 0,
                    'is_payment' => true,
                    'is_active' => true,
                    'note' => '2026 Accounts ledger account',
                ];
                if (isset($accountCols['company_id'])) {
                    $data['company_id'] = $aranId;
                    $match = ['company_id' => $aranId, 'name' => $acct['name']];
                }
                if (isset($accountCols['chart_of_account_id']) && $acct['coa'] !== null) {
                    $data['chart_of_account_id'] = $acct['coa'];
                }

                $existing = DB::table('accounts')->where($match)->first();
                if ($existing) {
                    // Preserve existing balances when re-seeding idempotently
                    unset($data['initial_balance'], $data['total_balance']);
                } elseif (isset($accountCols['is_default'])) {
                    $hasDefault = isset($accountCols['company_id'])
                        ? DB::table('accounts')->where('company_id', $aranId)->where('is_default', true)->exists()
                        : DB::table('accounts')->where('is_default', true)->exists();
                    $data['is_default'] = $acct['is_default'] && !$hasDefault;
                }

                $payload = array_intersect_key($data + [
                    'updated_at' => $now,
                    'created_at' => $existing->created_at ?? $now,
                ], $accountCols);

                DB::table('accounts')->updateOrInsert($match, $payload);
            }
        }
    }

    private function resolveCafeCompanyId(): ?int
    {
        if (
            Schema::hasTable('company_industry_settings')
            && Schema::hasColumn('company_industry_settings', 'profile_key')
            && Schema::hasColumn('company_industry_settings', 'company_id')
        ) {
            $companyId = DB::table('company_industry_settings')
                ->where('profile_key', 'cafe_bakery')
                ->value('company_id');
            if ($companyId) {
                return (int) $companyId;
            }
        }

        if (Schema::hasTable('companies')) {
            if (Schema::hasColumn('companies', 'code')) {
                $companyId = DB::table('companies')
                    ->whereIn('code', ['ARANCAFE', 'ARAN'])
                    ->value('id');
                if ($companyId) {
                    return (int) $companyId;
                }
            }

            if (Schema::hasColumn('companies', 'trade_name') && Schema::hasColumn('companies', 'legal_name')) {
                $companyId = DB::table('companies')
                    ->where('trade_name', 'like', '%Aran%')
                    ->orWhere('legal_name', 'like', '%Aran%')
                    ->value('id');
                if ($companyId) {
                    return (int) $companyId;
                }
            }
        }

        return null;
    }
}
