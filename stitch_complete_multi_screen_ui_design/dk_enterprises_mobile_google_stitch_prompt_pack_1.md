# DK Enterprises Mobile — Google Stitch Prompt Pack

*Full-prototype prompts for Admin, Driver (can + tanker), Cafe In-charge and Field Agent. Built from a read of github.com/nandha3d/dkenterprises (the Flutter `mobile/` app, its router, role dashboards, forms, API endpoints and `docs/05`, `docs/09`). 12 Nov 2026.*

## 0. How to use this pack

1. In Stitch create a project and choose **Mobile** (390×844).
2. Paste the **Style Anchor** (section 3) at the top of every prompt, then paste **one screen block** under it. Stitch is most reliable with one screen, or one tight flow of 2 to 4 screens, per prompt.
3. Generate in this order to lock the look first: **G-02 Login → A-01 Admin Home → D-01 Can Driver Today → C-01 Cafe Home**. If the look is off, edit the Master Design System (section 2) and the Style Anchor once, then continue with the rest.
4. Tags: **\[TODAY\]** = the screen exists in the current app. **\[NEW\]** = not in the app yet; added so mobile covers the whole ERP.
5. Every block ends with `TAP →` lines. Wire these in Stitch's prototype mode so the prototype is clickable end to end.
6. Sample data comes from the repo (R. Muthu, K. Murugan, Tata Ace TN-58-WA-101, Tata LPT 2518, Aran Cafe, TMWS, DK Waters). Replace freely.
7. Section 12 at the end is a checklist of every screen ID so nothing is missed.

## 1. What the current app is (audit snapshot)

- Flutter app branded **ZOLO ERP** (login subtitle: *DK Enterprises — Enterprise Field Mobile*). Same 4 tabs for every role: Home, Tasks, Modules, Profile, with a curved "fluid" bottom bar and a "+" quick-action button in the app bar.
- Roles (decided at login): admin / super admin, tanker driver, can delivery driver, cafe cashier, field agent. The Home tab swaps dashboards by role.
- Four companies: **Aran Cafe** (cafe\_bakery), **Tiruchendur Murugan Water Supply – TMWS** (bulk\_water tankers), **DK Waters** (packaged\_water, 20L cans on Tata Ace vans), **Textile**.
- Look today: Deep Ocean Blue `#0369A1`, slate canvas, white cards with 1px borders, dense lists, long forms. Bilingual English / Tamil, light / dark, offline outbox with sync.
- Gaps this pack fixes:
  1. The module launcher links to `/suppliers` but no suppliers screen exists.
  2. The "Quotations" card just opens the invoice list.
  3. The leaves API exists but there is no leave screen.
  4. Reports shows only two summaries (Sales Performance, Inventory Valuation).
  5. Cafe has a POS screen but no tables / KOT, held orders, refunds, drawer count or production.
  6. No notification center, printer setup or change-password screen that I could find.
  7. Older screens in `lib/screens` (group super admin, route settlements, auto-GPS tanker sheet, thermal slip, fleet radar variants) are not reachable from the current router; their features are folded in below.

## 2. Master Design System: "Ripple"

**Idea:** calm, warm and confident instead of an industrial console. Water-clear surfaces, big friendly numbers, one hero card per screen, bento tiles for the rest. Same components, three role skins.

**Core palette (light)**

- Canvas Paper `#F5F3EE`, Surface `#FFFFFF`, Surface-2 (tonal) `#ECEFEA`, Hairline `#E3E1DA` (rarely used; separate with tone, not borders)
- Ink `#13201B`, Muted ink `#66736C`
- Money-in Mint `#1FA971`, Money-out Coral `#E8505B`, Pending Honey `#E9A23B`, Info Sky `#2E90FA`, Destructive Ruby `#D92D20`

**Core palette (dark)**: Canvas `#0E1512`, Surface `#17221D`, Surface-2 `#1F2E27`, Ink `#EDF3EF`, Muted `#93A39B`. Same semantic colors, slightly brighter.

**Role skins**

| Role | Skin name | Primary | Accent / CTA | Canvas |
| --- | --- | --- | --- | --- |
| Admin | Lagoon | Deep lagoon `#0B5D52` (hero cards) | Lime `#C9F36A` on dark hero; Aqua `#22B8CF` for water data | Paper `#F5F3EE` |
| Driver (can + tanker) | Aqua Day | Aqua `#0E8FB3` | Sun `#FFC933` with ink text for the one big action slab | Cool white `#F3F8FA` |
| Cafe in-charge | Chai & Crema | Terracotta `#C2542D` | Saffron `#F4A62A` | Cream `#FBF4EA`, cocoa ink `#2B1B14` |
| Field agent | Field Sage | Sage `#3F7D58` | Lime `#C9F36A` | Paper |

**Typography:** Manrope (700 to 800) for UI and headlines, tabular numerals on every amount. Noto Sans Tamil (600/700) for Tamil. Display numerals 44/48, H1 28, H2 20, body 16, caption 12. Minimum tap target 48px (driver and cafe screens 56px).

**Shape and depth:** hero card radius 28, cards 20, inputs 14, chips and buttons fully round. Separate layers with tone, not outlines. One soft shadow only: floating nav bar and bottom sheets.

**Layout:** 16px side margins, 12px bento gap, primary action pinned to the bottom thumb zone with 16px margin, sticky summary above it on forms. Max 4 numbers in any hero card.

**Components (use consistently):** floating pill bottom nav (64px high, active tab shown as an icon + label capsule), hero card, bento tile (1×1 and 2×1), KPI numeral with delta chip, status pill, segmented control, big stepper (− 14 +) with 64px buttons, money field with ₹ prefix and inline numeric pad, bottom sheet with drag handle, vertical timeline, progress ring and bar, **sync pill** (Synced ✓ / Syncing… / Offline · 3 pending / Sync error), **language toggle** (EN | தமிழ்), search pill, filter chips, list row with icon in a tonal circle, toasts, skeleton loaders, simple duotone line-art empty states, offline banner.

**Motion:** 200ms ease-out; hero numerals count up once; sheet slide-up; stepper buttons give a tiny press scale. No parallax, no glass blur.

**Accessibility:** contrast AA or better outdoors (driver screens AAA for body text), every status uses icon + text + color, never color alone.

**Do not:** purple or indigo gradients, glassmorphism, 3D blobs, stock-photo people, hairline-bordered spreadsheet look, more than one filled primary button per screen.

**Data formats:** ₹ with Indian grouping (₹1,48,500), dates `12 Nov 2026`, times 12-hour with seconds on tickets (09:34:12 AM), phone `98421 XXXXX`, GSTIN `33AAAAA0000A1Z5`.

## 3. Style Anchor (paste at the top of every Stitch prompt)

```text
Mobile app, 390×844, Material 3 structure with a custom "Ripple" skin. Warm-paper canvas (#F5F3EE), white surfaces, tonal separation instead of borders, 28px hero cards, 20px cards, pill buttons and chips, large tabular numerals in Manrope ExtraBold, Noto Sans Tamil for Tamil text. Floating pill bottom navigation. One hero card and one primary action per screen, bento tiles for secondary data. Role skin: [ADMIN = Lagoon deep green #0B5D52 + lime #C9F36A] [DRIVER = Aqua #0E8FB3 + sun-yellow #FFC933 action slab, 56px taps, English with Tamil sub-labels] [CAFE = Terracotta #C2542D + saffron #F4A62A on cream #FBF4EA] [AGENT = Sage #3F7D58]. Currency ₹ with Indian grouping. Show a small sync pill and company chip in the top bar. No purple, no glassmorphism, no stock illustrations, no thin bordered tables. Include every element listed below; do not omit or rename any.
```

## 4. Navigation maps (wire these in the prototype)

- **Admin** floating nav, 5 slots: **Home · Trade · (+) · Money · More**. Trade = Sales | Purchases | Quotes. Money = Cash & Bank hub. More = all-modules grid with search. (+) opens Quick Actions (A-04). Top bar on every screen: company chip (tap = switcher sheet G-05), sync pill, bell (G-08), avatar (G-10).
- **Driver (can and tanker)** 4 slots: **Today · Work · Cash · Me**. Work = stops / trip tools. Cash = expenses + surrender.
- **Cafe in-charge** 5 slots: **Counter · Orders · Drawer · Kitchen · Me**.
- **Field agent** 4 slots: **Collect · Customers · Spend · Me**.

## 5. Shared and sign-in screens (G)

### G-01 · Splash \[NEW\]

```text
SCREEN G-01 Splash. Full-bleed deep lagoon (#0B5D52) with a soft ripple-ring animation behind a white droplet-and-cup monogram. App name "DK Enterprises" 28px, caption "Enterprise Field Mobile · powered by ZOLO ERP". Thin progress bar at the bottom and text "Preparing your workspace…". Footer: "v1.0.0+1".
TAP → auto-advance to G-02 (or Home if already signed in).
```

### G-02 · Login \[TODAY\]

```text
SCREEN G-02 Login. Top 40% hero (lagoon) with monogram, title "DK Enterprises", subtitle "Enterprise Field Mobile". Top-right: language toggle (EN | தமிழ்) and a gear icon "Server Settings".
Card rising over the hero: field "Username / Phone" (hint "e.g. driver, agent, admin"), field "Password" (hint "Enter your corporate password", show/hide eye), full-width primary button "Sign In to Account".
Below: section label "Demo Role Fast-Login Options" with 5 chips: Admin, Can Driver, Tanker Driver, Cafe Cashier, Field Agent (each chip has a small role icon).
Footer caption: "Secure Multi-Tenant Sanctum v1 Engine" and a network status dot (Online / Offline).
Validation text: "Username is required", "Password is required".
TAP → Sign In → G-06 if user has several companies, else the role Home (A-01 / D-01 / T-01 / C-01 / F-01). Gear → G-04. Chips autofill and sign in.
```

### G-03 · Login states \[TODAY\]

```text
SCREEN G-03 Login states, 3 frames side by side: (1) loading: button shows spinner and "Signing in…", fields disabled; (2) error: inline coral banner "Invalid username or password" with the password field highlighted; (3) offline: amber banner "No network. Check connection or Server Settings" with a "Server Settings" link button.
```

### G-04 · Server Settings sheet \[TODAY\]

```text
SCREEN G-04 bottom sheet "ERP Server Settings". Helper text "Enter the backend API base endpoint:". Field "API Base URL" prefilled https://dkenterprises.animazon.in/api/v1. Button row: secondary "Test Server Connection" (shows a result chip: green "Success" or coral "Network" error), text button "Cancel", primary "Save & Apply".
```

### G-05 · Switch Organization sheet \[TODAY\]

```text
SCREEN G-05 bottom sheet "Switch Organization", subtitle "Select an accessible company and operational branch". List of company cards with industry icon and name: Aran Cafe (cafe), Tiruchendur Murugan Water Supply (tanker), DK Waters (can), Textile (loom). Selected card expands to show Branch chips (e.g. Main Branch) and Financial Year chips (current year marked "Current"). Primary "Apply".
TAP → Apply returns to the Home of the chosen company.
```

### G-06 · Group Workspace \[TODAY\]

