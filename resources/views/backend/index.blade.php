@extends('backend.layout.main')
@section('charts', '1')
@section('content')

@push('css')
<link rel="stylesheet" href="{{ versioned_asset('css/pages/index.css') }}">
@endpush

<x-success-message key="message" />
<x-error-message key="not_permitted" />

@php
    $general_setting = $general_setting ?? \App\Models\GeneralSetting::latest()->first();
    if (!isset($role_has_permissions_list) || is_null($role_has_permissions_list)) {
        if (Auth::check() && Auth::user()->role_id > 2) {
            $role_has_permissions_list = DB::table('permissions')
                ->join('role_has_permissions', 'permissions.id', '=', 'role_has_permissions.permission_id')
                ->where('role_id', Auth::user()->role_id)
                ->select('permissions.name')
                ->get();
        } else {
            $role_has_permissions_list = collect([
                (object)['name' => 'revenue_profit_summary'],
                (object)['name' => 'cash_flow'],
                (object)['name' => 'monthly_summary'],
                (object)['name' => 'yearly_report']
            ]);
        }
    }

    if ($general_setting && $general_setting->theme == 'default.css') {
        $color = '#733686';
        $color_rgba = 'rgba(115, 54, 134, 0.8)';
    } elseif ($general_setting && $general_setting->theme == 'green.css') {
        $color = '#2ecc71';
        $color_rgba = 'rgba(46, 204, 113, 0.8)';
    } elseif ($general_setting && $general_setting->theme == 'blue.css') {
        $color = '#3498db';
        $color_rgba = 'rgba(52, 152, 219, 0.8)';
    } else {
        $color = '#34495e';
        $color_rgba = 'rgba(52, 73, 94, 0.8)';
    }
    $lims_warehouse_list = App\Models\Warehouse::where('is_active', true)->get();
@endphp

