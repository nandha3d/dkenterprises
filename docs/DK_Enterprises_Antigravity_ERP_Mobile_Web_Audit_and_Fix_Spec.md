# DK Enterprises ERP — Mobile/Web Data Isolation, API Parity, Demo Login & GPS Recovery
## Strict Antigravity IDE implementation and audit specification

**Repository:** `https://github.com/nandha3d/dkenterprises`  
**Target branch:** `main` (create a feature branch before implementation)  
**Application:** Laravel ERP web application + Flutter mobile application  
**Primary objective:** Make the web app and mobile app behave as two clients of the same ERP business system, with one authoritative backend, strict company isolation, identical business values/calculations, and a fully functional GPS module.

---

# 0. NON-NEGOTIABLE ENGINEERING RULES

These rules override convenience, visual shortcuts, demo shortcuts, and agent assumptions.

1. **The backend is the only source of truth for business data and business calculations.**
   - Flutter and web frontend may format, display, filter, paginate, sort, and validate obvious input constraints for user experience.
   - Neither frontend may calculate financial balances, totals, tax, discounts, stock valuation, outstanding amounts, ledger balances, route totals, commissions, profit, payroll, or any other business result.
   - All authoritative calculations must be implemented once in backend domain/application services and returned by API.
   - A frontend must never silently recalculate a missing API value.

2. **No hardcoded business data in production UI.**
   - No hardcoded company names, IDs, balances, transactions, user identities, customer/product records, vehicle coordinates, GPS telemetry, routes, drivers, KPI values, chart series, or financial amounts.
   - No fabricated fallback response when an API fails.
   - No random, sample, or seeded-looking values in production builds.
   - Empty API response means a truthful empty state. API failure means a truthful error/offline state.
   - Demo fixtures are allowed only in an explicitly isolated test/demo environment and must never be mistaken for live data.

3. **Every company-scoped page must show data for exactly one authorized active company.**
   - The only exception is the **Group Workspace / Company Selector landing page**, which may show consolidated group-level information across companies the signed-in user is authorized to see.
   - The Group Workspace is the only place where the cross-company company list, group totals, and company comparison are allowed.
   - Once a company is selected, all subsequent pages, widgets, reports, searches, exports, cached records, and mutations must be scoped to that active company.
   - No page other than Group Workspace may show another company's name, transactions, balances, customers, suppliers, employees, vehicles, stock, or operational information.
   - A company selector may appear elsewhere only if it is a context indicator for the current company; it must not reveal other company data or permit unauthorized switching.

4. **Never trust a company ID, role, user ID, branch ID, financial-year ID, permission, or manager assignment supplied by the client.**
   - Backend derives identity and allowed scope from the authenticated user and server-side assignments.
   - Client headers such as `X-Company-ID`, `X-Branch-ID`, and `X-Financial-Year-ID` are requested context only; backend must validate every value against the authenticated user's access.
   - Reject unauthorized context with 403. Do not silently fall back to another company.
   - All company-scoped queries and writes must include the resolved company scope at the database/query/service layer.

5. **The web app and mobile app must use the same business rules and authoritative API values.**
   - Do not create a second mobile calculation implementation.
   - Do not create a mobile-only business rule that changes web totals.
   - If web and mobile show different values for the same user, company, branch, financial year, date range, filters, and data snapshot, treat it as a defect.
   - API response contracts must be explicit, versioned, documented, and shared by both clients.

6. **Preserve existing workflows and business behavior.**
   - Do not remove existing web functionality to simplify mobile parity.
   - Do not redesign database schemas blindly.
   - Do not replace working accounting, inventory, sales, purchase, or operational logic without tracing its callers, tests, and data dependencies.
   - Do not mark a feature complete because a screen exists. It is complete only when its real API, permissions, validation, persistence, audit trail, and tests work.

7. **No fake success.**
   - A failed network request must never return `success: true`.
   - Do not display a receipt number, invoice number, transaction success, GPS upload success, or saved status until the backend confirms it or a clearly labelled durable offline queue has accepted it.
   - For offline-capable workflows, distinguish `Pending sync`, `Synced`, `Failed`, and `Conflict`. Do not call queued work posted/paid/confirmed.

8. **Do not weaken security to make the demo login or GPS work.**
   - Demo users must be real, explicitly provisioned, restricted accounts in a non-production/demo environment.
   - GPS permissions, background tracking, location retention, and access must be explicit and auditable.

---

# 1. CURRENT REPOSITORY SNAPSHOT AND KNOWN AUDIT FINDINGS

The current repository has a Laravel web application and a Flutter app under `mobile/`. The current mobile code has a more structured architecture than the older build, including Riverpod, GoRouter, an API client, secure storage, local SQLite, and an outbox sync worker. Do not discard this architecture without a documented reason.

Important inspected files:

