# DK Track Mobile: Audit and Full-ERP Mobile Master Prompt

Prepared for Nandhu, Animazon · 7 November 2026 · Repo reviewed: nandha3d/dkenterprises, main at commit 87f31b2

## Read this first

This comes from reading the code: the Flutter app in `mobile/`, the Laravel API in `routes/api.php` and `app/Http/Controllers/Api/V1`, the web sidebar, and `docs/05` and `docs/09`. I did not run the app or see rendered screens, so the UI findings come from code structure. Check sunlight readability yourself on a real phone.

There are four parts: **A** the audit, **B** the gap between the web ERP and the mobile app, **C** the backend work the mobile app needs, and **D** the master prompt to paste into your AI tool.

## Part A. Audit

### A1. Verdict

The app is a reasonable field tool for three DK businesses (tankers, water cans, cafe): six fixed roles, 18 screen files, about 11,600 lines of Dart and roughly twenty API calls. The ERP behind it is zoloERP, which also covers selling, buying, inventory, textile trade and job work, manufacturing, double-entry accounting, GST, HRM, repair and more. The app was built around DK’s businesses, not around the ERP, so UI polish alone will not bring the rest of the ERP across. The structure of the app and the API underneath it both have to change, and the security problems in A2 should be fixed before anything else.

### A2. Security and data-integrity blockers

1. **The mobile login never checks a password.** `mobileLogin` in `WaterLogisticsApiController` picks a role from the text of the username or the `role` field, then returns a random string as the token. It never looks at the users table, and no endpoint verifies that token.
2. **Every `/api/v1/mobile/*` route is outside `auth:sanctum`.** That covers login, bootstrap, dashboard, customers, products, invoices, financials, customer-onboard, collect-payment, spot-audit and driver-surrender. If the server at dkenterprises.animazon.in runs this code, anyone who knows the URL can read customer names, phones and can deposits, and can post a collection (which writes journal lines). I could only check the repo, not the live server. Customer reads are also not scoped to a company.
3. **The app logs anyone in.** In `api_service.dart`, any login response that is not 200 or 201 (a wrong password, for example) falls through to a hard-coded “Demo Test Mode” session. The password field is pre-filled with `admin`, `showDemoLoginRibbon` is `true`, and the one-tap demo logins keep their passwords in source.
4. **Fake numbers appear as real ones.** `financials()` returns fixed values (cash 48,250, bank 1,84,500, receivables 74,200) instead of reading the ledger. The role dashboards sum whole tables with no company filter, and some totals have no date filter either. On the app side, `fetchCustomers` and its siblings return hard-coded sample customers whenever the API fails or returns an empty list, so a new tenant with no customers sees invented ones.
5. **Some writes look like no-ops.** As far as I could see, `spotAudit` and `driverCashSurrender` return a success message without writing anything, and the app then tells the user the record was submitted. Please verify this on your side.
6. **The device chooses the role.** The login sends the role picked in the UI, and `role_selector_sheet.dart` lets users switch role inside the app. Roles and permissions should come from the server. The web ERP already has a roles and permissions system that the mobile app ignores.
7. **The token lives only in memory.** There is no secure storage and no refresh, so the user is logged out whenever Android kills the app.

### A3. Promised but not built

`sqflite` and `geolocator` are in `pubspec.yaml`, but nothing under `lib/` uses them. `docs/05` calls for a fully offline app with background GPS telematics. Today there is no local database, no sync queue and no idempotency keys, so a first offline build would also create duplicate records on retry. The Fleet screen draws a `CustomPaint` radar (`FleetRadarPainter`) rather than a map, and the phone never reports its own location. Server lists are cut at 50 rows (`take(50)`) with no paging, search or delta sync.

### A4. UI and UX findings

What works: bilingual Tamil and English, dark mode, a first screen chosen by role, and workflows that fit the business (can sales, plant refill, tanker trip sheet, spot audit, cafe drawer reconcile).

What does not:

- **Navigation follows company verticals, not tasks.** Tabs are hard-coded per role in `main.dart` (1,170 lines). An admin gets tabs named TMWS, DK Waters and Aran Cafe. There is no module launcher, no global search and no recents, and Can Sales POS appears in both the tab bar and the drawer. This layout cannot hold 25 or more ERP modules.
- **The text is too small.** Of 369 font-size values, 186 are in the 8 to 11 range, about half. Drivers read this outdoors.
- **The look contradicts your own design doc.** `docs/09` asks for flat, industrial, no purple and no frosted glass. The app uses brand purple, 70 `GlassCard` instances and `BackdropFilter` in five places, which is expensive on low-end Android. It also loads Inter through `google_fonts` (downloaded at run time unless bundled) instead of the specified Plus Jakarta Sans, JetBrains Mono and Noto Sans Tamil.
- **Colour carries no stable meaning.** There are 67 hard-coded hex colours on top of the theme tokens, and the accent changes with the role and with each tab.
- **Translation is hand-wired.** There are 428 inline `isTamil ? '…' : '…'` expressions and an `isTamil` flag passed into every screen. With no ARB files, adding a language or sending strings to a translator means editing every screen.
- **No shared components.** `lib/widgets` holds one file, `glass_card.dart`. Every screen builds its own buttons, inputs and loading, empty and error states.
- **Code structure.** `fleet_gps_screen.dart` is 1,267 lines and `ticket_machine_screen.dart` is 908. There are 108 `setState` calls, no state management, and business logic sits inside widgets. The only test is the default `widget_test.dart`.

## Part B. Web ERP versus mobile today

The web sidebar has roughly thirty menu groups. The app reaches a handful of them. The API column says what the Laravel API offers today. P0 means first release, P1 second, P2 last.

| ERP area (web) | On mobile today | API today | Priority |
| --- | --- | --- | --- |
| Dashboard and workspace | Role dashboards with unfiltered totals | `/mobile/dashboard/{role}` only | P0 |
| Products, categories, brands, units, barcode | Read-only price list, first 50 | products list, search, show | P0 scan and stock by warehouse; P1 add and edit |
| Parties: customers, suppliers, agents, areas | Customer list and KYC onboarding | customers, suppliers (read only) | P0 |
| Selling: bills, orders, quotations, returns and credit notes, dispatch register, POS, exchange, instalments, gift cards, coupons, courier | Can sales POS, cafe POS, delivery slip list | sales list, create, show, payments | P0 |
| Buying: bills, purchase orders, returns and debit notes, GRN | None | purchases list, create, show, payments | P0 |
| Inventory: stock by lot, stock count, adjustments, damage audit, transfers | Jar spot audit only | valuation, transfer | P0 |
| Textile trade and job work: challans, DC, packing slips, job work orders, job work GRN, pending with job workers | None | None | P1 |
| Manufacturing: recipes, productions | None | None | P2 |
| Distribution: routes, tanker trips, plant intake, credit ageing, GPS | Trip sheet, can routes, radar | routes, trip-sheets, can-deliveries, plant-intakes, driver-surrender | P0, rebuild |
| Repair center | None | repair jobs list, create, status (ready now) | P1 |
| Cafe and bakery | POS, drawer reconcile | menu, orders, drawer-reconcile | P0, rebuild |
| Projects and sites, booking calendar, eCommerce | None | None | P2 |
| Accounting: vouchers, chart of accounts, journal, ledger, trial balance, P&L, balance sheet, cash flow, day book, cash book, ageing, collections, money transfer | One summary screen with fixed numbers | `accounting/*` covers most; no cash flow, money transfer or inventory close | P0 collections, books, ageing, vouchers; P1 statements |
| Expenses and income | None | None | P0 expense capture |
| GST and compliance: GST review, GSTR-3B, ITC-04, TDS and TCS, e-documents | None | `v1/compliance/*` (report, returns, documents, dispatch) | P1 |
| Reports: sales, purchase, product, warehouse, expiry, quantity alert, payment, user, biller, challan, cash register | None | None | P1 |
| HRM and people: employees, attendance, leave, overtime, payroll, shifts, holidays, users, sale agents, billers | None | None | P0 attendance and leave; P1 the rest |
| Admin: company, branch and financial year switch, roles and permissions, notifications, activity log, WhatsApp, capabilities | None | company-context financial years and capabilities | P0 switcher, permissions, notifications |

Accounting is the biggest quick win: the API is already largely there and the app does not call it. Repair is the second: its three endpoints exist and the app has no screen for them.

## Part C. Backend work the mobile app needs