<div class="row mx-0">{{-- row around a container: no negative gutters, so the page never scrolls sideways --}}
    <div class="container-fluid">
        @if (!config('database.connections.zoloerp_landlord') && \Auth::user()->role_id <= 2)
            @if (isset($versionUpgradeData['alert_version_upgrade_enable']) && $versionUpgradeData['alert_version_upgrade_enable'] == true)
                <div id="alertSection" class="zolo-banner-card alert alert-dismissible fade show mb-3" role="alert">
                    <div class="zolo-banner-content">
                        <span class="zolo-badge-pill">zoloERP System</span>
                        <span class="zolo-banner-text">Version <strong>{{ $versionUpgradeData['demo_version'] }}</strong> is ready for your deployment.</span>
                        <a href="{{ route('new-release') }}" class="zolo-banner-action">View Release Notes &rarr;</a>
                    </div>
                    <button type="button" id="closeButtonUpgrade" class="close" data-dismiss="alert" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
            @endif
        @endif

        <!-- Executive Command Header & Controls -->
        <div class="col-md-12 mt-2 mb-3">
            <div class="zolo-dashboard-header">
                <div class="d-flex align-items-center justify-content-between flex-wrap">
                    <div class="zolo-greeting">
                        <h2 class="zolo-greeting-title">Welcome back, <span class="zolo-accent-name">{{ Auth::user()->name }}</span> 👋</h2>
                        <p class="zolo-greeting-subtitle">zoloERP &bull; Commercial, Financial &amp; Operational Command Center</p>
                    </div>

                    @php
                        $revenue_profit_summary = $role_has_permissions_list
                            ->where('name', 'revenue_profit_summary')
                            ->first();
                    @endphp
                    @if ($revenue_profit_summary)
                    <div class="zolo-filter-bar d-flex align-items-center flex-wrap mt-2 mt-md-0">
                        @if (\Auth::user()->role_id <= 2)
                        <div class="zolo-warehouse-picker mr-2">
                            <i class="dripicons-location text-primary mr-1"></i>
                            <select name="warehouse_id" class="selectpicker" id="warehouse_btn" data-live-search="true" data-live-search-style="begins">
                                <option value="0">{{ __('db.All Warehouse') }}</option>
                                @foreach ($lims_warehouse_list as $warehouse)
                                    <option value="{{ $warehouse->id }}">{{ $warehouse->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        @endif

                        <div class="dropdown">
                            <button type="button" class="btn btn-outline-secondary dropdown-toggle zolo-date-filter-btn" data-toggle="dropdown">
                                <i class="dripicons-calendar mr-1"></i> {{ __('db.Date Range') }}
                            </button>
                            <div class="dropdown-menu dropdown-menu-right zolo-dropdown-menu">
                                <button class="dropdown-item date-btn" data-start_date="{{ date('Y-m-d') }}" data-end_date="{{ date('Y-m-d') }}">{{ __('db.Today') }}</button>
                                <button class="dropdown-item date-btn" data-start_date="{{ date('Y-m-d', strtotime(' -7 day')) }}" data-end_date="{{ date('Y-m-d') }}">{{ __('db.Last 7 Days') }}</button>
                                <button class="dropdown-item date-btn active" data-start_date="{{ date('Y') . '-' . date('m') . '-' . '01' }}" data-end_date="{{ date('Y-m-d') }}">{{ __('db.This Month') }}</button>
                                <button class="dropdown-item date-btn" data-start_date="{{ date('Y') . '-01' . '-01' }}" data-end_date="{{ date('Y') . '-12' . '-31' }}">{{ __('db.This Year') }}</button>
                            </div>
                        </div>
                    </div>
                    @endif
                </div>

                <!-- Executive Quick Action Bar -->
                <div class="zolo-quick-actions-bar pt-2 mt-2 border-top border-secondary-subtle">
                    <span class="text-muted mr-2 u-fs-11_5px u-fw-600"><i class="dripicons-broadcast mr-1"></i>QUICK ACTIONS:</span>
                    @if(in_array('sales.pos', app(\App\Services\Platform\CapabilityService::class)->forNavigation(), true))
                    <a href="{{ route('sale.pos') }}" class="zolo-quick-btn primary">
                        <i class="dripicons-shopping-bag"></i> POS Terminal
                    </a>
                    @endif
                    <a href="{{ route('sales.index', ['new' => 1]) }}" class="zolo-quick-btn">
                        <i class="dripicons-plus"></i> New Sale
                    </a>
                    <a href="{{ route('purchases.index', ['new' => 1]) }}" class="zolo-quick-btn">
                        <i class="dripicons-cart"></i> New Purchase
                    </a>
                    <a href="{{ route('expenses.index', ['new' => 1]) }}" class="zolo-quick-btn">
                        <i class="dripicons-wallet"></i> Add Expense
                    </a>
                    @if (Route::has('accounting.coa'))
                    <a href="{{ route('accounting.coa') }}" class="zolo-quick-btn">
                        <i class="dripicons-list"></i> Chart of Accounts
                    </a>
                    @endif
                    @if (Route::has('accounting.general-ledger'))
                    <a href="{{ route('accounting.general-ledger') }}" class="zolo-quick-btn">
                        <i class="dripicons-document-edit"></i> General Ledger
                    </a>
                    @endif
                    <a href="{{ url('/operations/stock') }}" class="zolo-quick-btn">
                        <i class="dripicons-stack"></i> Stock ({{ $total_products ?? 0 }})
                    </a>
                </div>
            </div>

            @if (in_array('restaurant', explode(',', cache()->get('general_setting')->modules)))
                @if (Auth::user()->role_id > 2 && isset(Auth::user()->service_staff))
                    @php
                        $cooked = DB::table('sales')
                            ->where('waiter_id', Auth::user()->id)
                            ->where('sale_status', 5)
                            ->orWhere('sale_status', 6)
                            ->where('sales.created_at', '>=', now()->subDay())
                            ->count();
                    @endphp
                @elseif(Auth::user()->role_id <= 2)
                    @php
                        $cooked = DB::table('sales')
                            ->where('sale_status', 6)
                            ->where('sales.created_at', '>=', now()->subDay())
                            ->count();
                    @endphp
                @endif
                <a href="{{ route('kitchen.dashboard') }}">
                    <div class="alert alert-warning alert-dismissible text-center mb-2">
                        <strong>{{ $cooked }} {{ __('db.Orders to serve') }}</strong>
                    </div>
                </a>
            @endif
        </div>
    </div>
</div>

<!-- Multi-Company Live Insights Section (Aran Cafe, TMWS, DK Waters) -->
@if(isset($company_cards) && count($company_cards) > 0)
<section class="company-insights-section">
    <div class="container-fluid">
        <div class="company-insights-header">
            <h5 class="company-insights-title">
                <i class="dripicons-view-thumb text-primary"></i>
                Multi-Enterprise Command Deck &bull; Operational Insights
            </h5>
            <span class="company-insights-badge">
                <i class="dripicons-broadcast mr-1"></i> 3 Live Enterprises Connected
            </span>
        </div>

        <div class="row">
            @foreach($company_cards as $card)
            <div class="col-xl-4 col-lg-4 col-md-12 mb-3">
                <div class="company-insight-card theme-{{ $card['theme_color'] }} {{ $card['is_active'] ? 'is-active-company' : '' }}">
                    <div class="company-card-top-stripe"></div>

                    <!-- Card Header -->
                    <div class="company-card-header">
                        <div class="company-card-title-wrap">
                            <div class="company-card-icon-box">
                                <i class="{{ $card['icon'] }}"></i>
                            </div>
                            <div>
                                <h4 class="company-card-name">{{ $card['name'] }}</h4>
                                <p class="company-card-tagline">{{ $card['tagline'] }}</p>
                            </div>
                        </div>
                        @if($card['is_active'])
                            <span class="company-active-badge">
                                <span class="zolo-pulse-indicator"></span> Active Workspace
                            </span>
                        @else
                            <form action="{{ route('company.choose') }}" method="POST" class="d-inline m-0">
                                @csrf
                                <input type="hidden" name="company_id" value="{{ $card['id'] }}">
                                <button type="submit" class="company-card-btn-switch">
                                    <i class="fa fa-sign-in mr-1"></i> Switch
                                </button>
                            </form>
                        @endif
                    </div>

                    <!-- 4-Tile Metrics Grid -->
                    <div class="company-card-metrics-grid">
                        @if($card['vertical'] === 'cafe_bakery')
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Outlets</span>
                                    <i class="dripicons-store text-warning"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['branches_count'] }} Branches</div>
                                <div class="company-metric-tile-sub">Main Kitchen + Kiosk</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Daily Sales</span>
                                    <i class="dripicons-graph-bar text-success"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $currency_symbol }} {{ number_format($card['sales_today'], 2) }}</div>
                                <div class="company-metric-tile-sub">{{ $card['sales_count'] }} receipts billed</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Cash Drawers</span>
                                    <i class="dripicons-wallet text-primary"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['open_drawers'] }} Open</div>
                                <div class="company-metric-tile-sub">Shift Float Balanced</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Catalog Items</span>
                                    <i class="dripicons-tag text-info"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['products_count'] }} Items</div>
                                <div class="company-metric-tile-sub">{{ $card['ingredients_count'] }} raw ingredients</div>
                            </div>
                        @elseif($card['vertical'] === 'bulk_water')
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Tanker Fleet</span>
                                    <i class="dripicons-drop text-primary"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['active_tankers'] }} Lorries</div>
                                <div class="company-metric-tile-sub">Total: {{ $card['total_capacity_kl'] }} KL Capacity</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Delivered Water</span>
                                    <i class="dripicons-meter text-info"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ number_format($card['volume_kl'], 1) }} KL</div>
                                <div class="company-metric-tile-sub">{{ $card['trips_total'] }} total trips</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Excess Mileage</span>
                                    <i class="dripicons-direction text-warning"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ number_format($card['excess_km_total'], 1) }} KM</div>
                                <div class="company-metric-tile-sub">Rate: ₹45.00/KM</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Motor Pumping</span>
                                    <i class="dripicons-clock text-success"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ number_format($card['pump_mins_total'], 0) }} Mins</div>
                                <div class="company-metric-tile-sub">Rate: ₹10.00/min</div>
                            </div>
                        @else
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Route Fleet</span>
                                    <i class="dripicons-direction text-success"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['active_routes'] }} Routes</div>
                                <div class="company-metric-tile-sub">Tata Ace Daily Beats</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Delivered Today</span>
                                    <i class="dripicons-archive text-primary"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['cans_delivered_today'] }} Cans</div>
                                <div class="company-metric-tile-sub">{{ $card['cans_returned_today'] }} empties collected</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Market Circulation</span>
                                    <i class="dripicons-retweet text-info"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $card['cans_in_market'] }} Held</div>
                                <div class="company-metric-tile-sub">Customer bottles active</div>
                            </div>
                            <div class="company-metric-tile">
                                <div class="company-metric-tile-label">
                                    <span>Deposit Ledger</span>
                                    <i class="dripicons-lock text-warning"></i>
                                </div>
                                <div class="company-metric-tile-value">{{ $currency_symbol }} {{ number_format($card['deposits_held'], 2) }}</div>
                                <div class="company-metric-tile-sub">Anti-loss security deposit</div>
                            </div>
                        @endif
                    </div>

                    <!-- Visual Segmented Progress / Split Meter -->
                    <div class="company-visual-meter-wrap">
                        @if($card['vertical'] === 'cafe_bakery')
                            <div class="company-visual-meter-header">
                                <span>2-Branch Kitchen Stock Allocation</span>
                                <span class="font-weight-bold">
                                    Main: {{ (int)$card['branch1_stock'] }} | Express: {{ (int)$card['branch2_stock'] }}
                                </span>
                            </div>
                            <div class="company-visual-bar-track">
                                <div class="company-visual-bar-fill" style="width: 60%; background: #f59e0b;" title="Main Branch"></div>
                                <div class="company-visual-bar-fill" style="width: 40%; background: #d97706;" title="Express Counter"></div>
                            </div>
                        @elseif($card['vertical'] === 'bulk_water')
                            <div class="company-visual-meter-header">
                                <span>Multi-Compartment Chamber Segments (20KL & 40KL)</span>
                                <span class="text-info font-weight-bold">Split Ready</span>
                            </div>
                            <div class="company-chamber-segments">
                                <div class="company-chamber-box" title="Chamber 1">Chamber 1 (10KL)</div>
                                <div class="company-chamber-box" title="Chamber 2">Chamber 2 (10KL)</div>
                                <div class="company-chamber-box" title="Chamber 3 (40KL Tanker)">Chamber 3 (20KL)</div>
                            </div>
                        @else
                            <div class="company-visual-meter-header">
                                <span>Empty Can Recovery & Anti-Theft Ledger</span>
                                <span class="text-success font-weight-bold">
                                    92% Recovery Rate
                                </span>
                            </div>
                            <div class="company-visual-bar-track">
                                <div class="company-visual-bar-fill" style="width: 92%; background: #10b981;" title="Empty Cans Recovered"></div>
                                <div class="company-visual-bar-fill" style="width: 8%; background: #ef4444;" title="Pending in Market"></div>
                            </div>
                        @endif
                    </div>

                    <!-- Card Actions Bar -->
                    <div class="company-card-actions-bar">
                        <div class="d-flex align-items-center flex-wrap" style="gap: 4px;">
                            @if($card['vertical'] === 'cafe_bakery')
                                <a href="{{ route('sale.pos') }}" class="company-card-btn">
                                    <i class="dripicons-shopping-bag text-warning"></i> POS Counter
                                </a>
                                <a href="{{ route('cafe.index') }}" class="company-card-btn">
                                    <i class="dripicons-store"></i> Cafe Shift
                                </a>
                            @elseif($card['vertical'] === 'bulk_water')
                                <a href="{{ route('water-logistics.index') }}" class="company-card-btn">
                                    <i class="dripicons-drop text-primary"></i> Tanker Trips
                                </a>
                                <a href="{{ route('fleet.tracking') }}" class="company-card-btn">
                                    <i class="dripicons-direction"></i> Fleet GPS
                                </a>
                            @else
                                <a href="{{ route('water-logistics.index') }}" class="company-card-btn">
                                    <i class="dripicons-box text-success"></i> Can Routes
                                </a>
                                <a href="{{ route('water-logistics.credit-aging') }}" class="company-card-btn">
                                    <i class="dripicons-document"></i> Credit Aging
                                </a>
                            @endif
                        </div>
                        <div>
                            @if($card['is_active'])
                                <span class="badge badge-success font-weight-bold px-2 py-1" style="font-size: 11px;">
                                    <i class="fa fa-check mr-1"></i> Current
                                </span>
                            @else
                                <form action="{{ route('company.choose') }}" method="POST" class="d-inline m-0">
                                    @csrf
                                    <input type="hidden" name="company_id" value="{{ $card['id'] }}">
                                    <button type="submit" class="btn btn-xs btn-primary font-weight-bold px-2 py-1" style="font-size: 11px;">
                                        Enter &rarr;
                                    </button>
                                </form>
                            @endif
                        </div>
                    </div>

                </div>
            </div>
            @endforeach
        </div>
    </div>