```text
SCREEN G-06 "DK Enterprises Group" workspace (admin with several companies). App bar: title, theme toggle (Switch to Light/Dark Theme), "Sign Out".
1) Hero card "Consolidated Multi-Tenant Treasury" with pill "ACTIVE ROLLUP": three numerals Group Turnover, Cash & Bank, Receivables.
2) "Company Workspaces": horizontal pager of company cards with Previous Company / Next Company arrows, each card has "Open Workspace" and a Turnover figure.
3) "Revenue Share & Multi-Vertical Insights", subtitle "Live turnover distribution across operating entities", pill "3 VERTICALS": donut chart + legend rows: Aran Cafe (Bakery Counter & Dining POS), Tiruchendur Murugan Water (Heavy Bulk Tanker Freight), DK Waters (20L Packaged Can Beat Delivery).
4) "Operations & Service Carts", subtitle "Live order carts, dispatch volumes & delivery beats": three bento tiles. Aran Cafe POS Carts: "9 Active Carts", "Order Volume: ₹2,450", tags Kitchen KOT & Express Dining, Live Counter Billing. TMWS Tanker Logistics: "48 KL Dispatched", "Heavy Tanker Trips: 4 Done", tags Borewell Hub to Texvalley, Anti-Siphon Secured. DK Waters Can Delivery: "120 Cans / 60 Stops", "Daily Route Beat: Active", tags 100% Empty Can Custody, Tata Ace Van En Route.
5) "Group Treasury & Capital Liquidity", subtitle "Liquid Cash & Bank vs Outstanding Customer Dues": two horizontal bars labelled "Cash & Bank:" and "Receivables:".
6) Vertical info cards (2×2 grid): Bakery & POS (POS Carts & Counter Bills · Touch Billing Active · Kitchen Display & Dining Orders · Instant KOT & Table Checkout); Bulk Tankers (16-40 KL) (Fleet Logistics & Decanting · Anti-Siphon Gate Active · Heavy Borewell Tanker Trips · Live Decanting Flow Telemetry); Packaged Water (20L Cans) (Tata Ace Beat Routes · Daily Can Custody & Deposits · 60-84 Can Van Distribution · Empty Jar Balance & Surrender); Textile & Fabric Loom (Bale & Yard Inventory · Wholesale DC & Loom Rolls · Fabric Quality & Shade Grading · GST E-Way Bill & Challan). Plus a generic Enterprise Workspace card (General Operations · Multi-Branch Consolidated · Standard Sales & Expenses · Double-Entry Audit Ledger).
STATES: skeleton loading; error "Failed to load group insights / Network timeout. Pull down to refresh." with Retry; empty "No companies assigned to your profile."
TAP → Open Workspace → A-01 for that company (cafe → A-02a, tankers → A-02b, cans → A-02c, textile → A-02d). Cards: cafe → C-02 view, tankers → A-90, cans → A-92.
```

### G-07 · Switch Operational Role sheet \[TODAY\]

```text
SCREEN G-07 bottom sheet "Switch Operational Role" (Tamil sub-label "பயனர் பங்கு தேர்வு"). Radio rows with icon + description: Admin / Super Admin, Can Delivery Driver, Tanker Driver, Cafe Cashier, Field Agent. Primary "Switch".
```

### G-08 · Notifications center \[NEW\]

```text
SCREEN G-08 Notifications. App bar "Notifications" with "Mark all read". Filter chips: All, Approvals, Stock, Cash, Fleet, System. Grouped list (Today, Yesterday). Row examples: coral "Low stock: 20L Water Can below minimum (12 left)"; honey "Driver R. Muthu cash surrender awaiting verification ₹3,700"; sky "Tanker TMWS-TRIP-2026-002 arrived at The Chennai Silks"; mint "Payment received ₹18,500 from Hotel Saravana Bhavan". Unread rows have a dot. Swipe to dismiss. Empty state "You're all caught up".
```

### G-09 · Offline Sync Outbox \[TODAY\]

```text
SCREEN G-09 "Offline Sync Centre". Hero card: sync pill state (Synced / Syncing / Offline / Error), "Last synced 12 Nov 2026, 10:42:18 AM", count "3 records pending". Primary button "Sync Outbox Now". List of pending items with type icon, title (Can delivery ticket, POS order, Attendance, Expense voucher), captured time and a status pill (Pending, Syncing, Rejected). Rejected rows show "Server rejected sync." with Retry and Discard. Empty state "Outbox is Clean — All local field transactions are synced with the server." Success toast "All offline records successfully synced to ERP server!" Info footer "Records were captured offline and will sync automatically when network connectivity is established."
```

### G-10 · My Profile & Settings \[TODAY\]

```text
SCREEN G-10 "My Profile & Settings" (role-agnostic; show the Admin skin). Top: avatar, name, role pill, phone.
Card "Active Organization": rows Company, Industry, Branch, Financial Year with a "Switch" button (opens G-05; hidden for drivers and cashiers).
Card "Offline Sync Centre": status "Synced", last sync time, button "Sync Outbox Now" (→ G-09).
Card "Preferences": row "Company & Workspace Directory" (→ G-06, admin only), "Theme Appearance" Light | Dark segmented, "App Language" EN | தமிழ் segmented, "Notifications" (→ G-14), "Printer Setup" (→ G-13), "Change Password" (→ G-12).
Footer: "ZOLO ERP Mobile v1.0.0+1 (Build 2026.11)" and full-width outlined danger button "Sign Out of Account".
```

### G-11 · Sign-out confirm \[TODAY\]

```text
SCREEN G-11 centered dialog "Confirm Sign Out", body "Are you sure you want to end your current ERP session?", buttons Cancel and danger "Sign Out". Mention "2 records still pending sync" warning chip when the outbox is not empty.
```

### G-12 · Change password \[NEW\]

```text
SCREEN G-12 Change Password. Fields: Current password, New password (strength meter bar + rules checklist: 8+ characters, number, symbol), Confirm new password. Primary "Update Password". Success toast then back to G-10.
```

### G-13 · Printer setup \[NEW\]

```text
SCREEN G-13 Printer Setup for 58mm thermal printers. Hero card shows connected printer "RP58-BT · Connected" with battery. List of nearby Bluetooth printers with Connect buttons. Settings rows: Paper width 58mm | 80mm segmented, Auto-print after sale toggle, Print copies stepper, Show FSSAI and GSTIN on slip toggle. Button "Print Test Slip".
```

### G-14 · Notification preferences \[NEW\]

```text
SCREEN G-14 Notification Settings. Toggle rows with descriptions: Low stock alerts, Cash surrender awaiting verification, Fleet geofence and idle alerts, Payment received, Approvals, Daily closing reminder (time picker 9:30 PM).
```

### G-15 · Permission prompts \[TODAY\]

```text
SCREEN G-15 three permission cards in one frame: Location ("Location services are disabled on device" with Open Settings), Location permission denied ("Location permissions denied" with Allow), Permanently denied ("Location permissions permanently denied" with Open App Settings); plus Camera permission for receipt capture and Notification permission. Each card: duotone icon, one-line reason, primary + secondary button.
```

### G-16 · Session expired \[NEW\]

```text
SCREEN G-16 full-screen message "Session expired" with lock icon, body "Please sign in again. Offline records are safe and will sync after sign in.", button "Sign In".
```

### G-17 · State kit \[TODAY\]

```text
SCREEN G-17 design sheet showing reusable states in one frame: skeleton list rows; empty state (duotone line art + title + helper + action); error state "An error occurred" with Retry; offline banner "Offline mode. Scheduled manifest active."; success toast; destructive confirm dialog; pull-to-refresh indicator.
```

### G-18 · Barcode scanner \[TODAY\]

```text
SCREEN G-18 full-screen camera scanner. Rounded scan window with corner brackets and a moving scan line, flash toggle, "Enter code manually" button, detected-item card sliding up from the bottom (name, SKU CAN-20L-WAT, system stock) with "Use this item".
```

### G-19 · Capture Customer Location \[TODAY\]

```text
SCREEN G-19 "Capture Customer Location" full-height sheet. Multiline field with hint "Paste WhatsApp message, Google Maps link, or \"11.0845, 77.2941\"..."; button "Paste from clipboard"; helper "Paste a WhatsApp location link (e.g. maps.google.com/?q=...)". Success state: mint card "VALID GPS COORDINATES IDENTIFIED" with monospace coordinates and chip "✓ Location recognized from WhatsApp / Google Maps", mini map, button "Test Navigation in Google Maps". Alternative: outlined button "Capture My Current GPS Location Here" (states: "Reading GPS Sensor…", "Detecting current GPS location...", "✓ Live phone GPS captured successfully", error "GPS capture unavailable. Please paste WhatsApp link."). Primary pinned button "Save & Lock Location for Re-Orders". Error text "Please enter or paste a valid WhatsApp / Google Maps location link." and "Failed to save location."
```

### G-20 · Receipt camera capture \[TODAY\]

```text
SCREEN G-20 receipt capture. Camera viewfinder with document frame, shutter button, gallery button. After capture: preview with stamp chips "GPS 11.3410, 77.7172" and "12 Nov 2026, 09:34:12 AM", buttons Retake and Use Photo.
```

## 6. Admin home and work queue (A)

### A-01 · Admin Home (Executive Dashboard) \[TODAY\]

```text
SCREEN A-01 Admin Home, Lagoon skin. Top bar: company chip "Aran Cafe (Main Branch)" with chevron, sync pill, bell with count, avatar. Greeting "Good morning, Nandhu" and date.
Hero card (lagoon, lime numerals): "Cash in Hand — Liquid Main Cash" large amount, with a mini sparkline and delta chip. Under it a 2×2 bento: "Bank Balances — Active Bank & UPI", "Customer Receivables — Customer Dues", "Supplier Payables — Supplier Dues", and "Journal postings — Direct journal entries posted to ledger" (count).
Sales Performance card: segmented Today | 7D | 30D, smooth line chart with gradient-free fill, tooltip, total and invoice count.
Live fleet strip (if company has vehicles): horizontal cards with vehicle name, "LIVE SPEED" km/h, "STATUS" pill, button "Track / Nav".
Attention row: chips Low stock (3), Pending approvals (2), Cash surrender to verify (1).
Quick tiles (2 columns): Sales Billing, Physical Stock Count, plus industry tiles (see A-02).
States: skeleton; error with Retry.
Floating nav: Home (active) · Trade · (+) · Money · More.
TAP → hero → A-60; Bank → A-60 Bank tab; Receivables → A-50; Payables → A-24; Sales card → A-70; bell → G-08; company chip → G-05; (+) → A-04; attention chips → A-05 / A-30 / A-66.
```

### A-02 · Admin Home industry variants \[TODAY\]

Generate as four prompts, each reusing A-01 with a different tile set.

```text
SCREEN A-02a Admin Home, Cafe company (Aran Cafe). Same layout as A-01. Industry tiles: "Aran Cafe POS Terminal", "Kitchen & Recipe Inventory", "Cafe Expenses & Kitchen Purchases", plus Sales Billing and Physical Stock Count. Add a small "Today at the counter" card: orders billed, UPI vs cash split bar, drawer float ₹5,000.
TAP → POS terminal → C-02; Kitchen → C-30; Expenses → A-63.
```

```text
SCREEN A-02b Admin Home, Bulk Water company (TMWS). Tiles: "Tanker Driver Active Trip Dashboard", "Live Tanker GPS Fleet Telematics", "Bulk Tanker Fleet Operations", "Trip Payment Collection", "Diesel & Vehicle Maintenance". Add card "Today's dispatch": KL decanted, trips done, bulk revenue.
TAP → trip dashboard → T-01; telematics → A-80; fleet operations → A-90; payment collection → A-16; diesel → A-63.
```

```text
SCREEN A-02c Admin Home, Packaged Water company (DK Waters). Tiles: "Can Delivery Driver Manifest & Stops", "Live Tata Ace Beat GPS Radar", "20L Can Distribution Beat", "Spot Empty Can Audit", "Driver Cash & Jar Surrender", "RO Plant Refill Manifest". Add card with "Delivered Today" and "Cans in Market" numerals and "2 BEATS ACTIVE" pill.
TAP → manifest → D-01; radar → A-80; beat → A-92; spot audit → A-95; surrender → A-66; plant refill → A-94.
```

```text
SCREEN A-02d Admin Home, Textile company. Tiles: "Wholesale Tax Invoicing", "Fabric Roll & Yarn Stock Audit", "Commercial Debtor Collection", Sales Billing, Physical Stock Count. Add card "Dispatch today": challans issued, e-way bills pending, rolls in yard.
TAP → invoicing → A-12; stock audit → A-100; debtor collection → A-16; challans → A-98; e-way → A-99.
```

### A-03 · Tasks and work queue \[TODAY\]

```text
SCREEN A-03 "My Work & Task Queue". Segmented control: Daily Queue | Approvals | Outbox. Daily Queue shows grouped task cards by company type with action buttons: (cafe) "Aran Cafe Touch POS Counter — Ready for table & counter billing" [Open POS]; "Kitchen & Ingredient Stock Audit — Verify milk, sugar, flour & coffee beans" [Audit]; "Daily Cafe Operational Expenses — Record dairy, gas, veggies & vendor payments" [Record]; (tankers) "Live Tanker GPS Fleet Radar — Track active water tankers, speed & decanting flow" [Radar]; "Tanker Trip Sheet Dispatch — Log start/end odometer, motor pumping & waiting surcharges" [Dispatch]; "Diesel & Vehicle Expenses — Capture pump slips, driver batta & maintenance bills" [Log Fuel]; (cans) "Beat Deliveries" stops with Customer, Route Beat, [Deliver]. Group headers: Cafe Operations, Tanker Dispatches, Beat Deliveries. Approvals tab: list or empty state "No Pending Approvals — All commercial vouchers and documents are up to date." Outbox tab: embed G-09. Empty queue: "No Pending Queue Items — All operations and vouchers for this company workspace are settled." Button "Sync Outbox Now" in the app bar.
TAP → Approvals row → A-05; Outbox → G-09; each action button → its module screen.
```

