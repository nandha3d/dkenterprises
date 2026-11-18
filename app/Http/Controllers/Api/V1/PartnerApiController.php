<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Customer;
use App\Models\Supplier;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class PartnerApiController extends BaseApiController
{
    public function customers(Request $request): JsonResponse
    {
        $request->validate(['per_page' => 'sometimes|integer|min:1|max:100', 'search' => 'nullable|string|max:100']);
        $context = $this->companyContext($request);
        $query = Customer::forCompany($context)->with(['customerGroup' => fn ($q) => $q->forCompany($context)]);
        if ($request->filled('search')) {
            $term = $request->search;
            $query->where(function ($q) use ($term) {
                $q->where('name', 'LIKE', "%{$term}%")
                  ->orWhere('phone_number', 'LIKE', "%{$term}%")
                  ->orWhere('email', 'LIKE', "%{$term}%");
            });
        }

        $customers = $query->where('is_active', true)->paginate($request->input('per_page', 20));
        return $this->sendResponse(\App\Http\Resources\PartyResource::collection($customers->getCollection())->resolve($request), 'Customers retrieved', 200, [
            'pagination' => [
                'total' => $customers->total(),
                'per_page' => $customers->perPage(),
                'current_page' => $customers->currentPage(),
            ]
        ]);
    }

    public function suppliers(Request $request): JsonResponse
    {
        $request->validate(['per_page' => 'sometimes|integer|min:1|max:100', 'search' => 'nullable|string|max:100']);
        $query = Supplier::forCompany($this->companyContext($request));
        if ($request->filled('search')) {
            $term = $request->search;
            $query->where(function ($q) use ($term) {
                $q->where('name', 'LIKE', "%{$term}%")
                  ->orWhere('company_name', 'LIKE', "%{$term}%")
                  ->orWhere('phone_number', 'LIKE', "%{$term}%");
            });
        }

        $suppliers = $query->where('is_active', true)->paginate($request->input('per_page', 20));
        return $this->sendResponse(\App\Http\Resources\PartyResource::collection($suppliers->getCollection())->resolve($request), 'Suppliers retrieved', 200, [
            'pagination' => [
                'total' => $suppliers->total(),
                'per_page' => $suppliers->perPage(),
                'current_page' => $suppliers->currentPage(),
            ]
        ]);
    }

    /**
     * F-03: Update customer credit limit and credit days within the active company.
     */
    public function updateCreditLimit(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $customer = Customer::forCompany($context)->find($id);

        if (!$customer) {
            return $this->sendError('Customer not found in active company.', [], 404);
        }

        $validated = $request->validate([
            'credit_limit' => ['required', 'numeric', 'min:0'],
            'credit_days' => ['nullable', 'integer', 'min:0', 'max:365'],
        ]);

        $customer->credit_limit = round((float) $validated['credit_limit'], 2);
        if (array_key_exists('credit_days', $validated) && $validated['credit_days'] !== null) {
            $customer->credit_days = (int) $validated['credit_days'];
        }
        $customer->save();

        return $this->sendResponse([
            'id' => (int) $customer->id,
            'name' => $customer->name,
            'credit_limit' => (float) $customer->credit_limit,
            'credit_days' => (int) ($customer->credit_days ?? 0),
        ], 'Customer credit limit updated successfully');
    }

    /**
     * A-33: Direct supplier payment voucher (allocates across open purchase bills & posts AP journal).
     */
    public function paySupplier(Request $request, int $id): JsonResponse
    {
        $context = $this->companyContext($request);
        $companyId = $context->companyId;
        $supplier = Supplier::forCompany($context)->find($id);

        if (!$supplier) {
            return $this->sendError('Supplier not found in active company.', [], 404);
        }

        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'paying_method' => ['nullable', 'string', 'max:50'],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $amount = round((float) $validated['amount'], 2);
        $payingMethod = (string) ($validated['paying_method'] ?? 'Cash');
        $note = trim((string) ($validated['note'] ?? "Supplier Payment Voucher to {$supplier->name}"));
        $voucherRef = 'SPAY-' . date('YmdHis') . '-' . strtoupper(substr(bin2hex(random_bytes(2)), 0, 4));

        $result = \Illuminate\Support\Facades\DB::transaction(function () use ($context, $companyId, $supplier, $amount, $payingMethod, $note, $voucherRef) {
            $openPurchases = \Illuminate\Support\Facades\DB::table('purchases')
                ->where('company_id', $companyId)
                ->where('supplier_id', $supplier->id)
                ->whereNull('deleted_at')
                ->whereColumn('paid_amount', '<', 'grand_total')
                ->orderBy('id')
                ->get();

            $accountId = (int) (\Illuminate\Support\Facades\DB::table('accounts')
                ->where('company_id', $companyId)
                ->where('is_active', 1)
                ->value('id') ?: 1);

            $remaining = $amount;
            $allocatedBills = [];

            foreach ($openPurchases as $purchase) {
                if ($remaining <= 0.005) {
                    break;
                }
                $due = max(0.0, (float) $purchase->grand_total - (float) $purchase->paid_amount);
                if ($due <= 0.005) {
                    continue;
                }
                $apply = round(min($remaining, $due), 2);
                $newPaid = round((float) $purchase->paid_amount + $apply, 2);
                $newStatus = $newPaid >= ((float) $purchase->grand_total - 0.01) ? 2 : 1;

                \Illuminate\Support\Facades\DB::table('purchases')
                    ->where('id', $purchase->id)
                    ->update([
                        'paid_amount' => $newPaid,
                        'payment_status' => $newStatus,
                        'updated_at' => now(),
                    ]);

                \Illuminate\Support\Facades\DB::table('payments')->insert([
                    'purchase_id' => $purchase->id,
                    'payment_reference' => $voucherRef . '-' . $purchase->id,
                    'user_id' => \Illuminate\Support\Facades\Auth::id() ?? 1,
                    'account_id' => $accountId,
                    'amount' => $apply,
                    'paying_method' => $payingMethod,
                    'payment_note' => $note,
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $allocatedBills[] = [
                    'purchase_id' => (int) $purchase->id,
                    'reference_no' => $purchase->reference_no,
                    'applied_amount' => $apply,
                ];
                $remaining = round($remaining - $apply, 2);
            }

            if ($allocatedBills === []) {
                \Illuminate\Support\Facades\DB::table('payments')->insert([
                    'payment_reference' => $voucherRef,
                    'user_id' => \Illuminate\Support\Facades\Auth::id() ?? 1,
                    'account_id' => $accountId,
                    'amount' => $amount,
                    'paying_method' => $payingMethod,
                    'payment_note' => $note . ' (Direct AP Settlement)',
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            try {
                $accService = app(\App\Services\Accounting\AccountingService::class);
                $isBank = stripos($payingMethod, 'bank') !== false || stripos($payingMethod, 'upi') !== false || stripos($payingMethod, 'neft') !== false;
                $cashOrBank = $accService->getAccount($isBank ? 'bank' : 'cash', $context)?->id
                    ?? \App\Models\Accounting\ChartOfAccount::forCompany($context)->where('is_active', true)->whereDoesntHave('children')
                        ->where(fn ($q) => $isBank ? $q->where('code', '1020')->orWhere('control_type', 'bank') : $q->where('code', '1010')->orWhere('control_type', 'cash'))
                        ->value('id');
                $apAcc = $accService->getAccount('ap', $context)?->id
                    ?? \App\Models\Accounting\ChartOfAccount::forCompany($context)->where('is_active', true)->whereDoesntHave('children')
                        ->where(fn ($q) => $q->where('code', '2010')->orWhere('control_type', 'ap'))
                        ->value('id');

                if ($cashOrBank && $apAcc) {
                    $accService->postJournalEntry([
                        'entry_date' => now()->toDateString(),
                        'reference_type' => 'voucher',
                        'reference_no' => $voucherRef,
                        'description' => "Supplier Payment [{$voucherRef}] to {$supplier->name}",
                        'created_by' => \Illuminate\Support\Facades\Auth::id() ?? 1,
                    ], [
                        [
                            'chart_of_account_id' => (int) $apAcc,
                            'debit' => $amount,
                            'credit' => 0,
                            'memo' => 'Accounts Payable Settled',
                            'partner_type' => 'supplier',
                            'partner_id' => (int) $supplier->id,
                        ],
                        [
                            'chart_of_account_id' => (int) $cashOrBank,
                            'debit' => 0,
                            'credit' => $amount,
                            'memo' => "Paid via {$payingMethod}",
                        ],
                    ], $context);
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Supplier payment journal warning: ' . $e->getMessage());
            }

            return [
                'voucher_no' => $voucherRef,
                'supplier_id' => (int) $supplier->id,
                'supplier_name' => $supplier->name,
                'amount_paid' => $amount,
                'paying_method' => $payingMethod,
                'allocated_bills' => $allocatedBills,
                'unallocated_advance' => $remaining,
            ];
        });

        return $this->sendResponse($result, 'Supplier payment voucher recorded and posted', 201);
    }
}