1. **Replace the public `/mobile/*` group.** Log in against the real users table, issue a Sanctum token per device, and put every route behind `auth:sanctum` and `company.context`. Delete the role-from-username logic and the demo path.
2. **Add `GET /api/v1/me`.** It returns the user, their permission keys mapped from the existing roles, the companies, branches and financial years they can use, and the enabled capabilities (from `company-context/capabilities` and `addons/status`) so the app hides modules a tenant has not switched on.
3. **Fill the API gaps from Part B.** New controllers are needed for quotations, sales orders, returns and credit and debit notes, dispatch register, challans, DC and GRN, packing slips, job work, manufacturing, stock count, adjustments and damage stock, expenses and income, money transfer, HRM (attendance, leave, overtime, payslips), JSON versions of the reports, notifications, the activity log, and approvals.
4. **Add the cross-cutting rules every endpoint needs.** Cursor paging, an `updated_since` parameter for delta sync, server-side search, an `Idempotency-Key` header on every POST, client timestamps stored beside server timestamps, one error format with field-level errors, photo and signature upload, push token registration, PDF links for printable documents, and a minimum app version check.
5. **Fix the wrong data.** Make `financials()` read the ledger (reuse the `accounting/*` services), filter the dashboards by company and date, remove `take(50)` or replace it with paging, and make `spotAudit` and `driverCashSurrender` save a record with an audit trail.

## Part D. Master prompt

Paste everything between the two markers into your AI tool (Claude Code or Gemini in your IDE for the build, Google Stitch if you want a visual pass first). Do not ask for the whole app in one go: D11 splits the work into phases, so give the tool one phase per session and review before the next.

**▶ START OF PROMPT**

You are a senior Flutter engineer and product designer. Rebuild the DK Track mobile app (`mobile/` in this repository) into a complete mobile client for the whole zoloERP system, used by owners, managers, accountants, store staff, field agents, drivers and cashiers.

**D1. Context**

- Backend: Laravel zoloERP in this repo. REST under `/api/v1`, Sanctum auth, multi-company through `company.context`. The web sidebar is the reference list of modules: Master Data (Products, Parties, Commercial Masters), Inventory, Transactions (Buying, Selling), Operations (Job Work, Manufacturing, Projects, Distribution, Repair, Cafe, eCommerce, Bookings), Finance (Accounting, Expenses, Income), Compliance (GST), Reporting, Organization (People, HRM) and Administration.
- Existing app: Flutter in `mobile/lib`. Keep the proven workflows (Can Sales ticket machine, plant refill, tanker trip sheet, spot audit, cafe POS and drawer reconcile, driver cash surrender) and rebuild them on the new design system. The speed target stays: a can sale in under 15 seconds.
- Users: Tamil Nadu SMB staff on low to mid Android phones (2 to 4 GB RAM), patchy 4G, often outdoors. Tamil first, English second.

**D2. Non-negotiables**

1. Real authentication only. No demo mode, no default passwords, no role picker. Role and permissions come from the server through `GET /me`. Delete `showDemoLoginRibbon` and every hard-coded sample dataset from release code. Sample data may exist only under `test/` or behind a debug flag that cannot ship.
2. Never show fake or stale data as live. Every list shows whether it is live or cached, and when it was last refreshed. An API failure shows an error state, never invented records.
3. Offline-first for field work (D8). Every create action works offline and syncs later with an idempotency key.
4. Permission-driven UI: hide what the user cannot use. The server still enforces every rule.
5. No text under 12 sp. Primary buttons are 56 dp tall and every touch target is at least 48 dp.
6. No hard-coded strings. All text lives in ARB files (ta and en now, structured so hi and te can be added). No `isTamil` flags.
7. Money is shown in Indian format (₹1,48,500.00) and calculated with decimals or integer paise, never `double`.

**D3. Design system**

Direction: calm, rugged and task-first. Flat surfaces, 1 px borders, high contrast, big numbers, one primary action per screen. Think of a good banking app crossed with a field-service tool. No frosted glass, no blur, no purple gradients.

*Colour*

- One primary action colour for every role: blue `#0369A1` (light) and `#38BDF8` (dark). The web brand navy `#021840` and purple `#7D287E` appear only on the logo, splash and login.
- Semantic colours, used the same way on every screen: success, money in and synced `#059669` (dark `#10B981`); danger, money out, overdue and failed `#DC2626` (dark `#EF4444`); warning, pending and needs attention `#D97706` (dark `#F59E0B`); info `#0284C7`.
- Light surfaces: canvas `#F8FAFC`, card `#FFFFFF`, border `#E2E8F0`, text `#0F172A`, muted `#475569`. Dark surfaces: canvas `#0B0F17`, card `#111827`, border `#1F2937`, text `#F8FAFC`, muted `#94A3B8`.
- Light is the default because of outdoor use. Dark is optional and can follow the system setting.
- Contrast is 7:1 for body text on field screens and at least 4.5:1 everywhere else.
- Business identity (Tankers, Water, Cafe and so on) is shown as a small tag or icon, never by recolouring the whole app.