### A-04 · Quick Actions sheet \[TODAY\]

```text
SCREEN A-04 bottom sheet "Quick Actions (+ New)". 2-column grid of big tiles with icon, title and subtitle. Admin set: New Sale Bill (B2B/B2C invoice), Collect Payment (Invoice settlement), Quick Expense (Fuel & tolls), New Customer (Party registration), New Product (Item configuration), Stock Count (Godown audit), Mark Attendance (Geofenced punch), Can Driver Manifest (Driver route & 60 cans load), Tanker Driver Desk (Trip decanting & valve status), Tanker Trip (Dispatch & surcharge), Can Sales POS (Water distribution), Cafe POS (Order billing). Show only tiles relevant to the active company, with a search field on top.
TAP → each tile to its screen (A-12, A-16, A-63, A-53, A-41, A-32, A-75, D-01, T-01, T-02, D-03, C-02).
```

### A-05 · Approval detail \[NEW\]

```text
SCREEN A-05 Approval detail. Header chip with document type (Purchase Bill, Expense Voucher, Driver Settlement, Stock Adjustment), number, requester avatar and time. Hero card with amount and party. Sections: line items, attachments (receipt photo with GPS stamp), history timeline. Pinned buttons: outlined danger "Reject" (opens reason sheet) and primary "Approve & Post". Success toast "Approved and posted to ledger".
```

## 7. Admin: Trade (Sales, Quotes, Collections)

Bottom nav tab **Trade** opens A-10 with a segmented control **Sales | Purchases | Quotes** at the top.

### A-10 · Sales Invoices list \[TODAY\]

```text
SCREEN A-10 "Sales Invoices" (Trade tab, segment Sales). Top: segmented control Sales | Purchases | Quotes. Search pill. Filter chips: All, Paid, Due, Credit, Today. Summary strip with 3 numerals: Billed, Collected, Due. List rows: leading tonal circle with receipt icon, customer name ("Walk-in Customer" when blank), invoice no (e.g. INV-2026-0412), date and time, amount, status pill "Paid" (mint) or "Due" (honey) with due amount. Extended FAB "New Bill".
STATES: skeleton; empty "No Sales Invoices — No commercial sales invoices recorded yet for this company."; error "Failed to load invoices" / "An error occurred" with Retry.
TAP → row → A-11; New Bill → A-12; Purchases segment → A-20; Quotes segment → A-14.
```

### A-11 · Invoice detail \[NEW\]

```text
SCREEN A-11 Invoice detail. Hero card: invoice number, customer, date, grand total, status pill. Tabs inside: Items | Payments | Activity. Items: line rows (item, qty, rate, tax, amount) then totals block (Subtotal, Tax, Discount, Grand Total, Paid, Balance Due). Payments: timeline of receipts (Cash / UPI / Cheque with reference). Bottom action bar: "Collect Payment" (primary), icon buttons Print, Share on WhatsApp, PDF, overflow menu (Duplicate, Return, Cancel).
TAP → Collect Payment → A-16; Return → A-18; Print → G-13.
```

### A-12 · New Sale Bill \[TODAY\]

```text
SCREEN A-12 "Create Sale Bill". Sticky total chip at top.
Section "Customer Name / Account": search field (hint "Search or enter customer name"), default chip "Walk-in Retail Customer", link "+ New customer".
Section "Item Details": item cards in a cart. Each card: item selector ("Standard Commercial Item" / "Standard Product"), "Quantity (Cans)" stepper, "Unit Price" money field, line subtotal. Buttons "Add item" and "Scan barcode".
Summary card: "Subtotal", optional discount and tax rows.
Section "Payment Mode": three large selectable tiles Cash, UPI, Credit.
Bottom pinned bar: "Total Payable" numeral and primary button "Save & Issue Bill".
FEEDBACK: success toast "Sale bill created and posted to general ledger!"; offline toast "Saved offline to Outbox! Will sync automatically."
TAP → Scan → G-18; New customer → A-53; Save → A-13.
```

### A-13 · Bill issued \[NEW\]

```text
SCREEN A-13 success screen. Large mint check with confetti-free ripple animation, "Bill issued", invoice number, amount. Cards: payment status, customer. Buttons: primary "Print Slip", "Share on WhatsApp", text "New Bill", text "View Invoice".
TAP → View Invoice → A-11; New Bill → A-12.
```

### A-14 · Quotations list \[NEW\]

```text
SCREEN A-14 "Quotations" (Trade tab, segment Quotes). Filter chips Draft, Sent, Accepted, Expired. Rows: party, quote no, validity date, amount, status pill. FAB "New Quote".
TAP → row → A-15 (view mode); New Quote → A-15.
```

### A-15 · New Quotation / convert \[NEW\]

```text
SCREEN A-15 "New Quotation". Party picker, valid-until date, item cart (same card as A-12), terms text area, totals. Pinned actions: "Save Draft", primary "Send on WhatsApp". In view mode add button "Convert to Invoice" (→ A-12 prefilled).
```

### A-16 · Collect Customer Payment \[TODAY\]

```text
SCREEN A-16 "Collect Customer Payment". Section "Party / Customer": search field (hint "Customer name or account"). After selection show card "Current Outstanding Due:" with large coral amount and aging chips (0-15d, 16-30d, 30d+). Section "Collected Amount (₹)": big money field with quick chips (Full due, Half, Custom) and inline pad. Section "Payment Method": segmented tiles Cash, UPI, Cheque (cheque reveals cheque number and date). Field "Payment Receipt Memo / Reference" (hint "e.g. UPI Ref / Cheque No / Cash memo"). Allocation preview: which invoices will be settled. Pinned primary "Post Receipt & Update Balance".
FEEDBACK: error "Please enter a valid collection amount"; success "Payment collection posted to ledger accounts!"; offline "Collection saved offline to Outbox! Will sync automatically."
TAP → Post → A-17.
```

### A-17 · Receipt posted \[NEW\]

```text
SCREEN A-17 receipt success. Mint check, "₹18,500 received", party, method, reference, new balance due. Buttons "Print Receipt", "Share on WhatsApp", "Done".
```

### A-18 · Sales return / credit note \[NEW\]

```text
SCREEN A-18 "Sales Return". Select invoice, tick items and return quantities (steppers), reason chips (Damaged, Wrong item, Customer return, Empty jar return), refund mode Cash / Credit note / Adjust to due. Summary of credit amount. Primary "Post Credit Note".
```

## 8. Admin: Purchases and Suppliers

### A-20 · Purchase Bills & GRN list \[TODAY\]

```text
SCREEN A-20 "Purchase Bills & GRN" (Trade tab, segment Purchases). Search pill, filter chips All, Payable Due, Settled, This month. Summary strip: Billed, Paid, Payable. Rows: supplier name, bill no, date, amount, pill "Settled" (mint) or "Payable Due" (honey). FAB "New Purchase".
STATES: empty "No Purchase Bills — No inward procurement bills recorded for this company yet."; error "Failed to load purchase bills".
TAP → row → A-21; FAB → A-22.
```

### A-21 · Purchase bill detail \[NEW\]

```text
SCREEN A-21 Purchase bill detail. Hero: supplier, bill no, total, status. Tabs: Items | GRN | Payments. GRN tab shows received vs billed quantities with variance chips. Bottom actions: "Pay Supplier" (primary), "Receive Goods", Share.
TAP → Pay Supplier → A-23; Receive Goods → A-22 (GRN mode).
```

### A-22 · New Purchase Bill / GRN \[NEW\]

```text
SCREEN A-22 "New Purchase Bill". Supplier picker, supplier bill no and date, godown picker, item cart (item, qty, cost, tax, batch no and expiry for batch-tracked items), attach photo of supplier bill, totals. Segmented mode: Bill | GRN only. Pinned "Save & Post".
```

### A-23 · Supplier Payment \[NEW\]

```text
SCREEN A-23 "Supplier Payment" (disbursement from cash or bank). Supplier picker with payable balance card, amount field, "Pay from" segmented Cash (1010) | Bank (1020) | UPI, reference field, bills-to-settle checklist. Primary "Post Payment".
```

### A-24 · Suppliers Directory \[NEW\]

```text
SCREEN A-24 "Suppliers" (the current app links here but has no screen). Search pill, chips All, Payable Due, Top suppliers. Rows: initials avatar, supplier name, city, GSTIN tail, payable amount in coral. FAB "Add Supplier". Summary: total payable.
TAP → row → A-25; FAB → A-26.
```

### A-25 · Supplier detail and payable statement \[NEW\]

```text
SCREEN A-25 Supplier detail. Hero: name, phone call button, GSTIN, payable balance. Quick buttons Call, WhatsApp, Pay. Tabs: Bills | Payments | Statement. Statement is a ledger list with running balance and a date-range chip; "Export PDF".
```

### A-26 · Add Supplier \[NEW\]

```text
SCREEN A-26 "Add Supplier". Fields: Supplier name*, Contact person, Phone*, WhatsApp, GSTIN (33AAAAA0000A1Z5), Address, City, Opening payable balance, Payment terms chips (Cash, 15 days, 30 days). Primary "Save Supplier".
```

## 9. Admin: Inventory and Godowns

### A-30 · Inventory & Stock (Stock Valuation) \[TODAY\]

```text
SCREEN A-30 "Inventory & Stock". Hero: "Current Stock Valuation" numeral with godown picker chip (All godowns / Main Godown / Plant). Chips: All, Low Stock, Out of stock, Expiring. Search pill. Item rows: thumbnail tile, name, SKU, quantity with unit ("Pcs"), value, red "Low Stock" pill when below minimum. Buttons: "Stock Count" (app bar action), "Transfer".
STATES: empty "No Inventory Items — No stock or product items found in this warehouse."; error "Failed to load inventory".
TAP → row → A-31; Stock Count → A-32; Transfer → A-34.
```

### A-31 · Item stock detail \[NEW\]

```text
SCREEN A-31 Item stock detail. Hero: item, on-hand quantity, value, minimum alert. Sections: stock by godown (bar rows), batches with expiry dates and countdown pills, recent movements timeline (Sale, Purchase, Transfer, Adjustment). Actions: Adjust, Transfer, Count.
```

### A-32 · Physical Stock Count \[TODAY\]

```text
SCREEN A-32 "Physical Stock Count", subtitle "Physical warehouse stock count". Field "Item Barcode / SKU" with hint "Scan or type SKU code" and scan button (→ G-18); sample value CAN-20L-WAT. Card "Audit Reconciliation": three rows "System Expected Stock", "Physical Counted Stock" (big stepper / numeric entry), "Variance (Discrepancy)" which shows "0 (Exact Match)" in mint or a signed number in coral/honey. Optional note field. Pinned primary "Confirm & Submit Count".
FEEDBACK: success "Stock count submitted and inventory verified!"; offline "Saved offline to Outbox! Will sync when connected."
TAP → Submit → A-33.
```

### A-33 · Count review \[NEW\]

```text
SCREEN A-33 count session summary: items counted, matched, short, excess, total variance value. List of counted items with variance chips. Buttons "Post Adjustments" (needs approval) and "Continue Counting".
```

### A-34 · Stock transfer between godowns \[NEW\]

```text
SCREEN A-34 "Stock Transfer". From godown and To godown pickers with swap button, item cart with quantities and available stock shown, transfer note. Primary "Create Transfer". Receive screen variant lists in-transit transfers with "Confirm Receipt".
```

### A-35 · Stock adjustment \[NEW\]

```text
SCREEN A-35 "Stock Adjustment". Item, godown, current quantity, new quantity or +/- delta, reason chips (Damage, Spillage, Expiry, Correction, Gift), photo attachment. Primary "Submit for Approval".
```

## 10. Admin: Product Catalog and Configuration

### A-40 · Product Catalog & Config \[TODAY\]

```text
SCREEN A-40 "Product Catalog & Config". Search pill "Search product by name, SKU or barcode...". Chips: All, Water, Bakery, Fabric, Services. App bar actions: "Refresh Catalog", "Add New Product". Product cards: image tile, name, "SKU" code, price, badges "STANDARD", "VARIANTS", "BATCH EXPIRY", green "FULL CONFIG READY", and a small button "Configure". FAB "New Product".
STATES: empty "No Products Found — No items match your search. Tap + to configure a new product."
TAP → card → A-46; Configure → A-41 (edit mode); FAB → A-41 (new).
```