- `mobile/lib/main.dart`
- `mobile/lib/core/providers.dart`
- `mobile/lib/core/routing/app_router.dart`
- `mobile/lib/core/network/api_client.dart`
- `mobile/lib/core/sync/sync_worker.dart`
- `mobile/lib/features/auth/data/auth_repository.dart`
- `mobile/lib/features/auth/presentation/login_screen.dart`
- `mobile/lib/features/workspace/presentation/workspace_screen.dart`
- `mobile/lib/features/dashboard/presentation/executive_dashboard_screen.dart`
- `mobile/lib/screens/fleet_gps_screen.dart`
- `mobile/pubspec.yaml`
- `routes/api.php`
- `routes/web.php`

## 1.1 High-priority issues already visible in the inspected code

### A. GPS screen contains fabricated telemetry

`mobile/lib/screens/fleet_gps_screen.dart` currently defines `_tankers` and `_waterTrucks` as in-file hardcoded lists. These contain vehicle identifiers, driver names, phone numbers, coordinates, locations, speed, fuel, battery, capacity, delivery counts, geofence state, ETA, valve state, and telemetry-like values.

This is not live fleet tracking. A timer or radar animation does not make fabricated data real. Remove all production use of these lists and any simulated telemetry timer. Replace them with API-fed vehicle/driver/location/event data. Do not invent live location when the device or tracker is not reporting.

### B. Company context exists in the mobile client but must be enforced end-to-end

`ApiClient` attaches `X-Company-ID`, `X-Branch-ID`, and `X-Financial-Year-ID` headers from secure storage. This is useful context propagation, but it is not a security boundary. The Laravel middleware/service layer must independently validate the user's company, branch, and financial-year access on every request.

`AuthNotifier.refreshMe()` restores an active company from locally stored company ID or picks the first company. Audit this behavior carefully:
- A saved company must be revalidated against the latest server-provided authorized company list.
- If the saved company is no longer authorized, clear it and require a valid selection.
- Do not silently select the first company when the user has multiple companies and the business requires an explicit choice.
- When the active company changes, clear or partition all company-specific state and caches before rendering the next company.

### C. Group Workspace currently loads group-level insights

`WorkspaceScreen` calls the workspace endpoint and caches the result under `group_workspace_insights`. It renders group-level totals and company selection. This is appropriate only on the Group Workspace landing page. Verify that the API returns only companies the current user is authorized to see, and that no group cache is reused on company-specific pages.

### D. Dashboard cache is company-keyed, but all caches need a complete scope key

`ExecutiveDashboardScreen` uses `financials_company_$companyId`. Improve this pattern. Cache identity must include at least user ID, company ID, branch ID, financial-year ID, resource, and any filters/date range that affect the response. Purge or invalidate caches on logout, user change, company switch, branch switch, financial-year switch, and permission changes.

### E. Login currently has no verified demo-account flow

The inspected login screen has username/password login and server settings. Add role-based demo account choices only after a backend-owned demo credential/configuration endpoint is implemented. Never hardcode passwords or use client-side role impersonation.

### F. Outbox sync needs stronger semantics

`SyncWorker` currently retries queued mutations and maps non-POST methods through POST fallback. This is unsafe for future PUT/PATCH/DELETE operations. Implement explicit method handling, retry classification, idempotency, conflict handling, and server acknowledgement. Do not blindly retry permanent 4xx validation/permission failures.

### G. Web app has a large route surface

`routes/web.php` loads several route groups and many controllers; `routes/api.php` exposes API v1 modules. Perform a full route-to-controller-to-service-to-model audit. Do not assume mobile parity from the presence of a Flutter screen or API endpoint.

These are confirmed from the inspected files, not a claim that every repository file has already been exhaustively audited. The implementation agent must complete the full audit below before editing.

---

# 2. REQUIRED FULL AUDIT — DO THIS BEFORE CODING

Create and maintain these documents in `docs/audits/`:

1. `ERP_WEB_MOBILE_PARITY_MATRIX.md`
2. `COMPANY_ISOLATION_AUDIT.md`
3. `GPS_MODULE_AUDIT.md`
4. `API_CONTRACT_AND_CALCULATION_AUDIT.md`
5. `IMPLEMENTATION_CHANGELOG.md`

## 2.1 Repository-wide inventory

Inspect the complete repository, not only the files listed above:

- Laravel routes: web, API, operations, commercial, inventory, compliance, orders, reports, and any dynamically loaded route files.
- Controllers, Form Requests, middleware, policies, gates, services, actions, jobs, events, listeners, resources, transformers, models, observers, repositories, and query scopes.
- Migrations, seeders, factories, database constraints, indexes, and tenant/company relationships.
- Blade templates, Livewire components, JavaScript/TypeScript, Alpine code, frontend API calls, dashboard widgets, and report builders.
- Flutter feature folders, screens, providers, repositories, models, DTOs, widgets, navigation, local database, sync/outbox, GPS/location code, permissions, and tests.
- Environment/configuration, queues, scheduler, broadcasting, storage, notification integrations, and deployment scripts.
- Existing automated tests and CI workflows.

