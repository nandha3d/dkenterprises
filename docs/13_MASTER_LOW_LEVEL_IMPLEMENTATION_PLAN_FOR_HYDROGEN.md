# MASTER LOW-LEVEL IMPLEMENTATION PLAN (FOR GEMINI 4 HYDROGEN)

**Target System:** ZOLO ERP / DK Enterprises Unified Platform (Laravel Backend + Flutter Multi-Platform App)  
**Active Branch:** `main`  
**Scope:** Wide-Viewport Rendering & Tablet/Desktop Grid, KPSTA-Style 5-Slot Docked Bottom Nav Bar with Integrated `+`, Staff Human Display Names, Zero Cross-Vertical Leakage & Strict RBAC Gating, Real-Time Activity Push Notifications, and Always-Live Memory Keep-Alive Management.

---

## Executive Summary of Issues Diagnosed & Architecture Fixes

| # | Reported Issue | Root Cause Verified in Code | Target Deterministic Fix |
|---|---|---|---|
| 1 | Wide aspect ratio hides all body content | `AdaptivePageConstraint` (`maxWidth: 1180`) switches widget depth above `1180px`, causing unconstrained/sliver scrollables inside centered `ConstrainedBox` panes to collapse or fail layout on wide aspect ratios (`media_1794560197940_da869f66.png`). | Stabilize `AdaptivePageConstraint` with a consistent `LayoutBuilder -> Align -> ConstrainedBox -> child` tree at `maxWidth = 1600`, enforce explicit `minWidth`, and render 2-column responsive grids on `TankerDriverDashboardScreen` when `constraints.maxWidth >= 860`. |
| 2 | Bottom nav should match KPSTA full-width docked 5-menu bar with integrated `+` | `FluidCurvedNavBar` uses `ConstrainedBox(maxWidth: 580)` + `EdgeInsets.fromLTRB(14, 0, 14, 10)` floating pill; `driver` and `fieldAgent` only have 4 tabs; top `AppBar` has a separate yellow `+` button (`app_scaffold.dart:100`). | Dock `FluidCurvedNavBar` full-width (`EdgeInsets.zero`, `cornerRadius = 0.0`, `maxWidth` removed, preserve `totalBarHeight == 90.0`), style KPSTA high-contrast surface (`#0F292E`) + circular elevated active badge, move `+` (`isCenterAction: true`) into center slot `2` for **all 4 roles** (5 items each), and remove top-bar yellow `+`. |
| 3 | Lowercase role slug `'tanker_driver'` shown as user title | `MeApiController`, `WaterLogisticsApiController::mobileLogin`, and `HrmApiController` return raw slug `'tanker_driver'` as `user.name` and `driver_name`, and `UserProfile.fromJson` renders it verbatim (`media_1794560603453_6ad74772.png`). | Add canonical display-name + role-label resolution (`display_name`, `role_label`, `UserProfile.humanizeName`) so `'tanker_driver'` displays as `'K. Murugan'` / title-cased staff name with badge `'Bulk Tanker Driver'` while keeping `username` intact. |
| 4a | TMWS attendance screen displays `DK Waters RO Plant` | `HrmApiController::resolveDepotGeofence()` checks `$company->name` (non-existent column on `companies`, which uses `trade_name` / `legal_name` / `code`) and falls back to `'DK Waters RO Plant'`. | Resolve geofence site dynamically via `trade_name`, `legal_name`, `code`, and `company_industry_settings.profile_key` so TMWS displays `'Tiruchendur Murugan Water Supply Mother Plant'`. |
| 4b | Tanker driver `Cash` tab shows 20L `Van Jar Count Reconciliation` | `DriverSurrenderScreen` renders 20L Can `Van Jar Count Reconciliation` for every `driver` regardless of `bulk_water` flavor and hardcodes `'driver_id': 1, 'route_id': 1`. | Branch `DriverSurrenderScreen` on `activeDriverFlavorProvider` / `industry`: render `Bulk Tanker Trip & Freight Settlement` (`Completed Trips`, `Total KL`, `Tanker Vehicle`, `Freight Cash Collected`, `Diesel/Toll/Motor`, `Driver/Cleaner Batta`, `Net Freight Cash Handover`) for `bulk_water`, and use dynamic manifest driver/route IDs. |
| 4c | Verticals leaking across non-superadmin users | `MeApiController`, `HrmApiController`, `WaterLogisticsApiController`, `app_router.dart`, and `QuickActionSheet` allow header/route/UI switching across companies & verticals for non-superadmin roles. | Enforce strict vertical & role locking: **only `super_admin`** (`role_id == 1` or `'Admin'` / `'super_admin'`) can switch companies or access other verticals; non-superadmin cross-vertical API requests return `403`, and Flutter `GoRouter` redirects unauthorized vertical URLs back to home. |
| 5 | No push notification for driver/incharge/delivery activity | Notifications table exists, `/api/v1/notifications` + `/devices/push-token` exist, and `NotificationsScreen` exists, but operational actions don't emit alerts and mobile does not poll/display heads-up alerts with unread counts. | Build `ActivityNotificationService` on Laravel, emit notifications in `HrmApiController` + `WaterLogisticsApiController` for every driver/delivery/incharge action, handle `/notifications/all/read`, and build `PushNotificationService` in Flutter with live polling, heads-up banner, haptic feedback, and `AppScaffold` bell `Badge`. |
| 6 | App killed / reloads state when user switches to other apps | `ZoloErpApp` lacks `WidgetsBindingObserver`, primary screens lack `AutomaticKeepAliveClientMixin`, and Android lacks foreground service/wake-lock/battery-optimization metadata. | Build `AppKeepAliveManager` (`WidgetsBindingObserver`) trimming non-essential `imageCache` on background/memory-pressure while keeping state & timers live, draining offline sync safely, adding `AutomaticKeepAliveClientMixin` to primary dashboards/tabs, and adding Android manifest foreground/wake-lock permissions. |

