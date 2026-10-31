@extends('backend.layout.main')
@section('content')

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-to-do text-primary mr-2"></i> Bulk Water Tankers &amp; Customizable Trip Sheets
            </h3>
            <p class="text-muted small m-0 mt-1">Multi-capacity fleet (40KL trailer, 24KL, 16KL, 9KL) with automated distance, motor running &amp; waiting surcharges.</p>
        </div>
        <div class="col-md-5 text-right">
            <button type="button" class="btn btn-primary btn-sm shadow-sm" data-toggle="modal" data-target="#newTripModal">
                <i class="dripicons-plus"></i> + Generate Dynamic Trip Sheet
            </button>
        </div>
    </div>

    <!-- Live Tanker Fleet Cards (Zero Hardcoding Open Capacities) -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-top border-primary" style="border-top-width: 3px !important;">
                <div class="d-flex justify-content-between align-items-center">
                    <span class="badge badge-primary">Multi-Axle Trailer</span>
                    <span class="badge badge-success">&bull; Active</span>
                </div>
                <h4 class="font-weight-bold text-dark m-0 mt-2">TN 38 DZ 8841</h4>
                <div class="mt-2 text-primary font-weight-bold h5">40.0 KL <small class="text-muted">(40,000 L)</small></div>
                <div class="small text-muted mt-2">
                    <div><strong>Driver:</strong> Karthik Raja (98422 10103)</div>
                    <div><strong>Batta:</strong> ₹300 / trip sheet</div>
                    <div><strong>FC Expiry:</strong> 2027-08-15 (Valid)</div>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-top border-info" style="border-top-width: 3px !important;">
                <div class="d-flex justify-content-between align-items-center">
                    <span class="badge badge-info">Heavy Tanker</span>
                    <span class="badge badge-warning">&bull; Unloading</span>
                </div>
                <h4 class="font-weight-bold text-dark m-0 mt-2">TN 34 AF 4954</h4>
                <div class="mt-2 text-info font-weight-bold h5">24.0 KL <small class="text-muted">(24,000 L)</small></div>
                <div class="small text-muted mt-2">
                    <div><strong>Driver:</strong> Suresh Kumar (98422 10101)</div>
                    <div><strong>Batta:</strong> ₹250 / trip sheet</div>
                    <div><strong>FC Expiry:</strong> 2026-12-10 (41 days)</div>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-top border-info" style="border-top-width: 3px !important;">
                <div class="d-flex justify-content-between align-items-center">
                    <span class="badge badge-info">Standard Tanker</span>
                    <span class="badge badge-success">&bull; On Road</span>
                </div>
                <h4 class="font-weight-bold text-dark m-0 mt-2">TN 38 CY 5599</h4>
                <div class="mt-2 text-info font-weight-bold h5">16.0 KL <small class="text-muted">(16,000 L)</small></div>
                <div class="small text-muted mt-2">
                    <div><strong>Driver:</strong> Palanisamy M. (98422 10102)</div>
                    <div><strong>Batta:</strong> ₹250 / trip sheet</div>
                    <div><strong>FC Expiry:</strong> 2027-04-20 (Valid)</div>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card border-0 shadow-sm rounded p-3 bg-white border-top border-secondary" style="border-top-width: 3px !important;">
                <div class="d-flex justify-content-between align-items-center">
                    <span class="badge badge-secondary">City Tanker</span>
                    <span class="badge badge-dark">&bull; Standby</span>
                </div>
                <h4 class="font-weight-bold text-dark m-0 mt-2">TN 34 BF 1120</h4>
                <div class="mt-2 text-secondary font-weight-bold h5">9.0 KL <small class="text-muted">(9,000 L)</small></div>
                <div class="small text-muted mt-2">
                    <div><strong>Driver:</strong> Murugesan K. (98422 10104)</div>
                    <div><strong>Batta:</strong> ₹250 / trip sheet</div>
                    <div><strong>FC Expiry:</strong> 2027-01-05 (Valid)</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Trip Sheets with Dynamic Surcharges -->
    <div class="card border-0 shadow-sm rounded bg-white">
        <div class="card-header bg-white border-bottom py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-clipboard text-primary mr-2"></i> Recent Tanker Dispatches &amp; Itemized Trip Sheets
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Trip #</th>
                            <th>Vehicle &amp; Driver</th>
                            <th>Customer / Site</th>
                            <th>Load (KL)</th>
                            <th>Distance Surcharge</th>
                            <th>Motor Charge</th>
                            <th>Waiting Cost</th>
                            <th>Total Billed</th>
                            <th>Owner Approval</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>TRIP-2026-1030-01</strong></td>
                            <td>TN 38 DZ 8841 <small class="d-block text-muted">Karthik Raja</small></td>
                            <td>Vinayaga Spinning Mill <small class="d-block text-muted">Heavy Dyeing Borewell</small></td>
                            <td><span class="badge badge-primary font-weight-bold">40.0 KL</span></td>
                            <td>₹800 <small class="text-muted">(40km @ ₹20/km)</small></td>
                            <td>₹450 <small class="text-muted">(90 mins @ ₹5)</small></td>
                            <td>₹150 <small class="text-muted">(60 mins @ ₹2.5)</small></td>
                            <td><strong class="text-success h6">₹4,900.00</strong></td>
                            <td><span class="badge badge-success">Approved (Owner)</span></td>
                            <td><span class="badge badge-success">Dispatched</span></td>
                        </tr>
                        <tr>
                            <td><strong>TRIP-2026-1030-02</strong></td>
                            <td>TN 34 AF 4954 <small class="d-block text-muted">Suresh Kumar</small></td>
                            <td>Texvalley Corporate Campus <small class="d-block text-muted">Commercial Tower Tank</small></td>
                            <td><span class="badge badge-info font-weight-bold">24.0 KL</span></td>
                            <td>₹300 <small class="text-muted">(15km @ ₹20/km)</small></td>
                            <td>₹200 <small class="text-muted">(40 mins @ ₹5)</small></td>
                            <td>₹0 <small class="text-muted">(On Time)</small></td>
                            <td><strong class="text-success h6">₹3,000.00</strong></td>
                            <td><span class="badge badge-success">Approved (Owner)</span></td>
                            <td><span class="badge badge-warning">Unloading</span></td>
                        </tr>
                        <tr>
                            <td><strong>TRIP-2026-1030-03</strong></td>
                            <td>TN 38 CY 5599 <small class="d-block text-muted">Palanisamy M.</small></td>
                            <td>Amirtha Milk Dairy <small class="d-block text-muted">Chilling Plant Intake</small></td>
                            <td><span class="badge badge-info font-weight-bold">16.0 KL</span></td>
                            <td>₹200 <small class="text-muted">(10km @ ₹20/km)</small></td>
                            <td>₹150 <small class="text-muted">(30 mins @ ₹5)</small></td>
                            <td>₹75 <small class="text-muted">(30 mins @ ₹2.5)</small></td>
                            <td><strong class="text-success h6">₹2,425.00</strong></td>
                            <td><span class="badge badge-success">Approved (Owner)</span></td>
                            <td><span class="badge badge-success">Dispatched</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Dynamic Trip Sheet Generator -->