Use repository search to find:
- `company_id`, `companyId`, `X-Company-ID`, `activeCompany`, `switchCompany`
- `auth()->user()`, `Auth::user()`, `tenant`, `branch_id`, `financial_year_id`
- `sum`, `total`, `balance`, `tax`, `discount`, `round`, `stock`, `valuation`, `profit`, `receivable`, `payable`
- hardcoded currency values, demo/sample/mock arrays, fallback success, placeholder coordinates, fake driver/vehicle records
- GPS, location, geolocator, permission, background service, tracker, telemetry, geofence, route, beat, trip, attendance check-in.

## 2.2 Trace every critical workflow end-to-end

For each workflow, document:

`UI action → route → middleware → controller → validation → domain/service calculation → database writes/transactions → API response → web rendering → Flutter rendering → tests`

At minimum trace:

- Login, logout, current user, role/permission loading
- Group Workspace and company selection
- Manager assignment and company-scoped access
- Branch and financial-year selection
- Dashboard KPI and consolidated totals
- Sales invoice creation, editing, cancellation, payments, returns
- Purchase bills, supplier payments, returns
- Cash book, bank book, receipts, payments, journals, vouchers
- Trial balance, P&L, balance sheet, ledger, receivable/payable ageing
- Stock overview, stock count, stock adjustment, transfer, valuation
- Customer/supplier/product search and detail
- Expenses and approvals
- HRM, attendance, employee and manager workflows
- Water logistics, can deliveries, tanker trips, plant refills, driver surrender
- Cafe POS, kitchen inventory, cash reconciliation
- Reports, exports, notifications and tasks
- GPS live tracking, history, geofence and route playback.

Record exact file paths, route names, response keys, calculation owners, company scoping behavior, and missing tests. Do not write vague statements such as “API exists” or “mobile supports accounting.”

---

# 3. COMPANY ISOLATION AND GROUP WORKSPACE DESIGN

## 3.1 Required product behavior

There are two distinct contexts:

### Context A — Group Workspace (the only cross-company screen)

This is the landing page after successful login for users who have access to multiple companies or group-level management.

It may show:
- The companies the signed-in user is authorized to access.
- Group-wide totals and comparison cards, if the user's permissions explicitly allow consolidated reporting.
- Company name, logo, industry, status, assigned manager, and high-level summary.
- Search/filter across the authorized company list.
- A clear action to open one company workspace.

It must not include data from companies the user is not authorized to access.

### Context B — Company Workspace (all other pages)

After selecting a company:
- Header/context indicator shows only the selected company.
- All modules load that company's records only.
- No cross-company financial KPI, transaction list, customer, supplier, employee, stock, vehicle or location data.
- All global search results are scoped to the active company.
- All reports and exports are scoped to the active company.
- All dropdowns and autocomplete lists are scoped to the active company.
- Company switching returns the user to Group Workspace or opens a deliberate, permission-checked switch flow. Switching must clear stale screen state before the next company's data is rendered.

For a user authorized for exactly one company, the app may enter that company directly after authentication, but it must still establish and validate the company context server-side. Do not show group totals unless the user has group-level permission.

## 3.2 Manager assignment

Implement or repair company manager assignment as a server-owned relationship.

Audit existing schema first. Reuse existing relationships if they correctly model:
- User belongs to/has access to one or more companies.
- User may be assigned as manager for one or more companies.
- Manager assignment has effective status, role/permission scope, and audit history where appropriate.

If schema changes are required:
- Create a migration with foreign keys and indexes.
- Preserve existing assignments and backfill safely.
- Do not infer managers from display names or client-side role labels.
- Add a dedicated manager assignment service/policy.
- Ensure only authorized group admins can assign or remove company managers.
- A manager sees only the companies and modules explicitly assigned to them.
- A manager for Company A must receive 403 when requesting Company B, even if they alter headers or URL parameters.
- A manager must not be able to assign themselves to another company through API payload manipulation.

Add tests for manager assignment, revocation, company switching, direct URL/API access, search, reports, and exports.

## 3.3 Backend company-context middleware

Implement a single, reusable, fail-closed company-context resolver for all company-scoped API and web actions.

Requirements:
- Authenticate first.
- Resolve requested company context from a documented source (header/session/route, according to the web or API guard).
- Verify user-company membership and role/permission.
- Verify branch belongs to the selected company and is accessible.
- Verify financial year belongs to selected company and is valid/accessible.
- Store resolved context in a request-scoped context object/container.
- Ensure every company-scoped query uses the resolved context.
- Reject missing context when a route requires it.
- Never trust a raw `company_id` in request body as authorization.
- Avoid global mutable static company state.
- Ensure background jobs receive an explicit validated company context and do not leak it across jobs.
- Add automated tests for every middleware branch.