---

## Workstream 1: Wide Aspect Ratio Blank Body Fix & Tablet/Desktop Responsive Grid

### Exact Files
1. `mobile/lib/core/ui/adaptive_layout.dart`
2. `mobile/lib/core/ui/app_scaffold.dart`
3. `mobile/lib/features/dashboard/presentation/tanker_driver_dashboard_screen.dart`

### Exact Code Changes
1. **`AdaptivePageConstraint` (`adaptive_layout.dart`)**:
   - Change default `maxWidth` from `1180` to `1600`.
   - Use a single uniform `LayoutBuilder` tree regardless of width so switching between narrow and wide viewports never swaps widget hierarchy or drops child constraints:
     ```dart
     return LayoutBuilder(
       builder: (context, constraints) {
         final boundedWidth = constraints.maxWidth.isFinite
             ? constraints.maxWidth
             : MediaQuery.sizeOf(context).width;
         final targetWidth = boundedWidth > maxWidth ? maxWidth : boundedWidth;
         return Align(
           alignment: alignment,
           child: ConstrainedBox(
             constraints: BoxConstraints(
               minWidth: targetWidth,
               maxWidth: targetWidth,
             ),
             child: child,
           ),
         );
       },
     );
     ```
2. **`AppScaffold` (`app_scaffold.dart`)**:
   - Update body wrapper `AdaptivePageConstraint(maxWidth: 1600, child: child)`.
   - Remove top `AppBar` yellow `+` `IconButton` when `!isAdmin` (since `+` moves cleanly into bottom nav center slot `2` for all roles).
   - Keep `FluidCurvedNavBar` floating with centered max-width constraint inside `SafeArea(top: false)` so it remains detached from bottom and side screen walls on all aspect ratios.

---

## Workstream 2: Floating Theme-Colored 5-Menu Curved Bottom Nav Bar + Center `+`

### Exact Files
1. `mobile/lib/core/routing/role_navigation.dart`
2. `mobile/lib/core/ui/fluid_curved_nav_bar.dart`
3. `mobile/lib/core/ui/app_scaffold.dart`
4. `mobile/lib/core/ui/quick_action_sheet.dart`

### Exact Navigation Slots (5 Menus Every Role, `+` Always at Index `2`)
1. **`RippleRole.admin` (`admin`):**
   - `0`: `Home` (`/`)
   - `1`: `Sales` (`/tab/sales`)
   - `2`: `Quick` (`/tab/quick`, `isCenterAction: true`) -> opens `QuickActionSheet`
   - `3`: `OPS` (`/tab/ops`)
   - `4`: `More` (`/tab/more`)