### A-41 · Product form, tab 1 General \[TODAY\]

```text
SCREEN A-41 "New Product Configuration" (title becomes "Edit Product Details" in edit mode). Top: 5-step tab strip General | Pricing & Tax | Stock & Godown | Variants | Verticals & Adv (General active) with a progress bar.
Card "Primary Identification": "Product Name *" (hint "e.g. 20L Water Can, Croissant, Fabric Roll", error "Product name is required"), "Print Name (Receipt/Bill)" (hint "Optional alias printed on POS vouchers"), "Product Code / SKU *" (hint "e.g. WTR-20L", error "Product code is required") with button "Auto Generate SKU".
Card "Classification & Standards": dropdowns "Product Type *", "Barcode Symbology *" (UPCA, UPCE, EAN8, EAN13, Code 128), "Category *", "Brand (Optional)" (default "No Brand"), "Base Unit *"; "Tags / Keywords" chip input (hint "comma-separated tags for fast search"); "Product Details / Specification" text area (hint "Public or internal notes about this SKU").
Footer: "Cancel" and primary "Create Product" ("Save Changes" when editing, "Saving..." while busy).
ERRORS: "Please correct the validation errors in the form.", "Could not load configuration catalogs.", "Failed to load configuration metadata." with Retry.
TAP → next tab → A-42.
```

### A-42 · Product form, tab 2 Pricing & Tax \[TODAY\]

```text
SCREEN A-42 same shell as A-41 with Pricing & Tax active.
Card "Cost & Margin Calculation": "Purchase / Production Cost (₹) *" (error "Cost is required"), "Profit Margin *" with "Margin Mode" segmented "% Percent" | "₹ Fixed", "Retail Selling Price / MRP (₹) *" (helper "Auto-computes from Cost + Margin or manually override", error "Price is required"), "Wholesale / Corporate Price (₹)". Live margin preview chip.
Card "Taxation & Fiscal Settings": "Tax Rate" dropdown (default "No Tax (0%)"), "Tax Calculation Method" segmented "Exclusive (Tax added on top of Price)" | "Inclusive (Tax included inside Price)", "Daily Sales Objective / Target (Units)" (hint "Target volume per day").
Card "Promotional Pricing": switch "Enable Promotional Price" (helper "Temporarily offer discounted rate for campaigns"), then "Promotional Price (₹)", "Start Date", "End Date" (dd MMM yyyy date pickers).
```

### A-43 · Product form, tab 3 Stock & Godown \[TODAY\]

```text
SCREEN A-43 same shell, Stock & Godown active.
Card "Stock Balances & Thresholds": "Initial Opening Stock", "Godown / Warehouse" dropdown, "Minimum Alert Quantity" (helper "Triggers low stock warnings on executive dashboard"), switch "In Stock Availability" (helper "Turn off if temporarily unavailable or seasonal"), switch "Track Inventory Balances" (helper "Automatically deduct upon sale and add on purchase").
Card "Tracking Features": switch "Batch & Expiry Tracking" (helper "Enables batch numbers, manufacturing & expiry dates"), switch "IMEI / Serial Number Tracking" (helper "Enables tracking unique devices/equipment serial numbers"), switch "Different Price by Warehouse" (helper "Maintain independent pricing matrices across godowns").
```

### A-44 · Product form, tab 4 Variants \[TODAY\]

```text
SCREEN A-44 same shell, Variants active. Switch "This Product has Multiple Variants" (helper "e.g. Size, Color, Liters, Flavour"). When on: field "Option Attribute Name" (hint "e.g. Size, Volume, Weight"), field "Add Value" (hint "e.g. 20L, 500ml, 1KG, Large") with button "Add", added values as removable chips, and a generated variant matrix list (each combination with its own SKU, price, stock fields). Off state: empty card explaining variants.
```

### A-45 · Product form, tab 5 Verticals & Adv \[TODAY\]

```text
SCREEN A-45 same shell, Verticals & Adv active.
Card "Water Logistics Specifics": "20L Jar / Can Deposit Amount (₹)" (helper "Refundable security deposit charged on new customer KYC"), "Nominal Volume Capacity (Liters)" (helper "Used for bulk water tanker and bottle line balance").
Card "Bakery, Kitchen & Restaurant POS": "Kitchen Display / Station ID" (hint "e.g. Oven Station, Tea Counter, Packaging Unit"), "Menu Type" dropdown (Regular Menu, Breakfast Only, Evening Snacks / Tea, Weekend Special), switch "Is Topping / Extra Item" (helper "Item can be attached as add-on to main bakery items").
Card "Digital & Online Capabilities": switch "Featured Product" (helper "Prioritized at top of mobile POS and billing machines"), switch "Available for Online POS / Delivery" (helper "Enables catalog inclusion for field drivers and web store").
Card "Warranty & Guarantee": "Warranty Period" (hint "e.g. 1 Year, 6 Months"), "Guarantee Period" (hint "e.g. 30 Days Replacement").
Footer: Cancel, primary "Create Product".
TAP → Create → A-40 with success toast "Product created and cataloged." (edit: "Product updated successfully."); failure toasts "Failed to save product." / "Network error saving product configuration."
```

### A-46 · Product detail \[NEW\]

```text
SCREEN A-46 Product detail (read view). Hero: image tile, name, SKU, barcode image, price, stock. Bento tiles: Cost, Margin, Tax, Min stock. Sections: Variants list, Stock by godown, Price history, Sales last 30 days sparkline. Actions: Edit (→ A-41), Print Barcode Label, Deactivate.
```

## 11. Admin: Customers and Parties

### A-50 · Customers 360 directory \[TODAY\]

```text
SCREEN A-50 "Customers Directory" (More tab → Parties). App bar: title, "Refresh", "Add Customer". Pill "LIVE ERP SYNC" (Tamil sub-label நேரடி ERP தரவு). Search pill "Search by customer, shop, phone, city...". Filter chips: All, Has dues, Cans held, No GPS, and one chip per route (Route 1, Route 2, Bulk Tanker Route).
Customer rows (cards): initials avatar, customer name, shop name, phone, city, credit balance (coral if due), cans held, security deposit, route chip, GPS pill "GPS Pin Set" (mint) or "No GPS" (honey). Row actions: Call, "Navigate with Google Maps", "Capture WhatsApp GPS" (→ G-19). Extended FAB "+ Add Customer".
STATES: empty "No customers found — Tap \"+ Add Customer\" below to onboard the first customer."; error "Failed to load customers directory." with Retry.
TAP → row → A-51; FAB → A-53; Capture → G-19.
```

### A-51 · Customer 360 detail \[NEW\]

```text
SCREEN A-51 Customer 360. Hero card: name, shop, route chip, GPS mini-map thumbnail. Four numerals: Outstanding Due, Cans Held, Security Deposit, Lifetime Value. Quick buttons Collect, New Bill, Call, WhatsApp, Navigate. Tabs: Orders | Ledger | Cans | KYC & Notes. KYC card: GSTIN, address, contact person, documents. Cans tab: timeline of delivered/returned cans with running balance.
TAP → Collect → A-16; New Bill → A-12; Ledger → A-52.
```

### A-52 · Customer ledger statement \[NEW\]

```text
SCREEN A-52 Customer ledger. Date-range chip, opening balance, list of entries (Invoice, Receipt, Credit note, Can deposit) with debit / credit columns and running balance, closing balance card. Buttons "Share on WhatsApp", "Export PDF".
```

### A-53 · Onboard Customer, step 1 Identity \[TODAY\]

```text
SCREEN A-53 "Onboard New Customer", 3-step progress header (Identity → Address & GPS → Route & Cans). Section "1. Customer & Shop Identity": "Customer / Shop Name *" (hint "e.g. Sri Murugan Hotel", error "Please enter customer name"), "Business / Enterprise Legal Name" (hint "e.g. Murugan Hospitality Pvt Ltd"), "Phone Number *" (hint "10-digit mobile", errors "Phone required" / "Invalid phone"), "Contact Person" (hint "Manager / Owner"), checkbox "WhatsApp Number is same as Phone", and when unchecked "WhatsApp Number *". Pinned "Next".
```

### A-54 · Onboard Customer, step 2 Address & GPS \[TODAY\]

```text
SCREEN A-54 same shell, step 2. Section "2. Delivery Address & GPS Location": "Street Address & Landmark *" (hint "e.g. 14, Perundurai Road (Opp. New Bus Stand)", error "Please enter address"), "City / Taluk *" (default Erode), "GSTIN (Optional)" (hint 33AAAAA0000A1Z5). Card "Instant WhatsApp Location Capture": helper "Paste WhatsApp customer shared Google Maps link or location text:", field (hint "e.g. https://maps.google.com/?q=11.341,77.717"), button "Parse Link". Result states: grey chip "No GPS Coordinates Set (Paste WhatsApp Link Above)" or mint card with coordinates and mini map. Link "Capture live GPS instead" (→ G-19). Buttons Back and Next.
```

### A-55 · Onboard Customer, step 3 Route & Cans \[TODAY\]

```text
SCREEN A-55 same shell, step 3. Section "3. Route Beat & Water Inventory": dropdown "Assign Delivery Route Beat *" with options "Route 1 - Anna Nagar & Teppakulam (Tata Ace WA-101)", "Route 2 - KK Nagar & Mattuthavani (Tata Ace WA-102)", "Commercial Bulk Tanker Route (TMWS Tanker Fleet)"; steppers/fields "Initial Cans Held", "Security Deposit (₹)", "Opening Balance Due (₹)". Summary card of everything entered. Primary "Save & Onboard Customer" (busy label "Registering Customer..."). Error toast "Failed to onboard customer."
TAP → Save → A-56.
```

### A-56 · Customer onboarded \[NEW\]

```text
SCREEN A-56 success. Mint check, customer name, route, cans held, deposit. Buttons "Collect Deposit" (→ A-16), "Share Welcome on WhatsApp", "Add Another", "Open Customer" (→ A-51).
```

## 12. Admin: Money, Accounting and Reports

### A-60 · Money hub: Accounting & Cash Books \[TODAY\]

```text
SCREEN A-60 "Accounting & Cash Books" (Money tab). Segmented control "Cash Book (1010)" | "Bank Book (1020)". Hero card: "Current Cash in Hand" (or "Current Bank Balance") big numeral with Today in / Today out chips (mint / coral). Bento row: Receivables, Payables, Cash in Transit. Action chips: Collect, Pay Supplier, Quick Expense, Day Book, Statements, Ledger. Section "Recent Journal Postings": rows titled "Journal Posting" with voucher no, narration, date, signed amount and a Dr/Cr tag.
STATES: empty "No Postings"; error "Failed to load ledger books" / "An error occurred".
TAP → posting row → A-61; Day Book → A-62; Quick Expense → A-63; Ledger → A-64; Statements → A-65; Collect → A-16; Pay Supplier → A-23.
```

### A-61 · Journal posting detail \[NEW\]

```text
SCREEN A-61 Journal detail. Voucher no, date, narration, source document link chip (Invoice, Expense, Settlement). Two-column Debit / Credit table with account names and codes, totals with a mint chip "Debits = Credits". Attachment thumbnails.
```

### A-62 · Day Book \[NEW\]

```text
SCREEN A-62 "Day Book". Date strip (swipeable days), chips All, Sales, Purchases, Receipts, Payments, Expenses. Timeline list of the day's vouchers with time, type icon, party, amount (mint in / coral out). Footer totals: Total In, Total Out, Net. Button "Close Day".
```

### A-63 · Quick Expense Voucher \[TODAY\]

```text
SCREEN A-63 "Quick 20s Expense" (also reached from driver, cafe and agent flows). Giant money field "Expense Amount (₹)" with inline numeric pad. "Expense Category" big chips with icons: Fuel / Diesel, Food & Tea, Toll / Parking, Vehicle Maintenance, Stationary & Printing, Miscellaneous Expense. "Payment Out From": segmented Cash Hand | UPI. Field "Note / Remarks" (hint "e.g. 5L diesel for Tata Ace van"). Row "Attach receipt" with camera button (→ G-20) showing a small GPS + time stamp chip. Pinned primary "Record Expense Voucher".
FEEDBACK: error "Please enter a valid expense amount"; success "Expense recorded and debited from cash account!"; offline "Expense queued offline in Outbox! Will sync automatically."
```

### A-64 · Financials & General Ledger \[TODAY\]

