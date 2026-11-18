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
    $isTanker = ($verticalType ?? 'can') === 'tanker';
    $qtyUnit = $isTanker ? 'KL' : 'Cans';
@endphp

<section class="forms">
    <div class="container-fluid">
        <div class="row mb-4">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="row align-items-center">
                        <div class="col-md-7">
                            <span class="badge {{ $isTanker ? 'badge-primary' : 'badge-info' }} px-3 py-1 mb-2 text-uppercase">
                                {{ $isTanker ? 'Bulk Water Tanker Lorry Scheduling' : '20L Packaged Water Can Scheduling' }}
                            </span>
                            <h3 class="font-weight-bold text-dark m-0">Recurring &amp; Customizable Delivery Schedules</h3>
                            <p class="text-muted small m-0 mt-1">
                                Every scheduled occurrence automatically generates a backend <strong>Sales Order (SO-)</strong> tagged as <strong>Regular Scheduled</strong> and fulfills into a GST-compliant <strong>Sales Bill</strong> on delivery.
                            </p>
                        </div>
                        <div class="col-md-5 text-md-right mt-3 mt-md-0">
                            @if($isSuperAdmin)
                                <div class="btn-group btn-group-sm mr-2">
                                    <a href="{{ route('water-logistics.schedules.index', ['vertical' => 'can']) }}" class="btn {{ !$isTanker ? 'btn-primary' : 'btn-outline-primary' }}">20L Can</a>
                                    <a href="{{ route('water-logistics.schedules.index', ['vertical' => 'tanker']) }}" class="btn {{ $isTanker ? 'btn-primary' : 'btn-outline-primary' }}">Bulk Tanker</a>
                                </div>
                            @endif
                            <form action="{{ route('water-logistics.schedules.generate-due') }}" method="POST" class="d-inline mr-2">
                                @csrf
                                <input type="hidden" name="vertical_type" value="{{ $verticalType }}">
                                <button type="submit" class="btn btn-outline-success btn-sm">
                                    <i class="fa fa-refresh mr-1"></i> Generate Due Today
                                </button>
                            </form>
                            <button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#createScheduleModal">
                                <i class="fa fa-plus mr-1"></i> Create Schedule
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <div class="card border-0 shadow-sm rounded-lg p-4 bg-white">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="bg-light">
                                <tr>
                                    <th>Customer</th>
                                    <th>Frequency Rule</th>
                                    <th class="text-center">Qty ({{ $qtyUnit }})</th>
                                    <th class="text-right">Rate</th>
                                    <th>Next Run</th>
                                    <th>Last Generated</th>
                                    <th class="text-center">Status</th>
                                    <th class="text-right">Schedule Controls</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($schedules as $sched)
                                    <tr>
                                        <td>
                                            <div class="font-weight-bold text-dark">{{ $sched['customer_name'] ?? 'Customer' }}</div>
                                            <small class="text-muted">
                                                @if(!empty($sched['route_name'])) Route: {{ $sched['route_name'] }} @endif
                                                @if(!empty($sched['vehicle_number'])) Tanker: {{ $sched['vehicle_number'] }} @endif
                                                @if(!empty($sched['preferred_time_slot'])) &bull; {{ $sched['preferred_time_slot'] }} @endif
                                            </small>
                                        </td>
                                        <td>
                                            <span class="badge badge-info px-2 py-1">{{ $sched['schedule_label'] ?? 'Regular' }}</span>
                                        </td>
                                        <td class="text-center font-weight-bold text-primary">
                                            {{ $isTanker ? number_format((float) $sched['ordered_qty'], 1) : (int) $sched['ordered_qty'] }} {{ $qtyUnit }}
                                        </td>
                                        <td class="text-right">₹ {{ number_format((float) ($sched['unit_rate'] ?? 0), 2) }}</td>
                                        <td><strong>{{ $sched['next_run_date'] ?? '—' }}</strong></td>
                                        <td><small class="text-muted">{{ $sched['last_generated_date'] ?? 'Not yet' }}</small></td>
                                        <td class="text-center">
                                            <span class="badge {{ !empty($sched['is_active']) ? 'badge-success' : 'badge-secondary' }} px-2 py-1">
                                                {{ !empty($sched['is_active']) ? 'ACTIVE' : 'PAUSED' }}
                                            </span>
                                        </td>
                                        <td class="text-right">
                                            <form action="{{ route('water-logistics.schedules.generate-now', $sched['id']) }}" method="POST" class="d-inline">
                                                @csrf
                                                <input type="hidden" name="vertical_type" value="{{ $verticalType }}">
                                                <button type="submit" class="btn btn-outline-primary btn-sm mr-1" title="Create today's Sales Order now">
                                                    <i class="fa fa-bolt mr-1"></i> Create Now
                                                </button>
                                            </form>
                                            <form action="{{ route('water-logistics.schedules.skip', $sched['id']) }}" method="POST" class="d-inline">
                                                @csrf
                                                <input type="hidden" name="vertical_type" value="{{ $verticalType }}">
                                                <button type="submit" class="btn btn-outline-warning btn-sm mr-1">
                                                    Skip Next
                                                </button>
                                            </form>
                                            <form action="{{ route('water-logistics.schedules.toggle', $sched['id']) }}" method="POST" class="d-inline">
                                                @csrf
                                                <input type="hidden" name="vertical_type" value="{{ $verticalType }}">
                                                <button type="submit" class="btn btn-outline-{{ !empty($sched['is_active']) ? 'secondary' : 'success' }} btn-sm">
                                                    {{ !empty($sched['is_active']) ? 'Pause' : 'Resume' }}
                                                </button>
                                            </form>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="8" class="text-center py-4 text-muted">
                                            No recurring schedules configured yet for this vertical. Click <strong>Create Schedule</strong> to set up Daily, Every 2 Days, Weekly, or Custom plans.
                                        </td>
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