Do not solve leakage by hiding UI widgets only. Enforce isolation in backend queries and authorization.

## 3.4 Flutter state isolation

Create one authoritative `ActiveCompanyContext` state object containing:
- user ID
- company ID
- branch ID
- financial-year ID
- permissions/capabilities version
- context version or generation identifier.

Every repository request must obtain this context from one provider/interceptor. No feature should construct its own company header or silently omit it.

On context switch:
1. Block interactions and show a short transition state.
2. Cancel in-flight requests for the old context where possible.
3. Clear old company-specific Riverpod providers/state.
4. Clear old selected records and form drafts unless safely persisted with company identity.
5. Change active context only after server validation succeeds.
6. Fetch the new company bootstrap/configuration.
7. Load the new dashboard and permitted module list.
8. Ensure no old-company widget remains visible under the new company header.

Never render cached Company A data while the header says Company B.

## 3.5 Cache and offline database partitioning

Every cache/outbox/local record must be scoped with:
- authenticated user ID
- company ID
- branch ID where applicable
- financial-year ID where applicable
- resource name
- query/filter parameters
- schema/API version.

Never use shared keys such as `customers`, `products`, `financials`, or `dashboard` without context scope.

On logout:
- Clear auth tokens and user-specific cached data.
- Remove or quarantine unsynced operations according to an explicit safe policy; never replay one user's pending operations under another user.
- Do not delete financial records on the server.
On company switch:
- Do not delete legitimate pending work for the old company, but keep it isolated and sync it only with the same authorized identity and company context.
- Do not show the old company's cached records in the new company.
- If the user's permission has been revoked, do not sync its pending mutations; flag them for review.

---

# 4. LOGIN SCREEN — ROLE-BASED DEMO OPTIONS

The login screen must remain a real authentication screen. Add a clearly labelled **Demo access** section below the normal login form.

## 4.1 Required UX

- Show one compact card/button per demo role that is actually provisioned by the backend.
- Example role categories may include Group Admin/Super Admin, Company Admin, Company Manager, Accountant, Sales, Purchase, Inventory, HR, Cashier/POS, Field Agent, Delivery Driver, Tanker Driver, and other roles that genuinely exist in this installation.
- Do not invent role names that the backend does not support.
- Selecting a demo role may populate a short-lived demo username or request a server-issued demo session. It must not simply set the Flutter role locally.
- Show the company scope and permissions included in each demo account, without exposing another company's private data.
- If a role has multiple company assignments, let the user select only from the companies provisioned for that demo identity.
- Provide a visible `DEMO` banner after login so demo sessions cannot be confused with production accounts.
- Provide a clear warning that demo data/actions are non-production and may be reset.
- Keep the regular username/password login available.
- Do not display actual passwords in source code, app assets, API responses, remote config, or the UI.

## 4.2 Backend-owned demo access

Implement a non-production-only demo access mechanism:
- Disabled by default in production.
- Controlled by a server-side environment/config flag and deployment policy.
- Demo identities are real database users with explicit roles, company assignments, permissions and limited capabilities.
- Prefer a server endpoint such as `GET /api/v1/demo/accounts` returning only public labels, role descriptions, and opaque demo account IDs, followed by a rate-limited `POST /api/v1/demo/session` that issues a short-lived restricted token.
- Never accept a client-supplied role as proof of identity.
- Use dedicated seeded demo database data only in demo/staging environments.
- Disable sensitive mutations, payments, real SMS/WhatsApp/email, external payments, destructive actions and production GPS writes for demo sessions unless explicitly simulated in an isolated environment.
- Add audit logs identifying demo sessions.
- Rate-limit, expire tokens, and revoke demo sessions.

If the application has no safe demo environment, implement the UI as disabled with a clear message until backend provisioning is complete. Do not fake it.

## 4.3 Login tests

Test every demo role:
- Correct role and company list returned by `/me`.
- Correct default landing screen.
- Correct module visibility and permissions.
- Cannot change role by editing local storage, API payload or headers.
- Cannot access unauthorized company IDs.
- Demo session cannot access production-sensitive actions.
- Demo session expires and logs out cleanly.

---

# 5. WEB ↔ MOBILE FEATURE AND VALUE PARITY

## 5.1 Build a parity matrix from actual code

For every web module, record:
- Web route and UI component
- Backend endpoint(s)
- Required permission(s)
- Company/branch/FY scope
- Mobile route/screen
- Mobile repository/provider
- API response DTO
- Workflow actions supported
- Calculation owner
- Tests
- Parity status: Full / Partial / Missing / Defective.

Do not treat identical screen names as parity.

## 5.2 Shared API contract

Use Laravel API Resources/DTOs or the project's established response abstraction to expose consistent field names and types.

