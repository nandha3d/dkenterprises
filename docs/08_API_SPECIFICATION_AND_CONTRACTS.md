# DK Track — REST API Specification & Endpoint Contracts

## 1. API Architecture Conventions

All API endpoints follow RESTful standards and return standardized JSON envelopes.

- **Base URL**: `https://dktrack.dkenterprises.in/api/v1`
- **Default Content-Type**: `application/json`
- **Authentication**: `Authorization: Bearer <sanctum_token>`
- **Response Format**:
  ```json
  {
    "success": true,
    "data": { ... },
    "message": "Operation completed successfully",
    "meta": { "timestamp": "2026-10-30T10:30:00Z" }
  }
  ```
- **Error Format**:
  ```json
  {
    "success": false,
    "error": {
      "code": "VALIDATION_FAILED",
      "message": "The given data was invalid.",
      "details": { "phone": ["The phone number is required."] }
    }
  }
  ```

---

## 2. Authentication & User Profile Endpoints

### 2.1 `POST /auth/login`
Authenticates web and mobile users.
- **Request**:
  ```json
  {
    "phone": "9842100000",
    "password": "SecurePassword123",
    "device_uuid": "android-uuid-984214"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "token": "1|s7d8f6sd8f76sd8f76sd8f",
      "user": {
        "id": 1,
        "name": "Dinesh",
        "role": "tanker_manager",
        "division_access": "tanker",
        "preferred_language": "ta"
      }
    }
  }
  ```

---

## 3. Bulk Water Tanker Fleet Endpoints (With Dynamic Surcharges)

### 3.1 `POST /tankers/trips`
Dispatches a new tanker trip with **any tanker capacity** (e.g. 40KL) and itemized surcharges.
- **Request**:
  ```json
  {
    "customer_id": 4,
    "vehicle_id": 2,
    "driver_id": 3,
    "capacity_kl": 40.0,
    "load_source": "Main RO Water Plant",
    "destination_site": "Texvalley Corporate Campus",
    "trip_fare": 3500.00,
    "motor_used": true,
    "motor_charges": 250.00,
    "waiting_time_hours": 2.0,
    "waiting_time_charges": 300.00,
    "long_distance_km": 15,
    "long_distance_surcharge": 300.00,
    "miscellaneous_charges": 180.00,
    "miscellaneous_description": "Toll plaza receipt",
    "driver_batta": 250.00,
    "trip_date": "2026-10-30"
  }
  ```

### 3.2 `PATCH /tankers/trips/{id}/complete`
Driver finishes delivery at destination.
- **Request (Multipart Form Data)**:
  - `odometer_end`: `142865`
  - `motor_used`: `true`
  - `waiting_time_hours`: `2.0`
  - `receiver_name`: `"Kaliappan (Site In-charge)"`
  - `receiver_signature`: `<signature_svg_or_png>`
  - `gate_pass_photo`: `<binary_file>`

---

## 4. Water Can Distribution Endpoints (Multi-Plant Refills & GPS Tracking)

### 4.1 `POST /water-cans/routes/{id}/plant-intakes`
Supports **2, 3, or more plant refills** throughout the day (*Image 3*).
- **Request**:
  ```json
  {
    "intake_sequence": 2,
    "plant_slip_number": "RO-2026-9941",
    "cans_loaded": 84,
    "purchase_rate_per_can": 8.00,
    "slip_photo": "<binary_file>"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "data": {
      "intake_id": 45,
      "intake_sequence": 2,
      "cans_loaded": 84,
      "total_shift_loaded_cans": 156,
      "current_truck_stock": 96
    }
  }
  ```

### 4.2 `POST /water-cans/deliveries`
Single delivery entry with on-the-spot payment and exact GPS fix (<15s).
- **Request**:
  ```json
  {
    "can_route_id": 12,
    "customer_id": 8,
    "cans_delivered": 14,
    "empty_cans_collected": 14,
    "rate_per_can": 20.00,
    "payment_mode": "cash",
    "amount_paid": 280.00,
    "payment_time": "2026-10-30T09:34:12Z",
    "delivery_lat": 11.018221,
    "delivery_lng": 76.964119
  }
  ```

---

## 5. Telematics, Stoppage & Rest Time Analytics

### 5.1 `GET /telematics/routes/{id}/stoppages`
Pulls full stoppage timeline, rest duration, and dwell times.
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "vehicle_number": "TN 38 BX 4412",
      "total_gps_distance_km": 72.4,
      "total_stops": 24,
      "total_rest_minutes": 50,
      "stoppages": [
        {
          "location": "Main RO Treatment Plant",
          "arrival": "08:15:00",
          "departure": "08:35:00",
          "duration_minutes": 20,
          "category": "plant_loading"
        },
        {
          "location": "Aran Cafe - 1",
          "arrival": "09:20:00",
          "departure": "09:34:00",
          "duration_minutes": 14,
          "category": "customer_delivery"
        },
        {
          "location": "Highway Tea Stall",
          "arrival": "11:15:00",
          "departure": "12:05:00",
          "duration_minutes": 50,
          "category": "rest_break",
          "is_warning": true
        }
      ]
    }
  }
  ```

---

## 6. Future Bakery POS & External Integration Endpoints

### 6.1 `POST /pos/sync-sales`
Ingests counter transactions from physical Android POS or billing counter.
- **Request**:
  ```json
  {
    "pos_terminal_id": "POS-BAKERY-01",
    "idempotency_key": "3f98c4d2-7b3e-4f1a-8c90-e5a6f2b1d7e8",
    "closing_date": "2026-10-30",
    "drawer_cash": 1960.00,
    "coins": 104.00,
    "upi_total": 3700.00,
    "cash_expenses": 700.00
  }
  ```

---

## 7. Master Executive Single-Entry P&L Endpoints

### 7.1 `GET /pnl/master-dashboard`
Returns company-wide financial health with division drilldowns.
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "period": "2026-10-30",
      "gross_money_in": 148500.00,
      "operating_money_out": 82230.00,
      "net_operating_profit": 66270.00,
      "bank_balances": {
        "kavin_canara": 245000.00,
        "gpay_kavin_axis": 89400.00,
        "cash_in_hand": 34200.00
      },
      "divisions": {
        "tanker_fleet": { "revenue": 98000.00, "expenses": 51200.00, "net": 46800.00 },
        "water_can_distribution": { "revenue": 22500.00, "expenses": 13830.00, "net": 8670.00 },
        "bakery_retail": { "revenue": 28000.00, "expenses": 17200.00, "net": 10800.00 },
        "personal_drawings": { "total_out": 6500.00 }
      }
    }
  }
  ```
