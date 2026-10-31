import { Vehicle, TankerTrip, PlantIntake, CanDelivery, RouteStop, BakeryPurchase, BakeryClosing, CustomerCreditAccount } from '../types';

export const initialVehicles: Vehicle[] = [
  {
    id: 1,
    vehicle_number: 'TN 38 BX 4412',
    vehicle_type: 'can_truck',
    capacity_cans: 70,
    driver_name: 'Raja',
    driver_phone: '9842100006',
    status: 'moving',
    last_speed_kmh: 18.2,
    last_latitude: 11.018221,
    last_longitude: 76.964119,
    last_ping_ago: '14s ago',
    current_trip: 'Race Course - Gandhipuram (Stop #14)'
  },
  {
    id: 2,
    vehicle_number: 'TN 34 AF 4954',
    vehicle_type: 'tanker',
    capacity_kl: 24.0,
    driver_name: 'Suresh',
    driver_phone: '9842100005',
    status: 'at_destination',
    last_speed_kmh: 0.0,
    last_latitude: 11.042100,
    last_longitude: 77.011200,
    last_ping_ago: '22s ago',
    current_trip: 'Texvalley Corporate Campus (Trip 3)'
  },
  {
    id: 3,
    vehicle_number: 'TN 38 CY 5599',
    vehicle_type: 'tanker',
    capacity_kl: 16.0,
    driver_name: 'Ajith',
    driver_phone: '9842100011',
    status: 'moving',
    last_speed_kmh: 38.4,
    last_latitude: 11.025500,
    last_longitude: 76.982100,
    last_ping_ago: '35s ago',
    current_trip: 'Amirtha Milk Dairy'
  },
  {
    id: 4,
    vehicle_number: 'TN 38 DZ 8841',
    vehicle_type: 'tanker',
    capacity_kl: 40.0, // Open capacity (40KL trailer!)
    driver_name: 'Kuppusamy',
    driver_phone: '9842100013',
    status: 'moving',
    last_speed_kmh: 46.0,
    last_latitude: 11.081200,
    last_longitude: 77.042100,
    last_ping_ago: '10s ago',
    current_trip: 'Vinayaga Spinning Mill (Heavy Load)'
  },
  {
    id: 5,
    vehicle_number: 'TN 34 BF 1120',
    vehicle_type: 'tanker',
    capacity_kl: 9.0,
    driver_name: 'Sher Bist',
    driver_phone: '9842100012',
    status: 'stopped',
    last_speed_kmh: 0.0,
    last_latitude: 11.011200,
    last_longitude: 76.951200,
    last_ping_ago: '1m ago',
    current_trip: 'Muthampalayam Construction (Completed)'
  },
  {
    id: 6,
    vehicle_number: 'TN 38 AB 3340',
    vehicle_type: 'tanker',
    capacity_kl: 16.0,
    driver_name: 'Standby Driver',
    driver_phone: '9842100099',
    status: 'maintenance',
    last_speed_kmh: 0.0,
    last_latitude: 11.002100,
    last_longitude: 76.941200,
    last_ping_ago: '5m ago',
    current_trip: 'Workshop (Greasing & Welding)'
  },
  {
    id: 7,
    vehicle_number: 'TN 34 KL 7701',
    vehicle_type: 'tanker',
    capacity_kl: 9.0,
    driver_name: 'Spare Unit',
    driver_phone: '9842100098',
    status: 'stopped',
    last_speed_kmh: 0.0,
    last_latitude: 11.034100,
    last_longitude: 76.974100,
    last_ping_ago: '8m ago',
    current_trip: 'Yard Standby'
  }
];

export const initialTankerTrips: TankerTrip[] = [
  {
    id: 1,
    trip_number: 'TRP-2026-0841',
    customer_name: 'Texvalley Corporate Campus',
    vehicle_number: 'TN 34 AF 4954',
    driver_name: 'Suresh',
    capacity_kl: 24.0,
    destination: 'Texvalley Gate 2 Sump',
    status: 'at_destination',
    trip_date: '2026-10-30',
    start_time: '09:15 AM',
    base_fare: 2500.0,
    motor_used: true,
    motor_charges: 250.0,
    waiting_time_hours: 2.0,
    waiting_time_charges: 300.0,
    long_distance_km: 0,
    long_distance_surcharge: 0.0,
    miscellaneous_charges: 180.0, // Toll
    total_billing_amount: 3230.0,
    driver_batta: 250.0,
    fuel_expenses: 850.0,
    net_trip_profit: 2130.0,
    odometer_start: 142810,
    odometer_end: 142865,
    total_km: 55,
    gate_pass_photo: 'attached'
  },
  {
    id: 2,
    trip_number: 'TRP-2026-0842',
    customer_name: 'Amirtha Milk Dairy & Genset',
    vehicle_number: 'TN 38 CY 5599',
    driver_name: 'Ajith',
    capacity_kl: 16.0,
    destination: 'Amirtha Cooling Unit',
    status: 'in_transit',
    trip_date: '2026-10-30',
    start_time: '10:00 AM',
    base_fare: 1800.0,
    motor_used: true,
    motor_charges: 200.0,
    waiting_time_hours: 0.0,
    waiting_time_charges: 0.0,
    long_distance_km: 10,
    long_distance_surcharge: 200.0,
    miscellaneous_charges: 0.0,
    total_billing_amount: 2200.0,
    driver_batta: 250.0,
    fuel_expenses: 600.0,
    net_trip_profit: 1350.0,
    odometer_start: 98120,
    odometer_end: 98158,
    total_km: 38
  },
  {
    id: 3,
    trip_number: 'TRP-2026-0843',
    customer_name: 'Vinayaga Spinning Mill',
    vehicle_number: 'TN 38 DZ 8841',
    driver_name: 'Kuppusamy',
    capacity_kl: 40.0, // Open 40KL trailer!
    destination: 'Mill Processing Tank',
    status: 'in_transit',
    trip_date: '2026-10-30',
    start_time: '08:30 AM',
    base_fare: 3500.0,
    motor_used: false,
    motor_charges: 0.0,
    waiting_time_hours: 1.5,
    waiting_time_charges: 225.0,
    long_distance_km: 25,
    long_distance_surcharge: 500.0,
    miscellaneous_charges: 120.0,
    total_billing_amount: 4345.0,
    driver_batta: 350.0,
    fuel_expenses: 1400.0,
    net_trip_profit: 2595.0,
    odometer_start: 215400,
    odometer_end: 215482,
    total_km: 82
  }
];

