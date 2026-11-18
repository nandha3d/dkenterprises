@extends('backend.layout.main')
@section('content')

@if(session()->has('message'))
    <div class="alert alert-success alert-dismissible text-center">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        {{ session()->get('message') }}
    </div>
@endif

@if(session()->has('not_permitted'))
    <div class="alert alert-danger alert-dismissible text-center">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        {{ session()->get('not_permitted') }}
    </div>
@endif

@php
    $vehicle = $manifest['vehicle'] ?? [];
    $stats = $manifest['stats'] ?? [];
    $telemetry = $manifest['telemetry'] ?? [];
    $activeTrip = $manifest['active_trip'] ?? null;
    $pendingTrips = $manifest['pending_trips'] ?? [];
    $recentTrips = $manifest['recent_trips'] ?? [];
    $processUrlTemplate = route('water-logistics.trip.process', ['id' => '__TRIP_ID__']);
@endphp

<section class="forms">
    <div class="container-fluid">
        <!-- Header & Tanker Banner -->
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <div class="d-flex align-items-center flex-wrap gap-2 mb-2">
                                <span class="badge badge-info p-2 px-3 text-uppercase font-weight-bold">
                                    <i class="fa fa-truck mr-1"></i> {{ $vehicle['vehicle_number'] ?? 'Unassigned Vehicle' }}
                                </span>
                                <span class="badge badge-success p-2 px-3 text-uppercase font-weight-bold">
                                    <i class="fa fa-lock mr-1"></i> Valve: {{ $telemetry['anti_theft_valve_status'] ?? 'CLOSED & SEALED' }}
                                </span>
                                <span class="badge badge-light border p-2 px-3 text-dark">
                                    {{ $manifest['company_name'] ?? 'Bulk Tanker Operations' }}
                                </span>
                            </div>
                            <h3 class="font-weight-bold text-dark m-0">Bulk Tanker Driver Portal &amp; Order Processing</h3>
                            <p class="text-muted small m-0 mt-1">
                                {{ $vehicle['model'] ?? 'Bulk Water Tanker' }}
                                @if(!empty($vehicle['capacity_kl']))
                                    ({{ number_format((float) $vehicle['capacity_kl'], 1) }} KL)
                                @endif
                                &bull; Driver: <strong>{{ $manifest['driver_name'] ?? 'Unassigned Driver' }}</strong>
                                @if(!empty($manifest['driver_phone']))
                                    ({{ $manifest['driver_phone'] }})
                                @endif
                            </p>
                        </div>
                        <div class="col-md-4 text-md-right mt-3 mt-md-0">
                            <a href="{{ route('water-logistics.schedules.index', ['vertical' => 'tanker']) }}" class="btn btn-outline-info btn-sm mr-2">
                                <i class="fa fa-calendar mr-1"></i> Recurring Schedules
                            </a>
                            <a href="{{ route('fleet.tracking') }}" class="btn btn-outline-primary btn-sm mr-2">
                                <i class="fa fa-crosshairs mr-1"></i> Fleet Radar
                            </a>
                            <a href="{{ route('water-logistics.index') }}" class="btn btn-primary btn-sm">
                                <i class="fa fa-plus-circle mr-1"></i> Create Order / Trips
                            </a>
                        </div>
                    </div>

                    <!-- Live Meter & Odometer Strip -->
                    <div class="row mt-4 pt-3 border-top">
                        <div class="col-md-3 col-6 border-right text-center mb-2 mb-md-0">
                            <span class="text-muted small font-weight-600 text-uppercase">Current Odometer</span>
                            <h4 class="font-weight-bold text-dark m-0 mt-1 font-monospace">{{ number_format((int) ($vehicle['current_odometer'] ?? 0)) }} KM</h4>
                            <small class="text-muted">Live vehicle master reading</small>
                        </div>
                        <div class="col-md-3 col-6 border-right text-center mb-2 mb-md-0">
                            <span class="text-muted small font-weight-600 text-uppercase">Assigned Orders</span>
                            <h4 class="font-weight-bold text-warning m-0 mt-1">{{ count($pendingTrips) }} Open</h4>
                            <small class="text-muted">Pending / active dispatches</small>
                        </div>
                        <div class="col-md-3 col-6 border-right text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Completed Trips</span>
                            <h4 class="font-weight-bold text-primary m-0 mt-1">{{ (int) ($stats['trips_today'] ?? 0) }} Trips</h4>
                            <small class="text-muted">Settled &amp; delivered</small>
                        </div>
                        <div class="col-md-3 col-6 text-center">
                            <span class="text-muted small font-weight-600 text-uppercase">Water Volume Logged</span>
                            <h4 class="font-weight-bold text-info m-0 mt-1">{{ number_format((float) ($stats['total_kl'] ?? 0), 1) }} KL</h4>
                            <small class="text-muted">{{ number_format(((float) ($stats['total_kl'] ?? 0)) * 1000) }} Litres</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Assigned Tanker Orders Queue (Where Driver Processes Assigned Orders) -->
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <h5 class="font-weight-bold text-dark m-0">
                                <i class="fa fa-tasks text-primary mr-2"></i> Assigned Bulk Tanker Orders Queue
                            </h5>
                            <small class="text-muted">Advance dispatch milestones or process final odometer, pumping duration &amp; delivery completion right here.</small>
                        </div>
                        <span class="badge badge-warning px-3 py-2">{{ count($pendingTrips) }} Pending</span>
                    </div>

                    @if(!empty($pendingTrips))
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="thead-light">
                                    <tr>
                                        <th>Trip #</th>
                                        <th>Customer / Destination</th>
                                        <th>Qty (KL)</th>
                                        <th>Start KM</th>
                                        <th>Trip Rate</th>
                                        <th>Status</th>
                                        <th class="text-right">Process Order</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($pendingTrips as $order)
                                        @php
                                            $orderStatus = strtolower((string) ($order['status'] ?? 'pending'));
                                            $orderKl = (float) ($order['water_quantity_kl'] ?? 0);
                                            $orderStartKm = (int) ($order['start_km'] ?? ($vehicle['current_odometer'] ?? 0));
                                            $isRegular = !empty($order['is_regular_scheduled']) || ($order['order_origin'] ?? '') === 'scheduled';
                                        @endphp
                                        <tr>
                                            <td class="font-weight-bold text-primary">
                                                {{ $order['sales_order_no'] ?? $order['trip_number'] ?? ('#' . $order['id']) }}
                                                <div class="mt-1">
                                                    <span class="badge {{ $isRegular ? 'badge-info' : 'badge-light border text-dark' }}" style="font-size: 11px;">
                                                        {{ $order['schedule_label'] ?? ($isRegular ? 'Regular · Scheduled' : 'Created Today (On-Day)') }}
                                                    </span>
                                                </div>
                                            </td>
                                            <td>
                                                <div class="font-weight-bold text-dark">{{ $order['customer_name'] ?? $order['destination_site'] }}</div>
                                                <small class="text-muted">{{ $order['destination_site'] ?? '—' }}</small>
                                            </td>
                                            <td>{{ number_format($orderKl, 1) }} KL</td>
                                            <td class="font-monospace">{{ number_format($orderStartKm) }} KM</td>
                                            <td>₹ {{ number_format((float) ($order['trip_rate'] ?? 0), 2) }}</td>
                                            <td>
                                                <span class="badge badge-info text-uppercase">{{ str_replace('_', ' ', $orderStatus) }}</span>
                                            </td>
                                            <td class="text-right">
                                                <div class="d-inline-flex align-items-center flex-wrap justify-content-end">
                                                    @if(in_array($orderStatus, ['pending', 'assigned', 'dispatched', 'loading'], true))
                                                        <form method="POST" action="{{ route('water-logistics.trip.process', ['id' => $order['id']]) }}" class="d-inline mr-1">
                                                            @csrf
                                                            <input type="hidden" name="status" value="in_transit">
                                                            <input type="hidden" name="start_km" value="{{ $orderStartKm }}">
                                                            <button type="submit" class="btn btn-outline-warning btn-sm">
                                                                <i class="fa fa-play mr-1"></i> Start Moving
                                                            </button>
                                                        </form>
                                                    @elseif($orderStatus === 'in_transit')
                                                        <form method="POST" action="{{ route('water-logistics.trip.process', ['id' => $order['id']]) }}" class="d-inline mr-1">
                                                            @csrf
                                                            <input type="hidden" name="status" value="at_site">
                                                            <button type="submit" class="btn btn-outline-info btn-sm">
                                                                <i class="fa fa-map-pin mr-1"></i> Arrived at Site
                                                            </button>
                                                        </form>
                                                    @endif
                                                    <button
                                                        type="button"
                                                        class="btn btn-primary btn-sm js-process-tanker-order"
                                                        data-toggle="modal"
                                                        data-target="#processTankerOrderModal"
                                                        data-trip-id="{{ $order['id'] }}"
                                                        data-trip-number="{{ $order['trip_number'] ?? ('#' . $order['id']) }}"
                                                        data-customer-name="{{ $order['customer_name'] ?? $order['destination_site'] }}"
                                                        data-destination-site="{{ $order['destination_site'] ?? '' }}"
                                                        data-water-kl="{{ $orderKl }}"
                                                        data-start-km="{{ $orderStartKm }}"
                                                        data-end-km="{{ (int) ($order['end_km'] ?? 0) }}"
                                                        data-motor-mins="{{ (int) ($order['motor_pumping_minutes'] ?? 0) }}"
                                                        data-waiting-mins="{{ (int) ($order['waiting_minutes'] ?? 0) }}"
                                                        data-trip-rate="{{ (float) ($order['trip_rate'] ?? 0) }}"
                                                        data-diesel="{{ (float) ($order['diesel_expense'] ?? 0) }}"
                                                        data-toll="{{ (float) ($order['toll_expense'] ?? 0) }}"
                                                        data-batta="{{ (float) ($order['driver_batta'] ?? 0) }}"
                                                        data-receiver="{{ $order['site_receiver_name'] ?? '' }}"
                                                        data-status="completed"
                                                    >
                                                        <i class="fa fa-check-circle mr-1"></i> Process &amp; Complete
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    @else
                        <div class="alert alert-light border text-center mb-0 py-4">
                            <i class="fa fa-check-circle text-success mr-1"></i> No pending tanker orders are queued for this vehicle. Use <strong>Dispatch / Trip Sheets</strong> to create a new assignment or log an ad-hoc trip.
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Active Destination Site & Telemetry Row -->
        <div class="row mb-4">
            <div class="col-md-8">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white h-100">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <h5 class="font-weight-bold text-dark m-0">
                            <i class="fa fa-map-marker text-danger mr-2"></i> Active Assigned Customer Site
                        </h5>
                        @if(!empty($activeTrip['trip_number']))
                            <span class="badge badge-light border text-primary font-weight-bold px-2 py-1">
                                Trip #{{ $activeTrip['trip_number'] }} &bull; {{ strtoupper(str_replace('_', ' ', $activeTrip['status'] ?? 'pending')) }}
                            </span>
                        @endif
                    </div>

                    @if(!empty($activeTrip))
                        <div class="p-3 rounded-lg mb-3 bg-light border">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h4 class="font-weight-bold text-dark m-0">{{ $activeTrip['customer_name'] ?? 'Assigned Customer' }}</h4>
                                    <p class="text-muted small m-0 mt-1">
                                        <i class="fa fa-building-o mr-1"></i> Destination: <strong>{{ $activeTrip['destination_site'] ?? '—' }}</strong>
                                    </p>
                                    <p class="text-muted small m-0 mt-1">
                                        <i class="fa fa-map-pin mr-1"></i> {{ !empty($activeTrip['address']) ? $activeTrip['address'] : 'Address not pinned yet' }}
                                    </p>
                                    <p class="text-muted small m-0 mt-1">
                                        <i class="fa fa-phone mr-1"></i> Receiver Contact:
                                        @if(!empty($activeTrip['phone']))
                                            <a href="tel:{{ $activeTrip['phone'] }}">{{ $activeTrip['phone'] }}</a>
                                        @else
                                            <span>Not available</span>
                                        @endif
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right mt-3 mt-md-0">
                                    <div class="mb-2">
                                        <span class="badge badge-pill badge-primary px-3 py-2">
                                            <i class="fa fa-tint mr-1"></i> {{ number_format((float) ($activeTrip['water_decanted_liters'] ?? 0)) }} Litres ({{ number_format((float) ($activeTrip['water_quantity_kl'] ?? 0), 1) }} KL)
                                        </span>
                                    </div>
                                    @if(!empty($activeTrip['google_maps_url']))
                                        <a href="{{ $activeTrip['google_maps_url'] }}" target="_blank" class="btn btn-success btn-sm btn-block">
                                            <i class="fa fa-location-arrow mr-1"></i> 1-Tap Google Maps Navigation
                                        </a>
                                    @else
                                        <span class="badge badge-warning p-2 d-block text-center">GPS Pin Missing</span>
                                    @endif
                                </div>
                            </div>
                        </div>

                        <div class="row pt-2">
                            <div class="col-md-4 mb-2 mb-md-0">
                                <div class="p-3 rounded border text-center">
                                    <span class="small text-muted font-weight-600">Start Odometer</span>
                                    <h5 class="font-weight-bold text-dark m-0 mt-1">{{ number_format((int) ($activeTrip['start_km'] ?? 0)) }} KM</h5>
                                </div>
                            </div>
                            <div class="col-md-4 mb-2 mb-md-0">
                                <div class="p-3 rounded border text-center">
                                    <span class="small text-muted font-weight-600">Trip Rate</span>
                                    <h5 class="font-weight-bold text-dark m-0 mt-1">₹ {{ number_format((float) ($activeTrip['trip_rate'] ?? 0), 2) }}</h5>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="p-3 rounded border text-center">
                                    <span class="small text-muted font-weight-600">Diesel Logged</span>
                                    <h5 class="font-weight-bold text-dark m-0 mt-1">₹ {{ number_format((float) ($activeTrip['diesel_expense'] ?? 0), 2) }}</h5>
                                </div>
                            </div>
                        </div>

                        <div class="mt-4 d-flex flex-wrap gap-2">
                            @if(!empty($activeTrip['customer_id']))
                                <button type="button" class="btn btn-outline-info flex-grow-1 mr-2" data-toggle="modal" data-target="#whatsappLocationModal">
                                    <i class="fa fa-whatsapp mr-1 text-success"></i> Update Customer GPS via WhatsApp Pin
                                </button>
                            @endif
                            <button
                                type="button"
                                class="btn btn-primary flex-grow-1 js-process-tanker-order"
                                data-toggle="modal"
                                data-target="#processTankerOrderModal"
                                data-trip-id="{{ $activeTrip['id'] }}"
                                data-trip-number="{{ $activeTrip['trip_number'] ?? ('#' . $activeTrip['id']) }}"
                                data-customer-name="{{ $activeTrip['customer_name'] ?? $activeTrip['destination_site'] }}"
                                data-destination-site="{{ $activeTrip['destination_site'] ?? '' }}"
                                data-water-kl="{{ (float) ($activeTrip['water_quantity_kl'] ?? 0) }}"
                                data-start-km="{{ (int) ($activeTrip['start_km'] ?? 0) }}"
                                data-end-km="{{ (int) ($activeTrip['end_km'] ?? 0) }}"
                                data-motor-mins="{{ (int) ($activeTrip['motor_pumping_minutes'] ?? 0) }}"
                                data-waiting-mins="{{ (int) ($activeTrip['waiting_minutes'] ?? 0) }}"
                                data-trip-rate="{{ (float) ($activeTrip['trip_rate'] ?? 0) }}"
                                data-diesel="{{ (float) ($activeTrip['diesel_expense'] ?? 0) }}"
                                data-toll="{{ (float) ($activeTrip['toll_expense'] ?? 0) }}"
                                data-batta="0"
                                data-receiver=""
                                data-status="completed"
                            >
                                <i class="fa fa-check-circle mr-1"></i> Process &amp; Complete Active Order
                            </button>
                        </div>
                    @else
                        <div class="text-center py-5">
                            <i class="fa fa-check-circle-o text-success fa-3x"></i>
                            <h5 class="font-weight-bold mt-3">No Active Trip Assigned</h5>
                            <p class="text-muted small">Once the dispatcher assigns a tanker order, it will appear in your queue above.</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- Live Telematics Panel -->
            <div class="col-md-4 mt-4 mt-md-0">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white h-100">
                    <h5 class="font-weight-bold text-dark mb-3">
                        <i class="fa fa-shield text-primary mr-2"></i> Live Vehicle Telemetry
                    </h5>
                    <ul class="list-group list-group-flush">
                        <li class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="fa fa-tachometer mr-2"></i> Vehicle Speed</span>
                            <span class="font-weight-bold text-dark">{{ (int) ($telemetry['current_speed'] ?? 0) }} km/h</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="fa fa-map-marker mr-2 text-info"></i> GPS Lock</span>
                            <span class="font-weight-bold text-dark">
                                {{ !empty($telemetry['gps_lock']) ? 'Locked' : 'Awaiting GPS Ping' }}
                            </span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="fa fa-clock-o mr-2 text-warning"></i> Last GPS Ping</span>
                            <span class="font-weight-bold text-dark">{{ $telemetry['last_ping_at'] ?? 'No ping recorded' }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="fa fa-lock mr-2 text-success"></i> Valve State</span>
                            <span class="badge badge-success px-2 py-1">{{ $telemetry['anti_theft_valve_status'] ?? 'CLOSED & SEALED' }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center px-0">
                            <span class="text-muted"><i class="fa fa-road mr-2 text-primary"></i> Vehicle Capacity</span>
                            <span class="font-weight-bold text-dark">{{ number_format((float) ($vehicle['capacity_kl'] ?? 0), 1) }} KL</span>
                        </li>
                    </ul>

                    <div class="mt-4 p-3 rounded alert-success mb-0">
                        <small class="font-weight-600">
                            <i class="fa fa-info-circle mr-1"></i> Completing an order here automatically updates vehicle odometer and posts revenue/expense entries to the General Ledger.
                        </small>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Trips History -->
        @if(!empty($recentTrips))
            <div class="row mb-4">
                <div class="col-md-12">
                    <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                        <h5 class="font-weight-bold text-dark mb-3">
                            <i class="fa fa-history text-secondary mr-2"></i> Recent Tanker Trips
                        </h5>
                        <div class="table-responsive">
                            <table class="table table-sm table-striped mb-0">
                                <thead>
                                    <tr>
                                        <th>Trip #</th>
                                        <th>Customer / Site</th>
                                        <th>Qty (KL)</th>
                                        <th>Distance</th>
                                        <th>Motor Mins</th>
                                        <th>Trip Rate</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($recentTrips as $rt)
                                        <tr>
                                            <td class="font-weight-bold">{{ $rt['trip_number'] ?? ('#' . $rt['id']) }}</td>
                                            <td>{{ $rt['customer_name'] ?? $rt['destination_site'] }}</td>
                                            <td>{{ number_format((float) ($rt['water_quantity_kl'] ?? 0), 1) }} KL</td>
                                            <td>{{ number_format((int) ($rt['total_km'] ?? 0)) }} KM</td>
                                            <td>{{ (int) ($rt['motor_pumping_minutes'] ?? 0) }} mins</td>
                                            <td>₹ {{ number_format((float) ($rt['trip_rate'] ?? 0), 2) }}</td>
                                            <td><span class="badge badge-secondary text-uppercase">{{ $rt['status'] ?? 'pending' }}</span></td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        @endif
    </div>
</section>

<!-- Process Tanker Order Modal -->
<div class="modal fade" id="processTankerOrderModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
        <div class="modal-content border-0 shadow-lg rounded-lg">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title font-weight-bold">
                    <i class="fa fa-check-circle text-primary mr-2"></i> Process Tanker Order <span id="proc_trip_label"></span>
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form method="POST" action="" id="processTankerOrderForm" data-url-template="{{ $processUrlTemplate }}">
                @csrf
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label class="small font-weight-600 text-muted">Order Stage / Target Status</label>
                            <select name="status" id="proc_status" class="form-control" required>
                                <option value="in_transit">In Transit</option>
                                <option value="at_site">Arrived at Site</option>
                                <option value="decanting">Motor Decanting</option>
                                <option value="completed" selected>Completed &amp; Post Invoice</option>
                            </select>
                        </div>
                        <div class="col-md-6 form-group">
                            <label class="small font-weight-600 text-muted">Destination Site</label>
                            <input type="text" name="destination_site" id="proc_destination_site" class="form-control" required>
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-600 text-muted">Water Delivered (KL)</label>
                            <input type="number" step="0.1" min="0" name="water_quantity_kl" id="proc_water_kl" class="form-control" required>
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-600 text-muted">Start Odometer (KM)</label>
                            <input type="number" min="0" name="start_km" id="proc_start_km" class="form-control" required>
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-600 text-muted">End Odometer (KM)</label>
                            <input type="number" min="0" name="end_km" id="proc_end_km" class="form-control" required>
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Motor Start Time</label>
                            <input type="datetime-local" name="motor_started_at" id="proc_motor_started_at" class="form-control">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Motor Stop Time</label>
                            <input type="datetime-local" name="motor_stopped_at" id="proc_motor_stopped_at" class="form-control">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Motor Minutes</label>
                            <input type="number" min="0" name="motor_pumping_minutes" id="proc_motor_mins" class="form-control" value="0">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Site Waiting (Mins)</label>
                            <input type="number" min="0" name="waiting_minutes" id="proc_waiting_mins" class="form-control" value="0">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Trip Rate (₹)</label>
                            <input type="number" step="0.01" min="0" name="trip_rate" id="proc_trip_rate" class="form-control" required>
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Diesel Expense (₹)</label>
                            <input type="number" step="0.01" min="0" name="diesel_expense" id="proc_diesel" class="form-control" value="0">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Toll Expense (₹)</label>
                            <input type="number" step="0.01" min="0" name="toll_expense" id="proc_toll" class="form-control" value="0">
                        </div>
                        <div class="col-md-3 form-group">
                            <label class="small font-weight-600 text-muted">Driver Batta (₹)</label>
                            <input type="number" step="0.01" min="0" name="driver_batta" id="proc_batta" class="form-control" value="0">
                        </div>
                        <div class="col-md-12 form-group mb-0">
                            <label class="small font-weight-600 text-muted">Site Receiver / Security Name</label>
                            <input type="text" name="site_receiver_name" id="proc_receiver" class="form-control" placeholder="Name of customer representative signing off decant">
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary btn-sm">
                        <i class="fa fa-check mr-1"></i> Save &amp; Process Order
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- WhatsApp Location Modal -->
@if(!empty($activeTrip['customer_id']))
<div class="modal fade" id="whatsappLocationModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content border-0 shadow-lg rounded-lg">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title font-weight-bold">
                    <i class="fa fa-whatsapp text-success mr-2"></i> Update Customer GPS Location
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <form action="{{ url('api/v1/mobile/customers/' . $activeTrip['customer_id'] . '/location') }}" method="POST" id="whatsappLocationForm">
                @csrf
                <div class="modal-body">
                    <p class="text-muted small">
                        Paste the location pin or Google Maps share link sent by customer on WhatsApp (e.g. <code>https://maps.google.com/?q=11.2785,77.5842</code>).
                    </p>
                    <div class="form-group">
                        <label class="small font-weight-600 text-muted">Customer Name</label>
                        <input type="text" class="form-control" value="{{ $activeTrip['customer_name'] ?? '' }}" readonly>
                    </div>
                    <div class="form-group">
                        <label class="small font-weight-600 text-muted">WhatsApp Shared Text / Google Maps URL</label>
                        <textarea name="location_text" id="location_text" class="form-control" rows="3" placeholder="Paste WhatsApp location text or Google Maps link here..." required></textarea>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-success btn-sm">
                        <i class="fa fa-check mr-1"></i> Save Coordinates to Customer Master
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
@endif

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function () {
    const form = document.getElementById('processTankerOrderForm');
    if (!form) return;
    const urlTemplate = form.getAttribute('data-url-template') || '';

    document.querySelectorAll('.js-process-tanker-order').forEach(function (btn) {
        btn.addEventListener('click', function () {
            const tripId = btn.getAttribute('data-trip-id') || '';
            form.setAttribute('action', urlTemplate.replace('__TRIP_ID__', tripId));
            document.getElementById('proc_trip_label').textContent = btn.getAttribute('data-trip-number') || '';
            document.getElementById('proc_status').value = btn.getAttribute('data-status') || 'completed';
            document.getElementById('proc_destination_site').value = btn.getAttribute('data-destination-site') || '';
            document.getElementById('proc_water_kl').value = btn.getAttribute('data-water-kl') || '0';
            document.getElementById('proc_start_km').value = btn.getAttribute('data-start-km') || '0';
            const endKmVal = parseInt(btn.getAttribute('data-end-km') || '0', 10);
            document.getElementById('proc_end_km').value = endKmVal > 0 ? endKmVal : (btn.getAttribute('data-start-km') || '0');
            document.getElementById('proc_motor_mins').value = btn.getAttribute('data-motor-mins') || '0';
            document.getElementById('proc_waiting_mins').value = btn.getAttribute('data-waiting-mins') || '0';
            document.getElementById('proc_trip_rate').value = btn.getAttribute('data-trip-rate') || '0';
            document.getElementById('proc_diesel').value = btn.getAttribute('data-diesel') || '0';
            document.getElementById('proc_toll').value = btn.getAttribute('data-toll') || '0';
            document.getElementById('proc_batta').value = btn.getAttribute('data-batta') || '0';
            document.getElementById('proc_receiver').value = btn.getAttribute('data-receiver') || '';
            document.getElementById('proc_motor_started_at').value = '';
            document.getElementById('proc_motor_stopped_at').value = '';
        });
    });

    const startInput = document.getElementById('proc_motor_started_at');
    const stopInput = document.getElementById('proc_motor_stopped_at');
    const minsInput = document.getElementById('proc_motor_mins');
    function syncMotorMins() {
        if (!startInput.value || !stopInput.value) return;
        const s = new Date(startInput.value);
        let e = new Date(stopInput.value);
        if (isNaN(s.getTime()) || isNaN(e.getTime())) return;
        if (e < s) e = new Date(e.getTime() + 86400000);
        minsInput.value = Math.max(0, Math.ceil((e.getTime() - s.getTime()) / 60000));
    }
    if (startInput && stopInput) {
        startInput.addEventListener('change', syncMotorMins);
        stopInput.addEventListener('change', syncMotorMins);
    }
});
</script>
@endpush

@endsection
