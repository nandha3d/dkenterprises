<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\Account;
use App\Services\Accounting\AccountingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ExpenseApiController extends BaseApiController
{
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
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        $limit = min((int) ($request->input('limit', 50)), 100);

        $query = Expense::with(['expenseCategory:id,name,code', 'warehouse:id,name'])
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
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
            'expense_category_id' => 'required',
            'amount' => 'required|numeric|min:0.01',
            'warehouse_id' => 'nullable',
            'account_id' => 'nullable',
            'note' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        if (!$companyId && Auth::check()) {
            $companyId = DB::table('company_user')->where('user_id', Auth::id())->where('is_default', 1)->value('company_id')
                ?? DB::table('company_user')->where('user_id', Auth::id())->value('company_id')
                ?? 1;
        }

        $refNo = 'EXP-' . date('Ymd') . '-' . rand(1000, 9999);
        $amount = (float) $request->amount;
        $documentName = null;

        if ($request->hasFile('document')) {
            $doc = $request->file('document');
            $dir = public_path('documents/expense');
            if (!file_exists($dir)) {
                mkdir($dir, 0755, true);
            }
            $ext = $doc->getClientOriginalExtension();
            $documentName = 'exp_' . date('Ymd_His') . '_' . rand(100, 999) . '.' . $ext;
            $doc->move($dir, $documentName);
        }

        $warehouseId = $request->warehouse_id ?? (DB::table('warehouses')->where('company_id', $companyId)->value('id') ?? 1);
        $accountId = $request->account_id ?? (DB::table('accounts')->where('is_active', true)->value('id') ?? 1);

        $expense = Expense::create([
            'reference_no' => $refNo,
            'expense_category_id' => $request->expense_category_id,
            'warehouse_id' => $warehouseId,
            'account_id' => $accountId,
            'amount' => $amount,
            'user_id' => Auth::id() ?? 1,
            'note' => $request->note . ($request->latitude ? " [GPS: {$request->latitude}, {$request->longitude}]" : ''),
            'document' => $documentName,
            'company_id' => $companyId,
        ]);

        // Post to ledger if requested
        try {
            $this->accountingService->postJournalEntry([
                'entry_date' => date('Y-m-d'),
                'reference_type' => 'Expense',
                'reference_id' => $refNo,
                'narration' => "Operational Expense [{$refNo}] - {$request->note}",
                'items' => [
                    ['account_code' => '5010', 'debit' => $amount, 'credit' => 0, 'memo' => 'Operating Expense'],
                    ['account_code' => '1010', 'debit' => 0, 'credit' => $amount, 'memo' => 'Disbursed from Cash'],
                ]
            ]);
        } catch (\Throwable $e) {}

        return $this->sendResponse($expense, 'Expense recorded successfully', 201);
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
}