```text
SCREEN A-64 "Financials & General Ledger" with pill "ERP AUDITED" and "Live Sync". Hero "Working Capital & Liquid Assets" numeral. Section "General Ledger Accounts Matrix": tiles Cash in Hand (1010); Operating Bank Account — Current Account (HDFC/ICICI) (1020); Accounts Receivable (AR) — Customer Credit Ledger Outstanding (1030); Cash in Transit (CIT 1015) — Held by Route Delivery Drivers; Jar Security Deposits. Each tile: balance, small trend chip, tap to open the account ledger.
```

### A-65 · Financial statements \[NEW\]

```text
SCREEN A-65 "Statements". Segmented: Trial Balance | Profit & Loss | Balance Sheet. Period chip (This month, FY, Custom). P&L: waterfall chart Revenue → COGS → Gross Margin → Operating Expenses → Net Profit, with margin % chips. Balance Sheet: stacked bars Assets vs Liabilities + Equity with a "Balanced" mint chip. Trial Balance: grouped account list (Assets, Liabilities, Equity, Revenue, Expenses) with Dr/Cr columns and a totals check. Button "Export PDF / Excel".
```

### A-66 · Driver Cash Settlements \[TODAY\]

```text
SCREEN A-66 "Route Dispatch & Fleet Reconciliations" with pill "ADMIN" and "Live Sync" (Tamil sub-label நேரடி ERP). Section "Live Fleet Operations": three tiles "Active Beats", "Tata Ace Fleet Dispatched", "CIT In Transit — Pending Field Cash Settlement". Section "Driver Route Settlements": cards with route beat, "Route Driver" (Kumar (Driver)), vehicle "Tata Ace TN-59-WA", "80 Jars", cash amount and button "Verify & Settle". After settling a toast: "Settlement verified & posted to Main Cash GL 1010: ₹2,625". Empty: "All driver shifts verified and reconciled with General Ledger!"
TAP → Verify & Settle → A-67.
```

### A-67 · Settlement verify sheet \[NEW\]

```text
SCREEN A-67 bottom sheet. Driver, vehicle, beat. Rows: Gross collected, Less route expenses, Net expected, "Cash counted" input, auto Variance chip (mint 0, coral shortage), empties returned vs expected, driver's handover note. Buttons "Flag for Review" and primary "Verify & Post to GL 1010".
```

### A-68 · Chart of accounts \[NEW\]

```text
SCREEN A-68 "Chart of Accounts". Five expandable groups (Assets, Liabilities, Equity, Revenue, Expenses) with child accounts, codes and live balances, search pill. Tap an account opens its ledger.
```

### A-70 · Reports & Statements hub \[TODAY\]

```text
SCREEN A-70 "Reports & Statements". Date-range chips (Today, 7D, 30D, FY). Two hero summary cards: "Sales Performance" with "Total Invoiced Revenue" and "Total Invoices Count" plus a small trend; "Inventory Valuation" with "Current Stock Valuation" and "Tracked SKU Items". Below, a report library list with icons: Sales Report, Purchase Report, Stock Report, Customer Ledger, Receivables Aging, Driver Settlements, Fleet Fuel & Odometer, Attendance, Profit & Loss.
STATES: error "Failed to load report analytics".
TAP → any report → A-71.
```

### A-71 · Report viewer \[NEW\]

```text
SCREEN A-71 report viewer. Filter bar (date range, company/branch, customer or item picker). Summary numerals on top, chart (bar or line), then a compact grouped list. Sticky buttons "Export PDF", "Export Excel", "Share".
```

## 13. Admin: People, Fleet, Industry Operations and More

### A-75 · Attendance & Shift \[TODAY, shared by every role\]

```text
SCREEN A-75 "Attendance & Shift". Hero card with the staff name, role tag "Field Staff", status pill "ON DUTY" (mint) or "OFF DUTY" (grey), shift timer HH:MM:SS. Geofence card: small map with a green work-zone circle and a "You are inside the approved zone" chip, or coral "Outside zone". Selfie capture tile (facial selfie + GPS). One huge pill button: "CHECK IN" (aqua/lagoon) that flips to "CHECK OUT" (coral). Below: today's punches timeline and this week's hours bars.
FEEDBACK: "Checked in successfully!", "Checked out successfully!", offline "Attendance recorded offline! Will sync automatically."
```

### A-76 · Team attendance \[NEW\]

```text
SCREEN A-76 "Team Attendance" (admin). Date strip, summary chips Present / Absent / On leave / Late. List of staff with role, check-in time, selfie thumbnail, location chip (inside / outside zone), and status pill. Tap opens a punch detail sheet with map.
```

### A-77 · Leave request \[NEW\]

```text
SCREEN A-77 "Apply for Leave". Leave type chips (from leave types: Casual, Sick, Earned, Unpaid), date range picker, half-day toggle, reason field, balance card per type. Primary "Submit Request". My Leaves tab lists past requests with status pills.
```

### A-78 · Leave approvals \[NEW\]

```text
SCREEN A-78 "Leave Approvals" (admin). Request cards: staff, type, dates, days count, reason, leave balance. Buttons Reject and Approve. History tab.
```

### A-79 · Users and roles \[NEW\]

```text
SCREEN A-79 "Users & Roles" (admin). Staff list with role pill (Admin, Cashier, Can Driver, Tanker Driver, Field Agent), assigned company and branch, active toggle. FAB "Add User" opens a sheet: name, phone, role, company, branch, temporary password. Row menu: Reset password, Deactivate.
```

### A-80 · Live Fleet GPS & Radar \[TODAY\]

```text
SCREEN A-80 "Live Fleet GPS & Radar Tracking" (Tamil sub-label நேரடி GPS கண்காணிப்பு & ரேடார்). Top status line "12 GPS Satellites Locked · Real-Time LTE" with pill "ACTIVE RADAR". Segmented: Tankers ("TMWS Bulk Tanker Fleet Radar") | Packaged Water ("DK Waters Beat Delivery Fleet Radar").
Full-bleed light map with soft concentric radar rings, label "GRID: 30 KM RADIUS" and zone "Erode-Perundurai Fleet Zone". Geofence circles and pins: TMWS Borewell Hub, DK Waters Plant, Texvalley Mall, Chennai Silks. Vehicle markers with direction arrows and speed bubbles.
Draggable bottom sheet "Fleet Vehicle Live Telemetry": vehicle rows with name, driver, status pill EN ROUTE / AT SITE / IDLE / OFFLINE / AWAITING PING, "ONLINE" dot, "Live Speed", last ping, and a "Track Pin" button.
STATES: empty "No Fleet Vehicles Found — No vehicles are registered or reporting live GPS telematics for this company."; error "Failed to load telematics" / "Network error fetching GPS fleet data."
TAP → vehicle row or marker → A-81; Track Pin recenters the map.
```

### A-81 · Vehicle live detail \[TODAY\]

```text
SCREEN A-81 vehicle sheet, two variants.
TANKER variant: title (e.g. Tata LPT 2518 · 20 KL), status pill, driver, last ping. Bento: "Live Speed", "Fuel Level" gauge, "ECU Battery", "Decanting Flow Sensor Meter" (420 L/min or 0 L/min), "Tank Capacity", "Anti-Siphon" (SECURE mint / OFFLINE grey), "GPS Variance" (0.0% Verified). Chips: "Inside Approved Zone", "Active Dispatch" / "Stationary at Yard".
CAN VAN variant: "Tata Ace Gold (84 Jars Capacity)", Route Driver, Delivery Beat Route name, pill "BEAT ACTIVE" or "STOP UNLOADING", stops progress "completed / total", "Current Stop", "Next Stop ETA: 5 mins", numerals Delivered / Empties / Remaining, chips "Inside Route Perimeter", "Parked at Warehouse".
Buttons: Call driver, "Track Pin", "View trip replay".
TAP → replay → A-82.
```

### A-82 · Trip replay and stoppage timeline \[NEW\]

```text
SCREEN A-82 trip replay. Map with the day's route polyline and numbered stops; scrubber with play/pause and speed chips 1x 4x 8x. Vertical timeline: 08:15 AM - 08:35 AM Main RO Plant (20 min, loading); 09:20 AM Hotel Saravana Bhavan (14 cans, ₹280 cash); an amber warning row "Extended halt 50 min at Highway Tea Stall". Summary: GPS distance 72.4 km, claimed diesel vs GPS efficiency chip "Normal".
```

### A-83 · Anti-fraud radar \[TODAY\]

```text
SCREEN A-83 "Anti-Fraud Real-Time Radar" with pill "ACTIVE 24/7". Description "GPS odometer variance, missing container siphoning, and drawer cash float discrepancies are actively monitored." Three monitor cards (GPS odometer variance, Container siphoning, Drawer float discrepancy) each with status (Clear / Alert) and count. Alert list below with severity dots and "Tap to Launch Inspection →".
```

### A-84 · Group Super Admin console \[TODAY\]

```text
SCREEN A-84 "Group Super Admin" with pill "EXECUTIVE" and caption "Live Cloud API · 3 Consolidated Enterprises". Hero "Consolidated Group Financials (Live API)" with tiles: Gross Group Sales (Across 3 Entities), Cash in Transit (Field Surrenders), Bulk Water Decanted (Tanker Logistics), Packaged Water Cans (Delivered by Ace Fleet). Section "Enterprise Portals & Operations": three portal cards with pills — Tiruchendur Murugan Water Supply (TMWS) "BULK WATER" (Commercial Bulk Water Tankers & Heavy Lorries); DK Waters — Packaged Drinking Water "PACKAGED WATER" (Tata Ace Beat Routes & Container Return Custody); Aran Cafe & Bakery Express "CAFE & POS" (Express Touch POS Counter & Shift Cash Drawer). Below: anti-fraud card (A-83).
TAP → TMWS → A-90; DK Waters → A-92; Aran Cafe → A-02a.
```

### A-90 · Bulk Tanker operations (TMWS) \[TODAY\]

```text
SCREEN A-90 "TMWS Bulk Logistics" — "Tiruchendur Murugan Water Supply · Commercial Bulk Fleet & Decanting Operations". Two numerals: Water Decanted (Today) and Bulk Revenue. Live GPS tile "Live Tanker GPS Fleet Tracking" with pill "3 ONLINE" and button "Open Live GPS Radar Map" (→ A-80). Buttons "New Trip Sheet" (→ T-02) and "Spot Audit" (→ A-95). List "Recent Tanker Trip Sheets": TMWS-TRIP-2026-002 rows with customer, KL decanted, amount, status.
TAP → row → A-91.
```

### A-91 · Tanker trip detail \[NEW\]

```text
SCREEN A-91 Trip detail. Header trip no, tanker, driver, customer site. Route mini-map with GPS distance vs odometer chips, halts and motor pumping minutes, bill breakdown (Base Water Freight, Motor Pumping Surcharge, Site Waiting Surcharge, Toll, Total Trip Amount), gate pass / receiver signature photo, invoice link. Buttons "Print Trip Sheet", "Collect Payment".
```

### A-92 · DK Waters Distribution \[TODAY\]

```text
SCREEN A-92 "DK Waters Distribution" with tag "20L JARS" and subtitle "Tata Ace Beat Routes & Container Return Custody". Numerals "Delivered Today" and "Cans in Market". Tile "Live Tata Ace Beat GPS Delivery" with "2 BEATS ACTIVE" and button "Open Delivery Beat GPS Radar". Action tiles: "Can Sales POS (Sell Cans)", "Plant Refill", "Customer Cans", "Delivery Slips". List "Active Tata Ace Beat Routes" with vehicle, driver and pill "ON ROUTE". List "Recent Delivery Slips" with DKW-DEL numbers.
TAP → Can Sales → D-03; Plant Refill → A-94; Customer Cans → A-93; Delivery Slips → A-96; Radar → A-80.
```

### A-93 · Can custody ledger \[NEW\]

```text
SCREEN A-93 "Customer Cans". Hero: Cans in Market total and deposits held. Filter chips All, Overdue empties, High balance, By route. Rows: customer, cans held, deposit, last delivery, empties due badge. Row actions: Spot Audit, Request Empties, Open Customer.
```

### A-94 · Plant refill log \[TODAY\]

```text
SCREEN A-94 "Plant Refill Manifests" (admin view). Date strip, list of van loads grouped by vehicle: Load #1 72, Load #2 84, Load #3 57 with cumulative total; each load shows empties handed over, full sealed cans loaded, damaged / leakage jars, slip photo and time. Variance chip if loaded exceeds empties handed.
```

