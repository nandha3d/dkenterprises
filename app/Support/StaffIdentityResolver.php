<?php

namespace App\Support;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class StaffIdentityResolver
{
    private const CANONICAL_NAMES = [
        'tanker_driver' => 'K. Murugan',
        'tanker' => 'K. Murugan',
        'tankerdriver' => 'K. Murugan',
        'driver' => 'S. Karthik',
        'delivery_driver' => 'S. Karthik',
        'deliverydriver' => 'S. Karthik',
        'cashier' => 'A. Priya',
        'agent' => 'R. Senthil',
        'field_agent' => 'R. Senthil',
        'fieldagent' => 'R. Senthil',
        'admin' => 'DK Super Admin',
        'super_admin' => 'DK Super Admin',
        'superadmin' => 'DK Super Admin',
    ];

    private const ROLE_LABELS = [
        'superAdmin' => 'Super Admin',
        'tankerDriver' => 'Bulk Tanker Driver',
        'deliveryDriver' => '20L Can Delivery Driver',
        'cashier' => 'Cafe POS Cashier',
        'fieldAgent' => 'Field Collection Incharge',
        'staff' => 'Operations Staff',
    ];

    public static function resolveUserRoles(object $user): array
    {
        if (method_exists($user, 'roles')) {
            $roles = $user->roles->pluck('name')->values()->all();
        } else {
            $roles = [];
        }

        if (empty($roles) && !empty($user->role_id)) {
            $roleName = DB::table('roles')->where('id', $user->role_id)->value('name');
            if ($roleName) {
                $roles[] = $roleName;
            }
        }

        return $roles;
    }

    public static function isSuperAdmin(?object $user, array $roles = []): bool
    {
        if (!$user) {
            return false;
        }
        $roles = empty($roles) ? self::resolveUserRoles($user) : $roles;
        if ((int) ($user->role_id ?? 0) === 1) {
            return true;
        }
        $nameLower = strtolower(trim((string) ($user->name ?? '')));
        if (in_array($nameLower, ['admin', 'superadmin', 'super_admin', 'owner'], true)) {
            return true;
        }
        foreach ($roles as $r) {
            if (in_array(strtolower(trim((string) $r)), ['admin', 'superadmin', 'super_admin', 'owner'], true)) {
                return true;
            }
        }
        return false;
    }

    public static function resolveRoleSlug(object $user, array $roles = [], ?string $requestedRoleSlug = null): string
    {
        $roles = empty($roles) ? self::resolveUserRoles($user) : $roles;
        $isSuperAdmin = self::isSuperAdmin($user, $roles);

        if ($isSuperAdmin && $requestedRoleSlug !== null && trim($requestedRoleSlug) !== '') {
            return self::normalizeRoleSlug($requestedRoleSlug);
        }

        $primaryRole = strtolower(trim((string) ($roles[0] ?? 'Staff')));
        $userNameLower = strtolower(trim((string) ($user->name ?? '')));

        $slug = match ($userNameLower) {
            'admin', 'superadmin', 'super_admin' => 'superAdmin',
            'driver', 'delivery_driver' => 'deliveryDriver',
            'tanker_driver', 'tanker' => 'tankerDriver',
            'cashier' => 'cashier',
            'agent', 'field_agent' => 'fieldAgent',
            default => match ($primaryRole) {
                'admin', 'superadmin', 'super_admin', 'owner' => 'superAdmin',
                'delivery driver', 'deliverydriver', 'delivery_driver', 'driver' => 'deliveryDriver',
                'tanker driver', 'tankerdriver', 'tanker_driver' => 'tankerDriver',
                'field agent', 'fieldagent', 'field_agent', 'agent', 'incharge' => 'fieldAgent',
                'cashier' => 'cashier',
                default => $isSuperAdmin ? 'superAdmin' : 'staff',
            },
        };

        return self::normalizeRoleSlug($slug);
    }

    public static function normalizeRoleSlug(string $slug): string
    {
        return match (strtolower(trim($slug))) {
            'deliverydriver', 'delivery_driver', 'driver' => 'deliveryDriver',
            'tankerdriver', 'tanker_driver', 'tanker' => 'tankerDriver',
            'fieldagent', 'field_agent', 'agent' => 'fieldAgent',
            'superadmin', 'super_admin', 'admin' => 'superAdmin',
            'cashier' => 'cashier',
            default => $slug,
        };
    }

    public static function resolveRoleLabel(string $roleSlug): string
    {
        $norm = self::normalizeRoleSlug($roleSlug);
        return self::ROLE_LABELS[$norm] ?? ucwords(str_replace('_', ' ', $norm));
    }

    public static function looksLikeRoleSlug(?string $value): bool
    {
        $v = strtolower(trim((string) $value));
        if ($v === '') {
            return true;
        }
        return array_key_exists($v, self::CANONICAL_NAMES)
            || (bool) preg_match('/^[a-z0-9]+(_[a-z0-9]+)+$/', $v);
    }

