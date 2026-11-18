# Client Live Review Transcription, Bug Audit & Master 4-Phase Implementation Plan

**Project:** ZOLO ERP Pro / DK Track Unified Platform (Laravel Backend + Web ERP + Flutter Mobile/Tablet App)  
**Active Branch:** `main`  
**Review Date:** 2026-11-17 (12:19 PM – 1:29 PM IST)  
**Client Entities:** **DK Enterprises** — *Tiruchendur Murugan Water Supply (`TMWS`, Bulk Water)*, *DK Waters / `DRINKAA` (Packaged Drinking Water & Delivery Vans)*, and *Aran Cafe / Bakery (`ARAN1`, `ARAN2`)*  
**Primary Location:** Erode & Regional Industrial Belt (Veerappampalayam, Karungalpalayam, Chithode, Lakshmi Nagar, Mettukadai, Gobichettipalayam, Coimbatore, Salem)  
**Execution Purpose:** Complete, zero-omission source-of-truth specification so **Flash implementation agents** can execute all **4 Phases (13 Work Items)** deterministically without missing any requirement or making unverified assumptions.

---

## Part 1: Source Inventory (Audio Recordings & Screenshots)

### 1.1 Audio Recordings (`C:\Users\Nandhu\Downloads\drive-download-20261117T093313Z-1-001\`)

| # | Filename | Duration | Size | Core Topics Discussed |
|---|---|---|---|---|
| 1 | `17-11-2026 12.19.m4a` | 12m 27s | 12.10 MB | TMWS customer onboarding water-can leak bug (Screenshot 2); Customer `₹15,000` opening balance not showing as Due; Create Order & Driver Dispatch clarity; Real TMWS fleet specs (`Comet 14KL` × 2, `Taurus 25KL` × 3, `Eicher 9KL` × 2 w/ compartments, `Tata 407 5KL` × 1 w/ 2 compartments, `Pondicherry 25ft Trailer` × 1); Peak summer (`May–July`) tie-up outside tankers (`வெளி வண்டி`); Weekly/monthly corporate bulk billing; Internal WhatsApp dispatch workflow (`Owner`, `Kavin`, `Manager`). |
| 2 | `17-11-2026 12.33.m4a` | 0m 29s | 474 KB | Simplify vehicle tracking workflow and provide an inline customer creation/type-in option inside the Customer Name field on Order creation. |
| 3 | `17-11-2026 12.35.m4a` | 24m 27s | 23.76 MB | Instant walk-in residential customer entry (`Name`, `Phone`, `Location`, `KL`, `Agreed Price`); Fixed Corporate PO rates vs. dynamic residential/civil rates (`₹600–₹1,200+`); **8 Water Pickup / Borewell Points (`தண்ணி பிடிக்கிற இடம்`)** (4–5 regular + 3–4 outer paid weekly/monthly); Driver Trip flow (`Start`, `Odometer`, `Arrived`, `Motor Running Timer`); **Driver Vehicle Number selector dropdown** for rotating drivers; **`+ Extra / - Discount`** field; **GPay / UPI `Pending` vs `Confirmed` + Screenshot/Camera proof upload**; Payment Gateway deferred while DK Enterprises partnership netbanking activates. |
| 4 | `17-11-2026 13.03.m4a` | 3m 09s | 3.07 MB | Missing visible **Logout** button on Driver main screen; Multi-branch setup for **`ARAN1` & `ARAN2`** with branch-locked Managers/Cashiers; Cafe POS review & **`The route api/v1/pos/orders could not be found.`** 404 error (Screenshot 3). |
| 5 | `17-11-2026 13.07.m4a` | 9m 45s | 9.48 MB | Cafe walk-in POS priority vs. future dine-in KDS/tables; **Spreadsheet-Style Multi-Row Batch Daily Cash In/Out & Expense Entry** matching client's `2026 Accounts` Google Sheet (Screenshot 1); **Missing Mobile Quick Purchase Bill / Regular Supplier Entry** (~10 regular vendors: milk, groceries, ice cream, flour, fruits, onions, gas, auto spares). |
| 6 | `17-11-2026 13.23.m4a` | 5m 57s | 5.79 MB | **Bakery / Biscuit B2B Van Distribution** on the same 2 water-can vans (`Tata Ace EV` city `<100 km` & `Tata Ace Diesel` outer Gobi/Cbe/Salem — logging pieces/boxes per shop stop); **Wipe Demo Data for Fresh Client Live Trial**; Reproducing Cashier POS `Pay Cash` 404 error; Web Portal Expense Categories & HRM walkthrough (`Department`, `Designation`, `Shift`, `Employee`, `Attendance`, `Payroll`). |

### 1.2 Client Screenshots Audited

1. **Screenshot 1 (`1:14 PM` — `2026 Accounts` Google Sheet, `October` tab):**
   - **Top-Left Account Balances Summary Table:**
     - Columns: `Account` | `Opening` | `Current`
     - Accounts Listed: `Kavin Axis`, `Sasi`, `Axis OD LOAN`, `DeekTex`, `Kavin KVB`, `Kavin Canara`, `CASH` (`TOTAL: 0`).
   - **Top Totals Box:** `Total IN: 15515`, `Total OUT: 204337`, `Total: 219852`.
   - **Main Daily Transaction Ledger Columns:**
     - `S.NO`
     - `Date` (format observed: `21.10.2026`)
     - `Cash In/Out` (dropdown badge: `OUT` / `IN`)
     - `Company` (dropdown values observed: `TM WATER SUPPLY`, `DRINKAA`, `ARAN1`, `ARAN2`, `ARAN`, `FAMILY`, `COMMON`)
     - `Payment Type` (dropdown values observed: `GPAY - KAVIN AXIS`, `CASH`, etc.)
     - `Amount` (`300`, `900`, `9750`, `1900`, `1900`, `500`, `31460`, `1000`, `1000`, `798`, `10500`, `456`)
     - `VEHICLE / STAFFS` (dropdown pill values observed: `platina`, `SURESH`, `TN 47 M 4585`, `RAJA`)
     - `Bill No` (`WL9554`, `1693`)
     - `Description` (`suresh went to amirtha`, `mobile recharge`, `Tata Ace Ev Kotak loan`, `Kalpana Advance`, `Cooldrinks`, `Prabu auto spares`, `Chendhur gas agency`, `Boopathi advance`, `Raja advance`, `kavin , sasi haircut`, `Satha Workshop -Sakthi auto`, `Kovil EB bill`)

2. **Screenshot 2 (`12:19 PM` — `Onboard New Customer` in `TMWS`):**
   - Header: `Onboard New Customer` with green company pill `TMWS` at top-right.
   - Visible fields: `City / Taluk *: Erode`, `GSTIN (Optional)`, `Instant WhatsApp Location Capture: 11.381826, 77.700206` (`GPS Coordinates Locked: 11.38183, 77.70021`), `Pick on Map`.
   - Bug under **`3. Route Beat & Water Inventory`**:
     - `Assign Delivery Route Beat *: Commercial Bulk Tanker Route (TMWS Tanker Fleet)`
     - **Leaked Can Fields:** **`Initial Cans Held: 5`** and **`Security Deposit (₹): 750`** displayed inside `TMWS` (`bulk_water`), even though water cans/deposits only apply to `packaged_water` (`DK Waters` / `Drinkaa`).
     - **`Opening Balance Due (₹): 0.00`**

3. **Screenshot 3 (`1:06 PM` — `Counter POS Terminal` in `Aran Cafe`):**
   - Header: `Counter POS Terminal` · `Aran Cafe · No open drawer shift`.
   - Order Mode & Meta: `Dine-In` | **`Takeaway`** (selected) | `Delivery`; `Walk-in Customer` | `No Table` | `Print / Labels`.
   - Rate Slabs: **`Retail MRP`** (selected) | `Wholesale` | `Staff Rate` | `Online Aggregator` | `Fast Bill`.
   - Catalog Search: `tea` showing `Special Masala Tea` (`₹20`, `0 left`, `7x`).
   - Right Cart (`Current Order Ticket — 27 items`):
     - `Raw Dairy Milk (Bulk)` × `1` = `₹55.00`
     - `Blueberry Muffin` × `3` = `₹150.00`
     - `Milk Loaf Bread 400g` × `12` = `₹540.00`
     - `White Cane Sugar` × `4` = `₹180.00`
     - `Grand Total: ₹1,065.00`, `Cash` tender selected, `Hold / KOT` & `Print 80mm`.
   - **Critical Checkout Bug Banner (Red Snackbar at bottom):** **`The route api/v1/pos/orders could not be found.`**

---

## Part 2: Complete Chronological Audio Transcriptions & Business Rules

### 2.1 Recording 1: `17-11-2026 12.19.m4a` (12m 27s)

- **`00:00 – 00:13` | Bug — Water Can Fields Leaking into TMWS Bulk Tanker Customer Onboarding (Screenshot 2):**
  - *Tamil Excerpt:* *"இப்ப அந்த வாட்டர் கேன் சப்ளை இதும் இதுல வந்து நமக்கு லீக் ஆகுது இல்லையா? ஆமா. சரி ஓகே அதை எடுத்து விட்டுறேன்."*
  - *Meaning:* During TMWS onboarding on iPad, the developer & client notice `Initial Cans Held (5)` and `Security Deposit (₹750)` leaking onto the Bulk Tanker customer form. Must be hidden for `bulk_water` (`TMWS`).
