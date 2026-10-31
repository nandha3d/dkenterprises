-- ==============================================================================
-- DK Track — Database Schema (MySQL 8.0 / InnoDB)
-- Custom ERP & Fleet Logistics for DK Enterprises
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS integration_webhooks;
DROP TABLE IF EXISTS vehicle_route_stops;
DROP TABLE IF EXISTS vehicle_telematics_pings;
DROP TABLE IF EXISTS driver_batta_entries;
DROP TABLE IF EXISTS vehicle_expenses;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS bakery_daily_closings;
DROP TABLE IF EXISTS bakery_purchases;
DROP TABLE IF EXISTS bakery_items;
DROP TABLE IF EXISTS bakery_vendors;
DROP TABLE IF EXISTS can_cash_surrenders;
DROP TABLE IF EXISTS can_deliveries;
DROP TABLE IF EXISTS can_plant_intakes;
DROP TABLE IF EXISTS can_routes;
DROP TABLE IF EXISTS tanker_trips;
DROP TABLE IF EXISTS customer_rate_slabs;
DROP TABLE IF EXISTS trip_surcharge_types;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS drivers;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS geofences;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Users & RBAC
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(191) NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('owner', 'tanker_manager', 'can_manager', 'bakery_manager', 'driver', 'auditor') NOT NULL,
    division_access ENUM('all', 'tanker', 'can', 'bakery') DEFAULT 'all',
    preferred_language ENUM('en', 'ta') DEFAULT 'ta',
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_user_role (role),
    INDEX idx_user_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Audit Logs (Append-Only)
CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_audit_entity (entity_type, entity_id),
    INDEX idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Vehicles (Open Capacities, e.g. 40KL, 28KL, 9KL)