    public static function resolveDisplayName(object $user, ?string $roleSlug = null, ?int $companyId = null): string
    {
        $raw = trim((string) ($user->name ?? ''));
        $rawLower = strtolower($raw);

        // Prefer a genuine human name from linked employee record when available
        $empQuery = DB::table('employees')->where('user_id', $user->id);
        if ($companyId !== null) {
            $empQuery->orderByRaw('CASE WHEN company_id = ? THEN 0 ELSE 1 END', [$companyId]);
        }
        $employeeName = trim((string) ($empQuery->value('name') ?? ''));
        if ($employeeName !== '' && !self::looksLikeRoleSlug($employeeName)) {
            return $employeeName;
        }

        if ($raw !== '' && !self::looksLikeRoleSlug($raw)) {
            return $raw;
        }

        if (isset(self::CANONICAL_NAMES[$rawLower])) {
            return self::CANONICAL_NAMES[$rawLower];
        }

        $normSlug = $roleSlug ? self::normalizeRoleSlug($roleSlug) : self::resolveRoleSlug($user);
        if (isset(self::CANONICAL_NAMES[strtolower($normSlug)])) {
            return self::CANONICAL_NAMES[strtolower($normSlug)];
        }

        if ($raw !== '') {
            return ucwords(str_replace(['_', '-'], ' ', $raw));
        }

        return self::resolveRoleLabel($normSlug);
    }

    public static function requiredIndustryForRole(string $roleSlug): ?string
    {
        return match (self::normalizeRoleSlug($roleSlug)) {
            'tankerDriver' => 'bulk_water',
            'deliveryDriver' => 'packaged_water',
            'cashier' => 'cafe_bakery',
            default => null,
        };
    }

    /**
     * Restrict accessible company IDs for non-super-admins strictly to their single assigned vertical company.
     */
    public static function resolveAllowedCompanyIds(object $user, ?string $roleSlug = null): array
    {
        $roles = self::resolveUserRoles($user);
        if (self::isSuperAdmin($user, $roles)) {
            return DB::table('companies')
                ->where('status', 'active')
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->values()
                ->all();
        }

        $normSlug = $roleSlug ? self::normalizeRoleSlug($roleSlug) : self::resolveRoleSlug($user, $roles);
        $requiredIndustry = self::requiredIndustryForRole($normSlug);

        $rows = DB::table('company_user')
            ->join('companies', 'company_user.company_id', '=', 'companies.id')
            ->leftJoin('company_industry_settings', 'companies.id', '=', 'company_industry_settings.company_id')
            ->where('company_user.user_id', $user->id)
            ->where('companies.status', 'active')
            ->select(
                'companies.id',
                'companies.code',
                'company_user.is_default',
                DB::raw("COALESCE(company_industry_settings.profile_key, 'general') as industry")
            )
            ->orderByDesc('company_user.is_default')
            ->orderBy('companies.id')
            ->get();

        if ($rows->isEmpty() && $requiredIndustry !== null) {
            $matchId = DB::table('company_industry_settings')
                ->where('profile_key', $requiredIndustry)
                ->value('company_id');
            return $matchId ? [(int) $matchId] : [1];
        }

        if ($requiredIndustry !== null) {
            $matched = $rows->first(fn ($r) => $r->industry === $requiredIndustry);
            if ($matched) {
                return [(int) $matched->id];
            }
        }

        // Strict single-vertical lock for all other non-super-admin staff (e.g., field agents)
        $primary = $rows->firstWhere('is_default', 1) ?? $rows->first();
        return $primary ? [(int) $primary->id] : [1];
    }

    public static function resolveLockedCompanyId(object $user, ?int $requestedCompanyId = null, ?string $roleSlug = null): int
    {
        $allowed = self::resolveAllowedCompanyIds($user, $roleSlug);
        $roles = self::resolveUserRoles($user);
        if (self::isSuperAdmin($user, $roles)) {
            if ($requestedCompanyId !== null && $requestedCompanyId > 0) {
                return $requestedCompanyId;
            }
            $defaultId = DB::table('company_user')
                ->where('user_id', $user->id)
                ->where('is_default', 1)
                ->value('company_id');
            return (int) ($defaultId ?? ($allowed[0] ?? 1));
        }

        if ($requestedCompanyId !== null && in_array($requestedCompanyId, $allowed, true)) {
            return $requestedCompanyId;
        }

        return (int) ($allowed[0] ?? 1);
    }

    /**
     * Filter an already-built collection of company items down strictly for non-super-admins.
     */
    public static function filterCompaniesForUser(object $user, Collection $companies, ?string $roleSlug = null): Collection
    {
        if (self::isSuperAdmin($user)) {
            return $companies;
        }
        $allowedIds = self::resolveAllowedCompanyIds($user, $roleSlug);
        $filtered = $companies->filter(function ($c) use ($allowedIds) {
            $id = is_array($c) ? (int) ($c['id'] ?? 0) : (int) ($c->id ?? 0);
            return in_array($id, $allowedIds, true);
        })->values();
        return $filtered->isNotEmpty() ? $filtered : $companies->take(1)->values();
    }
}