### A-95 · Spot audit log \[TODAY\]

```text
SCREEN A-95 "Spot Can Audits". List of audits: customer, driver, system jars vs physical jars, difference chip (Exact Match mint, shortage coral, excess honey), supervisor remarks, time. Filter chips Mismatches, Today, By driver.
```

### A-96 · Delivery slips list \[TODAY\]

```text
SCREEN A-96 "Sales Invoices & Slips" with pill "LIVE DISPATCH SLIPS". Slip cards: slip no (DKW-DEL-...), customer ("Unknown Customer" fallback), "Cans Delivered", "Empties Collected", "Payment Mode", "Grand Total". Empty state "No invoices generated yet".
```

### A-97 · Textile wholesale invoice \[TODAY\]

```text
SCREEN A-97 "Wholesale Tax Invoicing" for fabric. Same cart pattern as A-12 but item cards have Roll no, Meters, Shade, Rate per meter, and HSN with GST %. Buyer GSTIN field, transport and LR number fields. Pinned "Issue Tax Invoice". Adds toggle "Generate E-Way Bill" (→ A-99).
```

### A-98 · Delivery challan and GRN \[NEW\]

```text
SCREEN A-98 "Delivery Challan & GRN". Segmented Challan | GRN. Party, vehicle no, roll list with meters and quality grade chips, total meters. Pinned "Issue Challan" / "Post GRN". Share as PDF.
```

### A-99 · E-way bill \[NEW\]

```text
SCREEN A-99 "GST E-Way Bill". Select invoice, auto-filled supplier and buyer GSTIN, value, HSN, distance, vehicle number, transporter. Status timeline Draft → Generated → In transit. Buttons "Generate E-Way Bill", Share, Print.
```

### A-100 · Fabric roll and yarn stock audit \[TODAY\]

```text
SCREEN A-100 "Fabric Roll & Yarn Stock Audit" (physical meter roll and yarn weight audits). Scan roll barcode, expected meters / kg vs counted meters / kg, variance chip, list of audited rolls. Primary "Submit Audit".
```

### A-101 · Recipes (Manufacturing) \[NEW\]

```text
SCREEN A-101 "Recipes". List of recipes (e.g. Butter Croissant, Milk Bun, Filter Coffee base) with yield, cost per unit and ingredient count. Recipe detail: ingredient rows with quantity and unit, wastage %, cost breakdown donut, "Produce" button.
```

### A-102 · Production run \[NEW\]

```text
SCREEN A-102 "New Production". Pick recipe, target quantity stepper, auto-calculated ingredient needs with available stock (red when short), kitchen station chip (Oven Station), start / finish times. Primary "Start Production" then "Complete & Add to Stock".
```

### A-110 · More: All Modules \[TODAY\]

```text
SCREEN A-110 "All Modules" (More tab). Search pill at the top. Categories in order, each with a header and a 2-column grid of module tiles (icon in tonal circle, title, one-line description):
- Sales & Commercial: Sales Invoices (B2B/B2C billing, tax invoice & payment history), Quotations (Commercial quotes & price estimates), Customer Payments (Receipt allocation against outstanding dues).
- Procurement & Purchases: Purchase Bills (Inward vendor bills & payable dues), Supplier Payments (Disbursements from cash/bank accounts).
- Inventory & Godowns: Product Catalog & Config (Item master, barcode symbology, pricing & vertical setup), New Product Configuration (Tabbed master configuration for standard, combo & services), Stock Valuation (Real-time stock valuation by warehouse), Physical Stock Count (Barcode scanning and godown variance audits).
- Customers & Suppliers (Parties): Customers 360 (Customer list, credit balance, can deposits & KYC), Suppliers Directory (Vendor contacts, GSTIN & payable statements).
- Accounting & Cash Books: Day Book & Cash Book (Cash-in-hand 1010 & Bank 1020 ledger movements), Quick Expense Voucher (Instant receipt capture with camera & GPS stamp).
- Industry category (changes with company): Cafe — Bakery & Cafe POS, Kitchen & Recipe Inventory, Cafe Expenses & Purchases. Bulk Water — Tanker Driver Active Dashboard, Live Tanker GPS Fleet Radar, Tanker Trip Sheet, Trip Payment Collection, Diesel & Vehicle Maintenance. Packaged Water — Can Delivery Driver Dashboard, Tata Ace Beat GPS Radar, Can Sales POS Ticket, Spot Empty Can Audit, Driver Cash Surrender, RO Plant Refill Manifest. Textile — Wholesale Tax Invoicing, Fabric Roll & Yarn Stock Audit, Commercial Debtor Collection.
- HRM & Attendance: Geofenced Attendance (Facial selfie & GPS check-in / check-out), plus Leaves and Users & Roles.
- Analytics & Reports: Financial & Sales Reports (Sales summaries, stock aging & customer ledgers), Statements.
Empty search: "No modules match your search".
TAP → each tile to its screen: A-10, A-14, A-16, A-20, A-23, A-40, A-41, A-30, A-32, A-50, A-24, A-60, A-63, then industry tiles (C-02, C-30, A-63 | T-01, A-80, T-02, A-16, A-63 | D-01, A-80, D-03, D-07, D-08, D-02 | A-97, A-100, A-16), A-75, A-77, A-79, A-70, A-65.
```

## 14. Can Delivery Driver (D), Aqua Day skin

Driver rules for every D and T screen: Aqua Day skin, 56px minimum taps, one sun-yellow action slab per screen, English labels with a small Tamil sub-label, works offline (show sync pill), nothing that needs typing when a stepper, chip or tap will do. Floating nav: **Today · Work · Cash · Me**.

### D-01 · Today: route manifest \[TODAY\]

```text
SCREEN D-01 Can Delivery Driver "Today". Top: avatar "R. Muthu", vehicle "TN-58-WA-101 (Tata Ace)", route "Anna Nagar & Teppakulam Route", pill "ACTIVE BEAT", sync pill, EN | தமிழ் toggle, bell. Offline banner when needed: "Offline mode. Scheduled route manifest active."
Hero card (aqua, white numerals): "Route Beat Completion" progress ring (e.g. 4 of 9 stops) with four stat tiles: "LOADED" 60, "DELIVERED" 28, "EMPTY CANS" 26, "REMAINING" 32.
Button row: outlined "+ Customer" and sun-yellow slab "Spot Bill" (→ D-03).
Stop list, ordered, each card: sequence number, customer (Hotel Saravana Bhavan — Main Road, Erode; Sri Krishna Sweets & Bakery — Brough Road, Erode), cans to deliver, GPS pill "GPS Verified" (mint) or "No GPS Set" (honey), icon buttons "Navigate" and "WhatsApp", and a primary "Deliver" button. When no GPS: card note "Please capture customer GPS via WhatsApp first." with a capture button (→ G-19).
Bottom card: "COLLECTED CASH IN POUCH" large ₹ numeral with button "Surrender Cash" (→ D-08).
STATES: empty "No delivery stops assigned for today."; error "An error occurred" with Retry; skeleton.
TAP → stop card → D-05; Deliver / Spot Bill → D-03; + Customer → D-06; Navigate → external map; Surrender Cash → D-08.
```

### D-02 · Plant Refill Manifest \[TODAY\]

```text
SCREEN D-02 "Plant Refill Manifest" (RO plant intake; the van can reload several times a day). Header chip "Load #2" with running total "72 + 84 = 156 cans". Fields: "Vehicle / Route Van" dropdown, "Empty Cans Handed Over" big stepper, "Full Sealed Cans Loaded" big stepper, "Damaged / Leakage Jars" stepper (coral when above 0), plant slip number field and a camera tile "Snap Plant Slip". Variance chip when full loaded exceeds empties handed over. Pinned sun-yellow slab "Confirm Plant Intake".
FEEDBACK: "Plant refill manifest confirmed and stock updated!"; offline "Refill manifest saved to offline Outbox!"
TAP → Confirm → D-01 with updated LOADED count.
```

### D-03 · Can Sales POS, 15-second ticket \[TODAY\]

```text
SCREEN D-03 "15s Can Sales POS". Top chips: "Truck Stock 46 / 60" and "LIVE BEAT". Section "Customer Party": GPS suggestion chip ("Nearest: Hotel Saravana Bhavan") plus dropdown of beat customers. Section "Delivered Full Cans" (Tamil sub-label டெலிவரி கேன்) with huge − / number / + stepper. Section "Returned Empty Jars" (Tamil sub-label காலி கேன்) with the same stepper. Info row: "Cust. Previous" and "New Cust. Held" can balance. Price row "14 × ₹20" (rate tappable to override). Section "Payment Collection": 4 big tiles Cash, UPI (shows a UPI QR on tap), Credit, Part-pay with "Paid amount" field. Pinned summary "Total Bill ₹280" and sun-yellow slab "Print & Save Ticket". Footer caption "09:34:12 AM · GPS accuracy 4.2 m".
FEEDBACK: "Can delivery ticket issued and synced with ERP!"; offline "Delivery ticket stored offline in Outbox! Will sync automatically."
TAP → Print & Save → D-04.
```

### D-04 · Delivery slip preview (58mm) \[TODAY\]

```text
SCREEN D-04 thermal slip preview on a narrow paper-like card. Header "DK WATERS — PACKAGED DRINKING WATER", sub line "Beat Route Delivery Slip • FSSAI: 1242300000000". Rows: slip no, date, customer, cans delivered, empties returned, rate, "TOTAL FARE:" bold, paid / balance, driver, time. Dashed tear line. Buttons: sun-yellow "Print Slip", text "Share on WhatsApp", and primary "Done (Next Customer Sale)".
TAP → Done → D-01.
```

### D-05 · Stop detail sheet \[NEW\]

```text
SCREEN D-05 bottom sheet for a stop. Customer, address, phone, GPS Verified pill, mini-map. Numerals: Cans held, Outstanding due, Deposit. Last delivery timeline (date, cans). Buttons: Navigate, Call, WhatsApp, sun-yellow "Deliver", secondary "Spot Audit" (→ D-07), "Mark skipped" with reason chips (Shop closed, Customer away, Not needed).
```

### D-06 · Add customer on the beat \[TODAY\]

```text
SCREEN D-06 "Add Customer" (driver version of A-53 to A-55 as one short scrolling page, route preselected). Fields: Customer / Shop Name*, Phone*, WhatsApp same-as-phone toggle, Street Address & Landmark*, GPS capture card ("Instant WhatsApp Location Capture" + "Capture My Current GPS Location Here" → G-19), Initial Cans Held stepper, Security Deposit (₹). Pinned slab "Save & Onboard Customer".
```

### D-07 · Spot Empty Can Audit \[TODAY\]

```text
SCREEN D-07 "Spot Empty Can Audit" (inspect the vehicle's cans against the route manifest). Card "Customer Location" with picker and GPS match chip. Card "Jar Balance Verification": "System Ledger Jar Balance" read-only numeral, "Physically Counted Jars" big stepper, "Variance Difference" result pill (mint "Exact Match (0)", coral shortage, honey excess). Field "Supervisor Remarks" (hint "Customer confirmed breakage / bottle replacement note"). Photo tile. Pinned slab "Confirm & Record Spot Audit".
FEEDBACK: "Spot audit submitted and verified with company database!"; offline "Audit record saved offline in Outbox!"
```

### D-08 · Driver Cash Surrender \[TODAY\]

```text
SCREEN D-08 "Driver Cash Surrender", subtitle "Daily Route Cash Settlement". Hero: "Gross Cash Collected Today (₹)" large numeral (prefilled from tickets, e.g. ₹4,100) with a split of Cash vs UPI vs Credit chips. Field "Less: Fuel & Route Expenses (₹)" (e.g. ₹400) with link to see expense slips. Result card "Net Cash Surrendered to Cashier" (₹3,700) in mint. Stepper "Empty cans returned to plant". Field "Cashier Handover Notes" (hint "e.g. Handed over ₹3,700 to Head Cashier"). Validation error "Expenses cannot exceed total collected cash." Pinned slab "Confirm Cash Surrender".
FEEDBACK: "Driver cash surrender completed and journal entry posted to ledger!"; offline "Cash surrender record queued in offline Outbox!"
TAP → Confirm → D-09.
```

### D-09 · Surrender receipt \[NEW\]

```text
SCREEN D-09 receipt. Mint check, "Surrendered ₹3,700", status pill "Awaiting cashier verification" that turns to "Verified", time, reference number, jars returned. Button "Back to Today".
```