// Multi-Plant Refill Intakes (from Image 3: Load 1: 72, Load 2: 84, Load 3: 57 = 213 cans @ ₹8)
export const initialPlantIntakes: PlantIntake[] = [
  {
    id: 1,
    intake_sequence: 1,
    time: '08:15 AM',
    cans_loaded: 72,
    purchase_rate: 8.0,
    total_cost: 576.0,
    slip_number: 'RO-PLANT-0912'
  },
  {
    id: 2,
    intake_sequence: 2,
    time: '12:45 PM',
    cans_loaded: 84,
    purchase_rate: 8.0,
    total_cost: 672.0,
    slip_number: 'RO-PLANT-0948'
  },
  {
    id: 3,
    intake_sequence: 3,
    time: '04:15 PM',
    cans_loaded: 57,
    purchase_rate: 8.0,
    total_cost: 456.0,
    slip_number: 'RO-PLANT-0980'
  }
];

// Real delivery route customer drops (Image 3)
export const initialCanDeliveries: CanDelivery[] = [
  { id: 1, customer_name: 'Black Pekoe Tea', cans_delivered: 3, empty_cans_collected: 3, rate_per_can: 20, total_amount: 60, payment_mode: 'cash', amount_paid: 60, unpaid_balance: 0, payment_time: '09:05 AM', delivery_lat: 11.012, delivery_lng: 76.955, is_synced: true },
  { id: 2, customer_name: 'One Cup Tea', cans_delivered: 5, empty_cans_collected: 5, rate_per_can: 20, total_amount: 100, payment_mode: 'cash', amount_paid: 100, unpaid_balance: 0, payment_time: '09:18 AM', delivery_lat: 11.014, delivery_lng: 76.958, is_synced: true },
  { id: 3, customer_name: 'Balaji Cafe', cans_delivered: 10, empty_cans_collected: 10, rate_per_can: 20, total_amount: 200, payment_mode: 'cash', amount_paid: 200, unpaid_balance: 0, payment_time: '09:30 AM', delivery_lat: 11.017, delivery_lng: 76.960, is_synced: true },
  { id: 4, customer_name: 'Aran Cafe - 1', cans_delivered: 14, empty_cans_collected: 14, rate_per_can: 20, total_amount: 280, payment_mode: 'cash', amount_paid: 280, unpaid_balance: 0, payment_time: '09:45 AM', delivery_lat: 11.019, delivery_lng: 76.963, is_synced: true },
  { id: 5, customer_name: 'Aran Cafe - 2', cans_delivered: 5, empty_cans_collected: 5, rate_per_can: 20, total_amount: 100, payment_mode: 'cash', amount_paid: 100, unpaid_balance: 0, payment_time: '10:02 AM', delivery_lat: 11.021, delivery_lng: 76.966, is_synced: true },
  { id: 6, customer_name: 'Friends Cafe', cans_delivered: 4, empty_cans_collected: 4, rate_per_can: 20, total_amount: 80, payment_mode: 'cash', amount_paid: 80, unpaid_balance: 0, payment_time: '10:15 AM', delivery_lat: 11.023, delivery_lng: 76.968, is_synced: true },
  { id: 7, customer_name: 'M.S. Bakery', cans_delivered: 8, empty_cans_collected: 8, rate_per_can: 20, total_amount: 160, payment_mode: 'cash', amount_paid: 160, unpaid_balance: 0, payment_time: '10:35 AM', delivery_lat: 11.025, delivery_lng: 76.971, is_synced: true },
  { id: 8, customer_name: 'Murugan Store', cans_delivered: 5, empty_cans_collected: 5, rate_per_can: 20, total_amount: 100, payment_mode: 'cash', amount_paid: 100, unpaid_balance: 0, payment_time: '10:50 AM', delivery_lat: 11.027, delivery_lng: 76.974, is_synced: true },
  { id: 9, customer_name: 'Vela Jewellers', cans_delivered: 13, empty_cans_collected: 13, rate_per_can: 20, total_amount: 260, payment_mode: 'credit', amount_paid: 0, unpaid_balance: 260, payment_time: '11:10 AM', delivery_lat: 11.029, delivery_lng: 76.977, is_synced: true },
  { id: 10, customer_name: 'Palani Hotel', cans_delivered: 11, empty_cans_collected: 11, rate_per_can: 20, total_amount: 220, payment_mode: 'credit', amount_paid: 0, unpaid_balance: 220, payment_time: '11:40 AM', delivery_lat: 11.031, delivery_lng: 76.980, is_synced: true },
  { id: 11, customer_name: 'Surya Tex - 1', cans_delivered: 13, empty_cans_collected: 13, rate_per_can: 20, total_amount: 260, payment_mode: 'credit', amount_paid: 0, unpaid_balance: 260, payment_time: '02:15 PM', delivery_lat: 11.035, delivery_lng: 76.985, is_synced: true },
  { id: 12, customer_name: 'Santha Company', cans_delivered: 37, empty_cans_collected: 37, rate_per_can: 20, total_amount: 740, payment_mode: 'credit', amount_paid: 0, unpaid_balance: 740, payment_time: '03:10 PM', delivery_lat: 11.040, delivery_lng: 76.992, is_synced: true },
  { id: 13, customer_name: 'Oppil Sand', cans_delivered: 15, empty_cans_collected: 15, rate_per_can: 20, total_amount: 300, payment_mode: 'cash', amount_paid: 300, unpaid_balance: 0, payment_time: '03:45 PM', delivery_lat: 11.042, delivery_lng: 76.995, is_synced: true },
  { id: 14, customer_name: 'Mahavishnu Pandal', cans_delivered: 8, empty_cans_collected: 8, rate_per_can: 20, total_amount: 160, payment_mode: 'credit', amount_paid: 0, unpaid_balance: 160, payment_time: '04:40 PM', delivery_lat: 11.045, delivery_lng: 77.001, is_synced: true },
  { id: 15, customer_name: 'E.K. Salim Store', cans_delivered: 7, empty_cans_collected: 7, rate_per_can: 20, total_amount: 140, payment_mode: 'cash', amount_paid: 140, unpaid_balance: 0, payment_time: '05:10 PM', delivery_lat: 11.048, delivery_lng: 77.005, is_synced: true },
  { id: 16, customer_name: 'R.P. Maligai Kadai', cans_delivered: 8, empty_cans_collected: 8, rate_per_can: 20, total_amount: 160, payment_mode: 'cash', amount_paid: 160, unpaid_balance: 0, payment_time: '05:35 PM', delivery_lat: 11.050, delivery_lng: 77.008, is_synced: true }
];

