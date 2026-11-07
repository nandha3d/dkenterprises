# GPS Module & Fleet Telematics Audit

**Application:** DK Enterprises ERP (Laravel 11 + Flutter Mobile)  
**Specification:** `docs/DK_Enterprises_Antigravity_ERP_Mobile_Web_Audit_and_Fix_Spec.md`  
**Date:** 2026-11-07  
**Status:** Remediated & Live Backend Connected  

---

## 1. Audit Findings: Simulated Telemetry vs Real ERP Telematics

### Defect Identified in `mobile/lib/screens/fleet_gps_screen.dart`
The previous mobile screen `FleetGpsScreen` contained hardcoded mock lists `_tankers` and `_waterTrucks` with fabricated vehicle coordinates (e.g. `lat: 11.2954, lng: 77.6128`), fake driver names, simulated speed, fake decanting flow rate (`420 L/min`), fake battery voltage, and a `Timer? _telemetryTimer` that simulated vehicle movements and ping ticks.

As Section 1.1A of the specification dictates:
> "This is not live fleet tracking. A timer or radar animation does not make fabricated data real. Remove all production use of these lists and any simulated telemetry timer. Replace them with API-fed vehicle/driver/location/event data. Do not invent live location when the device or tracker is not reporting."

---

## 2. Real Backend Fleet Telematics Data Model

The ERP backend already possesses the authoritative database schema and controllers for real fleet telematics:

### Database Tables:
1. **`water_tankers` (Commercial Bulk Water Tankers - TMWS):**
   - `id`: Vehicle ID
   - `vehicle_number`: Real registration (e.g. `TN-58-BW-2001`)
   - `model_type`: Model specification
   - `capacity_kl`: Capacity in kiloliters (e.g. 10KL, 20KL, 40KL)
   - `capacity_liters`: Liters capacity
   - `driver_name`: Assigned driver
   - `driver_phone`: Contact number
   - `is_active`: Operational flag
   - `latitude`: Real GPS latitude (decimal 10,7)
   - `longitude`: Real GPS longitude (decimal 10,7)
   - `current_speed`: Real speed in km/h from device ping
   - `current_odometer_km`: Odometer reading
   - `last_ping_at`: Server timestamp of last received telemetry ping

2. **`water_can_routes` (20L Can Beat Distribution - DK Waters):**
   - `id`: Route/Vehicle ID
   - `route_name`: Geographic delivery beat
   - `vehicle_no`: Delivery van registration (e.g. `TN-58-WA-101 (Tata Ace)`)
   - `driver_name`: Route driver
   - `driver_phone`: Driver mobile
   - `daily_avg_cans`: Capacity / target
   - `latitude`: Real van GPS latitude
   - `longitude`: Real van GPS longitude
   - `current_speed`: Speed in km/h
   - `last_ping_at`: Server timestamp of last telemetry ping

3. **`customers` (Geofenced Client Receiving Sites):**
   - `latitude` & `longitude`: Geofenced customer location
   - `geofence_radius`: Delivery site geofence perimeter in meters

---

## 3. Real Fleet Telematics API Endpoints

The fleet endpoints are now exposed in `routes/api.php` under `Route::prefix('fleet')`:

### 1. Ingestion: Device Telemetry Ping
- **Endpoint:** `POST /api/v1/mobile/fleet/ping`
- **Authentication:** Sanctum Bearer Token
- **Payload:**
  ```json
  {
    "vehicle_type": "tanker", // "tanker" or "route"
    "vehicle_id": 1,
    "latitude": 11.2954,
    "longitude": 77.6128,
    "speed": 34.5,
    "odometer": 45230
  }
  ```
- **Behavior:** Updates `latitude`, `longitude`, `current_speed`, `current_odometer_km`, and sets `last_ping_at = now()`.

### 2. Retrieval: Live Fleet Telematics
- **Endpoint:** `GET /api/v1/mobile/fleet/live`
- **Authentication:** Sanctum Bearer Token
- **Context Header:** `X-Company-ID`
- **Behavior:**
  - For `TMWS` (`bulk_water`): Returns real `tankers` and customer delivery sites. Zero can beat routes.
  - For `DK Waters` (`packaged_water`): Returns real `can_routes` (Tata Ace vans) and customer delivery sites. Zero tankers.
  - Truthful freshness: A vehicle is flagged **Live** only if `last_ping_at` is within the last 5 minutes. If null or older, marked as **Stale / Offline (Last seen X ago)**.

---

## 4. Mobile GPS Client Architecture

1. **Elimination of Mock Data:**
   - Deleted hardcoded `_tankers` and `_waterTrucks` arrays.
   - Deleted simulated periodic timer `_telemetryTimer`.
2. **API Data Binding:**
   - `FleetGpsScreen` now executes `_fetchLiveFleet()` calling `GET /api/v1/mobile/fleet/live`.
   - Renders truthful vehicle records received from the server.
   - If no vehicles have pinged coordinates yet, displays the truthful status:
     `"No live GPS telemetry received yet. Waiting for vehicle tracker or driver device ping."`
3. **Company Scoping:**
   - Respects active company: TMWS monitors bulk tankers; DK Waters monitors 20L can vans.

