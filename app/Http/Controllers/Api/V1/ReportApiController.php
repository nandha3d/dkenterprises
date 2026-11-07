<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Customer;
use App\Models\Supplier;
use App\Models\Sale;
use App\Models\Purchase;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportApiController extends BaseApiController
{
    /**
     * Mobile Sales Analytics Report.
     */
    public function sales(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        $startDate = $request->input('start_date', date('Y-m-01'));
        $endDate = $request->input('end_date', date('Y-m-d'));

        $query = Sale::whereDate('created_at', '>=', $startDate)
            ->whereDate('created_at', '<=', $endDate)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId));

        $totalSales = (float) $query->sum('grand_total');
        $totalPaid = (float) $query->sum('paid_amount');
        $totalInvoices = $query->count();
        $totalDue = $totalSales - $totalPaid;

        return $this->sendResponse([
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_sales' => $totalSales,
            'total_paid' => $totalPaid,
            'total_due' => $totalDue,
            'total_invoices' => $totalInvoices,
            'invoice_count' => $totalInvoices,
        ], 'Sales analytics report retrieved');
    }

    /**
     * Mobile Purchases Analytics Report.
     */
    public function purchases(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        $startDate = $request->input('start_date', date('Y-m-01'));
        $endDate = $request->input('end_date', date('Y-m-d'));

        $query = Purchase::whereDate('created_at', '>=', $startDate)
            ->whereDate('created_at', '<=', $endDate)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId));

        $totalPurchases = (float) $query->sum('grand_total');
        $totalPaid = (float) $query->sum('paid_amount');
        $totalBills = $query->count();
        $totalDue = $totalPurchases - $totalPaid;

        return $this->sendResponse([
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_purchases' => $totalPurchases,
            'total_paid' => $totalPaid,
            'total_due' => $totalDue,
            'total_bills' => $totalBills,
        ], 'Purchases analytics report retrieved');
    }

    /**
     * Mobile Warehouse Stock Valuation Report.
     */
    public function stock(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        $warehouseId = $request->input('warehouse_id');

        $query = DB::table('product_warehouse')
            ->join('products', 'product_warehouse.product_id', '=', 'products.id')
            ->join('warehouses', 'product_warehouse.warehouse_id', '=', 'warehouses.id')
            ->when($companyId, fn ($q) => $q->where('warehouses.company_id', $companyId))
            ->when($warehouseId, fn ($q) => $q->where('warehouses.id', $warehouseId))
            ->select(
                'products.id as product_id',
                'products.name as product_name',
                'products.code as product_code',
                'products.cost',
                'products.price',
                'warehouses.name as warehouse_name',
                'product_warehouse.qty as stock_qty',
                DB::raw('(product_warehouse.qty * products.cost) as stock_valuation')
            )
            ->orderBy('product_warehouse.qty', 'desc');

        $stockItems = $query->take(100)->get();
        $totalValuation = (float) $stockItems->sum('stock_valuation');

        return $this->sendResponse([
            'warehouse_id' => $warehouseId,
            'total_valuation' => $totalValuation,
            'total_items' => count($stockItems),
            'item_count' => count($stockItems),
            'items' => $stockItems,
        ], 'Stock valuation report retrieved');
    }

    /**
     * Customer 360 Single-Page Chronological Ledger Statement.
     */
    public function customerLedger(Request $request, int $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $startDate = $request->input('start_date', date('Y-04-01'));
        $endDate = $request->input('end_date', date('Y-m-d'));

        // Sales debits
        $sales = Sale::where('customer_id', $id)
            ->whereDate('created_at', '>=', $startDate)
            ->whereDate('created_at', '<=', $endDate)
            ->select('id', 'reference_no', 'grand_total', 'created_at')
            ->get()
            ->map(fn ($s) => [
                'date' => $s->created_at->toDateString(),
                'type' => 'Invoice',
                'reference' => $s->reference_no,
                'debit' => (float) $s->grand_total,
                'credit' => 0.0,
            ]);

        // Payment credits
        $payments = DB::table('payments')
            ->join('sales', 'payments.sale_id', '=', 'sales.id')
            ->where('sales.customer_id', $id)
            ->whereDate('payments.created_at', '>=', $startDate)
            ->whereDate('payments.created_at', '<=', $endDate)
            ->select('payments.id', 'payments.payment_reference', 'payments.amount', 'payments.created_at')
            ->get()
            ->map(fn ($p) => [
                'date' => substr($p->created_at, 0, 10),
                'type' => 'Payment',
                'reference' => $p->payment_reference,
                'debit' => 0.0,
                'credit' => (float) $p->amount,
            ]);

        $entries = $sales->concat($payments)->sortBy('date')->values()->all();

        $openingBalance = (float) $customer->opening_balance;
        $runningBalance = $openingBalance;
        $ledgerRows = [];

        foreach ($entries as $row) {
            $runningBalance += ($row['debit'] - $row['credit']);
            $row['running_balance'] = $runningBalance;
            $ledgerRows[] = $row;
        }

        return $this->sendResponse([
            'customer' => [
                'id' => $customer->id,
                'name' => $customer->name,
                'phone' => $customer->phone_number,
                'opening_balance' => $openingBalance,
                'current_balance' => $runningBalance,
            ],
            'start_date' => $startDate,
            'end_date' => $endDate,
            'opening_balance' => $openingBalance,
            'closing_balance' => $runningBalance,
            'entries' => $ledgerRows,
        ], 'Customer ledger statement retrieved');
    }
}