// Telematics Route Stoppages & Dwell Times (Tata Ace)
export const initialRouteStops: RouteStop[] = [
  { id: 1, location_name: 'Main RO Water Plant', arrival_time: '08:15 AM', departure_time: '08:35 AM', dwell_minutes: 20, stop_type: 'plant_loading' },
  { id: 2, location_name: 'Black Pekoe Tea', arrival_time: '09:05 AM', departure_time: '09:12 AM', dwell_minutes: 7, stop_type: 'customer_delivery' },
  { id: 3, location_name: 'Aran Cafe - 1', arrival_time: '09:40 AM', departure_time: '09:54 AM', dwell_minutes: 14, stop_type: 'customer_delivery' },
  { id: 4, location_name: 'Highway Tea Stall & Snack Center', arrival_time: '11:15 AM', departure_time: '12:05 PM', dwell_minutes: 50, stop_type: 'rest_break', is_warning: true },
  { id: 5, location_name: 'Main RO Water Plant (Load 2 Refill)', arrival_time: '12:40 PM', departure_time: '01:05 PM', dwell_minutes: 25, stop_type: 'plant_loading' },
  { id: 6, location_name: 'Santha Company Depot', arrival_time: '03:05 PM', departure_time: '03:25 PM', dwell_minutes: 20, stop_type: 'customer_delivery' },
  { id: 7, location_name: 'Bharat Petroleum Station', arrival_time: '04:00 PM', departure_time: '04:08 PM', dwell_minutes: 8, stop_type: 'fuel_station' }
];

