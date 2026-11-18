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
        <!-- Header & Route Beat Banner -->
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <div class="d-flex align-items-center gap-3 mb-2">
                                <span class="badge badge-success p-2 px-3 text-uppercase font-weight-bold" style="font-size: 13px; letter-spacing: 0.5px;">
                                    <i class="fa fa-truck mr-1"></i> {{ $manifest['vehicle']['vehicle_number'] ?? 'Unassigned Vehicle' }}
                                </span>
                                <span class="badge badge-info p-2 px-3 text-uppercase font-weight-bold" style="font-size: 12px;">
                                    <i class="fa fa-road mr-1"></i> {{ $manifest['route']['name'] ?? 'Unassigned Route' }}
                                </span>
                            </div>
                            <h3 class="font-weight-bold text-dark m-0">20L Packaged Water Distribution Manifest</h3>
                            <p class="text-muted small m-0 mt-1">
                                Driver: <strong>{{ $manifest['driver_name'] ?? 'Unassigned Driver' }}</strong>@if(!empty($manifest['driver_phone'])) ({{ $manifest['driver_phone'] }})@endif
                            </p>
                        </div>
                        <div class="col-md-4 text-right">
                            <a href="{{ route('water-logistics.schedules.index', ['vertical' => 'can']) }}" class="btn btn-outline-info btn-sm mr-2">
                                <i class="fa fa-calendar mr-1"></i> Recurring Schedules
                            </a>
                            <a href="{{ route('fleet.tracking') }}" class="btn btn-outline-primary btn-sm mr-2">
                                <i class="fa fa-map-marker mr-1"></i> Live Route GPS
                            </a>
                            <button type="button" class="btn btn-success btn-sm" data-toggle="modal" data-target="#canOrderModal">
                                <i class="fa fa-plus mr-1"></i> Create Order
                            </button>
                        </div>
                    </div>

                    <!-- Can Inventory Counters Strip -->
                    <div class="row mt-4 pt-3 border-top">
                        <div class="col-md-2 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Loaded Morning</span>
                            <h4 class="font-weight-bold text-dark m-0 mt-1">{{ $manifest['inventory']['loaded_cans'] ?? ($manifest['can_inventory']['loaded_cans'] ?? 0) }}</h4>
                            <small class="text-muted">Full 20L Jars</small>
                        </div>
                        <div class="col-md-2 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Delivered</span>
                            <h4 class="font-weight-bold text-success m-0 mt-1">{{ $manifest['inventory']['delivered_cans'] ?? ($manifest['can_inventory']['delivered_cans'] ?? 0) }}</h4>
                            <small class="text-muted">Jars Supplied</small>
                        </div>
                        <div class="col-md-2 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Empty Collected</span>
                            <h4 class="font-weight-bold text-primary m-0 mt-1">{{ $manifest['inventory']['empty_cans_collected'] ?? ($manifest['can_inventory']['empty_cans_on_truck'] ?? 0) }}</h4>
                            <small class="text-muted">Returned Empty</small>
                        </div>
                        <div class="col-md-2 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Return Ratio</span>
                            <h4 class="font-weight-bold text-info m-0 mt-1">{{ $manifest['inventory']['empty_return_ratio'] ?? '100%' }}</h4>
                            <small class="text-muted">Audit Threshold: &gt;90%</small>
                        </div>
                        <div class="col-md-2 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Remaining in Van</span>
                            <h4 class="font-weight-bold text-warning m-0 mt-1">{{ $manifest['inventory']['remaining_cans'] ?? ($manifest['can_inventory']['remaining_full_cans'] ?? 0) }}</h4>
                            <small class="text-muted">Available Stock</small>
                        </div>
                        <div class="col-md-2 text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Route Cash in Van</span>
                            <h4 class="font-weight-bold text-success m-0 mt-1">₹ {{ number_format($manifest['inventory']['cash_collected'] ?? ($manifest['cash']['cash_collected_today'] ?? 0), 2) }}</h4>
                            <small class="text-muted">Ready for surrender</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Open Booked Can Orders (Two-Stage Order Workflow) -->
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h5 class="font-weight-bold text-dark m-0">
                                <i class="fa fa-clipboard text-primary mr-2"></i> Open Can Orders ({{ count($manifest['pending_orders'] ?? []) }})
                            </h5>
                            <p class="text-muted small m-0">Step 1: Create Sales Order (notifies owner) → Step 2: Adjust if needed or Start Moving → Step 3: Close into Sales Bill at customer location</p>
                        </div>
                        <button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#canOrderModal">
                            <i class="fa fa-plus mr-1"></i> Create Order
                        </button>
                    </div>
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="bg-light">
                                <tr>
                                    <th class="border-0">Order #</th>
                                    <th class="border-0">Customer</th>
                                    <th class="border-0 text-center">Ordered Cans</th>
                                    <th class="border-0 text-right">Est. Amount</th>
                                    <th class="border-0 text-center">Status</th>
                                    <th class="border-0 text-right">Workflow Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($manifest['pending_orders'] ?? [] as $ord)
                                    @php
                                        $ordStatus = strtolower($ord['status'] ?? 'ordered');
                                        $isRegular = !empty($ord['is_regular_scheduled']) || ($ord['order_origin'] ?? '') === 'scheduled';
                                    @endphp
                                    <tr>
                                        <td>
                                            <span class="badge badge-dark px-2 py-1">{{ $ord['sales_order_no'] ?? $ord['order_no'] ?? ('ORD-' . $ord['id']) }}</span>
                                            <div class="mt-1">
                                                <span class="badge {{ $isRegular ? 'badge-info' : 'badge-light border text-dark' }} px-2 py-0" style="font-size: 11px;">
                                                    {{ $ord['schedule_label'] ?? ($isRegular ? 'Regular · Scheduled' : 'Created Today (On-Day)') }}
                                                </span>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="font-weight-bold text-dark">{{ $ord['customer_name'] ?? 'Customer' }}</div>
                                            @if(!empty($ord['order_notes']))<small class="text-muted">{{ $ord['order_notes'] }}</small>@endif
                                        </td>
                                        <td class="text-center font-weight-bold text-primary">{{ $ord['ordered_cans'] ?? 0 }} Cans</td>
                                        <td class="text-right font-weight-bold">₹ {{ number_format($ord['estimated_amount'] ?? 0, 2) }}</td>
                                        <td class="text-center">
                                            <span class="badge {{ $ordStatus === 'in_transit' ? 'badge-primary' : 'badge-warning' }} px-2 py-1 text-uppercase">
                                                {{ str_replace('_', ' ', $ordStatus) }}
                                            </span>
                                        </td>
                                        <td class="text-right">
                                            <button type="button" class="btn btn-outline-secondary btn-sm mr-1" data-toggle="modal" data-target="#adjustCanOrderModal{{ $ord['id'] }}">
                                                <i class="fa fa-sliders mr-1"></i> Adjust
                                            </button>
                                            @if($ordStatus !== 'in_transit')
                                                <form action="{{ route('water-logistics.can-orders.start', $ord['id']) }}" method="POST" class="d-inline">
                                                    @csrf
                                                    <button type="submit" class="btn btn-outline-primary btn-sm mr-1">
                                                        <i class="fa fa-truck mr-1"></i> Start Moving
                                                    </button>
                                                </form>
                                            @endif
                                            <button type="button" class="btn btn-success btn-sm" data-toggle="modal" data-target="#closeOrderModal{{ $ord['id'] }}">
                                                <i class="fa fa-check-circle mr-1"></i> Close &amp; Deliver
                                            </button>
                                        </td>
                                    </tr>

                                    <div class="modal fade" id="adjustCanOrderModal{{ $ord['id'] }}" tabindex="-1" role="dialog" aria-hidden="true">
                                        <div class="modal-dialog modal-dialog-centered" role="document">
                                            <div class="modal-content border-0 shadow-lg rounded-lg">
                                                <form action="{{ route('water-logistics.can-orders.adjust', $ord['id']) }}" method="POST">
                                                    @csrf
                                                    <div class="modal-header bg-info text-white border-0">
                                                        <h5 class="modal-title font-weight-bold">Adjust Sales Order · {{ $ord['customer_name'] ?? '' }}</h5>
                                                        <button type="button" class="close text-white" data-dismiss="modal"><span>&times;</span></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <div class="row">
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Ordered Cans *</label>
                                                                <input type="number" min="1" max="1000" name="ordered_cans" class="form-control" value="{{ $ord['ordered_cans'] ?? 1 }}" required>
                                                            </div>
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Rate per Can (₹)</label>
                                                                <input type="number" step="0.5" min="1" name="can_rate" class="form-control" value="{{ $ord['can_rate'] ?? ($ord['master_can_rate'] ?? 35) }}" required>
                                                            </div>
                                                        </div>
                                                        <div class="row">
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Delivery Date</label>
                                                                <input type="date" name="delivery_date" class="form-control" value="{{ $ord['delivery_date'] ?? now()->toDateString() }}">
                                                            </div>
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Payment Mode</label>
                                                                <select name="payment_mode" class="form-control">
                                                                    <option value="Cash" {{ strtolower($ord['payment_mode'] ?? '') === 'cash' ? 'selected' : '' }}>Cash</option>
                                                                    <option value="UPI" {{ strtolower($ord['payment_mode'] ?? '') === 'upi' ? 'selected' : '' }}>UPI / QR</option>
                                                                    <option value="Credit" {{ strtolower($ord['payment_mode'] ?? '') === 'credit' ? 'selected' : '' }}>Credit</option>
                                                                </select>
                                                            </div>
                                                        </div>
                                                        <div class="form-group">
                                                            <label class="small font-weight-bold">Customization Notes</label>
                                                            <input type="text" name="order_notes" class="form-control" value="{{ $ord['order_notes'] ?? '' }}">
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer border-0 bg-light">
                                                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                                                        <button type="submit" class="btn btn-info btn-sm font-weight-bold">Save Adjusted Sales Order</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="modal fade" id="closeOrderModal{{ $ord['id'] }}" tabindex="-1" role="dialog" aria-hidden="true">
                                        <div class="modal-dialog modal-dialog-centered" role="document">
                                            <div class="modal-content border-0 shadow-lg rounded-lg">
                                                <form action="{{ route('water-logistics.can-orders.close', $ord['id']) }}" method="POST">
                                                    @csrf
                                                    <div class="modal-header bg-dark text-white border-0">
                                                        <h5 class="modal-title font-weight-bold">Close Order {{ $ord['order_no'] ?? '' }} · {{ $ord['customer_name'] ?? '' }}</h5>
                                                        <button type="button" class="close text-white" data-dismiss="modal"><span>&times;</span></button>
                                                    </div>
                                                    <div class="modal-body">
                                                        <input type="hidden" name="route_id" value="{{ $ord['route_id'] ?? ($manifest['route']['id'] ?? 1) }}">
                                                        <div class="row">
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Delivered Cans *</label>
                                                                <input type="number" min="1" name="cans_delivered" class="form-control" value="{{ $ord['ordered_cans'] ?? 1 }}" required>
                                                            </div>
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Empty Cans Returned *</label>
                                                                <input type="number" min="0" name="empty_cans_returned" class="form-control" value="{{ $ord['ordered_cans'] ?? 0 }}" required>
                                                            </div>
                                                        </div>
                                                        <div class="row">
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Rate per Can (₹)</label>
                                                                <input type="number" step="any" min="1" name="can_rate" class="form-control" value="{{ $ord['can_rate'] ?? ($ord['master_can_rate'] ?? 35) }}" required>
                                                            </div>
                                                            <div class="col-md-6 form-group">
                                                                <label class="small font-weight-bold">Payment Mode</label>
                                                                <select name="payment_mode" class="form-control">
                                                                    <option value="Cash" {{ strtolower($ord['payment_mode'] ?? '') === 'cash' ? 'selected' : '' }}>Cash</option>
                                                                    <option value="UPI" {{ strtolower($ord['payment_mode'] ?? '') === 'upi' ? 'selected' : '' }}>UPI / QR</option>
                                                                    <option value="Credit" {{ strtolower($ord['payment_mode'] ?? '') === 'credit' ? 'selected' : '' }}>Credit</option>
                                                                </select>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer border-0 bg-light">
                                                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                                                        <button type="submit" class="btn btn-success btn-sm font-weight-bold">Confirm Delivery &amp; Notify Owner</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center py-3 text-muted">No open customer can orders. Click <strong>Create Order</strong> when a shop asks for cans before moving.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Create 20L Can Sales Order Modal -->
        <div class="modal fade" id="canOrderModal" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content border-0 shadow-lg rounded-lg">
                    <form action="{{ route('water-logistics.can-orders.store') }}" method="POST">
                        @csrf
                        <div class="modal-header bg-primary text-white border-0">
                            <h5 class="modal-title font-weight-bold">Create Customer 20L Can Sales Order (Notifies Owner)</h5>
                            <button type="button" class="close text-white" data-dismiss="modal"><span>&times;</span></button>
                        </div>
                        <div class="modal-body">
                            <input type="hidden" name="route_id" value="{{ $manifest['route']['id'] ?? 1 }}">
                            <div class="form-group">
                                <label class="small font-weight-bold">Customer / Shop *</label>
                                <select name="customer_id" class="form-control" required>
                                    @foreach($manifest['customers'] ?? [] as $cust)
                                        <option value="{{ $cust['id'] }}">{{ $cust['name'] }} ({{ $cust['phone_number'] ?? '' }})</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="row">
                                <div class="col-md-4 form-group">
                                    <label class="small font-weight-bold">Cans Requested *</label>
                                    <input type="number" min="1" max="1000" name="ordered_cans" class="form-control" value="7" required>
                                </div>
                                <div class="col-md-4 form-group">
                                    <label class="small font-weight-bold">Custom Rate (₹/Can)</label>
                                    <input type="number" step="0.5" min="1" name="can_rate" class="form-control" placeholder="Auto">
                                </div>
                                <div class="col-md-4 form-group">
                                    <label class="small font-weight-bold">Payment Mode</label>
                                    <select name="payment_mode" class="form-control">
                                        <option value="Cash">Cash</option>
                                        <option value="UPI">UPI / QR</option>
                                        <option value="Credit">Credit</option>
                                    </select>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6 form-group">
                                    <label class="small font-weight-bold">Delivery Schedule Rule</label>
                                    <select name="schedule_frequency" class="form-control">
                                        <option value="on_day">Today Only (On-Day Sales Order)</option>
                                        <option value="daily">Make Regular: Daily</option>
                                        <option value="every_n_days">Make Regular: Every N Days (2 Days Once)</option>
                                        <option value="weekly">Make Regular: Weekly</option>
                                        <option value="biweekly">Make Regular: Every 2 Weeks</option>
                                        <option value="monthly">Make Regular: Monthly</option>
                                    </select>
                                </div>
                                <div class="col-md-6 form-group">
                                    <label class="small font-weight-bold">Interval Days (if Every N Days)</label>
                                    <input type="number" min="1" max="90" name="interval_days" class="form-control" value="2">
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="small font-weight-bold">Order Notes (Optional)</label>
                                <input type="text" name="order_notes" class="form-control" placeholder="e.g. Customer asked 7 cans urgently">
                            </div>
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" id="canOrderStartNow" name="start_immediately" value="1">
                                <label class="form-check-label small" for="canOrderStartNow">Start Moving immediately toward customer location</label>
                            </div>
                        </div>
                        <div class="modal-footer border-0 bg-light">
                            <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-primary btn-sm font-weight-bold">Create Sales Order &amp; Notify Owner</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Assigned Route Delivery Stops -->
        <div class="row">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h5 class="font-weight-bold text-dark m-0">
                                <i class="fa fa-list-ol text-success mr-2"></i> Route Beat Customer Stops ({{ count($manifest['deliveries'] ?? []) }})
                            </h5>
                            <p class="text-muted small m-0">Sequential beat delivery schedule with customer geolocations</p>
                        </div>
                        <button type="button" class="btn btn-outline-info btn-sm" onclick="window.print()">
                            <i class="fa fa-print mr-1"></i> Print Delivery Sheet
                        </button>
                    </div>

                    <div class="table-responsive">
                        <table class="table table-hover align-middle">
                            <thead class="bg-light">
                                <tr>
                                    <th class="border-0">#</th>
                                    <th class="border-0">Customer / Enterprise</th>
                                    <th class="border-0">Address / Beat Point</th>
                                    <th class="border-0 text-center">Delivered (20L)</th>
                                    <th class="border-0 text-center">Empty Due</th>
                                    <th class="border-0 text-right">Bill Amount</th>
                                    <th class="border-0 text-center">Status</th>
                                    <th class="border-0 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($manifest['deliveries'] ?? [] as $idx => $stop)
                                    <tr>
                                        <td><strong>{{ $idx + 1 }}</strong></td>
                                        <td>
                                            <div class="font-weight-bold text-dark">{{ $stop['customer_name'] }}</div>
                                            <small class="text-muted"><i class="fa fa-phone mr-1"></i> <a href="tel:{{ $stop['phone'] }}">{{ $stop['phone'] }}</a></small>
                                        </td>
                                        <td>
                                            <div class="small text-muted">{{ $stop['address'] }}</div>
                                            @if(!empty($stop['latitude']) && !empty($stop['longitude']))
                                                <span class="badge badge-success px-2 py-1 small" style="font-size: 10px;">
                                                    <i class="fa fa-map-marker mr-1"></i> GPS Locked
                                                </span>
                                            @else
                                                <span class="badge badge-warning px-2 py-1 small" style="font-size: 10px;">
                                                    <i class="fa fa-exclamation-triangle mr-1"></i> Need GPS Pin
                                                </span>
                                            @endif
                                        </td>
                                        <td class="text-center font-weight-bold text-success">{{ $stop['cans_delivered'] ?? 0 }} Cans</td>
                                        <td class="text-center font-weight-bold text-muted">{{ $stop['empty_cans_returned'] ?? 0 }} Jars</td>
                                        <td class="text-right font-weight-bold text-dark">₹ {{ number_format($stop['total_amount'] ?? 0, 2) }}</td>
                                        <td class="text-center">
                                            <span class="badge badge-success px-2 py-1 text-uppercase">{{ $stop['status'] ?? 'Pending' }}</span>
                                        </td>
                                        <td class="text-right">
                                            @if(!empty($stop['google_maps_url']))
                                                <a href="{{ $stop['google_maps_url'] }}" target="_blank" class="btn btn-outline-success btn-sm p-1 px-2" title="Navigate">
                                                    <i class="fa fa-location-arrow"></i>
                                                </a>
                                            @endif
                                            <button type="button" class="btn btn-outline-secondary btn-sm p-1 px-2" title="WhatsApp Location Pin" data-toggle="modal" data-target="#whatsappLocationModalStop{{ $stop['customer_id'] }}">
                                                <i class="fa fa-whatsapp text-success"></i>
                                            </button>
                                        </td>
                                    </tr>

                                    <!-- WhatsApp Modal per stop -->
                                    <div class="modal fade" id="whatsappLocationModalStop{{ $stop['customer_id'] }}" tabindex="-1" role="dialog" aria-hidden="true">
                                        <div class="modal-dialog modal-dialog-centered" role="document">
                                            <div class="modal-content border-0 shadow-lg rounded-lg">
                                                <div class="modal-header border-0 pb-0">
                                                    <h5 class="modal-title font-weight-bold">
                                                        <i class="fa fa-whatsapp text-success mr-2"></i> Update GPS for {{ $stop['customer_name'] }}
                                                    </h5>
                                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                                                </div>
                                                <form action="{{ url('api/v1/mobile/customers/' . $stop['customer_id'] . '/location') }}" method="POST">
                                                    @csrf
                                                    <div class="modal-body">
                                                        <p class="text-muted small">Paste customer WhatsApp shared Google Maps link to lock delivery location for future orders.</p>
                                                        <div class="form-group">
                                                            <textarea name="location_text" class="form-control" rows="3" placeholder="https://maps.google.com/?q=lat,lng" required></textarea>
                                                        </div>
                                                    </div>
                                                    <div class="modal-footer border-0 pt-0">
                                                        <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                                                        <button type="submit" class="btn btn-success btn-sm">Save GPS Pin</button>
                                                    </div>
                                                </form>
                                            </div>
                                        </div>
                                    </div>
                                @empty
                                    <tr>
                                        <td colspan="8" class="text-center py-4 text-muted">No route deliveries scheduled for today.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

@endsection

