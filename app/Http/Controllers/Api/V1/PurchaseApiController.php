<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Purchase;
use App\Models\Supplier;
use App\Services\Platform\CompanyContext;
use App\Services\Platform\CompanyContextResolver;
use Illuminate\Database\Eloquent\Builder;
use App\Services\ERP\PurchaseService;
use App\Models\Accounting\JournalEntry;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Exception;

class PurchaseApiController extends BaseApiController
{
    private const DEFAULT_REGULAR_VENDORS = [
        ['name' => 'Amirtha Milk', 'default_category' => 'Milk', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Local Milk Vendor 2', 'default_category' => 'Milk', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Sri Murugan Groceries', 'default_category' => 'Groceries', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Ice Cream Distributor', 'default_category' => 'Ice Cream', 'preferred_payment_mode' => 'GPay'],
        ['name' => 'Maida & Bakery Flour Mill', 'default_category' => 'Flour', 'preferred_payment_mode' => 'Credit'],
        ['name' => 'Pazhamudir Cholai Fruits', 'default_category' => 'Fruits', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Onion & Vegetable Wholesale', 'default_category' => 'Vegetables', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Chendhur Gas Agency', 'default_category' => 'Commercial LPG', 'preferred_payment_mode' => 'GPay'],
        ['name' => 'Prabu Auto Spares', 'default_category' => 'Fleet Maintenance', 'preferred_payment_mode' => 'Cash'],
        ['name' => 'Satha Workshop - Sakthi Auto', 'default_category' => 'Fleet Maintenance', 'preferred_payment_mode' => 'Cash'],
    ];

    protected PurchaseService $purchaseService;

    public function __construct(PurchaseService $purchaseService)
    {
        $this->purchaseService = $purchaseService;
    }

    private function queryFor(CompanyContext $context): Builder
    {
        return Purchase::visibleIn($context)->with([
            'supplier' => fn ($q) => $q->forCompany($context),
            'warehouse' => fn ($q) => $q->forCompany($context),
            'payments' => fn ($q) => $q->visibleIn($context),
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate(['per_page' => 'sometimes|integer|min:1|max:100']);
        $query = $this->queryFor($this->companyContext($request));

        if ($request->filled('warehouse_id')) {
            $query->where('warehouse_id', $request->warehouse_id);
        }
        if ($request->filled('supplier_id')) {
            $query->where('supplier_id', $request->supplier_id);
        }
        if ($request->filled('payment_status')) {
            $query->where('payment_status', $request->payment_status);
        }

        $perPage = (int) $request->input('per_page', 15);
        $purchases = $query->orderBy('id', 'desc')->paginate($perPage);

        return $this->sendResponse(\App\Http\Resources\CommercialDocumentResource::collection($purchases->getCollection())->resolve($request), 'Purchases retrieved successfully', 200, [
            'pagination' => [
                'total' => $purchases->total(),
                'per_page' => $purchases->perPage(),
                'current_page' => $purchases->currentPage(),
                'last_page' => $purchases->lastPage(),
            ]
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $purchase = $this->queryFor($context)->with([
            'productPurchases' => fn ($q) => $q->forCompany($context)
                ->whereHas('product', fn ($q) => $q->forCompany($context))
                ->with(['product' => fn ($q) => $q->catalogFor($context)]),
        ])->find($id);

        if (!$purchase) {
            return $this->sendError('Purchase not found', [], 404);
        }

        $journalEntry = JournalEntry::withOwnedItems($context)
            ->where('reference_type', 'purchase')
            ->where('reference_id', $purchase->id)
            ->first();

        $data = (new \App\Http\Resources\CommercialDocumentResource($purchase))->resolve($request);
        $data['journal_entry'] = $journalEntry;

        return $this->sendResponse($data, 'Purchase retrieved successfully');
    }

    public function store(Request $request): JsonResponse
    {
        if (config('commercial.enabled')) {
            return app(\App\Http\Middleware\RequireSharedCommercial::class)->handle($request,
                fn ($request) => app(\App\Http\Controllers\CommercialController::class)->store($request, 'purchase'));
        }
        $validator = Validator::make($request->all(), [
            'supplier_id' => 'required|integer|exists:suppliers,id',
            'warehouse_id' => 'required|integer|exists:warehouses,id',
            'status' => 'sometimes|integer|in:1,2,3,4',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.qty' => 'required|numeric|min:0.01',
            'items.*.net_unit_cost' => 'required|numeric|min:0',
            'items.*.received_qty' => 'required_if:status,2|numeric|min:0|lte:items.*.qty',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        try {
            $purchase = $this->purchaseService->createPurchase($request->all(), $request->user()?->id, $this->companyContext($request));
            return $this->sendResponse($purchase, 'Purchase created successfully', 201);
        } catch (\Illuminate\Validation\ValidationException | \Illuminate\Auth\Access\AuthorizationException | \Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            throw $e;
        } catch (Exception $e) {
            return $this->sendError($e->getMessage(), [], 400);
        }
    }

    public function addPayment(Request $request, int $id): JsonResponse
    {
        if (config('commercial.enabled')) {
            return app(\App\Http\Middleware\RequireSharedCommercial::class)->handle($request,
                fn ($request) => app(\App\Http\Controllers\CommercialController::class)->payment($request, 'purchase', $id));
        }
        $context = $this->companyContext($request);
        $purchase = Purchase::visibleIn($context)->find($id);
        if (!$purchase) {
            return $this->sendError('Purchase not found', [], 404);
        }
        $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'paying_method' => 'required|string',
            'account_id' => 'nullable|integer|min:1',
        ]);
        try {
            $payment = $this->purchaseService->addPayment($purchase, $request->all(), $request->user()->id, $context);
            return $this->sendResponse($payment, 'Supplier payment recorded and posted successfully', 201);
        } catch (\Illuminate\Validation\ValidationException | \Illuminate\Auth\Access\AuthorizationException | \Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            throw $e;
        } catch (Exception $e) {
            return $this->sendError($e->getMessage(), [], 400);
        }
    }

    /**
     * List regular quick-purchase vendors (with fallback presets) + recent quick purchases.
     */
    public function regularVendors(Request $request): JsonResponse
    {
        $context = $this->resolvePurchaseContext($request);
        $companyId = $context->companyId;

        $hasRegularCol = Schema::hasColumn('suppliers', 'is_regular_vendor');
        $hasCategoryCol = Schema::hasColumn('suppliers', 'default_category');
        $hasModeCol = Schema::hasColumn('suppliers', 'preferred_payment_mode');

        $selectCols = ['id', 'name', 'company_name', 'phone_number', 'city', 'company_id'];
        if ($hasRegularCol) {
            $selectCols[] = 'is_regular_vendor';
        }
        if ($hasCategoryCol) {
            $selectCols[] = 'default_category';
        }
        if ($hasModeCol) {
            $selectCols[] = 'preferred_payment_mode';
        }

        $vendors = DB::table('suppliers')
            ->where('company_id', $companyId)
            ->where('is_active', 1)
            ->when($hasRegularCol, fn ($q) => $q->orderByDesc('is_regular_vendor'))
            ->orderBy('name')
            ->get($selectCols);

        if ($vendors->isEmpty()) {
            $vendors = collect(self::DEFAULT_REGULAR_VENDORS)->map(fn ($v) => (object) [
                'id' => null,
                'name' => $v['name'],
                'company_name' => $v['name'],
                'phone_number' => '',
                'city' => 'Erode',
                'company_id' => $companyId,
                'is_regular_vendor' => true,
                'default_category' => $v['default_category'],
                'preferred_payment_mode' => $v['preferred_payment_mode'],
                'is_fallback_preset' => true,
            ]);
        }

        $recentPurchases = DB::table('purchases as p')
            ->leftJoin('suppliers as s', 'p.supplier_id', '=', 's.id')
            ->where('p.company_id', $companyId)
            ->whereNull('p.deleted_at')
            ->orderByDesc('p.id')
            ->limit(10)
            ->select(
                'p.id',
                'p.reference_no',
                'p.supplier_id',
                DB::raw("COALESCE(s.name, 'Regular Supplier') as supplier_name"),
                'p.grand_total',
                'p.paid_amount',
                'p.payment_status',
                'p.note',
                'p.created_at'
            )
            ->get();

        return $this->sendResponse([
            'vendors' => $vendors->values()->all(),
            'recent_purchases' => $recentPurchases->values()->all(),
            'company_tags' => ['ARAN1', 'ARAN2', 'ARAN', 'TM WATER SUPPLY', 'DRINKAA', 'COMMON'],
        ], 'Regular vendors retrieved successfully');
    }

    /**
     * Fast mobile purchase bill / regular supplier entry (supports inline supplier creation & Cash/GPay/Credit).
     */
    public function quickStore(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'supplier_id' => 'nullable|integer|min:1',
            'supplier_name' => 'nullable|string|max:255',
            'supplier_phone' => 'nullable|string|max:50',
            'amount' => 'required|numeric|min:0.01',
            'payment_mode' => 'nullable|string|max:50',
            'payment_account' => 'nullable|string|max:120',
            'bill_no' => 'nullable|string|max:100',
            'bill_date' => 'nullable|date',
            'company_tag' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:120',
            'description' => 'nullable|string|max:500',
            'note' => 'nullable|string|max:500',
            'warehouse_id' => 'nullable|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        if (!$request->filled('supplier_id') && trim((string) $request->input('supplier_name', '')) === '') {
            return $this->sendError('Validation Error', ['supplier_name' => ['Either supplier_id or supplier_name is required.']], 422);
        }

        $context = $this->resolvePurchaseContext($request);
        $companyId = $context->companyId;
        $branchId = $context->branchId;
        $userId = (int) (Auth::id() ?? 1);

        $amount = round((float) $request->input('amount'), 2);
        $paymentMode = trim((string) ($request->input('payment_mode') ?? 'Cash'));
        $paymentAccount = trim((string) ($request->input('payment_account') ?? ($paymentMode === 'Cash' ? 'CASH' : 'Kavin Axis')));
        $billNo = $request->filled('bill_no') ? trim((string) $request->input('bill_no')) : null;
        $billDate = $request->filled('bill_date') ? substr((string) $request->input('bill_date'), 0, 10) : now()->toDateString();
        $companyTag = $request->filled('company_tag') ? trim((string) $request->input('company_tag')) : null;
        $category = $request->filled('category') ? trim((string) $request->input('category')) : null;
        $desc = trim((string) ($request->input('description') ?? $request->input('note') ?? 'Quick Purchase Bill'));

        $isCredit = stripos($paymentMode, 'credit') !== false;
        $paidAmount = $isCredit ? 0.0 : $amount;
        $paymentStatus = $isCredit ? 2 : 4; // 4 = Paid, 2 = Due

        $result = DB::transaction(function () use (
            $request, $companyId, $branchId, $context, $userId,
            $amount, $paidAmount, $paymentStatus, $paymentMode, $paymentAccount,
            $billNo, $billDate, $companyTag, $category, $desc
        ) {
            $supplierId = $this->resolveOrCreateQuickSupplier(
                $companyId,
                $request->filled('supplier_id') ? (int) $request->input('supplier_id') : null,
                $request->input('supplier_name'),
                $request->input('supplier_phone'),
                $category,
                $paymentMode
            );
            $supplier = DB::table('suppliers')->where('id', $supplierId)->first();

            $warehouseId = $this->resolveCompanyWarehouseId(
                $companyId,
                $branchId,
                $request->filled('warehouse_id') ? (int) $request->input('warehouse_id') : null
            );

            $refNo = 'QPB-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
            $noteParts = array_filter([
                $companyTag ? "[{$companyTag}]" : null,
                $category ? "[{$category}]" : null,
                $billNo ? "Bill #{$billNo}" : null,
                $desc,
                "Mode: {$paymentMode}" . ($paymentAccount !== '' ? " ({$paymentAccount})" : ''),
            ]);
            $fullNote = implode(' · ', $noteParts);

            $currencyId = (int) (DB::table('currencies')->where('is_active', 1)->orderBy('id')->value('id') ?: 1);
            $purchaseData = [
                'reference_no' => $refNo,
                'user_id' => $userId,
                'warehouse_id' => $warehouseId,
                'supplier_id' => $supplierId,
                'currency_id' => $currencyId,
                'exchange_rate' => 1,
                'item' => 1,
                'total_qty' => 1,
                'total_discount' => 0,
                'total_tax' => 0,
                'total_cost' => $amount,
                'order_tax_rate' => 0,
                'order_tax' => 0,
                'order_discount' => 0,
                'shipping_cost' => 0,
                'grand_total' => $amount,
                'paid_amount' => $paidAmount,
                'status' => 1,
                'payment_status' => $paymentStatus,
                'note' => $fullNote,
                'company_id' => $companyId,
                'created_at' => $billDate . ' ' . now()->format('H:i:s'),
                'updated_at' => now(),
            ];

            if (Schema::hasColumn('purchases', 'branch_id')) {
                $purchaseData['branch_id'] = $branchId;
            }
            if (Schema::hasColumn('purchases', 'financial_year_id')) {
                $purchaseData['financial_year_id'] = $context->financialYearId;
            }
            if (Schema::hasColumn('purchases', 'posted_at')) {
                $purchaseData['posted_at'] = now();
            }
            if (Schema::hasColumn('purchases', 'supplier_invoice_no')) {
                $purchaseData['supplier_invoice_no'] = $billNo;
            }
            if (Schema::hasColumn('purchases', 'supplier_invoice_date')) {
                $purchaseData['supplier_invoice_date'] = $billDate;
            }
            if (Schema::hasColumn('purchases', 'purchase_type')) {
                $purchaseData['purchase_type'] = 'quick_bill';
            }

            $purchaseId = (int) DB::table('purchases')->insertGetId($purchaseData);

            if ($paidAmount > 0) {
                $accountId = (int) (DB::table('accounts')
                    ->where('company_id', $companyId)
                    ->where('is_active', 1)
                    ->orderBy('id')
                    ->value('id') ?: 1);
                DB::table('payments')->insert([
                    'purchase_id' => $purchaseId,
                    'payment_reference' => 'PPAY-' . $refNo,
                    'user_id' => $userId,
                    'account_id' => $accountId,
                    'amount' => $paidAmount,
                    'currency_id' => $currencyId,
                    'exchange_rate' => 1,
                    'payment_at' => $billDate,
                    'change' => 0,
                    'paying_method' => $paymentMode,
                    'payment_note' => $fullNote,
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return [
                'purchase' => DB::table('purchases')->where('id', $purchaseId)->first(),
                'supplier' => $supplier,
            ];
        });

        return $this->sendResponse([
            'id' => (int) ($result['purchase']->id ?? 0),
            'reference_no' => $result['purchase']->reference_no ?? null,
            'supplier_id' => (int) ($result['supplier']->id ?? 0),
            'supplier_name' => $result['supplier']->name ?? $request->input('supplier_name'),
            'amount' => $amount,
            'paid_amount' => $paidAmount,
            'payment_mode' => $paymentMode,
            'payment_account' => $paymentAccount,
            'payment_status' => $isCredit ? 'credit' : 'paid',
            'bill_no' => $billNo,
            'bill_date' => $billDate,
            'company_tag' => $companyTag,
            'category' => $category,
            'description' => $desc,
            'purchase' => $result['purchase'],
        ], 'Quick purchase bill recorded successfully', 201);
    }

    private function resolvePurchaseContext(Request $request): CompanyContext
    {
        $context = $request->attributes->get(CompanyContext::class);
        if ($context instanceof CompanyContext) {
            return $context;
        }
        $companyId = $request->header('X-Company-ID') ? (int) $request->header('X-Company-ID') : null;
        $branchId = $request->header('X-Branch-ID') ? (int) $request->header('X-Branch-ID') : null;
        return app(CompanyContextResolver::class)->resolve((int) (Auth::id() ?? 1), $companyId, $branchId);
    }

    private function resolveOrCreateQuickSupplier(
        int $companyId,
        ?int $supplierId,
        ?string $supplierName,
        ?string $supplierPhone,
        ?string $category,
        string $paymentMode
    ): int {
        if ($supplierId) {
            $owned = DB::table('suppliers')->where('company_id', $companyId)->where('id', $supplierId)->value('id');
            if ($owned) {
                return (int) $owned;
            }
            $foreign = DB::table('suppliers')->where('id', $supplierId)->whereNotNull('company_id')->where('company_id', '!=', $companyId)->exists();
            if ($foreign) {
                throw \Illuminate\Validation\ValidationException::withMessages(['supplier_id' => 'Select a company-owned supplier.']);
            }
        }

        $cleanName = trim((string) ($supplierName ?? ''));
        if ($cleanName !== '') {
            $existing = DB::table('suppliers')
                ->where('company_id', $companyId)
                ->whereRaw('LOWER(name) = ?', [strtolower($cleanName)])
                ->orderBy('id')
                ->value('id');
            if ($existing) {
                return (int) $existing;
            }

            $attrs = [
                'company_id' => $companyId,
                'name' => $cleanName,
                'print_name' => $cleanName,
                'company_name' => $cleanName,
                'phone_number' => trim((string) ($supplierPhone ?? '')) ?: '0000000000',
                'address' => 'Erode',
                'city' => 'Erode',
                'is_active' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ];
            if (Schema::hasColumn('suppliers', 'is_regular_vendor')) {
                $attrs['is_regular_vendor'] = true;
            }
            if (Schema::hasColumn('suppliers', 'default_category') && $category) {
                $attrs['default_category'] = $category;
            }
            if (Schema::hasColumn('suppliers', 'preferred_payment_mode')) {
                $attrs['preferred_payment_mode'] = $paymentMode;
            }

            return (int) DB::table('suppliers')->insertGetId($attrs);
        }

        throw \Illuminate\Validation\ValidationException::withMessages(['supplier_name' => 'Supplier name is required.']);
    }

    private function resolveCompanyWarehouseId(int $companyId, int $branchId, ?int $requestedId = null): int
    {
        if ($requestedId) {
            $owned = DB::table('warehouses')->where('company_id', $companyId)->where('id', $requestedId)->value('id');
            if ($owned) {
                return (int) $owned;
            }
        }
        $existing = DB::table('warehouses')->where('company_id', $companyId)->where('branch_id', $branchId)->where('is_active', 1)->orderBy('id')->value('id')
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