// Bakery Raw Material Purchases (from Image 2)
export const initialBakeryPurchases: BakeryPurchase[] = [
  { id: 1, purchase_date: '2026-10-30', item_name_en: 'Coriander', item_name_ta: 'கொத்தமல்லி', vendor_name: 'Local Mandi', quantity: 1, unit: 'bundle', rate: 210, total_amount: 210, payment_mode: 'cash_drawer' },
  { id: 2, purchase_date: '2026-10-30', item_name_en: 'Tomato', item_name_ta: 'தக்காளி', vendor_name: 'Local Mandi', quantity: 2, unit: 'box', rate: 34, total_amount: 68, payment_mode: 'cash_drawer' },
  { id: 3, purchase_date: '2026-10-30', item_name_en: 'Cake & Bun', item_name_ta: 'கேக் & பன்', vendor_name: 'Sri Murugan Supplies', quantity: 1, unit: 'crate', rate: 390, total_amount: 390, payment_mode: 'cash_drawer' },
  { id: 4, purchase_date: '2026-10-30', item_name_en: 'Puffs', item_name_ta: 'பப்ஸ்', vendor_name: 'Sri Murugan Supplies', quantity: 1, unit: 'tray', rate: 300, total_amount: 300, payment_mode: 'cash_drawer' },
  { id: 5, purchase_date: '2026-10-30', item_name_en: '7up, Pepsi, Slice', item_name_ta: 'குளிர்பானங்கள்', vendor_name: 'City Beverage Depot', quantity: 1, unit: 'crate', rate: 270, total_amount: 270, payment_mode: 'cash_drawer' },
  { id: 6, purchase_date: '2026-10-30', item_name_en: 'Daily Finance Payment', item_name_ta: 'தினசரி பைனான்ஸ்', vendor_name: 'Finance Agent', quantity: 1, unit: 'instalment', rate: 1000, total_amount: 1000, payment_mode: 'cash_drawer' },
  { id: 7, purchase_date: '2026-10-30', item_name_en: 'Sugar', item_name_ta: 'சர்க்கரை', vendor_name: 'Balaji Grocery', quantity: 10, unit: 'kg', rate: 58.6, total_amount: 586, payment_mode: 'gpay_kavin', notes: 'G-Pay transaction by Kavin Anna' },
  { id: 8, purchase_date: '2026-10-30', item_name_en: 'Vim Lemons Dishwash', item_name_ta: 'விம் லெமன்', vendor_name: 'Balaji Grocery', quantity: 1, unit: 'bottle', rate: 139, total_amount: 139, payment_mode: 'gpay_kavin' },
  { id: 9, purchase_date: '2026-10-30', item_name_en: 'Brownies', item_name_ta: 'பிரவுனி', vendor_name: 'City Confectionery', quantity: 1, unit: 'box', rate: 530, total_amount: 530, payment_mode: 'cash_drawer' },
  { id: 10, purchase_date: '2026-10-30', item_name_en: 'Fresh Milk Packets', item_name_ta: 'பால் பாக்கெட் (20 Pockets)', vendor_name: 'Aavin / Local Farm', quantity: 20, unit: 'packet', rate: 32, total_amount: 640, payment_mode: 'cash_drawer' }
];

// Bakery Counter Closing (Image 1 Page 152)
export const initialBakeryClosing: BakeryClosing = {
  closing_date: '2026-10-30',
  physical_drawer_cash: 1960.0,
  coins_amount: 104.0,
  expenses_paid_from_drawer: 700.0,
  upi_collections: 3700.0,
  total_counter_revenue: 5764.0, // (1960 + 104) + 3700
  net_cash_banked: 1364.0, // (1960 + 104) - 700
  wastage: {
    bajji: 25,
    egg_bonda: 6,
    puff: 2,
    milk_pockets: 20
  },
  closed_by: 'Wife / Kavin'
};

// Corporate Credit Accounts (Image 4 Google Sheet)
export const initialCreditAccounts: CustomerCreditAccount[] = [
  {
    id: 1,
    company_name: 'Amirtha Milk Dairy & Genset',
    division: 'tanker',
    billing_cycle: '15-Day Cycle',
    current_balance: 124000,
    unbilled_amount: 18400,
    aging: { days_0_15: 18400, days_16_30: 35000, days_31_60: 42000, days_60_plus: 28600 },
    last_payment_date: '2026-10-18',
    follow_up_note: 'Promise by Senthil to clear ₹42K on Oct 31'
  },
  {
    id: 2,
    company_name: 'Texvalley Corporate Campus',
    division: 'tanker',
    billing_cycle: 'Monthly 1st - 30th',
    current_balance: 85000,
    unbilled_amount: 28500,
    aging: { days_0_15: 28500, days_16_30: 25000, days_31_60: 31500, days_60_plus: 0 },
    last_payment_date: '2026-10-24',
    follow_up_note: '88KL contract active; bill processing with finance team'
  },
  {
    id: 3,
    company_name: 'Vinayaga Spinning Mill',
    division: 'tanker',
    billing_cycle: 'Monthly 1st - 30th',
    current_balance: 95000,
    unbilled_amount: 12000,
    aging: { days_0_15: 12000, days_16_30: 18000, days_31_60: 25000, days_60_plus: 40000 },
    last_payment_date: '2026-09-30',
    follow_up_note: 'Overdue >60 days: Dinesh to visit mill manager on Saturday'
  },
  {
    id: 4,
    company_name: 'The Chennai Silks Warehouse',
    division: 'tanker',
    billing_cycle: 'Monthly 1st - 30th',
    current_balance: 42000,
    unbilled_amount: 8600,
    aging: { days_0_15: 8600, days_16_30: 14000, days_31_60: 19400, days_60_plus: 0 },
    last_payment_date: '2026-10-12',
    follow_up_note: 'Regular corporate client; cycle clears automatically'
  }
];