*Typography*

- Latin text: Plus Jakarta Sans. Amounts and odometer readings: JetBrains Mono, or Inter with tabular figures. Tamil: Noto Sans Tamil in weights 500, 600 and 700. Bundle every font as an asset; nothing downloads at run time.
- Scale in sp: display 32, title 22, section 18 semibold, body 16, label 14 semibold, caption 12 minimum. Totals on POS and document screens are 32 to 40 bold. Add 10 per cent line height for Tamil. Layouts must survive 1.3 times system font scale, and the app has its own text size setting (S, M, L, XL) for drivers.

*Layout and shape*

- 4 pt grid (4, 8, 12, 16, 24, 32) with 16 dp screen padding. The primary action is anchored at the bottom, in the thumb zone. Every document form has a sticky totals bar.
- Radius 12 on cards, 14 on buttons and inputs, full on chips. Cards are flat with a 1 px border. One soft shadow level, for bottom sheets only. No `BackdropFilter` anywhere.

*Component kit* (build once in `core/ui`, with golden tests for light, dark, Tamil and large text)

AppScaffold with top bar (company, branch and financial year chip, search, bell, sync dot), bottom navigation, ModuleTile, KpiCard (value, change, sparkline), list rows for party, document, product and ledger entry, StatusChip (Draft, Pending, Approved, Paid, Overdue, Cancelled, always colour plus icon plus word), AmountText, Stepper (minus, value, plus, with long-press repeat and tap-to-type number pad), PaymentModeSelector (Cash, UPI, Credit, Cheque, Bank), SearchField with barcode scan and voice, FilterChips row, DateRangePicker, EmptyState, ErrorState, OfflineBanner, Skeleton loader, ConfirmSheet, SignaturePad, PhotoCapture (compressed, stamped with time and GPS), DocumentHeader, LineItemEditor, TotalsBar, AuditTimeline and an undo Snackbar.

*Motion, feedback and accessibility*

- Motion is 150 to 220 ms ease-out, with haptics on confirm and error, and it respects the system reduce-motion setting.
- Every control has a semantics label. Status is never shown by colour alone. Navigation icons always carry labels. Offer a high-contrast mode and the large text setting above.

**D4. Navigation and information architecture**

- Bottom bar with five slots: Home, Tasks, a centre + New button, Modules and Me. The tabs never change by role; their content does.
- - New opens a bottom sheet of the quick actions this user is allowed: new sale, collect payment, new customer, add expense, new purchase, stock count, new job card, check in.
- Modules is a searchable grid of tiles grouped like the web sidebar (Sell, Buy, Stock, Parties, Money, Operations, People, Reports, Admin). Tiles are filtered by permissions and by the tenant’s enabled capabilities. A long press pins a tile to Home.
- The top bar on every main screen shows the company, branch and financial year chip (tap to switch), global search, the notification bell and a sync dot (green synced, amber with a pending count, red failed).
- Global search finds customers, suppliers, products (by name, code or barcode), documents by number and ledgers, with recents and a scan button.
- Tasks is the work queue: today’s route or stops, drafts, approvals waiting for me, overdue follow-ups and records that failed to sync.
- Every document has a link that opens from notifications and WhatsApp. The router checks permissions, so a user without access cannot reach a screen through a link.

**D5. Home by job**

Home is built from the user’s permissions, not from a fixed role. Start from these layouts:

- Owner or group admin: today’s sales, collections, purchases, cash and bank, receivables, payables and stock value; alerts for overdue, near-expiry, low stock, pending approvals and vehicles with no GPS signal; a switch between companies and businesses instead of tabs.
- Manager: approvals inbox, today’s dispatch, collections due, stock alerts, team attendance.
- Accountant: collections to allocate, vouchers to approve, day book, ageing, GST review items.
- Store keeper: GRN waiting, transfers in transit, open stock counts, expiry and low stock.
- Field agent: today’s beat with a visit list, collect payment, new customer with KYC, take order, outstanding by customer.
- Delivery driver: start shift (odometer and load), next stop, Can Sales ticket, plant refill, cash on hand, end-of-day cash surrender.
- Tanker driver: active trip, new trip, odometer, surcharges (motor, waiting, toll), fuel voucher, decanting, spot audit.
- Cashier: touch POS, drawer, KOT queue, day close.
- Supervisor or HR: attendance today, leave and overtime approvals.