- **`00:19 – 01:19` | Bug — Customer `Opening Balance Due (₹15,000)` Not Reflected in Due / Map Status:**
  - *Tamil Excerpt:* *"இந்த ஓபனிங் பேலன்ஸ்ங்கிறது வந்து ஏற்கனவே பெண்டிங் இருக்குற அமௌன்ட்... அவங்க கணக்குல 15,000 ஏற்கனவே பழைய ஓல்ட் பேலன்ஸ் இருக்கு... பட் பெய்டுன்னு தான் வருது இல்லையா, பழைய பேலன்ஸ் எதுவும் காமிக்கல... ஆனா இப்ப 15,000 போட்டுருக்கீங்க இல்லையா? சரி ஓகே அதை நான் ஆட் பண்ணிடுறேன்."*
  - *Meaning:* Client asks if `Opening Balance` is for existing old pending balance. They test-enter `₹15,000` for an onboarded customer and save, but viewing the customer in the directory / map still shows `PAID` (`₹0 Due`). `opening_balance` must be included in `total_sales` / `due_amount` calculations across the directory, customer 360° sheet, and map pins.
- **`01:38 – 03:18` | Order Booking & Missing Driver Master Setup:**
  - Client asks where Owner or Manager creates a tanker order so it reaches the driver (`Create Order` / `Trip Order`) and notes he has not yet created his actual driver & vehicle records (`நான் இன்னும் டிரைவர் எதுவும் கிரியேட் பண்ணலைங்கண்ணா`).
- **`03:27 – 10:55` | Real TMWS Fleet Variants, Capacities & Compartment Rules:**
  - Client specifies his exact TMWS tanker lineup and compartment flexibility:
    1. **Ashok Leyland Comet (`காமெட்`) — `14 KL` (`14,000 L`)** × **2 vehicles**: Single-chamber full load (`14 KL` only, no compartments).
    2. **Ashok Leyland Taurus (`டாரஸ் லாரி`) — `25 KL` (`25,000 L`)** × **3 vehicles**: Single-chamber full load (`25 KL` only, no compartments).
    3. **Eicher (`ஈச்சர் வண்டி`) — `9 KL` (`9,000 L`)** × **2 vehicles**: Compartmentalized — delivers `9 KL`, `8 KL`, `7 KL`, down to `4 KL` (economic rule: runs `4–5 KL` only for nearby city deliveries, full `7–9 KL` for longer distances).
    4. **Tata 407 (`டாடா 407`) — `5 KL` (`5,000 L`)** × **1 vehicle**: Dual-compartment (`2,000 L` + `3,000 L`) — takes orders for `5 KL`, `4 KL`, `3 KL`, or `2 KL`.
    5. **Pondicherry Large Trailer/Tanker (`பாண்டிச்சேரி பெரிய வண்டி`, 25 ft length)** × **1 vehicle**: Too long (`25 ft`) for narrow Erode city lanes; deployed on wide-road outer industrial/institutional contracts (`Sakthi Sugars Factory`, `Amrita Milk` ~6–7 months/year) and large hospital/school construction projects (`1 Lakh L` – `5 Lakh L` total requirements).
- **`03:45 – 06:35` | Peak Season (`May–July`) & Breakdown Tie-Up Outside Tankers (`வெளி வண்டி`):**
  - *Tamil Excerpt:* *"மே, ஜூன், ஜூலை அந்த மூணு மாசம் பாத்தீங்கன்னா எல்லா பக்கம் வைகை தண்ணி நிப்பாட்டிடுவாங்க... அப்ப நம்ம வண்டியும் பத்தாம வேற வண்டி காரங்களுக்கு லோட மாத்தி விடுவோம்ண்ணா... கஸ்டமர் டைரக்டா ரீடைரக்ட் ஆக மாட்டாங்க, என்னோட கஸ்டமர் தான், என் பேர்லயே பில் போடுவாங்க... நான் இவங்களுக்கு பே பண்ணிடுவேன்."*
  - *Business Rule:* When own fleet is full (summer peak, dyeing units / `பட்டறைக்காரங்க`) or under maintenance, loads are subcontracted to **1–2 trusted outside tanker owners** who carry TMWS's bill book.
  - The outside owner must NOT poach or directly bill the customer. TMWS invoices the customer (often accumulated into weekly/monthly corporate settlements where `₹2L–₹10L` stays open and clears in `₹50k–₹1L` installments), while TMWS tracks payable trip charges owed to the outside tanker vendor.
- **`08:15 – 12:25` | Real-World Incoming Call → Internal WhatsApp Dispatch Workflow:**
  - Client shows his WhatsApp dispatch messages used by **Owner**, **Kavin**, and **Manager**:
    - Regular party message: *"Eswaran Building — Eicher"*, *"Comet 14,000L"*.
    - New/Event message: *"For Kovil Function — Contact Number"*, *"Krishna Sizing"*, *"Keerthi Bakery Solar — 9KL (9,000L)"*.
  - Manager forwards to the driver; when Manager is on leave, Owner dispatches directly.

### 2.2 Recording 2: `17-11-2026 12.33.m4a` (0m 29s)

- **`00:01 – 00:29` | Simplify Vehicle Tracking & Inline Customer Option:**
  - Keep vehicle tracking straightforward and give an inline option inside the `Customer Name` control during order creation so dispatchers don't have to leave the order sheet to add a one-off customer.

### 2.3 Recording 3: `17-11-2026 12.35.m4a` (24m 27s)

- **`00:00 – 01:48` | Walk-in Residential Customer Inline Entry & Corporate Fixed PO vs. Dynamic Civil Price:**
  - *Tamil Excerpt:* *"புது புது வீட்டு கஸ்டமர்லாம் கால் பண்ணுவாங்கண்ணா... ரேண்டமா அப்படியே டைப் பண்ணி என்டர் ஆகுற மாதிரி, அதுக்கு கீழயே கெப்பாசிட்டி, காண்டாக்ட் நம்பர்... பிரைஸ் நானும் மேனேஜரும் என்ன கஸ்டமர்ட்ட பேசுறோமோ அந்த பிரைஸ் நாங்களே என்ட்ரி பண்ற மாதிரி."*
  - *Business Rule:* Corporate/industrial accounts have fixed Work Order / PO rates, whereas residential houses (`வீட்டு கஸ்டமர்`) / civil construction vary dynamically (`₹600`, `₹700`, `₹800`, `₹1,000`, `₹1,200+`) based on travel distance (e.g., Mettukadai), hose length / 2nd-floor overhead pumping, or requested water source. Order form must allow typing **Customer Name**, **Phone Number**, **Area/Location**, **Capacity (`KL`)**, and **Agreed Price (`₹`)** inline without leaving the order sheet.
- **`01:37 – 03:35` | 8 Water Pickup / Borewell Points (`தண்ணி பிடிக்கிற இடம்`):**
  - *Tamil Excerpt:* *"மொத்தம் எட்டு இடம் வச்சிருக்கோம்ண்ணா தண்ணி பிடிக்கிற இடம். ரெகுலரா பிடிக்கிற இடம் 4 டூ 5 இடம் (வீரப்பம்பாளையம், கருங்கல்பாளையம் ஆத்தோரம்...), மிச்சம் 3-4 இடம் அவுட்டர்ல (சித்தோடு, லட்சுமி நகர்)... அந்த கஸ்டமருக்கு நாங்க வீக்லி ஒன்ஸோ மன்த்லி ஒன்ஸோ பே பண்ணிடுவோம். அது நம்மளும் செலக்ட் பண்ற மாதிரி வேணும், டிரைவரும் செலக்ட் பண்ற மாதிரி வேணும்."*
  - *Requirements:*
    - Total **8 Pickup Points**: **4–5 Regular Borewells** (*Veerappampalayam*, *Karungalpalayam River-side (`கருங்கல்பாளையம் ஆத்தோரம்`)*, etc.) + **3–4 Outer Paid Borewells** (*Chithode (`சித்தோடு`)*, *Lakshmi Nagar (`லட்சுமி நகர்`)*, etc.).
    - Selectable by both **Owner/Manager** (on order booking) and **Driver** (on loading/trip completion, optionally geofence-assisted).
    - System must aggregate load counts and payable totals per pickup point for **weekly or monthly borewell-owner settlement**.
- **`03:36 – 06:22` | Driver Execution Flow & Motor Timer Review:**
  - Verified odometer start/end, arrival confirmation, and motor running timer / extra-minute surcharge calculation.