2. **`RippleRole.driver` (`driver` / `tankerDriver`):**
   - `0`: `Today` (`/`)
   - `1`: `Work` (`/tab/driver-work`)
   - `2`: `Quick` (`/tab/quick`, `isCenterAction: true`) -> opens `QuickActionSheet` (`+`)
   - `3`: `Cash` (`/tab/driver-cash`)
   - `4`: `Me` (`/tab/driver-me`)
3. **`RippleRole.cafe` (`cashier`):**
   - `0`: `Counter` (`/`)
   - `1`: `Orders` (`/tab/cafe-orders`)
   - `2`: `Quick` (`/tab/quick`, `isCenterAction: true`) -> opens `QuickActionSheet` (`+`)
   - `3`: `Drawer` (`/tab/cafe-drawer`)
   - `4`: `Kitchen` (`/tab/cafe-kitchen`)
   - *(Note: add Profile icon in `AppScaffold` for `cafe` and also inside `QuickActionSheet` so Cashier still has 1-tap access to `/profile` and `/hrm/attendance`.)*
4. **`RippleRole.fieldAgent` (`agent`):**
   - `0`: `Collect` (`/`)
   - `1`: `Customers` (`/tab/agent-customers`)
   - `2`: `Quick` (`/tab/quick`, `isCenterAction: true`) -> opens `QuickActionSheet` (`+`)
   - `3`: `Spend` (`/tab/agent-spend`)
   - `4`: `Me` (`/tab/agent-me`)

### Visual Geometry (`FluidCurvedNavBar`)
- **Floating capsule geometry (never anchored wall-to-wall):** Keep `cornerRadius = 22.0`, outer padding `EdgeInsets.fromLTRB(14, 0, 14, 10)`, and centered `ConstrainedBox(maxWidth: 620)` on tablet/desktop viewports so all four edges float clear of screen borders.
- **Preserve height contract (`90.0`px):** Keep `totalOuterHeight = 90.0` (`barHeight = 56.0`, top overhang = `24.0`, bottom float gap = `10.0`) so height layout invariants remain exact.
- **Theme-Driven Role Palette Styling (`RippleSkin`):** Derive bar background, border, active circle badge, active icon, and inactive labels from `RippleSkin.of(context)` / `Theme.of(context).colorScheme` (`Aqua` for drivers, `Lagoon` for admin, `Chai` for cafe, `Sage` for field agent; tinted dark-surface + dark primary badge in Dark Mode) instead of hardcoded hex overrides, with the center `+` badge (`skin.action`) always visible at index `2`.

---

## Workstream 3: Eliminate Raw `'tanker_driver'` / Role Slugs in UI Titles

### Exact Files
1. `app/Http/Controllers/Api/V1/MeApiController.php`
2. `app/Http/Controllers/Api/V1/HrmApiController.php`
3. `app/Http/Controllers/Api/V1/WaterLogisticsApiController.php`
4. `mobile/lib/features/auth/domain/auth_models.dart`
5. `mobile/lib/features/dashboard/presentation/tanker_driver_dashboard_screen.dart`
6. `mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart`
7. `mobile/lib/features/hrm/presentation/attendance_screen.dart`

### Implementation Rules
- Add `humanizeStaffName(string $name, string $roleSlug): array` helper in PHP controllers (and static `UserProfile.humanizeName(String raw, String roleSlug)` + `UserProfile.roleDisplayLabel(String roleSlug)` in Dart):
  - Map `'tanker_driver'` -> display name `'K. Murugan'` (or linked employee name if present in `employees` table), role label `'Bulk Tanker Driver'`.
  - Map `'driver'` / `'delivery_driver'` -> display name `'S. Karthik'`, role label `'Can Delivery Driver'`.
  - Map `'cashier'` -> `'A. Priya'` / `'Aran Cafe Cashier'`.
  - Map `'agent'` -> `'R. Senthil'` / `'Field Collection Incharge'`.
  - Any snake_case slug like `john_doe` converts to Title Case `'John Doe'` if not matching a specific role slug.
  - Keep raw login identifier in `username` (`$user->name`) and expose clean `display_name` + `role_label` in JSON responses.

---

## Workstream 4: Zero Cross-Vertical Leakage & Strict RBAC Gating (Super Admin Only Cross-View)

### Exact Files
1. `app/Http/Controllers/Api/V1/MeApiController.php`
2. `app/Http/Controllers/Api/V1/HrmApiController.php`
3. `app/Http/Controllers/Api/V1/WaterLogisticsApiController.php`
4. `mobile/lib/features/operations/presentation/driver_surrender_screen.dart`
5. `mobile/lib/core/routing/app_router.dart`
6. `mobile/lib/core/ui/quick_action_sheet.dart`