</section>
@endif

<!-- Executive KPI Strip (8 Core Business Indicators) -->
<section class="dashboard-counts pt-0">
    <div class="container-fluid">
        @if ($revenue_profit_summary)
        <div class="row">
            <!-- KPI 1: Net Revenue -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-purple">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-graph-bar"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-arrow-thin-up"></i> Inflow
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number revenue-data">{{ number_format((float) $revenue, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>{{ __('db.revenue') }}</span>
                            <x-info title="(grand_total - shipping_cost) - Return + income = Revenue" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Sale Return:</span>
                            <span class="text-danger font-weight-bold">{{ $currency_symbol }}<span class="return-data">{{ number_format((float) $return, $general_setting->decimal, '.', '') }}</span></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 2: Net Profit -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-blue">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-trophy"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-star"></i> Net Margin
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number profit-data">{{ number_format((float) $profit, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>{{ __('db.profit') }}</span>
                            <x-info title="Revenue + Purchase Return - Product Cost (COGS) - Expense" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Purchase Return:</span>
                            <span class="text-success font-weight-bold">{{ $currency_symbol }}<span class="purchase_return-data">{{ number_format((float) $purchase_return, $general_setting->decimal, '.', '') }}</span></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 3: Gross Sales Volume -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-cyan">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-cart"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-tag"></i> Sales
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number total_sale-data">{{ number_format((float) $total_sale, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>{{ __('db.Sale') }} Total</span>
                            <x-info title="Total gross sales value before deductions" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Customers:</span>
                            <span class="font-weight-bold">{{ $total_customers ?? 0 }} Active</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 4: Total Purchases (COGS) -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-orange">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-archive"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-arrow-thin-down"></i> Acquisition
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number total_purchase-data">{{ number_format((float) $purchase, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>{{ __('db.Purchase') }} Total</span>
                            <x-info title="Total merchandise purchase cost" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Suppliers:</span>
                            <span class="font-weight-bold">{{ $total_suppliers ?? 0 }} Vendors</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 5: Operating Expenses -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-rose">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-wallet"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-crosshair"></i> Overheads
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number expense-data">{{ number_format((float) $expense, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>{{ __('db.Expense') }}</span>
                            <x-info title="Operational overhead and direct business expenditures" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Type:</span>
                            <span class="text-warning font-weight-bold">Direct &amp; SG&amp;A</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 6: Customer Receivables (AR Due) -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-amber">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-clock"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-warning"></i> Due in
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number invoice-due-data">{{ number_format((float) $invoice_due, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>Receivables (AR)</span>
                            <x-info title="Unpaid invoices due from customers" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Collections:</span>
                            <span class="text-warning font-weight-bold">Pending Inflow</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 7: Supplier Payables (AP Due) -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-teal">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-calendar"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-information"></i> Due out
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number purchase_due-data">{{ number_format((float) $purchase_due, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>Payables (AP)</span>
                            <x-info title="Outstanding bills due to vendors" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Obligations:</span>
                            <span class="text-info font-weight-bold">Supplier Credit</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- KPI 8: Cash & Bank Liquidity -->
            <div class="col-xl-3 col-lg-3 col-md-6 col-sm-6 mb-3">
                <div class="zolo-kpi-card kpi-emerald">
                    <div class="zolo-kpi-header">
                        <div class="zolo-kpi-icon">
                            <i class="dripicons-briefcase"></i>
                        </div>
                        <span class="zolo-kpi-badge">
                            <i class="dripicons-checkmark"></i> Liquidity
                        </span>
                    </div>
                    <div class="zolo-kpi-body">
                        <div class="zolo-kpi-value">
                            <span class="zolo-kpi-currency">{{ $currency_symbol }}</span>
                            <span class="count-number liquid-balance-data">{{ number_format((float) $liquid_balance, $general_setting->decimal, '.', '') }}</span>
                        </div>
                        <div class="zolo-kpi-label">
                            <span>Cash &amp; Bank</span>
                            <x-info title="Total available liquidity across all active bank and cash accounts" type="info" />
                        </div>
                        <div class="zolo-kpi-subtext">
                            <span>Inventory Value:</span>
                            <span class="text-success font-weight-bold">{{ $currency_symbol }}<span class="stock-value-data">{{ number_format((float) $stock_valuation, $general_setting->decimal, '.', '') }}</span></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @endif
    </div>
