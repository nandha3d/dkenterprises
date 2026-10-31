@extends('backend.layout.main')
@section('content')

@if(session()->has('message'))
    <div class="alert alert-success alert-dismissible text-center">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        {{ session()->get('message') }}
    </div>
@endif

<section class="forms">
    <div class="container-fluid">
        @if($industry === 'packaged_water')
            {{-- ========================================================================= --}}
            {{-- VERTICAL: PACKAGED DRINKING WATER & 20L CAN DISTRIBUTION (DK WATERS)      --}}
            {{-- ========================================================================= --}}
            <!-- Header -->
            <div class="row align-items-center mb-4">
                <div class="col-md-7 d-flex align-items-center">
                    @if(!empty($general_setting->site_logo))
                        <img src="{{url('logo', $general_setting->site_logo)}}" class="mr-3 rounded u-maxh-48px u-maxw-140px u-of-contain" alt="{{$general_setting->site_title ?? 'Logo'}}">
                    @endif
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <h3 class="font-weight-bold text-dark m-0">20L Can Route Distribution &amp; Logistics</h3>
                            <span class="badge badge-success px-2 py-1 ml-2"><i class="dripicons-drop"></i> Packaged Water Vertical</span>
                        </div>
                        <p class="text-muted small m-0">Tata Ace daily beat route distribution, morning loaded stock, can deliveries, empty container return ledger, and anti-theft security deposits.</p>
                    </div>
                </div>
                <div class="col-md-5 text-right">
                    <a href="{{ route('fleet.tracking') }}" class="btn btn-outline-primary btn-sm mr-2">
                        <i class="fa fa-map-marker"></i> Live Route GPS
                    </a>
                    <a href="{{ route('water-logistics.credit-aging') }}" class="btn btn-outline-danger btn-sm mr-2">
                        <i class="dripicons-time-reverse"></i> Customer Credit Aging
                    </a>
                    <button type="button" class="btn btn-success btn-sm" data-toggle="modal" data-target="#canDeliveryModal">
                        <i class="dripicons-plus"></i> 20L Can Delivery
                    </button>
                </div>
            </div>

            <!-- KPI Metrics (Packaged Water Specific) -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">20L Cans Distributed</span>
                        <h3 class="font-weight-bold text-success m-0 mt-1">{{ number_format($totalCanDeliveries) }} Cans</h3>
                        <small class="text-muted">Tata Ace daily beat deliveries</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Customer Cans in Custody</span>
                        <h3 class="font-weight-bold text-dark m-0 mt-1">{{ number_format($totalCansHeld) }} Cans</h3>
                        <small class="text-info">In active market circulation</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Anti-Theft Deposit Balance</span>
                        <h3 class="font-weight-bold text-primary m-0 mt-1">₹ {{ number_format($totalDepositHeld, 2) }}</h3>
                        <small class="text-muted">Container anti-loss security fund</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Can Route Revenue Billed</span>
                        <h3 class="font-weight-bold text-dark m-0 mt-1">₹ {{ number_format($totalCanRevenue, 2) }}</h3>
                        <small class="text-success">Synchronized with GL 4010</small>
                    </div>
                </div>
            </div>

            <!-- Tabs: 20L Can Specific Workspaces -->
            <div class="card border-0 shadow-sm rounded-lg">
                <div class="card-header bg-white border-0 py-3">
                    <ul class="nav nav-tabs card-header-tabs" role="tablist">
                        <li class="nav-item">
                            <a class="nav-link active font-weight-bold" data-toggle="tab" href="#tab-can-deliveries" role="tab">
                                <i class="dripicons-drop text-success mr-1"></i> Daily Can Route Deliveries &amp; Manifests
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" data-toggle="tab" href="#tab-can-inventory" role="tab">
                                <i class="dripicons-stack text-primary mr-1"></i> Customer Container Balances &amp; Deposit Ledger
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" data-toggle="tab" href="#tab-can-routes" role="tab">
                                <i class="dripicons-direction text-info mr-1"></i> Active Beat Routes &amp; Vehicles (Tata Ace)
                            </a>
                        </li>
                    </ul>
                </div>
                <div class="card-body p-4">
                    <div class="tab-content">
                        <!-- Tab 1: Daily Can Deliveries -->
                        <div class="tab-pane fade show active" id="tab-can-deliveries" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Delivery No</th>
                                            <th>Date</th>
                                            <th>Beat Route</th>
                                            <th>Customer</th>
                                            <th>Morning Loaded</th>
                                            <th>Delivered</th>
                                            <th>Empty Returned</th>
                                            <th>Rate</th>
                                            <th>Total</th>
                                            <th>Paid / Mode</th>
                                            <th>Live Cans Held</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($deliveries as $del)
                                            <tr>
                                                <td><span class="badge badge-secondary px-2 py-1 font-mono">{{ $del->delivery_no }}</span></td>
                                                <td>{{ $del->delivery_date }}</td>
                                                <td><strong>{{ $del->route->route_name ?? 'Route Beat' }}</strong></td>
                                                <td>{{ $del->customer->name ?? 'Customer' }}</td>
                                                <td>{{ $del->morning_loaded_cans ?? 70 }}</td>
                                                <td class="font-weight-bold text-success">+{{ $del->cans_delivered }}</td>
                                                <td class="font-weight-bold text-info">-{{ $del->empty_cans_returned }}</td>
                                                <td>₹ {{ number_format($del->can_rate, 2) }}</td>
                                                <td class="font-weight-bold">₹ {{ number_format($del->total_amount, 2) }}</td>
                                                <td>
                                                    <span class="text-success font-weight-bold">₹ {{ number_format($del->paid_amount, 2) }}</span>
                                                    <small class="badge badge-light border ml-1">{{ $del->payment_mode }}</small>
                                                </td>
                                                <td><span class="badge badge-dark px-2 py-1">{{ $del->balance_cans_held }} Cans</span></td>
                                                <td><span class="badge badge-success px-2 py-1">{{ ucfirst($del->status) }}</span></td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="12" class="text-center text-muted py-4">No 20L can route deliveries recorded yet. Click "+ 20L Can Delivery" to log a beat delivery.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Tab 2: Customer Can Inventory & Anti-Theft Ledger -->
                        <div class="tab-pane fade" id="tab-can-inventory" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Customer Name</th>
                                            <th>Contact Phone</th>
                                            <th>Total Cans Held (Custody)</th>
                                            <th>Deposit Held (₹)</th>
                                            <th>Last Delivery Date</th>
                                            <th>Anti-Theft Variance</th>
                                            <th>Audit Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($canInventories as $inv)
                                            <tr>
                                                <td><strong>{{ $inv->customer_name ?? 'Customer #' . $inv->customer_id }}</strong></td>
                                                <td>{{ $inv->phone_number ?? 'N/A' }}</td>
                                                <td><span class="badge badge-primary px-2 py-1">{{ $inv->total_cans_held }} Cans in Hand</span></td>
                                                <td class="font-weight-bold">₹ {{ number_format($inv->deposit_held, 2) }}</td>
                                                <td>{{ $inv->last_delivery_date ? \Carbon\Carbon::parse($inv->last_delivery_date)->format('Y-m-d') : 'No deliveries' }}</td>
                                                <td>
                                                    @if($inv->can_variance_detected > 0)
                                                        <span class="badge badge-danger px-2 py-1"><i class="fa fa-exclamation-triangle"></i> {{ $inv->can_variance_detected }} Missing Cans</span>
                                                    @else
                                                        <span class="badge badge-light border text-success"><i class="fa fa-check"></i> Balanced (0)</span>
                                                    @endif
                                                </td>
                                                <td>
                                                    @if($inv->total_cans_held > 0 && $inv->deposit_held < ($inv->total_cans_held * 150))
                                                        <span class="badge badge-warning px-2 py-1">Partial Deposit Risk</span>
                                                    @else
                                                        <span class="badge badge-success px-2 py-1">Fully Collateralized</span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="7" class="text-center text-muted py-4">No customer container balances recorded yet.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Tab 3: Beat Routes & Vehicles -->
                        <div class="tab-pane fade" id="tab-can-routes" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Route Name</th>
                                            <th>Assigned Vehicle</th>
                                            <th>Driver Name</th>
                                            <th>Driver Contact</th>
                                            <th>Daily Avg Cans</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($routes as $rt)
                                            <tr>
                                                <td><strong>{{ $rt->route_name }}</strong></td>
                                                <td><span class="badge badge-dark px-2 py-1 font-mono">{{ $rt->vehicle_no ?? 'Tata Ace' }}</span></td>
                                                <td>{{ $rt->driver_name ?? 'Assigned Beat Driver' }}</td>
                                                <td>{{ $rt->driver_phone ?? 'N/A' }}</td>
                                                <td class="font-weight-bold text-info">{{ $rt->daily_avg_cans }} Cans/Day</td>
                                                <td>
                                                    @if($rt->is_active)
                                                        <span class="badge badge-success px-2 py-1">Active Beat</span>
                                                    @else
                                                        <span class="badge badge-secondary px-2 py-1">Inactive</span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="6" class="text-center text-muted py-4">No distribution routes registered yet.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Modal: 20L Can Delivery Modal -->
            <div id="canDeliveryModal" tabindex="-1" role="dialog" aria-hidden="true" class="modal fade text-left">
                <div role="document" class="modal-dialog modal-dialog-centered">
                    <div class="modal-content border-0 shadow-lg">
                        <form action="{{ route('water-logistics.can.store') }}" method="POST">
                            @csrf
                            <div class="modal-header bg-dark text-white border-0 py-3">
                                <h5 class="modal-title font-weight-bold">Log 20L Can Route Delivery</h5>
                                <button type="button" data-dismiss="modal" class="close text-white opacity-75"><span>&times;</span></button>
                            </div>
                            <div class="modal-body p-4">
                                <div class="row">
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Delivery Route (Tata Ace) *</label>
                                        <select name="route_id" class="form-control" required>
                                            @foreach($routes as $rt)
                                                <option value="{{ $rt->id }}">{{ $rt->route_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Customer *</label>
                                        <select name="customer_id" class="form-control selectpicker" data-live-search="true" required>
                                            @foreach($customers as $c)
                                                <option value="{{ $c->id }}">{{ $c->name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Cans Delivered *</label>
                                        <input type="number" min="1" name="cans_delivered" class="form-control" value="10" required>
                                    </div>
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Empty Cans Returned *</label>
                                        <input type="number" min="0" name="empty_cans_returned" class="form-control" value="8" required>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Rate per Can (₹)</label>
                                        <input type="number" step="any" name="can_rate" class="form-control" value="35.00" required>
                                    </div>
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Paid Amount (₹)</label>
                                        <input type="number" step="any" name="paid_amount" class="form-control" value="350.00" required>
                                    </div>
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Payment Mode</label>
                                        <select name="payment_mode" class="form-control">
                                            <option value="Cash">Cash</option>
                                            <option value="UPI">UPI / QR</option>
                                            <option value="Credit">Corporate Credit</option>
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div class="modal-footer border-0 p-3 bg-light">
                                <button type="button" class="btn btn-secondary px-4" data-dismiss="modal">Cancel</button>
                                <button type="submit" class="btn btn-success px-4 font-weight-bold">Confirm Can Delivery</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

        @elseif($industry === 'bulk_water')
            {{-- ========================================================================= --}}
            {{-- VERTICAL: COMMERCIAL BULK WATER & TANKER FLEET (TMWS)                      --}}
            {{-- ========================================================================= --}}
            <!-- Header -->
            <div class="row align-items-center mb-4">
                <div class="col-md-7 d-flex align-items-center">
                    @if(!empty($general_setting->site_logo))
                        <img src="{{url('logo', $general_setting->site_logo)}}" class="mr-3 rounded u-maxh-48px u-maxw-140px u-of-contain" alt="{{$general_setting->site_title ?? 'Logo'}}">
                    @endif
                    <div>
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <h3 class="font-weight-bold text-dark m-0">Commercial Bulk Water &amp; Fleet Logistics</h3>
                            <span class="badge badge-primary px-2 py-1 ml-2"><i class="dripicons-truck"></i> Bulk Water Vertical</span>
                        </div>
                        <p class="text-muted small m-0">Commercial bulk tanker fleet dispatch, multi-compartment chamber decanting, diesel &amp; driver batta expenses, and GPS telematics.</p>
                    </div>
                </div>
                <div class="col-md-5 text-right">
                    <a href="{{ route('fleet.tracking') }}" class="btn btn-outline-primary btn-sm mr-2">
                        <i class="fa fa-map-marker"></i> Live Fleet GPS
                    </a>
                    <a href="{{ route('water-logistics.credit-aging') }}" class="btn btn-outline-danger btn-sm mr-2">
                        <i class="dripicons-time-reverse"></i> Credit Aging Board
                    </a>
                    <button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#tankerTripModal">
                        <i class="dripicons-plus"></i> Log Tanker Trip
                    </button>
                </div>
            </div>

            <!-- KPI Metrics (Bulk Water Specific) -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Total Tanker Trips</span>
                        <h3 class="font-weight-bold text-dark m-0 mt-1">{{ number_format($totalTankerTrips) }}</h3>
                        <small class="text-info">Dispatched fleet trips</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Total Water Delivered</span>
                        <h3 class="font-weight-bold text-primary m-0 mt-1">{{ number_format($totalWaterDispatchedKl, 1) }} KL</h3>
                        <small class="text-muted">{{ number_format($totalWaterDispatchedKl * 1000) }} Liters decanted</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Fleet Revenue Billed</span>
                        <h3 class="font-weight-bold text-dark m-0 mt-1">₹ {{ number_format($totalTankerRevenue, 2) }}</h3>
                        <small class="text-success">Synchronized with GL 4010</small>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card border-0 shadow-sm rounded-lg p-3 bg-white">
                        <span class="small text-muted font-weight-600">Diesel &amp; Driver Batta</span>
                        <h3 class="font-weight-bold text-danger m-0 mt-1">₹ {{ number_format($totalTankerExpenses, 2) }}</h3>
                        <small class="text-muted">Trip disbursements (GL 5020)</small>
                    </div>
                </div>
            </div>

            <!-- Tabs: Bulk Tanker Specific Workspaces -->
            <div class="card border-0 shadow-sm rounded-lg">
                <div class="card-header bg-white border-0 py-3">
                    <ul class="nav nav-tabs card-header-tabs" role="tablist">
                        <li class="nav-item">
                            <a class="nav-link active font-weight-bold" data-toggle="tab" href="#tab-tankers" role="tab">
                                <i class="dripicons-truck text-primary mr-1"></i> Dispatched Tanker Trip Sheets &amp; Registry
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" data-toggle="tab" href="#tab-tanker-fleet" role="tab">
                                <i class="dripicons-view-thumb text-info mr-1"></i> Heavy Tanker Fleet &amp; Chamber Config
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link font-weight-bold" data-toggle="tab" href="#tab-trip-reconciliation" role="tab">
                                <i class="dripicons-wallet text-warning mr-1"></i> Fuel &amp; Trip Expense Reconciliation
                            </a>
                        </li>
                    </ul>
                </div>
                <div class="card-body p-4">
                    <div class="tab-content">
                        <!-- Tab 1: Tanker Trips -->
                        <div class="tab-pane fade show active" id="tab-tankers" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Trip No</th>
                                            <th>Date</th>
                                            <th>Tanker Vehicle</th>
                                            <th>Customer / Destination Site</th>
                                            <th>Water Qty (KL)</th>
                                            <th>Billed Rate</th>
                                            <th>Diesel</th>
                                            <th>Driver Batta</th>
                                            <th>Site Receiver</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($trips as $trip)
                                            <tr>
                                                <td><span class="badge badge-secondary px-2 py-1 font-mono">{{ $trip->trip_number }}</span></td>
                                                <td>{{ $trip->trip_date }}</td>
                                                <td><strong>{{ $trip->tanker->vehicle_number ?? 'N/A' }}</strong> ({{ $trip->tanker->capacity_kl }} KL)</td>
                                                <td>{{ $trip->customer->name ?? 'N/A' }} <div class="small text-muted">{{ $trip->destination_site }}</div></td>
                                                <td class="font-weight-bold text-primary">{{ $trip->water_quantity_kl }} KL</td>
                                                <td class="font-weight-bold">₹ {{ number_format($trip->trip_rate, 2) }}</td>
                                                <td class="text-danger">₹ {{ number_format($trip->diesel_expense, 2) }}</td>
                                                <td class="text-warning">₹ {{ number_format($trip->driver_batta, 2) }}</td>
                                                <td>{{ $trip->site_receiver_name ?: 'Verified' }}</td>
                                                <td><span class="badge badge-success px-2 py-1">{{ ucfirst($trip->status) }}</span></td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="10" class="text-center text-muted py-4">No tanker trips logged. Click "+ Log Tanker Trip" to record a delivery trip.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Tab 2: Tanker Fleet Config -->
                        <div class="tab-pane fade" id="tab-tanker-fleet" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Vehicle Registration</th>
                                            <th>Model / Chassis</th>
                                            <th>Capacity (KL)</th>
                                            <th>Capacity (Liters)</th>
                                            <th>Assigned Driver</th>
                                            <th>Driver Phone</th>
                                            <th>Telematics Status</th>
                                            <th>Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($tankers as $tnk)
                                            <tr>
                                                <td><span class="badge badge-dark px-2 py-1 font-mono">{{ $tnk->vehicle_number }}</span></td>
                                                <td>{{ $tnk->model_type ?? 'Heavy Commercial Tanker' }}</td>
                                                <td class="font-weight-bold text-primary">{{ $tnk->capacity_kl }} KL</td>
                                                <td>{{ number_format($tnk->capacity_liters ?? ($tnk->capacity_kl * 1000)) }} L</td>
                                                <td>{{ $tnk->driver_name ?? 'Fleet Driver' }}</td>
                                                <td>{{ $tnk->driver_phone ?? 'N/A' }}</td>
                                                <td>
                                                    @if(!empty($tnk->latitude) && !empty($tnk->longitude))
                                                        <span class="badge badge-success px-2 py-1"><i class="fa fa-wifi"></i> GPS Online</span>
                                                    @else
                                                        <span class="badge badge-secondary px-2 py-1">Standby</span>
                                                    @endif
                                                </td>
                                                <td>
                                                    @if($tnk->is_active)
                                                        <span class="badge badge-success px-2 py-1">Active Fleet</span>
                                                    @else
                                                        <span class="badge badge-danger px-2 py-1">Maintenance</span>
                                                    @endif
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="8" class="text-center text-muted py-4">No tanker vehicles registered in fleet yet.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Tab 3: Fuel & Expense Reconciliation -->
                        <div class="tab-pane fade" id="tab-trip-reconciliation" role="tabpanel">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="bg-light small uppercase">
                                        <tr>
                                            <th>Trip Number</th>
                                            <th>Trip Date</th>
                                            <th>Vehicle Number</th>
                                            <th>Gross Revenue</th>
                                            <th>Diesel Disbursed</th>
                                            <th>Driver Batta</th>
                                            <th>Toll Expense</th>
                                            <th>Net Trip Contribution</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($trips as $trip)
                                            @php
                                                $exp = ($trip->diesel_expense ?? 0) + ($trip->driver_batta ?? 0) + ($trip->toll_expense ?? 0);
                                                $margin = ($trip->trip_rate ?? 0) - $exp;
                                            @endphp
                                            <tr>
                                                <td><span class="badge badge-secondary px-2 py-1 font-mono">{{ $trip->trip_number }}</span></td>
                                                <td>{{ $trip->trip_date }}</td>
                                                <td>{{ $trip->tanker->vehicle_number ?? 'N/A' }}</td>
                                                <td class="font-weight-bold text-success">₹ {{ number_format($trip->trip_rate, 2) }}</td>
                                                <td class="text-danger">₹ {{ number_format($trip->diesel_expense, 2) }}</td>
                                                <td class="text-warning">₹ {{ number_format($trip->driver_batta, 2) }}</td>
                                                <td>₹ {{ number_format($trip->toll_expense, 2) }}</td>
                                                <td class="font-weight-bold {{ $margin >= 0 ? 'text-primary' : 'text-danger' }}">
                                                    ₹ {{ number_format($margin, 2) }}
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="8" class="text-center text-muted py-4">No trip expense data available for reconciliation.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Modal: Tanker Trip Modal -->
            <div id="tankerTripModal" tabindex="-1" role="dialog" aria-hidden="true" class="modal fade text-left">
                <div role="document" class="modal-dialog modal-dialog-centered">
                    <div class="modal-content border-0 shadow-lg">
                        <form action="{{ route('water-logistics.trip.store') }}" method="POST">
                            @csrf
                            <div class="modal-header bg-dark text-white border-0 py-3">
                                <h5 class="modal-title font-weight-bold">Log Water Tanker Trip Sheet</h5>
                                <button type="button" data-dismiss="modal" class="close text-white opacity-75"><span>&times;</span></button>
                            </div>
                            <div class="modal-body p-4">
                                <div class="row">
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Select Tanker Vehicle *</label>
                                        <select name="tanker_id" class="form-control" required>
                                            @foreach($tankers as $tnk)
                                                <option value="{{ $tnk->id }}">{{ $tnk->vehicle_number }} ({{ $tnk->capacity_kl }} KL)</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Select Customer / Client *</label>
                                        <select name="customer_id" class="form-control selectpicker" data-live-search="true" required>
                                            @foreach($customers as $c)
                                                <option value="{{ $c->id }}">{{ $c->name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Destination Site *</label>
                                        <input type="text" name="destination_site" class="form-control" placeholder="Factory / Site location" required>
                                    </div>
                                    <div class="col-md-6 form-group mb-3">
                                        <label class="font-weight-600 small">Delivered Qty (KL) *</label>
                                        <input type="number" step="0.1" min="0.1" name="water_quantity_kl" id="tanker_delivered_qty_kl" class="form-control" placeholder="Delivered Quantity in KL" required>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Trip Rate (₹) *</label>
                                        <input type="number" step="any" name="trip_rate" class="form-control" value="2500" required>
                                    </div>
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Diesel (₹)</label>
                                        <input type="number" step="any" name="diesel_expense" class="form-control" value="650">
                                    </div>
                                    <div class="col-md-4 form-group mb-3">
                                        <label class="font-weight-600 small">Driver Batta (₹)</label>
                                        <input type="number" step="any" name="driver_batta" class="form-control" value="300">
                                    </div>
                                </div>

                                <div class="form-group mb-0">
                                    <label class="font-weight-600 small">Site Receiver Name / Contact</label>
                                    <input type="text" name="site_receiver_name" class="form-control" placeholder="Name of site engineer or incharge">
                                </div>
                            </div>
                            <div class="modal-footer border-0 p-3 bg-light">
                                <button type="button" class="btn btn-secondary px-4" data-dismiss="modal">Cancel</button>
                                <button type="submit" class="btn btn-primary px-4 font-weight-bold">Submit Trip Sheet</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>

        @else
            {{-- ========================================================================= --}}
            {{-- DEDICATED VERTICAL SELECTOR: PREVENT PROCESS FLOW CONFLICTS               --}}
            {{-- ========================================================================= --}}
            <div class="row align-items-center mb-4">
                <div class="col-md-8">
                    <h3 class="font-weight-bold text-dark m-0">Water Supply &amp; Logistics Enterprise Gate</h3>
                    <p class="text-muted small m-0">Each company operates an independent process flow. Please select your target operational vertical.</p>
                </div>
            </div>

            <div class="row">
                <!-- Vertical 1: Commercial Bulk Water & Fleet Logistics -->
                <div class="col-md-6 mb-4">
                    <div class="card border-0 shadow-sm rounded-lg p-4 bg-white h-100 d-flex flex-column justify-content-between">
                        <div>
                            <div class="d-flex align-items-center mb-3">
                                <span class="badge badge-primary px-3 py-2 mr-2"><i class="dripicons-truck"></i> Heavy Tankers</span>
                                <h4 class="font-weight-bold m-0 text-dark">Commercial Bulk Water Logistics</h4>
                            </div>
                            <p class="text-muted small">Process flow tailored for <strong>Tiruchendur Murugan Water Supply (TMWS)</strong>:</p>
                            <ul class="text-muted small pl-3 mb-4">
                                <li>Heavy commercial bulk water tanker fleet dispatch</li>
                                <li>Multi-compartment chamber split decanting</li>
                                <li>Fuel (diesel) &amp; driver batta trip disbursement reconciliation</li>
                                <li>Site waiting delay and motor pumping surcharges</li>
                                <li>Live GPS fleet telematics tracking</li>
                            </ul>
                        </div>
                        <a href="{{ route('water-logistics.index', ['vertical' => 'bulk_water']) }}" class="btn btn-primary btn-block font-weight-bold py-2">
                            <i class="dripicons-arrow-right mr-1"></i> Open Bulk Tanker Operations
                        </a>
                    </div>
                </div>

                <!-- Vertical 2: 20L Can Route Distribution & Logistics -->
                <div class="col-md-6 mb-4">
                    <div class="card border-0 shadow-sm rounded-lg p-4 bg-white h-100 d-flex flex-column justify-content-between">
                        <div>
                            <div class="d-flex align-items-center mb-3">
                                <span class="badge badge-success px-3 py-2 mr-2"><i class="dripicons-drop"></i> 20L Cans</span>
                                <h4 class="font-weight-bold m-0 text-dark">Packaged Drinking Water Distribution</h4>
                            </div>
                            <p class="text-muted small">Process flow tailored for <strong>DK Waters (DKWATERS)</strong>:</p>
                            <ul class="text-muted small pl-3 mb-4">
                                <li>Tata Ace daily beat route manifests &amp; morning loaded stock</li>
                                <li>Filled can deliveries and empty container collection</li>
                                <li>Customer empty can custody ledger &amp; anti-theft variance audit</li>
                                <li>Refundable security deposit balance management</li>
                                <li>Beat route van GPS tracking</li>
                            </ul>
                        </div>
                        <a href="{{ route('water-logistics.index', ['vertical' => 'packaged_water']) }}" class="btn btn-success btn-block font-weight-bold py-2">
                            <i class="dripicons-arrow-right mr-1"></i> Open 20L Can Distribution Operations
                        </a>
                    </div>
                </div>
            </div>
        @endif
    </div>
</section>

@endsection