- **`06:23 – 10:35` | Driver Leave / Vehicle Swapping & Missing Driver Vehicle Dropdown (`08:00–08:42`):**
  - *Tamil Excerpt:* *"முக்காவாசி பேர் லீவ் போட்டுருவாங்கண்ணா, மாறி மாறி ஓட்டுவாங்க... டிரைவரோட ஃபார்ம்ல எந்த வண்டி ஓட்டுறாங்கன்னு வெஹிக்கிள் நம்பர் செலக்ட் பண்ற மாதிரி வேணும். அடுத்து கஸ்டமர் நேம், கெப்பாசிட்டி, பிரைஸ், கேஷா ஜிபேவா, மோட்டார் ரன்னிங் டைம்."*
  - *Gap Identified:* Driver's trip execution screen lacked a selector to pick which vehicle number the driver is currently operating (`மாறி மாறி ஓட்டுவாங்க`). Must add a **Vehicle Number selector dropdown** on the driver trip form + allow vehicle pre-assignment during order creation.
- **`12:56 – 13:45` | Simple `+ Extra / - Discount` Adjustment:**
  - *Tamil Excerpt:* *"டிஸ்கவுண்ட் / ஆட் அப்படின்னு சொல்லிட்டு மைனஸ் பிளஸ் மட்டும் கூட வச்சுக்கலாம்ண்ணா சிம்பிளா. பிளஸ் பண்ற மாதிரி இருந்தா ₹100 எக்ஸ்ட்ரா, இல்ல கூகுள் ரிவ்யூ போடுங்க ₹100 டிஸ்கவுண்ட் பண்றேன்னு சொன்னா மைனஸ் ₹100 போட்டுக்கலாம்."*
  - *Requirement:* Quick **`+ Extra Charge`** (e.g., extra hose/floor pumping `₹100`) and **`- Discount`** (e.g., Google Review promo `-₹100`) inputs on trip completion.
- **`13:46 – 20:40` | GPay / UPI `Pending` vs `Confirmed` Status + Screenshot Proof Upload:**
  - *Tamil Excerpt:* *"டிரைவர் போறாங்க, இறக்கிட்டு அவங்க ஜிபே பண்றாங்கன்னா ஓனரோட நம்பருக்கு தான் அனுப்பிச்சு விடுவாங்க... ஒரே நேரத்துல ரெண்டு வண்டி ₹600 இறக்கி இருப்பாங்க, எந்த கஸ்டமரோட பேமெண்ட்னு நமக்கு தெரியாது. கஸ்டமரே ஸ்கிரீன்ஷாட் எடுத்து அனுப்பிட்டாலும் சரி, இல்ல நம்ம டிரைவர் போட்டோ பிடிச்சு அப்லோட் பண்ணாலும் சரி... சில வீட்டுல அப்புறமா சாயந்திரம் ஜிபே பண்றேன்பாங்க, அப்ப பெண்டிங்னு காட்டணும். அப்புறம் ஸ்கிரீன்ஷாட் வந்ததும் டிரைவரோ மேனேஜரோ அப்லோட் பண்ணி கிளியர் பண்ணிக்கலாம்."*
  - *Real-World Pain Points Solved:*
    1. Multiple trucks deliver identical `₹600` loads at the same hour to Owner's / Kavin's bank account — impossible to match when checking bank statements 10 days later without an attached screenshot.
    2. Residential customers often pay via GPay hours later (*"will send in evening"*).
  - *Requirement:*
    - Payment modes on delivery: **`Cash`**, **`GPay / UPI`**, **`Account / Credit`**.
    - Under **`GPay / UPI`**, provide two sub-states: **`Pending Confirmation`** vs **`Confirmed / Received`**, plus **Camera/Gallery Payment Screenshot Upload** available both to the Driver at drop-off and to Manager/Owner later (when WhatsApp screenshot arrives) to verify & clear pending UPI collections.
- **`20:41 – 24:27` | Bank Account Setup & Future Expansion:**
  - Payment gateway integration is NOT needed now (`DK Enterprises` partnership netbanking KYC pending); individual accounts (`Kavin Axis`, `Kavin KVB`, `Kavin Canara`, `Sasi`, `Axis OD LOAN`, `DeekTex`) are used alongside expanding Cafe/Bakery toward Bangalore/Coimbatore.

### 2.4 Recording 4: `17-11-2026 13.03.m4a` (3m 09s)

