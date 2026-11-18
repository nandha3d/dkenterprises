<?php

namespace App\Http\Middleware;

use App\Services\Platform\CompanyContext;
use App\Services\Platform\CompanyContextResolver;
use Closure;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ResolveCompanyContext
{
    public function __construct(private CompanyContextResolver $resolver)
    {
    }

    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user) {
            throw new AuthorizationException('Active user required for company access.');
        }

        $companyId = $this->id($request, 'X-Company-ID', 'company_id');
        $sessionCompany = $request->hasSession() ? $request->session()->get('company_id') : null;
        // A company header selects a new tuple; old-company dependent session IDs are invalid.
        $useSessionDependents = !$request->headers->has('X-Company-ID')
            || ($sessionCompany !== null && filter_var($sessionCompany, FILTER_VALIDATE_INT) === $companyId);
        $branchId = $this->id($request, 'X-Branch-ID', 'branch_id', $useSessionDependents);

        if ($request->is('api/v1/water/schedules*') && \App\Support\StaffIdentityResolver::isSuperAdmin($user)) {
            $vertical = strtolower(trim((string) ($request->input('vertical_type') ?? $request->query('vertical_type') ?? '')));
            if ($vertical === '' && ($scheduleId = $request->route('id'))) {
                $vertical = strtolower((string) \Illuminate\Support\Facades\DB::table('delivery_schedules')->where('id', (int) $scheduleId)->value('vertical_type'));
            }
            $resolvedScheduleCompanyId = match ($vertical) {
                'tanker' => \Illuminate\Support\Facades\DB::table('company_industry_settings')->where('profile_key', 'bulk_water')->value('company_id')
                    ?? \Illuminate\Support\Facades\DB::table('companies')->where('code', 'TMWS')->value('id'),
                'can' => \Illuminate\Support\Facades\DB::table('company_industry_settings')->where('profile_key', 'packaged_water')->value('company_id')
                    ?? \Illuminate\Support\Facades\DB::table('companies')->where('code', 'DKWATERS')->value('id'),
                default => null,
            };
            if ($resolvedScheduleCompanyId) {
                if ($companyId !== (int) $resolvedScheduleCompanyId) {
                    $branchId = null;
                }
                $companyId = (int) $resolvedScheduleCompanyId;
            } else {
                $isWaterCompany = $companyId !== null && \Illuminate\Support\Facades\DB::table('company_industry_settings')
                    ->where('company_id', $companyId)
                    ->whereIn('profile_key', ['bulk_water', 'packaged_water'])
                    ->exists();
                if ($companyId === null || !$isWaterCompany) {
                    $fallbackCompanyId = \Illuminate\Support\Facades\DB::table('company_industry_settings')->where('profile_key', 'packaged_water')->value('company_id')
                        ?? \Illuminate\Support\Facades\DB::table('companies')->where('code', 'DKWATERS')->value('id');
                    if ($fallbackCompanyId) {
                        if ($companyId !== (int) $fallbackCompanyId) {
                            $branchId = null;
                        }
                        $companyId = (int) $fallbackCompanyId;
                    }
                }
            }
        }
        if (
            $branchId === null
            && $companyId !== null
            && $request->is('api/v1/pos/*', 'api/v1/quotations*', 'api/v1/customers/*', 'api/v1/suppliers/*')
        ) {
            $branchId = \Illuminate\Support\Facades\DB::table('company_user_branches as cub')
                ->join('company_branches as cb', 'cb.id', '=', 'cub.branch_id')
                ->where('cub.company_id', $companyId)
                ->where('cub.user_id', $user->id)
                ->where('cb.company_id', $companyId)
                ->where('cb.is_active', true)
                ->orderByRaw('CASE WHEN EXISTS (SELECT 1 FROM warehouses w WHERE w.company_id = cb.company_id AND w.branch_id = cb.id AND w.is_active = 1) THEN 0 ELSE 1 END')
                ->orderByRaw("CASE WHEN cb.branch_type = 'main' THEN 0 ELSE 1 END")
                ->orderBy('cb.id')
                ->value('cb.id');
            $branchId = $branchId ? (int) $branchId : null;
        }

        try {
            $context = $this->resolver->resolve(
                $user->id,
                $companyId,
                $branchId,
                $this->id($request, 'X-Financial-Year-ID', 'financial_year_id', $useSessionDependents),
            );
        } catch (\App\Exceptions\CompanyFinancialYearSetupRequired $error) {
            $admin = $this->resolver->canManageFinancialYears($user->id, $error->companyId);
            if (!$request->expectsJson() && $admin) {
                return redirect()->route('company.financial-years.setup', ['company_id' => $error->companyId]);
            }

            return response()->json([
                'message' => $admin ? 'Company financial year requires setup or explicit historical selection.' : 'Ask a company administrator to configure a financial year.',
                'errors' => $error->errors(),
                'setup_url' => $admin ? route('api.v1.company.financial-years.setup', ['company_id' => $error->companyId]) : null,
            ], 409);
        }
        $request->attributes->set(CompanyContext::class, $context);
        $request->attributes->set('erp.company_id', $context->companyId);
        $request->attributes->set('erp.branch_id', $context->branchId);
        try {
            return $next($request);
        } finally {
            // Context belongs to this request, including under persistent workers.
            $request->attributes->remove(CompanyContext::class);
        }
    }

    private function id(Request $request, string $header, string $sessionKey, bool $useSession = true): ?int
    {
        $value = $request->header($header);
        if ($value === null && $useSession && $request->hasSession()) {
            $value = $request->session()->get($sessionKey);
        }
        if ($value === null) {
            return null;
        }
        $id = filter_var($value, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        if ($id === false) {
            throw ValidationException::withMessages([$sessionKey => 'Context ID must be a positive integer.']);
        }

        return $id;
    }
}
