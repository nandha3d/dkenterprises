# DK Track — Field Servant & Driver Mobile App Specification

## 1. UX Design Philosophy & Ground Speed Law

The **DK Track Mobile Application** is engineered for Android smartphones operated by ground delivery boys, helper staff, and lorry drivers. 

### Core Ground Rules:
1. **"Bus Ticket Machine" Speed**: Delivery entries must take **under 15 to 20 seconds** per stop. Zero mandatory text typing on the road.
2. **GPS-Enabled Telematics & Route Logging**: Background GPS service records the delivery vehicle's route, stops, dwell time, and speed profile continuously.
3. **On-The-Spot Payment Tracking with Exact Timestamp**: Captures cash/UPI/credit with instant GPS coordinates and exact seconds timestamp.
4. **Multi-Refill Plant Intakes**: Delivery agents can record **2, 3, or more plant refills** throughout the shift without interrupting daily route tally.
5. **100% Offline-Functional**: Uses local SQLite database with background synchronization when 4G/Wi-Fi connects.

---

## 2. Multi-Plant Refill Workflow (Logging Cans on the Fly)

Delivery agents often return to the bottling plant multiple times a day (*Image 3: Load 1: 72, Load 2: 84, Load 3: 57*):

```
+-------------------------------------------------------------+
|  ஆலை கேன் ஏற்றுதல் (Plant Intake) · லோடு #2                  |
+-------------------------------------------------------------+
|  ஆலை பெயர்: Main RO Water Treatment Plant                   |
|                                                             |
|  ஏற்றப்பட்ட கேன்கள் எண்ணிக்கை (Cans Loaded):                 |
|  +-------+   +-------------------------------+   +-------+  |
|  |  - 5  |   |              84               |   |  + 5  |  |
|  +-------+   +-------------------------------+   +-------+  |
|                                                             |
|  ஆலை ரசீது எண் (Slip No): [ RO-2026-9941                  ] |
|                                                             |
|  +-------------------------------------------------------+  |
|  |        📸 ஆலை ரசீது படம் எடு (Snap Plant Slip)        |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  +-------------------------------------------------------+  |
|  |           ✅ ஏற்றுதல் உறுதிசெய் (CONFIRM LOAD)          |  |
|  +-------------------------------------------------------+  |
|  மொத்த ஏற்றப்பட்ட கேன்கள்: 72 + 84 = 156 கேன்கள் 🟢           |
+-------------------------------------------------------------+
```

---

## 3. Ultra-Fast Customer Delivery & Payment Entry (<15 Seconds)

Directly modeled on the actual delivery sheet (*Image 3*) with customers like *Black Pekoe Tea, One Cup Tea, Balaji Cafe, Aran Cafe*:

```
+-------------------------------------------------------------+
|  DK TRACK · வாட்டர் கேன் பிரிவு            [தமிழ் / EN] [🌐] |
|  வண்டி: TN 38 BX 4412 (Tata Ace)     ஸ்டாக்: 25 / 213 Cans |
+-------------------------------------------------------------+
|                                                             |
|  [📍 GPS பரிந்துரை: அரண் கஃபே - 1 (Aran Cafe - 1)]          |
|  அல்லது கடையைத் தேர்ந்தெடுக்கவும்: [ Balaji Cafe        ▼ ]  |
|                                                             |
|  டெலிவரி கேன் (Loaded Cans):                                |
|  +-------+   +-------------------------------+   +-------+  |
|  |  - 1  |   |              14               |   |  + 1  |  |
|  +-------+   +-------------------------------+   +-------+  |
|                                                             |
|  திரும்பிய காலி கேன் (Empty Returned):                       |
|  +-------+   +-------------------------------+   +-------+  |
|  |  - 1  |   |              14               |   |  + 1  |  |
|  +-------+   +-------------------------------+   +-------+  |
|                                                             |
|  மொத்தத் தொகை: ₹ 280 (14 × ₹20)                             |
|                                                             |
|  பணம் செலுத்தும் முறை (Payment Mode):                        |
|  +--------------------+  +--------------------+             |
|  |  💵 பணம் (CASH)   |  |   📱 GPAY / UPI    |             |
|  +--------------------+  +--------------------+             |
|  +--------------------+  +--------------------+             |
|  |  ⏳ கடன் (CREDIT)  |  |  📸 ரசீது படம்     |             |
|  +--------------------+  +--------------------+             |
|                                                             |
|  +-------------------------------------------------------+  |
|  |           ✅ பதிவு செய் (CONFIRM DELIVERY)             |  |
|  +-------------------------------------------------------+  |
|  நேரம்: 09:34:12 AM | ஜிபிஎஸ் துல்லியம்: 4.2m 🟢            |
+-------------------------------------------------------------+
```

---

## 4. Bulk Tanker Driver Trip Sheet (With Surcharges)

Supports **any tanker capacity** (9KL, 16KL, 24KL, 30KL, 40KL) and toggles dynamic surcharges on-site:

```
+-------------------------------------------------------------+
|  ட்ரிப் சீட் · பயணம் முடிவு (Trip Completion)               |
+-------------------------------------------------------------+
|  பார்ட்டி: Texvalley Corporate | கொள்ளளவு: 40.0 KL          |
|  தொடக்க ஓடோமீட்டர்: 1,42,810 km                              |
|  முடிவு ஓடோமீட்டர்:   [ 142865     ] km (மொத்தம்: 55 km)     |
|                                                             |
|  கூடுதல் கட்டணங்கள் (Ground Surcharges):                     |
|  [✓] மோட்டார் பயன்பாடு (Motor Used?):  + ₹ 250               |
|  [✓] காத்திருப்பு நேரம் (Waiting Time): [ 2.0  ] மணி (+ ₹300) |
|  [ ] தொலைதூர கட்டணம் (Long Distance):   [ 0    ] km          |
|  [✓] டோல்கேட் ரசீது (Tollgate / Misc):  + ₹ 180               |
|                                                             |
|  மொத்த பில் தொகை: ₹ 3,230.00                                |
|                                                             |
|  +-------------------------------------------------------+  |
|  |      📸 கேட் பாஸ் / வாடிக்கையாளர் கையெழுத்து எடு      |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  +-------------------------------------------------------+  |
|  |           ✅ பயணத்தை முடி (COMPLETE TRIP)             |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
```

---

## 5. Continuous GPS Telematics, Stoppage & Fuel Verification

1. **Background GPS Tracking**:
   - Transmits location every 30–45 seconds with speed, heading, and battery level.
   - Detects stops: When the vehicle remains stationary (<2 km/h) for >3 minutes, creates a `vehicle_route_stops` record.
2. **Dwell & Rest Time Alerts**:
   - If a driver halts at an unmapped location (e.g. tea stall) for >30 minutes, the app logs a rest break with timestamp.
3. **Accurate Distance for Fuel Audit**:
   - The app accumulates exact GPS road kilometres, providing an indisputable benchmark to verify claimed fuel bills and prevent inflated claims.
