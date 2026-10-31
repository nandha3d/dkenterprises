export type PortalType = 'executive' | 'tankers' | 'water-cans' | 'bakery' | 'customers' | 'fleet' | 'expenses' | 'telematics' | 'staff';

export type Language = 'en' | 'ta';

export interface StaffMember {
  id: number;
  name: string;
  role: 'tanker_driver' | 'can_delivery_boy' | 'bakery_counter' | 'kitchen_cook' | 'store_helper';
  role_display: string;
  division: 'tanker' | 'can' | 'bakery';
  phone: string;
  assigned_vehicle?: string;
  wage_type: 'daily' | 'monthly' | 'per_trip';
  base_wage: number; // e.g. ₹1,000/day for can driver, ₹22,000/mo for tanker driver, ₹350/day for Paati
  batta_rate?: number; // e.g. ₹250/trip
  advance_balance: number; // Current outstanding advance taken
  license_number?: string;
  badge_expiry?: string;
  is_active: boolean;
  joined_date: string;
}

export interface AttendanceRecord {
  id: number;
  staff_id: number;
  staff_name: string;
  role_display: string;
  division: 'tanker' | 'can' | 'bakery';
  date: string;
  check_in: string;
  check_out?: string;
  status: 'present' | 'on_trip' | 'half_day' | 'absent' | 'on_leave';
  notes?: string;
}

export interface PayrollRecord {
  id: number;
  staff_id: number;
  staff_name: string;
  division: 'tanker' | 'can' | 'bakery';
  settlement_month: string;
  base_earnings: number;
  batta_or_incentives: number;
  advances_deducted: number;
  net_payable: number;
  payment_mode: 'cash_drawer' | 'gpay_kavin' | 'canara_bank' | 'axis_bank';
  status: 'paid' | 'pending';
  disbursed_at?: string;
  voucher_no: string;
}

export interface LeaveRecord {
  id: number;
  staff_id: number;
  staff_name: string;
  division: 'tanker' | 'can' | 'bakery';
  leave_type: 'casual' | 'medical' | 'personal';
  start_date: string;
  end_date: string;
  days_count: number;
  reason: string;
  status: 'approved' | 'pending' | 'rejected';
}

export interface Vehicle {
  id: number;
  vehicle_number: string;
  vehicle_type: 'tanker' | 'can_truck' | 'other';
  division?: string;
  capacity_kl?: number; // Fully dynamic (e.g. 40.0, 24.0, 16.0, 9.0)
  capacity_cans?: number;
  driver_name?: string;
  driver_phone?: string;
  status: 'moving' | 'idling' | 'stopped' | 'at_destination' | 'maintenance' | 'standby';
  odometer_km?: number;
  fuel_tank_capacity?: number;
  fc_expiry_date?: string;
  fc_days_remaining?: number;
  insurance_expiry?: string;
  insurance_status?: 'VALID' | 'RENEWAL_DUE' | 'EXPIRED';
  last_speed_kmh: number;
  last_latitude: number;
  last_longitude: number;
  last_ping_ago: string;
  current_trip?: string;
}

export interface Customer {
  id: number;
  company_name: string;
  customer_code: string;
  contact_person: string;
  phone: string;
  division_type: 'tanker' | 'can' | 'both' | 'bakery';
  delivery_location_lat: number;
  delivery_location_lng: number;
  geofence_radius_meters: number;
  is_gps_locked: boolean;
  default_rate_per_can?: number;
  credit_limit: number;
  current_credit_balance: number;
  rate_slab?: {
    base_fare?: number;
    base_included_km?: number;
    extra_per_km_rate?: number;
    motor_rate_per_min?: number;
    wait_rate_per_min?: number;
  };
  last_delivery_at?: string;
  last_geofence_status?: 'verified' | 'mismatch' | 'unverifiable';
  last_distance_meters?: number;
}

export interface Expense {
  id: number;
  expense_date: string;
  division: 'tanker' | 'can' | 'bakery' | 'general';
  category: string;
  category_name: string;
  vehicle?: string;
  amount: number;
  payment_mode: 'cash_drawer' | 'gpay_kavin' | 'canara_bank' | 'axis_bank' | 'credit';
  payee: string;
  voucher_no: string;
  notes?: string;
}

export interface TankerTrip {
  id: number;
  trip_number: string;
  customer_name: string;
  vehicle_number: string;
  driver_name: string;
  capacity_kl: number;
  destination: string;
  status: 'scheduled' | 'dispatched' | 'in_transit' | 'at_destination' | 'completed';
  trip_date: string;
  start_time: string;
  base_fare: number;
  motor_used: boolean;
  motor_charges: number;
  waiting_time_hours: number;
  waiting_time_charges: number;
  long_distance_km: number;
  long_distance_surcharge: number;
  miscellaneous_charges: number;
  total_billing_amount: number;
  driver_batta: number;
  fuel_expenses: number;
  net_trip_profit: number;
  odometer_start?: number;
  odometer_end?: number;
  total_km?: number;
  gate_pass_photo?: string;
}

export interface PlantIntake {
  id: number;
  intake_sequence: number; // Load 1, Load 2, Load 3...
  time: string;
  cans_loaded: number;
  purchase_rate: number; // e.g. ₹8/can
  total_cost: number;
  slip_number: string;
}

export interface CanDelivery {
  id: number;
  customer_name: string;
  cans_delivered: number;
  empty_cans_collected: number;
  rate_per_can: number;
  total_amount: number;
  payment_mode: 'cash' | 'upi' | 'credit';
  amount_paid: number;
  unpaid_balance: number;
  payment_time: string;
  delivery_lat: number;
  delivery_lng: number;
  is_synced: boolean;
}

export interface RouteStop {
  id: number;
  location_name: string;
  arrival_time: string;
  departure_time: string;
  dwell_minutes: number;
  stop_type: 'plant_loading' | 'customer_delivery' | 'fuel_station' | 'rest_break' | 'traffic_halt';
  is_warning?: boolean;
}

export interface BakeryPurchase {
  id: number;
  purchase_date: string;
  item_name_en: string;
  item_name_ta: string;
  vendor_name: string;
  quantity: number;
  unit: string;
  rate: number;
  total_amount: number;
  payment_mode: 'cash_drawer' | 'gpay_kavin' | 'vendor_credit';
  notes?: string;
}

export interface BakeryClosing {
  closing_date: string;
  physical_drawer_cash: number;
  coins_amount: number;
  expenses_paid_from_drawer: number;
  upi_collections: number;
  total_counter_revenue: number;
  net_cash_banked: number;
  wastage: {
    bajji: number;
    egg_bonda: number;
    puff: number;
    milk_pockets: number;
  };
  closed_by: string;
}

export interface CustomerCreditAccount {
  id: number;
  company_name: string;
  division: 'tanker' | 'can';
  billing_cycle: string;
  current_balance: number;
  unbilled_amount: number;
  aging: {
    days_0_15: number;
    days_16_30: number;
    days_31_60: number;
    days_60_plus: number;
  };
  last_payment_date: string;
  follow_up_note?: string;
}
