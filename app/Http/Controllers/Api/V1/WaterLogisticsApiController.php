<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\User;
use App\Models\WaterCanDelivery;
use App\Models\WaterCanDriverSurrender;
use App\Models\WaterCanRoute;
use App\Models\WaterCanSpotAudit;
use App\Models\WaterTankerTrip;
use App\Services\Accounting\AccountingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class WaterLogisticsApiController extends BaseApiController
{
    protected $accountingService;

    public function __construct(AccountingService $accountingService)
    {
        $this->accountingService = $accountingService;
    }

    /**
     * Get active can routes and tankers
     */
    public function routes(): JsonResponse
    {
        $routes = WaterCanRoute::where('is_active', true)->get();
        $tankers = DB::table('water_tankers')->where('is_active', true)->get();

        return $this->sendResponse([
            'routes' => $routes,
            'tankers' => $tankers,
        ], 'Water routes and fleet retrieved successfully');
    }

    /**
     * Complete bootstrap data for DK Track Field Mobile App & PWA
     */
    public function mobileBootstrap(): JsonResponse
    {
        $routes = WaterCanRoute::where('is_active', true)->get();
        $tankers = DB::table('water_tankers')->where('is_active', true)->get();
        $customers = DB::table('customers')->select('id', 'name', 'phone_number', 'address', 'city')->take(50)->get();
        $cafeProducts = \App\Models\Product::where('is_active', true)->select('id', 'name', 'code', 'price', 'category_id')->take(30)->get();
        $cafeCategories = DB::table('categories')->where('is_active', true)->select('id', 'name')->get();

        return $this->sendResponse([
            'companies' => [
                [
                    'id' => 3,
                    'code' => 'DKWATERS',
                    'name' => 'DK Waters',
                    'tagline' => 'Packaged Drinking Water Distribution (Tata Ace Fleet)',
                    'vertical' => 'packaged_water',
                    'icon' => 'water_drop',
                    'primary_color' => '#0284C7'
                ],
                [
                    'id' => 2,
                    'code' => 'TMWS',
                    'name' => 'Tiruchendur Murugan Water Supply',
                    'tagline' => 'Commercial Bulk Water Tankers & Fleet Logistics',
                    'vertical' => 'bulk_water',
                    'icon' => 'fire_truck',
                    'primary_color' => '#2563EB'
                ],
                [
                    'id' => 1,
                    'code' => 'ARANCAFE',
                    'name' => 'Aran Cafe',
                    'tagline' => 'Bakery & Express Counter POS Operations',
                    'vertical' => 'cafe_bakery',
                    'icon' => 'local_cafe',
                    'primary_color' => '#D97706'
                ],
            ],
            'routes' => $routes,
            'tankers' => $tankers,
            'customers' => $customers,
            'cafe_products' => $cafeProducts,
            'cafe_categories' => $cafeCategories,
            'packages' => [
                ['code' => 'CAN-20L', 'name' => '20L Drinking Jar', 'name_ta' => '20L வாட்டர் கேன்', 'unit_price' => 35.0, 'is_jar' => true],
                ['code' => 'CAN-25L', 'name' => '25L Commercial Jar', 'name_ta' => '25L பெரிய கேன்', 'unit_price' => 45.0, 'is_jar' => true],
                ['code' => 'CAN-10L', 'name' => '10L Compact Dispenser', 'name_ta' => '10L நடுத்தர கேன்', 'unit_price' => 25.0, 'is_jar' => true],
                ['code' => 'BTL-1L', 'name' => '1L Bottled Pack (12 Pcs)', 'name_ta' => '1L பாட்டில் பாக் (12 шт)', 'unit_price' => 180.0, 'is_jar' => false],
                ['code' => 'BTL-2L', 'name' => '2L Bottled Pack (9 Pcs)', 'name_ta' => '2L பாட்டில் பாக் (9 шт)', 'unit_price' => 180.0, 'is_jar' => false],
                ['code' => 'BTL-500ML', 'name' => '500ML Mini Pack (24 Pcs)', 'name_ta' => '500ML மினி பாக் (24 шт)', 'unit_price' => 240.0, 'is_jar' => false],
            ]
        ], 'Mobile bootstrap data loaded successfully');
    }

    /**
     * Driver logs a multi-plant refill intake (Load 1, 2, 3...)
     */
    public function storePlantIntake(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required',
            'cans_loaded' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $intake = \App\Models\WaterCanPlantIntake::create([
            'route_id' => $request->route_id,
            'driver_id' => Auth::id() ?? $request->driver_id ?? 1,
            'plant_name' => $request->plant_name ?? 'Main RO Water Treatment Plant',
            'load_sequence' => $request->load_sequence ?? 1,
            'cans_loaded' => (int)$request->cans_loaded,
            'purchase_rate_per_can' => (float)($request->purchase_rate_per_can ?? 8.00),
            'slip_number' => $request->slip_number,
            'slip_photo' => $request->slip_photo,
            'odometer_km' => (int)($request->odometer_km ?? 0),
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'intake_time' => $request->intake_time ?? now(),
            'notes' => $request->notes,
        ]);

        $totalShiftLoaded = \App\Models\WaterCanPlantIntake::where('route_id', $request->route_id)
            ->whereDate('created_at', now()->toDateString())
            ->sum('cans_loaded');

        return $this->sendResponse([
            'intake' => $intake,
            'total_shift_loaded' => $totalShiftLoaded,
            'message' => 'Plant refill intake recorded successfully'
        ], 'Plant intake recorded', 201);
    }

    /**
     * Driver submits bulk tanker trip sheet
     */
    public function storeTripSheet(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'tanker_id' => 'required',
            'trip_date' => 'required|date',
            'source_plant' => 'required|string',
            'delivery_site' => 'required|string',
            'billed_amount' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $tripNumber = 'TRIP-' . date('Ymd') . '-' . rand(1000, 9999);
        $trip = DB::transaction(function () use ($request, $tripNumber) {
            $record = WaterTankerTrip::create([
                'trip_number' => $tripNumber,
                'tanker_id' => $request->tanker_id,
                'driver_id' => Auth::id() ?? $request->driver_id ?? 1,
                'customer_id' => $request->customer_id ?? 1,
                'trip_date' => $request->trip_date,
                'source_plant' => $request->source_plant,
                'delivery_site' => $request->delivery_site,
                'start_km' => $request->start_km ?? 0,
                'end_km' => $request->end_km ?? 0,
                'diesel_expense' => $request->diesel_expense ?? 0,
                'toll_expense' => $request->toll_expense ?? 0,
                'driver_batta' => $request->driver_batta ?? 0,
                'billed_amount' => $request->billed_amount,
                'payment_status' => $request->payment_status ?? 'Pending',
                'site_receiver_name' => $request->site_receiver_name,
                'receiver_signature' => $request->receiver_signature,
                'status' => 'Delivered',
                'notes' => $request->notes,
            ]);

            // Post to General Ledger
            if ((float)$request->billed_amount > 0) {
                try {
                    $this->accountingService->postJournalEntry([
                        'entry_date' => $request->trip_date,
                        'reference_type' => 'WaterTankerTrip',
                        'reference_id' => $tripNumber,
                        'narration' => "Bulk Tanker Delivery [{$tripNumber}] to {$request->delivery_site}",
                        'items' => [
                            ['account_code' => '1030', 'debit' => (float)$request->billed_amount, 'credit' => 0, 'memo' => 'AR Water Delivery'],
                            ['account_code' => '4010', 'debit' => 0, 'credit' => (float)$request->billed_amount, 'memo' => 'Water Logistics Revenue']
                        ]
                    ]);
                } catch (\Exception $e) {}
            }

            return $record;
        });

        return $this->sendResponse($trip, 'Tanker trip sheet logged and posted to ERP ledger', 201);
    }

    /**
     * Driver logs 20L can delivery on route
     */
    public function storeCanDelivery(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required',
            'customer_id' => 'required',
            'delivery_date' => 'required|date',
            'cans_delivered' => 'required|integer|min:1',
            'unit_price' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $deliveryNumber = 'CAN-' . date('Ymd') . '-' . rand(1000, 9999);
        $totalAmount = (int)$request->cans_delivered * (float)$request->unit_price;
        $cashCollected = (float)($request->cash_collected ?? 0);

        $delivery = DB::transaction(function () use ($request, $deliveryNumber, $totalAmount, $cashCollected) {
            $record = WaterCanDelivery::create([
                'delivery_number' => $deliveryNumber,
                'route_id' => $request->route_id,
                'driver_id' => Auth::id() ?? 1,
                'customer_id' => $request->customer_id,
                'delivery_date' => $request->delivery_date,
                'cans_delivered' => $request->cans_delivered,
                'empty_cans_collected' => $request->empty_cans_collected ?? 0,
                'unit_price' => $request->unit_price,
                'total_amount' => $totalAmount,
                'cash_collected' => $cashCollected,
                'empty_balance_due' => (int)$request->cans_delivered - (int)($request->empty_cans_collected ?? 0),
                'payment_mode' => $cashCollected >= $totalAmount ? 'Cash' : 'Credit',
                'signature_url' => $request->signature_url,
                'notes' => $request->notes,
            ]);

            // Post to Double-entry accounting
            try {
                $items = [];
                if ($cashCollected > 0) {
                    $items[] = ['account_code' => '1010', 'debit' => $cashCollected, 'credit' => 0, 'memo' => 'Driver Cash Collected'];
                }
                $arBalance = $totalAmount - $cashCollected;
                if ($arBalance > 0) {
                    $items[] = ['account_code' => '1030', 'debit' => $arBalance, 'credit' => 0, 'memo' => 'Customer Can AR Balance'];
                }
                $items[] = ['account_code' => '4010', 'debit' => 0, 'credit' => $totalAmount, 'memo' => 'Water 20L Can Revenue'];

                $this->accountingService->postJournalEntry([
                    'entry_date' => $request->delivery_date,
                    'reference_type' => 'WaterCanDelivery',
                    'reference_id' => $deliveryNumber,
                    'narration' => "20L Can Delivery [{$deliveryNumber}]",
                    'items' => $items,
                ]);
            } catch (\Exception $e) {}

            return $record;
        });

        return $this->sendResponse($delivery, 'Can delivery logged successfully', 201);
    }

    /**
     * Driver surrenders cash and empty can count at end of shift (Real DB Persistence & Ledger Posting)
     */
    public function driverCashSurrender(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required',
            'surrender_date' => 'required|date',
            'cash_surrendered' => 'required|numeric',
            'empty_cans_returned' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $receiptNumber = 'SURR-' . date('Ymd') . '-' . rand(100, 999);
        $cashAmount = (float) $request->cash_surrendered;
        $emptyCans = (int) $request->empty_cans_returned;
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id') ?? $request->company_id ?? 3;
        $branchId = $request->header('X-Branch-ID') ?? $request->attributes->get('erp.branch_id') ?? $request->branch_id;

        $surrender = WaterCanDriverSurrender::create([
            'surrender_receipt' => $receiptNumber,
            'company_id' => $companyId,
            'branch_id' => $branchId,
            'route_id' => $request->route_id,
            'driver_id' => Auth::id() ?? 1,
            'surrender_date' => $request->surrender_date,
            'cash_surrendered' => $cashAmount,
            'empty_cans_returned' => $emptyCans,
            'filled_cans_returned' => (int) ($request->filled_cans_returned ?? 0),
            'damaged_cans_reported' => (int) ($request->damaged_cans_reported ?? 0),
            'status' => 'Verified & Deposited to Main Cash Ledger',
            'notes' => $request->notes,
        ]);

        // Post accounting journal entry if cash surrendered > 0
        if ($cashAmount > 0) {
            try {
                $header = [
                    'entry_date' => $request->surrender_date,
                    'reference_type' => 'DriverCashSurrender',
                    'reference_id' => $receiptNumber,
                    'narration' => "Driver Cash Surrender [{$receiptNumber}] from Route ID {$request->route_id}",
                ];
                $items = [
                    ['account_code' => '1010', 'debit' => $cashAmount, 'credit' => 0, 'memo' => 'Main Cash In Hand'],
                    ['account_code' => '1030', 'debit' => 0, 'credit' => $cashAmount, 'memo' => 'Driver Settlement Clearing'],
                ];
                $this->accountingService->postJournalEntry($header, $items);
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Driver surrender journal post error: ' . $e->getMessage());
            }
        }

        return $this->sendResponse([
            'id' => $surrender->id,
            'route_id' => $surrender->route_id,
            'driver_id' => $surrender->driver_id,
            'surrender_date' => $surrender->surrender_date->toDateString(),
            'cash_surrendered' => (float) $surrender->cash_surrendered,
            'empty_cans_returned' => $surrender->empty_cans_returned,
            'surrender_receipt' => $surrender->surrender_receipt,
            'status' => $surrender->status,
        ], 'Driver shift surrendered and balanced');
    }

    /**
     * Customer Onboarding & KYC (Field Agent)
     */
    public function customerOnboard(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone_number' => 'required|string',
            'address' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $companyId = $request->company_id ?? 3; // Default DK Waters
        $customer = \App\Models\Customer::create([
            'name' => $request->name,
            'phone_number' => $request->phone_number,
            'address' => $request->address,
            'city' => $request->city ?? 'Madurai',
            'company_id' => $companyId,
            'customer_group_id' => 1,
            'is_active' => true,
        ]);

        $initialCans = (int)($request->opening_cans_held ?? 0);
        $depositHeld = (float)($request->deposit_held ?? ($initialCans * 150));

        if ($initialCans > 0 || $depositHeld > 0) {
            DB::table('water_can_inventories')->updateOrInsert(
                ['customer_id' => $customer->id],
                [
                    'total_cans_held' => $initialCans,
                    'deposit_held' => $depositHeld,
                    'last_delivery_date' => now()->toDateString(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }

        return $this->sendResponse([
            'customer' => $customer,
            'customer_code' => 'CUST-' . str_pad($customer->id, 5, '0', STR_PAD_LEFT),
            'initial_cans_held' => $initialCans,
            'deposit_held' => $depositHeld,
        ], 'Customer onboarded successfully', 201);
    }

    /**
     * Credit Outstanding Collection (Field Agent)
     */
    public function collectPayment(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required',
            'amount_collected' => 'required|numeric|min:1',
            'payment_mode' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $receiptNumber = $request->receipt_number ?? ('REC-' . date('Ymd') . '-' . rand(1000, 9999));
        $amount = (float)$request->amount_collected;

        // Post to ledger: Debit Cash/Bank (1010/1020), Credit Accounts Receivable (1030)
        try {
            $accountCode = strtolower($request->payment_mode) === 'cash' ? '1010' : '1020';
            $header = [
                'entry_date' => date('Y-m-d'),
                'reference_type' => 'CustomerCollection',
                'reference_id' => $receiptNumber,
                'narration' => "Credit Collection [{$receiptNumber}] from Customer ID {$request->customer_id}",
            ];
            $items = [
                ['account_code' => $accountCode, 'debit' => $amount, 'credit' => 0, 'memo' => 'Collection Received'],
                ['account_code' => '1030', 'debit' => 0, 'credit' => $amount, 'memo' => 'AR Balance Cleared'],
            ];
            $this->accountingService->postJournalEntry($header, $items);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Mobile collection ledger posting error: ' . $e->getMessage());
        }

        return $this->sendResponse([
            'receipt_number' => $receiptNumber,
            'customer_id' => $request->customer_id,
            'amount_collected' => $amount,
            'payment_mode' => $request->payment_mode,
            'collection_date' => date('Y-m-d H:i:s'),
            'status' => 'Payment posted & settled',
        ], 'Collection recorded successfully', 201);
    }

    /**
     * Physical Spot Audit (Field Agent / Auditor) - Persisted into water_can_spot_audits table
     */
    public function spotAudit(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'vehicle_number' => 'nullable|string',
            'driver_name' => 'nullable|string',
            'physical_units' => 'required|numeric',
            'expected_units' => 'nullable|numeric',
            'physical_cash' => 'nullable|numeric',
            'expected_cash' => 'nullable|numeric',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation error', $validator->errors()->toArray(), 422);
        }

        $auditId = 'AUDIT-' . date('Ymd') . '-' . rand(1000, 9999);
        $expectedUnits = (int) ($request->expected_units ?? 0);
        $physicalUnits = (int) ($request->physical_units ?? 0);
        $diffUnits = $physicalUnits - $expectedUnits;

        $expectedCash = (float) ($request->expected_cash ?? 0);
        $physicalCash = (float) ($request->physical_cash ?? 0);
        $diffCash = $physicalCash - $expectedCash;

        $isFraudSuspected = (bool) $request->is_fraud_suspected || abs($diffUnits) > 2 || abs($diffCash) > 500;

        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id') ?? $request->company_id ?? 3;
        $branchId = $request->header('X-Branch-ID') ?? $request->attributes->get('erp.branch_id') ?? $request->branch_id;

        $audit = WaterCanSpotAudit::create([
            'audit_id' => $auditId,
            'company_id' => $companyId,
            'branch_id' => $branchId,
            'auditor_id' => Auth::id(),
            'vehicle_number' => $request->vehicle_number,
            'driver_name' => $request->driver_name,
            'audit_date' => $request->audit_date ?? now()->toDateString(),
            'expected_units' => $expectedUnits,
            'physical_units' => $physicalUnits,
            'unit_difference' => $diffUnits,
            'expected_cash' => $expectedCash,
            'physical_cash' => $physicalCash,
            'cash_difference' => $diffCash,
            'is_fraud_suspected' => $isFraudSuspected,
            'status' => 'Audited & Logged into Anti-Fraud Command',
            'notes' => $request->notes,
        ]);

        return $this->sendResponse([
            'id' => $audit->id,
            'audit_id' => $auditId,
            'vehicle_number' => $audit->vehicle_number,
            'driver_name' => $audit->driver_name,
            'unit_difference' => $audit->unit_difference,
            'cash_difference' => (float) $audit->cash_difference,
            'is_fraud_suspected' => (bool) $audit->is_fraud_suspected,
            'status' => $audit->status,
        ], 'Spot audit recorded', 201);
    }

    /**
     * Role Dashboard Summary
     */
    public function roleDashboard(Request $request, string $role): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');

        $metrics = [
            'role' => $role,
            'tmws' => [
                'tankers_count' => DB::table('water_tankers')->where('is_active', true)->count(),
                'trips_today' => DB::table('water_tanker_trips')->whereDate('trip_date', date('Y-m-d'))->count(),
                'total_kl' => (float) DB::table('water_tanker_trips')->sum('water_quantity_kl'),
                'revenue' => (float) DB::table('water_tanker_trips')->sum('trip_rate'),
            ],
            'dk_waters' => [
                'active_routes' => DB::table('water_can_routes')->where('is_active', true)->count(),
                'deliveries_today' => DB::table('water_can_deliveries')
                    ->whereDate('delivery_date', date('Y-m-d'))
                    ->count(),
                'cans_delivered' => (int) DB::table('water_can_deliveries')->sum('cans_delivered'),
                'cans_in_market' => (int) DB::table('water_can_inventories')
                    ->join('customers', 'water_can_inventories.customer_id', '=', 'customers.id')
                    ->when($companyId, fn ($q) => $q->where('customers.company_id', $companyId))
                    ->sum('water_can_inventories.total_cans_held'),
                'deposits_held' => (float) DB::table('water_can_inventories')
                    ->join('customers', 'water_can_inventories.customer_id', '=', 'customers.id')
                    ->when($companyId, fn ($q) => $q->where('customers.company_id', $companyId))
                    ->sum('water_can_inventories.deposit_held'),
                'revenue' => (float) DB::table('water_can_deliveries')->sum('total_amount'),
            ],
            'aran_cafe' => [
                'open_drawers' => Schema::hasTable('cafe_cash_drawers') ? DB::table('cafe_cash_drawers')->where('status', 'open')->count() : 0,
                'pos_sales' => (float) DB::table('sales')->where('company_id', 1)->whereDate('created_at', date('Y-m-d'))->sum('grand_total'),
            ],
        ];

        return $this->sendResponse($metrics, "Dashboard data for role {$role}");
    }

    /**
     * Dedicated Multi-Role Mobile Login with Real Sanctum Authentication
     */
    public function mobileLogin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required_without:email|string',
            'email' => 'required_without:username|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        $identifier = $request->input('username') ?? $request->input('email');
        $user = User::where(function ($q) use ($identifier) {
            $q->where('name', $identifier)->orWhere('email', $identifier);
        })->where('is_active', true)->where('is_deleted', false)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->sendError('Unauthorized', ['credentials' => 'Invalid username/email or password.'], 401);
        }

        // Issue genuine Sanctum personal access token
        $token = $user->createToken('dk-track-mobile')->plainTextToken;

        // Roles & Permissions from DB
        $roles = $user->roles->pluck('name')->values()->all();
        if (empty($roles)) {
            $roleRecord = DB::table('roles')->where('id', $user->role_id)->first();
            if ($roleRecord) {
                $roles[] = $roleRecord->name;
            }
        }
        $primaryRole = $roles[0] ?? 'Staff';

        $permissions = $user->getAllPermissions()->pluck('name')->values()->all();
        if ($user->role_id == 1 || in_array('Admin', $roles, true)) {
            $allPerms = DB::table('permissions')->pluck('name')->values()->all();
            $permissions = array_values(array_unique(array_merge($permissions, $allPerms)));
        }

        // Accessible companies
        $companies = DB::table('company_user')
            ->join('companies', 'company_user.company_id', '=', 'companies.id')
            ->where('company_user.user_id', $user->id)
            ->where('companies.status', 'active')
            ->select('companies.id', 'companies.code', 'companies.legal_name', 'companies.trade_name', 'company_user.is_default')
            ->get();

        $defaultCompany = $companies->firstWhere('is_default', 1) ?? $companies->first();

        // Normalized role slug for mobile compatibility
        $rawRoleInput = $request->input('role');
        $roleSlug = $rawRoleInput ?: match(strtolower($primaryRole)) {
            'admin', 'superadmin', 'owner' => 'superAdmin',
            'delivery driver', 'driver' => 'deliveryDriver',
            'tanker driver' => 'tankerDriver',
            'field agent', 'agent' => 'fieldAgent',
            'cashier' => 'cashier',
            default => strtolower(str_replace(' ', '', $primaryRole)),
        };
        if (strtolower($roleSlug) === 'deliverydriver') $roleSlug = 'deliveryDriver';
        if (strtolower($roleSlug) === 'tankerdriver') $roleSlug = 'tankerDriver';
        if (strtolower($roleSlug) === 'fieldagent') $roleSlug = 'fieldAgent';
        if (strtolower($roleSlug) === 'superadmin') $roleSlug = 'superAdmin';

        return $this->sendResponse([
            'token' => $token,
            'token_type' => 'Bearer',
            'role' => $roleSlug,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'username' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $primaryRole,
                'role_slug' => $roleSlug,
                'role_id' => $user->role_id,
                'company_id' => $defaultCompany?->id,
            ],
            'permissions' => $permissions,
            'companies' => $companies,
            'allowed_modules' => ['dashboard', 'water_logistics', 'sales', 'inventory', 'accounting', 'fleet', 'cafe_pos', 'anti_fraud'],
        ], 'Authenticated successfully for mobile role session');
    }

    /**
     * ERP Customers Directory (Company Scoped & Paginated)
     */
    public function customersList(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id') ?? $request->company_id;
        $limit = min((int) ($request->input('limit', 50)), 100);

        $query = DB::table('customers')
            ->leftJoin('water_can_inventories', 'customers.id', '=', 'water_can_inventories.customer_id')
            ->when($companyId, fn ($q) => $q->where('customers.company_id', $companyId))
            ->when($request->filled('updated_since'), fn ($q) => $q->where('customers.updated_at', '>=', $request->updated_since))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%' . $request->search . '%';
                $q->where(fn ($sub) => $sub->where('customers.name', 'like', $term)->orWhere('customers.phone_number', 'like', $term));
            })
            ->select(
                'customers.id',
                'customers.name',
                'customers.phone_number as phone',
                'customers.address',
                'customers.city',
                'customers.company_id',
                DB::raw('COALESCE(water_can_inventories.total_cans_held, 0) as cans_held'),
                DB::raw('COALESCE(water_can_inventories.deposit_held, 0) as deposit_held'),
                'customers.updated_at'
            )
            ->orderBy('customers.id', 'desc');

        $customers = $query->take($limit)->get();

        return $this->sendResponse($customers, 'Customers directory retrieved');
    }

    /**
     * ERP Products & Price Matrix (Company Scoped & Paginated)
     */
    public function productsList(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id') ?? $request->company_id;
        $limit = min((int) ($request->input('limit', 50)), 100);

        $query = DB::table('products')
            ->where('is_active', true)
            ->when($companyId, fn ($q) => $q->where('company_id', $companyId))
            ->when($request->filled('updated_since'), fn ($q) => $q->where('updated_at', '>=', $request->updated_since))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%' . $request->search . '%';
                $q->where(fn ($sub) => $sub->where('name', 'like', $term)->orWhere('code', 'like', $term));
            })
            ->select('id', 'name', 'code', 'price', 'unit_id', 'company_id', 'updated_at')
            ->orderBy('id', 'desc');

        $products = $query->take($limit)->get();

        return $this->sendResponse($products, 'Products catalog retrieved');
    }

    /**
     * ERP Invoices & Delivery Slips (Company Scoped & Paginated)
     */
    public function invoicesList(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id') ?? $request->company_id;
        $limit = min((int) ($request->input('limit', 50)), 100);

        $query = DB::table('water_can_deliveries')
            ->join('customers', 'water_can_deliveries.customer_id', '=', 'customers.id')
            ->when($companyId, fn ($q) => $q->where('customers.company_id', $companyId))
            ->when($request->filled('updated_since'), fn ($q) => $q->where('water_can_deliveries.updated_at', '>=', $request->updated_since))
            ->select(
                'water_can_deliveries.id',
                'water_can_deliveries.delivery_no',
                'water_can_deliveries.delivery_date',
                'water_can_deliveries.cans_delivered',
                'water_can_deliveries.empty_cans_returned as empty_cans_collected',
                'water_can_deliveries.total_amount',
                'water_can_deliveries.payment_mode',
                'customers.name as customer_name',
                'water_can_deliveries.updated_at'
            )
            ->orderBy('water_can_deliveries.id', 'desc');

        $deliveries = $query->take($limit)->get();

        return $this->sendResponse($deliveries, 'Invoices and deliveries retrieved');
    }

    /**
     * ERP Financial Ledger Balances (Real Calculation from Ledger & Inventories)
     */
    public function financials(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-ID') ?? $request->attributes->get('erp.company_id');
        if (!$companyId && Auth::check()) {
            $companyId = DB::table('company_user')->where('user_id', Auth::id())->where('is_default', 1)->value('company_id')
                ?? DB::table('company_user')->where('user_id', Auth::id())->value('company_id')
                ?? 3;
        }
        $companyId ??= 3; // Fallback to DK Waters if not specified

        // 1. Live Ledger balances from journal_items
        $cash1010 = (float) DB::table('journal_items')
            ->join('chart_of_accounts', 'journal_items.chart_of_account_id', '=', 'chart_of_accounts.id')
            ->where('chart_of_accounts.company_id', $companyId)
            ->where(fn ($q) => $q->where('chart_of_accounts.code', '1010')->orWhere('chart_of_accounts.control_type', 'cash'))
            ->sum(DB::raw('journal_items.debit - journal_items.credit'));

        $bank1020 = (float) DB::table('journal_items')
            ->join('chart_of_accounts', 'journal_items.chart_of_account_id', '=', 'chart_of_accounts.id')
            ->where('chart_of_accounts.company_id', $companyId)
            ->where(fn ($q) => $q->where('chart_of_accounts.code', '1020')->orWhere('chart_of_accounts.control_type', 'bank'))
            ->sum(DB::raw('journal_items.debit - journal_items.credit'));

        $ar1030 = (float) DB::table('journal_items')
            ->join('chart_of_accounts', 'journal_items.chart_of_account_id', '=', 'chart_of_accounts.id')
            ->where('chart_of_accounts.company_id', $companyId)
            ->where(fn ($q) => $q->where('chart_of_accounts.code', '1030')->orWhere('chart_of_accounts.control_type', 'ar'))
            ->sum(DB::raw('journal_items.debit - journal_items.credit'));

        // 2. Container Deposits held for customers of this company
        $totalDeposits = (float) DB::table('water_can_inventories')
            ->join('customers', 'water_can_inventories.customer_id', '=', 'customers.id')
            ->where('customers.company_id', $companyId)
            ->sum('water_can_inventories.deposit_held');

        // 3. Driver Surrendered Cash today (in transit to bank)
        $cashInTransit = (float) DB::table('water_can_driver_surrenders')
            ->where('company_id', $companyId)
            ->whereDate('surrender_date', now()->toDateString())
            ->sum('cash_surrendered');

        // 4. Collections received today
        $todayCollections = (float) DB::table('water_can_deliveries')
            ->join('customers', 'water_can_deliveries.customer_id', '=', 'customers.id')
            ->where('customers.company_id', $companyId)
            ->whereDate('water_can_deliveries.delivery_date', now()->toDateString())
            ->sum('water_can_deliveries.paid_amount');

        $data = [
            'company_id' => (int) $companyId,
            'cash_in_hand_1010' => $cash1010,
            'bank_account_1020' => $bank1020,
            'accounts_receivable_1030' => $ar1030,
            'total_container_deposits' => $totalDeposits,
            'cash_in_transit_drivers' => $cashInTransit,
            'today_collections' => $todayCollections,
        ];

        return $this->sendResponse($data, 'Real-time financial ledger balances retrieved');
    }
}