**D6. Module specifications**

Build every module below as list, detail, then create and edit, using the patterns in D7. If the backend cannot yet support writes for a module, ship it view-only and say so on the screen.

1. **Selling.** Sales bills, orders, quotations, returns and credit notes, dispatch register, exchange, instalments, gift cards, coupons, courier. Create a bill by choosing a customer, adding items by scan or search, then quantity, rate, discount, tax and bill sundry, then payment, then save, print or share on WhatsApp. A quotation converts to an order and an order to a bill with partial fulfilment. Retail POS has barcode scan, hold and recall, split payment, and coupon or gift card at checkout.
2. **Buying.** Purchase orders with approval, purchase bills, GRN against a PO with lot and expiry capture and photo proof, returns and debit notes, supplier payments.
3. **Parties.** Customer and supplier 360: tap to call, WhatsApp or open in maps, outstanding with ageing buckets, credit limit, statement as PDF, last ten documents, can and deposit balance for water customers, KYC documents. Create and edit with GST lookup and a duplicate check. Agents, brokers and areas as simple lists.
4. **Products and inventory.** Product list and detail (photo, price list, stock by warehouse and lot, expiry), barcode or QR lookup, add and edit with photo capture, stock by lot, stock count (scan to count, variance review, submit), adjustments and damage with reason and photo, transfers with send, in-transit and receive states, low stock and expiry alerts, label printing over Bluetooth.
5. **Textile trade, DC and job work.** Challan and delivery challan create, dispatch register, DC to GRN flow with partial receipts, rework and return, packing slips with scan, job work orders, material DC to a job worker, job work GRN, pending with job workers, ITC-04 view, and signature and photo proof on every hand-over.
6. **Manufacturing.** View recipes and BOM, create a production order (issue ingredients, record output and wastage), production history.
7. **Distribution (water and tankers).** Routes and beat list, Can Sales ticket machine, multi-load plant refill, tanker trip sheet with surcharges, driver cash surrender, credit ageing, live map with vehicle trail and trip replay. Background GPS runs only during an active shift.
8. **Cafe and bakery.** Touch POS with categories and modifiers, hold and recall, split payment, KOT, drawer open and close with reconciliation, day close, Bluetooth thermal printing.
9. **Repair center.** Job sheets as status chips (Received, Diagnosing, Waiting for parts, Ready, Delivered), create a job with device, issue and photos, update status, parts used, customer signature on delivery, convert to invoice.
10. **Accounting.** Collections (receipt with allocation to open invoices and a preview before posting), vouchers (receipt, payment, journal, contra), day book, cash book, cash and bank accounts with money transfer, ledger drill-down, ageing for receivables and payables, trial balance, profit and loss, balance sheet, cash flow, approvals. Statements are read-only with a date range and PDF export.
11. **Expenses and income.** A quick expense in under 20 seconds: category, amount, payment mode, bill photo, GPS stamp. Fuel and mileage entries, approval status for my expenses, income entries.
12. **GST and compliance.** GST review summary, GSTR-3B, ITC-04 and TDS and TCS views with export, e-document status with retry, approval of credit and debit notes.
13. **Reports.** A report library with favourites: sales, purchase, product, warehouse stock, expiry, quantity alert, payment, user, biller, challan and cash register. Each has a date range, filters, a chart, and PDF, Excel or share export. Offline shows the last snapshot with its timestamp.
14. **HRM and teams.** Geofenced check-in and check-out with a selfie and shift, leave apply and approve, overtime, holidays, payslips (read), employee directory. Users, agents and billers as admin lists.
15. **Projects, bookings and eCommerce.** Task board and my tasks, booking calendar with day and week views and quick create, and an eCommerce order list with pack and ship status where the tenant has it enabled.
16. **Admin and settings.** Company, branch and financial year switch, profile, language, theme, text size, printers, sync centre (pending queue, retry, conflicts), notification centre, activity log (read), permissions viewer, WhatsApp share templates, app lock with biometrics or PIN, app version.

**D7. Shared screen patterns**

