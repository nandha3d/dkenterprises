# Zolo ERP — Mobile Technical & Codebase Architecture Audit

**Document Reference:** `docs/mobile/MOBILE_TECHNICAL_AUDIT.md`  
**Date:** 2026-11-07  
**Target:** `mobile/` Flutter codebase (Flutter 3.44.0 / Dart 3.12.0)  
**Status:** Audit Completed · Critical Blockers & Action Items Identified

---

## 1. Executive Summary

A comprehensive architectural and technical audit was conducted on every file within `mobile/lib/` (11,600+ lines across 23 Dart files) and its accompanying Android/package configuration. 

While the application provides functional field prototypes for DK's three verticals (water tankers, water cans, cafe POS), it suffers from severe technical debt, security bypasses, simulated device features, heavy GPU-draining visual effects, rigid per-role navigation, and complete absence of real offline synchronization.

---

## 2. File-by-File Technical Audit

### 2.1 Main Application Entry Point & Navigation Shell (`mobile/lib/main.dart` — 1,127 lines)
- **Architecture Flaw:** Monolithic screen switching based on hardcoded `UserRole` enums.
- **Navigation Antipattern:** Bottom navigation bars are dynamically swapped with distinct arrays per role:
  - `SuperAdmin`: `[TMWS, DK Waters, Aran Cafe, Accounts]`
  - `Admin`: `[Overview, Operations, Fleet, Accounts]`
  - `FieldAgent`: `[Route/KYC, Collect, Audit, Customers]`
  - `DeliveryDriver`: `[Cans POS, Refill, Surrender, Invoices]`
  - `TankerDriver`: `[Active Trip, Fleet, Expenses, Log Sheet]`
  - `Cashier`: `[POS, Drawer, Menu, Orders]`
- **Defects:**
  - Hardcoded tabs prevent access to the wider ERP (Purchases, Quotations, Stock counts, Job work, HRM, Reports).
  - Can Sales POS is duplicated in both the bottom navigation bar and the side navigation drawer.
  - Zero state management (108 `setState` invocations scattered across widgets; zero Riverpod/Provider consumption).
  - Navigation state is wiped whenever switching companies or restarting the application.

---

### 2.2 Authentication & Security (`mobile/lib/screens/login_screen.dart` — 619 lines)
- **Critical Security Bypasses:**
  - Line 15: `static const bool showDemoLoginRibbon = true;` permanently renders one-tap role login shortcuts.
  - Lines 31-32: Pre-fills username `admin` and password `admin` by default.
  - Lines 60-89 (`_selectRoleShortcut`): Hardcoded passwords in client source code (`admin`, `agent123`, `driver123`, `cashier123`).
  - Line 90-102 of `api_service.dart`: If API authentication fails or the device is offline, `login()` silently falls back to a fabricated "Demo Test Mode" session (`demo-token-${timestamp}`), granting immediate application entry.
- **Remediation Required:**
  - Completely eliminate pre-filled passwords, demo bypasses, and role shortcut ribbons.
  - Enforce real bcrypt authentication against `/api/v1/mobile/login` or `/api/v1/auth/login`.
  - Fetch user role and permissions from `GET /api/v1/me`.
  - Store tokens securely using `flutter_secure_storage`.

---

### 2.3 Client-Side Role Elevation (`mobile/lib/screens/role_selector_sheet.dart` — 224 lines)
- **Defect:** Allows any user to open a modal bottom sheet and switch their active role to Super Admin, Admin, Field Agent, Route Driver, Tanker Driver, or Cashier with zero server validation.
- **Remediation Required:**
  - Retire client-side role switching. The authenticated user's permissions and accessible companies/branches must be dictated solely by `GET /api/v1/me`.

---

### 2.4 API Communication Layer (`mobile/lib/services/api_service.dart` — 763 lines)
- **Defects:**
  - Monolithic single class handling disparate domains (auth, water, cafe, fleet, financials).
  - Token stored solely in memory (`String? _authToken;`), resulting in immediate user logout when Android pauses or terminates the process.
  - Silent fake fallback data:
    - Line 498: `fetchCustomers()` returns 5 hardcoded mock customer objects if HTTP response is empty or fails.
    - Line 562: `fetchProducts()` returns mock product array on failure.
    - Line 603: `fetchInvoices()` returns mock invoices on failure.
    - Line 648: `fetchFinancials()` returns hardcoded ₹48,250 cash and ₹1,84,500 bank.
  - Lacks request timeouts configuration, retry policies, cursor pagination, and standard error interceptors.
- **Remediation Required:**
  - Refactor into modular feature repositories (`AuthRepository`, `SalesRepository`, `AccountingRepository`, etc.).
  - Centralize Dio/HTTP client with interceptors for `Authorization: Bearer <token>`, `X-Company-ID`, `X-Branch-ID`, `X-Financial-Year-ID`, and `Idempotency-Key`.
  - Remove all mock fallbacks from production code; surface real `ErrorState` on network failure.

---

### 2.5 Data Models (`mobile/lib/models/models.dart` — 465 lines)
- **Defects:**
  - Combines all entity definitions into a single file.
  - Incomplete schemas missing core ERP fields (HSN codes, GST tax slabs, journal lines, debit/credit flags, warehouse IDs).
  - Lacks proper JSON serialization/deserialization validation.
  - Missing entities for Double-entry accounting, Purchase orders, GRN, Job work, and HRM.