- **`00:01 – 00:14` | Bug — Driver App Logout Button Hidden Inside Sub-Menu:**
  - *Tamil Excerpt:* *"டிரைவர் ஆப்ல லாக் அவுட் இல்ல... ஓ இங்க இருக்கு ஓகே ஓகே. சரி நான் அங்க இன்னொன்னு வெளியில வச்சர்றேன்."*
  - *Verified Root Cause in Codebase ([`app_scaffold.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/core/ui/app_scaffold.dart#L159-L203)):* Only `RippleRole.cafe` gets a direct Profile shortcut icon; drivers do not have an immediately visible top-bar `Sign Out` button (`Icons.logout_rounded`) without navigating via `More` tab -> `Profile`. Must add a visible 1-tap `Logout` button with confirmation dialog in driver dashboards / top AppBar.
- **`00:40 – 01:36` | Multi-Branch Setup for 2 Cafe Shops (`ARAN1` & `ARAN2`):**
  - *Tamil Excerpt:* *"இப்ப ரெண்டு கடைக்கு தனித்தனியா ஐடியா? நம்ம பிரான்ச் செட் பண்ணிக்கலாம்... யார் மேனேஜரோ இல்ல இன்சார்ஜ் அதை அசைன் பண்ணிக்கலாம், அவங்க அதை மட்டும் தான் பாத்துக்க முடியும்."*
  - *Requirement:* Create two branches under Aran Cafe (**`ARAN1`** and **`ARAN2`**) and assign separate branch managers/cashiers so each shop staff sees/operates only their assigned branch while Owner/Super Admin views and filters both.
- **`01:38 – 03:09` | Cafe POS Review & `The route api/v1/pos/orders could not be found.` 404 Bug (Screenshot 3):**
  - Client appreciates fast tap-to-add POS checkout and optional 80mm thermal printing (*"we only print receipts for customers who ask"*).
  - Tapping **Pay (`₹1,065.00`)** triggers red error snackbar: `The route api/v1/pos/orders could not be found.`
  - *Verified Root Cause in Codebase ([`pos_repository.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/pos/data/pos_repository.dart#L452-L540)):* When `POST /pos/orders` returns `404` against an older remote deployment (e.g., `dkenterprises.animazon.in`), `submitOrder()` attempts a single fallback to `ApiEndpoints.cafeOrders`, and if that legacy endpoint fails or rejects a field, line `539` (`return res;`) returns the **original `/pos/orders` 404 error**! On backend, we also must verify `POST /api/v1/pos/orders` has zero deployment/middleware blocks (`routes/api.php` lines `240-260`, `CafeApiController.php`, `PosApiController.php`) and add a bulletproof fallback chain in mobile (`POST /pos/orders` -> `POST /cafe/orders` -> `POST /sales`).

### 2.5 Recording 5: `17-11-2026 13.07.m4a` (9m 45s)

- **`00:00 – 01:15` | Walk-in Counter Billing Priority:**
  - Client confirms rapid counter billing + receipt total is primary daily workflow today; Table/KDS management is useful when expanding to a larger sit-down cafe.
- **`04:48 – 06:41` | Spreadsheet-Style Multi-Row Batch Daily Cash In/Out & Expense Entry (Screenshot 1):**
  - *Tamil Excerpt:* *"ஒவ்வொரு தடவையும் நீங்க சப்மிட் குடுக்க வேண்டாம் அப்படின்னா நான் லிஸ்ட் மாதிரியே குடுத்துர்றேன், ஜஸ்ட் டைப் பண்ணி டைப் பண்ணி நீங்க லாஸ்ட்டா சப்மிட் குடுத்தா போதும்... அந்த கூகுள் ஷீட் நான் அடிச்சிட்டு இருக்கேன்னு சொன்னேன்லண்ணா..."*
  - *Requirement:* Match client's **`2026 Accounts`** Google Sheet workflow inside Mobile & Web:
    - Live **Account Summary Strip**: `Kavin Axis`, `Sasi`, `Axis OD LOAN`, `DeekTex`, `Kavin KVB`, `Kavin Canara`, `CASH`, plus `Total IN` / `Total OUT`.
    - **Multi-Row Batch Ledger Form** where the user enters rows rapidly (`Date`, `IN / OUT`, `Company [TM WATER SUPPLY / DRINKAA / ARAN1 / ARAN2 / ARAN / FAMILY / COMMON]`, `Payment Account`, `Vehicle / Staff tag`, `Bill No`, `Amount`, `Description`), clicks **`+ Add Row`**, sees running `Total IN` / `Total OUT`, and submits all rows in **one tap (`Submit All`)**.
- **`06:42 – 08:55` | Missing Mobile Quick Purchase Bill / Regular Suppliers Screen:**
  - *Tamil Excerpt:* *"கிராசரிஸ், பால் (அமிர்தா), ஐஸ்கிரீம், மாவு ஐட்டம், பழமுதிர் சோலை, வெங்காயம் மூட்டை... சப்ளையர் நம்ம கடைக்கு சப்ளை பண்றவங்க ஒரு 10 வெண்டர்ஸ் ரெகுலராவே இருப்பாங்கண்ணா... பர்ச்சேஸ் பில்... சரி ஓகே இதுல ஆப்ஷன் நான் குடுக்கல."*
  - *Gap Verified:* Mobile Quick Action / Ops does not expose a **Quick Purchase Bill / Supplier Entry** screen despite `PurchaseApiController` & `PartnerApiController` existing on backend (`routes/api.php` lines `138-142`, `193-194`). Must build a fast mobile Purchase Bill / Supplier Payout flow pre-populated with regular vendors (*Amirtha Milk*, *Second Milk Vendor*, *Groceries*, *Ice Cream*, *Maida / Flour*, *Pazhamudir Cholai Fruits*, *Onion Bags*, *Chendhur Gas Agency*, *Prabu Auto Spares*, *Satha Workshop*) supporting `Cash` / `GPay` (with account selection) / `Supplier Credit`.

### 2.6 Recording 6: `17-11-2026 13.23.m4a` (5m 57s)

- **`00:00 – 01:55` | Bakery / Biscuit B2B Van Delivery Alongside Water Cans:**
  - *Tamil Excerpt:* *"கேன் இதே ஆட்டோ தான்ண்ணா, இதே பசங்க தான்... ஹாஃப் டே இதுவும் ஹாஃப் டே அதுவும், இல்லன்னா ஒரு நாள் இதுவும் ஒரு நாள் அதுவும் அப்படி பிளான் பண்றோம் இதே ஆட்டோல... பேக்கரி சப்ளை எல்லாமே இதுல பண்ணிக்கலாம். ஒவ்வொரு கடைக்கும் எத்தனை பீஸ் அப்படின்னு மட்டும் இறக்குறப்ப போடுற மாதிரி."*
  - *Fleet Usage Context:* 2 delivery vans under `DK Waters / Drinkaa` (`Tata Ace EV` for local city routes up to ~100 km range; `Tata Ace Diesel` for outer routes like Gobichettipalayam, Coimbatore, Salem). The same boys deliver water cans half-day/alternate-day and **Bakery / Biscuit boxes/pieces** to shops.
  - *Requirement:* Add a lightweight **`Bakery / Biscuit Supply`** item mode on the Can Van delivery screen so drivers can log **item name / pack**, **pieces/boxes delivered**, **rate**, and **Cash/GPay/Credit** at each shop stop without needing a separate app.
- **`02:04 – 02:32` | Clean Wipe of Demo Data Before Live Client Trial:**
  - *Tamil Excerpt:* *"இதுல டேட்டா எல்லாம் டெலீட் பண்ணி குடுக்கட்டா? ஆ டெலீட் பண்ணி குடுங்கண்ணா, கிளியர் பண்ணி குடுங்க. நான் பிரெஷ்ஷா ஒவ்வொன்னா என்ட்ரி பண்ணி பாக்குறேன்ண்ணா."*
  - *Requirement:* Provide a safe, idempotent **`erp:reset-for-golive`** Artisan command (and Super Admin API trigger) that truncates all dummy sales, sample water deliveries, sample tanker trips, sample POS orders, sample expenses/journal transactions while **preserving** core configuration: companies (`TMWS`, `DK Waters/Drinkaa`, `Aran Cafe`), branches (`ARAN1`, `ARAN2`), real fleet vehicles, 8 water pickup points, payment accounts, expense categories, tax/company settings, regular suppliers, and user logins.
- **`02:33 – 05:57` | Cashier POS Error Live Verification & Web Portal HRM/Categories Walkthrough:**
  - Confirmed Cashier POS checkout error and showed client Web Portal Expense Categories + HRM (`Department`, `Designation`, `Shift`, `Employee`, `Attendance`, `Payroll`).

---

## Part 3: Verified Codebase Root Causes & Exact Schema Specifications

### 3.1 Root Causes Verified Directly in Code

| # | Bug / Gap | Exact File & Line Verified | Technical Root Cause |
|---|---|---|---|
| **B1** | POS checkout shows `The route api/v1/pos/orders could not be found.` | [`pos_repository.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/pos/data/pos_repository.dart#L452-L540), [`routes/api.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/routes/api.php#L233-L260), [`CafeApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/CafeApiController.php#L58-L100) | Older remote deployments don't have `/api/v1/pos/orders` registered/cached cleanly; `submitOrder` falls back once to `/cafe/orders` with incomplete payload (`price` vs `unit_price`, missing `company_id`/`branch_id` resilience), and if `cafeOrders` returns an error it returns `res` (the 404 message from `/pos/orders`) instead of trying `/sales` or reporting `legacySale`'s response. |
| **B2** | `TMWS` Customer Onboarding leaks `Initial Cans Held` & `Security Deposit (₹)` | [`customer_form_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/customers/presentation/customer_form_screen.dart#L525-L596) | Section `3. Route Beat & Water Inventory` renders `_initialCansController` (`Initial Cans Held`) and `_depositController` (`Security Deposit (₹)`) unconditionally without checking `activeCompany?.industry == 'bulk_water'`. |
| **B3** | Customer `Opening Balance Due (₹15,000)` shows as `PAID` (`₹0 Due`) | [`WaterLogisticsApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php#L56-L173), [`customersList`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php#L3375-L3403), [`fleetLive`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php#L6311-L6330) | Neither `customersList()` nor `fleetLive()` selects `customers.opening_balance`, and `attachCustomerFinancialSummary()` never seeds `$stats[$cid]['total_sales']` with `customers.opening_balance`! Only `customerFullHistory()` (line `7332`) used `opening_balance` as timeline starting balance, while summary `$item->due_amount` remained `0`. |
| **B4** | Driver App has no immediately visible `Logout` button | [`app_scaffold.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/core/ui/app_scaffold.dart#L159-L203), [`tanker_driver_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/tanker_driver_dashboard_screen.dart), [`can_delivery_driver_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart) | `AppScaffold` `actions` only renders a profile button for `RippleRole.cafe`; drivers must tap `More` -> `Profile` -> `Sign Out`. Adding a visible Logout `IconButton` on `AppScaffold` / driver header solves it in 1 tap. |
| **G1** | Rotating Drivers cannot select Vehicle Number in Tanker Trip UI | [`tanker_trip_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/tanker_trip_screen.dart), [`tanker_trip_sheet_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/screens/tanker_trip_sheet_screen.dart), [`WaterLogisticsApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php#L996) | Backend accepts `tanker_id` (`line 996`), but driver screens lacked an interactive `Vehicle Number` selector populated with TMWS fleet variants + Outside Vehicle mode. |
| **G2** | No 8 Water Pickup / Borewell Points model/API/UI | [`water_tanker_trips` migration](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/database/migrations/2026_09_19_000005_create_water_logistics_dk_track_tables.php#L34) | Only a free-text `source_plant` string exists (`'Borewell Plant 1'`); no `water_pickup_points` master table, load counter, or weekly/monthly borewell settlement report exists. |
| **G3** | No `GPay Pending` vs `Confirmed` verification workflow + screenshot proof | [`water_can_deliveries`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Models/WaterCanDelivery.php#L9-L40), [`water_tanker_trips`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Models/WaterTankerTrip.php#L9-L43), [`can_sales_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/can_sales_screen.dart) | UPI payments immediately assume confirmed paid or credit without distinguishing `pending_verification` vs `confirmed` or storing/reconciling a uploaded screenshot receipt later by Driver/Manager/Owner. |
| **G4** | Single-row Expense form vs. `2026 Accounts` multi-row sheet & missing Quick Purchase Bill | [`quick_expense_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/expenses/presentation/quick_expense_screen.dart#L18-L115), [`ExpenseApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/ExpenseApiController.php#L58-L130) | `QuickExpenseScreen` submits 1 expense at a time, lacks `IN`/`OUT`, `Company` tag (`TMWS/DRINKAA/ARAN1/ARAN2/FAMILY/COMMON`), multi-account selector (`Kavin Axis`, `Sasi`, `Axis OD LOAN`, `DeekTex`, `Kavin KVB`, `Kavin Canara`, `CASH`), `Vehicle/Staff` tag, and `Bill No`; no Quick Purchase screen exists on mobile. |

### 3.2 Database Migrations & Guarded Schema Design

Create two clean migrations (every `Schema::table` wrapped in `if (!Schema::hasColumn(...))` checks and foreign-key-safe for SQLite test runs + MySQL production):

1. **`2026_11_17_000001_add_tmws_fleet_pickup_points_and_payment_proofs.php`:**
   - **New Table `water_pickup_points`:**
     - `id` (bigIncrements), `company_id` (unsignedBigInteger, nullable, indexed), `name` (string), `code` (string, nullable), `location_type` (string, default `'regular_borewell'` — `'regular_borewell'` | `'outer_paid_borewell'`), `address` (string, nullable), `latitude` (decimal 10,7 nullable), `longitude` (decimal 10,7 nullable), `geofence_radius_m` (integer default `200`), `owner_name` (string, nullable), `owner_phone` (string, nullable), `rate_per_load` (decimal 10,2 default `0`), `settlement_cycle` (string default `'own'` — `'own'` | `'weekly'` | `'monthly'`), `is_active` (boolean default `true`), `timestamps`.
   - **Update `water_tankers`:**
     - `company_id` (unsignedBigInteger nullable index), `vehicle_variant` (string nullable — `'Comet'`, `'Taurus'`, `'Eicher'`, `'Tata 407'`, `'Pondicherry Trailer'`, `'Outside Vehicle'`), `supported_capacities_json` (text/json nullable — e.g. `"[14]"`, `"[25]"`, `"[4,5,6,7,8,9]"`, `"[2,3,4,5]"`), `has_compartments` (boolean default `false`), `compartment_notes` (string nullable), `is_outsourced` (boolean default `false`), `vendor_name` (string nullable), `vendor_phone` (string nullable).
   - **Update `water_tanker_trips`:**
     - `pickup_point_id` (unsignedBigInteger nullable index), `pickup_point_name` (string nullable), `is_outsourced_vehicle` (boolean default `false`), `external_vehicle_no` (string nullable), `external_vendor_name` (string nullable), `vendor_payable_amount` (decimal 12,2 default `0`), `extra_charge` (decimal 12,2 default `0`), `discount_amount` (decimal 12,2 default `0`), `adjustment_note` (string nullable), `paid_amount` (decimal 12,2 default `0`), `payment_mode` (string default `'Credit'`), `payment_verification_status` (string default `'confirmed'` — `'not_applicable'` | `'pending_verification'` | `'confirmed'`), `payment_proof_path` (string nullable), `payment_verified_at` (timestamp nullable), `payment_verified_by` (unsignedBigInteger nullable).
   - **Update `water_can_deliveries`:**
     - `extra_charge` (decimal 12,2 default `0`), `discount_amount` (decimal 12,2 default `0`), `adjustment_note` (string nullable), `payment_verification_status` (string default `'confirmed'`), `payment_proof_path` (string nullable), `payment_verified_at` (timestamp nullable), `payment_verified_by` (unsignedBigInteger nullable), `item_category` (string default `'water_can'` — `'water_can'` | `'bakery_supply'`), `bakery_items_json` (text/json nullable), `bakery_pieces_delivered` (integer default `0`).

2. **`2026_11_17_000002_add_spreadsheet_ledger_and_multi_branch_columns.php`:**
   - **Update `expenses`:**
     - `entry_type` (string default `'OUT'` — `'IN'` | `'OUT'`), `company_tag` (string nullable — `'TM WATER SUPPLY'`, `'DRINKAA'`, `'ARAN1'`, `'ARAN2'`, `'ARAN'`, `'FAMILY'`, `'COMMON'`), `payment_account` (string default `'CASH'`), `vehicle_or_staff_tag` (string nullable), `bill_no` (string nullable), `entry_date` (date nullable).
   - **Update `suppliers`:**
     - `company_id` (unsignedBigInteger nullable index), `default_category` (string nullable — e.g., `'Milk'`, `'Groceries'`, `'Gas'`, `'Auto Spares'`), `is_regular_vendor` (boolean default `false`), `preferred_payment_mode` (string default `'Cash'`).

---

## Part 4: Master 4-Phase Implementation Plan (Structured for Flash Agents)

> **Concurrency Strategy for Flash Agents:**  
> - **Phase 1 Agent** (`Critical Bug Fixes`) touches `pos_repository.dart`, `customer_form_screen.dart`, `app_scaffold.dart`, driver dashboard headers, `WaterLogisticsApiController::attachCustomerFinancialSummary/customersList/fleetLive`.  
> - **Phase 2 Backend Agent + Phase 2 Mobile Agent** implement TMWS Fleet, 8 Pickup Points, Inline Walk-In Customer, Driver Vehicle Selector, `+Extra/-Discount`, and GPay Pending + Screenshot Proof.  
> - **Phase 3 Agent** implements `2026 Accounts` Multi-Row Batch Cash In/Out Ledger (`ExpenseApiController` + `quick_expense_screen.dart`) & Mobile Quick Purchase Bill / Regular Suppliers (`PurchaseApiController::quickStore` + `quick_purchase_screen.dart`).  
> - **Phase 4 Agent** implements `ARAN1`/`ARAN2` Multi-Branch setup, Bakery/Biscuit Van Delivery Beat on `Tata Ace EV`/`Tata Ace Diesel`, and `php artisan erp:reset-for-golive`.  
> *(Note: Backend Agents touching `routes/api.php` or `WaterLogisticsApiController.php` should run sequentially or merge cleanly via clearly isolated sections so no edit collides.)*

---

### PHASE 1: Critical Bug Fixes (Immediate Client Blockers)

#### Work Item 1.1 — Fix Cafe POS Checkout `api/v1/pos/orders` 404 Error (Screenshot 3)
- **Root Fix (Mobile — [`mobile/lib/features/pos/data/pos_repository.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/pos/data/pos_repository.dart#L452-L540)):**
  - In `PosRepository::submitOrder()`, when `POST ApiEndpoints.posOrders` fails with `_isNotFoundFailure(f)` (`404`):
    1. First try `POST ApiEndpoints.cafeOrders` (`/cafe/orders`) sending `company_id`, `branch_id`, `total_amount`, `grand_total`, `payment_method`, and `items` (with both `price` and `unit_price`). If `legacySale` succeeds, return `legacySale`.
    2. If `legacySale` ALSO fails with `404`, try fallback `POST ApiEndpoints.sales` (`/sales`) with canonical sale payload (`sale_status: 1`, `customer_id: customerId ?? 1`, `warehouse_id: warehouseId ?? 1`, `biller_id: billerId ?? 1`, `items`, `paid_amount`, `payment_method`).
    3. If any fallback fails with a non-404 validation/server error, return **that fallback's error**, NOT the stale `res` (`404 api/v1/pos/orders`)!
    4. Even for `hold == true`, if `404`, store held draft locally in SQLite cache so the tablet cashier never gets blocked!
- **Root Fix (Backend — [`routes/api.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/routes/api.php#L233-L260), [`CafeApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/CafeApiController.php#L58-L100)):**
  - Ensure `CafeApiController::storeOrder()` accepts both `total` / `total_amount` / `grand_total`, both `items.*.price` / `items.*.unit_price`, and respects `$branchId` (`X-Branch-ID` / `branch_id`).
  - Add top-level alias `Route::post('cafe-orders', [CafeApiController::class, 'storeOrder'])` inside `routes/api.php` and verify `CapabilityServiceProvider` does not accidentally reject super-admin / cashier calls when `operations.cafe_bakery` is queried on `Aran Cafe`.

#### Work Item 1.2 — Hide Water Can & Deposit Fields on `TMWS` (`bulk_water`) Customer Onboarding (Screenshot 2)
- **Target File:** [`mobile/lib/features/customers/presentation/customer_form_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/customers/presentation/customer_form_screen.dart#L525-L596)
- **Exact Changes:**
  - Read active company industry via `ref.watch(authNotifierProvider).activeCompany?.industry.toLowerCase()` (`final isBulkTanker = industry == 'bulk_water';`).
  - When `isBulkTanker == true`:
    - Change Section 3 header from `'3. Route Beat & Water Inventory'` to `'3. Tanker Route & Opening Balance'`.
    - Hide the `Row` containing `Initial Cans Held` (`_initialCansController`) and `Security Deposit (₹)` (`_depositController`) completely (`if (!isBulkTanker) ...[...]`), ensuring payload sends `0` for `initial_cans` and `deposit` when saving.
    - Keep `Assign Delivery Route Beat` (or filter to tanker routes/optional) and **`Opening Balance Due (₹)`** (`_openingBalanceController`) prominently visible!
    - Also inspect [`mobile/lib/screens/field_agent_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/screens/field_agent_screen.dart#L294) and apply the same `isBulkTanker` guard if shared with TMWS field agents.

#### Work Item 1.3 — Include `customers.opening_balance` in Customer `Due` / `Paid` Status & Map Pins (`12.19.m4a`)
- **Target File:** [`app/Http/Controllers/Api/V1/WaterLogisticsApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php)
- **Exact Changes:**
  1. In `customersList()` (`lines 3375-3392`), add `'customers.opening_balance'` and `'customers.credit_days'` (if column exists via `Schema::hasColumn`) to `->select(...)`.
  2. In `fleetLive()` (`lines 6250-6326` across ALL 3 role branches: `isTankerDriver`, `isCanDriver`, and `Owner/Admin`), add `'opening_balance'` to `customers` `->select(...)`.
  3. In `attachCustomerFinancialSummary()` (`lines 56-172`):
     - Collect each customer's `opening_balance` directly from `$item->opening_balance` (or batch-query `DB::table('customers')->whereIn('id', $customerIds)->pluck('opening_balance', 'id')` as guaranteed fallback so no caller can omit it!).
     - Initialize `$stats[$cid]['opening_balance'] = max(0.0, (float) $openingBal);` and add it to `$stats[$cid]['total_sales'] += $openingBal;` (while exposing `$item->opening_balance = round($openingBal, 2);`).
     - Wait: verify `customerFullHistory()` (`lines 6970-7352`) so `summaryCustomer->total_sales` and `summaryCustomer->due_amount` match identically and include standalone `payments` (e.g., opening-balance receipt settlements not linked to a `sale_id`) if any exist in `payments` / `deposits`!
     - Re-verify `enrichCustomerSummaries()` (`lines 480-507`):
       - `$dueAmount = round(max(0.0, $totalSales - $totalPaid), 2);`
       - `$item->payment_status = $overdueAmount > 0.01 ? 'overdue' : ($dueAmount > 0.01 ? 'due' : 'paid');`
       - When a customer is created with `opening_balance = 15000` and zero trips/sales yet: `total_sales = 15000.0`, `total_paid = 0.0`, `due_amount = 15000.0`, `payment_status = 'due'`!
       - Also check if an `Opening Balance` virtual entry should appear at the bottom of `recent_purchases` / `purchases` / `timeline` in `customerFullHistory()` when `$openingBal > 0.01` so clicking the customer shows *"Opening Balance (Pre-ERP): ₹15,000"*.

#### Work Item 1.4 — Visible 1-Tap Logout Button on Driver Main Screen (`13.03.m4a`)
- **Target Files:**
  - [`mobile/lib/core/ui/app_scaffold.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/core/ui/app_scaffold.dart#L159-L203)
  - [`mobile/lib/features/dashboard/presentation/tanker_driver_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/tanker_driver_dashboard_screen.dart)
  - [`mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart)
- **Exact Changes:**
  - In `AppScaffold` `AppBar.actions`: whenever `rippleRole == RippleRole.driver || rippleRole == RippleRole.cafe || rippleRole == RippleRole.fieldAgent` (every non-admin staff role, or always visible in a compact menu/icon), display a visible **`Icons.logout_rounded`** button (`Key('appbar_logout_btn')`, tooltip `'Sign Out'`) next to theme/sync!
  - Tapping it opens a 1-tap confirmation `AlertDialog` (*"Sign out of this shift? Pending offline records will stay saved."*) -> `"Sign Out"` -> calls `await ref.read(authNotifierProvider.notifier).logout();`.

---

### PHASE 2: Bulk Water Tanker (`TMWS`) Upgrades, 8 Pickup Points, Rotating Vehicle Selector & GPay Screenshot Verification

#### Work Item 2.1 — Seed Real TMWS Fleet Variants (`water_tankers`) & 8 Water Pickup Points (`water_pickup_points`)
- **Target Files:**
  - `database/migrations/2026_11_17_000001_add_tmws_fleet_pickup_points_and_payment_proofs.php`
  - `database/seeders/TmwsFleetAndPickupPointsSeeder.php`
  - New Model: `app/Models/WaterPickupPoint.php`
  - Update Model: [`app/Models/WaterTanker.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Models/WaterTanker.php) & [`app/Models/WaterTankerTrip.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Models/WaterTankerTrip.php)
- **Exact Fleet Records for TMWS (`bulk_water` company):**
  1. `Comet #1` (`Comet`, `capacity_kl: 14`, `capacity_liters: 14000`, `supported_capacities_json: [14]`, `has_compartments: false`, `compartment_notes: 'Single tank 14KL full load'`)
  2. `Comet #2` (`Comet`, `14 KL`, single full load)
  3. `Taurus #1` (`Taurus`, `25 KL`, `[25]`, `has_compartments: false`, `'Single tank 25KL full load'`)
  4. `Taurus #2` (`Taurus`, `25 KL`, single full load)
  5. `Taurus #3` (`Taurus`, `25 KL`, single full load)
  6. `Eicher #1` (`Eicher`, `9 KL`, `[4, 5, 6, 7, 8, 9]`, `has_compartments: true`, `'Compartments: 4KL–9KL flexible local/medium loads'`)
  7. `Eicher #2` (`Eicher`, `9 KL`, `[4, 5, 6, 7, 8, 9]`, `has_compartments: true`)
  8. `Tata 407` (`Tata 407`, `5 KL`, `[2, 3, 4, 5]`, `has_compartments: true`, `'2 Compartments (2KL + 3KL)'`)
  9. `Pondicherry Big Tanker` (`Pondicherry Trailer`, `25 KL`, `[25, 30, 35, 40]`, `has_compartments: false`, `'25ft outer industrial/construction vehicle (not for narrow city streets)'`)
  10. Special tie-up option in UI: **`Outside / Tie-Up Vehicle (வெளி வண்டி)`** (`is_outsourced_vehicle: true`) — prompts for `external_vehicle_no`, `external_vendor_name`, and `vendor_payable_amount` (`driver/trip cost`).
- **Exact 8 Seeded Water Pickup Points (`water_pickup_points`):**
  - Regular Points (`location_type: 'regular_borewell'`, `settlement_cycle: 'own'` or `'monthly'`):
    1. `Veerappampalayam Regular Borewell` (`PP-VPM`)
    2. `Karungalpalayam River-Side Bore` (`PP-KPR`, `கருங்கல்பாளையம் ஆத்தோரம்`)
    3. `Solar Borewell Point` (`PP-SLR`)
    4. `Surampatti Regular Point` (`PP-SRP`)
    5. `Mettukadai Regular Point` (`PP-MKD`)
  - Outer Paid Points (`location_type: 'outer_paid_borewell'`, `settlement_cycle: 'weekly'` or `'monthly'`):
    6. `Chithode Outer Pickup` (`PP-CHT`, weekly/monthly borewell settlement)
    7. `Lakshmi Nagar Outer Pickup` (`PP-LKN`, weekly/monthly borewell settlement)
    8. `Perundurai Road Outer Pickup` (`PP-PND`, weekly/monthly borewell settlement)

#### Work Item 2.2 — Pickup Points API, Load Settlement Report & Enhanced Trip Sheet / Order Backend
- **Target Files:** [`routes/api.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/routes/api.php#L202-L231), [`app/Http/Controllers/Api/V1/WaterLogisticsApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php)
- **New & Updated Endpoints:**
  1. `GET /api/v1/water/pickup-points` (`pickupPointsIndex`): Returns active `water_pickup_points` for the company + today/week/month load counts & vendor payable totals (`SUM(vendor_payable)` / `COUNT(trips)`) per borewell point.
  2. `POST /api/v1/water/pickup-points` (`storePickupPoint`): Allows Owner/Admin to add/edit borewell locations, coordinates (`latitude`, `longitude`), `rate_per_load`, and `settlement_cycle` (`own`, `weekly`, `monthly`).
  3. Update `driverManifest()` / `routes()` / `fleetLive()`: Include `tankers` list (all active TMWS trucks with `vehicle_variant`, `capacity_kl`, `supported_capacities`), `pickup_points` list, and pending GPay verifications count!
  4. Update `storeTripSheet()` & `storeTankerOrder()` & `processTripOrder()`:
     - **Inline Walk-In Customer Auto-Creation:** If `customer_id` is empty/null AND `walk_in_customer_name` (or `customer_name`) + `walk_in_customer_phone` (or `customer_phone`) are submitted, automatically `firstOrCreate` a `customers` record under `$companyId` (`type: 'walk_in'`, `address/city: $request->input('location_area') ?? $destinationSite`, `latitude/longitude` if supplied) instead of dumping onto generic ID 1!
     - **Rotating Driver Vehicle Override:** Accept `tanker_id` / `vehicle_number` from Driver on `processTripOrder` as well as `storeTripSheet`, updating the trip's `tanker_id`.
     - **Outside Tie-Up Vehicle Fields:** Accept `is_outsourced_vehicle`, `external_vehicle_no`, `external_vendor_name`, `vendor_payable_amount`. Store cleanly on `water_tanker_trips` (and in `notes` JSON for legacy compatibility) so customer billing (`grand_total`) still goes under `TMWS` while Owner reports show net margin (`trip_rate - vendor_payable_amount`).
     - **Pickup Point & Adjustments:** Accept `pickup_point_id`, `pickup_point_name`, `extra_charge`, `discount_amount`, `adjustment_note`. Compute final billable total `= max(0, base_trip_rate + motor_pumping_charge + extra_charge - discount_amount)`.
     - **GPay / UPI `Pending` vs `Confirmed` + Screenshot Upload (`MultipartFile` or `payment_proof_base64`):**
       - Save uploaded proof image to `public/uploads/payment_proofs/{Ymd}/{trip_or_delivery_no}.jpg`.
       - If `payment_mode` contains `'GPay'`/`'UPI'` and `payment_status_flag == 'pending_verification'`, set `payment_verification_status = 'pending_verification'`, `paid_amount = 0` (until verified!), or record `claimed_upi_amount` in metadata, so it clearly shows as **GPay Pending Verification** (`பெண்டிங்`) for Owner/Manager/Driver follow-up! Once confirmed (with or without screenshot), update `payment_verification_status = 'confirmed'`, record `paid_amount`, update `sales.paid_amount` + insert `payments` row via `VerticalSaleSyncService`.
  5. New Endpoint `POST /api/v1/water/payments/verify-proof` (`verifyWaterPaymentProof`):
     - Accepts `entity_type` (`'tanker_trip'` | `'can_delivery'`), `entity_id`, `status` (`'pending_verification'` | `'confirmed'`), `paid_amount`, `payment_account` (optional, e.g., `'GPAY - KAVIN AXIS'`), and `proof_image` (multipart file or base64).
     - Allows Customer WhatsApp screenshots to be uploaded **1–2 days later** by Owner, Manager, or Driver to convert a `Pending GPay` delivery into `Confirmed Paid`!

#### Work Item 2.3 — Mobile UI Upgrades for TMWS Order Creation & Driver Trip Sheet
- **Target Files:**
  - [`mobile/lib/core/network/api_endpoints.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/core/network/api_endpoints.dart)
  - [`mobile/lib/features/operations/presentation/water_order_helpers.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/water_order_helpers.dart) (`showCreateTankerOrderSheet`, `showAdjustWaterOrderSheet`)
  - [`mobile/lib/features/operations/presentation/tanker_trip_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/tanker_trip_screen.dart)
  - [`mobile/lib/screens/tanker_trip_sheet_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/screens/tanker_trip_sheet_screen.dart)
  - [`mobile/lib/features/operations/presentation/can_sales_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/can_sales_screen.dart)
- **Exact Mobile UX Features:**
  1. **`Create Tanker Order` Sheet (`showCreateTankerOrderSheet`) & Driver Trip Form:**
     - **Customer Selector with Inline `+ Walk-in / New Customer` Toggle:** Select existing customer OR toggle `"Walk-in / New Customer"` right inside the Customer Name box to type **Name**, **Phone Number**, **Area/Location**, and **Custom Agreed Price (`₹`)**.
     - **Fleet Vehicle Dropdown + Compartments:** Dropdown lists all TMWS vehicles (`TN ... Comet 14KL`, `TN ... Taurus 25KL`, `TN ... Eicher 9KL [4–9KL]`, `TN ... Tata 407 5KL [2–5KL]`, `TN ... Pondicherry 25ft Trailer`) + **`Outside / Tie-Up Vehicle (வெளி வண்டி)`** choice. Choosing `Eicher` shows quick KL chips `[4, 5, 6, 7, 8, 9]`; `Tata 407` shows `[2, 3, 4, 5]`; `Outside Vehicle` reveals `External Vehicle No`, `Vendor Name`, `Vendor Payable Rate (₹)`.
     - **8 Water Pickup Points Selector:** Dropdown showing the 8 seeded borewell locations (`Veerappampalayam`, `Karungalpalayam River-side`, `Chithode Outer`, etc.) selectable on Order Creation AND editable on Driver Execution.
  2. **Driver Trip Execution (`TankerTripScreen` & `TankerTripSheetScreen`):**
     - Visible **Vehicle Number dropdown at top of form** so drivers who swap trucks or cover leave immediately choose which vehicle they are driving today.
     - **`+ Extra / - Discount` Quick Stepper & Reason Note:** Two compact pills (`+ Add Extra ₹` & `- Discount ₹`) + short note (`Hose 2nd floor` / `Google Review`), dynamically updating Net Payable.
     - **Payment Mode & GPay Verification Controls (both Tanker & Can `CanSalesScreen`):**
       - Radio/chip modes: **`Cash`**, **`GPay / UPI`**, **`Account / Credit`**.
       - When **`GPay / UPI`** is tapped:
         - Status toggle: **`Pending (Pay Later / Verify)`** vs **`Confirmed (Received)`**.
         - Button **`Upload / Capture GPay Screenshot`** (`image_picker` camera/gallery) showing thumbnail preview and uploading proof to `/api/v1/water/payments/verify-proof` or inline in trip completion.
     - Add a **`Pending GPay Proofs`** badge/drawer on Admin & Manager dashboards + Customer 360° sheet so pending UPI entries show an `"Upload Proof / Verify"` action button!

---

### PHASE 3: `2026 Accounts` Spreadsheet Multi-Row Cash In/Out & Mobile Quick Purchase Bill

#### Work Item 3.1 — Backend `2026 Accounts` Multi-Row Batch Ledger & Multi-Account Summary
- **Target Files:**
  - `database/migrations/2026_11_17_000002_add_spreadsheet_ledger_and_multi_branch_columns.php`
  - [`app/Models/Expense.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Models/Expense.php)
  - [`app/Http/Controllers/Api/V1/ExpenseApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/ExpenseApiController.php)
  - [`routes/api.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/routes/api.php#L270-L275)
- **Exact API Additions:**
  1. `POST /api/v1/expenses/batch` (`ExpenseApiController::storeBatch`):
     - Accepts `rows`: array of `{ entry_date, entry_type ('IN'|'OUT'), company_tag, payment_account, vehicle_or_staff_tag, bill_no, amount, category, description }`.
     - Validates every row inside one `DB::transaction`, creates linked `Expense` rows (and for `'IN'` rows optionally posts cash/bank inflow voucher in `AccountingService` / cash-in ledger without losing expense reporting parity), returning created rows + updated totals.
  2. `GET /api/v1/expenses/accounts-summary` (`ExpenseApiController::accountsSummary`):
     - Returns Opening, Total IN, Total OUT, and Current Balance grouped by client's **7 exact accounts**:
       - `Kavin Axis` (`GPAY - KAVIN AXIS`)
       - `Sasi`
       - `Axis OD LOAN`
       - `DeekTex`
       - `Kavin KVB`
       - `Kavin Canara`
       - `CASH`
     - Also returns company tag breakdown (`TM WATER SUPPLY`, `DRINKAA`, `ARAN1`, `ARAN2`, `ARAN`, `FAMILY`, `COMMON`) and known `VEHICLE / STAFFS` tags (`platina`, `SURESH`, `TN 47 M 4585`, `RAJA`, plus active fleet vehicle numbers & employees).

#### Work Item 3.2 — Mobile `QuickExpenseScreen` Upgraded with Multi-Row Batch Sheet (`2026 Accounts` Parity)
- **Target Files:**
  - [`mobile/lib/core/network/api_endpoints.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/core/network/api_endpoints.dart) (`expensesBatch`, `expensesAccountsSummary`)
  - [`mobile/lib/features/expenses/presentation/quick_expense_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/expenses/presentation/quick_expense_screen.dart)
- **Exact UI Upgrades:**
  - Keep fast 1-entry mode for drivers, and add a top segmented tab **`Single Entry` | `Sheet Batch (Multi-Row)`** (defaulting Admin to **`Sheet Batch`** or selectable):
    - **Top Summary Strip:** Horizontal scrollable chips matching Screenshot 1 (`Total IN ₹...`, `Total OUT ₹...`, plus account balances `Kavin Axis`, `Kavin KVB`, `Kavin Canara`, `Sasi`, `Axis OD LOAN`, `DeekTex`, `CASH`).
    - **Spreadsheet Row Builder Cards (Horizontally & Vertically Ergonomic on Tablet/Phone):**
      - Each row contains: `#S.NO`, `Date` (default today), `IN / OUT` toggle pill (`OUT` red / `IN` green), `Company` dropdown (`TM WATER SUPPLY`, `DRINKAA`, `ARAN1`, `ARAN2`, `ARAN`, `FAMILY`, `COMMON`), `Payment Account` dropdown (`GPAY - KAVIN AXIS`, `CASH`, `KAVIN KVB`, `KAVIN CANARA`, `SASI`, `AXIS OD LOAN`, `DEEKTEX`), `Amount`, `Vehicle / Staff` autocomplete chip/dropdown, `Bill No`, `Description`.
      - **`+ Add Row`** appends an empty row pre-filled with the last row's `Date`, `Company`, and `Payment Account` for ultra-fast continuous typing (just like Google Sheets!).
      - Sticky footer shows live count (`N rows · IN ₹X · OUT ₹Y`) and **`Submit All Rows`** button (with offline Outbox fallback if offline).

#### Work Item 3.3 — Mobile Quick Purchase Bill / Regular Supplier Entry Screen
- **Target Files:**
  - Backend: [`app/Http/Controllers/Api/V1/PurchaseApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/PurchaseApiController.php) (add `quickStore()` & `regularVendors()`), [`routes/api.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/routes/api.php#L138-L143)
  - Mobile: New screen `mobile/lib/features/operations/presentation/quick_purchase_screen.dart` + route `/operations/quick-purchase` in `app_router.dart` + tile in `QuickActionSheet` / `ExecutiveDashboardScreen` / `CashierDashboardScreen` / `More` hub.
- **Exact Regular Vendors & Purchase Fields:**
  - Pre-seeded quick-pick suppliers (stored in `suppliers` with `is_regular_vendor = true`):
    1. *Amirtha Milk* (`Milk`)
    2. *Local Milk Vendor 2* (`Milk`)
    3. *Sri Murugan Groceries* (`Groceries`)
    4. *Ice Cream Distributor* (`Ice Cream`)
    5. *Maida & Bakery Flour Mill* (`Flour`)
    6. *Pazhamudir Cholai Fruits* (`Fruits`)
    7. *Onion & Vegetable Wholesale* (`Vegetables`)
    8. *Chendhur Gas Agency* (`Commercial LPG`)
    9. *Prabu Auto Spares* (`Fleet Maintenance`)
    10. *Satha Workshop - Sakthi Auto* (`Fleet Maintenance`)
    *(Plus inline `+ Add Supplier` option)*
  - Mobile Form Fields:
    - **Supplier Selector** (quick filter pills or dropdown + inline new supplier)
    - **Company / Branch Tag** (`ARAN1`, `ARAN2`, `TMWS`, `DRINKAA`, `COMMON`)
    - **Bill No & Date**
    - **Item / Description & Total Amount (`₹`)**
    - **Payment Status & Mode:** `Cash` | `GPay (Account)` | `Credit (Supplier Payables Later)` + optional bill photo capture.

---

### PHASE 4: Multi-Branch (`ARAN1`/`ARAN2`), Bakery/Biscuit Van Beat & Go-Live Clean Reset

#### Work Item 4.1 — Multi-Branch Setup for `ARAN1` & `ARAN2`
- **Target Files:**
  - New Seeder: `database/seeders/AranMultiBranchSeeder.php`
  - [`app/Http/Middleware/ResolveCompanyContext.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Middleware/ResolveCompanyContext.php)
  - [`app/Http/Controllers/Api/V1/MeApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/MeApiController.php)
  - [`mobile/lib/features/dashboard/presentation/cashier_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/cashier_dashboard_screen.dart) & [`mobile/lib/features/operations/presentation/cafe_pos_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/cafe_pos_screen.dart)
- **Exact Behavior:**
  - Ensure **Aran Cafe / Bakery** (`company_id` resolved dynamically by code/profile `cafe_bakery`) has two active `company_branches`:
    - **`ARAN1` (`Aran Cafe - Shop 1`)**
    - **`ARAN2` (`Aran Cafe - Shop 2`)**
  - Each branch gets its own `warehouses`, `document_series`, and `company_user_branches` assignment for its shop cashier/incharge (`aran1_manager`, `aran2_manager`).
  - Non-admin branch users (`aran1_manager`, `aran2_manager`) are locked to their assigned `branch_id` across POS orders, expenses, purchases, and cash drawers.
  - Owner / Super Admin sees a 1-tap **`ARAN1` | `ARAN2` | `All Branches`** branch switcher pill directly on Cafe POS and Admin Dashboard headers!

#### Work Item 4.2 — Bakery / Biscuit B2B Van Delivery Beat (`Tata Ace EV` & `Tata Ace Diesel`)
- **Target Files:**
  - Backend: [`WaterLogisticsApiController.php`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/app/Http/Controllers/Api/V1/WaterLogisticsApiController.php) (`storeCanDelivery` / `closeCanOrder`) + [`water_can_routes` seeder](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/database/seeders/)
  - Mobile: [`mobile/lib/features/operations/presentation/can_sales_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/operations/presentation/can_sales_screen.dart) & [`mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart`](file:///f:/PROJECTS/WEBSITES/DK%20Enterprises/mobile/lib/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart)
- **Exact Features:**
  - Seed the client's 2 real delivery vans cleanly under `water_can_routes`:
    1. **`Tata Ace EV (City Local <100km)`** (`Erode Local · Water + Bakery`)
    2. **`Tata Ace Diesel (Outer Highway)`** (`Gobi / Coimbatore / Salem · Water + Bakery`)
  - On `CanSalesScreen` (Delivery Stop Entry), add a clean top mode selector:
    - **`Water Cans`** (existing `Delivered` / `Empties Returned` / `Damaged` + container size)
    - **`Bakery & Biscuits (Van Supply)`** (new lightweight tabular entry where driver picks items like *Sweet Biscuits Box*, *Salt Biscuits Pack*, *Tea Cake / Bun Tray*, *Rusks*, logs **Pieces / Boxes Delivered**, rate per piece, and collects `Cash` / `GPay Pending or Confirmed` / `Shop Credit`).
    - When submitting Bakery B2B supply, persist `item_category = 'bakery_supply'`, `bakery_items_json`, `bakery_pieces_delivered`, and sync into ERP `sales` cleanly!

#### Work Item 4.3 — Go-Live Clean Demo Data Reset Command & API (`erp:reset-for-golive`)
- **Target Files:**
  - New Command: `app/Console/Commands/ErpResetForGoliveCommand.php` (signature: `php artisan erp:reset-for-golive {--force} {--seed-masters}`)
  - Controller / Route: `POST /api/v1/admin/reset-demo-data` (Super Admin ONLY, requires password/confirmation token `'RESET-FOR-LIVE'`).
- **Exact Preserved vs. Wiped Tables:**
  - **TRUNCATE / DELETE (All Demo & Test Transactions):**
    - `sales`, `product_sales`, `sale_drafts`, `sales_orders`, `commercial_order_items`, `commercial_order_allocations`
    - `payments`, `deposits`
    - `purchases`, `product_purchases`
    - `returns`, `product_returns`, `return_purchases`, `purchase_product_return`
    - `expenses`, `journal_entries`, `journal_items`, `account_allocations`, `account_open_items`
    - `water_tanker_trips`, `water_can_deliveries`, `water_can_inventories` (or reset `total_cans_held = 0, deposit_held = 0`), `water_can_plant_intakes`, `water_can_spot_audits`, `driver_cash_surrenders`, `delivery_schedules`
    - `fleet_trip_logs`, `gps_pings` (if present), `cafe_cash_drawers`, `cafe_ingredient_usages`, `cash_registers`
    - `gst_transaction_projections`, `notifications`
    - Reset `customers` (except `id = 1` Walk-in Customer OR keep customers if `--keep-customers` flag passed; default resets dummy seeded customers unless real onboarded customers exist), keeping non-demo real users.
  - **PRESERVE & RE-SEED CLEAN MASTERS (`--seed-masters`):**
    - `companies`, `company_branches` (including `ARAN1` & `ARAN2`), `company_industry_settings`, `company_capabilities`
    - `users`, `roles`, `permissions`, `company_user`, `company_user_branches`
    - `water_tankers` (TMWS 9 real trucks), `water_can_routes` (`Tata Ace EV` & `Tata Ace Diesel`), `water_pickup_points` (8 Erode pickup points)
    - `accounts` (`Kavin Axis`, `Sasi`, `Axis OD LOAN`, `DeekTex`, `Kavin KVB`, `Kavin Canara`, `CASH`)
    - `expense_categories`, `tax_categories`, `chart_of_accounts`, `document_series`, `fiscal_years`
    - `suppliers` (regular cafe/fleet vendors) & real product catalog items.

---

## Part 5: Flash-Agent Execution Order & Verification Checklist

### Step-by-Step Delegation Plan for Flash Agents
1. **Batch A (Backend Core — Phase 1B + Phase 2 Backend + Phase 3 Backend + Phase 4 Backend):**
   - **Flash Agent 1 (Migrations, Models & Seeders):** Write both migrations (`2026_11_17_000001_...` & `2026_11_17_000002_...`), `WaterPickupPoint` model, update `WaterTanker` / `WaterTankerTrip` / `WaterCanDelivery` / `Expense` / `Supplier` models, and create seeders (`TmwsFleetAndPickupPointsSeeder`, `AranMultiBranchSeeder`, `ErpResetForGoliveCommand`).
   - **Flash Agent 2 (Controllers & API Routes):** Update `WaterLogisticsApiController.php` (`opening_balance` fix, pickup points endpoints, inline walk-in customer, outsourced tanker fields, `+extra/-discount`, `verifyWaterPaymentProof`), `ExpenseApiController.php` (`storeBatch`, `accountsSummary`), `PurchaseApiController.php` (`quickStore`, `regularVendors`), `CafeApiController.php`, and `routes/api.php`.
2. **Batch B (Mobile Bug Fixes & Features — Parallel Safe Across Separate Screen Files):**
   - **Flash Agent 3 (Phase 1 Fixes + Phase 2 Tanker & Can Screen Upgrades):** Update `pos_repository.dart`, `customer_form_screen.dart`, `app_scaffold.dart`, `api_endpoints.dart`, `water_order_helpers.dart`, `tanker_trip_screen.dart`, `tanker_trip_sheet_screen.dart`, and `can_sales_screen.dart`.
   - **Flash Agent 4 (Phase 3 Spreadsheet Batch & Quick Purchase + Phase 4 Bakery Van & Branch Switcher):** Update `quick_expense_screen.dart`, create `quick_purchase_screen.dart`, wire route `/operations/quick-purchase` in `app_router.dart` & `quick_action_sheet.dart`, update `can_delivery_driver_dashboard_screen.dart` & `cafe_pos_screen.dart`.
3. **Batch C (Verification & Regression Tests):**
   - **Backend Verification:**
     - `php -l` across every touched PHP file.
     - Feature PHPUnit tests covering: Customer `opening_balance = 15000` -> `due_amount = 15000` & `payment_status = 'due'`; TMWS 8 pickup points & outsourced tanker fields; GPay `pending_verification` -> `verify-proof` -> `confirmed`; `POST /api/v1/expenses/batch`; `POST /api/v1/purchases/quick`; `ARAN1`/`ARAN2` branch isolation; `erp:reset-for-golive`.
   - **Mobile Verification:**
     - `flutter analyze` (once Flutter SDK is restored in environment) and widget/unit tests covering: TMWS Customer form hiding `Initial Cans Held` & `Security Deposit`; Driver AppBar visible Logout button; POS `404` fallback; `QuickExpenseScreen` multi-row batch add/submit; `TankerTripScreen` vehicle dropdown & GPay pending/screenshot upload.
