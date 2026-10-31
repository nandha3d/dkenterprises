# DK Track — Complete Enterprise Fleet & Business ERP
**Custom Single-Tenant Solution for DK Enterprises**

---

### Executive Overview & Delivered Capabilities

In accordance with your directives, we have designed, implemented, and verified a fully featured, lightweight, standalone ERP system for DK Enterprises. We carefully studied **ZOLO-ERP-PRO** (`D:\PROJECTS\WEBSITES\zolo-erp-pro`) and **LoanApp** (`D:\PROJECTS\WEBSITES\loanapp`) without modifying a single line of code in those repositories. We extracted only the essential architectural patterns for staff, payroll, attendance, leave, expenses, and GPS geo-fencing, keeping the codebase completely clean, free of vendor bloat, and optimized for standard Linux Shared Hosting (Hostinger / cPanel) and Laravel Herd.

The complete production bundle is just **220 KB in size** (zero heavy Node/Docker daemons).

---

## 1. Staff, Driver & Delivery Boy Management (`StaffPortal.tsx`)

A unified human capital management system tailored to the three physical operational divisions:

### 1.1 Heavy Vehicle Drivers (Water Tanker Division)
- **Personnel**: Suresh Kumar, Palanisamy M., Karthik Raja (40KL Multi-Axle Trailer), Murugesan K.
- **Compensation Structure**: Monthly base salary (₹19,000 – ₹26,000) + dynamic **Trip Batta** (₹250 – ₹300 per completed trip sheet).
- **Compliance Tracking**: Heavy Vehicle Driving License Number and RTO Badge Expiry countdown alerts.

### 1.2 Water Can Delivery Boys (Tata Ace 20L Division)
- **Personnel**: Vigneshwaran (Vicky - Lead Delivery Agent), Raja Sundaram (Loader/Helper).
- **Compensation Structure**: Fixed daily wage (₹1,000 for Vicky, ₹650 for Raja) + per-can volume delivery incentives.
- **Advance Tracking**: Real-time advance balance ledger with automated payroll deduction.

### 1.3 Bakery & Cafe Staff (Bakery Division)
- **Personnel**: Kavin Anna (Counter / Store In-charge), Selvam Master (Master Baker / Tea Maker), Paati (Store Helper & Dishwashing).
- **Compensation Structure**:
  - Kavin & Selvam: Monthly salaried with GPay/bank settlements.
  - Paati: Fixed **₹350 daily wage** disbursed directly from the evening cash drawer (Image 2 item #10).

### 1.4 Daily Field Attendance & Shift Logs
- Live daily check-in / check-out timestamps.
- Operational status flags: `Present`, `On Trip` (dispatched on tanker/can run), `Half Day`, `Absent`, `On Leave`.

### 1.5 Monthly & Weekly Payroll Reconciler
- Formula:
  $$\text{Net Payable} = \text{Base Earnings} + \text{Trip Batta / Can Incentives} - \text{Advance Deductions}$$
- 1-Click Voucher Disbursement recording payment mode (`Cash Drawer`, `GPay Kavin`, `Canara Bank`, `Axis Bank`).

### 1.6 Leave Management
- Formal leave requests (`Personal`, `Medical`, `Emergency`, `Casual`).
- Status workflow: `Pending` $\to$ `Approved` $\to$ `Rejected` with automatic attendance and salary adjustment.

---

## 2. Customer Management & GPS Geo-Locking (`CustomersPortal.tsx`)

Directly inspired by the agent verification system in `loanapp`:
- **Shop Geofence Pinning**: Locks each customer's physical delivery location (`Latitude`, `Longitude`, `Geofence Radius` in meters, e.g., 75m for city shops, 150m–200m for industrial mills).
- **Automated Haversine Verification**:
  $$d = 2R \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos\phi_1\cos\phi_2\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
  - **VERIFIED**: When delivery agent's phone GPS fix is within the locked shop radius.
  - **MISMATCH FRAUD ALERT**: Flagged immediately when a drop is confirmed outside the shop radius (e.g., Santha Company 420m away).
- **Credit Balance & Rate Slabs**: Open dynamic pricing per customer (zero hardcoding).

---

## 3. Fleet & Truck Management (`FleetPortal.tsx`)

- **Zero Hardcoding Open Capacities**: Fully supports open decimal fields (e.g., 40.0 KL, 28.0 KL, 24.0 KL, 16.0 KL, 9.0 KL, 70 Cans Tata Ace).
- **Regulatory Compliance**: Real-time countdowns for Fitness Certificate (FC) expiry and Comprehensive Commercial Insurance renewal.
- **Odometer & Telematics Status**: Live speed, current dispatch trip, and last GPS ping timestamp.

---

## 4. Multi-Vertical Expense Ledger (`ExpensesPortal.tsx`)

A consolidated cost accounting ledger categorized by division:
- **Bulk Tankers**: Diesel / fuel bunk receipts, driver trip batta, highway tolls, motor impeller servicing.
- **Water Cans**: RO mineral plant water intake cost (loads 1, 2, 3 refills @ dynamic ₹8/can), daily driver wages, vehicle fuel.
- **Bakery & Cafe**: Daily raw materials (Image 2 ingredients), daily finance loan instalment (₹1,000), Paati daily helper wage (₹350).
- **General Admin**: TNEB commercial electricity bill, auditor & tax filing fees.
- **Payment Source Tracking**: Canara Bank, Axis Bank, GPay Kavin, Cash Safe Drawer.

---

## 5. Live GPS Telematics & Route Audit (`TelematicsPortal.tsx`)

- **Interactive Leaflet Fleet Map**: Real-time vehicle pins with live movement vectors.
- **Rest Dwell & Unmapped Stoppage Analysis**: Flags any vehicle idling or resting at an unmapped location for $> 30$ minutes to prevent driver time fraud.
- **Fuel Fraud Cross-Audit**: Compares claimed petrol bunk receipt liters against actual GPS road distance covered.

---

## 6. Architecture & Deployment Status

| Component | Status | Details |
| :--- | :--- | :--- |
| **Herd Local Server** | **Active & Verified** | Serving at `http://dk-track.test` (PHP 8.4 CLI) |
| **Shared Hosting Package** | **Compiled & Ready** | `release/dk_track_hostinger_cpanel_production.zip` (220.2 KB) |
| **Vite Dev Server** | **Active** | `http://localhost:5173/` |
| **Database Schema** | **Ready** | `backend/database/dk_track_master_schema.sql` (MySQL 8.0 InnoDB) |
| **Bilingual Engine** | **Active** | Full English & Vernacular Tamil (தமிழ்) parity |
| **Theme System** | **Active** | Fresh Modern Light Theme + Sleek Dark Mode |