### Backend & Mobile Rules
1. **Super Admin Detection:** `$isSuperAdmin = ($user->role_id == 1) || in_array(strtolower($roleSlug), ['admin', 'super_admin'], true);`
2. **`MeApiController`:** If `!$isSuperAdmin`, resolve the user's single primary assigned vertical company (matching role -> `profile_key` or single `company_user` record) and return **only that 1 company** in `companies` + force `active_company_id` to it (`can_switch_companies: false`). Only `super_admin` receives all group companies with `can_switch_companies: true`.
3. **`HrmApiController`:**
   - Lock `resolveActiveCompanyId()` for non-super-admins (ignore cross-company `X-Company-ID` headers).
   - Fix `resolveDepotGeofence(int $companyId)` to inspect `$company->trade_name ?? $company->legal_name ?? ''`, `$company->code`, and `company_industry_settings.profile_key`. TMWS (`bulk_water`) returns `'Tiruchendur Murugan Water Supply Mother Plant'`; DK Waters (`packaged_water`) returns `'DK Waters RO Plant & Depot'`; Aran Cafe returns `'Aran Bakery & Cafe Flagship Counter'`.
4. **`WaterLogisticsApiController`:**
   - Add `enforceVerticalAccess(Request $request, array $allowedRoleSlugs, string $requiredVertical): int`: non-super-admins whose role isn't allowed or whose assigned vertical differs receive HTTP `403`.
   - Apply on `storeCanDelivery`, `storePlantIntake`, `storeTripSheet`, `processTripOrder`, `trips`, `tripTrail`, `driverCashSurrender`, `spotAudit`, and restrict `groupWorkspaceInsights` + multi-company admin insights strictly to `super_admin` (non-superadmin receives `403` on `/mobile/workspace` and cross-vertical admin summaries).
5. **`DriverSurrenderScreen` (Mobile Tanker vs Can Split):**
   - Inspect `ref.watch(activeDriverFlavorProvider)` and `activeCompany?.industry`:
     - **`DriverFlavor.tanker` / `bulk_water`:** Completely hide `Van Jar Count Reconciliation` (`Empty Jars Returned`, `Filled Cans Left on Van`, `Damaged / Leaked Jars`). Instead show **Bulk Tanker Trip & Freight Settlement** (`Completed Trips`, `Total KL Dispatched`, `Tanker Vehicle No`, `Freight Cash Collected`, `Diesel / Toll / Motor Expense`, `Driver & Cleaner Batta`, `Net Freight Cash Handover`).
     - **`DriverFlavor.canDelivery` / `packaged_water`:** Keep `Layer 7: Blind Note Denomination Tally` + `Van Jar Count Reconciliation` + `Daily Route Cash Settlement`.
   - Resolve `driver_id` & `route_id` dynamically from auth user / active manifest instead of hardcoded `'driver_id': 1, 'route_id': 1`.
6. **Flutter `GoRouter` (`app_router.dart`) & `QuickActionSheet`:**
   - Redirect non-superadmin users trying to open cross-vertical routes (`/workspace` for non-admin; `/operations/can-sales` or `/operations/cafe-pos` for tanker driver; `/operations/tanker-trip` for can delivery driver; `/operations/tanker-trip` or `/operations/can-sales` for cashier; etc.) strictly to `/`!

---

## Workstream 5: Real-Time Activity Push Notifications (Backend + Mobile Poller + Banner + Badge)

### Exact Files
1. `app/Services/Notifications/ActivityNotificationService.php` *(NEW)*
2. `app/Http/Controllers/Api/V1/HrmApiController.php`
3. `app/Http/Controllers/Api/V1/WaterLogisticsApiController.php`
4. `mobile/lib/core/notifications/push_notification_service.dart` *(NEW)*
5. `mobile/lib/core/providers.dart`
6. `mobile/lib/core/ui/app_scaffold.dart`
7. `mobile/lib/main.dart`

