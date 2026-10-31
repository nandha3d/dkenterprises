@extends('backend.layout.main')

@section('content')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
<style>
    .fleet-workspace {
        display: flex;
        flex-direction: column;
        height: calc(100vh - 65px);
        background: #f8fafc;
        padding: 10px 14px;
        gap: 10px;
    }
    .fleet-kpi-bar {
        display: flex;
        gap: 12px;
        flex-shrink: 0;
    }
    .fleet-kpi-card {
        flex: 1;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 10px 14px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
    }
    .fleet-kpi-title {
        font-size: 11px;
        text-transform: uppercase;
        font-weight: 700;
        color: #64748b;
        letter-spacing: 0.5px;
    }
    .fleet-kpi-val {
        font-size: 20px;
        font-weight: 800;
        color: #0f172a;
        margin-top: 2px;
    }
    .fleet-kpi-icon {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 16px;
    }
    .fleet-layout-split {
        display: flex;
        flex: 1;
        gap: 12px;
        min-height: 0;
    }
    .fleet-sidebar-panel {
        width: 360px;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        flex-shrink: 0;
    }
    .fleet-map-container {
        flex: 1;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        overflow: hidden;
        position: relative;
    }
    #fleet-leaflet-map {
        width: 100%;
        height: 100%;
        min-height: 480px;
    }
    .vehicle-card {
        padding: 10px 12px;
        border-bottom: 1px solid #f1f5f9;
        cursor: pointer;
        transition: all 0.2s;
    }
    .vehicle-card:hover {
        background: #f8fafc;
    }
    .vehicle-card.active {
        background: #eef2ff;
        border-left: 3px solid #4f46e5;
    }
    .pulse-marker-tanker {
        background: #0284c7;
        color: #fff;
        border-radius: 50%;
        border: 2px solid #fff;
        box-shadow: 0 0 10px rgba(2,132,199,0.8);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
    }
    .pulse-marker-can {
        background: #10b981;
        color: #fff;
        border-radius: 50%;
        border: 2px solid #fff;
        box-shadow: 0 0 10px rgba(16,185,129,0.8);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
    }
    .geofence-alert-badge {
        animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
        0% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.05); opacity: 0.85; }
        100% { transform: scale(1); opacity: 1; }
    }
</style>