export const initialCustomers = [
  {
    id: 1,
    company_name: 'Aran Cafe - 1',
    customer_code: 'CUST-CAN-001',
    contact_person: 'Mr. Senthil',
    phone: '98421 55601',
    division_type: 'can' as const,
    delivery_location_lat: 11.018221,
    delivery_location_lng: 76.964119,
    geofence_radius_meters: 75,
    is_gps_locked: true,
    default_rate_per_can: 20.00,
    credit_limit: 5000.00,
    current_credit_balance: 1420.00,
    last_delivery_at: '2026-10-30 09:12:15',
    last_geofence_status: 'verified' as const,
    last_distance_meters: 14.5
  },
  {
    id: 2,
    company_name: 'Aran Cafe - 2',
    customer_code: 'CUST-CAN-002',
    contact_person: 'Mr. Ramesh',
    phone: '98421 55602',
    division_type: 'can' as const,
    delivery_location_lat: 11.021450,
    delivery_location_lng: 76.968920,
    geofence_radius_meters: 75,
    is_gps_locked: true,
    default_rate_per_can: 20.00,
    credit_limit: 5000.00,
    current_credit_balance: 840.00,
    last_delivery_at: '2026-10-30 09:35:40',
    last_geofence_status: 'verified' as const,
    last_distance_meters: 21.0
  },
  {
    id: 3,
    company_name: 'Texvalley Corporate Campus',
    customer_code: 'CUST-TNK-001',
    contact_person: 'Estate Manager',
    phone: '94433 12890',
    division_type: 'tanker' as const,
    delivery_location_lat: 11.332400,
    delivery_location_lng: 77.712100,
    geofence_radius_meters: 150,
    is_gps_locked: true,
    default_rate_per_can: 0.00,
    credit_limit: 100000.00,
    current_credit_balance: 12450.00,
    rate_slab: {
      base_fare: 2500.00,
      base_included_km: 15,
      extra_per_km_rate: 20.00,
      motor_rate_per_min: 5.00,
      wait_rate_per_min: 2.50
    },
    last_delivery_at: '2026-10-30 11:20:00',
    last_geofence_status: 'verified' as const,
    last_distance_meters: 35.0
  },
  {
    id: 4,
    company_name: 'The Chennai Silks (Dyeing Unit)',
    customer_code: 'CUST-TNK-002',
    contact_person: 'Purchase Officer',
    phone: '98430 44810',
    division_type: 'tanker' as const,
    delivery_location_lat: 11.084500,
    delivery_location_lng: 77.294100,
    geofence_radius_meters: 200,
    is_gps_locked: true,
    default_rate_per_can: 0.00,
    credit_limit: 150000.00,
    current_credit_balance: 28400.00,
    last_delivery_at: '2026-10-29 16:45:00',
    last_geofence_status: 'verified' as const,
    last_distance_meters: 48.0
  },
  {
    id: 5,
    company_name: 'Black Pekoe Tea',
    customer_code: 'CUST-CAN-003',
    contact_person: 'Mr. Kumar',
    phone: '99441 33201',
    division_type: 'can' as const,
    delivery_location_lat: 11.014200,
    delivery_location_lng: 76.958700,
    geofence_radius_meters: 75,
    is_gps_locked: true,
    default_rate_per_can: 20.00,
    credit_limit: 3000.00,
    current_credit_balance: 360.00,
    last_delivery_at: '2026-10-30 10:15:00',
    last_geofence_status: 'verified' as const,
    last_distance_meters: 18.2
  },
  {
    id: 6,
    company_name: 'Santha Company (Shop)',
    customer_code: 'CUST-CAN-004',
    contact_person: 'Proprietor',
    phone: '97871 00293',
    division_type: 'can' as const,
    delivery_location_lat: 11.026800,
    delivery_location_lng: 76.974200,
    geofence_radius_meters: 75,
    is_gps_locked: true,
    default_rate_per_can: 20.00,
    credit_limit: 4000.00,
    current_credit_balance: 680.00,
    last_delivery_at: '2026-10-30 13:40:00',
    last_geofence_status: 'mismatch' as const, // Alert: 420m away from shop
    last_distance_meters: 420.0
  }
];

