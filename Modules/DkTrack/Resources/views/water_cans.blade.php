@extends('backend.layout.main')
@section('content')

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-drop text-success mr-2"></i> Packaged Drinking Water Distribution &amp; Logistics
            </h3>
            <p class="text-muted small m-0 mt-1">Multi-plant refill trips (3 loads/day), route odometer audits, photo verification &amp; customer container balance security.</p>
        </div>
        <div class="col-md-5 text-right">
            <button type="button" class="btn btn-outline-success btn-sm mr-2 shadow-sm" data-toggle="modal" data-target="#plantRefillModal">
                <i class="dripicons-plus"></i> + Log Plant Refill Trip (Loads 1, 2, 3)
            </button>
            <button type="button" class="btn btn-success btn-sm shadow-sm" data-toggle="modal" data-target="#canDeliveryModal">
                <i class="dripicons-checkmark"></i> + Quick Customer Drop
            </button>
        </div>
    </div>

    <!-- Daily Plant Refill Trips Summary (3 Trips Completed Today) -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-retweet text-success mr-1"></i> Today's RO Plant Intake Refills &mdash; Tata Ace TN 38 BX 4412
            </h5>
            <span class="badge badge-success px-3 py-2 font-weight-bold">3 Refill Trips &bull; 213 Total Cans Refilled</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Refill Run</th>
                            <th>Time</th>
                            <th>Plant Source</th>
                            <th>Cans Loaded</th>
                            <th>Plant Cost (@ ₹8/can)</th>
                            <th>Odometer Reading</th>
                            <th>Proof Verification</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Trip #1 (Morning Run)</strong></td>
                            <td>08:15 AM</td>
                            <td>Main RO Mineral Water Plant</td>
                            <td><span class="badge badge-primary font-weight-bold">70 Cans</span></td>
                            <td>₹560.00</td>
                            <td>142,810 km</td>
                            <td><span class="badge badge-success">&check; Photo &amp; GPS Verified</span></td>
                            <td><span class="badge badge-success">Completed &bull; Delivered</span></td>
                        </tr>
                        <tr>
                            <td><strong>Trip #2 (Mid-Day Refill)</strong></td>
                            <td>12:30 PM</td>
                            <td>Main RO Mineral Water Plant</td>
                            <td><span class="badge badge-primary font-weight-bold">73 Cans</span></td>
                            <td>₹584.00</td>
                            <td>142,838 km <small class="text-muted">(+28 km)</small></td>
                            <td><span class="badge badge-success">&check; Photo &amp; GPS Verified</span></td>
                            <td><span class="badge badge-success">Completed &bull; Delivered</span></td>
                        </tr>
                        <tr>
                            <td><strong>Trip #3 (Evening Refill)</strong></td>
                            <td>03:45 PM</td>
                            <td>Main RO Mineral Water Plant</td>
                            <td><span class="badge badge-primary font-weight-bold">70 Cans</span></td>
                            <td>₹560.00</td>
                            <td>142,866 km <small class="text-muted">(+28 km)</small></td>
                            <td><span class="badge badge-success">&check; Photo &amp; GPS Verified</span></td>
                            <td><span class="badge badge-success">Completed &bull; Delivering</span></td>
                        </tr>
                    </tbody>
                    <tfoot class="thead-light font-weight-bold">
                        <tr>
                            <td colspan="3">Total Daily RO Plant Intakes:</td>
                            <td class="text-primary font-weight-bold">213 Cans</td>
                            <td class="text-danger font-weight-bold">₹1,704.00</td>
                            <td colspan="3" class="text-right text-muted font-weight-normal">Total Route Distance Covered: 56.4 km</td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>

    <!-- Live Customer Can Security & Anti-Theft Balance Ledger -->
    <div class="card border-0 shadow-sm rounded bg-white">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-shield text-primary mr-1"></i> Customer Live Can Balance Ledger (Anti-Loss Security)
            </h5>
            <small class="text-muted">Prevents jar loss: Track cans delivered vs empty jars returned</small>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Customer Name</th>
                            <th>Contact Phone</th>
                            <th>Today Delivered</th>
                            <th>Empties Returned</th>
                            <th>Current Empty Held</th>
                            <th>Deposit Status</th>
                            <th>Geo-Lock Verification</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Aran Cafe - 1</strong></td>
                            <td>98421 55601</td>
                            <td><span class="badge badge-success">+15 Cans</span></td>
                            <td><span class="badge badge-info">-15 Returned</span></td>
                            <td><strong>15 Cans Held</strong></td>
                            <td><span class="badge badge-success">₹3,000 Deposit Active</span></td>
                            <td><span class="badge badge-success">&check; GPS Verified (14m fix)</span></td>
                        </tr>
                        <tr>
                            <td><strong>Aran Cafe - 2</strong></td>
                            <td>98421 55602</td>
                            <td><span class="badge badge-success">+10 Cans</span></td>
                            <td><span class="badge badge-info">-10 Returned</span></td>
                            <td><strong>10 Cans Held</strong></td>
                            <td><span class="badge badge-success">₹2,000 Deposit Active</span></td>
                            <td><span class="badge badge-success">&check; GPS Verified (21m fix)</span></td>
                        </tr>
                        <tr>
                            <td><strong>Black Pekoe Tea</strong></td>
                            <td>99441 33201</td>
                            <td><span class="badge badge-success">+8 Cans</span></td>
                            <td><span class="badge badge-info">-8 Returned</span></td>
                            <td><strong>12 Cans Held</strong></td>
                            <td><span class="badge badge-success">₹2,400 Deposit Active</span></td>
                            <td><span class="badge badge-success">&check; GPS Verified (18m fix)</span></td>
                        </tr>
                        <tr>
                            <td><strong>Santha Company</strong></td>
                            <td>97871 00293</td>
                            <td><span class="badge badge-success">+20 Cans</span></td>
                            <td><span class="badge badge-warning">-15 Returned</span></td>
                            <td><strong class="text-danger">25 Cans Held</strong></td>
                            <td><span class="badge badge-warning">₹2,000 Deposit (+5 Deficit)</span></td>
                            <td><span class="badge badge-danger">&times; Mismatch Alert (420m away)</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Log Plant Refill Trip -->