---

### 2.6 Visual Design & Theme System (`mobile/lib/theme/app_theme.dart` — 114 lines)
- **Violation of Design Principles (`docs/09` & Master Prompt):**
  - Uses purple brand accents (`#7D287E`) and multi-stop gradients across cards and headers.
  - 67 hardcoded hex values scattered throughout screens (`#0284C7`, `#2563EB`, `#D97706`, `#10B981`, `#EF4444`, `#F59E0B`).
  - Colors change unpredictably per role and per tab rather than conveying consistent semantic meaning (e.g. green for synced/money in, red for overdue/failed).
  - Outdoor readability issue: 186 font-size definitions (out of 369) are between 8sp and 11sp, violating the 12sp minimum floor for outdoor readability.

---

### 2.7 Reusable Widgets & Performance Bottlenecks (`mobile/lib/widgets/glass_card.dart` — 113 lines)
- **Severe Performance Bottleneck:**
  - 70 instances of `GlassCard` across the screen tree.
  - Uses `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`.
  - On low-end to mid-range Android devices (2GB–4GB RAM, Mali-G52 or Adreno 610 GPUs), realtime backdrop filtering causes massive frame drops (rendering at 15–25 fps instead of 60 fps) and excessive battery drain.
- **Remediation Required:**
  - Completely remove `BackdropFilter` and `GlassCard`.
  - Replace with flat, industrial Material 3 surface tokens: 1px border (`#E2E8F0` light / `#1F2937` dark), solid card background (`#FFFFFF` light / `#111827` dark), and 12px corner radius.

---

### 2.8 Internationalization & Typography
- **Defects:**
  - 428 occurrences of inline `widget.isTamil ? '...' : '...'` ternary checks.
  - `isTamil` boolean is manually prop-drilled down widget constructors across all 18 screen files.
  - No Flutter `.arb` (Application Resource Bundle) or `flutter_localizations` integration.
  - Relies on Google Fonts runtime fetching rather than bundled offline font assets.
- **Remediation Required:**
  - Implement standard `intl` with `app_en.arb` and `app_ta.arb`.
  - Bundle fonts locally: Plus Jakarta Sans (English), JetBrains Mono (Numbers/Amounts), and Noto Sans Tamil.

---

### 2.9 Offline Persistence & Synchronization
- **Defects:**
  - `sqflite: ^2.3.0` is listed in `pubspec.yaml`, but not a single file under `mobile/lib/` opens a database or executes SQL.
  - Zero local master data caching; switching airplane mode on causes total app failure or silent fallback to fake demo data.
  - No outbox table, no idempotency keys, and no retry mechanism for field transactions.
- **Remediation Required:**
  - Implement SQLite/Drift database with master cache and outbox table (`uuid`, `endpoint`, `payload`, `idempotency_key`, `attempts`, `status`).
  - Add background synchronization engine with exponential backoff.

---

### 2.10 GPS Telematics & Device Integrations (`mobile/lib/screens/fleet_gps_screen.dart` — 1,219 lines)
- **Defects:**
  - `geolocator: ^10.1.0` is in `pubspec.yaml`, but never polled in the background.
  - Line 930 (`FleetRadarPainter`): Fleet screen renders an animated custom painter radar with hardcoded mock vehicle positions rather than an interactive map with real GPS breadcrumb trails.
  - Android foreground service not configured for background shift tracking.
- **Remediation Required:**
  - Implement genuine GPS location logging during active driver shifts.
  - Integrate interactive map view (`flutter_map` with OpenStreetMap or Google Maps).

---

### 2.11 Testing Infrastructure
- **Defects:**
  - Zero unit tests.
  - Zero integration tests.
  - Only default template `test/widget_test.dart` (which currently fails due to missing provider wrappers).
- **Remediation Required:**
  - Unit tests for money calculations, sync queue, and auth token management.
  - Widget tests for design system components.
  - Integration tests for offline sale creation and server reconciliation.

---

## 3. Summary of Technical Debt & Action Items

| Priority | Area | Current Technical Debt | Target Resolution |
|---|---|---|---|
| **P0** | **Authentication** | Hardcoded passwords & fake token fallback | Sanctum token auth, `/api/v1/me` role/permissions |
| **P0** | **Architecture** | 1,127-line `main.dart` with role-swapped tabs | 5-slot bottom bar (Home, Tasks, +New, Modules, Me) |
| **P0** | **Design System** | 70 `GlassCard` blurs & tiny <12sp typography | Flat industrial design tokens, text >=12sp, touch >=48dp |
| **P0** | **Data Integrity** | Fake numbers returned on error & no-op writes | Real accounting ledger queries & SQLite outbox engine |
| **P1** | **Localization** | 428 inline `isTamil ?` ternaries | ARB localization files (`app_en.arb`, `app_ta.arb`) |
| **P1** | **State & DI** | 108 `setState` calls, zero state architecture | Riverpod 3.x feature architecture |
| **P1** | **GPS & Maps** | Fake radar painter with hardcoded vehicles | Real GPS tracking during shifts + interactive map |

