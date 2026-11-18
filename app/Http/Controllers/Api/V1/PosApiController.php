<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Account;
use App\Models\Biller;
use App\Models\CashRegister;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\Payment;
use App\Models\Product;
use App\Models\Product_Sale;
use App\Models\ProductReturn;
use App\Models\ProductVariant;
use App\Models\Returns;
use App\Models\Sale;
use App\Models\Table;
use App\Models\Unit;
use App\Models\Warehouse;
use App\Services\Accounting\AccountingService;
use App\Services\Inventory\InventoryMovementService;
use App\Services\Inventory\StockLine;
use App\Services\Inventory\StockMovementCommand;
use App\Services\ERP\CompanyWriteGuard;
use App\Services\Platform\CompanyContext;
use App\Services\Platform\DocumentNumberService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

/**
 * ERP-backed Point of Sale controller for mobile & tablet terminals.
 *
 * Bridges CashRegister shifts (X/Z reports), dine-in Table occupancy, held drafts
 * (`sale_status = 3`), multi-tender split payments (`Cash`, `UPI`, `Card`, `Credit`),
 * InventoryMovementService stock ledger deductions/restocks, DocumentNumberService
 * sequences, and balanced AccountingService general ledger postings.
 */
class PosApiController extends BaseApiController
{
    public function __construct(
        private readonly CompanyWriteGuard $guard,
        private readonly DocumentNumberService $numbers,
        private readonly InventoryMovementService $inventory,
        private readonly AccountingService $accounting,
    ) {
    }

    /**
     * Load POS terminal bootstrap payload: settings, warehouses, tables, menu catalog,
     * customers, billers, and the authenticated user's currently open cash register shift.
     */
    public function bootstrap(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $userId = (int) Auth::id();

        $warehouses = Warehouse::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->orderByRaw('CASE WHEN branch_id = ? THEN 0 ELSE 1 END', [$context->branchId])
            ->orderBy('id')
            ->get(['id', 'name', 'branch_id', 'phone', 'address']);

        $requestedWarehouseId = $request->filled('warehouse_id') ? (int) $request->input('warehouse_id') : null;
        $activeWarehouse = $warehouses->firstWhere('id', $requestedWarehouseId) ?? $warehouses->first();
        $warehouseId = $activeWarehouse?->id;

        $openRegister = $this->findOpenRegister($userId, $companyId, $warehouseId);
        if ($openRegister && $warehouseId === null) {
            $warehouseId = (int) $openRegister->warehouse_id;
        }

        $categories = DB::table('categories')
            ->where('is_active', true)
            ->where('company_id', $companyId)
            ->orderBy('name')
            ->get(['id', 'name', 'parent_id', 'image']);

        $productsQuery = Product::query()
            ->where('is_active', true)
            ->where('company_id', $companyId)
            ->orderByDesc('featured')
            ->orderBy('name');

        $products = $productsQuery->take(200)->get([
            'id', 'name', 'code', 'type', 'price', 'cost', 'category_id',
            'unit_id', 'sale_unit_id', 'tax_id', 'tax_method', 'image', 'featured',
            'qty', 'alert_quantity', 'is_active',
        ]);

        $stockByProduct = $warehouseId
            ? DB::table('product_warehouse')
                ->where('warehouse_id', $warehouseId)
                ->whereIn('product_id', $products->pluck('id'))
                ->selectRaw('product_id, SUM(qty) as warehouse_qty')
                ->groupBy('product_id')
                ->pluck('warehouse_qty', 'product_id')
            : collect();

        $taxRates = DB::table('taxes')
            ->pluck('rate', 'id');

        $formattedProducts = $products->map(function (Product $product) use ($stockByProduct, $taxRates) {
            $stock = $stockByProduct->has($product->id)
                ? (float) $stockByProduct->get($product->id)
                : (float) ($product->qty ?? 0);

            return [
                'id' => (int) $product->id,
                'name' => (string) $product->name,
                'code' => (string) ($product->code ?? ''),
                'type' => (string) ($product->type ?? 'standard'),
                'price' => round((float) $product->price, 2),
                'cost' => round((float) ($product->cost ?? 0), 2),
                'category_id' => $product->category_id ? (int) $product->category_id : null,
                'tax_rate' => $product->tax_id ? (float) ($taxRates->get($product->tax_id) ?? 0) : 0.0,
                'tax_method' => (int) ($product->tax_method ?? 1),
                'image' => $product->image,
                'is_featured' => (bool) ($product->featured ?? false),
                'is_available' => (bool) ($product->is_active ?? true),
                'stock_qty' => round($stock, 2),
                'alert_quantity' => round((float) ($product->alert_quantity ?? 5), 2),
            ];
        })->values();

        $posSetting = DB::table('pos_setting')->latest('id')->first();
        $defaultCustomerId = $this->resolveDefaultCustomerId($companyId, $posSetting?->customer_id);

        $customersRaw = Customer::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->orderByRaw("CASE WHEN LOWER(name) LIKE '%walk%' THEN 0 ELSE 1 END")
            ->orderBy('name')
            ->take(50)
            ->get(['id', 'name', 'phone_number', 'company_name', 'credit_limit', 'points']);

        $customerDues = Sale::query()
            ->where('company_id', $companyId)
            ->whereNull('deleted_at')
            ->where('sale_status', 1)
            ->whereRaw('grand_total > paid_amount')
            ->selectRaw('customer_id, SUM(grand_total - paid_amount) as due_amount')
            ->groupBy('customer_id')
            ->pluck('due_amount', 'customer_id');

        $customers = $customersRaw->map(fn ($c) => [
            'id' => (int) $c->id,
            'name' => (string) $c->name,
            'phone_number' => $c->phone_number,
            'company_name' => $c->company_name,
            'credit_limit' => round((float) ($c->credit_limit ?? 0), 2),
            'due_amount' => round((float) ($customerDues->get($c->id) ?? 0), 2),
            'points' => round((float) ($c->points ?? 0), 2),
        ])->values();

        $billers = Biller::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->orderBy('id')
            ->get(['id', 'name', 'company_name', 'phone_number']);

        $heldCount = Sale::query()
            ->where('company_id', $companyId)
            ->where('sale_status', 3)
            ->count();

        $supportsTables = $this->companySupportsDiningTables($companyId);
        $companyRow = \App\Models\Company::find($companyId);
        $companySettings = is_array($companyRow?->settings_json) ? $companyRow->settings_json : [];
        $companyName = $companyRow?->trade_name ?: ($companyRow?->legal_name ?: 'ERP Company');
        $companyGstin = $companyRow?->gstin ?: null;
        $companyUpiVpa = $companySettings['upi_vpa']
            ?? ($companySettings['invoice_print']['upi_vpa'] ?? null);

        return $this->sendResponse([
            'company_id' => $companyId,
            'company_name' => $companyName,
            'gstin' => $companyGstin,
            'upi_vpa' => $companyUpiVpa,
            'branch_id' => $context->branchId,
            'financial_year_id' => $context->financialYearId,
            'active_warehouse_id' => $warehouseId,
            'default_customer_id' => $defaultCustomerId,
            'default_biller_id' => $billers->first()?->id,
            'pos_setting' => [
                'is_table' => $supportsTables && (bool) ($posSetting->is_table ?? true),
                'cash_register' => (bool) ($posSetting->cash_register ?? true),
                'thermal_invoice_size' => $posSetting->thermal_invoice_size ?? '80mm',
                'payment_options' => $posSetting?->payment_options
                    ? array_values(array_filter(explode(',', (string) $posSetting->payment_options)))
                    : ['Cash', 'UPI', 'Card', 'Credit'],
            ],
            'order_types' => $supportsTables ? ['dine_in', 'takeaway', 'delivery'] : ['takeaway', 'delivery'],
            'payment_methods' => ['Cash', 'UPI', 'Card', 'Credit'],
            'price_tiers' => [
                ['code' => 'Retail MRP', 'multiplier' => 1.0],
                ['code' => 'Wholesale', 'multiplier' => 0.88],
                ['code' => 'Staff Rate', 'multiplier' => 0.60],
                ['code' => 'Online Aggregator', 'multiplier' => 1.15],
            ],
            'shift' => $openRegister ? $this->buildShiftSummary($openRegister, $context) : null,
            'held_orders_count' => $heldCount,
            'warehouses' => $warehouses,
            'billers' => $billers,
            'customers' => $customers,
            'categories' => $categories,
            'products' => $formattedProducts,
            'tables' => $this->loadTablesPayload($context),
        ], 'POS bootstrap fetched successfully');
    }

    /**
     * List POS dining tables along with floor metadata and live held-order occupancy.
     */
    public function tables(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);

