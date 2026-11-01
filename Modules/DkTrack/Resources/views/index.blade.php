@php
    $sbCompanyId = session('company_id');
    $sbCompany = $sbCompanyId ? \App\Models\Company::find($sbCompanyId) : null;
    $sbIndustry = $sbCompany?->industry;
@endphp

@extends('backend.layout.main')
@section('content')

@if(session()->has('message'))
    <div class="alert alert-success alert-dismissible text-center">
        <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        {{ session()->get('message') }}
    </div>
@endif

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-direction text-primary mr-2"></i> DK Track &mdash; Executive Command Dashboard
            </h3>
            <p class="text-muted small m-0 mt-1">Operations Engine for Bulk Water Tankers, Packaged Drinking Water Distribution, Cafe Operations &amp; GPS Telematics</p>
        </div>
        <div class="col-md-5 text-right">
            <a href="{{ route('dktrack.mobile_simulator') }}" target="_blank" class="btn btn-outline-primary btn-sm mr-2 shadow-sm">
                <i class="dripicons-phone"></i> Mobile Driver App
            </a>
            @if($sbIndustry !== 'packaged_water')
            <a href="{{ route('dktrack.tankers') }}" class="btn btn-primary btn-sm mr-2 shadow-sm">
                <i class="dripicons-plus"></i> + Tanker Trip Sheet
            </a>
            @endif
            @if($sbIndustry !== 'bulk_water')
            <a href="{{ route('dktrack.water_cans') }}" class="btn btn-success btn-sm shadow-sm">
                <i class="dripicons-drop"></i> + Packaged Water Delivery
            </a>
            @endif
        </div>
    </div>

    <!-- KPI Metric Cards -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-primary" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">TODAY'S FLEET REVENUE</span>
                <h3 class="font-weight-bold text-dark m-0 mt-2">₹1,48,500</h3>
                <div class="d-flex justify-content-between align-items-center mt-2 small text-muted">
                    <span>Tanker: ₹1.24L</span>
                    <span>Cans: ₹24.5K</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-info" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">WATER DISPATCHED TODAY</span>
                <h3 class="font-weight-bold text-info m-0 mt-2">96.0 KL</h3>
                <div class="d-flex justify-content-between align-items-center mt-2 small text-muted">
                    <span>Tankers: 96,000 L</span>
                    <span>Cans: 213 Units</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-warning" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">DIESEL &amp; OPERATING COSTS</span>
                <h3 class="font-weight-bold text-warning m-0 mt-2">₹8,420</h3>
                <div class="d-flex justify-content-between align-items-center mt-2 small text-muted">
                    <span>Diesel: ₹6,720</span>
                    <span>Batta: ₹1,700</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-success" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">NET OPERATING MARGIN</span>
                <h3 class="font-weight-bold text-success m-0 mt-2">₹1,40,080</h3>
                <div class="d-flex justify-content-between align-items-center mt-2 small text-muted">
                    <span>94.3% Operating Profit</span>
                    <span class="text-success font-weight-bold">&uarr; Optimal</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Active Fleet Live Telematics & Quick Jump Grid -->
    <div class="row mb-4">
        <div class="col-md-8">
            <div class="card border-0 shadow-sm rounded bg-white">
                <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
                    <h5 class="font-weight-bold m-0 text-dark">
                        <i class="dripicons-map text-primary mr-1"></i> Active Fleet Telematics &amp; GPS Status
                    </h5>
                    <a href="{{ route('dktrack.telematics') }}" class="btn btn-outline-secondary btn-sm">Full Telematics Map &rarr;</a>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover align-middle mb-0 text-nowrap">
                            <thead class="thead-light">
                                <tr>
                                    <th>Vehicle</th>
                                    <th>Type &amp; Capacity</th>
                                    <th>Assigned Driver</th>
                                    <th>Status &amp; Speed</th>
                                    <th>Current Destination / Route</th>
                                    <th>GPS Telemetry</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td><strong>TN 38 DZ 8841</strong></td>
                                    <td><span class="badge badge-primary">40.0 KL Multi-Axle</span></td>
                                    <td>Karthik Raja <small class="text-muted d-block">98422 10103</small></td>
                                    <td><span class="badge badge-success">Moving &bull; 46 km/h</span></td>
                                    <td>Vinayaga Spinning Mill</td>
                                    <td><span class="badge badge-light border text-success">&bull; GPS Live (10s ago)</span></td>
                                </tr>
                                <tr>
                                    <td><strong>TN 34 AF 4954</strong></td>
                                    <td><span class="badge badge-info">24.0 KL Tanker</span></td>
                                    <td>Suresh Kumar <small class="text-muted d-block">98422 10101</small></td>
                                    <td><span class="badge badge-warning">At Destination (Unloading)</span></td>
                                    <td>Texvalley Corporate Campus</td>
                                    <td><span class="badge badge-light border text-success">&bull; GPS Live (22s ago)</span></td>
                                </tr>
                                <tr>
                                    <td><strong>TN 38 CY 5599</strong></td>
                                    <td><span class="badge badge-info">16.0 KL Tanker</span></td>
                                    <td>Palanisamy M. <small class="text-muted d-block">98422 10102</small></td>
                                    <td><span class="badge badge-success">Moving &bull; 38 km/h</span></td>
                                    <td>Amirtha Milk Dairy</td>
                                    <td><span class="badge badge-light border text-success">&bull; GPS Live (35s ago)</span></td>
                                </tr>
                                <tr>
                                    <td><strong>TN 34 BF 1120</strong></td>
                                    <td><span class="badge badge-secondary">9.0 KL Tanker</span></td>
                                    <td>Murugesan K. <small class="text-muted d-block">98422 10104</small></td>
                                    <td><span class="badge badge-dark">Standby at RO Plant</span></td>
                                    <td>Borewell Plant 1 Yard</td>
                                    <td><span class="badge badge-light border text-muted">Halted (0 km/h)</span></td>
                                </tr>
                                <tr>
                                    <td><strong>TN 38 BX 4412</strong></td>
                                    <td><span class="badge badge-success">Tata Ace &bull; 70 Cans</span></td>
                                    <td>Vignesh (Vicky) <small class="text-muted d-block">97871 44120</small></td>
                                    <td><span class="badge badge-success">Delivering &bull; Stop #14</span></td>
                                    <td>Race Course &ndash; Gandhipuram</td>
                                    <td><span class="badge badge-light border text-success">&bull; Geo-Verified Drop</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <!-- Operational Verticals Quick Jump -->
            <div class="card border-0 shadow-sm rounded bg-white mb-3">
                <div class="card-header bg-white border-bottom py-3">
                    <h6 class="font-weight-bold m-0 text-dark">
                        <i class="dripicons-view-thumb text-primary mr-1"></i> Operational Portals
                    </h6>
                </div>
                <div class="card-body p-3">
                    @if($sbIndustry !== 'packaged_water')
                    <a href="{{ route('dktrack.tankers') }}" class="d-flex align-items-center justify-content-between p-2 mb-2 rounded border text-decoration-none text-dark hover-bg-light">
                        <div class="d-flex align-items-center">
                            <i class="dripicons-to-do fa-lg text-primary mr-3"></i>
                            <div>
                                <strong class="d-block">Bulk Water Tankers</strong>
                                <small class="text-muted">Dynamic KL Capacities, Surcharges &amp; Trip Sheets</small>
                            </div>
                        </div>
                        <i class="dripicons-chevron-right text-muted"></i>
                    </a>
                    @endif

                    @if($sbIndustry !== 'bulk_water')
                    <a href="{{ route('dktrack.water_cans') }}" class="d-flex align-items-center justify-content-between p-2 mb-2 rounded border text-decoration-none text-dark hover-bg-light">
                        <div class="d-flex align-items-center">
                            <i class="dripicons-drop fa-lg text-success mr-3"></i>
                            <div>
                                <strong class="d-block">Packaged Drinking Water</strong>
                                <small class="text-muted">Plant Refills, Beat Route Drops &amp; Container Custody</small>
                            </div>
                        </div>
                        <i class="dripicons-chevron-right text-muted"></i>
                    </a>
                    @endif

                    <a href="{{ route('dktrack.bakery') }}" class="d-flex align-items-center justify-content-between p-2 mb-2 rounded border text-decoration-none text-dark hover-bg-light">
                        <div class="d-flex align-items-center">
                            <i class="dripicons-store fa-lg text-warning mr-3"></i>
                            <div>
                                <strong class="d-block">Bakery &amp; Cafe Store</strong>
                                <small class="text-muted">Daily Ingredients, Drawer Closing, Paati Wages</small>
                            </div>
                        </div>
                        <i class="dripicons-chevron-right text-muted"></i>
                    </a>

                    <a href="{{ route('dktrack.customers') }}" class="d-flex align-items-center justify-content-between p-2 mb-2 rounded border text-decoration-none text-dark hover-bg-light">
                        <div class="d-flex align-items-center">
                            <i class="dripicons-location fa-lg text-danger mr-3"></i>
                            <div>
                                <strong class="d-block">Customers &amp; Geo-Lock</strong>
                                <small class="text-muted">Haversine GPS Verification &amp; Slabs</small>
                            </div>
                        </div>
                        <i class="dripicons-chevron-right text-muted"></i>
                    </a>

                    <a href="{{ route('dktrack.staff') }}" class="d-flex align-items-center justify-content-between p-2 rounded border text-decoration-none text-dark hover-bg-light">
                        <div class="d-flex align-items-center">
                            <i class="dripicons-user-group fa-lg text-info mr-3"></i>
                            <div>
                                <strong class="d-block">Staff, Drivers &amp; Payroll</strong>
                                <small class="text-muted">Daily Wages, Batta, Advances &amp; Leaves</small>
                            </div>
                        </div>
                        <i class="dripicons-chevron-right text-muted"></i>
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
.hover-bg-light:hover {
    background-color: #f8fafc;
    border-color: #0284c7 !important;
}
</style>

@endsection
