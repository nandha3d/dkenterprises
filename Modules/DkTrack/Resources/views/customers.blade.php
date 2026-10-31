@extends('backend.layout.main')
@section('content')

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-location text-danger mr-2"></i> Customer Management &amp; Anti-Fraud GPS Geo-Locking
            </h3>
            <p class="text-muted small m-0 mt-1">Pin customer shop GPS coordinates to prevent delivery fraud. Automatic Haversine verification on every drop confirmation.</p>
        </div>
        <div class="col-md-5 text-right">
            <button type="button" class="btn btn-primary btn-sm shadow-sm" data-toggle="modal" data-target="#addCustomerModal">
                <i class="dripicons-plus"></i> + Add Customer &amp; Pin Geo-Fence
            </button>
        </div>
    </div>

    <!-- Live Haversine Geofence Delivery Feed -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-radar text-primary mr-1"></i> Live Haversine Distance Geofence Verification Feed
            </h5>
            <small class="text-muted">Threshold: 75m for city retail &bull; 150m-200m for industrial estates</small>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Customer Name</th>
                            <th>Pinned Shop Coordinates</th>
                            <th>Driver Drop Coordinates</th>
                            <th>GPS Distance</th>
                            <th>Geofence Threshold</th>
                            <th>Anti-Fraud Audit Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>Aran Cafe - 1</strong> <small class="text-muted d-block">Race Course Road</small></td>
                            <td><code>11.018221, 76.964119</code></td>
                            <td><code>11.018235, 76.964132</code></td>
                            <td><strong class="text-success">14.5 meters</strong></td>
                            <td>75 meters</td>
                            <td><span class="badge badge-success px-3 py-1">&check; VERIFIED IN-SHOP</span></td>
                        </tr>
                        <tr>
                            <td><strong>Aran Cafe - 2</strong> <small class="text-muted d-block">Gandhipuram Cross</small></td>
                            <td><code>11.021450, 76.968920</code></td>
                            <td><code>11.021470, 76.968940</code></td>
                            <td><strong class="text-success">21.0 meters</strong></td>
                            <td>75 meters</td>
                            <td><span class="badge badge-success px-3 py-1">&check; VERIFIED IN-SHOP</span></td>
                        </tr>
                        <tr>
                            <td><strong>Texvalley Corporate Campus</strong> <small class="text-muted d-block">Heavy Industrial Gate</small></td>
                            <td><code>11.332400, 77.712100</code></td>
                            <td><code>11.332430, 77.712140</code></td>
                            <td><strong class="text-success">35.0 meters</strong></td>
                            <td>150 meters</td>
                            <td><span class="badge badge-success px-3 py-1">&check; VERIFIED IN-SHOP</span></td>
                        </tr>
                        <tr>
                            <td><strong>Santha Company (Shop)</strong> <small class="text-muted d-block">Town Hall Circle</small></td>
                            <td><code>11.026800, 76.974200</code></td>
                            <td><code>11.030500, 76.975100</code></td>
                            <td><strong class="text-danger">420.0 meters</strong></td>
                            <td>75 meters</td>
                            <td><span class="badge badge-danger px-3 py-1">&times; MISMATCH FRAUD ALERT</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Master Customer List with Geo-Lock Pinning -->
    <div class="card border-0 shadow-sm rounded bg-white">
        <div class="card-header bg-white border-bottom py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-user-id text-danger mr-1"></i> Master Customer Directory &amp; Dynamic Rate Slabs
            </h5>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Customer Code</th>
                            <th>Company / Shop</th>
                            <th>Division</th>
                            <th>Contact Person</th>
                            <th>Phone</th>
                            <th>Rate Slab / Terms</th>
                            <th>Credit Balance</th>
                            <th>GPS Geo-Lock</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><code>CUST-CAN-001</code></td>
                            <td><strong>Aran Cafe - 1</strong></td>
                            <td><span class="badge badge-success">20L Water Cans</span></td>
                            <td>Mr. Senthil</td>
                            <td>98421 55601</td>
                            <td>₹20.00 / Can</td>
                            <td>₹1,420.00</td>
                            <td><span class="badge badge-success">&check; Pinned (75m radius)</span></td>
                            <td><button class="btn btn-outline-primary btn-sm" onclick="alert('Geo-lock coordinates: 11.018221, 76.964119')"><i class="dripicons-location"></i> View</button></td>
                        </tr>
                        <tr>
                            <td><code>CUST-TNK-001</code></td>
                            <td><strong>Texvalley Corporate Campus</strong></td>
                            <td><span class="badge badge-primary">Bulk Water Tankers</span></td>
                            <td>Estate Manager</td>
                            <td>94433 12890</td>
                            <td>Base ₹2,500 + ₹20/km + ₹5/min motor</td>
                            <td>₹12,450.00</td>
                            <td><span class="badge badge-success">&check; Pinned (150m radius)</span></td>
                            <td><button class="btn btn-outline-primary btn-sm" onclick="alert('Geo-lock coordinates: 11.332400, 77.712100')"><i class="dripicons-location"></i> View</button></td>
                        </tr>
                        <tr>
                            <td><code>CUST-TNK-002</code></td>
                            <td><strong>The Chennai Silks (Dyeing Unit)</strong></td>
                            <td><span class="badge badge-primary">Bulk Water Tankers</span></td>
                            <td>Purchase Officer</td>
                            <td>98430 44810</td>
                            <td>Base ₹3,800 + ₹22/km + ₹5/min motor</td>
                            <td>₹28,400.00</td>
                            <td><span class="badge badge-success">&check; Pinned (200m radius)</span></td>
                            <td><button class="btn btn-outline-primary btn-sm" onclick="alert('Geo-lock coordinates: 11.084500, 77.294100')"><i class="dripicons-location"></i> View</button></td>
                        </tr>
                        <tr>
                            <td><code>CUST-CAN-004</code></td>
                            <td><strong>Santha Company</strong></td>
                            <td><span class="badge badge-success">20L Water Cans</span></td>
                            <td>Proprietor</td>
                            <td>97871 00293</td>
                            <td>₹20.00 / Can</td>
                            <td>₹680.00</td>
                            <td><span class="badge badge-warning">Pinned (75m radius)</span></td>
                            <td><button class="btn btn-outline-danger btn-sm" onclick="alert('Audit Alert: Driver confirmed drop 420m away from pinned shop!')"><i class="dripicons-warning"></i> Audit Alert</button></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@endsection