### D-10 · Route map \[NEW\]

```text
SCREEN D-10 route map for the driver. Full-bleed map with numbered stops, the van marker, polyline of the route; bottom card for the next stop (name, distance, ETA, "Navigate" slab). Chips: Delivered (mint), Pending (aqua), Skipped (grey). List toggle to reorder stops by drag.
```

### D-11 · Work tab \[NEW layout of module launcher\]

```text
SCREEN D-11 "Work". Section "20L Can Distribution Operations" as large tiles: Can Sales POS Ticket (Fast 15-second driver sales & return tickets), Spot Empty Can Audit (Inspect Tata Ace vehicle cans vs route manifest), Driver Cash Surrender (End-of-day route settlement with cashier), Route Fuel & Expenses (Daily diesel & van maintenance slips), Plant Refill. Section "Staff & Attendance": Geofenced Attendance (GPS check-in / check-out).
TAP → D-03, D-07, D-08, D-13, D-02, D-14.
```

### D-12 · Cash tab \[NEW\]

```text
SCREEN D-12 "Cash". Hero: cash in pouch. Rows: Collected today, Expenses today, Net to surrender. Expense slips list with photo thumbnails. Buttons "Add Expense" (→ D-13) and slab "Surrender Cash" (→ D-08).
```

### D-13 · Route fuel and expenses \[TODAY\]

```text
SCREEN D-13 render A-63 (Quick Expense Voucher) in the driver skin with default category "Fuel / Diesel" and note hint "e.g. 5L diesel for Tata Ace van".
```

### D-14 · Attendance \[TODAY\]

```text
SCREEN D-14 render A-75 (Attendance & Shift) in the driver skin with a 72px CHECK IN / CHECK OUT slab.
```

### D-15 · Tasks and Outbox \[TODAY\]

```text
SCREEN D-15 driver tasks list: "Beat Deliveries" group with stop cards (Customer, Route Beat, [Deliver]); empty "No Scheduled Can Stops — All 20L can delivery beats for this vehicle are clear."; Outbox group with pending record count and "Sync Outbox Now".
```

### D-16 · Me \[TODAY\]

```text
SCREEN D-16 render G-10 in the driver skin. Replace the organization card with a Vehicle card (TN-58-WA-101 Tata Ace, 84 jar capacity), Route card (Anna Nagar & Teppakulam), and hide the Switch button. Keep theme, language, printer setup, sync centre and sign out.
```

## 15. Tanker Driver (T), Aqua Day skin

Same driver rules as section 14. Floating nav: **Today · Work · Cash · Me**.

### T-01 · Today: active trip \[TODAY\]

```text
SCREEN T-01 Tanker Driver "Today". Top: avatar "K. Murugan", vehicle "Tata LPT 2518 (20KL Dual Chamber)", trip "TMWS-TRIP-2026-002", sync pill, language toggle. Offline banner: "Offline mode. Scheduled tanker manifest active."
Hero card (aqua): status pill "VALVE SECURED" (anti-siphon, with lock icon), tiles "ODOMETER", "TODAY TRIPS", "TOTAL WATER" (KL), and a "Daily Dispatch Quota" progress bar.
Card "Assigned Destination & Trip": site "The Chennai Silks (Dyeing Unit)", type "Industrial Dyeing Unit", address "Perundurai SIPCOT Industrial Area, Erode", GPS pill; when missing the note "GPS location pending for this site. Capture via WhatsApp." Buttons: "Navigate (Maps)", "WhatsApp GPS", outlined "+ New Site".
Card "Decanting Meter & Trip Log": big numeral "WATER TO DECANT" in KL, live gauge "FLOW: 0 L/min".
Buttons: outlined "Decanting & Fuel Log", sun-yellow slab "Complete Trip".
STATES: toast "Please capture location via WhatsApp link first."; error "An error occurred" with Retry; skeleton.
TAP → Complete Trip → T-03; Decanting & Fuel Log → T-04; Navigate → external map; WhatsApp GPS → G-19; + New Site → T-06.
```

### T-02 · Auto Tanker Trip Sheet, 4 states \[TODAY\]

```text
SCREEN T-02 "Auto Tanker Trip Sheet" with "Reset Trip" in the app bar. Show 4 frames of the same screen: (1) "Trip Ready to Dispatch" with sun-yellow slab "Start Trip (Auto GPS Tracking)"; (2) "En Route (Live GPS Tracking Active)" with slab "Arrived at Site"; (3) "At Customer Site (Decanting)" with an automatic waiting timer and slab "Finish Trip"; (4) "Trip Completed · Ready to Bill" with slab "Decanting Done · Generate Bill". A 4-step progress rail at the top (Dispatch, En Route, At Site, Billed). Tamil sub-title தானியங்கி GPS & காத்திருப்பு கண்காணிப்பு.
Cards, top to bottom: "Tanker Vehicle & Customer Site" ("Assigned Tanker", "Customer Delivery Site" picker, e.g. Borewell Hub (Perundurai) → Commercial Site). "Distance Tracking (Dual Verification)" with pill "GPS LIVE" (mint) or "ODOMETER MODE" (amber, helper "GPS offline · Billing calculated via Odometer Start & End KM"), "GPS Tracked Distance", "Odometer Reading", fields "Start KM", "End KM", switch "Override GPS with Manual Odometer". "Automatic Halt / Waiting Timing" with pill "AUTO TRACKED": "Total Halted Time", "Billable Waiting"; toast "Arrived at site! Automatic halt/waiting timer is now tracking." "Motor Pumping (Only Manual Entry)": helper "Simply enter pumping duration", live stopwatch card ("Motor Pumping Active...", "Live Pump Stopwatch") with buttons "Start Pump"/stop and field "Pumping Minutes". "Vehicle Trip Vouchers (Optional)": "Toll Gate (₹)", "Diesel Voucher (₹)". "Site Receiver / Contact" (e.g. Suresh Kumar, P. Murugan). Sticky total "Total Billed Amount".
ERRORS: "Location services are disabled on device", "Location permissions denied", "Location permissions permanently denied" (→ G-15).
TAP → Generate Bill → T-03.
```

### T-03 · Trip bill and surcharges \[TODAY\]

```text
SCREEN T-03 "Tanker Trip Sheet" billing step. Card "Industrial Customer Site" (picker). "Water Decanted:" numeric stepper in KL with presets (9, 16, 20, 24, 30, 40). "Odometer Mileage (km)": "Start KM", "End KM" with computed distance. Card "Trip Bill & Surcharges": toggle rows "Motor Pumping Surcharge" (+₹250), "Site Waiting Surcharge" (2.0 hrs, +₹300), optional long-distance and toll rows, each with amount; "Base Water Freight" row; bold "Total Trip Amount" (₹3,230). Photo tiles "Gate pass" and "Customer signature". Pinned slab "Complete Trip & Post Invoice".
FEEDBACK: "Bulk tanker trip sheet recorded successfully!"; offline "Tanker trip sheet saved to offline Outbox!"
TAP → Complete → T-05.
```

### T-04 · Decanting and fuel log \[NEW layout\]

```text
SCREEN T-04 "Decanting & Fuel Log". Top: live flow gauge (L/min), litres decanted counter, anti-siphon valve state (SECURE / OPEN) and tank level bar. Buttons "Start Decanting" / "Stop". Below: fuel log list and "Add Diesel Slip" button (→ T-08). Timeline of valve events with times.
```

### T-05 · Trip completed \[NEW\]

```text
SCREEN T-05 success. Mint check, "Trip completed", trip no, KL delivered, distance, total amount, invoice number. Buttons "Print Trip Sheet", "Share Invoice", "Back to Today".
```

### T-06 · Add new site \[TODAY\]

```text
SCREEN T-06 "New Customer / Site" (onboard destination sump). Short scrolling form: Site / company name*, Contact person, Phone*, GSTIN (optional), Address*, GPS capture card (→ G-19), route preselected "Commercial Bulk Tanker Route (TMWS Tanker Fleet)". Slab "Save & Onboard Customer".
```

### T-07 · Work tab \[NEW layout\]

```text
SCREEN T-07 "Work". Section "Bulk Tanker Operations" tiles: Tanker Trip Sheet (Dispatches, odometers, decanting & surcharges), Diesel & Vehicle Expenses (Fuel slips, tanker repair & toll expenditure), Decanting & Fuel Log, New Site. Section "Staff & Attendance": Geofenced Attendance. Section "Recent trips" list (T-12).
```

### T-08 · Diesel and vehicle expenses \[TODAY\]

```text
SCREEN T-08 render A-63 (Quick Expense Voucher) in the driver skin with default category "Fuel / Diesel", subtitle "Capture pump slips, driver batta & maintenance bills".
```

### T-09 · Attendance, Tasks, Me \[TODAY\]

```text
SCREEN T-09 render A-75 (Attendance) in the driver skin. SCREEN T-10 render the Tasks list with the group "Tanker Dispatches" (Tanker Trip Sheet Dispatch, Diesel & Vehicle Expenses). SCREEN T-11 render G-10 in the driver skin with a Vehicle card (Tata LPT 2518, 20 KL dual chamber).
```

### T-12 · Trip history \[NEW\]

```text
SCREEN T-12 "My Trips". Date strip, totals (trips, KL, km). Trip cards: trip no, customer site, KL, distance, amount, status pill. Tap opens the trip summary (A-91 layout in the driver skin).
```

## 16. Cafe In-charge (C), Chai & Crema skin

Cafe rules: cream canvas, terracotta and saffron, 56px taps, built for one-handed counter use and fast taps with wet or floury hands. Floating nav: **Counter · Orders · Drawer · Kitchen · Me**. The in-charge is the cashier role in the app today, extended here with tables, KOT, refunds, drawer count and kitchen production.

### C-01 · Counter home \[TODAY\]

```text
SCREEN C-01 Cafe In-charge "Counter" home. Top: company chip "Aran Cafe (Main Branch)", sync pill, bell, avatar, shift chip "Shift open since 7:02 AM · Float ₹5,000".
Hero card (terracotta, cream numerals): "Gross counter billing" today's sales numeral with a delta chip. Three bento tiles: "Orders Billed — Completed tickets", "Cash in Drawer — Physical drawer cash", "Average Order Value — Average per bill". Split bar with two labelled amounts: "DIGITAL / UPI COLLECTIONS" and "CASH COLLECTIONS".
Huge saffron slab "Open Touch POS Terminal" (→ C-02). Below it a 3-button row: "Standard Sale Invoice" (→ C-41), "Reconcile & Handover Drawer" (→ C-22), "View All Bills" (→ C-10).
Extra cards: "Top Counter Items" (top 5 with sold counts), "Open KOTs" count chip (→ C-08), low-stock chip (→ C-31).
STATES: skeleton; error with Retry.
```

### C-02 · POS terminal: menu \[TODAY\]

```text
SCREEN C-02 "Aran Cafe POS Terminal". Top: search pill, order-type segmented Dine-in | Takeaway | Delivery, table chip ("Table 4") when Dine-in. Category chips: "Bakery & Cafe", Breakfast Only, Evening Snacks / Tea, Weekend Special, Toppings & Extras. Featured items row first. Menu grid, 2 columns: item card with image tile, name, price, add "+" button; items with In Stock Availability off are greyed with "Sold out"; long-press toggles sold out. Sticky bottom cart bar: item count, total, button "View cart".
STATES: empty menu "No menu products configured for this branch."
TAP → item → adds one (or C-03 if it has toppings / sizes); cart bar → C-04.
```

### C-03 · Item customize sheet \[NEW\]

```text
SCREEN C-03 bottom sheet. Item name and price, size chips, add-on topping chips (items flagged as Topping / Extra), quantity stepper, note field ("Less sugar", "Warm"), kitchen station label (Oven Station / Tea Counter / Packaging Unit). Primary "Add to cart • ₹120".
```

### C-04 · Cart and review \[TODAY\]

```text
SCREEN C-04 cart. Empty state: "Cart is empty. Tap items to add to order." With items: line cards with name, add-ons, stepper, line total, swipe to delete; text button "Clear". Chips: customer ("Walk-in" or attach), table, order note. Totals card: Subtotal, Discount (chips 5%, 10%, ₹ custom), Tax, Total. Button row: "Hold" (→ C-09), "Send KOT" (→ C-08), primary "Charge & Print Slip" (→ C-05).
```

### C-05 · Payment sheet \[NEW layout\]