For each endpoint document:
- HTTP method and route
- authentication and permissions
- company/branch/FY scope
- query parameters and pagination
- request validation
- response schema and nullability
- decimal precision/currency behavior
- date/time/timezone behavior
- error codes and validation payload
- idempotency and retry behavior
- audit events.

Where possible, generate or maintain an OpenAPI schema and use typed Dart models generated from the same contract. Do not hand-maintain divergent DTOs without contract tests.

## 5.3 Same data and same values

For a parity test, run the same query from web and mobile with identical:
- authenticated user
- active company
- branch
- financial year
- date range
- status filters
- currency
- pagination/sort criteria.

Compare normalized API/domain values, not just rounded labels. Any mismatch must be traced to backend query logic, stale cache, timezone, rounding, permission scope, or frontend transformation.

Display server-returned totals and balances exactly according to the documented currency precision. Formatting may add grouping symbols and currency symbol but must not alter the numeric value.

## 5.4 Mobile workflow parity

Mobile should support the same business workflow end-to-end where mobile usage is appropriate:
- list/search/detail
- create/edit where permitted
- validation
- approval/rejection where permitted
- payment/receipt workflow
- attachments/photos
- audit history
- status transitions
- print/share/download where supported
- offline queue only for explicitly approved workflows
- sync status and conflict resolution.

Do not merely reproduce the web dashboard. Build mobile-appropriate interactions while retaining identical business rules and backend results.

---

# 6. BACKEND-ONLY CALCULATIONS — ABSOLUTE RULE

Create a calculation ownership register for every business figure.

Examples:
- Invoice subtotal, line discounts, invoice discounts, taxes, cess, round-off, grand total.
- Purchase total, landed cost, purchase return values.
- Receipt/payment allocation and remaining outstanding.
- Cash book/bank book opening, debit, credit and closing balance.
- Ledger balance, trial balance, P&L and balance sheet.
- Stock on hand, reserved stock, available stock, stock valuation, batch/serial quantities.
- Production consumption, yield, wastage and finished goods.
- Driver route collection, delivery totals, cash variance, container/jar variance.
- GPS distance, route deviation, geofence entry/exit duration, idle duration and ETA where these are business metrics.
- Attendance duration, overtime, payroll, incentives and commissions.
- Cafe POS order totals, tax, discounts, settlement and drawer variance.
- Reports, dashboard KPIs and charts.

Rules:
1. Calculation logic belongs in backend domain services/actions, not Blade, JavaScript, Alpine, Flutter widgets, Dart providers, or SQL fragments duplicated across endpoints.
2. Use decimal-safe arithmetic / database decimal columns. Avoid binary floating-point for money.
3. Define rounding policy centrally and test it.
4. Use database transactions for multi-record financial/inventory operations.
5. Use a single source of truth for ledger postings and stock movements.
6. Return calculated fields from API; frontends display them.
7. If a calculation is unavailable, return an explicit error/nullable field with documented semantics. Do not invent a value.
8. Frontend may calculate ephemeral presentation-only values such as progress percentage only when the API explicitly provides numerator/denominator and the value is not an authoritative business result. Prefer backend-provided percentages for dashboards.
9. Add backend unit tests and API feature tests for each calculation.
10. Add web/mobile contract tests that assert both clients display the same API-returned value.

Audit all existing frontend calculations and remove/replace them. Search for arithmetic in Blade, JavaScript, Alpine, Dart, Flutter providers, screen widgets and chart code. Do not remove harmless formatting logic.

---

# 7. GPS MODULE — RESTORE REAL FUNCTIONALITY

The GPS module must return to the functional behavior of the earlier build, but must be audited against current backend capabilities rather than copying old UI mockups. Preserve the previous useful workflow where it exists; do not preserve simulated data.

## 7.1 First, establish what the previous build actually did

Inspect Git history and earlier commits/branches for the last known-good GPS implementation:
- Identify the exact commit and files.
- Compare old GPS screen, route/beat screens, driver app flows, location services, API endpoints, backend tables, map integration, and permissions.
- Record features lost or regressed during the new UI implementation.
- Create a before/after feature matrix.
- Do not assume the older build was fully correct; verify each workflow and API.
- If history cannot be accessed, state that clearly and use the current backend/domain behavior as the source of truth.

## 7.2 Required GPS roles and views

Respect actual role/permission definitions. Typical views may include:

**Group/Company Admin or Fleet Manager**
- Live map of authorized company vehicles only.
- Vehicle/driver list with last-seen time and freshness indicator.
- Filters by vehicle type, route, driver, status and branch.
- Vehicle detail: current position, speed, heading, last update, assigned driver, active trip/route, device health and relevant operational status.
- Trip history and route replay.
- Geofence events and route deviation alerts.
- Driver/vehicle assignment, if permitted.
- Exportable location history, subject to permission and retention rules.

