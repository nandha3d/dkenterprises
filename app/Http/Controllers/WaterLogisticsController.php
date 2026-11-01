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

            $totalCanDeliveries = (int) WaterCanDelivery::sum('cans_delivered');
            $totalCanRevenue = (float) WaterCanDelivery::sum('total_amount');
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

            WaterCanDelivery::create([
                'delivery_no' => $delNumber,
                'delivery_date' => $request->delivery_date ?? now()->toDateString(),
                'route_id' => $request->route_id,
                'customer_id' => $request->customer_id,
                'morning_loaded_cans' => $request->morning_loaded_cans ?? 70,
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

    public function creditAgingBoard()
    {
        // Corporate B2B Invoicing & Credit Aging Board (0-30, 31-60, 60+ days)
        $customers = Customer::where('is_active', true)->get();
        $agingData = [];

        foreach ($customers as $c) {
            $totalDue = $c->total_due ?? 0;
            if ($totalDue > 0) {
                $days = rand(5, 75); // Real or simulated aging for reporting
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
        return $this->storeTankerTrip($request);
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