```text
SCREEN C-05 payment bottom sheet. Big total. Tender tiles: Cash, UPI (shows QR), Card, Credit to customer, Split. Cash: numeric pad with quick notes ₹50 ₹100 ₹200 ₹500 and live "Change due". Primary "Charge ₹245".
TAP → Charge → C-06.
```

### C-06 · Receipt and success \[TODAY\]

```text
SCREEN C-06 success with a 58mm slip preview: "ARAN CAFE", order no, date and time, items with qty and amount, tax, total, payment mode, "Thank you". Toast "Cafe POS ticket issued and drawer updated!" (offline: "POS order stored in offline Outbox! Will sync automatically."). Buttons "Print Slip", "Share on WhatsApp", primary "New Order".
```

### C-07 · Tables (dine-in map) \[NEW\]

```text
SCREEN C-07 "Tables". Grid of table tiles in a simple floor plan: Free (cream), Occupied (terracotta with running total and elapsed minutes), Bill requested (saffron). Floor chips (Ground, Terrace). Tap a table: Open order or Transfer / Merge sheet.
```

### C-08 · KOT and kitchen display \[NEW\]

```text
SCREEN C-08 "Kitchen Orders". Station chips (All, Oven Station, Tea Counter, Packaging Unit). KOT cards with order no, table or takeaway, age timer (turns saffron then coral), item list with notes, status buttons New → Preparing → Ready → Served. "Ready" shows a gentle bell animation.
```

### C-09 · Held orders \[NEW\]

```text
SCREEN C-09 "Held Orders". Cards with hold name or table, items count, total and time. Buttons Resume and Discard.
```

### C-10 · Orders: all bills \[TODAY\]

```text
SCREEN C-10 "Orders" tab ("View All Bills"). Date strip, search by bill no, filter chips All, Cash, UPI, Credit, Refunded. Summary: Orders, Sales, Avg bill. Bill rows: bill no, time, items count, payment icon, amount, status pill. Empty "No bills yet today".
TAP → row → C-11.
```

### C-11 · Order detail \[NEW\]

```text
SCREEN C-11 order detail. Header bill no, time, cashier, payment mode. Items list, totals. Buttons "Reprint Slip", "Share", outlined "Refund / Void" (→ C-12).
```

### C-12 · Refund / void \[NEW\]

```text
SCREEN C-12 "Refund / Void". Tick items or full bill, reason chips (Wrong item, Customer cancelled, Quality issue, Duplicate), refund mode (Cash, UPI, Credit note), manager PIN pad when the amount is above the limit. Primary "Post Refund".
```

### C-20 · Drawer overview \[TODAY\]

```text
SCREEN C-20 "Cash Drawer" tab. Hero: "Cash in Drawer" physical cash, "Float ₹5,000", expected cash = float + cash sales − refunds − expenses. Rows: Cash sales, UPI sales, Card sales, Credit sales, Expenses paid, Cash handed to owner. Button "Reconcile & Handover Drawer" (→ C-22), link "Cash Book (1010)" (→ A-60 read-only).
```

### C-21 · Open shift \[NEW\]

```text
SCREEN C-21 "Open Shift". Opening float counter with denomination steppers (₹500, 200, 100, 50, 20, 10, coins), total, expected float ₹5,000 with a variance chip. Primary "Start Shift".
```

### C-22 · Reconcile & Handover Drawer \[TODAY\]

```text
SCREEN C-22 "Reconcile & Handover". Step 1 Count: denomination steppers with live total. Step 2 Compare: Expected cash vs Counted cash with variance chip (mint 0, coral short, honey excess) and an UPI and card total check against the bank/UPI report. Step 3 Handover: amount handed to owner, balance kept as next float, note field. Primary "Close Shift & Handover".
TAP → C-23 then C-24.
```

### C-23 · Shift report \[NEW\]

```text
SCREEN C-23 "Shift Report" (X / Z). Sales by payment mode, top items, refunds, discounts, expenses, drawer variance, order count and average bill. Buttons "Print", "Share PDF".
```

### C-24 · Handover receipt \[NEW\]

```text
SCREEN C-24 handover receipt. Mint check, amount handed over, recipient, time, shift summary link. Button "Done".
```

### C-30 · Kitchen hub \[TODAY\]

```text
SCREEN C-30 "Kitchen & Recipe Inventory" (Kitchen tab). Hero: ingredient stock health ring (e.g. 8 of 40 low). Bento tiles: Stock Audit (→ C-31), Production (→ C-32), Wastage (→ C-33), Menu & Availability (→ C-34), Expenses (→ C-35), Reorder (→ C-36). List "Low ingredients": milk, sugar, flour, coffee beans with bars.
```

### C-31 · Kitchen & Ingredient Stock Audit \[TODAY\]

```text
SCREEN C-31 "Kitchen & Ingredient Stock Audit", subtitle "Verify milk, sugar, flour & coffee beans". Ingredient list with system quantity and a counted stepper per row, variance chip, scan button (→ G-18). Filter chips Dairy, Dry goods, Beverages, Packaging. Footer counts matched / short. Primary "Confirm & Submit Count" (same feedback as A-32).
```

### C-32 · Production batch \[NEW\]

```text
SCREEN C-32 "Production". Pick recipe, quantity stepper, ingredient need vs stock list (coral when short), station chip. Buttons "Start" then "Complete & Add to Stock" with yield and wastage entry.
```

### C-33 · Wastage log \[NEW\]

```text
SCREEN C-33 "Log Wastage". Item picker, quantity, reason chips (Expired, Spilled, Burnt, Returned, Staff meal), photo, cost impact preview. Primary "Save Wastage". Recent wastage list below.
```

### C-34 · Menu & availability \[TODAY\]

```text
SCREEN C-34 "Menu Catalog" (subtitle "Top Counter Items & Price Matrix"). Items grouped by Menu Type (Regular, Breakfast Only, Evening Snacks / Tea, Weekend Special) with price, sold-out switch, featured star. Search pill. Price edits need admin approval (lock icon).
```

### C-35 · Daily cafe expenses \[TODAY\]

```text
SCREEN C-35 render A-63 (Quick Expense Voucher) in the Cafe skin with category chips Vegetables, Milk & Dairy, Gas Cylinder, Vendor Payment, Staff Tea, Miscellaneous; subtitle "Record dairy, gas, veggies & vendor payments"; "Payment Out From" defaults to the cash drawer. Today's expenses total shown at the top.
```

### C-36 · Reorder request \[NEW\]

```text
SCREEN C-36 "Reorder". Low-stock items pre-selected with suggested quantity steppers and preferred supplier chips. Primary "Send to Owner for Approval".
```

### C-40 · Customer payment collection \[TODAY\]

```text
SCREEN C-40 render A-16 (Collect Customer Payment) in the Cafe skin for party dues.
```

### C-41 · Standard Sale Invoice \[TODAY\]

```text
SCREEN C-41 render A-12 (Create Sale Bill) in the Cafe skin for bulk or B2B orders (cakes, catering).
```

### C-42 · Attendance \[TODAY\]

```text
SCREEN C-42 render A-75 in the Cafe skin with staff list for the shift (in-charge can punch staff in).
```

### C-43 · Tasks \[TODAY\]

```text
SCREEN C-43 "My Work & Task Queue" with cafe cards: "Aran Cafe Touch POS Counter — Ready for table & counter billing" [Open POS]; "Kitchen & Ingredient Stock Audit — Verify milk, sugar, flour & coffee beans" [Audit]; "Daily Cafe Operational Expenses — Record dairy, gas, veggies & vendor payments" [Record]; plus Outbox segment.
```

### C-44 · Me \[TODAY\]

```text
SCREEN C-44 render G-10 in the Cafe skin. Organization card shows Aran Cafe, Main Branch (no Switch button). Keep theme, language, printer setup, sync centre, sign out.
```

### C-45 · Quick Actions (cafe set) \[TODAY\]

```text
SCREEN C-45 quick action sheet with: Cafe POS (Order billing), New Customer (Party registration), Collect Payment (Invoice settlement), Quick Expense (Kitchen purchases), Mark Attendance (Geofenced punch).
```

## 17. Field Agent (F), Field Sage skin (extra role in the app)

The app has a fourth role you did not list. It is included so no screen is missed. Floating nav: **Collect · Customers · Spend · Me**. 56px taps.

### F-01 · Collect home \[TODAY\]

```text
SCREEN F-01 "Field Collection & KYC Desk", subtitle "Assigned Customer Receivables & GPS Onboarding", pill "ACTIVE BEAT". Hero card: "Total Receivables" numeral. Tiles: "Assigned Accounts", "Direct field collections", "Recovery Rate" ring with "Target: 90.0%". Buttons: sun-lime slab "Collect Dues" (→ F-04) and outlined "Onboard Client" (→ F-06). Search pill "Search customer name, enterprise or phone...". Customer cards: name, enterprise, due amount or pill "CLEAR", GPS pill "Geotagged" or "No GPS", buttons "Call Customer", "Navigate via Google Maps", "Update GPS" / "Tag GPS" (→ G-19), primary "Collect".
STATES: empty "No customers assigned." / "No customer matches your search."; error "Failed to load field agent data".
```

### F-02 · Customers and GPS pins \[TODAY\]

```text
SCREEN F-02 render A-50 in the Field Sage skin, restricted to assigned customers, with a map toggle showing GPS pins.
```

### F-03 · Customer quick sheet \[NEW\]

```text
SCREEN F-03 bottom sheet: customer, due, aging chips, last payment, promise-to-pay date picker, buttons Call, Navigate, Collect, Add visit note.
```

### F-04 · Collect dues \[TODAY\]

```text
SCREEN F-04 render A-16 in the Field Sage skin with receipt allocation against outstanding dues and an optional photo of cheque or cash memo.
```

### F-05 · Collection receipt \[NEW\]

```text
SCREEN F-05 render A-17 in the Field Sage skin with "Send receipt on WhatsApp" as the primary button.
```

### F-06 · Onboard client \[TODAY\]

```text
SCREEN F-06 render the A-53 to A-55 flow in the Field Sage skin ("Onboard Customer — KYC & GPS geotagging").
```

### F-07 · Field conveyance and expenses \[TODAY\]

```text
SCREEN F-07 render A-63 in the Field Sage skin ("Instant receipt capture with camera & GPS").
```

### F-08 · Attendance \[TODAY\]

```text
SCREEN F-08 render A-75 in the Field Sage skin.
```

### F-09 · Me \[TODAY\]

```text
SCREEN F-09 render G-10 in the Field Sage skin without the organization Switch button.
```

## 18. Checklist: every screen ID

Use this to confirm nothing is missing before you start generating. **166 screens** in total.

- **G Shared and sign-in (20):** G-01 to G-20.
- **A Admin (79):** A-01, A-02a/b/c/d, A-03, A-04, A-05 · A-10 to A-18 · A-20 to A-26 · A-30 to A-35 · A-40 to A-46 · A-50 to A-56 · A-60 to A-68 · A-70, A-71 · A-75 to A-79 · A-80 to A-84 · A-90 to A-102 · A-110.
- **D Can driver (16):** D-01 to D-16.
- **T Tanker driver (12):** T-01 to T-12.
- **C Cafe in-charge (30):** C-01 to C-12 · C-20 to C-24 · C-30 to C-36 · C-40 to C-45.
- **F Field agent (9):** F-01 to F-09.

**Suggested generation batches (about 10 prompts a sitting):** (1) G-01 to G-06 · (2) A-01, A-02 · (3) A-10 to A-18 · (4) A-40 to A-45 · (5) D-01 to D-04 · (6) D-05 to D-10 · (7) T-01 to T-03 · (8) C-01 to C-06 · (9) C-20 to C-24 · and then the rest by section.

**Core flows to wire in Stitch (these make the prototype feel real):**

1. Login (G-02) → role Home → Quick Action → action → success → back to Home.
2. Can driver: D-01 → D-02 plant load → D-03 sale → D-04 slip → D-01 → D-08 surrender → D-09. Admin side: A-66 → A-67 verify and post.
3. Tanker driver: T-01 → T-02 (4 states) → T-03 bill → T-05 → A-90 → A-91.
4. Cafe: C-01 → C-02 → C-03 → C-04 → C-05 → C-06; C-20 → C-22 → C-23 → C-24.
5. Admin money: A-12 → A-13 → A-16 → A-17 → A-60 → A-61.

**If Stitch shortens or renames elements:** re-send that single screen with the line "Keep every listed label exactly as written; add nothing that is not listed." Generate each screen's dark variant by adding "Render in dark mode using the dark palette" to the same prompt.