- List screens: search, filter chips, sort, a date range where relevant, pull to refresh, infinite scroll with skeleton rows, empty, error and offline states, a cached-at label when offline, and swipe actions for the two most common actions.
- Detail screens: status chip and headline amount at the top, a sticky action bar with the next valid step first, tabs only when there are more than three sections, an audit timeline, attachments, print and share.
- Document forms (bills, orders, GRN, vouchers): header, line items, charges and tax, and a sticky totals bar with one Save button. Save draft and Submit are separate, unsaved changes survive the app being killed, and every number field uses a numeric pad with the unit shown.
- Approvals: one inbox for every document type, approve or reject with a reason, the document one tap away.
- Print and share: PDF from the server for official documents, local rendering for thermal slips, WhatsApp and the system share sheet.
- Every destructive action asks for confirmation and offers undo where possible.

**D8. Offline and sync**

- A local database (Drift on SQLite) caches masters (customers, suppliers, products, prices, routes, accounts, warehouses) and refreshes them with delta pulls using `updated_since`.
- Writes go to an outbox table (UUID, endpoint, payload, idempotency key, client time, GPS, status, attempts, last error). A sync worker drains it on reconnect and on a timer with exponential backoff, and keeps running in the background.
- These flows must work fully offline: can sale, plant refill, tanker trip, collections, expense capture, attendance, stock count, cafe POS orders, visit logs, GRN and transfers.
- Online only: approvals, statements, GST views and report generation. Reports show a cached snapshot with its time.
- Conflicts: the server wins on master data, documents created on the phone are append-only, and editing an existing document needs a connection. A conflict or rejection lands in the Sync Centre with the reason and a retry or discard choice. It never disappears silently.
- Background location uses a foreground service during active shifts only, every 30 seconds while moving and every 5 minutes when idle, uploaded in batches, with a clear permission explanation in Tamil and English.
- Logout wipes the local database, after a warning if the outbox still holds unsent records.

**D9. Architecture**

- Flutter with feature-first folders: `core/` (api, db, sync, auth, l10n, theme, ui) and `features/<module>/{data,domain,presentation}`.
- Suggested packages (pick maintained equivalents if needed): Riverpod for state, go\_router with permission guards, dio with interceptors for auth, retry and idempotency headers, drift, freezed and json\_serializable, flutter\_secure\_storage, workmanager, firebase\_messaging, mobile\_scanner, a Bluetooth thermal printing package, flutter\_map or google\_maps\_flutter, and intl with ARB.
- Tokens in secure storage with refresh, a biometric or PIN app lock, no credentials in source, `--dart-define` for environments (production, staging), and no localhost fallbacks in release builds.
- Tests: unit tests for the sync engine and the money maths, golden tests for the component kit, an integration test that creates a sale offline, restores the network and checks that exactly one record exists on the server, and a permission test that a cashier cannot open Accounting.
- CI runs analysis, tests and a release build on every push.

**D10. Acceptance criteria**

1. Wrong credentials fail. No demo or sample data path exists in a release build.
2. Every module in D6 is present, or is marked view-only with a visible reason.
3. Cold start is 3 seconds or less and lists scroll at 60 fps on a 3 GB Android phone. The release APK is under 50 MB.
4. A can sale takes 4 taps or fewer and under 15 seconds, offline.
5. Switching the network off during a submit and retrying creates exactly one server record.
6. Every screen has loading, empty, error and offline states.
7. No text below 12 sp, the contrast targets in D3 are met, and the app is usable at 1.3 times font scale in Tamil.
8. A script confirms that every ARB key exists in both ta and en, and that no string is hard-coded in a widget.
9. A user sees only the modules their permissions and the tenant’s capabilities allow.

**D11. Build phases** (run one phase per session, and stop for a demo before the next)

0. **Backend security and `/me`** (Part C items 1 and 2). Blocks everything else.
1. **Foundation.** Component kit, theme, ARB, auth, navigation shell with Modules and global search, company switcher, local database and sync engine, Sync Centre.
2. **Field core.** Rebuild Can Sales, plant refill, tanker trip, collections, expenses, attendance, spot audit, cafe POS and background GPS on the new base, fully offline.
3. **Commercial core.** Parties, products, selling, buying, quotations, orders, returns, inventory and stock count, dispatch, DC and GRN.
4. **Finance and reports.** Vouchers, books, ageing, statements, reports, approvals inbox, GST views.
5. **Long tail.** Job work, manufacturing, repair, HRM, projects, bookings, eCommerce, admin tools.

**◀ END OF PROMPT**