        return $this->sendResponse([
            'tables' => $this->loadTablesPayload($context),
        ], 'POS tables fetched successfully');
    }

    /**
     * Return the currently open CashRegister shift (live X-report) for the authenticated user.
     */
    public function currentShift(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $warehouseId = $request->filled('warehouse_id') ? (int) $request->input('warehouse_id') : null;
        $register = $this->findOpenRegister((int) Auth::id(), $context->companyId, $warehouseId);

        return $this->sendResponse([
            'has_open_shift' => $register !== null,
            'shift' => $register ? $this->buildShiftSummary($register, $context) : null,
        ], $register ? 'Open POS shift fetched successfully' : 'No open cash register shift');
    }

    /**
     * Open a new CashRegister shift for the current user and company warehouse.
     */
    public function openShift(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'cash_in_hand' => ['required', 'numeric', 'min:0'],
            'warehouse_id' => ['nullable', 'integer'],
        ]);

        $warehouseId = $validated['warehouse_id'] ?? $this->resolveDefaultWarehouseId($context);
        if (!$warehouseId) {
            return $this->sendError('No active warehouse found for this company branch.', [], 422);
        }

        $warehouse = $this->guard->warehouse($warehouseId, $context, $userId, false);

        $existing = $this->findOpenRegister($userId, $context->companyId, (int) $warehouse->id);
        if ($existing) {
            return $this->sendError('A cash register shift is already open for this warehouse.', [
                'shift' => [$this->buildShiftSummary($existing, $context)],
            ], 422);
        }

        $register = CashRegister::create([
            'cash_in_hand' => round((float) $validated['cash_in_hand'], 2),
            'user_id' => $userId,
            'warehouse_id' => $warehouse->id,
            'status' => true,
        ]);

        return $this->sendResponse(
            $this->buildShiftSummary($register, $context),
            'Cash register shift opened successfully',
            201
        );
    }

    /**
     * Close the open CashRegister shift with counted actual cash and generate the Z-report.
     */
    public function closeShift(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'actual_cash' => ['required', 'numeric', 'min:0'],
            'cash_register_id' => ['nullable', 'integer'],
            'warehouse_id' => ['nullable', 'integer'],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $companyWarehouseIds = Warehouse::query()
            ->where('company_id', $context->companyId)
            ->pluck('id');

        $query = CashRegister::query()
            ->where('user_id', $userId)
            ->where('status', true)
            ->whereIn('warehouse_id', $companyWarehouseIds);

        if (!empty($validated['cash_register_id'])) {
            $query->whereKey((int) $validated['cash_register_id']);
        } elseif (!empty($validated['warehouse_id'])) {
            $query->where('warehouse_id', (int) $validated['warehouse_id']);
        }

        /** @var CashRegister|null $register */
        $register = $query->latest('id')->first();
        if (!$register) {
            return $this->sendError('No open cash register shift found to close.', [], 404);
        }

        $closedSummary = DB::transaction(function () use ($register, $validated, $context) {
            $summary = $this->buildShiftSummary($register, $context);
            $expectedCash = (float) $summary['expected_cash'];
            $actualCash = round((float) $validated['actual_cash'], 2);

            $register->closing_balance = round($expectedCash, 2);
            $register->actual_cash = $actualCash;
            $register->status = false;
            $register->save();

            $fresh = $this->buildShiftSummary($register->fresh(), $context);
            $fresh['variance'] = round($actualCash - $expectedCash, 2);
            $fresh['note'] = $validated['note'] ?? null;

            return $fresh;
        });

        return $this->sendResponse($closedSummary, 'Cash register shift closed successfully');
    }

    /**
     * List POS orders (completed, held drafts, returned) scoped to the active company.
     */
    public function orders(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $perPage = min(max((int) $request->input('per_page', 30), 1), 100);

        $query = Sale::query()
            ->with(['customer:id,name,phone_number', 'warehouse:id,name', 'payments:id,sale_id,paying_method,amount,payment_reference,created_at'])
            ->where('company_id', $companyId)
            ->when($request->filled('branch_id'), fn ($q) => $q->where('branch_id', (int) $request->input('branch_id')))
            ->when($request->filled('sale_status'), fn ($q) => $q->where('sale_status', (int) $request->input('sale_status')))
            ->when($request->filled('cash_register_id'), fn ($q) => $q->where('cash_register_id', (int) $request->input('cash_register_id')))
            ->when($request->filled('q'), function ($q) use ($request) {
                $term = trim((string) $request->input('q'));
                $q->where(function ($sub) use ($term) {
                    $sub->where('reference_no', 'like', "%{$term}%")
                        ->orWhereHas('customer', fn ($cq) => $cq->where('name', 'like', "%{$term}%")->orWhere('phone_number', 'like', "%{$term}%"));
                });
            })
            ->latest('id');

        $paginator = $query->paginate($perPage);
        $saleIds = collect($paginator->items())->pluck('id')->all();
        $returnsBySale = $saleIds !== []
            ? Returns::query()->where('company_id', $companyId)->whereIn('sale_id', $saleIds)->get()->groupBy('sale_id')
            : collect();

        $counts = [
            'completed' => Sale::query()->where('company_id', $companyId)->where('sale_status', 1)->count(),
            'held' => Sale::query()->where('company_id', $companyId)->where('sale_status', 3)->count(),
            'with_returns' => Returns::query()->where('company_id', $companyId)->whereNotNull('sale_id')->distinct('sale_id')->count('sale_id'),
        ];

        $items = collect($paginator->items())
            ->map(fn (Sale $sale) => $this->formatSale($sale, false, $returnsBySale->get($sale->id)))
            ->values();

        return $this->sendResponse([
            'orders' => $items,
            'counts' => $counts,
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ], 'POS orders fetched successfully');
    }

    /**
     * Show a single POS order with full line items, payments, and return history.
     */
    public function showOrder(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $sale = Sale::query()
            ->with(['customer:id,name,phone_number,email', 'warehouse:id,name', 'biller:id,name', 'payments'])
            ->where('company_id', $context->companyId)
            ->find($id);

        if (!$sale) {
            return $this->sendError('POS order not found.', [], 404);
        }

        $returns = Returns::query()->where('company_id', $context->companyId)->where('sale_id', $sale->id)->get();

        return $this->sendResponse($this->formatSale($sale, true, $returns), 'POS order fetched successfully');
    }

    /**
     * Create a finalized POS order OR save/update a held draft (`status = 'held'` / `sale_status = 3`).
     */
    public function storeOrder(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $userId = (int) Auth::id();
        $isHeld = $this->isHeldRequest($request);

        return $this->persistOrder($request, $context, $userId, null, $isHeld);
    }

    /**
     * Resume a held POS draft (`sale_status = 3`) and check it out as a finalized ERP sale.
     */
    public function resumeHeldOrder(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $userId = (int) Auth::id();

        $draft = Sale::query()
            ->where('company_id', $context->companyId)
            ->where('sale_status', 3)
            ->find($id);

        if (!$draft) {
            return $this->sendError('Held POS draft not found.', [], 404);
        }

        if ($draft->posted_at !== null) {
            return $this->sendError('This order has already been posted.', [], 422);
        }

        $keepHeld = $this->isHeldRequest($request);

        return $this->persistOrder($request, $context, $userId, $draft, $keepHeld);
    }

    /**
     * Cancel and remove an unposted held POS draft (`sale_status = 3`), releasing its table.
     */
    public function cancelHeldOrder(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);

        $draft = Sale::query()
            ->where('company_id', $context->companyId)
            ->where('sale_status', 3)
            ->find($id);

        if (!$draft) {
            return $this->sendError('Held POS draft not found.', [], 404);
        }

        if ($draft->posted_at !== null) {
            return $this->sendError('Posted orders cannot be cancelled via draft removal; issue a refund instead.', [], 422);
        }

        DB::transaction(function () use ($draft) {
            Product_Sale::where('sale_id', $draft->id)->delete();
            $draft->forceDelete();
        });

        return $this->sendResponse(['deleted_id' => $id], 'Held POS draft cancelled successfully');
    }

    /**
     * Issue a full or partial POS return/credit note for a posted sale.
     *
     * Records ERP `Returns` (`sale_credit_note`) and `ProductReturn` rows, increments
     * `Product_Sale.return_qty`, optionally receives restockable goods via InventoryMovementService,
     * and posts a balanced credit-note JournalEntry.
     */
    public function refundOrder(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'refund_method' => ['nullable', 'string', 'in:Cash,UPI,Card,Credit Card,Bank,Credit'],
            'restock' => ['nullable', 'boolean'],
            'reason' => ['nullable', 'string', 'max:500'],
            'cash_register_id' => ['nullable', 'integer'],
            'items' => ['nullable', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.qty' => ['required_with:items', 'numeric', 'gt:0'],
        ]);

        $sale = Sale::query()
            ->where('company_id', $context->companyId)
            ->where('sale_status', 1)
            ->find($id);

        if (!$sale) {
            return $this->sendError('Completed POS order not found.', [], 404);
        }

        $saleLines = Product_Sale::query()->where('sale_id', $sale->id)->get();
        if ($saleLines->isEmpty()) {
            return $this->sendError('Order has no line items eligible for return.', [], 422);
        }

        $refundMethod = $validated['refund_method'] ?? 'Cash';
        $restock = (bool) ($validated['restock'] ?? true);
        $reason = trim((string) ($validated['reason'] ?? 'POS customer return'));

        $returnedByLine = ProductReturn::query()
            ->whereIn('source_line_id', $saleLines->pluck('id'))
            ->selectRaw('source_line_id, SUM(qty) as returned_qty')
            ->groupBy('source_line_id')
            ->pluck('returned_qty', 'source_line_id');

        $requestedItems = $validated['items'] ?? $saleLines->map(function (Product_Sale $line) use ($returnedByLine) {
            $already = max((float) ($line->return_qty ?? 0), (float) ($returnedByLine->get($line->id) ?? 0));
            $remaining = max(0.0, (float) $line->qty - $already);

            return ['product_id' => (int) $line->product_id, 'qty' => $remaining];
        })->filter(fn ($row) => $row['qty'] > 0.0001)->values()->all();

        if ($requestedItems === []) {
            return $this->sendError('All items on this order have already been returned.', [], 422);
        }

        $cashRegisterId = $this->resolveCashRegisterId($request, $userId, $context, (int) $sale->warehouse_id);

        try {
            $result = DB::transaction(function () use ($context, $userId, $sale, $saleLines, $returnedByLine, $requestedItems, $refundMethod, $restock, $reason, $cashRegisterId) {
                $context = $this->guard->context($context, $userId);
                $businessDate = $this->guard->begin($context, now()->toDateString());

                $linesByProduct = $saleLines->keyBy('product_id');
                $resolvedReturns = [];
                $totalQty = 0.0;
                $totalDiscount = 0.0;
                $totalTax = 0.0;
                $totalPrice = 0.0;

                foreach ($requestedItems as $reqLine) {
                    $productId = (int) $reqLine['product_id'];
                    $returnQty = round((float) $reqLine['qty'], 4);
                    /** @var Product_Sale|null $origLine */
                    $origLine = $linesByProduct->get($productId);

                    if (!$origLine) {
                        throw ValidationException::withMessages([
                            'items' => ["Product #{$productId} is not part of order {$sale->reference_no}."],
                        ]);
                    }

                    $alreadyReturned = max(
                        (float) ($origLine->return_qty ?? 0),
                        (float) ($returnedByLine->get($origLine->id) ?? 0)
                    );
                    $returnable = round((float) $origLine->qty - $alreadyReturned, 4);
                    if ($returnQty > $returnable + 0.0001) {
                        throw ValidationException::withMessages([
                            'items' => ["Cannot return {$returnQty} of product #{$productId}; only {$returnable} remaining."],
                        ]);
                    }

                    $ratio = (float) $origLine->qty > 0 ? ($returnQty / (float) $origLine->qty) : 0.0;
                    $lineTax = round((float) $origLine->tax * $ratio, 2);
                    $lineDiscount = round((float) $origLine->discount * $ratio, 2);
                    $lineTotal = round((float) $origLine->total * $ratio, 2);

                    $totalQty += $returnQty;
                    $totalDiscount += $lineDiscount;
                    $totalTax += $lineTax;
                    $totalPrice += $lineTotal;

                    $resolvedReturns[] = [
                        'orig' => $origLine,
                        'qty' => $returnQty,
                        'discount' => $lineDiscount,
                        'tax' => $lineTax,
                        'total' => $lineTotal,
                    ];
                }

                $netSubtotal = round(max(0.0, $totalPrice - $totalTax), 2);
                $grandTotal = round($totalPrice, 2);
                $creditAccount = $this->resolvePaymentAccountForMethod($refundMethod, $context, $userId);
                $reservation = $this->numbers->reserve('sale_credit_note', $context, $businessDate, $userId);

                $returnDoc = new Returns([
                    'reference_no' => $reservation->formatted_number,
                    'user_id' => $userId,
                    'sale_id' => $sale->id,
                    'cash_register_id' => $cashRegisterId,
                    'customer_id' => $sale->customer_id,
                    'warehouse_id' => $sale->warehouse_id,
                    'biller_id' => $sale->biller_id,
                    'account_id' => $creditAccount?->id ?? Account::where('company_id', $context->companyId)->value('id') ?? 1,
                    'currency_id' => $sale->currency_id ?? 1,
                    'exchange_rate' => $sale->exchange_rate ?? 1,
                    'item' => count($resolvedReturns),
                    'total_qty' => round($totalQty, 2),
                    'total_discount' => round($totalDiscount, 2),
                    'total_tax' => round($totalTax, 2),
                    'total_price' => round($netSubtotal, 2),
                    'order_tax_rate' => 0,
                    'order_tax' => 0,
                    'grand_total' => $grandTotal,
                    'return_note' => $reason,
                    'staff_note' => 'Refund via '.$refundMethod,
                ]);
                $returnDoc->company_id = $context->companyId;
                $returnDoc->branch_id = $context->branchId;
                $returnDoc->financial_year_id = $context->financialYearId;
                $returnDoc->note_type = 'credit_note';
                $returnDoc->adjustment_type = 'return';
                $returnDoc->status = 'draft';
                $returnDoc->posted_at = null;
                $returnDoc->save();
                $this->numbers->assign($reservation, $returnDoc);

                $stockLines = [];
                $productsById = Product::whereIn('id', array_map(fn ($r) => $r['orig']->product_id, $resolvedReturns))
                    ->get()
                    ->keyBy('id');

                foreach ($resolvedReturns as $row) {
                    /** @var Product_Sale $orig */
                    $orig = $row['orig'];
                    $pr = new ProductReturn([
                        'return_id' => $returnDoc->id,
                        'product_id' => $orig->product_id,
                        'product_batch_id' => $orig->product_batch_id,
                        'variant_id' => $orig->variant_id,
                        'imei_number' => $orig->imei_number,
                        'qty' => $row['qty'],
                        'sale_unit_id' => $orig->sale_unit_id,
                        'net_unit_price' => $orig->net_unit_price,
                        'discount' => $row['discount'],
                        'tax_rate' => $orig->tax_rate,
                        'tax' => $row['tax'],
                        'total' => $row['total'],
                    ]);
                    $pr->company_id = $context->companyId;
                    $pr->source_line_id = $orig->id;
                    $pr->disposition = $restock ? 'restock' : 'writeoff';
                    $pr->save();

                    $prod = $productsById->get($orig->product_id);
                    if ($restock && $prod && ($prod->type ?? 'standard') === 'standard') {
                        $unitCost = max(0.0, (float) ($prod->cost ?? 0));
                        $stockLines[] = new StockLine(
                            productId: (int) $orig->product_id,
                            qty: (float) $row['qty'],
                            variantId: $orig->variant_id ? (int) $orig->variant_id : null,
                            batchId: $orig->product_batch_id ? (int) $orig->product_batch_id : null,
                            unitCost: $unitCost,
                            uomId: $orig->sale_unit_id ? (int) $orig->sale_unit_id : null,
                        );
                    }
                }

                $returnDoc->status = 'posted';
                $returnDoc->posted_at = now();
                $returnDoc->save();

                if ($restock && $stockLines !== []) {
                    $this->inventory->receive(new StockMovementCommand(
                        date: $businessDate,
                        lines: $stockLines,
                        warehouseId: (int) $sale->warehouse_id,
                        sourceType: 'sale_credit_note',
                        sourceId: (int) $returnDoc->id,
                        sourceNo: $returnDoc->reference_no,
                        idempotencyKey: 'pos_return:'.$returnDoc->id,
                        reason: $reason,
                        userId: $userId,
                        context: $context,
                    ));
                }

                $journalEntry = $this->postReturnJournal($returnDoc, $netSubtotal, $totalTax, $grandTotal, $refundMethod, $context, $userId);

                return [
                    'return' => $returnDoc,
                    'journal_entry_id' => $journalEntry?->id,
                    'restocked' => $restock && $stockLines !== [],
                    'refund_method' => $refundMethod,
                ];
            });
        } catch (ValidationException $e) {
            return $this->sendError($e->getMessage(), $e->errors(), 422);
        }

        return $this->sendResponse([
            'return_id' => (int) $result['return']->id,
            'reference_no' => $result['return']->reference_no,
            'sale_id' => (int) $sale->id,
            'sale_reference_no' => $sale->reference_no,
            'grand_total' => round((float) $result['return']->grand_total, 2),
            'refund_method' => $result['refund_method'],
            'restocked' => $result['restocked'],
            'journal_entry_id' => $result['journal_entry_id'],
        ], 'POS return processed successfully', 201);
    }

    /**
     * C-08: Kitchen Display System (KDS) active ticket feed.
     */
    public function kds(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $includeServed = $request->boolean('include_served', false);

        $sales = Sale::query()
            ->with(['customer:id,name,phone_number'])
            ->where('company_id', $companyId)
            ->whereIn('sale_status', [1, 3])
            ->latest('id')
            ->take(50)
            ->get();

        $saleIds = $sales->pluck('id')->all();
        $linesBySale = $saleIds !== []
            ? Product_Sale::query()
                ->join('products', 'products.id', '=', 'product_sales.product_id')
                ->whereIn('product_sales.sale_id', $saleIds)
                ->select('product_sales.*', 'products.name as product_name', 'products.code as product_code')
                ->get()
                ->groupBy('sale_id')
            : collect();

        $tableNames = Table::query()->pluck('name', 'id');

        $tickets = $sales->map(function (Sale $sale) use ($linesBySale, $tableNames) {
            $attrs = is_array($sale->attributes_json) ? $sale->attributes_json : [];
            $kdsStatus = (string) ($attrs['kds_status'] ?? ((int) $sale->sale_status === 3 ? 'new' : 'preparing'));
            $lines = $linesBySale->get($sale->id, collect());
            $tableId = $sale->table_id ?? ($attrs['table_id'] ?? null);

            return [
                'id' => (int) $sale->id,
                'reference_no' => (string) $sale->reference_no,
                'sale_status' => (int) $sale->sale_status,
                'kds_status' => $kdsStatus,
                'order_type' => (string) ($attrs['order_type'] ?? ($tableId ? 'dine_in' : 'takeaway')),
                'table_id' => $tableId ? (int) $tableId : null,
                'table_name' => $tableId ? ($tableNames->get((int) $tableId) ?? "Table #{$tableId}") : null,
                'customer_name' => $sale->customer?->name ?? 'Walk-in Customer',
                'item_count' => (int) $sale->item,
                'total_qty' => round((float) $sale->total_qty, 2),
                'grand_total' => round((float) $sale->grand_total, 2),
                'sale_note' => $sale->sale_note,
                'elapsed_minutes' => $sale->created_at ? (int) $sale->created_at->diffInMinutes(now()) : 0,
                'created_at' => $sale->created_at?->toIso8601String(),
                'items' => $lines->map(fn ($l) => [
                    'product_id' => (int) $l->product_id,
                    'product_name' => (string) $l->product_name,
                    'product_code' => (string) $l->product_code,
                    'qty' => round((float) $l->qty, 2),
                ])->values()->all(),
            ];
        })->filter(fn (array $ticket) => $includeServed || $ticket['kds_status'] !== 'served')
          ->values();

        $counts = [
            'new' => $tickets->where('kds_status', 'new')->count(),
            'preparing' => $tickets->where('kds_status', 'preparing')->count(),
            'ready' => $tickets->where('kds_status', 'ready')->count(),
            'served' => $tickets->where('kds_status', 'served')->count(),
        ];

        return $this->sendResponse([
            'tickets' => $tickets,
            'counts' => $counts,
        ], 'KDS kitchen tickets fetched successfully');
    }

    /**
     * C-08: Advance or update a Kitchen Display System (KDS) ticket status.
     */
    public function updateKdsStatus(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $validated = $request->validate([
            'status' => ['required', 'string', 'in:new,preparing,ready,served'],
            'note' => ['nullable', 'string', 'max:255'],
        ]);

        $sale = Sale::query()
            ->where('company_id', $context->companyId)
            ->find($id);

        if (!$sale) {
            return $this->sendError('Kitchen ticket not found for active company.', [], 404);
        }

        $attrs = is_array($sale->attributes_json) ? $sale->attributes_json : [];
        $attrs['kds_status'] = $validated['status'];
        $attrs['kds_updated_at'] = now()->toIso8601String();
        $attrs['kds_updated_by'] = (int) Auth::id();
        if (!empty($validated['note'])) {
            $attrs['kds_note'] = $validated['note'];
        }
        $sale->attributes_json = $attrs;
        $sale->save();

        return $this->sendResponse([
            'id' => (int) $sale->id,
            'reference_no' => $sale->reference_no,
            'kds_status' => $validated['status'],
            'updated_at' => $attrs['kds_updated_at'],
        ], 'Kitchen ticket status updated to '.$validated['status']);
    }

    /**
     * C-34: Toggle menu item availability (86 Item) for the active company.
     */
    public function toggleProductAvailability(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $product = Product::query()
            ->where('company_id', $context->companyId)
            ->find($id);

        if (!$product) {
            return $this->sendError('Product not found in active company.', [], 404);
        }

        $validated = $request->validate([
            'is_available' => ['nullable', 'boolean'],
            'in_stock' => ['nullable', 'boolean'],
            'reason' => ['nullable', 'string', 'max:255'],
        ]);

        $newAvailability = array_key_exists('is_available', $validated) && $validated['is_available'] !== null
            ? (bool) $validated['is_available']
            : (array_key_exists('in_stock', $validated) && $validated['in_stock'] !== null
                ? (bool) $validated['in_stock']
                : !((bool) ($product->is_active ?? true)));

        $product->is_active = $newAvailability;
        $product->save();

        return $this->sendResponse([
            'id' => (int) $product->id,
            'name' => $product->name,
            'code' => $product->code,
            'is_available' => (bool) $product->is_active,
            'reason' => $validated['reason'] ?? null,
        ], $newAvailability ? "{$product->name} restored to POS menu" : "{$product->name} marked 86 (Unavailable)");
    }

    /**
     * C-32: Log a kitchen/bakery production batch and increment finished SKU stock.
     */
    public function storeProductionBatch(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'warehouse_id' => ['nullable', 'integer'],
            'product_id' => ['required_without:items', 'nullable', 'integer'],
            'qty' => ['required_without:items', 'nullable', 'numeric', 'gt:0'],
            'unit_cost' => ['nullable', 'numeric', 'min:0'],
            'note' => ['nullable', 'string', 'max:500'],
            'items' => ['required_without:product_id', 'nullable', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.qty' => ['required_with:items', 'numeric', 'gt:0'],
            'items.*.unit_cost' => ['nullable', 'numeric', 'min:0'],
        ]);

        $warehouseId = $validated['warehouse_id'] ?? $this->resolveDefaultWarehouseId($context);
        if (!$warehouseId) {
            return $this->sendError('No active warehouse found for this company.', [], 422);
        }
        $warehouse = $this->guard->warehouse((int) $warehouseId, $context, $userId, false);

        $rawItems = $validated['items'] ?? [[
            'product_id' => (int) $validated['product_id'],
            'qty' => (float) $validated['qty'],
            'unit_cost' => isset($validated['unit_cost']) ? (float) $validated['unit_cost'] : null,
        ]];

        $productIds = array_values(array_unique(array_map(fn ($r) => (int) $r['product_id'], $rawItems)));
        $products = Product::query()
            ->where('company_id', $companyId)
            ->whereIn('id', $productIds)
            ->get()
            ->keyBy('id');

        if ($products->count() !== count($productIds)) {
            return $this->sendError('One or more products do not belong to the active company.', [], 422);
        }

        $refNo = 'PROD-'.now()->format('YmdHis').'-'.strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));
        $note = trim((string) ($validated['note'] ?? 'Kitchen Production Batch'));

        $batch = DB::transaction(function () use ($companyId, $context, $warehouse, $rawItems, $products, $refNo, $note) {
            $totalQty = array_sum(array_map(fn ($r) => (float) $r['qty'], $rawItems));

            $adjustmentId = DB::table('adjustments')->insertGetId([
                'reference_no' => $refNo,
                'warehouse_id' => $warehouse->id,
                'total_qty' => round($totalQty, 2),
                'item' => count($rawItems),
                'note' => '[PRODUCTION BATCH] '.$note,
                'company_id' => $companyId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $linesSummary = [];
            foreach ($rawItems as $row) {
                /** @var Product $product */
                $product = $products->get((int) $row['product_id']);
                $qty = round((float) $row['qty'], 2);
                $unitCost = round((float) ($row['unit_cost'] ?? $product->cost ?? 0), 2);

                DB::table('product_adjustments')->insert([
                    'adjustment_id' => $adjustmentId,
                    'product_id' => $product->id,
                    'unit_cost' => $unitCost,
                    'qty' => $qty,
                    'action' => '+',
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $product->qty = round((float) ($product->qty ?? 0) + $qty, 2);
                $product->is_active = true;
                $product->save();

                $existingWh = DB::table('product_warehouse')
                    ->where('product_id', $product->id)
                    ->where('warehouse_id', $warehouse->id)
                    ->first();

                if ($existingWh) {
                    DB::table('product_warehouse')
                        ->where('id', $existingWh->id)
                        ->update([
                            'qty' => round((float) $existingWh->qty + $qty, 2),
                            'updated_at' => now(),
                        ]);
                } else {
                    DB::table('product_warehouse')->insert([
                        'product_id' => $product->id,
                        'warehouse_id' => $warehouse->id,
                        'qty' => $qty,
                        'price' => $product->price,
                        'company_id' => $companyId,
                        'branch_id' => $context->branchId,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                $linesSummary[] = [
                    'product_id' => (int) $product->id,
                    'product_name' => $product->name,
                    'qty_added' => $qty,
                    'new_stock_qty' => round((float) $product->qty, 2),
                ];
            }

            return [
                'id' => (int) $adjustmentId,
                'reference_no' => $refNo,
                'warehouse_id' => (int) $warehouse->id,
                'total_qty' => round($totalQty, 2),
                'note' => $note,
                'items' => $linesSummary,
            ];
        });

        return $this->sendResponse($batch, 'Production batch recorded and stock updated', 201);
    }

    /**
     * C-33: Log kitchen spoilage/wastage, deduct stock, and record wastage adjustment.
     */
    public function storeWastage(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'warehouse_id' => ['nullable', 'integer'],
            'product_id' => ['required_without:items', 'nullable', 'integer'],
            'qty' => ['required_without:items', 'nullable', 'numeric', 'gt:0'],
            'reason' => ['nullable', 'string', 'max:500'],
            'items' => ['required_without:product_id', 'nullable', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.qty' => ['required_with:items', 'numeric', 'gt:0'],
        ]);

        $warehouseId = $validated['warehouse_id'] ?? $this->resolveDefaultWarehouseId($context);
        if (!$warehouseId) {
            return $this->sendError('No active warehouse found for this company.', [], 422);
        }
        $warehouse = $this->guard->warehouse((int) $warehouseId, $context, $userId, false);

        $rawItems = $validated['items'] ?? [[
            'product_id' => (int) $validated['product_id'],
            'qty' => (float) $validated['qty'],
        ]];

        $productIds = array_values(array_unique(array_map(fn ($r) => (int) $r['product_id'], $rawItems)));
        $products = Product::query()
            ->where('company_id', $companyId)
            ->whereIn('id', $productIds)
            ->get()
            ->keyBy('id');

        if ($products->count() !== count($productIds)) {
            return $this->sendError('One or more products do not belong to the active company.', [], 422);
        }

        $refNo = 'WST-'.now()->format('YmdHis').'-'.strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));
        $reason = trim((string) ($validated['reason'] ?? 'Kitchen Spoilage & Wastage'));

        $wastage = DB::transaction(function () use ($companyId, $warehouse, $rawItems, $products, $refNo, $reason) {
            $totalQty = array_sum(array_map(fn ($r) => (float) $r['qty'], $rawItems));
            $totalCost = 0.0;

            $adjustmentId = DB::table('adjustments')->insertGetId([
                'reference_no' => $refNo,
                'warehouse_id' => $warehouse->id,
                'total_qty' => round($totalQty, 2),
                'item' => count($rawItems),
                'note' => '[WASTAGE] '.$reason,
                'company_id' => $companyId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $linesSummary = [];
            foreach ($rawItems as $row) {
                /** @var Product $product */
                $product = $products->get((int) $row['product_id']);
                $qty = round((float) $row['qty'], 2);
                $unitCost = round((float) ($product->cost ?: ($product->price * 0.5)), 2);
                $totalCost += round($qty * $unitCost, 2);

                DB::table('product_adjustments')->insert([
                    'adjustment_id' => $adjustmentId,
                    'product_id' => $product->id,
                    'unit_cost' => $unitCost,
                    'qty' => $qty,
                    'action' => '-',
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $product->qty = round(max(0.0, (float) ($product->qty ?? 0) - $qty), 2);
                $product->save();

                $existingWh = DB::table('product_warehouse')
                    ->where('product_id', $product->id)
                    ->where('warehouse_id', $warehouse->id)
                    ->first();

                if ($existingWh) {
                    DB::table('product_warehouse')
                        ->where('id', $existingWh->id)
                        ->update([
                            'qty' => round(max(0.0, (float) $existingWh->qty - $qty), 2),
                            'updated_at' => now(),
                        ]);
                }

                $linesSummary[] = [
                    'product_id' => (int) $product->id,
                    'product_name' => $product->name,
                    'qty_wasted' => $qty,
                    'wastage_cost' => round($qty * $unitCost, 2),
                    'remaining_stock_qty' => round((float) $product->qty, 2),
                ];
            }

            return [
                'id' => (int) $adjustmentId,
                'reference_no' => $refNo,
                'warehouse_id' => (int) $warehouse->id,
                'total_qty' => round($totalQty, 2),
                'total_wastage_cost' => round($totalCost, 2),
                'reason' => $reason,
                'items' => $linesSummary,
            ];
        });

        return $this->sendResponse($wastage, 'Wastage logged and inventory adjusted', 201);
    }

    /**
     * C-36: List low-stock SKUs and internal kitchen reorder requests.
     */
    public function reorderRequests(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;

        $requests = DB::table('purchases')
            ->leftJoin('suppliers', 'purchases.supplier_id', '=', 'suppliers.id')
            ->leftJoin('warehouses', 'purchases.warehouse_id', '=', 'warehouses.id')
            ->where('purchases.company_id', $companyId)
            ->whereNull('purchases.deleted_at')
            ->where(function ($q) {
                $q->where('purchases.status', 3)
                  ->orWhere('purchases.reference_no', 'like', 'REQ-%');
            })
            ->orderByDesc('purchases.id')
            ->limit(30)
            ->get([
                'purchases.id',
                'purchases.reference_no',
                'purchases.supplier_id',
                'suppliers.name as supplier_name',
                'purchases.warehouse_id',
                'warehouses.name as warehouse_name',
                'purchases.item as item_count',
                'purchases.total_qty',
                'purchases.grand_total',
                'purchases.status',
                'purchases.note',
                'purchases.created_at',
            ]);

        $lowStockItems = Product::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->whereRaw('COALESCE(qty, 0) <= COALESCE(alert_quantity, 10)')
            ->orderBy('qty')
            ->limit(30)
            ->get(['id', 'name', 'code', 'qty', 'alert_quantity', 'cost', 'price']);

        return $this->sendResponse([
            'reorder_requests' => $requests,
            'low_stock_items' => $lowStockItems,
        ], 'Kitchen reorder requests fetched successfully');
    }

    /**
     * C-36: Create an internal kitchen reorder request / purchase requisition.
     */
    public function storeReorderRequest(Request $request): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $userId = (int) Auth::id();

        $validated = $request->validate([
            'warehouse_id' => ['nullable', 'integer'],
            'supplier_id' => ['nullable', 'integer'],
            'product_id' => ['required_without:items', 'nullable', 'integer'],
            'qty' => ['required_without:items', 'nullable', 'numeric', 'gt:0'],
            'note' => ['nullable', 'string', 'max:500'],
            'items' => ['required_without:product_id', 'nullable', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.qty' => ['required_with:items', 'numeric', 'gt:0'],
            'items.*.unit_cost' => ['nullable', 'numeric', 'min:0'],
        ]);

        $warehouseId = $validated['warehouse_id'] ?? $this->resolveDefaultWarehouseId($context);
        if (!$warehouseId) {
            return $this->sendError('No active warehouse found for this company.', [], 422);
        }
        $warehouse = $this->guard->warehouse((int) $warehouseId, $context, $userId, false);

        $supplierId = $validated['supplier_id'] ?? DB::table('suppliers')
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->orderBy('id')
            ->value('id');

        $rawItems = $validated['items'] ?? [[
            'product_id' => (int) $validated['product_id'],
            'qty' => (float) $validated['qty'],
        ]];

        $productIds = array_values(array_unique(array_map(fn ($r) => (int) $r['product_id'], $rawItems)));
        $products = Product::query()
            ->where('company_id', $companyId)
            ->whereIn('id', $productIds)
            ->get()
            ->keyBy('id');

        if ($products->count() !== count($productIds)) {
            return $this->sendError('One or more products do not belong to the active company.', [], 422);
        }

        $refNo = 'REQ-'.now()->format('YmdHis').'-'.strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));
        $defaultUnitId = (int) (Unit::orderBy('id')->value('id') ?: 1);

        $reorder = DB::transaction(function () use ($companyId, $context, $userId, $warehouse, $supplierId, $rawItems, $products, $refNo, $defaultUnitId, $validated) {
            $totalQty = 0.0;
            $totalCost = 0.0;
            $prepared = [];

            foreach ($rawItems as $row) {
                /** @var Product $product */
                $product = $products->get((int) $row['product_id']);
                $qty = round((float) $row['qty'], 2);
                $unitCost = round((float) ($row['unit_cost'] ?? $product->cost ?: ($product->price * 0.6)), 2);
                $lineTotal = round($qty * $unitCost, 2);

                $totalQty += $qty;
                $totalCost += $lineTotal;
                $prepared[] = [
                    'product' => $product,
                    'qty' => $qty,
                    'unit_cost' => $unitCost,
                    'total' => $lineTotal,
                ];
            }

            $purchaseId = DB::table('purchases')->insertGetId([
                'reference_no' => $refNo,
                'user_id' => $userId,
                'warehouse_id' => $warehouse->id,
                'supplier_id' => $supplierId,
                'item' => count($prepared),
                'total_qty' => round($totalQty, 2),
                'total_discount' => 0,
                'total_tax' => 0,
                'total_cost' => round($totalCost, 2),
                'order_tax_rate' => 0,
                'order_tax' => 0,
                'order_discount' => 0,
                'shipping_cost' => 0,
                'grand_total' => round($totalCost, 2),
                'paid_amount' => 0,
                'status' => 3, // Pending / Ordered Requisition
                'payment_status' => 1,
                'note' => trim((string) ($validated['note'] ?? 'Kitchen Stock Reorder Requisition')),
                'company_id' => $companyId,
                'branch_id' => $context->branchId,
                'financial_year_id' => $context->financialYearId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            if (Schema::hasTable('product_purchases')) {
                foreach ($prepared as $line) {
                    DB::table('product_purchases')->insert([
                        'purchase_id' => $purchaseId,
                        'product_id' => $line['product']->id,
                        'qty' => $line['qty'],
                        'recieved' => 0,
                        'purchase_unit_id' => $line['product']->purchase_unit_id ?: $line['product']->unit_id ?: $defaultUnitId,
                        'net_unit_cost' => $line['unit_cost'],
                        'discount' => 0,
                        'tax_rate' => 0,
                        'tax' => 0,
                        'total' => $line['total'],
                        'company_id' => $companyId,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            return [
                'id' => (int) $purchaseId,
                'reference_no' => $refNo,
                'warehouse_id' => (int) $warehouse->id,
                'supplier_id' => $supplierId ? (int) $supplierId : null,
                'item_count' => count($prepared),
                'total_qty' => round($totalQty, 2),
                'estimated_cost' => round($totalCost, 2),
                'status' => 'pending_po',
            ];
        });

        return $this->sendResponse($reorder, 'Kitchen reorder request submitted', 201);
    }

    /**
     * D-04 & C-06: Generate structured ESC/POS thermal receipt, KOT, and TSPL barcode/neck-tag label payload.
     */
    public function printOrderJob(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $sale = Sale::query()
            ->with(['customer:id,name,phone_number', 'warehouse:id,name,phone,address', 'payments'])
            ->where('company_id', $context->companyId)
            ->find($id);

        if (!$sale) {
            return $this->sendError('POS order not found in active company.', [], 404);
        }

        $company = DB::table('companies')->where('id', $context->companyId)->first();
        $returns = Returns::query()->where('company_id', $context->companyId)->where('sale_id', $sale->id)->get();
        $formatted = $this->formatSale($sale, true, $returns);

        $attrs = is_array($sale->attributes_json) ? $sale->attributes_json : [];
        $printCount = ((int) ($attrs['print_count'] ?? 0)) + 1;
        $tokenNumber = (string) ($attrs['token_number'] ?? str_pad((string) (($sale->id % 999) + 1), 4, '0', STR_PAD_LEFT));
        $attrs['print_count'] = $printCount;
        $attrs['token_number'] = $tokenNumber;
        $attrs['last_printed_at'] = now()->toIso8601String();
        DB::table('sales')
            ->where('id', $sale->id)
            ->update([
                'attributes_json' => json_encode($attrs, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ]);

        $format = (string) $request->input('format', $request->input('paper_width', '80mm'));
        $paperWidth = str_contains($format, '58') ? '58mm' : '80mm';
        $companyTitle = (string) ($company->trade_name ?? $company->legal_name ?? 'DK Enterprises');
        $branchInfo = (string) ($sale->warehouse?->name ?? 'Main Branch');
        $priceTier = (string) ($attrs['price_tier'] ?? 'Retail MRP');
        $lineNotes = is_array($attrs['line_notes'] ?? null) ? $attrs['line_notes'] : [];
        $dateStr = Carbon::parse($sale->created_at ?? now())->format('d M Y H:i');
        $pkdStr = Carbon::parse($sale->created_at ?? now())->format('d/m/y H:i');
        $expStr = Carbon::parse($sale->created_at ?? now())->addDays(1)->format('d/m/y');
        $batchCode = 'B'.Carbon::parse($sale->created_at ?? now())->format('ymd').'-'.str_pad((string) ($sale->id % 100), 2, '0', STR_PAD_LEFT);

        $widthCols = $paperWidth === '58mm' ? 32 : 48;
        $sepDouble = str_repeat('=', $widthCols);
        $sepSingle = str_repeat('-', $widthCols);

        $receiptLines = [
            $sepDouble,
            str_pad(strtoupper($companyTitle), $widthCols, ' ', STR_PAD_BOTH),
            str_pad($branchInfo, $widthCols, ' ', STR_PAD_BOTH),
            str_pad('GSTIN: 33AABCA1234F1Z5 · FSSAI: 12426001', $widthCols, ' ', STR_PAD_BOTH),
            $sepDouble,
            str_pad("[ COUNTER TOKEN : #{$tokenNumber} ]", $widthCols, ' ', STR_PAD_BOTH),
            $sepSingle,
            'Receipt : '.$formatted['reference_no'],
            'Date    : '.$dateStr,
            'Type    : '.strtoupper((string) $formatted['order_type']).' · Tier: '.$priceTier,
            'Customer: '.$formatted['customer_name'],
            $sepSingle,
        ];

        $kotLines = [
            str_repeat('=', 32),
            str_pad("KITCHEN ORDER TICKET #{$tokenNumber}", 32, ' ', STR_PAD_BOTH),
            str_pad(strtoupper((string) $formatted['order_type']), 32, ' ', STR_PAD_BOTH),
            str_repeat('-', 32),
            'Ref : '.$formatted['reference_no'],
            'Time: '.Carbon::parse($sale->created_at ?? now())->format('H:i:s'),
            str_repeat('-', 32),
        ];

        $labels = [];
        $tsplBlocks = [];

        foreach ($formatted['items'] ?? [] as $item) {
            $pName = (string) $item['product_name'];
            $pCode = (string) ($item['product_code'] ?: ('SKU-'.$item['product_id']));
            $itemNote = (string) ($lineNotes[(string) $item['product_id']] ?? '');

            $receiptLines[] = sprintf(
                '%-18s %4s x %6.2f = %7.2f',
                mb_substr($pName, 0, 18),
                $item['qty'],
                $item['net_unit_price'],
                $item['total']
            );
            if ($itemNote !== '') {
                $receiptLines[] = '  * Note: '.$itemNote;
            }

            $kotLines[] = sprintf('[ %s x ]  %s', $item['qty'], $pName);
            if ($itemNote !== '') {
                $kotLines[] = '   >> PREP: '.strtoupper($itemNote);
            }

            $cleanTitle = addslashes(mb_substr(strtoupper($companyTitle), 0, 22));
            $cleanItem = addslashes(mb_substr(strtoupper($pName), 0, 24));
            $mrpStr = number_format((float) $item['net_unit_price'], 2);

            $tspl = implode("\n", [
                'SIZE 50 mm, 25 mm',
                'GAP 2 mm, 0 mm',
                'DIRECTION 1',
                'CLS',
                "TEXT 16,12,\"2\",0,1,1,\"{$cleanTitle}\"",
                "TEXT 210,12,\"1\",0,1,1,\"BATCH: {$batchCode}\"",
                'BAR 16,32,368,2',
                "TEXT 16,42,\"3\",0,1,1,\"{$cleanItem}\"",
                "TEXT 16,70,\"2\",0,1,1,\"MRP: Rs.{$mrpStr}\"",
                "TEXT 195,70,\"1\",0,1,1,\"PKD: {$pkdStr}\"",
                "TEXT 195,88,\"1\",0,1,1,\"USE: {$expStr}\"",
                "BARCODE 32,112,\"128\",52,1,0,2,2,\"{$pCode}\"",
                'PRINT 1,'.max(1, (int) ceil((float) $item['qty'])),
            ]);

            $tsplBlocks[] = $tspl;
            $labels[] = [
                'product_id' => (int) $item['product_id'],
                'product_name' => $pName,
                'barcode' => $pCode,
                'batch_code' => $batchCode,
                'mrp' => round((float) $item['net_unit_price'], 2),
                'qty' => (float) $item['qty'],
                'packed_at' => $pkdStr,
                'expiry_at' => $expStr,
                'label_size' => '50x25mm',
                'tspl' => $tspl,
            ];
        }

        $kotLines[] = str_repeat('=', 32);

        $receiptLines[] = $sepSingle;
        if (($formatted['order_discount'] ?? 0) > 0) {
            $receiptLines[] = sprintf('DISCOUNT   : -INR %0.2f', $formatted['order_discount']);
        }
        if (($formatted['shipping_cost'] ?? 0) > 0) {
            $receiptLines[] = sprintf('PARCEL/PACK: +INR %0.2f', $formatted['shipping_cost']);
        }
        if (($formatted['total_tax'] ?? 0) + ($formatted['order_tax'] ?? 0) > 0) {
            $taxHalf = round(((float) $formatted['total_tax'] + (float) $formatted['order_tax']) / 2.0, 2);
            $receiptLines[] = sprintf('CGST       :  INR %0.2f', $taxHalf);
            $receiptLines[] = sprintf('SGST       :  INR %0.2f', $taxHalf);
        }
        $receiptLines[] = $sepDouble;
        $receiptLines[] = sprintf('GRAND TOTAL: INR %0.2f', $formatted['grand_total']);
        $receiptLines[] = sprintf('PAID       : INR %0.2f', $formatted['paid_amount']);
        if ($formatted['due_amount'] > 0) {
            $receiptLines[] = sprintf('BALANCE DUE: INR %0.2f', $formatted['due_amount']);
        }
        $receiptLines[] = $sepSingle;
        $receiptLines[] = 'Thank you for your business!';
        $receiptLines[] = '- - - - - TEAR TOKEN STUB - - - - -';
        $receiptLines[] = "TOKEN #{$tokenNumber} | {$formatted['reference_no']} | INR ".number_format((float) $formatted['grand_total'], 2);
        $receiptLines[] = $sepDouble;

        $upiQrString = sprintf(
            'upi://pay?pa=dkenterprises@upi&pn=%s&am=%0.2f&tr=%s&cu=INR',
            rawurlencode($companyTitle),
            (float) $formatted['grand_total'],
            rawurlencode((string) $formatted['reference_no'])
        );

        return $this->sendResponse([
            'job_id' => 'PRN-'.$sale->id.'-'.$printCount,
            'sale_id' => (int) $sale->id,
            'reference_no' => $formatted['reference_no'],
            'token_number' => $tokenNumber,
            'format' => $format,
            'paper_width' => $paperWidth,
            'price_tier' => $priceTier,
            'print_count' => $printCount,
            'printed_at' => $attrs['last_printed_at'],
            'company_name' => $companyTitle,
            'branch_name' => $branchInfo,
            'upi_qr_string' => $upiQrString,
            'order' => $formatted,
            'receipt_lines' => $receiptLines,
            'kot_lines' => $kotLines,
            'kot_text' => implode("\n", $kotLines),
            'labels' => $labels,
            'tspl_commands' => implode("\n\n", $tsplBlocks),
            'raw_text' => implode("\n", $receiptLines),
        ], 'Thermal receipt & label print job generated');
    }

    /**
     * Persist either a new POS order/draft or update+finalize an existing held draft.
     */
    private function persistOrder(
        Request $request,
        CompanyContext $context,
        int $userId,
        ?Sale $existingDraft,
        bool $isHeld
    ): JsonResponse {
        $validated = $request->validate([
            'warehouse_id' => ['nullable', 'integer'],
            'customer_id' => ['nullable', 'integer'],
            'biller_id' => ['nullable', 'integer'],
            'table_id' => ['nullable', 'integer'],
            'cash_register_id' => ['nullable', 'integer'],
            'order_type' => ['nullable', 'string', 'in:dine_in,takeaway,delivery'],
            'order_discount' => ['nullable', 'numeric', 'min:0'],
            'order_tax_rate' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'shipping_cost' => ['nullable', 'numeric', 'min:0'],
            'round_off_amount' => ['nullable', 'numeric', 'min:-1', 'max:1'],
            'price_tier' => ['nullable', 'string', 'max:40'],
            'line_notes' => ['nullable', 'array'],
            'sale_note' => ['nullable', 'string', 'max:1000'],
            'staff_note' => ['nullable', 'string', 'max:1000'],
            'payment_method' => ['nullable', 'string', 'in:Cash,UPI,Card,Credit Card,Bank,Cheque,Credit'],
            'paid_amount' => ['nullable', 'numeric', 'min:0'],
            'payments' => ['nullable', 'array'],
            'payments.*.method' => ['required_with:payments', 'string', 'in:Cash,UPI,Card,Credit Card,Bank,Cheque,Credit'],
            'payments.*.amount' => ['required_with:payments', 'numeric', 'gt:0'],
            'payments.*.note' => ['nullable', 'string', 'max:250'],
            'items' => [$existingDraft ? 'nullable' : 'required', 'array', 'min:1'],
            'items.*.product_id' => ['required_with:items', 'integer'],
            'items.*.qty' => ['required_with:items', 'numeric', 'gt:0'],
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.net_unit_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.discount' => ['nullable', 'numeric', 'min:0'],
            'items.*.tax_rate' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'items.*.variant_id' => ['nullable', 'integer'],
            'items.*.note' => ['nullable', 'string', 'max:160'],
        ]);

        $rawItems = $validated['items'] ?? null;
        if ($rawItems === null && $existingDraft) {
            $rawItems = Product_Sale::where('sale_id', $existingDraft->id)
                ->get()
                ->map(fn (Product_Sale $ps) => [
                    'product_id' => (int) $ps->product_id,
                    'qty' => (float) $ps->qty,
                    'unit_price' => (float) $ps->net_unit_price,
                    'discount' => (float) ($ps->discount ?? 0),
                    'tax_rate' => (float) ($ps->tax_rate ?? 0),
                    'variant_id' => $ps->variant_id ? (int) $ps->variant_id : null,
                ])->all();
        }

        if (empty($rawItems)) {
            return $this->sendError('At least one line item is required for a POS order.', ['items' => ['Empty cart.']], 422);
        }

        try {
            $sale = DB::transaction(function () use ($request, $validated, $rawItems, $context, $userId, $existingDraft, $isHeld) {
                $context = $this->guard->context($context, $userId);
                $businessDate = $this->guard->begin($context, now()->toDateString());

                $warehouseId = $validated['warehouse_id'] ?? $existingDraft?->warehouse_id ?? $this->resolveDefaultWarehouseId($context);
                $warehouse = $this->guard->warehouse($warehouseId, $context, $userId, false);

                $requestedCustomerId = $validated['customer_id'] ?? $existingDraft?->customer_id;
                if ($requestedCustomerId) {
                    $sharedWalkIn = DB::table('customers')
                        ->withoutCompanyScope()
                        ->where('id', (int) $requestedCustomerId)
                        ->where('is_active', true)
                        ->whereNull('company_id')
                        ->exists();
                    if ($sharedWalkIn) {
                        $requestedCustomerId = $this->resolveDefaultCustomerId($context->companyId);
                    }
                }
                $customerId = $requestedCustomerId ?: $this->resolveDefaultCustomerId($context->companyId);
                if (!$customerId) {
                    throw ValidationException::withMessages(['customer_id' => ['No active customer configured for this company.']]);
                }
                $this->guard->owned(Customer::class, $customerId, $context, 'customer_id');

                $billerId = $validated['biller_id'] ?? $existingDraft?->biller_id ?? Biller::where('company_id', $context->companyId)->where('is_active', true)->orderBy('id')->value('id');
                if ($billerId) {
                    $this->guard->owned(Biller::class, $billerId, $context, 'biller_id');
                }

                $tableId = array_key_exists('table_id', $validated)
                    ? ($validated['table_id'] ? (int) $validated['table_id'] : null)
                    : $existingDraft?->table_id;

                if ($tableId !== null) {
                    $table = Table::whereKey($tableId)->where('is_active', true)->first();
                    if (!$table) {
                        throw ValidationException::withMessages(['table_id' => ['Selected dining table was not found or is inactive.']]);
                    }
                    $occupied = Sale::query()
                        ->where('company_id', $context->companyId)
                        ->where('sale_status', 3)
                        ->where('table_id', $tableId)
                        ->when($existingDraft, fn ($q) => $q->where('id', '!=', $existingDraft->id))
                        ->exists();
                    if ($occupied) {
                        throw ValidationException::withMessages(['table_id' => ["Table {$table->name} already has an active held ticket."]]);
                    }
                }

                $cashRegisterId = $validated['cash_register_id']
                    ?? $existingDraft?->cash_register_id
                    ?? $this->resolveCashRegisterId($request, $userId, $context, (int) $warehouse->id);

                $productIds = array_values(array_unique(array_map(fn ($row) => (int) $row['product_id'], $rawItems)));
                $products = Product::query()
                    ->whereIn('id', $productIds)
                    ->where('is_active', true)
                    ->where('company_id', $context->companyId)
                    ->get()
                    ->keyBy('id');

                if ($products->count() !== count($productIds)) {
                    $missing = array_diff($productIds, $products->keys()->all());
                    throw ValidationException::withMessages([
                        'items' => ['Invalid or inaccessible product IDs for active company: '.implode(', ', $missing)],
                    ]);
                }

                $taxRates = DB::table('taxes')->pluck('rate', 'id');
                $defaultUnitId = (int) (Unit::orderBy('id')->value('id') ?: 1);

                $preparedLines = [];
                $totalQty = 0.0;
                $totalDiscount = 0.0;
                $totalTax = 0.0;
                $totalPrice = 0.0;

                foreach ($rawItems as $line) {
                    /** @var Product $product */
                    $product = $products->get((int) $line['product_id']);
                    $qty = round((float) $line['qty'], 4);
                    $unitPrice = round((float) ($line['unit_price'] ?? $line['net_unit_price'] ?? $product->price), 2);
                    $discount = round((float) ($line['discount'] ?? 0), 2);
                    $taxRate = round((float) ($line['tax_rate'] ?? ($product->tax_id ? ($taxRates->get($product->tax_id) ?? 0) : 0)), 2);

                    $gross = max(0.0, ($unitPrice * $qty) - $discount);
                    $lineTax = round(($gross * $taxRate) / 100.0, 2);
                    $lineTotal = round($gross + $lineTax, 2);

                    $totalQty += $qty;
                    $totalDiscount += $discount;
                    $totalTax += $lineTax;
                    $totalPrice += $lineTotal;

                    $preparedLines[] = [
                        'product' => $product,
                        'qty' => $qty,
                        'variant_id' => $line['variant_id'] ?? null,
                        'sale_unit_id' => (int) ($product->sale_unit_id ?: $product->unit_id ?: $defaultUnitId),
                        'net_unit_price' => $unitPrice,
                        'discount' => $discount,
                        'tax_rate' => $taxRate,
                        'tax' => $lineTax,
                        'total' => $lineTotal,
                    ];
                }

                $orderDiscount = round((float) ($validated['order_discount'] ?? $existingDraft?->order_discount ?? 0), 2);
                $orderTaxRate = round((float) ($validated['order_tax_rate'] ?? $existingDraft?->order_tax_rate ?? 0), 2);
                $shippingCost = round((float) ($validated['shipping_cost'] ?? $existingDraft?->shipping_cost ?? 0), 2);
                $roundOffAmount = round((float) ($validated['round_off_amount'] ?? $existingDraft?->attributes_json['round_off_amount'] ?? 0), 2);

                $taxableBase = max(0.0, $totalPrice - $orderDiscount);
                $orderTax = round(($taxableBase * $orderTaxRate) / 100.0, 2);
                $grandTotal = round(max(0.0, $taxableBase + $orderTax + $shippingCost + $roundOffAmount), 2);

                $orderType = $validated['order_type']
                    ?? ($existingDraft?->attributes_json['order_type'] ?? ($tableId ? 'dine_in' : 'takeaway'));

                $tenders = [];
                $paidAmount = 0.0;
                $paymentStatus = 1; // Pending

                if (!$isHeld) {
                    $tenders = $this->normalizeTenders($validated, $grandTotal);
                    foreach ($tenders as $tender) {
                        if ($tender['method'] !== 'Credit') {
                            $paidAmount += $tender['amount'];
                        }
                    }
                    $paidAmount = round(min($paidAmount, $grandTotal), 2);
                    $paymentStatus = $paidAmount >= ($grandTotal - 0.01)
                        ? 4 // Paid
                        : ($paidAmount > 0 ? 3 : 1); // Partial / Pending
                }

                $reservation = null;
                if (!$isHeld) {
                    $reservation = $this->numbers->reserve('sale', $context, $businessDate, $userId);
                }

                $sale = $existingDraft ?? new Sale();
                if ($reservation) {
                    $sale->reference_no = $reservation->formatted_number;
                } elseif (!$existingDraft) {
                    $sale->reference_no = 'HLD-'.now()->format('YmdHis').'-'.strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));
                }

                $sale->fill([
                    'user_id' => $userId,
                    'cash_register_id' => $cashRegisterId,
                    'table_id' => $isHeld ? $tableId : null,
                    'customer_id' => $customerId,
                    'warehouse_id' => $warehouse->id,
                    'biller_id' => $billerId,
                    'item' => count($preparedLines),
                    'total_qty' => round($totalQty, 2),
                    'total_discount' => round($totalDiscount, 2),
                    'total_tax' => round($totalTax, 2),
                    'total_price' => round($totalPrice, 2),
                    'grand_total' => $grandTotal,
                    'currency_id' => $sale->currency_id ?? 1,
                    'exchange_rate' => $sale->exchange_rate ?? 1,
                    'order_tax_rate' => $orderTaxRate,
                    'order_tax' => $orderTax,
                    'order_discount_type' => $orderDiscount > 0 ? 'Flat' : null,
                    'order_discount_value' => $orderDiscount,
                    'order_discount' => $orderDiscount,
                    'shipping_cost' => $shippingCost,
                    'sale_status' => $isHeld ? 3 : 1,
                    'payment_status' => $paymentStatus,
                    'paid_amount' => $paidAmount,
                    'sale_note' => $validated['sale_note'] ?? $sale->sale_note,
                    'staff_note' => $validated['staff_note'] ?? $sale->staff_note,
                    'sale_type' => 'pos',
                ]);
                $sale->company_id = $context->companyId;
                $sale->branch_id = $context->branchId;
                $sale->financial_year_id = $context->financialYearId;
                $sale->posted_at = $isHeld ? null : now();
                $existingAttrs = is_array($sale->attributes_json) ? $sale->attributes_json : [];
                $lineNotes = is_array($request->input('line_notes')) ? $request->input('line_notes') : ($existingAttrs['line_notes'] ?? []);
                foreach ($rawItems as $rawItem) {
                    if (!empty($rawItem['note']) && !empty($rawItem['product_id'])) {
                        $lineNotes[(string) $rawItem['product_id']] = trim((string) $rawItem['note']);
                    }
                }
                $sale->attributes_json = array_merge($existingAttrs, [
                    'source' => 'mobile_pos',
                    'order_type' => $orderType,
                    'table_id' => $tableId,
                    'kds_status' => $existingAttrs['kds_status'] ?? 'new',
                    'price_tier' => (string) ($request->input('price_tier') ?? $existingAttrs['price_tier'] ?? 'Retail MRP'),
                    'round_off_amount' => round((float) ($request->input('round_off_amount') ?? $existingAttrs['round_off_amount'] ?? 0), 2),
                    'line_notes' => $lineNotes,
                ]);
                $sale->save();

                if ($reservation) {
                    $this->numbers->assign($reservation, $sale);
                }

                if ($existingDraft) {
                    Product_Sale::where('sale_id', $sale->id)->delete();
                }

                $stockLines = [];
                foreach ($preparedLines as $line) {
                    /** @var Product $product */
                    $product = $line['product'];
                    $ps = new Product_Sale([
                        'sale_id' => $sale->id,
                        'product_id' => $product->id,
                        'variant_id' => $line['variant_id'],
                        'qty' => $line['qty'],
                        'return_qty' => 0,
                        'sale_unit_id' => $line['sale_unit_id'],
                        'net_unit_price' => $line['net_unit_price'],
                        'discount' => $line['discount'],
                        'tax_rate' => $line['tax_rate'],
                        'tax' => $line['tax'],
                        'total' => $line['total'],
                    ]);
                    $ps->company_id = $context->companyId;
                    $ps->save();

                    if (!$isHeld && ($product->type ?? 'standard') === 'standard') {
                        $availQty = (float) DB::table('product_warehouse')
                            ->where('warehouse_id', $warehouse->id)
                            ->where('product_id', $product->id)
                            ->sum('qty');

                        // Only post ledger stock issue when ERP projection tracks stock for this SKU
                        if ($availQty >= $line['qty'] - 0.0001) {
                            $stockLines[] = new StockLine(
                                productId: (int) $product->id,
                                qty: (float) $line['qty'],
                                variantId: $line['variant_id'] ? (int) $line['variant_id'] : null,
                                uomId: (int) $line['sale_unit_id'],
                            );
                        }
                    }
                }

                if (!$isHeld) {
                    $movement = null;
                    if ($stockLines !== []) {
                        $movement = $this->inventory->issue(new StockMovementCommand(
                            date: $businessDate,
                            lines: $stockLines,
                            warehouseId: (int) $warehouse->id,
                            sourceType: 'sale',
                            sourceId: (int) $sale->id,
                            sourceNo: $sale->reference_no,
                            idempotencyKey: 'pos_sale:'.$sale->id,
                            userId: $userId,
                            context: $context,
                        ));
                    }

                    $tenderBreakdown = ['Cash' => 0.0, 'Bank' => 0.0, 'AR' => 0.0];
                    $remainingBalance = $grandTotal;

                    foreach ($tenders as $tender) {
                        if ($tender['method'] === 'Credit') {
                            $tenderBreakdown['AR'] += $tender['amount'];
                            continue;
                        }
                        if ($remainingBalance <= 0.005) {
                            continue;
                        }
                        $applied = round(min($tender['amount'], $remainingBalance), 2);
                        $remainingBalance = round($remainingBalance - $applied, 2);

                        $payMethodLabel = $tender['method'] === 'Card' ? 'Credit Card' : $tender['method'];
                        $payAccount = $this->resolvePaymentAccountForMethod($tender['method'], $context, $userId);
                        $payRes = $this->numbers->reserve('sale_payment', $context, $businessDate, $userId);

                        $payment = Payment::create([
                            'payment_reference' => $payRes->formatted_number,
                            'user_id' => $userId,
                            'sale_id' => $sale->id,
                            'cash_register_id' => $cashRegisterId,
                            'account_id' => $payAccount?->id ?? 1,
                            'amount' => $applied,
                            'used_points' => 0,
                            'change' => round(max(0.0, $tender['amount'] - $applied), 2),
                            'paying_method' => $payMethodLabel,
                            'payment_note' => $tender['note'] ?? null,
                            'company_id' => $context->companyId,
                        ]);
                        $this->numbers->assign($payRes, $payment);

                        if ($tender['method'] === 'Cash') {
                            $tenderBreakdown['Cash'] += $applied;
                        } else {
                            $tenderBreakdown['Bank'] += $applied;
                        }
                    }

                    // Any uncollected residual goes to Accounts Receivable
                    $settledCashBank = round($tenderBreakdown['Cash'] + $tenderBreakdown['Bank'], 2);
                    $arAmount = round(max(0.0, $grandTotal - $settledCashBank), 2);

                    if ($arAmount > 0.01 && !$request->boolean('override_credit_limit')) {
                        $customerLimit = (float) (DB::table('customers')->where('id', $customerId)->value('credit_limit') ?? 0);
                        if ($customerLimit > 0) {
                            $existingDue = (float) Sale::query()
                                ->where('company_id', $context->companyId)
                                ->where('customer_id', $customerId)
                                ->whereNull('deleted_at')
                                ->where('sale_status', 1)
                                ->where('id', '!=', $sale->id)
                                ->selectRaw('COALESCE(SUM(grand_total - paid_amount), 0) as due')
                                ->value('due');
                            if (($existingDue + $arAmount) > ($customerLimit + 0.01)) {
                                throw ValidationException::withMessages([
                                    'customer_id' => [
                                        sprintf('Customer credit limit (₹%.2f) exceeded. Existing due ₹%.2f + new credit ₹%.2f.', $customerLimit, $existingDue, $arAmount),
                                    ],
                                ]);
                            }
                        }
                    }

                    $this->postSaleJournalMultiTender(
                        $sale,
                        $tenderBreakdown['Cash'],
                        $tenderBreakdown['Bank'],
                        $arAmount,
                        $movement ? (int) $movement->id : null,
                        $context,
                        $userId
                    );
                }

                return $sale->fresh(['customer:id,name,phone_number', 'warehouse:id,name', 'payments']);
            });
        } catch (ValidationException $e) {
            return $this->sendError($e->getMessage(), $e->errors(), 422);
        }

        $returns = Returns::query()->where('company_id', $context->companyId)->where('sale_id', $sale->id)->get();

        return $this->sendResponse(
            $this->formatSale($sale, true, $returns),
            $isHeld ? 'POS draft held successfully' : 'POS order completed successfully',
            $existingDraft ? 200 : 201
        );
    }

    private function isHeldRequest(Request $request): bool
    {
        $status = $request->input('status');
        if (is_string($status) && strtolower($status) === 'held') {
            return true;
        }

        return (int) $request->input('sale_status', 0) === 3 || $request->boolean('hold');
    }

    /**
     * @return array<int, array{method:string, amount:float, note:?string}>
     */
    private function normalizeTenders(array $validated, float $grandTotal): array
    {
        if (array_key_exists('payments', $validated) && is_array($validated['payments'])) {
            if (count($validated['payments']) > 0) {
                return array_values(array_map(fn ($row) => [
                    'method' => (string) $row['method'],
                    'amount' => round((float) $row['amount'], 2),
                    'note' => $row['note'] ?? null,
                ], $validated['payments']));
            }

            $explicitPaid = array_key_exists('paid_amount', $validated) && $validated['paid_amount'] !== null
                ? round((float) $validated['paid_amount'], 2)
                : 0.0;
            $explicitMethod = (string) ($validated['payment_method'] ?? 'Credit');
            if ($explicitPaid <= 0 || $explicitMethod === 'Credit') {
                return [['method' => 'Credit', 'amount' => $grandTotal, 'note' => null]];
            }

            return [['method' => $explicitMethod, 'amount' => $explicitPaid, 'note' => null]];
        }

        $method = (string) ($validated['payment_method'] ?? 'Cash');
        if ($method === 'Credit') {
            return [['method' => 'Credit', 'amount' => $grandTotal, 'note' => null]];
        }

        $paid = array_key_exists('paid_amount', $validated) && $validated['paid_amount'] !== null
            ? round((float) $validated['paid_amount'], 2)
            : $grandTotal;

        if ($paid <= 0) {
            return [['method' => 'Credit', 'amount' => $grandTotal, 'note' => null]];
        }

        return [['method' => $method, 'amount' => $paid, 'note' => null]];
    }

    private function findOpenRegister(int $userId, int $companyId, ?int $warehouseId = null): ?CashRegister
    {
        $warehouseIds = Warehouse::query()
            ->where('company_id', $companyId)
            ->pluck('id');

        if ($warehouseIds->isEmpty()) {
            return null;
        }

        $query = CashRegister::query()
            ->where('user_id', $userId)
            ->where('status', true)
            ->whereIn('warehouse_id', $warehouseIds);

        if ($warehouseId !== null && $warehouseIds->contains($warehouseId)) {
            $query->where('warehouse_id', $warehouseId);
        }

        return $query->latest('id')->first();
    }

    private function resolveCashRegisterId(Request $request, int $userId, CompanyContext $context, int $warehouseId): ?int
    {
        if ($request->filled('cash_register_id')) {
            $id = (int) $request->input('cash_register_id');
            $warehouseIds = Warehouse::where('company_id', $context->companyId)->pluck('id');
            $valid = CashRegister::query()
                ->whereKey($id)
                ->where('status', true)
                ->whereIn('warehouse_id', $warehouseIds)
                ->value('id');

            if (!$valid) {
                throw ValidationException::withMessages(['cash_register_id' => ['Cash register is closed or does not belong to this company.']]);
            }

            return (int) $valid;
        }

        $open = $this->findOpenRegister($userId, $context->companyId, $warehouseId)
            ?? $this->findOpenRegister($userId, $context->companyId, null);

        return $open ? (int) $open->id : null;
    }

    private function buildShiftSummary(CashRegister $register, CompanyContext $context): array
    {
        $companyId = $context->companyId;
        $paymentsQuery = Payment::query()
            ->where('cash_register_id', $register->id)
            ->where('company_id', $companyId)
            ->whereNotNull('sale_id');

        $totalPayment = (float) (clone $paymentsQuery)->sum('amount');
        $cashPayment = (float) (clone $paymentsQuery)->where('paying_method', 'Cash')->sum('amount');
        $upiPayment = (float) (clone $paymentsQuery)->where('paying_method', 'UPI')->sum('amount');
        $cardPayment = (float) (clone $paymentsQuery)->whereIn('paying_method', ['Card', 'Credit Card'])->sum('amount');
        $chequePayment = (float) (clone $paymentsQuery)->where('paying_method', 'Cheque')->sum('amount');
        $giftCardPayment = (float) (clone $paymentsQuery)->where('paying_method', 'Gift Card')->sum('amount');
        $bankPayment = (float) (clone $paymentsQuery)->where('paying_method', 'Bank')->sum('amount');

        $salesQuery = Sale::query()
            ->where('cash_register_id', $register->id)
            ->where('company_id', $companyId)
            ->where('sale_status', 1);

        $totalSalesCount = (clone $salesQuery)->count();
        $totalSaleAmount = (float) (clone $salesQuery)->sum('grand_total');
        $creditSaleAmount = round(max(0.0, $totalSaleAmount - $totalPayment), 2);

        $totalSaleReturn = (float) Returns::query()
            ->where('cash_register_id', $register->id)
            ->where('company_id', $companyId)
            ->sum('grand_total');

        $totalExpense = (float) Expense::query()
            ->where('cash_register_id', $register->id)
            ->where('company_id', $companyId)
            ->sum('amount');

        $expectedCash = round(max(0.0, (float) $register->cash_in_hand + $cashPayment - $totalSaleReturn - $totalExpense), 2);
        $warehouseName = Warehouse::whereKey($register->warehouse_id)->value('name');

        return [
            'id' => (int) $register->id,
            'warehouse_id' => (int) $register->warehouse_id,
            'warehouse_name' => $warehouseName,
            'user_id' => (int) $register->user_id,
            'status' => (bool) $register->status ? 'open' : 'closed',
            'opened_at' => $register->created_at?->toIso8601String(),
            'closed_at' => !(bool) $register->status ? $register->updated_at?->toIso8601String() : null,
            'cash_in_hand' => round((float) $register->cash_in_hand, 2),
            'total_sales_count' => $totalSalesCount,
            'total_sale_amount' => round($totalSaleAmount, 2),
            'total_payment' => round($totalPayment, 2),
            'cash_payment' => round($cashPayment, 2),
            'upi_payment' => round($upiPayment, 2),
            'card_payment' => round($cardPayment, 2),
            'bank_payment' => round($bankPayment, 2),
            'cheque_payment' => round($chequePayment, 2),
            'gift_card_payment' => round($giftCardPayment, 2),
            'credit_sale_amount' => $creditSaleAmount,
            'total_sale_return' => round($totalSaleReturn, 2),
            'total_expense' => round($totalExpense, 2),
            'expected_cash' => $expectedCash,
            'closing_balance' => $register->closing_balance !== null ? round((float) $register->closing_balance, 2) : null,
            'actual_cash' => $register->actual_cash !== null ? round((float) $register->actual_cash, 2) : null,
        ];
    }

    private function companySupportsDiningTables(int $companyId): bool
    {
        if (Schema::hasColumn('tables', 'company_id')) {
            return true;
        }

        $company = DB::table('companies')
            ->where('id', $companyId)
            ->first(['code', 'trade_name', 'legal_name', 'settings_json']);

        if (!$company) {
            return false;
        }

        $settings = is_string($company->settings_json ?? null)
            ? json_decode($company->settings_json, true)
            : (array) ($company->settings_json ?? []);
        $industry = strtolower((string) ($settings['industry'] ?? ''));
        $code = strtolower((string) ($company->code ?? ''));
        $name = strtolower((string) ($company->trade_name ?? $company->legal_name ?? ''));

        return $industry === 'cafe_bakery'
            || str_contains($code, 'cafe')
            || str_contains($name, 'cafe')
            || str_contains($name, 'bakery');
    }

    private function loadTablesPayload(CompanyContext $context): array
    {
        if (!$this->companySupportsDiningTables($context->companyId)) {
            return [];
        }

        $hasFloors = Schema::hasTable('floors');
        $tablesQuery = Table::query()->where('tables.is_active', true);

        if (Schema::hasColumn('tables', 'company_id')) {
            $tablesQuery->where('tables.company_id', $context->companyId);
        }

        if ($hasFloors) {
            $tablesQuery->leftJoin('floors', 'tables.floor_id', '=', 'floors.id')
                ->select('tables.*', 'floors.name as floor_name');
        } else {
            $tablesQuery->select('tables.*');
        }

        $tables = $tablesQuery->orderBy('tables.id')->get();
        $heldByTable = Sale::query()
            ->with('customer:id,name')
            ->where('company_id', $context->companyId)
            ->where('sale_status', 3)
            ->whereNotNull('table_id')
            ->get()
            ->keyBy('table_id');

        return $tables->map(function ($table) use ($heldByTable) {
            /** @var Sale|null $held */
            $held = $heldByTable->get($table->id);

            return [
                'id' => (int) $table->id,
                'name' => (string) $table->name,
                'seats' => (int) ($table->number_of_person ?? 2),
                'floor_id' => $table->floor_id ? (int) $table->floor_id : null,
                'floor_name' => $table->floor_name ?? null,
                'description' => $table->description,
                'status' => $held ? 'occupied' : 'available',
                'held_sale_id' => $held ? (int) $held->id : null,
                'held_reference_no' => $held?->reference_no,
                'held_grand_total' => $held ? round((float) $held->grand_total, 2) : null,
                'held_customer_name' => $held?->customer?->name,
            ];
        })->values()->all();
    }

    private function resolveDefaultWarehouseId(CompanyContext $context): ?int
    {
        $id = Warehouse::query()
            ->where('company_id', $context->companyId)
            ->where('is_active', true)
            ->orderByRaw('CASE WHEN branch_id = ? THEN 0 ELSE 1 END', [$context->branchId])
            ->orderBy('id')
            ->value('id');

        return $id ? (int) $id : null;
    }

    private function resolveDefaultCustomerId(int $companyId, ?int $preferredId = null): ?int
    {
        if ($preferredId) {
            $exists = Customer::query()
                ->where('company_id', $companyId)
                ->where('is_active', true)
                ->whereKey($preferredId)
                ->value('id');
            if ($exists) {
                return (int) $exists;
            }
        }

        $id = Customer::query()
            ->where('company_id', $companyId)
            ->where('is_active', true)
            ->orderByRaw("CASE WHEN LOWER(name) LIKE '%walk%' THEN 0 ELSE 1 END")
            ->orderBy('id')
            ->value('id');

        if ($id) {
            return (int) $id;
        }

        $groupId = (int) (DB::table('customer_groups')->withoutCompanyScope()->orderBy('id')->value('id') ?: 1);
        $created = new Customer([
            'customer_group_id' => $groupId,
            'name' => 'Walk-in Customer',
            'company_name' => 'Walk-in Customer',
            'phone_number' => '0000000000',
            'is_active' => true,
        ]);
        $created->company_id = $companyId;
        $created->save();

        return (int) $created->id;
    }

    private function resolvePaymentAccountForMethod(string $method, CompanyContext $context, int $userId)
    {
        $role = $method === 'Cash' ? 'cash' : 'bank';

        return $this->accounting->getAccount($role, $context, $userId);
    }

    private function postSaleJournalMultiTender(
        Sale $sale,
        float $cashAmount,
        float $bankAmount,
        float $arAmount,
        ?int $stockMovementId,
        CompanyContext $context,
        int $userId
    ): void {
        $cashAcc = $this->accounting->getAccount('cash', $context, $userId);
        $bankAcc = $this->accounting->getAccount('bank', $context, $userId);
        $arAcc = $this->accounting->getAccount('ar', $context, $userId);
        $salesAcc = $this->accounting->getAccount('sales', $context, $userId);
        $taxAcc = $this->accounting->getAccount('tax_output', $context, $userId);
        $discountAcc = $this->accounting->getAccount('discounts', $context, $userId);
        $freightAcc = $this->accounting->getAccount('freight', $context, $userId);

        if (!$salesAcc) {
            return;
        }

        $items = [];
        if ($cashAmount >= 0.01 && $cashAcc) {
            $items[] = [
                'chart_of_account_id' => $cashAcc->id,
                'debit' => round($cashAmount, 2),
                'credit' => 0,
                'memo' => 'POS Cash receipt '.$sale->reference_no,
            ];
        }
        if ($bankAmount >= 0.01 && $bankAcc) {
            $items[] = [
                'chart_of_account_id' => $bankAcc->id,
                'debit' => round($bankAmount, 2),
                'credit' => 0,
                'memo' => 'POS Digital/UPI/Card receipt '.$sale->reference_no,
            ];
        }
        if ($arAmount >= 0.01 && $arAcc) {
            $items[] = [
                'chart_of_account_id' => $arAcc->id,
                'debit' => round($arAmount, 2),
                'credit' => 0,
                'memo' => 'POS Credit receivable '.$sale->reference_no,
                'partner_type' => 'customer',
                'partner_id' => (int) $sale->customer_id,
            ];
        }

        $orderDiscount = round((float) ($sale->order_discount ?? 0), 2);
        if ($orderDiscount >= 0.01 && $discountAcc) {
            $items[] = [
                'chart_of_account_id' => $discountAcc->id,
                'debit' => $orderDiscount,
                'credit' => 0,
                'memo' => 'POS Order discount '.$sale->reference_no,
            ];
        }

        $totalTax = round((float) ($sale->total_tax ?? 0) + (float) ($sale->order_tax ?? 0), 2);
        $shipping = round((float) ($sale->shipping_cost ?? 0), 2);

        $debitSum = round(array_sum(array_column($items, 'debit')), 2);
        $taxCredit = ($totalTax >= 0.01 && $taxAcc) ? $totalTax : 0.0;
        $freightCredit = ($shipping >= 0.01 && $freightAcc) ? $shipping : 0.0;
        $salesCredit = round($debitSum - $taxCredit - $freightCredit, 2);

        if ($salesCredit >= 0.01) {
            $items[] = [
                'chart_of_account_id' => $salesAcc->id,
                'debit' => 0,
                'credit' => $salesCredit,
                'memo' => 'POS Sales revenue '.$sale->reference_no,
            ];
        }
        if ($taxCredit >= 0.01 && $taxAcc) {
            $items[] = [
                'chart_of_account_id' => $taxAcc->id,
                'debit' => 0,
                'credit' => $taxCredit,
                'memo' => 'POS Output tax '.$sale->reference_no,
            ];
        }
        if ($freightCredit >= 0.01 && $freightAcc) {
            $items[] = [
                'chart_of_account_id' => $freightAcc->id,
                'debit' => 0,
                'credit' => $freightCredit,
                'memo' => 'POS Delivery charge '.$sale->reference_no,
            ];
        }

        if ($stockMovementId) {
            $cogsValue = round((float) DB::table('stock_movement_lines')
                ->where('stock_movement_id', $stockMovementId)
                ->selectRaw('SUM(ABS(value)) as total_val')
                ->value('total_val'), 2);
            $cogsAcc = $this->accounting->getAccount('cogs', $context, $userId);
            $invAcc = $this->accounting->getAccount('inventory', $context, $userId);
            if ($cogsValue >= 0.01 && $cogsAcc && $invAcc) {
                $items[] = ['chart_of_account_id' => $cogsAcc->id, 'debit' => $cogsValue, 'credit' => 0, 'memo' => 'POS COGS '.$sale->reference_no];
                $items[] = ['chart_of_account_id' => $invAcc->id, 'debit' => 0, 'credit' => $cogsValue, 'memo' => 'POS Inventory issue '.$sale->reference_no];
            }
        }

        if ($items !== []) {
            $this->accounting->postJournalEntry([
                'entry_date' => Carbon::parse($sale->created_at ?? now())->toDateString(),
                'reference_type' => 'sale',
                'reference_id' => (int) $sale->id,
                'reference_no' => $sale->reference_no,
                'description' => 'POS Sale '.$sale->reference_no,
                'posting_key' => 'pos_sale:'.$sale->id.':v1',
            ], $items, $context);
        }
    }

    private function postReturnJournal(
        Returns $returnDoc,
        float $netSubtotal,
        float $totalTax,
        float $grandTotal,
        string $refundMethod,
        CompanyContext $context,
        int $userId
    ) {
        $salesAcc = $this->accounting->getAccount('sales', $context, $userId);
        $taxAcc = $this->accounting->getAccount('tax_output', $context, $userId);
        $creditRole = match ($refundMethod) {
            'Cash' => 'cash',
            'Credit' => 'ar',
            default => 'bank',
        };
        $creditAcc = $this->accounting->getAccount($creditRole, $context, $userId);

        if (!$salesAcc || !$creditAcc || $grandTotal < 0.01) {
            return null;
        }

        $taxDebit = ($totalTax >= 0.01 && $taxAcc) ? round($totalTax, 2) : 0.0;
        $salesDebit = round($grandTotal - $taxDebit, 2);

        $items = [
            [
                'chart_of_account_id' => $salesAcc->id,
                'debit' => $salesDebit,
                'credit' => 0,
                'memo' => 'POS Return reversal '.$returnDoc->reference_no,
            ],
        ];
        if ($taxDebit >= 0.01 && $taxAcc) {
            $items[] = [
                'chart_of_account_id' => $taxAcc->id,
                'debit' => $taxDebit,
                'credit' => 0,
                'memo' => 'POS Output tax reversal '.$returnDoc->reference_no,
            ];
        }
        $creditLine = [
            'chart_of_account_id' => $creditAcc->id,
            'debit' => 0,
            'credit' => round($grandTotal, 2),
            'memo' => 'POS Refund ('.$refundMethod.') '.$returnDoc->reference_no,
        ];
        if ($creditRole === 'ar') {
            $creditLine['partner_type'] = 'customer';
            $creditLine['partner_id'] = (int) $returnDoc->customer_id;
        }
        $items[] = $creditLine;

        return $this->accounting->postJournalEntry([
            'entry_date' => Carbon::parse($returnDoc->created_at ?? now())->toDateString(),
            'reference_type' => 'sale_credit_note',
            'reference_id' => (int) $returnDoc->id,
            'reference_no' => $returnDoc->reference_no,
            'description' => 'POS Return '.$returnDoc->reference_no,
            'posting_key' => 'pos_return:'.$returnDoc->id.':v1',
        ], $items, $context);
    }

    private function formatSale(Sale $sale, bool $includeLines, $returns = null): array
    {
        $returnsList = $returns ?? collect();
        $refundedTotal = round((float) $returnsList->sum('grand_total'), 2);
        $statusLabel = match ((int) $sale->sale_status) {
            1 => $refundedTotal >= (float) $sale->grand_total - 0.01 && (float) $sale->grand_total > 0
                ? 'returned'
                : ($refundedTotal > 0 ? 'partial_return' : 'completed'),
            3 => 'held',
            4 => 'returned',
            5 => 'voided',
            default => 'pending',
        };

        $customerRow = $sale->customer;
        if ($customerRow === null && $sale->customer_id) {
            $customerRow = DB::table('customers')
                ->withoutCompanyScope()
                ->where('id', $sale->customer_id)
                ->first(['id', 'name', 'phone_number']);
        }

        $data = [
            'id' => (int) $sale->id,
            'reference_no' => (string) $sale->reference_no,
            'sale_status' => (int) $sale->sale_status,
            'sale_status_label' => $statusLabel,
            'kds_status' => $sale->attributes_json['kds_status'] ?? ((int) $sale->sale_status === 3 ? 'new' : 'preparing'),
            'payment_status' => (int) $sale->payment_status,
            'order_type' => $sale->attributes_json['order_type'] ?? 'takeaway',
            'table_id' => $sale->table_id ? (int) $sale->table_id : null,
            'warehouse_id' => (int) $sale->warehouse_id,
            'warehouse_name' => $sale->warehouse?->name,
            'customer_id' => (int) $sale->customer_id,
            'customer_name' => $customerRow?->name ?? 'Walk-in Customer',
            'customer_phone' => $customerRow?->phone_number,
            'cash_register_id' => $sale->cash_register_id ? (int) $sale->cash_register_id : null,
            'item_count' => (int) $sale->item,
            'total_qty' => round((float) $sale->total_qty, 2),
            'total_price' => round((float) $sale->total_price, 2),
            'total_discount' => round((float) $sale->total_discount, 2),
            'total_tax' => round((float) $sale->total_tax, 2),
            'order_discount' => round((float) ($sale->order_discount ?? 0), 2),
            'order_tax' => round((float) ($sale->order_tax ?? 0), 2),
            'shipping_cost' => round((float) ($sale->shipping_cost ?? 0), 2),
            'round_off_amount' => round((float) ($sale->attributes_json['round_off_amount'] ?? 0), 2),
            'price_tier' => (string) ($sale->attributes_json['price_tier'] ?? 'Retail MRP'),
            'line_notes' => is_array($sale->attributes_json['line_notes'] ?? null) ? $sale->attributes_json['line_notes'] : (object) [],
            'grand_total' => round((float) $sale->grand_total, 2),
            'paid_amount' => round((float) $sale->paid_amount, 2),
            'due_amount' => round(max(0.0, (float) $sale->grand_total - (float) $sale->paid_amount), 2),
            'refunded_total' => $refundedTotal,
            'sale_note' => $sale->sale_note,
            'created_at' => $sale->created_at?->toIso8601String(),
            'payments' => $sale->payments->map(fn (Payment $p) => [
                'id' => (int) $p->id,
                'reference' => $p->payment_reference,
                'method' => $p->paying_method,
                'amount' => round((float) $p->amount, 2),
                'change' => round((float) ($p->change ?? 0), 2),
                'created_at' => $p->created_at?->toIso8601String(),
            ])->values()->all(),
            'returns' => $returnsList->map(fn (Returns $r) => [
                'id' => (int) $r->id,
                'reference_no' => $r->reference_no,
                'grand_total' => round((float) $r->grand_total, 2),
                'reason' => $r->return_note,
                'created_at' => $r->created_at?->toIso8601String(),
            ])->values()->all(),
        ];

        if ($includeLines) {
            $lines = Product_Sale::query()
                ->join('products', 'products.id', '=', 'product_sales.product_id')
                ->where('product_sales.sale_id', $sale->id)
                ->select('product_sales.*', 'products.name as product_name', 'products.code as product_code')
                ->get();

            $returnedByLine = $lines->isNotEmpty()
                ? ProductReturn::query()
                    ->whereIn('source_line_id', $lines->pluck('id'))
                    ->selectRaw('source_line_id, SUM(qty) as returned_qty')
                    ->groupBy('source_line_id')
                    ->pluck('returned_qty', 'source_line_id')
                : collect();

            $lineNotes = is_array($sale->attributes_json['line_notes'] ?? null) ? $sale->attributes_json['line_notes'] : [];
            $data['items'] = $lines->map(function ($l) use ($returnedByLine, $lineNotes) {
                $retQty = max((float) ($l->return_qty ?? 0), (float) ($returnedByLine->get($l->id) ?? 0));

                return [
                    'id' => (int) $l->id,
                    'product_id' => (int) $l->product_id,
                    'product_name' => $l->product_name,
                    'product_code' => $l->product_code,
                    'qty' => round((float) $l->qty, 2),
                    'return_qty' => round($retQty, 2),
                    'returnable_qty' => round(max(0.0, (float) $l->qty - $retQty), 2),
                    'net_unit_price' => round((float) $l->net_unit_price, 2),
                    'discount' => round((float) $l->discount, 2),
                    'tax_rate' => round((float) $l->tax_rate, 2),
                    'tax' => round((float) $l->tax, 2),
                    'total' => round((float) $l->total, 2),
                    'note' => $lineNotes[(string) $l->product_id] ?? null,
                ];
            })->values()->all();
        }

        return $data;
    }
}