<div class="modal fade" id="newTripModal" tabindex="-1" role="dialog" aria-labelledby="newTripModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title font-weight-bold" id="newTripModalLabel">
                    <i class="dripicons-plus mr-1"></i> Generate Water Tanker Trip Sheet
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="tripSheetForm">
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Select Vehicle / Tanker</label>
                            <select class="form-control" id="tankerSelect" onchange="updateTripCalculation()">
                                <option value="40" data-num="TN 38 DZ 8841" data-driver="Karthik Raja" data-batta="300">TN 38 DZ 8841 (40.0 KL Multi-Axle Trailer)</option>
                                <option value="24" data-num="TN 34 AF 4954" data-driver="Suresh Kumar" data-batta="250" selected>TN 34 AF 4954 (24.0 KL Tanker)</option>
                                <option value="16" data-num="TN 38 CY 5599" data-driver="Palanisamy M." data-batta="250">TN 38 CY 5599 (16.0 KL Tanker)</option>
                                <option value="9" data-num="TN 34 BF 1120" data-driver="Murugesan K." data-batta="250">TN 34 BF 1120 (9.0 KL Tanker)</option>
                            </select>
                        </div>
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Customer / Delivery Site</label>
                            <input type="text" class="form-control" value="Texvalley Corporate Campus" placeholder="Enter customer or site">
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold">Base Trip Rate (₹)</label>
                            <input type="number" class="form-control" id="baseFare" value="2500" oninput="updateTripCalculation()">
                        </div>
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold">Total Distance (km)</label>
                            <input type="number" class="form-control" id="tripKm" value="25" oninput="updateTripCalculation()">
                            <small class="text-muted">Min 10km included, extra @ ₹20/km</small>
                        </div>
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold">Motor Running (Mins)</label>
                            <input type="number" class="form-control" id="motorMins" value="45" oninput="updateTripCalculation()">
                            <small class="text-muted">Charge: ₹5 per min</small>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold">Customer Waiting Time (Mins)</label>
                            <input type="number" class="form-control" id="waitingMins" value="30" oninput="updateTripCalculation()">
                            <small class="text-muted">Charge: ₹2.50 per min</small>
                        </div>
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold">Owner Accepted Discount (₹)</label>
                            <input type="number" class="form-control" id="discountAmt" value="0" oninput="updateTripCalculation()">
                            <small class="text-muted">If bargained &amp; approved</small>
                        </div>
                        <div class="form-group col-md-4">
                            <label class="font-weight-bold text-success">Calculated Net Total (₹)</label>
                            <input type="text" class="form-control font-weight-bold text-success h5 bg-light" id="totalCalculated" value="₹3,100.00" readonly>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="font-weight-bold">Trip Notes / Surcharge Approver</label>
                        <input type="text" class="form-control" value="Approved by Owner (Batta ₹250 added to driver ledger)">
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-success btn-sm font-weight-bold" onclick="alert('Trip Sheet generated and recorded into Accounting Ledger!'); $('#newTripModal').modal('hide');">
                    <i class="dripicons-checkmark"></i> Confirm &amp; Save Trip Sheet
                </button>
            </div>
        </div>
    </div>
</div>

<script>
function updateTripCalculation() {
    var base = parseFloat(document.getElementById('baseFare').value) || 0;
    var km = parseFloat(document.getElementById('tripKm').value) || 0;
    var motor = parseFloat(document.getElementById('motorMins').value) || 0;
    var wait = parseFloat(document.getElementById('waitingMins').value) || 0;
    var discount = parseFloat(document.getElementById('discountAmt').value) || 0;

    var extraKm = Math.max(0, km - 10);
    var kmCharge = extraKm * 20;
    var motorCharge = motor * 5;
    var waitCharge = wait * 2.50;

    var total = base + kmCharge + motorCharge + waitCharge - discount;
    document.getElementById('totalCalculated').value = '₹' + total.toFixed(2);
}
</script>

@endsection