CREATE TABLE vehicles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_number VARCHAR(30) NOT NULL UNIQUE,
    vehicle_type ENUM('tanker', 'can_truck', 'other') NOT NULL,
    capacity_kl DECIMAL(6, 2) NULL, -- Completely open, e.g. 40.00, 24.00, 16.00, 9.00
    capacity_cans INT UNSIGNED NULL, -- 70 for Tata Ace
    ownership_type ENUM('owned', 'leased', 'attached') DEFAULT 'owned',
    gps_device_id VARCHAR(100) NULL,
    last_latitude DECIMAL(10, 7) NULL,
    last_longitude DECIMAL(10, 7) NULL,
    last_speed_kmh DECIMAL(5, 2) DEFAULT 0.00,
    last_ignition_on BOOLEAN DEFAULT FALSE,
    last_ping_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_vehicle_type (vehicle_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Drivers
CREATE TABLE drivers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    license_number VARCHAR(50) NULL,
    assigned_division ENUM('tanker', 'can', 'general') NOT NULL,
    wage_type ENUM('weekly', 'monthly', 'per_trip') DEFAULT 'per_trip',
    base_wage DECIMAL(10, 2) DEFAULT 0.00,
    default_batta_per_trip DECIMAL(8, 2) DEFAULT 250.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Customers
CREATE TABLE customers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    customer_code VARCHAR(50) NULL UNIQUE,
    contact_person VARCHAR(150) NULL,
    phone VARCHAR(20) NOT NULL,
    gstin VARCHAR(20) NULL,
    billing_address TEXT NULL,
    delivery_location_lat DECIMAL(10, 7) NULL,
    delivery_location_lng DECIMAL(10, 7) NULL,
    geofence_radius_meters INT UNSIGNED DEFAULT 250,
    division_type ENUM('tanker', 'can', 'both') NOT NULL,
    billing_cycle ENUM('daily', 'weekly', '15_days', 'monthly_1_to_30', 'monthly_custom') DEFAULT 'monthly_1_to_30',
    credit_limit DECIMAL(12, 2) DEFAULT 0.00,
    credit_days_allowed INT UNSIGNED DEFAULT 30,
    current_credit_balance DECIMAL(12, 2) DEFAULT 0.00,
    external_pos_id VARCHAR(100) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_div (division_type),
    INDEX idx_customer_balance (current_credit_balance)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Trip Surcharge Types
CREATE TABLE trip_surcharge_types (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name_en VARCHAR(100) NOT NULL,
    name_ta VARCHAR(100) NOT NULL,
    billing_type ENUM('flat', 'per_hour', 'per_km', 'manual') NOT NULL,
    default_rate DECIMAL(10, 2) DEFAULT 0.00,
    is_taxable BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Customer Rate Slabs
CREATE TABLE customer_rate_slabs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    service_type ENUM('tanker_trip', 'can_delivery', 'special_water') NOT NULL,
    capacity_kl DECIMAL(6, 2) NULL,
    price_per_load DECIMAL(10, 2) NOT NULL,
    price_per_kl DECIMAL(10, 2) NULL,
    can_sale_rate DECIMAL(8, 2) NULL,
    can_deposit_rate DECIMAL(8, 2) NULL,
    gst_rate_percent DECIMAL(5, 2) DEFAULT 0.00,
    motor_charge_override DECIMAL(10, 2) NULL,
    waiting_hour_rate_override DECIMAL(10, 2) NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_slab_lookup (customer_id, service_type, capacity_kl)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Tanker Trips
CREATE TABLE tanker_trips (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    dispatched_by_user_id BIGINT UNSIGNED NOT NULL,
    
    trip_date DATE NOT NULL,
    capacity_kl DECIMAL(6, 2) NOT NULL,
    load_source VARCHAR(150) NOT NULL DEFAULT 'Main RO Water Plant',
    destination_site VARCHAR(255) NOT NULL,
    status ENUM('scheduled', 'dispatched', 'in_transit', 'at_destination', 'unloading', 'completed', 'cancelled') DEFAULT 'scheduled',
    
    odometer_start INT UNSIGNED NULL,
    odometer_end INT UNSIGNED NULL,
    total_km INT UNSIGNED GENERATED ALWAYS AS (odometer_end - odometer_start) STORED,
    
    start_time DATETIME NULL,
    arrival_time DATETIME NULL,
    end_time DATETIME NULL,
    
    trip_fare DECIMAL(10, 2) NOT NULL,
    motor_used BOOLEAN DEFAULT FALSE,
    motor_charges DECIMAL(10, 2) DEFAULT 0.00,
    waiting_time_hours DECIMAL(4, 2) DEFAULT 0.00,
    waiting_time_charges DECIMAL(10, 2) DEFAULT 0.00,
    long_distance_km INT UNSIGNED DEFAULT 0,
    long_distance_surcharge DECIMAL(10, 2) DEFAULT 0.00,
    miscellaneous_charges DECIMAL(10, 2) DEFAULT 0.00,
    miscellaneous_description VARCHAR(255) NULL,
    
    total_surcharges DECIMAL(10, 2) GENERATED ALWAYS AS (
        motor_charges + waiting_time_charges + long_distance_surcharge + miscellaneous_charges
    ) STORED,
    total_billing_amount DECIMAL(10, 2) GENERATED ALWAYS AS (
        trip_fare + motor_charges + waiting_time_charges + long_distance_surcharge + miscellaneous_charges
    ) STORED,
    
    driver_batta DECIMAL(8, 2) DEFAULT 0.00,
    total_expenses DECIMAL(10, 2) DEFAULT 0.00,
    
    gate_pass_photo_path VARCHAR(255) NULL,
    receiver_signature_path VARCHAR(255) NULL,
    receiver_name VARCHAR(150) NULL,
    receiver_phone VARCHAR(20) NULL,
    
    is_invoiced BOOLEAN DEFAULT FALSE,
    invoice_id BIGINT UNSIGNED NULL,
    notes TEXT NULL,
    idempotency_key VARCHAR(100) NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (dispatched_by_user_id) REFERENCES users(id),
    INDEX idx_trip_date (trip_date),
    INDEX idx_trip_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Can Routes (Tata Ace Shifts)
CREATE TABLE can_routes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_date DATE NOT NULL,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,
    helper_name VARCHAR(100) NULL,
    route_name VARCHAR(150) NOT NULL,
    status ENUM('active', 'surrendered', 'closed') DEFAULT 'active',
    
    total_loaded_cans INT UNSIGNED NOT NULL DEFAULT 0,
    total_delivered_cans INT UNSIGNED DEFAULT 0,
    total_empty_cans_returned INT UNSIGNED DEFAULT 0,
    total_damaged_cans INT UNSIGNED DEFAULT 0,
    current_truck_stock INT UNSIGNED GENERATED ALWAYS AS (total_loaded_cans - total_delivered_cans) STORED,
    
    total_cash_sales DECIMAL(10, 2) DEFAULT 0.00,
    total_upi_sales DECIMAL(10, 2) DEFAULT 0.00,
    total_credit_sales DECIMAL(10, 2) DEFAULT 0.00,
    total_sales_value DECIMAL(10, 2) GENERATED ALWAYS AS (total_cash_sales + total_upi_sales + total_credit_sales) STORED,
    
    total_plant_cost DECIMAL(10, 2) DEFAULT 0.00,
    total_distance_km DECIMAL(6, 2) DEFAULT 0.00,
    driver_wage DECIMAL(10, 2) DEFAULT 1000.00,
    
    shift_start_time DATETIME NULL,
    shift_end_time DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    INDEX idx_can_route_date (route_date, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Multi-Plant Refill Intakes
CREATE TABLE can_plant_intakes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    can_route_id BIGINT UNSIGNED NOT NULL,
    intake_sequence INT UNSIGNED NOT NULL DEFAULT 1,
    plant_slip_number VARCHAR(50) NULL,
    cans_loaded INT UNSIGNED NOT NULL,
    purchase_rate_per_can DECIMAL(8, 2) NOT NULL DEFAULT 8.00,
    total_cost DECIMAL(10, 2) GENERATED ALWAYS AS (cans_loaded * purchase_rate_per_can) STORED,
    plant_operator_name VARCHAR(100) NULL,
    slip_photo_path VARCHAR(255) NULL,
    loaded_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (can_route_id) REFERENCES can_routes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Can Customer Deliveries
CREATE TABLE can_deliveries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    can_route_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    cans_delivered INT UNSIGNED NOT NULL,
    empty_cans_collected INT UNSIGNED NOT NULL DEFAULT 0,
    rate_per_can DECIMAL(8, 2) NOT NULL,
    total_amount DECIMAL(10, 2) GENERATED ALWAYS AS (cans_delivered * rate_per_can) STORED,
    payment_mode ENUM('cash', 'upi', 'credit') NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    unpaid_balance DECIMAL(10, 2) GENERATED ALWAYS AS (total_amount - amount_paid) STORED,
    payment_time DATETIME NOT NULL,
    payment_reference VARCHAR(100) NULL,
    delivery_lat DECIMAL(10, 7) NOT NULL,
    delivery_lng DECIMAL(10, 7) NOT NULL,
    client_uuid VARCHAR(100) NULL UNIQUE,
    notes VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (can_route_id) REFERENCES can_routes(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    INDEX idx_delivery_cust (customer_id, payment_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Can Cash Surrenders
CREATE TABLE can_cash_surrenders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    can_route_id BIGINT UNSIGNED NOT NULL UNIQUE,
    driver_id BIGINT UNSIGNED NOT NULL,
    verified_by_user_id BIGINT UNSIGNED NOT NULL,
    expected_cash_amount DECIMAL(10, 2) NOT NULL,
    actual_cash_surrendered DECIMAL(10, 2) NOT NULL,
    cash_shortage_excess DECIMAL(10, 2) GENERATED ALWAYS AS (actual_cash_surrendered - expected_cash_amount) STORED,
    expected_empty_cans INT UNSIGNED NOT NULL,
    actual_empty_cans_returned INT UNSIGNED NOT NULL,
    missing_cans INT UNSIGNED GENERATED ALWAYS AS (expected_empty_cans - actual_empty_cans_returned) STORED,
    status ENUM('matched', 'shortage_approved', 'disputed') DEFAULT 'matched',
    remarks TEXT NULL,
    surrendered_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (can_route_id) REFERENCES can_routes(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (verified_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. Bakery Items Master
CREATE TABLE bakery_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item_name_en VARCHAR(100) NOT NULL,
    item_name_ta VARCHAR(100) NOT NULL,
    unit_of_measure VARCHAR(30) NOT NULL,
    standard_price DECIMAL(10, 2) NULL,
    external_pos_id VARCHAR(100) NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. Bakery Vendors
CREATE TABLE bakery_vendors (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100) NULL,
    phone VARCHAR(20) NOT NULL,
    current_pending_balance DECIMAL(12, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. Bakery Purchases
CREATE TABLE bakery_purchases (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_date DATE NOT NULL,
    bakery_item_id BIGINT UNSIGNED NOT NULL,
    bakery_vendor_id BIGINT UNSIGNED NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    rate_per_unit DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * rate_per_unit) STORED,
    paid_amount DECIMAL(10, 2) DEFAULT 0.00,
    payment_mode ENUM('cash', 'upi', 'vendor_credit') NOT NULL,
    bill_photo_path VARCHAR(255) NULL,
    entered_by_user_id BIGINT UNSIGNED NOT NULL,
    notes VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (bakery_item_id) REFERENCES bakery_items(id),
    FOREIGN KEY (bakery_vendor_id) REFERENCES bakery_vendors(id),
    FOREIGN KEY (entered_by_user_id) REFERENCES users(id),
    INDEX idx_bakery_purchase_date (purchase_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. Bakery Daily Closings (3-Minute Reconciler)
CREATE TABLE bakery_daily_closings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    closing_date DATE NOT NULL UNIQUE,
    closed_by_user_id BIGINT UNSIGNED NOT NULL,
    physical_drawer_cash DECIMAL(10, 2) NOT NULL,
    coins_amount DECIMAL(10, 2) DEFAULT 0.00,
    upi_collections DECIMAL(10, 2) NOT NULL,
    cash_expenses_paid_from_drawer DECIMAL(10, 2) DEFAULT 0.00,
    total_counter_revenue DECIMAL(10, 2) GENERATED ALWAYS AS (physical_drawer_cash + coins_amount + upi_collections) STORED,
    net_cash_banked DECIMAL(10, 2) GENERATED ALWAYS AS ((physical_drawer_cash + coins_amount) - cash_expenses_paid_from_drawer) STORED,
    wastage_json JSON NULL,
    notes TEXT NULL,
    verified_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (closed_by_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. Telematics Pings & Stops
CREATE TABLE vehicle_telematics_pings (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    speed_kmh DECIMAL(5, 2) DEFAULT 0.00,
    heading_deg DECIMAL(5, 2) DEFAULT 0.00,
    battery_level INT UNSIGNED NULL,
    ignition_on BOOLEAN DEFAULT TRUE,
    recorded_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    INDEX idx_telematics_vehicle_time (vehicle_id, recorded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vehicle_route_stops (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    can_route_id BIGINT UNSIGNED NULL,
    tanker_trip_id BIGINT UNSIGNED NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    location_label VARCHAR(150) NULL,
    customer_id BIGINT UNSIGNED NULL,
    arrival_time DATETIME NOT NULL,
    departure_time DATETIME NULL,
    dwell_duration_minutes INT UNSIGNED DEFAULT 0,
    stop_category ENUM('customer_delivery', 'plant_loading', 'fuel_station', 'rest_break', 'traffic_halt', 'unauthorized_idle') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    INDEX idx_stop_vehicle_time (vehicle_id, arrival_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. Invoices & Single-Entry P&L
CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    subtotal_amount DECIMAL(12, 2) NOT NULL,
    gst_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(12, 2) NOT NULL,
    paid_amount DECIMAL(12, 2) DEFAULT 0.00,
    outstanding_balance DECIMAL(12, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    status ENUM('draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled') DEFAULT 'draft',
    aging_bucket ENUM('current_0_15', 'due_16_30', 'overdue_31_60', 'critical_60_plus') DEFAULT 'current_0_15',
    pdf_path VARCHAR(255) NULL,
    created_by_user_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (created_by_user_id) REFERENCES users(id),
    INDEX idx_invoice_aging (aging_bucket, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
