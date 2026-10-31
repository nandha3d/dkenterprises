# DK Track — Production Release & Deployment Guide
**Client: DK Enterprises (Single-Tenant Standalone ERP)**  
**Date of Release**: October 30, 2026  
**Hosting Target**: Linux Shared Hosting (Hostinger / cPanel / LiteSpeed / Apache with PHP 8.2+ and MySQL 8.0)

---

## 📦 Production Release Artifacts

The `release/` folder contains everything needed to go live:

1. **`release/dk_track_hostinger_cpanel_production.zip` (181 KB)**:
   - Production compiled Web Application (React 19 + TypeScript SPA).
   - Lightweight PHP 8.2+ REST API router and controllers.
   - Hardened `.htaccess` with security headers and URL rewrites.
2. **`release/dk_enterprises_master_database_setup.sql` (28 KB)**:
   - 18 InnoDB MySQL 8.0 tables with foreign key constraints and financial DECIMAL(12,2) precision.
   - Seeded real-world accounts (*Texvalley 88KL, Amirtha Milk, Aran Cafe, Balaji Cafe, Page 152 closing ledger*).
3. **`mobile/`**:
   - Production Flutter Android application codebase.
   - Verified with `flutter analyze` (0 errors) and `flutter test` (100% passed).

---

## 🚀 Part 1: Web App & Backend Deployment (Hostinger / cPanel)

### Step 1: Create Database in cPanel / Hostinger
1. Log in to your Hostinger or cPanel Dashboard.
2. Navigate to **MySQL Databases** (or **Databases**).
3. Create a new database: e.g., `u123456789_dk_track`.
4. Create a new user with a strong password (e.g., `u123456789_dk_user`).
5. Assign all privileges on the database to the user.

### Step 2: Import Database Schema & Seeds
1. Open **phpMyAdmin** from the control panel.
2. Select your newly created database.
3. Click the **Import** tab.
4. Choose file: `release/dk_enterprises_master_database_setup.sql`.
5. Click **Import / Go**. All 18 tables and real-world ground seed records will be created.

### Step 3: Upload Web & API Zip to File Manager
1. In Hostinger / cPanel, open **File Manager**.
2. Navigate into your domain's root folder (`public_html/`).
3. Click **Upload** and select `release/dk_track_hostinger_cpanel_production.zip`.
4. Right-click the uploaded `.zip` and click **Extract**.
5. Move the extracted files so that `index.html` sits directly inside `public_html/`:
   ```text
   public_html/
   ├── index.html                    (React SPA Entry Point)
   ├── assets/                       (Minified CSS & JS Bundles)
   ├── favicon.svg & icons.svg
   ├── api/
   │   ├── v1/
   │   │   ├── index.php             (PHP REST API Router)
   │   │   └── .htaccess             (LiteSpeed / Apache URL rewrite)
   │   ├── config/
   │   │   └── database.php          (Database Credentials)
   │   └── src/                      (Controllers & Services)
   ```

### Step 4: Configure Database Credentials
Edit `public_html/api/config/database.php` (or set environment variables in cPanel):
```php
return [
    'host'     => 'localhost',
    'port'     => 3306,
    'database' => 'u123456789_dk_track',
    'username' => 'u123456789_dk_user',
    'password' => 'YOUR_STRONG_PASSWORD',
    'charset'  => 'utf8mb4',
    // ...
];
```

### Step 5: Test the Live URL
- Open `https://your-domain.com/` in any browser:
  - Default: **Clean Light Theme** and **English** language.
  - Test the **Dark Mode** toggle (Sun/Moon).
  - Test the **தமிழ் (Tamil)** toggle.
- Test API Healthcheck:
  - Visit `https://your-domain.com/api/v1/health`
  - Expected JSON output: `{"status":"OK","system":"DK Track Single-Tenant ERP",...}`

---

## 📱 Part 2: Field Mobile App (Android)

### Option A: Interactive Field Driver Simulator (Zero Installation Needed)
The web portal includes an embedded **Field Driver Mobile Simulator** that runs right in any smartphone browser, tablet, or PC:
1. Log into `https://your-domain.com/` on the driver's phone.
2. Tap the **Driver App Simulator** button in the top bar.
3. Drivers have immediate access to the **<15s Bus Ticket Machine Entry**:
   - Customer dropdown (*Aran Cafe 1 & 2, Balaji Cafe, etc.*).
   - High-contrast `+` / `-` touch steppers for loaded and empty cans.
   - Cash / UPI / Credit payment buttons.
   - On-the-spot GPS coordinates and seconds timestamp capture.

### Option B: Compiling Native Android APK (`mobile/`)
To generate a standalone `.apk` for direct distribution to company phones:
1. Ensure the Android SDK command-line tools are installed.
2. In the `mobile/` directory, run:
   ```bash
   cd mobile
   flutter pub get
   flutter build apk --release
   ```
3. The release APK will be generated at:
   `mobile/build/app/outputs/flutter-apk/app-release.apk`
4. Copy this file to Android phones and tap to install.

---

## 🛡️ Operational Guardrails Certified

- [x] **Strict Shared Hosting Safe**: No background Node.js daemons, persistent Socket.io servers, or Docker dependencies.
- [x] **Zero Hardcoding**: Tanker capacities are open decimals (supporting 40KL+ trailers); rates and surcharges resolved dynamically from the database.
- [x] **Multi-Plant Refill Support**: Tata Ace tracking supports sequential intakes (Load 1, 2, 3...) with live stock balance ($\sum \text{Intakes} - \sum \text{Deliveries}$).
- [x] **Anti-Theft Spot Audit**: Instant reconciler comparing observed cans and cash against expected server balances.
- [x] **Bilingual Parity**: Every screen, button, and report supports English and Tamil (தமிழ்).
