<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Company;
use App\Models\User;
use App\Services\Platform\CapabilityService;
use App\Services\Platform\CompanyContext;
use App\Services\Platform\LegacyModuleAdapter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MeApiController extends BaseApiController
{
    /**
     * Retrieve the authenticated user's identity, roles, permissions,
     * accessible companies, branches, financial years, and enabled capabilities.
     */
    public function me(Request $request, CapabilityService $capabilities): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return $this->sendError('Unauthenticated', ['auth' => 'Valid Sanctum token required.'], 401);
        }

        // 1. Roles & Permissions
        $roles = $user->roles->pluck('name')->values()->all();
        if (empty($roles)) {
            $roleRecord = DB::table('roles')->where('id', $user->role_id)->first();
            if ($roleRecord) {
                $roles[] = $roleRecord->name;
            }
        }

        $permissions = $user->getAllPermissions()->pluck('name')->values()->all();
        // If Admin / role_id 1, ensure all system permissions are accessible
        if ($user->role_id == 1 || in_array('Admin', $roles, true)) {
            $allPerms = DB::table('permissions')->pluck('name')->values()->all();
            $permissions = array_values(array_unique(array_merge($permissions, $allPerms)));
        }

        // 2. Accessible Companies
        $memberships = DB::table('company_user')
            ->join('companies', 'company_user.company_id', '=', 'companies.id')
            ->where('company_user.user_id', $user->id)
            ->where('companies.status', 'active')
            ->select(
                'companies.id',
                'companies.code',
                'companies.legal_name',
                'companies.trade_name',
                'companies.base_currency_id',
                'companies.timezone',
                'companies.country_code',
                'companies.state_code',
                'company_user.is_default'
            )
            ->get();

        $companiesData = [];
        $defaultCompanyId = null;

        foreach ($memberships as $membership) {
            if ($membership->is_default || $defaultCompanyId === null) {
                $defaultCompanyId = $membership->id;
            }

            // Company industry profile
            $industrySetting = DB::table('company_industry_settings')
                ->where('company_id', $membership->id)
                ->first();
            $industry = $industrySetting ? $industrySetting->profile_key : 'general';
            $subtype = $industrySetting ? $industrySetting->subtype : null;

            // Branches accessible by user in this company
            $userBranchIds = DB::table('company_user_branches')
                ->where('company_id', $membership->id)
                ->where('user_id', $user->id)
                ->pluck('branch_id');

            $branches = DB::table('company_branches')
                ->where('company_id', $membership->id)
                ->where('is_active', true)
                ->when($userBranchIds->isNotEmpty(), fn ($q) => $q->whereIn('id', $userBranchIds))
                ->select('id', 'code', 'name', 'is_active')
                ->get();

            // Financial years
            $fiscalYears = DB::table('fiscal_years')
                ->where('company_id', $membership->id)
                ->select('id', 'name as financial_year', 'start_date', 'end_date', 'is_closed')
                ->orderBy('start_date', 'desc')
                ->get();

            // Enabled capabilities & active modules
            $companyContext = new CompanyContext(
                $membership->id,
                $branches->first()?->id ?? 1,
                $fiscalYears->where('is_closed', false)->first()?->id ?? ($fiscalYears->first()?->id ?? 1)
            );

            $activeModules = [];
            foreach (array_keys(LegacyModuleAdapter::MODULES) as $modKey) {
                if ($capabilities->enabled($modKey, $companyContext)) {
                    $activeModules[] = $modKey;
                }
            }

            $companiesData[] = [
                'id' => $membership->id,
                'code' => $membership->code,
                'legal_name' => $membership->legal_name,
                'trade_name' => $membership->trade_name ?: $membership->legal_name,
                'industry' => $industry,
                'subtype' => $subtype,
                'is_default' => (bool) $membership->is_default,
                'base_currency_id' => $membership->base_currency_id,
                'timezone' => $membership->timezone,
                'branches' => $branches,
                'fiscal_years' => $fiscalYears,
                'active_modules' => $activeModules,
                'capabilities' => $capabilities->forNavigation($companyContext),
            ];
        }

        // Active context determination
        $activeCompanyId = (int) ($request->header('X-Company-ID') ?? $defaultCompanyId);
        $activeCompany = collect($companiesData)->firstWhere('id', $activeCompanyId);
        $activeBranchId = (int) ($request->header('X-Branch-ID') ?? ($activeCompany['branches'][0]->id ?? 1));
        $activeFiscalYearId = (int) ($request->header('X-Financial-Year-ID') ?? ($activeCompany['fiscal_years'][0]->id ?? 1));

        $primaryRole = $roles[0] ?? 'Staff';
        $roleSlug = match(strtolower($user->name)) {
            'admin' => 'superAdmin',
            'driver' => 'deliveryDriver',
            'tanker_driver', 'tanker' => 'tankerDriver',
            'cashier' => 'cashier',
            'agent', 'field_agent' => 'fieldAgent',
            default => match(strtolower($primaryRole)) {
                'admin', 'superadmin', 'owner' => 'superAdmin',
                'delivery driver', 'deliverydriver', 'driver' => 'deliveryDriver',
                'tanker driver', 'tankerdriver' => 'tankerDriver',
                'field agent', 'fieldagent', 'agent' => 'fieldAgent',
                'cashier' => 'cashier',
                default => 'staff',
            },
        };

        return $this->sendResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $primaryRole,
                'role_slug' => $roleSlug,
                'role_id' => $user->role_id,
                'warehouse_id' => $user->warehouse_id,
                'biller_id' => $user->biller_id,
            ],
            'roles' => $roles,
            'permissions' => $permissions,
            'companies' => $companiesData,
            'active_context' => [
                'company_id' => $activeCompanyId,
                'branch_id' => $activeBranchId,
                'financial_year_id' => $activeFiscalYearId,
            ],
        ], 'User identity and company context retrieved successfully');
    }
}