**Field Agent / Delivery Driver / Tanker Driver**
- Own location sharing status.
- Start/end shift or trip workflow, if supported by backend.
- Clear permission and GPS signal status.
- Route/beat and assigned stops.
- Check-in/check-out at customer/site using a server-validated geostamp where business rules require it.
- No ability to see other drivers' live locations unless explicitly permitted.

**Company Manager**
- Only company vehicles and staff assigned to their company and permission scope.

## 7.3 Device-side tracking

Use a maintained Flutter location/background execution solution compatible with target Android versions. Audit package support and licensing before adding dependencies.

Implement:
- Runtime permission flow for foreground location.
- Background location permission only where essential and legally/operationally justified.
- Android foreground service notification during active background tracking.
- Battery optimization guidance where needed; never silently bypass user controls.
- Location accuracy, provider state, GPS disabled state, permission denied/permanently denied, network unavailable and stale fix states.
- Configurable sampling interval and distance filter supplied by backend policy where possible.
- Battery-aware tracking and graceful stop on logout/shift completion according to policy.
- Secure local queue for offline location points.
- Idempotent batch upload with server acknowledgement.
- Retry with exponential backoff and jitter.
- Deduplicate by device ID + sequence number or immutable event UUID.
- Preserve original capture timestamp and server receipt timestamp.
- Detect clock skew and invalid/out-of-order points.
- Do not create a fake coordinate if GPS is unavailable.
- Do not show a vehicle as live if its last point is stale. Display `Last seen X ago`.
- Respect user consent, privacy notices, retention, and access audit.

Do not rely on a Dart `Timer.periodic` while the app is suspended as a background tracking implementation.

## 7.4 Backend GPS data model and APIs

Audit existing tables and endpoints first. Reuse or extend the existing design safely.

The backend should support, as needed:
- Trackable device/vehicle/driver association.
- Location point ingestion (single and batch).
- Current location snapshot.
- Location history with bounded time range and pagination.
- Active trip/route association.
- Geofence definitions and events.
- Route/beat assignment and stop completion.
- Device heartbeat/health.
- Tracking session start/stop.
- Alert acknowledgement and audit trail.

Each location point should have validated:
- company ID (derived/validated server-side)
- vehicle/device/driver association
- latitude/longitude range
- accuracy
- speed and heading when available
- captured_at and received_at
- sequence/event ID
- source/provider and metadata where useful.

Security:
- A driver/device may submit only its own assigned tracking identity.
- Do not accept an arbitrary `company_id` to write into another tenant.
- Fleet viewers can query only their authorized company and assigned scope.
- Never return cross-company points in a list, map, export or history endpoint.
- Validate that vehicle, driver, trip and company relationships match.
- Rate-limit ingestion and protect against replay/abuse.

## 7.5 Map UI requirements

- Use real API coordinates only.
- Map markers must reflect real vehicle records.
- Marker clustering for dense fleets.
- Selecting a marker opens a vehicle detail sheet.
- Provide list/map toggle.
- Show loading, no vehicles, no location permission, stale data, API error and offline states distinctly.
- Show `Live` only when the backend freshness threshold is satisfied.
- Show timestamp and timezone clearly.
- Provide route polyline/history only from real recorded points or server-generated route data.
- Do not animate markers along invented paths.
- Do not display fictional speed, fuel, battery, tank level, flow rate, valve state, ETA or geofence state. These require real sensors/API fields.
- If telemetry is not integrated, omit those fields or label them `Not available`; do not simulate.
- Ensure the map respects the active company context and manager assignment.
- Keep map interactions responsive on low-end Android devices.

## 7.6 GPS acceptance tests

- Two companies have distinct vehicles and drivers; neither can see the other's markers or history.
- Manager of Company A cannot fetch Company B points by changing query/header.
- Driver A can submit only their assigned device/vehicle location.
- Revoked driver/device cannot continue posting.
- GPS denied, GPS disabled, stale point, no network and app background states are truthful.
- Offline points upload once and are deduplicated.
- Out-of-order points do not overwrite a newer current position.
- Map and vehicle list show the same server snapshot.
- Location history is filtered by company, vehicle and date range.
- Background tracking behavior is tested on physical Android devices, not just emulator.
- Battery impact and notification behavior are verified.

---

# 8. API AND AUTHENTICATION AUDIT

Inspect current authentication and mobile-specific endpoints. Ensure:
- Mobile login uses the same real identity/authentication system as web where intended.
- Password verification is server-side.
- Token issuance/revocation follows Laravel Sanctum or the project's established secure mechanism.
- `/me` returns authenticated user, roles, permissions, authorized companies, branches, financial years, active modules and capabilities.
- Public bootstrap endpoints expose no private company/user/financial information.
- Protected mobile endpoints require authentication and appropriate permission/context middleware.
- Every mutation has server-side validation, authorization, audit logging and transaction safety.
- No client-supplied role determines authorization.
- No client-generated fake bearer token.
- No demo fallback on production API failure.
- Tokens are stored in secure storage, expire/revoke correctly, and are removed on logout.
- 401 and 403 are handled distinctly.
- API errors are not swallowed.
- API requests use appropriate timeouts, retry policies and request IDs.
- Sensitive data is not logged in production.

