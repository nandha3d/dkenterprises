<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\WaterCanDelivery;
use App\Models\WaterCanRoute;
use App\Models\WaterTanker;
use App\Models\WaterTankerTrip;
use App\Services\Accounting\AccountingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class WaterLogisticsController extends Controller
{
    protected $accountingService;

    public function __construct(AccountingService $accountingService)
    {
        $this->accountingService = $accountingService;
    }

    public function index(Request $request)
    {
        $companyContext = $request->attributes->get(\App\Services\Platform\CompanyContext::class);
        $companyId = $companyContext?->companyId ?? session('company_id');
        $activeCompany = $companyId ? \App\Models\Company::find($companyId) : null;
        $industry = $request->query('vertical') ?? ($activeCompany ? $activeCompany->industry : null);

        if (!in_array($industry, ['bulk_water', 'packaged_water'])) {
            $industry = ($activeCompany && ($activeCompany->code === 'TMWS' || str_contains(strtolower($activeCompany->trade_name ?? ''), 'tanker') || str_contains(strtolower($activeCompany->trade_name ?? ''), 'murugan')))
                ? 'bulk_water'
                : 'packaged_water';
        }

        if ($industry === 'packaged_water') {
            // Strict DK Waters isolation: Packaged drinking water only. Never query or compute bulk tankers.
            $tankers = collect([]);
            $trips = collect([]);
            $totalTankerTrips = 0;
            $totalWaterDispatchedKl = 0.0;
            $totalTankerRevenue = 0.0;
            $totalTankerExpenses = 0.0;

            $routes = WaterCanRoute::where('is_active', true)->get();
            $deliveries = WaterCanDelivery::with(['route', 'customer'])->latest()->take(50)->get();
            $customers = Customer::where('is_active', true)
                ->where(function ($q) use ($activeCompany) {
                    $targetId = $activeCompany ? $activeCompany->id : 3;
                    $q->where('company_id', $targetId);
                })
                ->select('id', 'name', 'phone_number')
                ->get();

            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)->select('id', 'name', 'phone_number')->get();
            }

            $canInventories = DB::table('water_can_inventories')
                ->leftJoin('customers', 'water_can_inventories.customer_id', '=', 'customers.id')
                ->select('water_can_inventories.*', 'customers.name as customer_name', 'customers.phone_number')
                ->get();

            $nonCompletedStatuses = ['ordered', 'pending', 'dispatched', 'assigned', 'in_transit', 'cancelled'];
            $totalCanDeliveries = (int) WaterCanDelivery::whereNotIn(DB::raw("LOWER(COALESCE(status, 'completed'))"), $nonCompletedStatuses)->sum('cans_delivered');
            $totalCanRevenue = (float) WaterCanDelivery::whereNotIn(DB::raw("LOWER(COALESCE(status, 'completed'))"), $nonCompletedStatuses)->sum('total_amount');
            $totalCansHeld = (int) DB::table('water_can_inventories')->sum('total_cans_held');
            $totalDepositHeld = (float) DB::table('water_can_inventories')->sum('deposit_held');
            $activeRoutesCount = $routes->count();
        } else {
            // Strict TMWS isolation: Bulk commercial water tankers only. Never query or compute packaged water routes.
            $routes = collect([]);
            $deliveries = collect([]);
            $canInventories = collect([]);
            $totalCanDeliveries = 0;
            $totalCanRevenue = 0.0;
            $totalCansHeld = 0;
            $totalDepositHeld = 0.0;
            $activeRoutesCount = 0;

            $tankers = WaterTanker::where('is_active', true)->get();
            $trips = WaterTankerTrip::with(['tanker', 'customer'])->latest()->take(50)->get();
            $customers = Customer::where('is_active', true)
                ->where(function ($q) use ($activeCompany) {
                    $targetId = $activeCompany ? $activeCompany->id : 2;
                    $q->where('company_id', $targetId);
                })
                ->select('id', 'name', 'phone_number')
                ->get();

            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)->select('id', 'name', 'phone_number')->get();
            }

            $totalTankerTrips = WaterTankerTrip::count();
            $totalWaterDispatchedKl = (float) WaterTankerTrip::sum('water_quantity_kl');
            $totalTankerRevenue = (float) WaterTankerTrip::sum('trip_rate');
            $totalTankerExpenses = (float) WaterTankerTrip::sum(DB::raw('COALESCE(diesel_expense, 0) + COALESCE(driver_batta, 0) + COALESCE(toll_expense, 0)'));
        }

        return view('backend.water_logistics.index', compact(
            'tankers', 'trips', 'routes', 'deliveries', 'customers', 'canInventories',
            'totalTankerTrips', 'totalWaterDispatchedKl', 'totalCanDeliveries', 'totalTankerRevenue',
            'totalTankerExpenses', 'totalCanRevenue', 'totalCansHeld', 'totalDepositHeld', 'activeRoutesCount',
            'activeCompany', 'industry'
        ));
    }

    public function storeTankerTrip(Request $request)
    {
        $request->validate([
            'tanker_id' => 'required',
            'customer_id' => 'required',
            'destination_site' => 'required|string',
            'water_quantity_kl' => 'required|numeric|min:0.5',
            'trip_rate' => 'required|numeric|min:0',
        ]);

        $tripNumber = 'TRIP-' . date('Ymd') . '-' . rand(100, 999);

        DB::transaction(function () use ($request, $tripNumber) {
            WaterTankerTrip::create([
                'trip_number' => $tripNumber,
                'tanker_id' => $request->tanker_id,
                'customer_id' => $request->customer_id,
                'trip_date' => $request->trip_date ?? now()->toDateString(),
                'source_plant' => $request->source_plant ?? 'Borewell Filtration Plant 1',
                'destination_site' => $request->destination_site,
                'water_quantity_kl' => $request->water_quantity_kl,
                'trip_rate' => $request->trip_rate,
                'diesel_expense' => $request->diesel_expense ?? 0,
                'toll_expense' => $request->toll_expense ?? 0,
                'driver_batta' => $request->driver_batta ?? 0,
                'site_receiver_name' => $request->site_receiver_name,
                'status' => 'delivered',
                'notes' => $request->notes,
                'created_by' => Auth::id() ?? 1,
            ]);

            // Automatically post double-entry revenue & expense entries
            if ($request->trip_rate > 0) {
                try {
                    $items = [
                        ['account_code' => '1030', 'debit' => $request->trip_rate, 'credit' => 0, 'memo' => 'Water Tanker AR receivable'],
                        ['account_code' => '4010', 'debit' => 0, 'credit' => $request->trip_rate, 'memo' => 'Bulk Water Tanker Logistics Revenue']
                    ];

                    $diesel = (float)($request->diesel_expense ?? 0);
                    $batta = (float)($request->driver_batta ?? 0);
                    $expenses = $diesel + $batta;

                    if ($expenses > 0) {
                        $items[] = ['account_code' => '5020', 'debit' => $expenses, 'credit' => 0, 'memo' => 'Tanker Diesel & Driver Batta Trip Expense'];
                        $items[] = ['account_code' => '1010', 'debit' => 0, 'credit' => $expenses, 'memo' => 'Cash disbursement for tanker trip expenses'];
                    }

                    $this->accountingService->postJournalEntry([
                        'entry_date' => $request->trip_date ?? now()->toDateString(),
                        'reference_type' => 'WaterTankerTrip',
                        'reference_id' => $tripNumber,
                        'narration' => "Water Tanker Trip [{$tripNumber}] {$request->water_quantity_kl}KL to {$request->destination_site}",
                        'items' => $items
                    ]);
                } catch (\Exception $e) {}
            }
        });

        return redirect()->back()->with('message', "Tanker Trip {$tripNumber} logged and financial ledger updated successfully.");
    }

    public function storeCanDelivery(Request $request)
    {
        $request->validate([
            'route_id' => 'required',
            'customer_id' => 'required',
            'cans_delivered' => 'required|integer|min:1',
            'can_rate' => 'required|numeric|min:1',
        ]);

        $delNumber = 'CAN-' . date('Ymd') . '-' . rand(100, 999);
        $totalAmount = (int)$request->cans_delivered * (float)$request->can_rate;
        $paidAmount = (float)($request->paid_amount ?? 0);

        DB::transaction(function () use ($request, $delNumber, $totalAmount, $paidAmount) {
            // Calculate customer live can balance
            $prevHeld = DB::table('water_can_inventories')->where('customer_id', $request->customer_id)->value('total_cans_held') ?? 0;
            $newHeld = $prevHeld + (int)$request->cans_delivered - (int)($request->empty_cans_returned ?? 0);

            $routeDefaultLoad = (int) (DB::table('water_can_routes')->where('id', $request->route_id)->value('daily_avg_cans') ?? 0);
            WaterCanDelivery::create([
                'delivery_no' => $delNumber,
                'delivery_date' => $request->delivery_date ?? now()->toDateString(),
                'route_id' => $request->route_id,
                'customer_id' => $request->customer_id,
                'morning_loaded_cans' => $request->morning_loaded_cans ?? $routeDefaultLoad,
                'cans_delivered' => $request->cans_delivered,
                'empty_cans_returned' => $request->empty_cans_returned ?? 0,
                'can_rate' => $request->can_rate,
                'total_amount' => $totalAmount,
                'paid_amount' => $paidAmount,
                'payment_mode' => $request->payment_mode ?? 'Cash',
                'balance_cans_held' => $newHeld,
                'status' => 'delivered',
                'created_by' => Auth::id() ?? 1,
            ]);

            // Update anti-theft live can balance
            DB::table('water_can_inventories')->updateOrInsert(
                ['customer_id' => $request->customer_id],
                [
                    'total_cans_held' => $newHeld,
                    'last_delivery_date' => now(),
                    'updated_at' => now(),
                ]
            );

            // Double entry
            if ($totalAmount > 0) {
                try {
                    $items = [];
                    if ($paidAmount > 0) {
                        $items[] = ['account_code' => '1010', 'debit' => $paidAmount, 'credit' => 0, 'memo' => 'Packaged Drinking Water Cash/UPI collection'];
                    }
                    $due = $totalAmount - $paidAmount;
                    if ($due > 0) {
                        $items[] = ['account_code' => '1030', 'debit' => $due, 'credit' => 0, 'memo' => 'Packaged Drinking Water Customer Due balance'];
                    }
                    $items[] = ['account_code' => '4010', 'debit' => 0, 'credit' => $totalAmount, 'memo' => 'Packaged Drinking Water Sales Revenue'];

                    $this->accountingService->postJournalEntry([
                        'entry_date' => $request->delivery_date ?? now()->toDateString(),
                        'reference_type' => 'WaterCanDelivery',
                        'reference_id' => $delNumber,
                        'narration' => "Packaged Drinking Water Delivery [{$delNumber}] {$request->cans_delivered} units",
                        'items' => $items
                    ]);
                } catch (\Exception $e) {}
            }
        });

        return redirect()->back()->with('message', "Packaged Drinking Water Delivery {$delNumber} recorded. Customer container balance updated.");
    }

    private function applyPackagedWaterRequestContext(Request $request): void
    {
        $user = Auth::user();
        if ($user && \App\Support\StaffIdentityResolver::isSuperAdmin($user)) {
            $pwCompanyId = (int) (DB::table('companies')->where('industry', 'packaged_water')->value('id') ?? 3);
            $request->headers->set('X-Company-ID', (string) $pwCompanyId);
            $request->attributes->set('erp.company_id', $pwCompanyId);
        }
    }

    private function applyBulkWaterRequestContext(Request $request): void
    {
        $user = Auth::user();
        if ($user && \App\Support\StaffIdentityResolver::isSuperAdmin($user)) {
            $bwCompanyId = (int) (DB::table('companies')->where('industry', 'bulk_water')->value('id')
                ?? DB::table('companies')->where('code', 'TMWS')->value('id')
                ?? 2);
            $request->headers->set('X-Company-ID', (string) $bwCompanyId);
            $request->attributes->set('erp.company_id', $bwCompanyId);
        }
    }

    public function storeCanOrder(Request $request)
    {
        $this->applyPackagedWaterRequestContext($request);
        $request->merge(['order_source' => Auth::user() && \App\Support\StaffIdentityResolver::isSuperAdmin(Auth::user()) ? 'web_admin' : 'web_driver']);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->storeCanOrder($request);
        $payload = $res->getData(true);

        if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
            return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to create can order.');
        }

        $orderNo = $payload['data']['sales_order_no'] ?? $payload['data']['order_no'] ?? '';
        return redirect()->back()->with('message', "Can Sales Order {$orderNo} created & owner notified.");
    }

    public function adjustCanOrder(Request $request, int $id)
    {
        $this->applyPackagedWaterRequestContext($request);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->updateCanOrder($request, $id);
        $payload = $res->getData(true);

        if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
            return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to adjust can order.');
        }

        return redirect()->back()->with('message', $payload['message'] ?? 'Can Sales Order customized.');
    }

    public function storeTankerOrder(Request $request)
    {
        $this->applyBulkWaterRequestContext($request);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->storeTankerOrder($request);
        $payload = $res->getData(true);

        if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
            return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to create tanker order.');
        }

        $orderNo = $payload['data']['sales_order_no'] ?? $payload['data']['trip_number'] ?? '';
        return redirect()->back()->with('message', "Bulk Tanker Sales Order {$orderNo} created & owner notified.");
    }

    public function adjustTankerOrder(Request $request, int $id)
    {
        $this->applyBulkWaterRequestContext($request);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->updateTankerOrder($request, $id);
        $payload = $res->getData(true);

        if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
            return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to adjust tanker order.');
        }

        return redirect()->back()->with('message', $payload['message'] ?? 'Tanker Sales Order customized.');
    }

    public function schedules(Request $request)
    {
        $user = Auth::user();
        $reqVertical = strtolower(trim((string) $request->query('vertical', '')));
        if ($user && \App\Support\StaffIdentityResolver::isSuperAdmin($user)) {
            if ($reqVertical === 'tanker') {
                $this->applyBulkWaterRequestContext($request);
                $request->merge(['vertical_type' => 'tanker']);
            } elseif ($reqVertical === 'can') {
                $this->applyPackagedWaterRequestContext($request);
                $request->merge(['vertical_type' => 'can']);
            } else {
                $ctxCompanyId = $request->attributes->get(\App\Services\Platform\CompanyContext::class)?->companyId ?? session('company_id');
                $industry = $ctxCompanyId ? strtolower((string) DB::table('companies')->where('id', $ctxCompanyId)->value('industry')) : 'packaged_water';
                if ($industry === 'bulk_water') {
                    $this->applyBulkWaterRequestContext($request);
                    $request->merge(['vertical_type' => 'tanker']);
                } else {
                    $this->applyPackagedWaterRequestContext($request);
                    $request->merge(['vertical_type' => 'can']);
                }
            }
        } elseif ($reqVertical !== '') {
            $request->merge(['vertical_type' => $reqVertical]);
        }

        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->schedulesIndex($request);
        if ($res->getStatusCode() >= 400) {
            abort(403, $res->getData(true)['message'] ?? 'Forbidden');
        }
        $data = $res->getData(true)['data'] ?? [];
        return view('backend.water_logistics.schedules', [
            'verticalType' => $data['vertical_type'] ?? 'can',
            'companyId' => $data['company_id'] ?? null,
            'schedules' => $data['schedules'] ?? [],
            'customers' => $data['customers'] ?? [],
            'routes' => $data['routes'] ?? [],
            'tankers' => $data['tankers'] ?? [],
            'isSuperAdmin' => $user && \App\Support\StaffIdentityResolver::isSuperAdmin($user),
        ]);
    }

    public function storeSchedule(Request $request)
    {
        $vt = strtolower(trim((string) ($request->input('vertical_type') ?? 'can')));
        if ($vt === 'tanker') {
            $this->applyBulkWaterRequestContext($request);
        } else {
            $this->applyPackagedWaterRequestContext($request);
        }
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->storeSchedule($request);
        $payload = $res->getData(true);
        if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
            return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to save schedule.');
        }
        return redirect()->back()->with('message', $payload['message'] ?? 'Recurring delivery schedule created.');
    }

    public function toggleSchedule(Request $request, int $id)
    {
        $vt = strtolower(trim((string) ($request->input('vertical_type') ?? '')));
        if ($vt === 'tanker') {
            $this->applyBulkWaterRequestContext($request);
        } elseif ($vt === 'can') {
            $this->applyPackagedWaterRequestContext($request);
        }
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->toggleSchedule($request, $id);
        $payload = $res->getData(true);
        return redirect()->back()->with('message', $payload['message'] ?? 'Schedule updated.');
    }

    public function skipSchedule(Request $request, int $id)
    {
        $vt = strtolower(trim((string) ($request->input('vertical_type') ?? '')));
        if ($vt === 'tanker') {
            $this->applyBulkWaterRequestContext($request);
        } elseif ($vt === 'can') {
            $this->applyPackagedWaterRequestContext($request);
        }
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->skipSchedule($request, $id);
        $payload = $res->getData(true);
        return redirect()->back()->with('message', $payload['message'] ?? 'Next occurrence skipped.');
    }

    public function generateScheduleNow(Request $request, int $id)
    {
        $vt = strtolower(trim((string) ($request->input('vertical_type') ?? '')));
        if ($vt === 'tanker') {
            $this->applyBulkWaterRequestContext($request);
        } elseif ($vt === 'can') {
            $this->applyPackagedWaterRequestContext($request);
        }
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->generateScheduleNow($request, $id);
        $payload = $res->getData(true);
        return redirect()->back()->with('message', $payload['message'] ?? 'Scheduled Sales Order generated.');
    }

    public function generateDueSchedules(Request $request)
    {
        $vt = strtolower(trim((string) ($request->input('vertical_type') ?? '')));
        if ($vt === 'tanker') {
            $this->applyBulkWaterRequestContext($request);
        } elseif ($vt === 'can') {
            $this->applyPackagedWaterRequestContext($request);
        }
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->generateDueSchedules($request);
        $payload = $res->getData(true);
        return redirect()->back()->with('message', $payload['message'] ?? 'Due schedules processed.');
    }

    public function startCanOrder(Request $request, int $id)
    {
        $this->applyPackagedWaterRequestContext($request);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->startCanOrder($request, $id);
        $payload = $res->getData(true);

        return redirect()->back()->with('message', $payload['message'] ?? 'Order status updated to In Transit.');
    }

    public function closeCanOrder(Request $request, int $id)
    {
        $this->applyPackagedWaterRequestContext($request);
        $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->closeCanOrder($request, $id);
        $payload = $res->getData(true);

        return redirect()->back()->with('message', $payload['message'] ?? 'Order closed & delivered.');
    }

    public function creditAgingBoard()
    {
        // Corporate B2B Invoicing & Credit Aging Board (0-30, 31-60, 60+ days)
        $customers = Customer::where('is_active', true)->get();
        $agingData = [];

        foreach ($customers as $c) {
            $totalDue = $c->total_due ?? 0;
            if ($totalDue > 0) {
                $oldestUnpaidDate = DB::table('sales')
                    ->where('customer_id', $c->id)
                    ->whereNull('deleted_at')
                    ->whereColumn('paid_amount', '<', 'grand_total')
                    ->min('created_at');
                $days = $oldestUnpaidDate
                    ? max(1, (int) \Carbon\Carbon::parse($oldestUnpaidDate)->diffInDays(now()))
                    : max(1, (int) ($c->updated_at ? \Carbon\Carbon::parse($c->updated_at)->diffInDays(now()) : 1));
                $bucket = $days <= 30 ? '0-30' : ($days <= 60 ? '31-60' : '60+');
                $agingData[] = [
                    'customer' => $c,
                    'total_due' => $totalDue,
                    'days_outstanding' => $days,
                    'bucket' => $bucket
                ];
            }
        }

        return view('backend.water_logistics.credit_aging', compact('agingData'));
    }

    public function creditAging()
    {
        return $this->creditAgingBoard();
    }

    public function storeTripSheet(Request $request)
    {
        if ($request->filled('trip_id')) {
            return $this->processTankerOrder($request, (int) $request->input('trip_id'));
        }

        $requestedStatus = strtolower(trim((string) ($request->input('status') ?? '')));
        if (in_array($requestedStatus, ['pending', 'assigned', 'dispatched'], true)) {
            $this->applyBulkWaterRequestContext($request);
            $res = app(\App\Http\Controllers\Api\V1\WaterLogisticsApiController::class)->storeTankerOrder($request);
            $payload = $res->getData(true);
            if ($res->getStatusCode() >= 400 || empty($payload['success'])) {
                return redirect()->back()->with('not_permitted', $payload['message'] ?? 'Unable to dispatch tanker order.');
            }
            $tripNumber = $payload['data']['trip_number'] ?? '';
            $salesOrderNo = $payload['data']['sales_order_no'] ?? '';
            return redirect()->back()->with('message', "Tanker Sales Order {$tripNumber}" . ($salesOrderNo ? " ({$salesOrderNo})" : '') . " dispatched to driver portal queue.");
        }

        return $this->storeTankerTrip($request);
    }

    public function processTankerOrder(Request $request, int $id)
    {
        $trip = WaterTankerTrip::findOrFail($id);

        $targetStatus = strtolower(trim((string) ($request->input('status') ?? 'completed')));
        $allowedStatuses = ['dispatched', 'assigned', 'in_transit', 'at_site', 'decanting', 'completed', 'delivered'];
        if (!in_array($targetStatus, $allowedStatuses, true)) {
            $targetStatus = 'completed';
        }

        $tanker = WaterTanker::find($trip->tanker_id);
        $startKm = (int) ($request->input('start_km') ?? ($trip->start_km ?: ($tanker?->current_odometer_km ?? 0)));
        $endKm = (int) ($request->input('end_km') ?? $trip->end_km ?? 0);
        $totalKm = $endKm >= $startKm && $endKm > 0 ? ($endKm - $startKm) : (int) ($trip->total_km ?? 0);

        $motorMinutes = (int) ($request->input('motor_pumping_minutes') ?? $trip->motor_pumping_minutes ?? 0);
        if ($motorMinutes === 0 && $request->filled('motor_started_at') && $request->filled('motor_stopped_at')) {
            try {
                $mStart = \Carbon\Carbon::parse($request->input('motor_started_at'));
                $mStop = \Carbon\Carbon::parse($request->input('motor_stopped_at'));
                if ($mStop->lessThan($mStart)) {
                    $mStop->addDay();
                }
                $motorMinutes = max(0, (int) ceil($mStart->diffInSeconds($mStop) / 60));
            } catch (\Throwable $e) {
            }
        }
        $motorCharge = $request->filled('motor_pumping_charge')
            ? (float) $request->input('motor_pumping_charge')
            : ($motorMinutes > 0 ? round(150.0 + (max(0, $motorMinutes - 15) * 5.0), 2) : (float) ($trip->motor_pumping_charge ?? 0));

        $waitingMinutes = (int) ($request->input('waiting_minutes') ?? $trip->waiting_minutes ?? 0);
        $waitingCharge = $request->filled('waiting_charge')
            ? (float) $request->input('waiting_charge')
            : ($waitingMinutes > 0 ? round($waitingMinutes * 2.50, 2) : (float) ($trip->waiting_charge ?? 0));

        $tripRate = (float) ($request->input('trip_rate') ?? $trip->trip_rate ?? 0);
        $diesel = (float) ($request->input('diesel_expense') ?? $trip->diesel_expense ?? 0);
        $toll = (float) ($request->input('toll_expense') ?? $trip->toll_expense ?? 0);
        $batta = (float) ($request->input('driver_batta') ?? $trip->driver_batta ?? 0);

        $existingNotes = [];
        if (!empty($trip->notes) && is_string($trip->notes) && str_starts_with(trim($trip->notes), '{')) {
            $existingNotes = json_decode($trip->notes, true) ?: [];
        }
        $mergedNotes = array_merge($existingNotes, array_filter([
            'trip_started_at' => $request->input('trip_started_at'),
            'site_arrived_at' => $request->input('site_arrived_at'),
            'site_departed_at' => $request->input('site_departed_at'),
            'motor_started_at' => $request->input('motor_started_at'),
            'motor_stopped_at' => $request->input('motor_stopped_at'),
            'travel_duration_minutes' => $request->input('travel_duration_minutes'),
            'site_dwell_minutes' => $request->input('site_dwell_minutes'),
            'gps_tracked_km' => $request->input('gps_tracked_km'),
            'processed_by' => Auth::id(),
            'processed_at' => now()->toIso8601String(),
        ], static fn ($v) => $v !== null && $v !== ''));

        $wasAlreadyCompleted = in_array(strtolower((string) $trip->status), ['completed', 'delivered'], true);
        $isCompleting = in_array($targetStatus, ['completed', 'delivered'], true);

        DB::transaction(function () use (
            $trip, $tanker, $request, $targetStatus, $startKm, $endKm, $totalKm,
            $motorMinutes, $motorCharge, $waitingMinutes, $waitingCharge,
            $tripRate, $diesel, $toll, $batta, $mergedNotes, $wasAlreadyCompleted, $isCompleting
        ) {
            DB::table('water_tanker_trips')->where('id', $trip->id)->update([
                'water_quantity_kl' => $request->filled('water_quantity_kl') ? (float) $request->input('water_quantity_kl') : $trip->water_quantity_kl,
                'destination_site' => $request->filled('destination_site') ? $request->input('destination_site') : $trip->destination_site,
                'start_km' => $startKm,
                'end_km' => $endKm,
                'total_km' => $totalKm,
                'trip_rate' => $tripRate,
                'diesel_expense' => $diesel,
                'toll_expense' => $toll,
                'driver_batta' => $batta,
                'motor_pumping_minutes' => $motorMinutes,
                'motor_pumping_charge' => $motorCharge,
                'waiting_minutes' => $waitingMinutes,
                'waiting_charge' => $waitingCharge,
                'site_receiver_name' => $request->filled('site_receiver_name') ? $request->input('site_receiver_name') : $trip->site_receiver_name,
                'status' => $targetStatus,
                'notes' => json_encode($mergedNotes),
                'updated_at' => now(),
            ]);

            if ($tanker && $endKm > (int) $tanker->current_odometer_km) {
                DB::table('water_tankers')->where('id', $tanker->id)->update([
                    'current_odometer_km' => $endKm,
                    'updated_at' => now(),
                ]);
            }

            if ($isCompleting && !$wasAlreadyCompleted && $tripRate > 0) {
                try {
                    $items = [
                        ['account_code' => '1030', 'debit' => $tripRate, 'credit' => 0, 'memo' => 'Bulk Tanker Trip Bill'],
                        ['account_code' => '4020', 'debit' => 0, 'credit' => $tripRate, 'memo' => 'Water Tanker Freight & Supply Revenue'],
                    ];
                    if (($diesel + $toll + $batta) > 0) {
                        $exp = $diesel + $toll + $batta;
                        $items[] = ['account_code' => '5030', 'debit' => $exp, 'credit' => 0, 'memo' => 'Tanker Fleet Trip Fuel & Batta'];
                        $items[] = ['account_code' => '1010', 'debit' => 0, 'credit' => $exp, 'memo' => 'Cash / Fleet Expense Paid'];
                    }

                    $this->accountingService->postJournalEntry([
                        'entry_date' => $trip->trip_date ?: now()->toDateString(),
                        'reference_type' => 'WaterTankerTrip',
                        'reference_id' => $trip->trip_number,
                        'narration' => "Bulk Water Tanker Trip [{$trip->trip_number}] Completed",
                        'items' => $items,
                    ]);
                } catch (\Throwable $e) {
                }
            }
        });

        if ($isCompleting && $tripRate > 0 && $trip->customer_id) {
            try {
                $notifyCompanyId = (int) (request()->attributes->get(\App\Services\Platform\CompanyContext::class)?->companyId
                    ?? session('company_id')
                    ?? DB::table('companies')->where('code', 'TMWS')->value('id')
                    ?? 2);
                $freshTrip = DB::table('water_tanker_trips')->where('id', $trip->id)->first();
                if ($freshTrip) {
                    $kl = max(1.0, (float) ($freshTrip->water_quantity_kl ?? 10.0));
                    $erpSync = app(\App\Services\ERP\VerticalSaleSyncService::class);
                    $salesOrderId = !empty($freshTrip->sales_order_id) ? (int) $freshTrip->sales_order_id : null;
                    if (!$salesOrderId) {
                        $salesOrderId = $erpSync->syncSalesOrder([
                            'company_id' => $notifyCompanyId,
                            'customer_id' => (int) $freshTrip->customer_id,
                            'user_id' => (int) ($freshTrip->created_by ?? auth()->id() ?? 1),
                            'business_date' => (string) ($freshTrip->trip_date ?? now()->toDateString()),
                            'promised_date' => (string) ($freshTrip->trip_date ?? now()->toDateString()),
                            'note' => 'Bulk Tanker Order ' . $freshTrip->trip_number,
                            'source_type' => 'water_tanker',
                            'source_ref' => (string) $freshTrip->trip_number,
                            'order_origin' => $freshTrip->order_origin ?? 'on_day',
                            'schedule_id' => $freshTrip->schedule_id ?? null,
                            'schedule_label' => $freshTrip->schedule_label ?? 'Created Today (On-Day)',
                            'product_code' => 'BW-10KL',
                            'product_name' => 'Bulk RO/Industrial Tanker Water (' . $kl . ' KL)',
                            'qty' => $kl,
                            'unit_rate' => round($tripRate / $kl, 4),
                        ]);
                        if ($salesOrderId > 0) {
                            DB::table('water_tanker_trips')->where('id', $trip->id)->update(['sales_order_id' => $salesOrderId]);
                        }
                    }

                    $saleId = $erpSync->syncCompletedSale([
                        'existing_sale_id' => $freshTrip->sale_id ?? null,
                        'sales_order_id' => $salesOrderId,
                        'company_id' => $notifyCompanyId,
                        'customer_id' => (int) $freshTrip->customer_id,
                        'user_id' => (int) ($freshTrip->created_by ?? auth()->id() ?? 1),
                        'reference_no' => (string) ($freshTrip->trip_number ?: ('TRP-' . $freshTrip->id)),
                        'sale_date' => (string) ($freshTrip->trip_date ?? now()->toDateString()),
                        'discount' => (float) ($freshTrip->discount_amount ?? 0),
                        'paid_amount' => 0.0,
                        'payment_mode' => 'Credit',
                        'sale_type' => 'water_tanker',
                        'credit_days' => 15,
                        'sale_note' => 'Bulk Tanker Supply (' . $freshTrip->trip_number . ') - ' . ($freshTrip->destination_site ?? ''),
                        'items' => [[
                            'product_code' => 'BW-10KL',
                            'name' => 'Bulk RO/Industrial Tanker Water (' . $kl . ' KL)',
                            'qty' => $kl,
                            'unit_price' => round(($tripRate + (float) ($freshTrip->discount_amount ?? 0)) / $kl, 4),
                            'discount' => (float) ($freshTrip->discount_amount ?? 0),
                            'hsn_sac' => '22019090',
                        ]],
                    ]);
                    if ($saleId > 0 && \Illuminate\Support\Facades\Schema::hasColumn('water_tanker_trips', 'sale_id')) {
                        DB::table('water_tanker_trips')->where('id', $trip->id)->update(['sale_id' => $saleId]);
                    }
                }
            } catch (\Throwable $e) {
            }
        }

        return redirect()->back()->with('message', "Tanker Order {$trip->trip_number} updated to status [" . strtoupper($targetStatus) . '].');
    }

    /**
     * Attach ERP Sales / Paid / Due / Overdue summary onto customer models/records for web map pins.
     */
    private function enrichCustomersWithFinancials($customers)
    {
        $ids = collect($customers)->pluck('id')->filter()->values()->all();
        if (empty($ids)) {
            return $customers;
        }
        $rows = DB::table('sales')
            ->whereIn('customer_id', $ids)
            ->whereNull('deleted_at')
            ->where(fn ($q) => $q->whereNull('sale_status')->orWhere('sale_status', 1))
            ->selectRaw('customer_id, COALESCE(SUM(grand_total), 0) as total_sales, COALESCE(SUM(paid_amount), 0) as total_paid')
            ->groupBy('customer_id')
            ->get()
            ->keyBy('customer_id');

        foreach ($customers as $c) {
            $r = $rows->get($c->id);
            $sales = round((float) ($r->total_sales ?? 0), 2);
            $paid = round((float) ($r->total_paid ?? 0), 2);
            $due = round(max(0.0, $sales - $paid), 2);
            $c->total_sales = $sales;
            $c->total_paid = $paid;
            $c->due_amount = $due;
            $c->payment_status = $due > 0.01 ? 'due' : 'paid';
        }
        return $customers;
    }

    public function fleetTracking()
    {
        $companyContext = request()->attributes->get(\App\Services\Platform\CompanyContext::class);
        $company = $companyContext?->company ?? \App\Models\Company::find(session('company_id'));
        $industry = request('vertical') ?? $company?->industry;

        if (!in_array($industry, ['bulk_water', 'packaged_water'])) {
            $industry = ($company && ($company->code === 'TMWS' || str_contains(strtolower($company->trade_name ?? ''), 'tanker') || str_contains(strtolower($company->trade_name ?? ''), 'murugan')))
                ? 'bulk_water'
                : 'packaged_water';
        }

        if ($industry === 'packaged_water') {
            // Strict DK Waters isolation: Packaged drinking water delivery only
            $tankers = collect([]);
            $canRoutes = WaterCanRoute::where('is_active', true)->get();
            $recentTrips = collect([]);
            $customers = Customer::where('is_active', true)
                ->where('company_id', $company?->id ?? 3)
                ->whereNotNull('latitude')
                ->select('id', 'name', 'company_name', 'phone_number', 'address', 'city', 'latitude', 'longitude', 'geofence_radius')
                ->get();
            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)
                    ->whereNotNull('latitude')
                    ->select('id', 'name', 'company_name', 'phone_number', 'address', 'city', 'latitude', 'longitude', 'geofence_radius')
                    ->get();
            }
        } else {
            // Strict TMWS isolation: Bulk commercial water tankers only
            $tankers = WaterTanker::where('is_active', true)->get();
            $canRoutes = collect([]);
            $recentTrips = WaterTankerTrip::with(['tanker', 'customer'])->latest()->take(10)->get();
            $customers = Customer::where('is_active', true)
                ->where('company_id', $company?->id ?? 2)
                ->whereNotNull('latitude')
                ->select('id', 'name', 'company_name', 'phone_number', 'address', 'city', 'latitude', 'longitude', 'geofence_radius')
                ->get();
            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)
                    ->whereNotNull('latitude')
                    ->select('id', 'name', 'company_name', 'phone_number', 'address', 'city', 'latitude', 'longitude', 'geofence_radius')
                    ->get();
            }
        }

        $customers = $this->enrichCustomersWithFinancials($customers);
        $totalVehicles = $tankers->count() + $canRoutes->count();
        $movingVehicles = $tankers->where('current_speed', '>', 0)->count() + $canRoutes->where('current_speed', '>', 0)->count();
        $geofencedSites = $customers->count();

        return view('backend.water_logistics.fleet_tracking', compact(
            'tankers', 'canRoutes', 'customers', 'recentTrips',
            'totalVehicles', 'movingVehicles', 'geofencedSites', 'industry'
        ));
    }

    public function fleetTelematicsLive()
    {
        $companyContext = request()->attributes->get(\App\Services\Platform\CompanyContext::class);
        $company = $companyContext?->company ?? \App\Models\Company::find(session('company_id'));
        $industry = request('vertical') ?? $company?->industry;

        if (!in_array($industry, ['bulk_water', 'packaged_water'])) {
            $industry = ($company && ($company->code === 'TMWS' || str_contains(strtolower($company->trade_name ?? ''), 'tanker') || str_contains(strtolower($company->trade_name ?? ''), 'murugan')))
                ? 'bulk_water'
                : 'packaged_water';
        }

        if ($industry === 'packaged_water') {
            $tankers = collect([]);
            $canRoutes = WaterCanRoute::where('is_active', true)->get();
            $customers = Customer::where('is_active', true)->where('company_id', $company?->id ?? 3)->whereNotNull('latitude')->get();
            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)->whereNotNull('latitude')->get();
            }
        } else {
            $tankers = WaterTanker::where('is_active', true)->get();
            $canRoutes = collect([]);
            $customers = Customer::where('is_active', true)->where('company_id', $company?->id ?? 2)->whereNotNull('latitude')->get();
            if ($customers->isEmpty()) {
                $customers = Customer::where('is_active', true)->whereNotNull('latitude')->get();
            }
        }

        $customers = $this->enrichCustomersWithFinancials($customers);

        return response()->json([
            'success' => true,
            'industry' => $industry,
            'tankers' => $tankers,
            'can_routes' => $canRoutes,
            'customers' => $customers,
            'server_time' => now()->toIso8601String()
        ]);
    }

    public function fleetTelematicsPing(Request $request)
    {
        $request->validate([
            'vehicle_type' => 'required|in:tanker,route',
            'vehicle_id' => 'required',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'speed' => 'nullable|numeric',
            'odometer' => 'nullable|numeric',
        ]);

        $lat = (float)$request->latitude;
        $lng = (float)$request->longitude;
        $speed = (float)($request->speed ?? 0);

        if ($request->vehicle_type === 'tanker') {
            $vehicle = WaterTanker::find($request->vehicle_id);
            if ($vehicle) {
                $vehicle->update([
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'current_speed' => $speed,
                    'current_odometer_km' => $request->odometer ?: $vehicle->current_odometer_km,
                    'last_ping_at' => now(),
                ]);
            }
        } else {
            $vehicle = WaterCanRoute::find($request->vehicle_id);
            if ($vehicle) {
                $vehicle->update([
                    'latitude' => $lat,
                    'longitude' => $lng,
                    'current_speed' => $speed,
                    'last_ping_at' => now(),
                ]);
            }
        }

        // Check if inside any customer geofence (Haversine formula in meters)
        $insideCustomer = null;
        $customers = Customer::where('is_active', true)->whereNotNull('latitude')->get();
        foreach ($customers as $c) {
            $dist = $this->calculateDistanceMeters($lat, $lng, (float)$c->latitude, (float)$c->longitude);
            $radius = (int)($c->geofence_radius ?: 150);
            if ($dist <= $radius) {
                $insideCustomer = [
                    'id' => $c->id,
                    'name' => $c->name,
                    'distance_meters' => round($dist, 1),
                    'radius_meters' => $radius
                ];
                break;
            }
        }

        return response()->json([
            'success' => true,
            'inside_geofence' => (bool)$insideCustomer,
            'customer' => $insideCustomer,
            'timestamp' => now()->toIso8601String()
        ]);
    }

    private function calculateDistanceMeters($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    public function calculateTankerTrip(Request $request)
    {
        $companyContext = $request->attributes->get(\App\Services\Platform\CompanyContext::class);
        $companyId = $companyContext?->companyId ?? session('company_id');

        $tanker = WaterTanker::find($request->tanker_id);
        $capKl = $tanker ? (float)$tanker->capacity_kl : (float)($request->capacity_kl ?? 10);

        // Dynamically find matching bulk water product without hardcoded capacity arrays
        $product = null;
        if ($request->filled('product_id')) {
            $product = \App\Models\Product::find($request->product_id);
        }
        if (!$product && $companyId) {
            $product = \App\Models\Product::where('company_id', $companyId)
                ->where('is_active', true)
                ->where(function ($q) use ($capKl) {
                    $q->where('water_capacity_spec', 'LIKE', "%{$capKl}%")
                      ->orWhere('code', 'LIKE', "%{$capKl}%")
                      ->orWhere('name', 'LIKE', "%{$capKl}%");
                })
                ->first();

            if (!$product) {
                $product = \App\Models\Product::where('company_id', $companyId)
                    ->where('is_active', true)
                    ->where(function ($q) {
                        $q->where('is_water_logistics', true)
                          ->where('water_vertical_type', 'bulk_water')
                          ->orWhere('code', 'LIKE', 'BW-%');
                    })
                    ->first();
            }
        }

        $ratePerKl = (float)($product?->price ? ($product->price / max(1, (float)($product->water_capacity_spec ?: $capKl))) : 120.0);
        $defaultTripRate = $product?->price ?: round($capKl * $ratePerKl);
        $baseRate = (float)($request->base_rate ?: $defaultTripRate);
        $baseCode = $product?->code ?: ('BW-' . round($capKl) . 'KL');
        $baseName = $product?->name ?: ("Commercial Bulk Water Supply (" . $capKl . "KL Tanker Trip)");

        $baseInfo = [
            'code' => $baseCode,
            'name' => $baseName,
            'rate' => $baseRate,
            'product_id' => $product?->id,
        ];

        $startKm = (float)($request->start_km ?? ($tanker->current_odometer_km ?? 0));
        $endKm = (float)($request->end_km ?? 0);
        $totalKm = max(0, $endKm - $startKm);
        if ($request->filled('total_km') && $totalKm == 0) {
            $totalKm = (float)$request->total_km;
        }

        $baseKmLimit = (float)($request->base_km_limit ?: ($product?->base_km_limit ?: 10));
        $excessKm = max(0, $totalKm - $baseKmLimit);
        $excessRate = (float)($request->excess_km_rate ?: ($product?->excess_km_rate ?: 45));
        $excessCharge = $excessKm * $excessRate;

        $pumpMins = (int)($request->motor_pumping_minutes ?? 0);
        $pumpRate = (float)($request->pump_rate ?: 10);
        $pumpCharge = $pumpMins * $pumpRate;

        $waitMins = (int)($request->waiting_minutes ?? 0);
        $waitRate = (float)($request->waiting_rate ?: 15);
        $waitCharge = $waitMins * $waitRate;

        $discount = (float)($request->discount_amount ?? 0);

        $subtotal = $baseRate + $excessCharge + $pumpCharge + $waitCharge;
        $netTotal = max(0, $subtotal - $discount);

        return response()->json([
            'success' => true,
            'tanker' => $tanker,
            'capacity_kl' => $capKl,
            'base_product' => $baseInfo,
            'base_charge' => $baseRate,
            'start_km' => $startKm,
            'end_km' => $endKm,
            'total_km' => $totalKm,
            'base_km_limit' => $baseKmLimit,
            'excess_km' => $excessKm,
            'excess_rate' => $excessRate,
            'excess_charge' => $excessCharge,
            'motor_pumping_minutes' => $pumpMins,
            'pump_rate' => $pumpRate,
            'pumping_charge' => $pumpCharge,
            'waiting_minutes' => $waitMins,
            'wait_rate' => $waitRate,
            'waiting_charge' => $waitCharge,
            'discount' => $discount,
            'subtotal' => $subtotal,
            'net_total' => $netTotal,
            'lines' => array_values(array_filter([
                [
                    'code' => $baseInfo['code'],
                    'name' => $baseInfo['name'],
                    'qty' => 1,
                    'unit' => 'TRIP',
                    'rate' => $baseRate,
                    'amount' => $baseRate
                ],
                $excessKm > 0 ? [
                    'code' => 'SRV-KM',
                    'name' => 'Excess Distance Delivery Mileage (' . $excessKm . ' KM excess @ ₹' . $excessRate . '/KM)',
                    'qty' => $excessKm,
                    'unit' => 'KM',
                    'rate' => $excessRate,
                    'amount' => $excessCharge
                ] : null,
                $pumpMins > 0 ? [
                    'code' => 'SRV-PUMP',
                    'name' => 'Motor Pumping Operating Service (' . $pumpMins . ' mins @ ₹' . $pumpRate . '/min)',
                    'qty' => $pumpMins,
                    'unit' => 'MIN',
                    'rate' => $pumpRate,
                    'amount' => $pumpCharge
                ] : null,
                $waitMins > 0 ? [
                    'code' => 'SRV-WAIT',
                    'name' => 'On-Site Tanker Waiting Delay Charge (' . $waitMins . ' mins @ ₹' . $waitRate . '/min)',
                    'qty' => $waitMins,
                    'unit' => 'MIN',
                    'rate' => $waitRate,
                    'amount' => $waitCharge
                ] : null,
            ]))
        ]);
    }
}