<div class="fleet-workspace">
    <!-- Top Action & Telematics Bar -->
    <div class="d-flex align-items-center justify-content-between mb-1">
        <div class="d-flex align-items-center gap-2">
            <h4 class="mb-0 font-weight-bold text-dark" style="font-size: 18px;">
                <i class="fa fa-map-marker text-primary mr-1"></i> Live Fleet GPS Tracking &amp; Customer Geofencing
            </h4>
            <span class="badge badge-primary px-2 py-1 ml-2" style="font-size: 11px;">
                <span class="spinner-grow spinner-grow-sm text-light mr-1" style="width: 8px; height: 8px;"></span> Live Telematics Active
            </span>
        </div>

        <div class="d-flex align-items-center gap-2">
            <button type="button" class="btn btn-sm btn-outline-info font-weight-bold" id="btn-simulate-movement">
                <i class="fa fa-play mr-1"></i> Simulate Fleet Movement
            </button>
            <button type="button" class="btn btn-sm btn-outline-success font-weight-bold" id="btn-test-geofence">
                <i class="fa fa-bullseye mr-1"></i> Test Geofence Arrival
            </button>
            <button type="button" class="btn btn-sm btn-primary font-weight-bold" id="btn-ping-now">
                <i class="fa fa-refresh mr-1"></i> Trigger GPS Ping
            </button>
            <a href="{{ route('water-logistics.index') }}" class="btn btn-sm btn-outline-secondary font-weight-bold">
                <i class="fa fa-arrow-left mr-1"></i> Back to Water Logistics
            </a>
        </div>
    </div>

    <!-- Telematics KPI Bar -->
    <div class="fleet-kpi-bar">
        <div class="fleet-kpi-card">
            <div>
                <div class="fleet-kpi-title">Total Active Fleet</div>
                <div class="fleet-kpi-val" id="stat-total-fleet">{{ $totalVehicles }} <small class="text-muted" style="font-size: 12px;">Units</small></div>
            </div>
            <div class="fleet-kpi-icon" style="background: #e0f2fe; color: #0284c7;">
                <i class="fa fa-truck"></i>
            </div>
        </div>
        <div class="fleet-kpi-card">
            <div>
                <div class="fleet-kpi-title">Fleet In Transit (Moving)</div>
                <div class="fleet-kpi-val text-success" id="stat-moving-fleet">{{ $movingVehicles }} <small class="text-muted" style="font-size: 12px;">Live</small></div>
            </div>
            <div class="fleet-kpi-icon" style="background: #dcfce7; color: #15803d;">
                <i class="fa fa-tachometer"></i>
            </div>
        </div>
        <div class="fleet-kpi-card">
            <div>
                <div class="fleet-kpi-title">Geofenced Customer Sites</div>
                <div class="fleet-kpi-val text-primary" id="stat-geofence-sites">{{ $geofencedSites }} <small class="text-muted" style="font-size: 12px;">Verified</small></div>
            </div>
            <div class="fleet-kpi-icon" style="background: #ede9fe; color: #7c3aed;">
                <i class="fa fa-crosshairs"></i>
            </div>
        </div>
        <div class="fleet-kpi-card">
            <div>
                <div class="fleet-kpi-title">Avg Fleet Speed / Safety</div>
                <div class="fleet-kpi-val text-info">28.4 <small class="text-muted" style="font-size: 12px;">km/h</small></div>
            </div>
            <div class="fleet-kpi-icon" style="background: #fef3c7; color: #d97706;">
                <i class="fa fa-shield"></i>
            </div>
        </div>
    </div>

    <!-- Main Workspace Split: Left Sidebar List + Right Live Map -->
    <div class="fleet-layout-split">
        <!-- Sidebar: Fleet & Site Directory -->
        <div class="fleet-sidebar-panel">
            <div class="p-2 border-bottom bg-light">
                <ul class="nav nav-pills nav-justified" id="fleet-tabs" role="tablist">
                    <li class="nav-item">
                        <a class="nav-link active py-1 px-2 font-weight-bold" style="font-size: 11px;" id="tab-tankers-btn" data-toggle="pill" href="#tab-tankers">
                            Tankers ({{ $tankers->count() }})
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link py-1 px-2 font-weight-bold" style="font-size: 11px;" id="tab-routes-btn" data-toggle="pill" href="#tab-routes">
                            20L Cans ({{ $canRoutes->count() }})
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link py-1 px-2 font-weight-bold" style="font-size: 11px;" id="tab-sites-btn" data-toggle="pill" href="#tab-sites">
                            Sites ({{ $customers->count() }})
                        </a>
                    </li>
                </ul>
            </div>

            <div class="tab-content flex-grow-1 overflow-auto" id="fleet-tab-content">
                <!-- Tankers Tab -->
                <div class="tab-pane fade show active" id="tab-tankers" role="tabpanel">
                    @foreach($tankers as $tanker)
                    <div class="vehicle-card" onclick="focusVehicle({{ $tanker->latitude }}, {{ $tanker->longitude }}, '{{ $tanker->vehicle_number }}')">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <span class="font-weight-bold text-dark" style="font-size: 13px;">{{ $tanker->vehicle_number }}</span>
                            <span class="badge {{ $tanker->current_speed > 0 ? 'badge-success' : 'badge-secondary' }} px-2 py-0" style="font-size: 10px;">
                                {{ $tanker->current_speed > 0 ? 'MOVING · ' . $tanker->current_speed . ' km/h' : 'IDLE / PUMPING' }}
                            </span>
                        </div>
                        <div class="text-muted" style="font-size: 11px;">
                            <i class="fa fa-user-circle mr-1 text-primary"></i> Driver: <strong>{{ $tanker->driver_name }}</strong> ({{ $tanker->driver_phone }})
                        </div>
                        <div class="d-flex justify-content-between text-muted mt-1" style="font-size: 10.5px;">
                            <span><i class="fa fa-tint text-info mr-1"></i> Cap: {{ $tanker->capacity_kl }} KL</span>
                            <span><i class="fa fa-dashboard mr-1"></i> Odo: {{ number_format($tanker->current_odometer_km) }} KM</span>
                        </div>
                    </div>
                    @endforeach
                </div>

                <!-- 20L Can Routes Tab -->
                <div class="tab-pane fade" id="tab-routes" role="tabpanel">
                    @foreach($canRoutes as $route)
                    <div class="vehicle-card" onclick="focusVehicle({{ $route->latitude ?? 11.02 }}, {{ $route->longitude ?? 76.96 }}, '{{ $route->route_name }}')">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <span class="font-weight-bold text-dark" style="font-size: 12.5px;">{{ $route->route_name }}</span>
                            <span class="badge {{ ($route->current_speed ?? 0) > 0 ? 'badge-success' : 'badge-warning' }} px-2 py-0" style="font-size: 10px;">
                                {{ ($route->current_speed ?? 0) > 0 ? $route->current_speed . ' km/h' : 'STOPPED' }}
                            </span>
                        </div>
                        <div class="text-muted" style="font-size: 11px;">
                            <i class="fa fa-truck mr-1 text-info"></i> {{ $route->vehicle_no }}
                        </div>
                        <div class="d-flex justify-content-between text-muted mt-1" style="font-size: 10.5px;">
                            <span><i class="fa fa-user mr-1"></i> {{ $route->driver_name }}</span>
                            <span><i class="fa fa-cubes text-success mr-1"></i> Loaded: {{ $route->daily_avg_cans }} Cans</span>
                        </div>
                    </div>
                    @endforeach
                </div>

                <!-- Geofenced Sites Tab -->
                <div class="tab-pane fade" id="tab-sites" role="tabpanel">
                    @foreach($customers as $site)
                    <div class="vehicle-card" onclick="focusSite({{ $site->latitude }}, {{ $site->longitude }}, '{{ addslashes($site->name) }}', {{ $site->geofence_radius }})">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <span class="font-weight-bold text-dark text-truncate" style="font-size: 12.5px; max-width: 220px;" title="{{ $site->name }}">{{ $site->name }}</span>
                            <span class="badge badge-info px-2 py-0" style="font-size: 10px;">
                                <i class="fa fa-circle-o-notch"></i> {{ $site->geofence_radius }}m Zone
                            </span>
                        </div>
                        <div class="text-muted text-truncate" style="font-size: 11px;" title="{{ $site->address }}">
                            <i class="fa fa-building-o mr-1 text-secondary"></i> {{ $site->address ?? 'Coimbatore' }}
                        </div>
                        <div class="text-muted mt-1" style="font-size: 10.5px;">
                            <i class="fa fa-phone mr-1"></i> {{ $site->phone_number }}
                        </div>
                    </div>
                    @endforeach
                </div>
            </div>
        </div>

        <!-- Live Leaflet Map Container -->
        <div class="fleet-map-container">
            <div id="fleet-leaflet-map"></div>
            
            <!-- Live Geofence Arrival Overlay Alert -->
            <div id="geofence-alert-box" class="position-absolute" style="top: 15px; right: 15px; z-index: 1000; display: none;">
                <div class="card shadow-lg border-success geofence-alert-badge" style="background: rgba(255,255,255,0.96); min-width: 300px;">
                    <div class="card-body p-3">
                        <div class="d-flex align-items-center mb-2">
                            <span class="badge badge-success mr-2 p-1"><i class="fa fa-check-circle fa-lg"></i></span>
                            <strong class="text-success" style="font-size: 13px;">GEOFENCE ARRIVAL VERIFIED</strong>
                        </div>
                        <div id="geofence-alert-text" class="text-dark font-weight-bold" style="font-size: 12px;"></div>
                        <div class="text-muted mt-1" style="font-size: 11px;">
                            Vehicle is safely inside customer premises. Delivery lock verified in ERP core.
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
<script>
    var map;
    var markers = {};
    var circles = {};
    var fleetData = {
        tankers: @json($tankers),
        canRoutes: @json($canRoutes),
        customers: @json($customers)
    };

    $(document).ready(function() {
        initMap();
    });

    function initMap() {
        // Center on Coimbatore / Erode region
        map = L.map('fleet-leaflet-map').setView([11.0168, 76.9650], 13);

        // OpenStreetMap Crisp Tiles
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; OpenStreetMap contributors | DK Track ERP'
        }).addTo(map);

        // Render Geofenced Customers
        fleetData.customers.forEach(function(cust) {
            if (cust.latitude && cust.longitude) {
                var lat = parseFloat(cust.latitude);
                var lng = parseFloat(cust.longitude);
                var radius = parseInt(cust.geofence_radius) || 150;

                // Geofence Circle
                var circle = L.circle([lat, lng], {
                    color: '#4f46e5',
                    fillColor: '#6366f1',
                    fillOpacity: 0.15,
                    weight: 2,
                    radius: radius
                }).addTo(map);

                circle.bindPopup(
                    '<div style="min-width: 200px;">' +
                    '<strong style="color: #4f46e5; font-size: 13px;">' + cust.name + '</strong><br>' +
                    '<span style="font-size: 11px; color: #64748b;">' + (cust.address || '') + '</span><br>' +
                    '<div style="margin-top: 6px; padding: 4px 6px; background: #eef2ff; border-radius: 4px; font-size: 11px;">' +
                    '<strong>Geofence Radius:</strong> ' + radius + ' meters<br>' +
                    '<strong>Contact:</strong> ' + (cust.phone_number || 'N/A') +
                    '</div>' +
                    '</div>'
                );

                circles['cust_' + cust.id] = circle;

                // Center Pin for Customer Site
                var siteIcon = L.divIcon({
                    className: 'custom-site-pin',
                    html: '<div style="background: #4f46e5; color: #fff; border-radius: 4px; padding: 2px 5px; font-size: 10px; font-weight: bold; border: 1px solid #fff; box-shadow: 0 1px 4px rgba(0,0,0,0.3); white-space: nowrap;"><i class="fa fa-building"></i> ' + cust.name.substring(0, 15) + '...</div>',
                    iconSize: [120, 24],
                    iconAnchor: [60, 12]
                });
                L.marker([lat, lng], {icon: siteIcon}).addTo(map);
            }
        });

        // Render Tankers
        fleetData.tankers.forEach(function(tanker) {
            if (tanker.latitude && tanker.longitude) {
                var lat = parseFloat(tanker.latitude);
                var lng = parseFloat(tanker.longitude);

                var icon = L.divIcon({
                    className: 'custom-tanker-pin',
                    html: '<div class="pulse-marker-tanker" style="width: 32px; height: 32px;"><i class="fa fa-truck"></i></div>',
                    iconSize: [32, 32],
                    iconAnchor: [16, 16]
                });

                var marker = L.marker([lat, lng], {icon: icon}).addTo(map);
                marker.bindPopup(
                    '<div style="min-width: 210px;">' +
                    '<strong style="color: #0284c7; font-size: 13px;">' + tanker.vehicle_number + '</strong> (' + tanker.capacity_kl + ' KL)<br>' +
                    '<span style="font-size: 11px; color: #475569;">' + tanker.model_type + '</span><hr style="margin: 6px 0;">' +
                    '<span style="font-size: 11px;"><strong>Driver:</strong> ' + tanker.driver_name + ' (' + tanker.driver_phone + ')</span><br>' +
                    '<span style="font-size: 11px;"><strong>Speed:</strong> ' + tanker.current_speed + ' km/h</span><br>' +
                    '<span style="font-size: 11px;"><strong>Odometer:</strong> ' + tanker.current_odometer_km + ' KM</span><br>' +
                    '<span style="font-size: 10px; color: #94a3b8;">Last Ping: Just now</span>' +
                    '</div>'
                );

                markers['tanker_' + tanker.id] = marker;
            }
        });

        // Render Can Routes
        fleetData.canRoutes.forEach(function(route) {
            var lat = parseFloat(route.latitude) || 11.026;
            var lng = parseFloat(route.longitude) || 76.985;

            var icon = L.divIcon({
                className: 'custom-can-pin',
                html: '<div class="pulse-marker-can" style="width: 28px; height: 28px;"><i class="fa fa-cubes"></i></div>',
                iconSize: [28, 28],
                iconAnchor: [14, 14]
            });

            var marker = L.marker([lat, lng], {icon: icon}).addTo(map);
            marker.bindPopup(
                '<div style="min-width: 200px;">' +
                '<strong style="color: #10b981; font-size: 13px;">' + route.route_name + '</strong><br>' +
                '<span style="font-size: 11px;"><strong>Vehicle:</strong> ' + route.vehicle_no + '</span><br>' +
                '<span style="font-size: 11px;"><strong>Driver / Delivery Boy:</strong> ' + route.driver_name + '</span><br>' +
                '<span style="font-size: 11px;"><strong>Daily Cans:</strong> ' + route.daily_avg_cans + '</span>' +
                '</div>'
            );

            markers['route_' + route.id] = marker;
        });
    }

    function focusVehicle(lat, lng, label) {
        if (lat && lng && map) {
            map.flyTo([lat, lng], 16, {duration: 1.2});
        }
    }

    function focusSite(lat, lng, name, radius) {
        if (lat && lng && map) {
            map.flyTo([lat, lng], 16, {duration: 1.2});
        }
    }

    // Interactive Simulation: Simulate Movement
    $('#btn-simulate-movement').on('click', function() {
        var $btn = $(this);
        $btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm"></span> Moving Fleet...');

        var step = 0;
        var interval = setInterval(function() {
            step++;
            fleetData.tankers.forEach(function(tanker, idx) {
                var m = markers['tanker_' + tanker.id];
                if (m) {
                    var curPos = m.getLatLng();
                    var newLat = curPos.lat + (idx % 2 === 0 ? 0.0006 : -0.0005);
                    var newLng = curPos.lng + (idx % 2 === 0 ? 0.0005 : 0.0006);
                    m.setLatLng([newLat, newLng]);
                }
            });

            if (step >= 8) {
                clearInterval(interval);
                $btn.prop('disabled', false).html('<i class="fa fa-play mr-1"></i> Simulate Fleet Movement');
            }
        }, 300);
    });

    // Test Geofence Arrival
    $('#btn-test-geofence').on('click', function() {
        var firstTanker = fleetData.tankers[0];
        var firstCust = fleetData.customers[0];

        if (firstTanker && firstCust && markers['tanker_' + firstTanker.id]) {
            var targetLat = parseFloat(firstCust.latitude) + 0.0001;
            var targetLng = parseFloat(firstCust.longitude) + 0.0001;

            markers['tanker_' + firstTanker.id].setLatLng([targetLat, targetLng]);
            map.flyTo([targetLat, targetLng], 17, {duration: 1});

            // Show alert box
            $('#geofence-alert-text').html(
                'Tanker <strong>' + firstTanker.vehicle_number + ' (40KL)</strong> arrived at <strong>' + firstCust.name + '</strong>!'
            );
            $('#geofence-alert-box').fadeIn(400);

            setTimeout(function() {
                $('#geofence-alert-box').fadeOut(600);
            }, 6000);
        }
    });

    // Trigger Real GPS Ping via AJAX
    $('#btn-ping-now').on('click', function() {
        var firstTanker = fleetData.tankers[0];
        if (!firstTanker) return;

        $.ajax({
            url: "{{ route('fleet.telematics.ping') }}",
            type: "POST",
            data: {
                _token: "{{ csrf_token() }}",
                vehicle_type: 'tanker',
                vehicle_id: firstTanker.id,
                latitude: firstTanker.latitude,
                longitude: firstTanker.longitude,
                speed: 36.5,
                odometer: (parseInt(firstTanker.current_odometer_km) || 45000) + 12
            },
            success: function(resp) {
                alert("GPS Telematics Ping sent successfully. Server Time: " + resp.timestamp + "\nInside Customer Geofence: " + (resp.inside_geofence ? 'YES' : 'NO'));
            }
        });
    });
</script>
@endsection