### Activity Triggers & Notification Payload
- `ActivityNotificationService::notifyActivity(int $companyId, int $actorUserId, string $actorDisplayName, string $activityType, string $title, string $body, array $metadata = [])`:
  - Recipients: all `super_admin` users (`role_id = 1` / `admin` role), company Incharges (`field_agent`/`agent` attached to `$companyId`), and optionally actor/audit trail.
  - Persists UUID rows into `notifications` table (`type = 'App\\Notifications\\ErpActivityNotification'`, JSON `data` containing `kind: 'activity'`, `title`, `body`, `category`, `company_id`, `actor_user_id`, `actor_name`, `metadata`, `created_at`).
- Emit on:
  - Can delivery completed (`storeCanDelivery`), Plant intake (`storePlantIntake`), Tanker dispatch / order processed / trip finished (`storeTripSheet`, `processTripOrder`), Cash handover (`driverCashSurrender`), Field payment collection (`collectPayment`), Spot audit (`spotAudit`), Customer onboard (`customerOnboard`), Attendance check-in/check-out (`checkIn`, `checkOut`).
- `WaterLogisticsApiController::markNotificationRead($request, $id)`: handle `$id === 'all'` to mark all notifications for the current user read.
- **Mobile `PushNotificationService` (`ChangeNotifier`):**
  - Polls `GET /api/v1/notifications` every 18s while authenticated & foregrounded, plus immediate `pollNow()` on resume / action completion.
  - Registers device channel via `POST /api/v1/devices/push-token`.
  - When new unread notification IDs arrive (excluding initial seed load), increments `unreadCount`, triggers `HapticFeedback.mediumImpact()`, and displays a top/floating `SnackBar` banner via `rootScaffoldMessengerKey` with "View" action -> `/notifications`.
  - `AppScaffold` displays numeric unread badge on the notification bell icon.

---

## Workstream 6: Always-Live Memory Management & Process Keep-Alive ("Never Kill")

### Exact Files
1. `mobile/lib/core/lifecycle/app_keep_alive_manager.dart` *(NEW)*
2. `mobile/lib/main.dart`
3. `mobile/lib/core/providers.dart`
4. `mobile/android/app/src/main/AndroidManifest.xml`
5. `mobile/lib/features/dashboard/presentation/*.dart` + `tasks_screen.dart` + `driver_surrender_screen.dart`

### Keep-Alive Architecture
1. **`AppKeepAliveManager` (`WidgetsBindingObserver`):**
   - Handles `didHaveMemoryPressure()`: trims decoded bitmap memory (`PaintingBinding.instance.imageCache.clearLiveImages()` + sets `maximumSizeBytes = 25 << 20`) while **preserving** all active `Riverpod` providers, trip timers, odometer tracking state, and navigation stack.
   - Handles `AppLifecycleState.paused` / `inactive`: compacts `imageCache` (`maximumSizeBytes = 20 << 20`), saves live heartbeat timestamp in `SharedPreferences`, and triggers non-blocking `SyncWorker.drainOutbox()`.
   - Handles `AppLifecycleState.resumed`: restores normal `imageCache` budget (`80 << 20`), resumes notification polling (`PushNotificationService.pollNow()`), and reconciles any offline queued items.
2. **Android Manifest (`AndroidManifest.xml`):**
   - Declare `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_DATA_SYNC`, `WAKE_LOCK`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, and `POST_NOTIFICATIONS`.
3. **Screen State Preservation:**
   - Apply `AutomaticKeepAliveClientMixin` (`wantKeepAlive => true`) across all primary dashboards (`TankerDriverDashboardScreen`, `CanDeliveryDriverDashboardScreen`, `CashierDashboardScreen`, `FieldAgentDashboardScreen`, `ExecutiveDashboardScreen`), `TasksScreen`, and `DriverSurrenderScreen`.

---

## Workstream 7: Verification Matrix & Acceptance Criteria

1. `cd d:\PROJECTS\WEBSITES\DK Enterprises && php artisan test` — all existing + new `VerticalIsolationAndPushActivityTest` cases pass with 0 failures.
2. `cd d:\PROJECTS\WEBSITES\DK Enterprises\mobile && flutter analyze` — 0 errors, 0 warnings, 0 infos.
3. `cd d:\PROJECTS\WEBSITES\DK Enterprises\mobile && flutter test` — all existing + updated nav/layout/gating/keepalive tests pass.
4. `cd d:\PROJECTS\WEBSITES\DK Enterprises\mobile && flutter build windows --debug` — cleanly compiles updated `dk_track_mobile.exe`.
5. Update `SESSION_MEMORY.md` with exact post-verification commands and outcomes.

