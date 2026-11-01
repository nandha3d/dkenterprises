@php
    $sbCompanyId = session('company_id');
    $sbCompany = $sbCompanyId ? \App\Models\Company::find($sbCompanyId) : null;
    $sbIndustry = $sbCompany?->industry;
@endphp

@extends('backend.layout.main')
@section('content')

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-user-group text-info mr-2"></i> Staff, Drivers &amp; Payroll Management
            </h3>
            <p class="text-muted small m-0 mt-1">Multi-vertical human capital: Tanker heavy drivers (trip batta), packaged drinking water delivery staff (daily wages), cafe staff (Paati daily payout) &amp; advance recovery.</p>
        </div>
        <div class="col-md-5 text-right">
            <button type="button" class="btn btn-outline-primary btn-sm mr-2 shadow-sm" data-toggle="modal" data-target="#recordAttendanceModal">
                <i class="dripicons-clock"></i> Mark Field Attendance
            </button>
            <button type="button" class="btn btn-primary btn-sm shadow-sm" data-toggle="modal" data-target="#disbursePayrollModal">
                <i class="dripicons-wallet"></i> Disburse Payroll Voucher
            </button>
        </div>
    </div>

    <!-- Payroll & Advance Summary Cards -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-primary" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">TOTAL ACTIVE WORKFORCE</span>
                <h3 class="font-weight-bold text-dark m-0 mt-2">9 Staff Members</h3>
                <small class="text-muted">4 Drivers &bull; 2 Delivery &bull; 3 Bakery</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-success" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">BASE MONTHLY PAYROLL</span>
                <h3 class="font-weight-bold text-success m-0 mt-2">₹1,50,000</h3>
                <small class="text-muted">Fixed salary obligations</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-info" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">TRIP BATTA &amp; INCENTIVES</span>
                <h3 class="font-weight-bold text-info m-0 mt-2">₹18,450</h3>
                <small class="text-info font-weight-bold">Tanker trips + can drops</small>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-left border-danger" style="border-left-width: 4px !important;">
                <span class="small text-muted font-weight-bold">OUTSTANDING ADVANCES</span>
                <h3 class="font-weight-bold text-danger m-0 mt-2">₹6,650</h3>
                <small class="text-danger font-weight-bold">Auto-recovered from payroll</small>
            </div>
        </div>
    </div>

    <!-- Staff Directory & Wage Structures -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-vcard text-primary mr-1"></i> Staff Directory, Licenses &amp; Wage Models
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Staff Name</th>
                            <th>Operational Role</th>
                            <th>Division</th>
                            <th>Contact Phone</th>
                            <th>Assigned Vehicle</th>
                            <th>Wage Model</th>
                            <th>Batta / Daily Rate</th>
                            <th>Advance Balance</th>
                            <th>Compliance &amp; Badge</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Karthik Raja</strong></td>
                            <td>Heavy Trailer Driver</td>
                            <td><span class="badge badge-primary">Bulk Tankers</span></td>
                            <td>98422 10103</td>
                            <td>TN 38 DZ 8841 (40KL)</td>
                            <td>Monthly Salaried</td>
                            <td><strong>₹300 / trip sheet</strong></td>
                            <td><span class="badge badge-light border">₹0.00</span></td>
                            <td><span class="badge badge-success">&check; Badge Exp: 2029-03</span></td>
                        </tr>
                        <tr>
                            <td><strong>Suresh Kumar</strong></td>
                            <td>Senior Tanker Driver</td>
                            <td><span class="badge badge-primary">Bulk Tankers</span></td>
                            <td>98422 10101</td>
                            <td>TN 34 AF 4954 (24KL)</td>
                            <td>Monthly Salaried</td>
                            <td><strong>₹250 / trip sheet</strong></td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹2,000.00</span></td>
                            <td><span class="badge badge-success">&check; Badge Exp: 2028-11</span></td>
                        </tr>
                        <tr>
                            <td><strong>Palanisamy M.</strong></td>
                            <td>Tanker Driver</td>
                            <td><span class="badge badge-primary">Bulk Tankers</span></td>
                            <td>98422 10102</td>
                            <td>TN 38 CY 5599 (16KL)</td>
                            <td>Monthly Salaried</td>
                            <td><strong>₹250 / trip sheet</strong></td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹1,500.00</span></td>
                            <td><span class="badge badge-success">&check; Badge Exp: 2027-08</span></td>
                        </tr>
                        <tr>
                            <td><strong>Murugesan K.</strong></td>
                            <td>Tanker Driver</td>
                            <td><span class="badge badge-primary">Bulk Tankers</span></td>
                            <td>98422 10104</td>
                            <td>TN 34 BF 1120 (Tanker)</td>
                            <td>Monthly Salaried</td>
                            <td><strong>₹250 / trip sheet</strong></td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹800.00</span></td>
                            <td><span class="badge badge-success">&check; Badge Exp: 2027-05</span></td>
                        </tr>
                        @if($sbIndustry !== 'bulk_water')
                        <tr>
                            <td><strong>Vignesh (Vicky)</strong></td>
                            <td>Route Distribution Lead</td>
                            <td><span class="badge badge-success">Packaged Drinking Water</span></td>
                            <td>97871 44120</td>
                            <td>TN 38 BX 4412 (Tata Ace)</td>
                            <td>Fixed Daily Wage</td>
                            <td><strong>₹1,000 / day</strong></td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹1,200.00</span></td>
                            <td><span class="badge badge-success">&check; License Valid</span></td>
                        </tr>
                        <tr>
                            <td><strong>Raja Sundaram</strong></td>
                            <td>Route Loader &amp; Helper</td>
                            <td><span class="badge badge-success">Packaged Drinking Water</span></td>
                            <td>97871 44122</td>
                            <td>TN 38 BX 4412 (Tata Ace)</td>
                            <td>Fixed Daily Wage</td>
                            <td><strong>₹650 / day</strong></td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹500.00</span></td>
                            <td><span class="badge badge-light border">Helper Badge</span></td>
                        </tr>
                        @endif
                        <tr>
                            <td><strong>Kavin Anna</strong></td>
                            <td>Store Counter &amp; Closing</td>
                            <td><span class="badge badge-warning text-dark">Bakery Cafe</span></td>
                            <td>98421 00001</td>
                            <td>Store Counter</td>
                            <td>Monthly Salaried</td>
                            <td>₹25,000 / month</td>
                            <td><span class="badge badge-light border">₹0.00</span></td>
                            <td><span class="badge badge-success">&check; Manager</span></td>
                        </tr>
                        <tr>
                            <td><strong>Selvam Master</strong></td>
                            <td>Master Baker &amp; Tea Maker</td>
                            <td><span class="badge badge-warning text-dark">Bakery Cafe</span></td>
                            <td>94420 88123</td>
                            <td>Store Kitchen</td>
                            <td>Monthly Salaried</td>
                            <td>₹18,000 / month</td>
                            <td><span class="badge badge-warning text-dark font-weight-bold">₹1,000.00</span></td>
                            <td><span class="badge badge-success">&check; Food Safety</span></td>
                        </tr>
                        <tr>
                            <td><strong>Paati (Periyamma)</strong></td>
                            <td>Store Helper &amp; Dishwashing</td>
                            <td><span class="badge badge-warning text-dark">Bakery Cafe</span></td>
                            <td>Store Assistant</td>
                            <td>Store Floor</td>
                            <td>Daily Drawer Payout</td>
                            <td><strong>₹350 / day (Drawer)</strong></td>
                            <td><span class="badge badge-light border">₹150.00</span></td>
                            <td><span class="badge badge-light border">Store Assistant</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Monthly & Weekly Payroll Advance Reconciler -->
    <div class="card border-0 shadow-sm rounded bg-white">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <div>
                <h5 class="font-weight-bold m-0 text-dark">
                    <i class="dripicons-wallet text-success mr-1"></i> Payroll &amp; Advance Settlement Reconciler
                </h5>
                <small class="text-muted">Formula: Net Payable = Base Earnings + Batta/Incentives &minus; Advances Deducted</small>
            </div>
            <span class="badge badge-primary font-weight-bold px-3 py-2">October 2026 Settlement</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Staff Member</th>
                            <th>Division</th>
                            <th>Settlement Period</th>
                            <th>Base Earnings</th>
                            <th>Batta / Incentives</th>
                            <th>Advances Deducted</th>
                            <th>Net Payable</th>
                            <th>Payment Channel</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Suresh Kumar</strong></td>
                            <td><span class="badge badge-primary">Tanker</span></td>
                            <td>October 2026</td>
                            <td>₹22,000.00</td>
                            <td class="text-success font-weight-bold">+₹6,500.00 <small>(26 trips)</small></td>
                            <td class="text-danger font-weight-bold">&minus;₹2,000.00</td>
                            <td><strong class="text-success h6">₹26,500.00</strong></td>
                            <td><span class="badge badge-light border">Canara Bank NEFT</span></td>
                            <td><span class="badge badge-success">&check; Disbursed</span></td>
                        </tr>
                        <tr>
                            <td><strong>Vignesh (Vicky)</strong></td>
                            <td><span class="badge badge-success">Water Cans</span></td>
                            <td>Oct 2026 (Week 4)</td>
                            <td>₹7,000.00 <small>(7 days)</small></td>
                            <td class="text-success font-weight-bold">+₹950.00 <small>(vol incentive)</small></td>
                            <td class="text-danger font-weight-bold">&minus;₹1,200.00</td>
                            <td><strong class="text-success h6">₹6,750.00</strong></td>
                            <td><span class="badge badge-light border">Cash Safe Drawer</span></td>
                            <td><span class="badge badge-success">&check; Disbursed</span></td>
                        </tr>
                        <tr>
                            <td><strong>Selvam Master</strong></td>
                            <td><span class="badge badge-warning text-dark">Bakery</span></td>
                            <td>October 2026</td>
                            <td>₹18,000.00</td>
                            <td class="text-success font-weight-bold">+₹1,500.00</td>
                            <td class="text-danger font-weight-bold">&minus;₹1,000.00</td>
                            <td><strong class="text-success h6">₹18,500.00</strong></td>
                            <td><span class="badge badge-light border">GPay (Kavin)</span></td>
                            <td><span class="badge badge-success">&check; Disbursed</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@endsection