</section>

{{-- Dashboard panels as labelled tabs (app-shell.js steps) so the dashboard fits one screen. --}}
<div class="dash-panels container-fluid" data-shell-steps>
<div data-step-title="Cash flow">
<!-- Visual Financial & Cash Flow Analytics Row -->
<div class="container-fluid">
    <div class="row">
        @php
            $cash_flow = $role_has_permissions_list->where('name', 'cash_flow')->first();
            $monthly_summary = $role_has_permissions_list->where('name', 'monthly_summary')->first();
        @endphp

        @if ($cash_flow)
        <div class="col-lg-7 col-md-12 mb-3">
            <div class="card line-chart-example h-100 mb-0">
                <div class="card-header d-flex align-items-center justify-content-between">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-pulse text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.Cash Flow') }} <span class="text-muted u-fs-12px u-fw-500">(Last 6 Months)</span></h4>
                    </div>
                    <span class="badge badge-success font-weight-semibold">Live Flow</span>
                </div>
                <div class="card-body pt-1 pb-2 u-ov-hidden">
                    <div class="zolo-chart-box u-pos-relative u-h-230px u-maxh-230px u-w-100pct u-ov-hidden">
                        <canvas id="cashFlow" height="230"
                            data-color = "{{ $color }}"
                            data-color_rgba = "{{ $color_rgba }}"
                            data-recieved = "{{ json_encode($payment_recieved) }}"
                            data-sent = "{{ json_encode($payment_sent) }}"
                            data-month = "{{ json_encode($month) }}"
                            data-label1="{{ __('db.Payment Recieved') }}"
                            data-label2="{{ __('db.Payment Sent') }}" class="u-maxh-230px u-w-100pct u-d-block"></canvas>
                    </div>
                </div>
            </div>
        </div>
        @endif

        @if ($monthly_summary)
        <div class="col-lg-5 col-md-12 mb-3">
            <div class="card h-100 mb-0 u-ov-hidden">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-pie-chart text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ date('F') }} {{ date('Y') }} Breakdown</h4>
                    </div>
                    <span class="badge badge-primary font-weight-semibold">Summary</span>
                </div>
                <div class="card-body pt-1 pb-2 d-flex flex-column justify-content-between u-ov-hidden">
                    <div class="zolo-donut-box u-pos-relative u-h-180px u-maxh-180px u-w-100pct u-d-flex u-items-center u-justify-center u-ov-hidden">
                        <canvas id="transactionChart" height="180" class="z-chart-canvas"
                            data-color = "{{ $color }}"
                            data-color_rgba = "{{ $color_rgba }}" data-revenue={{ $revenue }}
                            data-purchase={{ $purchase }} data-expense={{ $expense }}
                            data-label1="{{ __('db.Purchase') }}" data-label2="{{ __('db.revenue') }}"
                            data-label3="{{ __('db.Expense') }}"> </canvas>
                    </div>
                    <!-- Quick Metric Badges -->
                    <div class="d-flex justify-content-around align-items-center pt-2 border-top border-secondary-subtle">
                        <div class="donut-legend-pill">
                            <span class="donut-legend-dot u-bg-primary"></span>
                            <span>Purchase: {{ $currency_symbol }}{{ number_format((float)$purchase, 0, '.', ',') }}</span>
                        </div>
                        <div class="donut-legend-pill">
                            <span class="donut-legend-dot u-bg-success"></span>
                            <span>Revenue: {{ $currency_symbol }}{{ number_format((float)$revenue, 0, '.', ',') }}</span>
                        </div>
                        <div class="donut-legend-pill">
                            <span class="donut-legend-dot u-bg-warning"></span>
                            <span>Expense: {{ $currency_symbol }}{{ number_format((float)$expense, 0, '.', ',') }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @endif
    </div>
</div>

</div>

<!-- Modular Industry Addon Live Pulse Bar -->
@if(!empty($addon_stats))
<div data-step-title="Industry addons">
<div class="container-fluid mt-1 mb-3">
    <div class="row">
        @if(isset($addon_stats['water_tankers']) || isset($addon_stats['cans_delivered_today']))
        <div class="col-md-4 mb-2 mb-md-0">
            <div class="zolo-addon-pulse-card">
                <div class="d-flex align-items-center">
                    <div class="zolo-kpi-icon mr-2 u-bg-rgba-2-132-199-0_15 u-c-info">
                        <i class="dripicons-truck"></i>
                    </div>
                    <div>
                        <div class="u-fs-11px u-fw-700 u-tt-uppercase u-c-info">Water Logistics</div>
                        <div class="u-fs-13px u-fw-700 u-c-neo-text-primary">
                            {{ $addon_stats['water_tankers'] ?? 0 }} Tankers Active &bull; {{ $addon_stats['water_trips_today'] ?? 0 }} Trips
                        </div>
                    </div>
                </div>
                <div class="text-right">
                    <span class="zolo-pulse-indicator mr-1"></span>
                    <a href="{{ url('water-logistics') }}" class="btn btn-xs btn-outline-info ml-1">Fleet &rarr;</a>
                </div>
            </div>
        </div>
        @endif

        @if(isset($addon_stats['open_drawers']))
        <div class="col-md-4 mb-2 mb-md-0">
            <div class="zolo-addon-pulse-card">
                <div class="d-flex align-items-center">
                    <div class="zolo-kpi-icon mr-2 u-bg-rgba-234-88-12-0_15 u-c-warning">
                        <i class="dripicons-store"></i>
                    </div>
                    <div>
                        <div class="u-fs-11px u-fw-700 u-tt-uppercase u-c-warning">Bakery &amp; Cafe POS</div>
                        <div class="u-fs-13px u-fw-700 u-c-neo-text-primary">
                            {{ $addon_stats['open_drawers'] ?? 0 }} Active Drawers &bull; Fast Register
                        </div>
                    </div>
                </div>
                <div class="text-right">
                    <span class="zolo-pulse-indicator mr-1"></span>
                    <a href="{{ url('cafe') }}" class="btn btn-xs btn-outline-warning ml-1">Terminal &rarr;</a>
                </div>
            </div>
        </div>
        @endif

        @if(isset($addon_stats['repair_services_count']))
        <div class="col-md-4 mb-2 mb-md-0">
            <div class="zolo-addon-pulse-card">
                <div class="d-flex align-items-center">
                    <div class="zolo-kpi-icon mr-2 u-bg-rgb-primary-rgb-0_15 u-c-primary">
                        <i class="dripicons-gear"></i>
                    </div>
                    <div>
                        <div class="u-fs-11px u-fw-700 u-tt-uppercase u-c-primary">RMA Repair Service</div>
                        <div class="u-fs-13px u-fw-700 u-c-neo-text-primary">
                            {{ $addon_stats['repair_services_count'] ?? 0 }} Services Configured &bull; Live Bench
                        </div>
                    </div>
                </div>
                <div class="text-right">
                    <span class="zolo-pulse-indicator mr-1"></span>
                    <a href="{{ url('repair/dashboard') }}" class="btn btn-xs btn-outline-primary ml-1">Queue &rarr;</a>
                </div>
            </div>
        </div>
        @endif
    </div>
</div>
</div>
@endif

<div data-step-title="Transactions &amp; stock">
<!-- Operational Activity & Inventory Alerts Hub -->
<div class="container-fluid">
    <div class="row">
        <!-- Left: Recent Transaction Activity Hub -->
        <div class="col-lg-7 col-md-12 mb-3">
            <div class="card h-100 mb-0">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-swap text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.Recent Transaction') }}</h4>
                    </div>
                    <div class="badge badge-primary font-weight-semibold">{{ __('db.latest') }} 5</div>
                </div>
                <div class="card-body pt-1 pb-2">
                    <ul class="nav nav-tabs" role="tablist">
                        <li class="nav-item">
                            <a class="nav-link active" href="#sale-latest" role="tab" data-toggle="tab">{{ __('db.Sale') }}</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#purchase-latest" role="tab" data-toggle="tab">{{ __('db.Purchase') }}</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#quotation-latest" role="tab" data-toggle="tab">{{ __('db.Quotation') }}</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#payment-latest" role="tab" data-toggle="tab">{{ __('db.Payment') }}</a>
                        </li>
                    </ul>

                    <div class="tab-content pt-2">
                        <div role="tabpanel" class="tab-pane fade show active" id="sale-latest">
                            <div class="table-responsive">
                                <table id="recent-sale" class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>{{ __('db.date') }}</th>
                                            <th>{{ __('db.reference') }}</th>
                                            <th>{{ __('db.customer') }}</th>
                                            <th>{{ __('db.status') }}</th>
                                            <th>{{ __('db.grand total') }}</th>
                                        </tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                        </div>
                        <div role="tabpanel" class="tab-pane fade" id="purchase-latest">
                            <div class="table-responsive">
                                <table id="recent-purchase" class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>{{ __('db.date') }}</th>
                                            <th>{{ __('db.reference') }}</th>
                                            <th>{{ __('db.Supplier') }}</th>
                                            <th>{{ __('db.status') }}</th>
                                            <th>{{ __('db.grand total') }}</th>
                                        </tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                        </div>
                        <div role="tabpanel" class="tab-pane fade" id="quotation-latest">
                            <div class="table-responsive">
                                <table id="recent-quotation" class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>{{ __('db.date') }}</th>
                                            <th>{{ __('db.reference') }}</th>
                                            <th>{{ __('db.customer') }}</th>
                                            <th>{{ __('db.status') }}</th>
                                            <th>{{ __('db.grand total') }}</th>
                                        </tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                        </div>
                        <div role="tabpanel" class="tab-pane fade" id="payment-latest">
                            <div class="table-responsive">
                                <table id="recent-payment" class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>{{ __('db.date') }}</th>
                                            <th>{{ __('db.reference') }}</th>
                                            <th>{{ __('db.Amount') }}</th>
                                            <th>{{ __('db.Paid By') }}</th>
                                        </tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right: Critical Inventory Health & Best Sellers -->
        <div class="col-lg-5 col-md-12 mb-3">
            <!-- Critical Stock Alerts -->
            <div class="card mb-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-warning text-warning mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">Critical Stock Alerts</h4>
                    </div>
                    @if($low_stock_count > 0)
                        <span class="badge badge-danger">{{ $low_stock_count }} Low Stock</span>
                    @else
                        <span class="badge badge-success">Inventory Healthy</span>
                    @endif
                </div>
                <div class="card-body pt-1 pb-2">
                    @if(isset($low_stock_products) && count($low_stock_products) > 0)
                    <div class="table-responsive">
                        <table class="table table-sm">
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th>Warehouse</th>
                                    <th>Stock</th>
                                    <th>Threshold</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($low_stock_products as $item)
                                <tr>
                                    <td>
                                        <div class="font-weight-bold u-fs-12_5px">{{ $item->name }}</div>
                                        <small class="text-muted">[{{ $item->code }}]</small>
                                    </td>
                                    <td><span class="badge badge-secondary">{{ $item->warehouse_name }}</span></td>
                                    <td><span class="badge badge-danger">{{ $item->qty }}</span></td>
                                    <td><span class="text-muted u-fs-12px">{{ $item->alert_quantity }}</span></td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    @else
                    <div class="text-center py-3 text-muted">
                        <i class="dripicons-checkmark text-success mr-1 u-fs-20px"></i>
                        <p class="mb-0 mt-1 u-fs-12_5px">All items are comfortably stocked above reorder thresholds.</p>
                    </div>
                    @endif
                </div>
            </div>

            <!-- Best Sellers (Monthly) -->
            <div class="card mb-0">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-star text-warning mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.Best Seller') . ' ' . date('F') }}</h4>
                    </div>
                    <div class="badge badge-primary font-weight-semibold">{{ __('db.top') }} 5</div>
                </div>
                <div class="table-responsive">
                    <table id="monthly-best-selling-qty" class="table table-sm mb-0">
                        <thead>
                            <tr>
                                <th>{{ __('db.Product Details') }}</th>
                                <th>{{ __('db.qty') }}</th>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
</div>

<div data-step-title="Yearly &amp; best sellers">
<!-- Annual Commercial Growth Section (Collapsible / Compact) -->
<div class="container-fluid mb-4">
    <div class="row">
        @php
            $yearly_report = $role_has_permissions_list->where('name', 'yearly_report')->first();
        @endphp
        @if ($yearly_report)
        <div class="col-md-12 mb-3">
            <div class="card mb-0">
                <div class="card-header d-flex align-items-center justify-content-between">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-calendar text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.yearly report') }} &bull; Commercial Annual Velocity</h4>
                    </div>
                    <span class="badge badge-primary font-weight-semibold">{{ date('Y') }} Fiscal</span>
                </div>
                <div class="card-body pt-1 pb-2 u-ov-hidden">
                    <div class="zolo-yearly-box u-pos-relative u-h-210px u-maxh-210px u-w-100pct u-ov-hidden">
                        <canvas id="saleChart" height="210"
                            data-sale_chart_value = "{{ json_encode($yearly_sale_amount) }}"
                            data-purchase_chart_value = "{{ json_encode($yearly_purchase_amount) }}"
                            data-label1="{{ __('db.Purchased Amount') }}"
                            data-label2="{{ __('db.Sold Amount') }}" class="u-maxh-210px u-w-100pct u-d-block"></canvas>
                    </div>
                </div>
            </div>
        </div>
        @endif

        <div class="col-md-6 mb-3">
            <div class="card mb-0 h-100">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-trophy text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.Best Seller') . ' ' . date('Y') . ' (' . __('db.qty') . ')' }}</h4>
                    </div>
                    <div class="badge badge-primary font-weight-semibold">{{ __('db.top') }} 5</div>
                </div>
                <div class="table-responsive">
                    <table id="yearly-best-selling-qty" class="table table-sm mb-0">
                        <thead>
                            <tr>
                                <th>{{ __('db.Product Details') }}</th>
                                <th>{{ __('db.qty') }}</th>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-3">
            <div class="card mb-0 h-100">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center">
                        <i class="dripicons-jewel text-primary mr-2 u-fs-1_1rem"></i>
                        <h4 class="mb-0">{{ __('db.Best Seller') . ' ' . date('Y') . ' (' . __('db.Price') . ')' }}</h4>
                    </div>
                    <div class="badge badge-primary font-weight-semibold">{{ __('db.top') }} 5</div>
                </div>
                <div class="table-responsive">
                    <table id="yearly-best-selling-price" class="table table-sm mb-0">
                        <thead>
                            <tr>
                                <th>{{ __('db.Product Details') }}</th>
                                <th>{{ __('db.grand total') }}</th>
                            </tr>
                        </thead>
                        <tbody></tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
</div>
</div>

@endsection

@push('scripts')
<script type="text/javascript">
    $(document).ready(function() {
        // Load Annual Best Selling by Price
        $.ajax({
            url: '{{ url('/yearly-best-selling-price') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                var url = '{{ url('/images/product') }}';
                data.forEach(function(item) {
                    var images = item.product_images ? item.product_images.split(',') : ['zummXD2dvAtI.png'];
                    $('#yearly-best-selling-price').find('tbody').append(
                        '<tr><td><div class="d-flex align-items-center"><img src="' +
                        url + '/' + images[0] +
                        '" width="28" height="24" class="mr-2 rounded"> <span class="font-weight-medium">' + item
                        .product_name + '</span> <span class="text-muted ml-1">[' + item.product_code + ']</span></div></td><td class="font-weight-bold">' +
                        (item.total_price / item.exchange_rate).toFixed({{ $general_setting->decimal }}) + '</td></tr>');
                });
            }
        });

        // Load Annual Best Selling by Quantity
        $.ajax({
            url: '{{ url('/yearly-best-selling-qty') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                var url = '{{ url('/images/product') }}';
                data.forEach(function(item) {
                    var images = item.product_images ? item.product_images.split(',') : ['zummXD2dvAtI.png'];
                    $('#yearly-best-selling-qty').find('tbody').append(
                        '<tr><td><div class="d-flex align-items-center"><img src="' +
                        url + '/' + images[0] +
                        '" width="28" height="24" class="mr-2 rounded"> <span class="font-weight-medium">' + item
                        .product_name + '</span> <span class="text-muted ml-1">[' + item.product_code + ']</span></div></td><td class="font-weight-bold">' +
                        item.sold_qty + '</td></tr>');
                });
            }
        });

        // Load Monthly Best Selling by Quantity
        $.ajax({
            url: '{{ url('/monthly-best-selling-qty') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                var url = '{{ url('/images/product') }}';
                data.forEach(function(item) {
                    var images = item.product_images ? item.product_images.split(',') : ['zummXD2dvAtI.png'];
                    $('#monthly-best-selling-qty').find('tbody').append(
                        '<tr><td><div class="d-flex align-items-center"><img src="' +
                        url + '/' + images[0] +
                        '" width="28" height="24" class="mr-2 rounded"> <span class="font-weight-medium">' + item
                        .product_name + '</span> <span class="text-muted ml-1">[' + item.product_code + ']</span></div></td><td class="font-weight-bold">' +
                        item.sold_qty + '</td></tr>');
                });
            }
        });

        // Load Recent Sales Invoices
        $.ajax({
            url: "{{ url('/recent-sale') }}",
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                data.forEach(function(item) {
                    var sale_date = item.created_at ? dateFormat(item.created_at.split('T')[0], '{{ $general_setting->date_format }}') : '';
                    var status = '';
                    if (item.sale_status == 1) {
                        status = '<span class="badge badge-success">{{ __('db.Completed') }}</span>';
                    } else if (item.sale_status == 2) {
                        status = '<span class="badge badge-danger">{{ __('db.Pending') }}</span>';
                    } else {
                        status = '<span class="badge badge-warning">{{ __('db.Draft') }}</span>';
                    }
                    $('#recent-sale').find('tbody').append('<tr><td>' + sale_date +
                        '</td><td><span class="font-weight-medium text-primary">' + item.reference_no + '</span></td><td>' + item.name +
                        '</td><td>' + status + '</td><td class="font-weight-bold">' + (item.grand_total/item.exchange_rate).toString()
                        .replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '</td></tr>');
                });
            }
        });

        // Load Recent Purchases
        $.ajax({
            url: '{{ url('/recent-purchase') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                data.forEach(function(item) {
                    var payment_date = item.created_at ? dateFormat(item.created_at.split('T')[0], '{{ $general_setting->date_format }}') : '';
                    var status = '';
                    if (item.status == 1) {
                        status = '<span class="badge badge-success">{{ __('db.Recieved') }}</span>';
                    } else if (item.status == 2) {
                        status = '<span class="badge badge-danger">{{ __('db.Partial') }}</span>';
                    } else if (item.status == 3) {
                        status = '<span class="badge badge-danger">{{ __('db.Pending') }}</span>';
                    } else {
                        status = '<span class="badge badge-warning">{{ __('db.Ordered') }}</span>';
                    }
                    $('#recent-purchase').find('tbody').append('<tr><td>' + payment_date +
                        '</td><td><span class="font-weight-medium text-primary">' + item.reference_no + '</span></td><td>' + (item.name || 'N/A') +
                        '</td><td>' + status + '</td><td class="font-weight-bold">' + (item.grand_total/item.exchange_rate).toString()
                        .replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '</td></tr>');
                });
            }
        });

        // Load Recent Quotations
        $.ajax({
            url: '{{ url('/recent-quotation') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                data.forEach(function(item) {
                    var quotation_date = item.created_at ? dateFormat(item.created_at.split('T')[0], '{{ $general_setting->date_format }}') : '';
                    var status = item.quotation_status == 1 ? '<span class="badge badge-success">{{ __('db.Pending') }}</span>' : '<span class="badge badge-danger">{{ __('db.Sent') }}</span>';
                    $('#recent-quotation').find('tbody').append('<tr><td>' + quotation_date + '</td><td><span class="font-weight-medium text-primary">' + item.reference_no + '</span></td><td>' + item.name + '</td><td>' + status + '</td><td class="font-weight-bold">' + item.grand_total.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + '</td></tr>');
                });
            }
        });

        // Load Recent Payments
        $.ajax({
            url: '{{ url('/recent-payment') }}',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                data.forEach(function(item) {
                    var payment_date = item.created_at ? dateFormat(item.created_at.split('T')[0], '{{ $general_setting->date_format }}') : '';
                    $('#recent-payment').find('tbody').append('<tr><td>' + payment_date +
                        '</td><td><span class="font-weight-medium text-primary">' + item.payment_reference + '</span></td><td class="font-weight-bold">' + (item.amount/item.exchange_rate)
                        .toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") +
                        '</td><td><span class="badge badge-info">' + item.paying_method + '</span></td></tr>');
                });
            }
        });
    });

    function dateFormat(inputDate, format) {
        const date = new Date(inputDate);
        const day = date.getDate();
        const month = date.getMonth() + 1;
        const year = date.getFullYear();
        format = format.replace("m", month.toString().padStart(2, "0"));
        format = format.replace("Y", year.toString());
        format = format.replace("d", day.toString().padStart(2, "0"));
        return format;
    }

    $(".date-btn").on("click", function() {
        $(".date-btn").removeClass("active");
        $(this).addClass("active");
        var start_date = $(this).data('start_date');
        var end_date = $(this).data('end_date');
        var warehouse_id = $("#warehouse_btn").val();
        $.get('dashboard-filter/' + start_date + '/' + end_date + '/' + warehouse_id, function(data) {
            dashboardFilter(data);
        });
    });

    $("#warehouse_btn").on("change", function() {
        var warehouse_id = $(this).val();
        var start_date = $('.date-btn.active').data('start_date');
        var end_date = $('.date-btn.active').data('end_date');
        $.get('dashboard-filter/' + start_date + '/' + end_date + '/' + warehouse_id, function(data) {
            dashboardFilter(data);
        });
    });

    function dashboardFilter(data) {
        // data array:
        // [0: revenue, 1: return, 2: profit, 3: purchase_return, 4: total_sale, 5: invoice_due, 6: purchase - return, 7: purchase_due, 8: expense]
        var fields = ['revenue', 'return', 'profit', 'purchase_return', 'total_sale', 'invoice-due', 'total_purchase', 'purchase_due', 'expense'];
        fields.forEach(function(name, i) {
            if (data[i] !== undefined) showKpi('.' + name + '-data', data[i]);
        });
        fitKpiValues();
    }

    // KPI amounts: grouped in the company currency's style; from one lakh (1,00,000) up they show compact
    // (1.33L, 2.4Cr) so they fit the card, and the exact figure is the hover title.
    var kpiDecimals = {{ (int) $general_setting->decimal }};
    var kpiSymbol = @json($currency_symbol);
    var kpiLocale = kpiSymbol === '₹' ? 'en-IN' : 'en';
    function setKpi(el, value) {
        var n = Number(value) || 0;
        var full = n.toLocaleString(kpiLocale, {minimumFractionDigits: kpiDecimals, maximumFractionDigits: kpiDecimals});
        el.textContent = Math.abs(n) >= 100000
            ? new Intl.NumberFormat(kpiLocale, {notation: 'compact', minimumFractionDigits: 2, maximumFractionDigits: 2}).format(n) : full;
        el.title = kpiSymbol + full;
    }
    function showKpi(selector, value) {
        $(selector).each(function() { setKpi(this, value); }).hide().fadeIn(300);
    }
    // Long figures shrink the value text instead of being cut off at the card edge.
    function fitKpiValues() {
        document.querySelectorAll('.dashboard-counts .zolo-kpi-value').forEach(function(box) {
            box.style.fontSize = '';
            var size = parseFloat(getComputedStyle(box).fontSize);
            while (box.scrollWidth > box.clientWidth && size > 11) {
                size -= 1;
                box.style.setProperty('font-size', size + 'px', 'important');
            }
        });
    }
    $('.dashboard-counts .count-number, .return-data, .purchase_return-data, .stock-value-data').each(function() {
        setKpi(this, parseFloat(this.textContent));
    });
    fitKpiValues();
    $(window).on('load resize', fitKpiValues);
</script>
@endpush