<!-- Create Recurring Delivery Schedule Modal -->
<div class="modal fade" id="createScheduleModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
        <div class="modal-content border-0 shadow-lg rounded-lg">
            <form action="{{ route('water-logistics.schedules.store') }}" method="POST">
                @csrf
                <input type="hidden" name="vertical_type" value="{{ $verticalType }}">
                <div class="modal-header bg-primary text-white border-0">
                    <h5 class="modal-title font-weight-bold">Create Recurring Delivery Schedule ({{ $isTanker ? 'Bulk Tanker' : '20L Can' }})</h5>
                    <button type="button" class="close text-white" data-dismiss="modal"><span>&times;</span></button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label class="small font-weight-bold">Customer *</label>
                            <select name="customer_id" class="form-control" required>
                                @foreach($customers as $cust)
                                    <option value="{{ $cust->id }}">{{ $cust->name }} ({{ $cust->phone_number ?? '' }})</option>
                                @endforeach
                            </select>
                        </div>
                        @if($isTanker)
                            <div class="col-md-6 form-group">
                                <label class="small font-weight-bold">Assigned Tanker Lorry</label>
                                <select name="tanker_id" class="form-control">
                                    @foreach($tankers as $tnk)
                                        <option value="{{ $tnk->id }}">{{ $tnk->vehicle_number }} ({{ $tnk->capacity_kl }} KL)</option>
                                    @endforeach
                                </select>
                            </div>
                        @else
                            <div class="col-md-6 form-group">
                                <label class="small font-weight-bold">Delivery Beat Route</label>
                                <select name="route_id" class="form-control">
                                    @foreach($routes as $rt)
                                        <option value="{{ $rt->id }}">{{ $rt->route_name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        @endif
                    </div>

                    <div class="row">
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">Order Qty ({{ $qtyUnit }}) *</label>
                            <input type="number" step="{{ $isTanker ? '0.5' : '1' }}" min="{{ $isTanker ? '1' : '1' }}" name="ordered_qty" class="form-control" value="{{ $isTanker ? '10' : '7' }}" required>
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">{{ $isTanker ? 'Trip Rate (₹)' : 'Rate per Can (₹)' }}</label>
                            <input type="number" step="0.5" min="1" name="unit_rate" class="form-control" value="{{ $isTanker ? '1800' : '35' }}">
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">Payment Mode</label>
                            <select name="payment_mode" class="form-control">
                                <option value="Cash" {{ !$isTanker ? 'selected' : '' }}>Cash</option>
                                <option value="UPI">UPI / QR</option>
                                <option value="Credit" {{ $isTanker ? 'selected' : '' }}>Credit</option>
                            </select>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">Recurrence Frequency *</label>
                            <select name="frequency" class="form-control" id="schedFreqSelect">
                                <option value="daily">Daily</option>
                                <option value="every_n_days">Every N Days (e.g. Every 2 Days)</option>
                                <option value="weekly">Weekly (Select Weekdays)</option>
                                <option value="biweekly">Every 2 Weeks (Biweekly)</option>
                                <option value="monthly">Monthly</option>
                                <option value="one_time">One-Time Planned</option>
                            </select>
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">Interval Days (for Every N Days)</label>
                            <input type="number" min="1" max="90" name="interval_days" class="form-control" value="2">
                        </div>
                        <div class="col-md-4 form-group">
                            <label class="small font-weight-bold">Time Slot</label>
                            <input type="text" name="preferred_time_slot" class="form-control" placeholder="e.g. 07:00 AM - 09:00 AM">
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="small font-weight-bold d-block">Weekdays (when Weekly is selected)</label>
                        @foreach([1 => 'Mon', 2 => 'Tue', 3 => 'Wed', 4 => 'Thu', 5 => 'Fri', 6 => 'Sat', 7 => 'Sun'] as $dNum => $dLabel)
                            <label class="checkbox-inline mr-3 small">
                                <input type="checkbox" name="days_of_week[]" value="{{ $dNum }}"> {{ $dLabel }}
                            </label>
                        @endforeach
                    </div>

                    <div class="row">
                        <div class="col-md-6 form-group">
                            <label class="small font-weight-bold">Start Date *</label>
                            <input type="date" name="start_date" class="form-control" value="{{ now()->toDateString() }}" required>
                        </div>
                        <div class="col-md-6 form-group">
                            <label class="small font-weight-bold">End Date (Optional)</label>
                            <input type="date" name="end_date" class="form-control">
                        </div>
                    </div>

                    <div class="form-check">
                        <input type="checkbox" class="form-check-input" id="genSchedNow" name="generate_immediately" value="1" checked>
                        <label class="form-check-label small" for="genSchedNow">Immediately create first Sales Order (SO-) for start date</label>
                    </div>
                </div>
                <div class="modal-footer border-0 bg-light">
                    <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary btn-sm font-weight-bold">Save Recurring Schedule</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