export const initialExpenses = [
  {
    id: 1,
    expense_date: '2026-10-30',
    division: 'tanker' as const,
    category: 'fuel_diesel',
    category_name: 'Diesel / Fuel (Lorry TN 34 AF 4954)',
    vehicle: 'TN 34 AF 4954',
    amount: 4200.00,
    payment_mode: 'canara_bank' as const,
    payee: 'HP Petrol Bunk, Kangeyam Road',
    voucher_no: 'EXP-TNK-2026-081',
    notes: 'Full tank 44.2 litres for Texvalley trip'
  },
  {
    id: 2,
    expense_date: '2026-10-30',
    division: 'tanker' as const,
    category: 'driver_batta',
    category_name: 'Driver Batta (Suresh)',
    vehicle: 'TN 34 AF 4954',
    amount: 250.00,
    payment_mode: 'cash_drawer' as const,
    payee: 'Driver Suresh',
    voucher_no: 'EXP-TNK-2026-082',
    notes: 'Trip batta for long distance run'
  },
  {
    id: 3,
    expense_date: '2026-10-29',
    division: 'tanker' as const,
    category: 'tolls_permits',
    category_name: 'National Highway Tolls',
    vehicle: 'TN 38 DZ 8841',
    amount: 360.00,
    payment_mode: 'gpay_kavin' as const,
    payee: 'FASTag Toll Plaza',
    voucher_no: 'EXP-TNK-2026-079',
    notes: 'Vijayamangalam Toll FASTag recharge'
  },
  {
    id: 4,
    expense_date: '2026-10-28',
    division: 'tanker' as const,
    category: 'vehicle_service',
    category_name: 'Pumping Motor Servicing & Oil',
    vehicle: 'TN 38 CY 5599',
    amount: 1850.00,
    payment_mode: 'canara_bank' as const,
    payee: 'Lakshmi Auto Garage',
    voucher_no: 'EXP-TNK-2026-075',
    notes: 'Delivery motor impeller seal replaced'
  },
  {
    id: 5,
    expense_date: '2026-10-30',
    division: 'can' as const,
    category: 'water_plant_cost',
    category_name: 'RO Plant Water Intake (213 Cans @ ₹8)',
    vehicle: 'TN 38 BX 4412',
    amount: 1704.00,
    payment_mode: 'cash_drawer' as const,
    payee: 'Main RO Mineral Water Plant',
    voucher_no: 'EXP-CAN-2026-041',
    notes: 'Loads 1, 2, and 3 refills total 213 cans'
  },
  {
    id: 6,
    expense_date: '2026-10-30',
    division: 'can' as const,
    category: 'wages_salaries',
    category_name: 'Driver & Delivery Helper Daily Wage',
    vehicle: 'TN 38 BX 4412',
    amount: 1000.00,
    payment_mode: 'cash_drawer' as const,
    payee: 'Vignesh (Driver)',
    voucher_no: 'EXP-CAN-2026-042',
    notes: 'Daily fixed wage for 16 drops'
  },
  {
    id: 7,
    expense_date: '2026-10-29',
    division: 'can' as const,
    category: 'fuel_diesel',
    category_name: 'Diesel for Tata Ace',
    vehicle: 'TN 38 BX 4412',
    amount: 650.00,
    payment_mode: 'gpay_kavin' as const,
    payee: 'Indian Oil Bunk',
    voucher_no: 'EXP-CAN-2026-039',
    notes: '6.5 litres diesel for day route'
  },
  {
    id: 8,
    expense_date: '2026-10-30',
    division: 'bakery' as const,
    category: 'raw_materials',
    category_name: 'Daily Ingredients & Supplies (Image 2)',
    vehicle: 'Store Counter',
    amount: 3861.60,
    payment_mode: 'cash_drawer' as const,
    payee: 'Various Mandi & Grocery Vendors',
    voucher_no: 'EXP-BAK-2026-102',
    notes: 'Milk, Tomatoes, Coriander, Puffs, Tea dust'
  },
  {
    id: 9,
    expense_date: '2026-10-30',
    division: 'bakery' as const,
    category: 'finance_instalment',
    category_name: 'Daily Finance Instalment Payment',
    vehicle: 'Store Counter',
    amount: 1000.00,
    payment_mode: 'cash_drawer' as const,
    payee: 'Finance Collection Agent',
    voucher_no: 'EXP-BAK-2026-103',
    notes: 'Daily loan repayment instalment'
  },
  {
    id: 10,
    expense_date: '2026-10-30',
    division: 'bakery' as const,
    category: 'wages_salaries',
    category_name: 'Paati Wages & Helper Advance',
    vehicle: 'Store Counter',
    amount: 350.00,
    payment_mode: 'cash_drawer' as const,
    payee: 'Store Helper (Paati)',
    voucher_no: 'EXP-BAK-2026-104',
    notes: 'Daily washing & cleaning assistance'
  },
  {
    id: 11,
    expense_date: '2026-10-28',
    division: 'general' as const,
    category: 'electricity_utilities',
    category_name: 'TNEB Electricity Bill (Bakery & Office)',
    vehicle: 'Head Office / Store',
    amount: 3420.00,
    payment_mode: 'axis_bank' as const,
    payee: 'TNEB Tamil Nadu Electricity Board',
    voucher_no: 'EXP-GEN-2026-015',
    notes: 'Monthly commercial tariff'
  },
  {
    id: 12,
    expense_date: '2026-10-27',
    division: 'general' as const,
    category: 'miscellaneous',
    category_name: 'Accountant Audit & Books Closing',
    vehicle: 'Head Office',
    amount: 2000.00,
    payment_mode: 'gpay_kavin' as const,
    payee: 'Auditor Sundaram & Associates',
    voucher_no: 'EXP-GEN-2026-016',
    notes: 'Monthly tax filing retainership'
  }
];

