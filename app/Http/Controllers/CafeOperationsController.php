<?php

namespace App\Http\Controllers;

use App\Services\Inventory\InventoryMovementService;
use App\Services\Inventory\StockMovementCommand;
use App\Services\Inventory\StockLine;
use App\Services\Platform\CompanyContext;

use App\Models\Category;
use App\Models\Product;
use App\Models\Warehouse;
use App\Services\Accounting\AccountingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class CafeOperationsController extends Controller
{
    protected $accountingService;

    public function __construct(AccountingService $accountingService)
    {
        $this->accountingService = $accountingService;
    }

    public function index()
    {
        $rawMaterials = DB::table('cafe_raw_materials')->latest()->take(20)->get();
        $cashDrawers = DB::table('cafe_cash_drawers')->latest()->take(15)->get();
        $products = Product::where('is_active', true)->select('id', 'name', 'code', 'cost', 'qty')->get();

        $warehouses = Warehouse::where('is_active', true)->get();
        return view('backend.cafe.index', compact('rawMaterials', 'cashDrawers', 'products', 'warehouses'));
    }

    public function storeRawMaterial(Request $request)
    {
        return DB::transaction(function () use ($request) {
            $request->validate([
                'product_id' => 'required|integer|exists:products,id',
                'warehouse_id' => 'required|integer|exists:warehouses,id',
                'consumed_today' => 'required|numeric|min:0.01',
                'opening_stock' => 'required|numeric',
            ]);

            $product = Product::findOrFail($request->product_id);
            $closing = (float) $request->opening_stock + (float) $request->received_today - (float) $request->consumed_today;

            $logId = DB::table('cafe_raw_materials')->insertGetId([
                'log_date' => $request->log_date ?? now()->toDateString(),
                'product_id' => $product->id,
                'item_name' => $product->name,
                'opening_stock' => $request->opening_stock,
                'received_today' => $request->received_today ?? 0,
                'consumed_today' => $request->consumed_today,
                'closing_stock' => $closing,
                'unit_code' => $request->unit_code ?? 'kg',
                'user_id' => Auth::id() ?? 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            app(InventoryMovementService::class)->issue(new StockMovementCommand(
                date: $request->log_date ?? now()->toDateString(),
                lines: [StockLine::fromArray([
                    'product_id' => $product->id, 'qty' => $request->consumed_today,
                    'variant_id' => $request->variant_id, 'product_batch_id' => $request->product_batch_id,
                    'imei_number' => $request->imei_number,
                ])],
                warehouseId: (int) $request->warehouse_id,
                sourceType: 'legacy:cafe_raw_materials', sourceId: $logId, userId: Auth::id(),
                context: $request->attributes->get(CompanyContext::class),
            ));

            return redirect()->back()->with('message', "Raw material consumption [{$product->name}] logged successfully.");

        });
    }

    public function storeDrawerReconcile(Request $request)
    {
        $request->validate([
            'opening_float' => 'required|numeric',
            'physical_cash_counted' => 'required|numeric',
            'upi_settlement_counted' => 'required|numeric',
        ]);

        $date = $request->drawer_date ?? now()->toDateString();

        // Query today's sales from system
        $systemCash = DB::table('payments')->whereDate('created_at', $date)->where('paying_method', 'Cash')->sum('amount');
        $systemUpi = DB::table('payments')->whereDate('created_at', $date)->whereIn('paying_method', ['UPI', 'Online', 'Card'])->sum('amount');
        $totalSystem = $systemCash + $systemUpi;

        $totalPhysical = (float)$request->physical_cash_counted + (float)$request->upi_settlement_counted - (float)$request->opening_float;
        $discrepancy = $totalPhysical - $totalSystem;

        $status = abs($discrepancy) < 1 ? 'balanced' : ($discrepancy > 0 ? 'over' : 'short');

        DB::table('cafe_cash_drawers')->insert([
            'drawer_date' => $date,
            'cashier_id' => Auth::id() ?? 1,
            'opening_float' => $request->opening_float,
            'system_cash_sales' => $systemCash,
            'system_upi_sales' => $systemUpi,
            'total_system_sales' => $totalSystem,
            'physical_cash_counted' => $request->physical_cash_counted,
            'upi_settlement_counted' => $request->upi_settlement_counted,
            'total_physical_collected' => $totalPhysical,
            'discrepancy_amount' => $discrepancy,
            'status' => $status,
            'notes' => $request->notes,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return redirect()->back()->with('message', "Evening counter cash drawer reconciled: Status is {$status} (Discrepancy: ₹ " . number_format($discrepancy, 2) . ").");
    }

    public function quickPos(Request $request)
    {
        $posController = app(\App\Http\Controllers\Api\V1\PosApiController::class);
        $bootstrapResponse = $posController->bootstrap($request)->getData(true);
        $bootstrap = $bootstrapResponse['data'] ?? [];

        $companyId = (int) ($bootstrap['company_id'] ?? 1);
        $companyModel = \App\Models\Company::find($companyId);
        $companySettings = is_array($companyModel?->settings_json) ? $companyModel->settings_json : [];
        $companyName = $bootstrap['company_name']
            ?? $companyModel?->trade_name
            ?? $companyModel?->legal_name
            ?? 'ERP POS Terminal';
        $upiVpa = $bootstrap['upi_vpa']
            ?? ($companySettings['upi_vpa'] ?? ($companySettings['invoice_print']['upi_vpa'] ?? null));
        $companyGstin = $bootstrap['gstin'] ?? $companyModel?->gstin;

        $categories = Category::where('is_active', true)
            ->where('company_id', $companyId)
            ->orderBy('name')
            ->get();
        $products = Product::where('is_active', true)
            ->where('company_id', $companyId)
            ->orderByDesc('featured')
            ->orderBy('name')
            ->select('id', 'name', 'code', 'price', 'image', 'category_id', 'qty', 'type', 'featured')
            ->get();
        $warehouses = Warehouse::where('is_active', true)
            ->where('company_id', $companyId)
            ->get();

        return view('backend.cafe.quick_pos', compact(
            'categories',
            'products',
            'warehouses',
            'bootstrap',
            'companyName',
            'companyId',
            'upiVpa',
            'companyGstin'
        ));
    }

    public function pos(Request $request)
    {
        return $this->quickPos($request);
    }

    public function posBootstrap(Request $request)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->bootstrap($request);
    }

    public function posOrders(Request $request)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->orders($request);
    }

    public function openShift(Request $request)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->openShift($request);
    }

    public function closeShift(Request $request)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->closeShift($request);
    }

    public function toggleProductAvailability(Request $request, int $id)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->toggleProductAvailability($request, $id);
    }

    public function printOrderJob(Request $request, int $id)
    {
        return app(\App\Http\Controllers\Api\V1\PosApiController::class)->printOrderJob($request, $id);
    }

    public function reconcileDrawer(Request $request)
    {
        return $this->storeDrawerReconcile($request);
    }

    public function storeOrder(Request $request)
    {
        $response = app(\App\Http\Controllers\Api\V1\PosApiController::class)->storeOrder($request);
        if ($request->expectsJson() || $request->ajax() || $request->wantsJson()) {
            return $response;
        }

        $payload = $response->getData(true);
        $ref = $payload['data']['reference_no'] ?? 'POS-ORDER';
        return redirect()->back()->with('message', "POS Order {$ref} processed and posted to ERP ledger successfully.");
    }
}