<div class="modal fade" id="plantRefillModal" tabindex="-1" role="dialog" aria-labelledby="plantRefillModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title font-weight-bold" id="plantRefillModalLabel">
                    <i class="dripicons-plus mr-1"></i> Log RO Plant Refill Trip
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="refillTripForm">
                    <div class="form-group">
                        <label class="font-weight-bold">Trip / Refill Sequence</label>
                        <select class="form-control">
                            <option>Trip #1 (Morning Refill)</option>
                            <option>Trip #2 (Mid-Day Refill)</option>
                            <option>Trip #3 (Evening Refill)</option>
                            <option>Trip #4 (Special Order Extra Refill)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="font-weight-bold">Vehicle</label>
                        <input type="text" class="form-control" value="TN 38 BX 4412 (Tata Ace - Vignesh)" readonly>
                    </div>
                    <div class="form-row">
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">Cans Loaded</label>
                            <input type="number" class="form-control font-weight-bold text-success" value="70">
                        </div>
                        <div class="form-group col-md-6">
                            <label class="font-weight-bold">RO Plant Rate / Can (₹)</label>
                            <input type="number" class="form-control" value="8">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="font-weight-bold">Truck Odometer at Plant Gate (km)</label>
                        <input type="number" class="form-control" value="142866">
                    </div>
                    <div class="form-group">
                        <label class="font-weight-bold">Upload Plant Gate Photo / Slip</label>
                        <div class="custom-file">
                            <input type="file" class="custom-file-input" id="plantPhoto">
                            <label class="custom-file-label" for="plantPhoto">Capture Photo with Driver App...</label>
                        </div>
                        <small class="text-muted">Recorded with GPS timestamp: 11.018221, 76.964119</small>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-success btn-sm font-weight-bold" onclick="alert('RO Plant Refill Trip logged! Inventory incremented.'); $('#plantRefillModal').modal('hide');">
                    <i class="dripicons-checkmark"></i> Save Refill Trip
                </button>
            </div>
        </div>
    </div>
</div>

@endsection