export const initialStaff = [
  // Bulk Tanker Drivers
  {
    id: 1,
    name: 'Suresh Kumar',
    role: 'tanker_driver' as const,
    role_display: 'Senior Tanker Driver',
    division: 'tanker' as const,
    phone: '98422 10101',
    assigned_vehicle: 'TN 34 AF 4954 (24 KL)',
    wage_type: 'monthly' as const,
    base_wage: 22000.0,
    batta_rate: 250.0,
    advance_balance: 2000.0,
    license_number: 'TN-34-2015-004128',
    badge_expiry: '2028-11-20',
    is_active: true,
    joined_date: '2023-04-10'
  },
  {
    id: 2,
    name: 'Palanisamy M.',
    role: 'tanker_driver' as const,
    role_display: 'Tanker Driver',
    division: 'tanker' as const,
    phone: '98422 10102',
    assigned_vehicle: 'TN 38 CY 5599 (16 KL)',
    wage_type: 'monthly' as const,
    base_wage: 20000.0,
    batta_rate: 250.0,
    advance_balance: 1500.0,
    license_number: 'TN-38-2018-009941',
    badge_expiry: '2027-08-15',
    is_active: true,
    joined_date: '2024-01-15'
  },
  {
    id: 3,
    name: 'Karthik Raja',
    role: 'tanker_driver' as const,
    role_display: 'Heavy Trailer Driver (40KL)',
    division: 'tanker' as const,
    phone: '98422 10103',
    assigned_vehicle: 'TN 38 DZ 8841 (40 KL)',
    wage_type: 'monthly' as const,
    base_wage: 26000.0,
    batta_rate: 300.0,
    advance_balance: 0.0,
    license_number: 'TN-38-2012-001284',
    badge_expiry: '2029-03-10',
    is_active: true,
    joined_date: '2022-08-01'
  },
  {
    id: 4,
    name: 'Murugesan K.',
    role: 'tanker_driver' as const,
    role_display: 'Tanker Driver',
    division: 'tanker' as const,
    phone: '98422 10104',
    assigned_vehicle: 'TN 34 BF 1120 (9 KL)',
    wage_type: 'monthly' as const,
    base_wage: 19000.0,
    batta_rate: 250.0,
    advance_balance: 800.0,
    license_number: 'TN-34-2019-006712',
    badge_expiry: '2027-05-22',
    is_active: true,
    joined_date: '2024-06-12'
  },

  // 20L Water Can Delivery Boys
  {
    id: 5,
    name: 'Vigneshwaran (Vicky)',
    role: 'can_delivery_boy' as const,
    role_display: 'Can Delivery Route Lead',
    division: 'can' as const,
    phone: '97871 44120',
    assigned_vehicle: 'TN 38 BX 4412 (Tata Ace)',
    wage_type: 'daily' as const,
    base_wage: 1000.0, // Fixed daily wage
    batta_rate: 50.0,
    advance_balance: 1200.0,
    license_number: 'TN-38-2021-008123',
    badge_expiry: '2031-10-10',
    is_active: true,
    joined_date: '2024-03-01'
  },
  {
    id: 6,
    name: 'Raja Sundaram',
    role: 'can_delivery_boy' as const,
    role_display: 'Can Delivery Helper & Loader',
    division: 'can' as const,
    phone: '97871 44122',
    assigned_vehicle: 'TN 38 BX 4412 (Tata Ace)',
    wage_type: 'daily' as const,
    base_wage: 650.0,
    batta_rate: 0.0,
    advance_balance: 500.0,
    is_active: true,
    joined_date: '2024-09-01'
  },

  // Bakery & Store Staff
  {
    id: 7,
    name: 'Kavin Anna',
    role: 'bakery_counter' as const,
    role_display: 'Store Counter & Closing In-Charge',
    division: 'bakery' as const,
    phone: '98421 00001',
    wage_type: 'monthly' as const,
    base_wage: 25000.0,
    advance_balance: 0.0,
    is_active: true,
    joined_date: '2020-01-01'
  },
  {
    id: 8,
    name: 'Selvam Master',
    role: 'kitchen_cook' as const,
    role_display: 'Master Baker & Tea Maker',
    division: 'bakery' as const,
    phone: '94420 88123',
    wage_type: 'monthly' as const,
    base_wage: 18000.0,
    advance_balance: 1000.0,
    is_active: true,
    joined_date: '2023-02-15'
  },
  {
    id: 9,
    name: 'Paati (Periyamma)',
    role: 'store_helper' as const,
    role_display: 'Store Helper & Dishwashing',
    division: 'bakery' as const,
    phone: 'Store Assistant',
    wage_type: 'daily' as const,
    base_wage: 350.0, // Evening drawer payout (Image 2 item #10)
    advance_balance: 150.0,
    is_active: true,
    joined_date: '2023-05-10'
  }
];

