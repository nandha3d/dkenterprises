<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\Account;
use App\Services\Accounting\AccountingService;
use App\Services\Platform\CompanyContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class ExpenseApiController extends BaseApiController
{
    private const LEDGER_ACCOUNTS = [
        'Kavin Axis',
        'Sasi',
        'Axis OD LOAN',
        'DeekTex',
        'Kavin KVB',
        'Kavin Canara',
        'CASH',
    ];

    private const COMPANY_TAGS = [
        'TM WATER SUPPLY',
        'DRINKAA',
        'ARAN1',
        'ARAN2',
        'ARAN',
        'FAMILY',
        'COMMON',
    ];

    private const DEFAULT_STAFF_VEHICLE_TAGS = [
        'platina',
        'SURESH',
        'TN 47 M 4585',
        'RAJA',
    ];

    protected AccountingService $accountingService;

    public function __construct(AccountingService $accountingService)
    {
        $this->accountingService = $accountingService;
    }

    /**
     * List expenses for active company.
     */
    public function index(Request $request): JsonResponse
    {
        $context = $request->attributes->get(\App\Services\Platform\CompanyContext::class);
        $companyId = $context?->companyId ?? ($request->header('X-Company-ID') ? (int) $request->header('X-Company-ID') : null);
        if ($companyId && Auth::check() && !$context) {
            $context = app(\App\Services\Platform\CompanyContextResolver::class)->resolve((int) Auth::id(), (int) $companyId);
            $companyId = $context->companyId;
        } elseif (!$companyId && Auth::check()) {
            $companyId = (int) (DB::table('company_user')->where('user_id', Auth::id())->where('is_default', 1)->value('company_id')
                ?? DB::table('company_user')->where('user_id', Auth::id())->value('company_id')
                ?? 1);
        }
        $companyId = (int) ($companyId ?: 1);
        $limit = min((int) ($request->input('limit', 50)), 100);

        $query = Expense::with(['expenseCategory:id,name,code', 'warehouse:id,name'])
            ->where('company_id', $companyId)
            ->when($request->filled('starting_date'), fn ($q) => $q->whereDate('created_at', '>=', $request->starting_date))
            ->when($request->filled('ending_date'), fn ($q) => $q->whereDate('created_at', '<=', $request->ending_date))
            ->when($request->filled('expense_category_id'), fn ($q) => $q->where('expense_category_id', $request->expense_category_id))
            ->when($request->filled('warehouse_id'), fn ($q) => $q->where('warehouse_id', $request->warehouse_id))
            ->orderBy('id', 'desc');

        $expenses = $query->paginate($limit);

        return $this->sendResponse($expenses, 'Expenses retrieved successfully');
    }

    /**
     * Quick expense capture with optional GPS & bill photo.
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'expense_category_id' => 'nullable',
            'category' => 'nullable|string',
            'amount' => 'required|numeric|min:0.01',
            'warehouse_id' => 'nullable',
            'account_id' => 'nullable',
            'note' => 'nullable|string',
            'description' => 'nullable|string',
            'entry_type' => 'nullable|in:IN,OUT,in,out',
            'company_tag' => 'nullable|string|max:100',
            'payment_account' => 'nullable|string|max:120',
            'vehicle_or_staff_tag' => 'nullable|string|max:120',
            'bill_no' => 'nullable|string|max:100',
            'entry_date' => 'nullable|date',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        [$context, $companyId, $branchId] = $this->resolveExpenseContext($request);

        $documentName = null;
        if ($request->hasFile('document')) {
            $doc = $request->file('document');
            $dir = public_path('documents/expense');
            if (!file_exists($dir)) {
                mkdir($dir, 0755, true);
            }
            $ext = $doc->getClientOriginalExtension();
            $documentName = 'exp_' . date('Ymd_His') . '_' . strtoupper(bin2hex(random_bytes(3))) . '.' . $ext;
            $doc->move($dir, $documentName);
        }

        $expense = $this->createExpenseEntry($request->all(), $companyId, $branchId, $context, $documentName);

        return $this->sendResponse($expense, 'Expense recorded successfully', 201);
    }

    /**
     * Multi-row spreadsheet batch daily cash IN/OUT & expense entry (2026 Accounts parity).
     */
    public function storeBatch(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'rows' => 'required|array|min:1|max:200',
            'rows.*.amount' => 'required|numeric|min:0.01',
            'rows.*.entry_type' => 'nullable|in:IN,OUT,in,out',
            'rows.*.entry_date' => 'nullable|date',
            'rows.*.company_tag' => 'nullable|string|max:100',
            'rows.*.payment_account' => 'nullable|string|max:120',
            'rows.*.vehicle_or_staff_tag' => 'nullable|string|max:120',
            'rows.*.bill_no' => 'nullable|string|max:100',
            'rows.*.category' => 'nullable|string|max:120',
            'rows.*.expense_category_id' => 'nullable',
            'rows.*.warehouse_id' => 'nullable',
            'rows.*.account_id' => 'nullable',
            'rows.*.note' => 'nullable|string|max:500',
            'rows.*.description' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        [$context, $companyId, $branchId] = $this->resolveExpenseContext($request);

        $created = [];
        $totalIn = 0.0;
        $totalOut = 0.0;

        DB::transaction(function () use ($request, $companyId, $branchId, $context, &$created, &$totalIn, &$totalOut) {
            foreach ($request->input('rows', []) as $row) {
                $expense = $this->createExpenseEntry($row, $companyId, $branchId, $context);
                $type = strtoupper(trim((string) ($row['entry_type'] ?? 'OUT')));
                if ($type === 'IN') {
                    $totalIn += (float) $expense->amount;
                } else {
                    $totalOut += (float) $expense->amount;
                }
                $created[] = $expense;
            }
        });

        return $this->sendResponse([
            'rows' => $created,
            'count' => count($created),
            'total_in' => round($totalIn, 2),
            'total_out' => round($totalOut, 2),
            'net_flow' => round($totalIn - $totalOut, 2),
        ], count($created) . ' ledger rows recorded successfully', 201);
    }

    /**
     * Multi-account balances & company/staff tag metadata matching 2026 Accounts Google Sheet.
     */
    public function accountsSummary(Request $request): JsonResponse
    {
        [, $companyId] = $this->resolveExpenseContext($request);

        $hasEntryType = Schema::hasColumn('expenses', 'entry_type');
        $hasPaymentAccount = Schema::hasColumn('expenses', 'payment_account');
        $hasCompanyTag = Schema::hasColumn('expenses', 'company_tag');
        $hasVehicleStaffTag = Schema::hasColumn('expenses', 'vehicle_or_staff_tag');

        $accountsMap = [];
        foreach (self::LEDGER_ACCOUNTS as $accName) {
            $accountsMap[$accName] = [
                'name' => $accName,
                'opening' => 0.0,
                'total_in' => 0.0,
                'total_out' => 0.0,
                'current' => 0.0,
            ];
        }

        $companyAccounts = DB::table('accounts')
            ->where('company_id', $companyId)
            ->where('is_active', 1)
            ->get(['name', 'initial_balance']);
        foreach ($companyAccounts as $ca) {
            $norm = $this->normalizeAccountLabel((string) $ca->name);
            if (isset($accountsMap[$norm])) {
                $accountsMap[$norm]['opening'] += (float) ($ca->initial_balance ?? 0);
            }
        }

        $selectCols = ['amount'];
        if ($hasEntryType) {
            $selectCols[] = 'entry_type';
        }
        if ($hasPaymentAccount) {
            $selectCols[] = 'payment_account';
        }
        if ($hasCompanyTag) {
            $selectCols[] = 'company_tag';
        }
        if ($hasVehicleStaffTag) {
            $selectCols[] = 'vehicle_or_staff_tag';
        }

        $rows = DB::table('expenses')
            ->where('company_id', $companyId)
            ->when($request->filled('starting_date'), fn ($q) => $q->whereDate('created_at', '>=', $request->input('starting_date')))
            ->when($request->filled('ending_date'), fn ($q) => $q->whereDate('created_at', '<=', $request->input('ending_date')))
            ->get($selectCols);

        $totalIn = 0.0;
        $totalOut = 0.0;
        $byCompanyTag = [];
        $observedTags = [];

        foreach ($rows as $row) {
            $amt = (float) ($row->amount ?? 0);
            $type = $hasEntryType ? strtoupper(trim((string) ($row->entry_type ?? 'OUT'))) : 'OUT';
            $accLabel = $this->normalizeAccountLabel((string) ($hasPaymentAccount ? ($row->payment_account ?? 'CASH') : 'CASH'));
            if (!isset($accountsMap[$accLabel])) {
                $accountsMap[$accLabel] = [
                    'name' => $accLabel,
                    'opening' => 0.0,
                    'total_in' => 0.0,
                    'total_out' => 0.0,
                    'current' => 0.0,
                ];
            }

            if ($type === 'IN') {
                $accountsMap[$accLabel]['total_in'] += $amt;
                $totalIn += $amt;
            } else {
                $accountsMap[$accLabel]['total_out'] += $amt;
                $totalOut += $amt;
            }

            if ($hasCompanyTag && !empty($row->company_tag)) {
                $tag = trim((string) $row->company_tag);
                $byCompanyTag[$tag] = $byCompanyTag[$tag] ?? ['company_tag' => $tag, 'total_in' => 0.0, 'total_out' => 0.0];
                if ($type === 'IN') {
                    $byCompanyTag[$tag]['total_in'] += $amt;
                } else {
                    $byCompanyTag[$tag]['total_out'] += $amt;
                }
            }

            if ($hasVehicleStaffTag && !empty($row->vehicle_or_staff_tag)) {
                $observedTags[] = trim((string) $row->vehicle_or_staff_tag);
            }
        }

        foreach ($accountsMap as &$acc) {
            $acc['opening'] = round($acc['opening'], 2);
            $acc['total_in'] = round($acc['total_in'], 2);
            $acc['total_out'] = round($acc['total_out'], 2);
            $acc['current'] = round($acc['opening'] + $acc['total_in'] - $acc['total_out'], 2);
        }
        unset($acc);

        $liveVehicles = [];
        if (Schema::hasTable('water_tankers')) {
            $liveVehicles = array_merge($liveVehicles, DB::table('water_tankers')->where('is_active', true)->pluck('vehicle_number')->all());
        }
        if (Schema::hasTable('water_can_routes')) {
            $liveVehicles = array_merge($liveVehicles, DB::table('water_can_routes')->where('is_active', true)->whereNotNull('vehicle_no')->pluck('vehicle_no')->all());
        }
        $liveEmployees = Schema::hasTable('employees')
            ? DB::table('employees')->where('is_active', true)->pluck('name')->all()
            : [];

        $vehicleStaffTags = array_values(array_unique(array_filter(array_merge(
            self::DEFAULT_STAFF_VEHICLE_TAGS,
            $observedTags,
            $liveVehicles,
            $liveEmployees
        ))));

        return $this->sendResponse([
            'accounts' => array_values($accountsMap),
            'total_in' => round($totalIn, 2),
            'total_out' => round($totalOut, 2),
            'net_balance' => round($totalIn - $totalOut, 2),
            'company_tags' => self::COMPANY_TAGS,
            'vehicle_staff_tags' => $vehicleStaffTags,
            'by_company_tag' => array_values($byCompanyTag),
        ], 'Expense accounts summary retrieved successfully');
    }

    private function resolveExpenseContext(Request $request): array
    {
        $context = $request->attributes->get(CompanyContext::class);
        $companyId = $context?->companyId ?? ($request->header('X-Company-ID') ? (int) $request->header('X-Company-ID') : null);
        if (!$companyId && Auth::check()) {
            $companyId = DB::table('company_user')->where('user_id', Auth::id())->where('is_default', 1)->value('company_id')
                ?? DB::table('company_user')->where('user_id', Auth::id())->value('company_id')
                ?? 1;
        }
        $companyId = (int) ($companyId ?: 1);
        $branchId = $context?->branchId ?? ($request->header('X-Branch-ID') ? (int) $request->header('X-Branch-ID') : null);
        if ($branchId === null && Auth::check()) {
            $branchId = DB::table('company_user_branches as cub')
                ->join('company_branches as cb', 'cb.id', '=', 'cub.branch_id')
                ->where('cub.company_id', $companyId)
                ->where('cub.user_id', Auth::id())
                ->where('cb.company_id', $companyId)
                ->where('cb.is_active', 1)
                ->orderByRaw("CASE WHEN cb.branch_type = 'main' THEN 0 ELSE 1 END")
                ->orderBy('cb.id')
                ->value('cb.id');
            $branchId = $branchId ? (int) $branchId : null;
        }
        $branchId = (int) ($branchId
            ?? DB::table('company_branches')->where('company_id', $companyId)->where('is_active', 1)->orderBy('id')->value('id')
            ?? 1);

        if (!$context && Auth::check()) {
            try {
                $context = app(\App\Services\Platform\CompanyContextResolver::class)->resolve(Auth::id(), $companyId, $branchId);
            } catch (\Illuminate\Auth\Access\AuthorizationException $e) {
                throw $e;
            } catch (\Throwable $e) {
                $context = null;
            }
        }
        if ($context) {
            $companyId = $context->companyId;
            $branchId = $context->branchId;
        }

        return [$context, $companyId, $branchId];
    }

    private function createExpenseEntry(
        array $row,
        int $companyId,
        int $branchId,
        ?CompanyContext $context,
        ?string $documentName = null
    ): Expense {
        $expenseCategoryId = $row['expense_category_id'] ?? null;
        if (!$expenseCategoryId && !empty($row['category'])) {
            $expenseCategoryId = DB::table('expense_categories')
                ->where('name', 'like', '%' . $row['category'] . '%')
                ->value('id');
        }
        $expenseCategoryId = $expenseCategoryId ?? (DB::table('expense_categories')->where('is_active', true)->value('id') ?? 1);

        $refNo = 'EXP-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
        $amount = (float) $row['amount'];
        $entryType = strtoupper(trim((string) ($row['entry_type'] ?? 'OUT')));
        if (!in_array($entryType, ['IN', 'OUT'], true)) {
            $entryType = 'OUT';
        }
        $paymentAccount = trim((string) ($row['payment_account'] ?? 'CASH'));
        if ($paymentAccount === '') {
            $paymentAccount = 'CASH';
        }
        $entryDate = !empty($row['entry_date']) ? substr((string) $row['entry_date'], 0, 10) : date('Y-m-d');

        $warehouseId = $this->resolveCompanyWarehouseId(
            $companyId,
            $branchId,
            !empty($row['warehouse_id']) ? (int) $row['warehouse_id'] : null
        );
        $accountId = $row['account_id'] ?? $this->resolveLedgerAccountId($companyId, $paymentAccount);

        $rawDesc = $row['note'] ?? $row['description'] ?? 'Mobile Field Expense';
        $noteText = trim((!empty($row['category']) ? "[{$row['category']}] " : '') . $rawDesc);
        if (!empty($row['latitude'])) {
            $noteText .= " [GPS: {$row['latitude']}, {$row['longitude']}]";
        }

        $attributes = [
            'reference_no' => $refNo,
            'expense_category_id' => $expenseCategoryId,
            'warehouse_id' => $warehouseId,
            'account_id' => $accountId,
            'amount' => $amount,
            'user_id' => Auth::id() ?? 1,
            'note' => $noteText,
            'document' => $documentName,
            'company_id' => $companyId,
        ];

        $guardedCols = [
            'entry_type' => $entryType,
            'company_tag' => !empty($row['company_tag']) ? trim((string) $row['company_tag']) : null,
            'payment_account' => $paymentAccount,
            'vehicle_or_staff_tag' => !empty($row['vehicle_or_staff_tag']) ? trim((string) $row['vehicle_or_staff_tag']) : null,
            'bill_no' => !empty($row['bill_no']) ? trim((string) $row['bill_no']) : null,
            'entry_date' => $entryDate,
        ];
        foreach ($guardedCols as $col => $val) {
            if (Schema::hasColumn('expenses', $col)) {
                $attributes[$col] = $val;
            }
        }

        $expense = new Expense();
        $expense->forceFill($attributes);
        $expense->save();

        if ($context) {
            try {
                $isBank = stripos($paymentAccount, 'cash') === false;
                $cashOrBankAcc = $this->accountingService->getAccount($isBank ? 'bank' : 'cash', $context)?->id
                    ?? \App\Models\Accounting\ChartOfAccount::forCompany($context)->where('is_active', true)->whereDoesntHave('children')
                        ->where(fn ($q) => $isBank
                            ? $q->where('code', '1020')->orWhere('control_type', 'bank')
                            : $q->where('code', '1010')->orWhere('control_type', 'cash'))
                        ->value('id')
                    ?? $this->accountingService->getAccount('cash', $context)?->id;

                $expAcc = $this->accountingService->getAccount('expense', $context)?->id
                    ?? \App\Models\Accounting\ChartOfAccount::forCompany($context)->where('is_active', true)->whereDoesntHave('children')
                        ->where('type', 'expense')->orderBy('code')->value('id');

                if ($entryType === 'IN') {
                    $revAcc = $this->accountingService->getAccount('sales', $context)?->id
                        ?? \App\Models\Accounting\ChartOfAccount::forCompany($context)->where('is_active', true)->whereDoesntHave('children')
                            ->where('type', 'revenue')->orderBy('code')->value('id')
                        ?? $expAcc;
                    if ($cashOrBankAcc && $revAcc) {
                        $this->accountingService->postJournalEntry([
                            'entry_date' => $entryDate,
                            'reference_type' => 'expense',
                            'reference_id' => $expense->id,
                            'reference_no' => $refNo,
                            'description' => "Cash/Bank Inflow [{$refNo}] - {$noteText}",
                            'created_by' => Auth::id() ?? 1,
                        ], [
                            ['chart_of_account_id' => (int) $cashOrBankAcc, 'debit' => $amount, 'credit' => 0, 'memo' => "Inflow to {$paymentAccount}"],
                            ['chart_of_account_id' => (int) $revAcc, 'debit' => 0, 'credit' => $amount, 'memo' => 'Ledger Inflow'],
                        ], $context);
                    }
                } elseif ($expAcc && $cashOrBankAcc) {
                    $this->accountingService->postJournalEntry([
                        'entry_date' => $entryDate,
                        'reference_type' => 'expense',
                        'reference_id' => $expense->id,
                        'reference_no' => $refNo,
                        'description' => "Operational Expense [{$refNo}] - {$noteText}",
                        'created_by' => Auth::id() ?? 1,
                    ], [
                        ['chart_of_account_id' => (int) $expAcc, 'debit' => $amount, 'credit' => 0, 'memo' => 'Operating Expense'],
                        ['chart_of_account_id' => (int) $cashOrBankAcc, 'debit' => 0, 'credit' => $amount, 'memo' => "Disbursed from {$paymentAccount}"],
                    ], $context);
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Mobile expense journal post warning: ' . $e->getMessage());
            }
        }

        return $expense;
    }

    private function resolveLedgerAccountId(int $companyId, string $paymentAccount): int
    {
        $norm = $this->normalizeAccountLabel($paymentAccount);
        $matched = DB::table('accounts')
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->where('name', 'like', '%' . $norm . '%')
            ->orderBy('id')
            ->value('id');
        if ($matched) {
            return (int) $matched;
        }
        return (int) (DB::table('accounts')->where('company_id', $companyId)->where('is_active', true)->orderBy('id')->value('id') ?? 1);
    }

    private function normalizeAccountLabel(string $raw): string
    {
        $upper = strtoupper(trim($raw));
        if ($upper === '' || $upper === 'CASH') {
            return 'CASH';
        }
        if (str_contains($upper, 'AXIS') && str_contains($upper, 'OD')) {
            return 'Axis OD LOAN';
        }
        if (str_contains($upper, 'KAVIN') && str_contains($upper, 'AXIS')) {
            return 'Kavin Axis';
        }
        if (str_contains($upper, 'KVB')) {
            return 'Kavin KVB';
        }
        if (str_contains($upper, 'CANARA')) {
            return 'Kavin Canara';
        }
        if (str_contains($upper, 'DEEKTEX')) {
            return 'DeekTex';
        }
        if (str_contains($upper, 'SASI')) {
            return 'Sasi';
        }
        return trim($raw);
    }

    /**
     * List active expense categories.
     */
    public function categories(Request $request): JsonResponse
    {
        $categories = ExpenseCategory::where('is_active', true)
            ->select('id', 'code', 'name')
            ->orderBy('name')
            ->get();

        return $this->sendResponse($categories, 'Expense categories retrieved');
    }

    private function resolveCompanyWarehouseId(int $companyId, int $branchId, ?int $requestedId = null): int
    {
        if ($requestedId) {
            $owned = DB::table('warehouses')->where('company_id', $companyId)->where('branch_id', $branchId)->where('id', $requestedId)->value('id')
                ?? DB::table('warehouses')->where('company_id', $companyId)->where('id', $requestedId)->value('id');
            if ($owned) {
                return (int) $owned;
            }
            $foreignQuery = DB::table('warehouses');
            if ($foreignQuery instanceof \App\Support\Database\CompanyScopedBuilder) {
                $foreignQuery->withoutCompanyScope();
            }
            if ($foreignQuery->where('id', $requestedId)->whereNotNull('company_id')->where('company_id', '!=', $companyId)->exists()) {
                throw \Illuminate\Validation\ValidationException::withMessages(['warehouse_id' => 'Select a company-owned warehouse.']);
            }
        }
        $existing = DB::table('warehouses')->where('company_id', $companyId)->where('branch_id', $branchId)->where('is_active', 1)->orderBy('id')->value('id')
            ?? DB::table('warehouses')->where('company_id', $companyId)->where('branch_id', $branchId)->orderBy('id')->value('id')
            ?? DB::table('warehouses')->where('company_id', $companyId)->where('is_active', 1)->orderBy('id')->value('id');
        if ($existing) {
            return (int) $existing;
        }
        return (int) DB::table('warehouses')->insertGetId([
            'name' => "Branch {$branchId} Warehouse",
            'phone' => '0000000000',
            'address' => 'Main Branch',
            'is_active' => 1,
            'company_id' => $companyId,
            'branch_id' => $branchId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