Audit all endpoints in `routes/api.php` and included route files. Build a route coverage report showing which endpoints are used by web, mobile, both, or neither.

---

# 9. MOBILE OFFLINE AND SYNC RULES

Offline mode is allowed only for workflows explicitly designed for it.

- Read-only cached data must display its cache timestamp and stale/offline state.
- Every cached record must be company/user/context partitioned.
- Mutations enter a durable outbox only when the workflow supports offline capture.
- Outbox item stores method, endpoint, payload, user, company, branch, FY, idempotency key, creation time, and status.
- Sync worker must support only explicitly implemented HTTP methods; never turn PUT/PATCH/DELETE into POST.
- Retry network errors and retryable 5xx; do not endlessly retry 400/401/403/404/422.
- 409 conflicts require resolution, not blind retry.
- Server must enforce idempotency on financial and inventory mutations.
- Sync response must map server-generated IDs and authoritative totals back to local records.
- Never label pending transactions as posted, paid, delivered or reconciled.
- Prevent a queued Company A mutation from being sent with Company B context.
- Add a user-visible sync center with pending, syncing, failed, conflict and synced states.

---

# 10. IMPLEMENTATION PLAN — STRICT PHASES

Do not attempt a visual redesign first. Correct data isolation and source-of-truth problems before polishing the UI.

## Phase 0 — Baseline and safety
- Create feature branch.
- Record current commit SHA and working tree status.
- Run existing tests, static analysis and Flutter analyze.
- Capture screenshots of current mobile screens and web dashboards.
- Back up relevant database/schema state in the approved environment.
- Create audit documents.
- No production data mutation.

**Exit:** Baseline is documented; tests and known failures are recorded.

## Phase 1 — Full audit and parity matrix
- Complete repository inventory and workflow tracing.
- Identify all frontend calculations and hardcoded/fallback data.
- Identify company-scoped tables, queries, caches, APIs and routes.
- Identify GPS regressions against previous known-good commit.
- Produce prioritized defect list with severity, file path, evidence and proposed fix.

**Exit:** Audit docs reviewed; no implementation based on assumptions.

## Phase 2 — Backend company isolation
- Implement/reuse server-side company context resolver.
- Audit all web and API queries.
- Enforce manager assignments and company access policies.
- Protect reports, exports, global search, dashboard and background jobs.
- Add cross-company negative tests.

**Exit:** Company A users/managers cannot read or mutate Company B data through any tested route.

## Phase 3 — Authentication and demo access
- Correct mobile/web auth consistency.
- Correct `/me` response and permissions.
- Implement restricted backend-provisioned demo identities.
- Add login demo role cards backed by server config.
- Disable demo functionality in production unless explicitly approved.

**Exit:** Real auth only; demo roles cannot impersonate or escape scope.

## Phase 4 — API contracts and calculation centralization
- Document response contracts.
- Move/centralize business calculations to backend services.
- Remove frontend business calculations and fabricated fallback values.
- Ensure web and mobile call the same endpoints/domain logic.
- Add contract and calculation tests.

**Exit:** Identical API results for identical contexts and query inputs.

## Phase 5 — Flutter context and cache isolation
- Centralize active company context.
- Make every repository use the context-aware API client.
- Partition all cache and outbox data.
- Clear stale providers and screens on context change.
- Add company-switch race-condition tests.

**Exit:** No previous-company data remains visible after switching.

## Phase 6 — GPS restoration
- Compare current and prior GPS implementations.
- Remove mock vehicle/telemetry arrays.
- Implement real location ingestion and query APIs.
- Implement device tracking, offline queue, freshness, map/list, trip history and geofence features according to actual backend capability.
- Test on physical devices.

**Exit:** No fabricated GPS information; live/stale/offline states are accurate.

## Phase 7 — Web/mobile workflow parity
- Implement missing mobile workflows based on the parity matrix.
- Keep mobile UX native and task-oriented.
- Match business rules, fields, statuses, validation and API values.
- Add parity tests for every high-priority workflow.

**Exit:** Every declared mobile-supported workflow is end-to-end functional.

## Phase 8 — UI/UX refinement
- Only after data correctness is established, refine mobile UI.
- Keep the company context clear but do not expose other companies outside Group Workspace.
- Provide readable mobile accounting books, dashboard, module launcher, tasks, profile and GPS screens.
- Use consistent loading, empty, error, offline and permission states.
- Avoid fake decorative KPIs and placeholder cards.

**Exit:** Screens are usable and visually consistent without changing business values.

## Phase 9 — Release validation
- Run Laravel tests, Flutter tests, `flutter analyze`, formatting, PHP static analysis and route audit.
- Run security tests and cross-company isolation tests.
- Run web/mobile parity tests.
- Run physical Android GPS/background tests.
- Review logs for errors and sensitive-data leakage.
- Prepare deployment and rollback instructions.