export const initialAttendance = [
  {
    id: 1,
    staff_id: 1,
    staff_name: 'Suresh Kumar',
    role_display: 'Senior Tanker Driver',
    division: 'tanker' as const,
    date: '2026-10-30',
    check_in: '07:30 AM',
    check_out: '06:15 PM',
    status: 'on_trip' as const,
    notes: 'Dispatched to Texvalley Campus (24KL)'
  },
  {
    id: 2,
    staff_id: 2,
    staff_name: 'Palanisamy M.',
    role_display: 'Tanker Driver',
    division: 'tanker' as const,
    date: '2026-10-30',
    check_in: '08:00 AM',
    check_out: '05:45 PM',
    status: 'on_trip' as const,
    notes: 'Dispatched to Amirtha Milk (16KL)'
  },
  {
    id: 3,
    staff_id: 3,
    staff_name: 'Karthik Raja',
    role_display: 'Heavy Trailer Driver (40KL)',
    division: 'tanker' as const,
    date: '2026-10-30',
    check_in: '07:00 AM',
    check_out: '07:00 PM',
    status: 'on_trip' as const,
    notes: 'Dispatched to Vinayaga Spinning Mill (40KL)'
  },
  {
    id: 4,
    staff_id: 4,
    staff_name: 'Murugesan K.',
    role_display: 'Tanker Driver',
    division: 'tanker' as const,
    date: '2026-10-30',
    check_in: '08:15 AM',
    check_out: '01:00 PM',
    status: 'half_day' as const,
    notes: 'Half day leave for RTO inspection'
  },
  {
    id: 5,
    staff_id: 5,
    staff_name: 'Vigneshwaran (Vicky)',
    role_display: 'Can Delivery Route Lead',
    division: 'can' as const,
    date: '2026-10-30',
    check_in: '08:00 AM',
    check_out: '05:30 PM',
    status: 'present' as const,
    notes: '3 plant refill runs completed (213 cans)'
  },
  {
    id: 6,
    staff_id: 6,
    staff_name: 'Raja Sundaram',
    role_display: 'Can Delivery Helper',
    division: 'can' as const,
    date: '2026-10-30',
    check_in: '08:05 AM',
    check_out: '05:30 PM',
    status: 'present' as const,
    notes: 'Assisted Vicky on Tata Ace route'
  },
  {
    id: 7,
    staff_id: 7,
    staff_name: 'Kavin Anna',
    role_display: 'Store Counter & Closing',
    division: 'bakery' as const,
    date: '2026-10-30',
    check_in: '06:30 AM',
    status: 'present' as const,
    notes: 'Cash drawer closing reconciler'
  },
  {
    id: 8,
    staff_id: 8,
    staff_name: 'Selvam Master',
    role_display: 'Master Baker',
    division: 'bakery' as const,
    date: '2026-10-30',
    check_in: '05:30 AM',
    status: 'present' as const,
    notes: 'Morning tea & bun puff batch'
  },
  {
    id: 9,
    staff_id: 9,
    staff_name: 'Paati (Periyamma)',
    role_display: 'Store Helper',
    division: 'bakery' as const,
    date: '2026-10-30',
    check_in: '09:00 AM',
    check_out: '05:00 PM',
    status: 'present' as const,
    notes: '₹350 daily wage disbursed from drawer'
  }
];

export const initialPayroll = [
  {
    id: 1,
    staff_id: 1,
    staff_name: 'Suresh Kumar',
    division: 'tanker' as const,
    settlement_month: 'October 2026',
    base_earnings: 22000.0,
    batta_or_incentives: 6500.0, // 26 trips x ₹250
    advances_deducted: 2000.0,
    net_payable: 26500.0,
    payment_mode: 'canara_bank' as const,
    status: 'paid' as const,
    disbursed_at: '2026-10-28',
    voucher_no: 'PAY-TNK-2026-101'
  },
  {
    id: 2,
    staff_id: 5,
    staff_name: 'Vigneshwaran (Vicky)',
    division: 'can' as const,
    settlement_month: 'October 2026 (Week 4)',
    base_earnings: 7000.0, // 7 days x ₹1,000
    batta_or_incentives: 950.0, // can volume incentives
    advances_deducted: 1200.0,
    net_payable: 6750.0,
    payment_mode: 'cash_drawer' as const,
    status: 'paid' as const,
    disbursed_at: '2026-10-29',
    voucher_no: 'PAY-CAN-2026-088'
  },
  {
    id: 3,
    staff_id: 8,
    staff_name: 'Selvam Master',
    division: 'bakery' as const,
    settlement_month: 'October 2026',
    base_earnings: 18000.0,
    batta_or_incentives: 1500.0,
    advances_deducted: 1000.0,
    net_payable: 18500.0,
    payment_mode: 'gpay_kavin' as const,
    status: 'paid' as const,
    disbursed_at: '2026-10-27',
    voucher_no: 'PAY-BAK-2026-052'
  }
];

export const initialLeaves = [
  {
    id: 1,
    staff_id: 4,
    staff_name: 'Murugesan K.',
    division: 'tanker' as const,
    leave_type: 'personal' as const,
    start_date: '2026-10-31',
    end_date: '2026-10-31',
    days_count: 1,
    reason: 'Family temple festival in Kangeyam',
    status: 'approved' as const
  },
  {
    id: 2,
    staff_id: 2,
    staff_name: 'Palanisamy M.',
    division: 'tanker' as const,
    leave_type: 'medical' as const,
    start_date: '2026-11-03',
    end_date: '2026-11-04',
    days_count: 2,
    reason: 'Eye checkup & medical renewal',
    status: 'pending' as const
  }
];

