@extends('backend.layout.main')
@section('content')

<!-- Leaflet CSS & JS for Interactive Fleet Map -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<div class="container-fluid py-4">
    <!-- Header -->
    <div class="row align-items-center mb-4">
        <div class="col-md-7">
            <h3 class="font-weight-bold text-dark m-0">
                <i class="dripicons-map text-primary mr-2"></i> GPS Fleet Telematics &amp; Stoppage Audit
            </h3>
            <p class="text-muted small m-0 mt-1">Live satellite GPS tracking, anti-theft rest dwell analysis (&gt;30 min stoppage alerts) and claimed fuel vs GPS road km cross-audit.</p>
        </div>
        <div class="col-md-5 text-right">
            <span class="badge badge-success px-3 py-2 font-weight-bold mr-2">&bull; Telemetry Engine Connected</span>
            <button class="btn btn-outline-primary btn-sm" onclick="location.reload()"><i class="dripicons-clockwise"></i> Refresh Pings</button>
        </div>
    </div>

    <!-- Live Leaflet Fleet Map Container -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <h5 class="font-weight-bold m-0 text-dark">
                <i class="dripicons-location text-danger mr-1"></i> Live Real-Time Fleet Map &mdash; Coimbatore &amp; Tiruppur Region
            </h5>
            <div class="small text-muted">
                <span class="mr-3 text-success font-weight-bold">&bull; 4 Moving</span>
                <span class="mr-3 text-warning font-weight-bold">&bull; 1 Unloading</span>
                <span class="text-secondary font-weight-bold">&bull; 1 Standby</span>
            </div>
        </div>
        <div class="card-body p-0">
            <div id="fleetMap" style="height: 480px; width: 100%; z-index: 1;"></div>
        </div>
    </div>

    <!-- Rest Dwell & Stoppage Analysis Table (> 30 Mins Stoppage Detection) -->
    <div class="card border-0 shadow-sm rounded bg-white mb-4">
        <div class="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
            <div>
                <h5 class="font-weight-bold m-0 text-dark">
                    <i class="dripicons-time-reverse text-warning mr-1"></i> Rest Dwell &amp; Unmapped Stoppage Analysis (&gt;30 Mins)
                </h5>
                <small class="text-muted">Prevents driver time fraud and unauthorized side trips</small>
            </div>
            <span class="badge badge-warning text-dark font-weight-bold px-3 py-2">1 Suspicious Dwell Flagged</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0 text-nowrap">
                    <thead class="thead-light">
                        <tr>
                            <th>Vehicle</th>
                            <th>Driver</th>
                            <th>Halt Location / Landmark</th>
                            <th>Halt Duration</th>
                            <th>Ignition Status</th>
                            <th>Customer Verified?</th>
                            <th>Audit Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>TN 34 AF 4954 (24KL)</strong></td>
                            <td>Suresh Kumar</td>
                            <td>Texvalley Unloading Bay 2</td>
                            <td><strong>42 Minutes</strong></td>
                            <td>Ignition OFF &bull; Pump ON</td>
                            <td><span class="badge badge-success">&check; Legitimate Tank Discharge</span></td>
                            <td><span class="badge badge-success">Audit Pass</span></td>
                        </tr>
                        <tr>
                            <td><strong>TN 38 BX 4412 (Tata Ace)</strong></td>
                            <td>Vignesh (Vicky)</td>
                            <td>Near Town Hall Flyover Service Road</td>
                            <td><strong class="text-danger">54 Minutes</strong></td>
                            <td>Ignition OFF &bull; Pump OFF</td>
                            <td><span class="badge badge-danger">&times; Unmapped Stop (No Customer)</span></td>
                            <td><span class="badge badge-danger px-3 py-1 font-weight-bold">REST DWELL ALERT &gt; 30M</span></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", function () {
    var map = L.map('fleetMap').setView([11.0168, 76.9558], 11);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    var vehicles = [
        { num: 'TN 38 DZ 8841', type: '40.0 KL Trailer', driver: 'Karthik Raja', lat: 11.0812, lng: 77.0421, status: 'Moving (46 km/h)', dest: 'Vinayaga Spinning Mill' },
        { num: 'TN 34 AF 4954', type: '24.0 KL Tanker', driver: 'Suresh Kumar', lat: 11.0421, lng: 77.0112, status: 'Unloading (0 km/h)', dest: 'Texvalley Corporate Campus' },
        { num: 'TN 38 CY 5599', type: '16.0 KL Tanker', driver: 'Palanisamy M.', lat: 11.0255, lng: 76.9821, status: 'Moving (38 km/h)', dest: 'Amirtha Milk Dairy' },
        { num: 'TN 34 BF 1120', type: '9.0 KL Tanker', driver: 'Murugesan K.', lat: 11.0112, lng: 76.9512, status: 'Standby (0 km/h)', dest: 'Borewell Plant 1 Yard' },
        { num: 'TN 38 BX 4412', type: 'Tata Ace (70 Cans)', driver: 'Vignesh (Vicky)', lat: 11.0182, lng: 76.9641, status: 'Delivering Stop #14', dest: 'Race Course Road' }
    ];

    vehicles.forEach(function (v) {
        var marker = L.marker([v.lat, v.lng]).addTo(map);
        marker.bindPopup(
            "<strong>" + v.num + "</strong> (" + v.type + ")<br>" +
            "Driver: " + v.driver + "<br>" +
            "Status: <span style='color:green;'>" + v.status + "</span><br>" +
            "Destination: " + v.dest
        );
    });
});
</script>

@endsection