**Exit:** All acceptance criteria pass; no unresolved critical/high severity defects.

---

# 11. TEST MATRIX — MUST BE AUTOMATED

## Company isolation
- Group admin with access to A+B sees A+B only on Group Workspace.
- Company A manager sees only A in every company-scoped page.
- Company B manager sees only B.
- User with one company cannot discover other companies by changing IDs.
- User with no company assignment receives a safe access error.
- Changing `X-Company-ID` to unauthorized company returns 403.
- Changing branch/FY to an unauthorized one returns 403.
- Search, reports, exports, dashboard, notifications, GPS and background jobs are scoped.
- Concurrent requests during company switching cannot mix responses.

## Calculation parity
- Web and mobile show the same API result for same context and filters.
- Invoice, tax, discount, round-off and payment allocation test vectors.
- Cash/bank ledger and balance test vectors.
- Stock valuation and transfer test vectors.
- Receivables/payables ageing test vectors.
- Driver collection and variance test vectors.
- No frontend-only business calculation remains.

## Demo login
- Every role is provisioned server-side.
- Demo role labels and company scope match backend configuration.
- No password or role privilege embedded in app.
- Production demo disabled by default.
- Demo cannot perform restricted external/destructive operations.
- Demo token expiry and revocation work.

## GPS
- Live point upload and current position.
- Permission denied and GPS disabled.
- Background tracking on supported Android versions.
- Offline queue, retry, idempotency and duplicate prevention.
- Stale data freshness.
- Company and driver isolation.
- Geofence and route history correctness.
- Device revocation and reassignment.

## Workflow parity
- Same sale, purchase, accounting, inventory, HRM, operations and reporting workflow produces the same backend state regardless of web or mobile client.
- Validation failures are consistent and field-specific.
- Server errors never appear as successful mutations.

---

# 12. REQUIRED DEFINITION OF DONE

A phase is not complete until all relevant conditions are met:

- [ ] Every changed file is listed in the implementation changelog.
- [ ] Every business calculation has a documented backend owner.
- [ ] No production screen uses hardcoded business data.
- [ ] No API failure returns fake success.
- [ ] Company scope is enforced server-side for reads and writes.
- [ ] Group-wide data is visible only in Group Workspace and only to authorized users.
- [ ] Manager assignment is enforced in API and web routes.
- [ ] Cache, search, reports, exports, GPS and offline queue respect company context.
- [ ] Login demo choices are backed by restricted server-provisioned demo accounts.
- [ ] Web and mobile use identical authoritative API values.
- [ ] GPS shows only actual received location/telemetry and accurate freshness state.
- [ ] Tests cover positive and negative authorization cases.
- [ ] Flutter and Laravel static analysis pass.
- [ ] No critical/high security or data-integrity defects remain.
- [ ] Screenshots and test evidence are attached to the final report.
- [ ] Deployment/rollback notes are included.

---

# 13. FINAL INSTRUCTIONS TO THE ANTIGRAVITY AGENT

Work as a senior Laravel ERP architect, Flutter lead, application security engineer, QA engineer and GPS/mobile systems engineer.

Do not rush into code generation. First inspect the complete repository and Git history. Use the installed Flutter/Dart, UI/UX, accessibility, Laravel/PHP and testing skills where available.

For every defect:
1. Reproduce or prove it from code/tests.
2. Identify root cause and every affected workflow.
3. Fix it at the correct architectural layer.
4. Add regression tests.
5. Verify web and mobile behavior.
6. Record files changed and evidence.

Do not:
- invent database columns or API routes without checking existing schema;
- add mock records to make a screen look populated;
- put business calculations in Flutter or JavaScript;
- use client role/company values as authorization;
- share group totals on company pages;
- keep old company data in providers or cache after switching;
- simulate GPS movement or telemetry;
- silently fall back to another company or another API endpoint;
- claim success when an API call failed;
- declare a module complete because its UI was created.

If a required capability does not exist in the backend, implement the backend capability first, then connect both web and mobile. If a requirement cannot safely be completed because data, credentials, device hardware, map keys or deployment access are unavailable, document the exact blocker and leave the feature honestly incomplete.

**Final deliverables:**
1. Complete audit documents listed in Section 2.
2. Working backend company isolation and manager assignment.
3. Safe demo login experience.
4. Shared API contracts and backend-only calculations.
5. Fully scoped Flutter app with company-safe cache and workflows.
6. Restored real GPS module with no mock telemetry.
7. Web/mobile parity matrix with evidence.
8. Automated regression/security/parity tests.
9. Deployment and rollback checklist.
10. A final report listing completed, partial, blocked and deferred work separately.

**The highest priority is data correctness and company isolation. A beautiful UI displaying another company's data is a critical failure.**
