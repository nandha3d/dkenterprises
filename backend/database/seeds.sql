-- ==============================================================================
-- DK Track — Real-World Seed Data
-- Derived directly from client interview transcript & physical notebook records
-- ==============================================================================

-- 1. Users
INSERT INTO users (id, name, phone, email, password_hash, role, division_access, preferred_language) VALUES
(1, 'DK Admin / Owner', '9842100001', 'owner@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'owner', 'all', 'ta'),
(2, 'Dinesh (Tanker Manager)', '9842100002', 'dinesh@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'tanker_manager', 'tanker', 'ta'),
(3, 'Savari (Can Manager)', '9842100003', 'savari@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'can_manager', 'can', 'ta'),
(4, 'Bakery Manager (Family)', '9842100004', 'bakery@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'bakery_manager', 'bakery', 'ta'),
(5, 'Suresh (Tanker Driver)', '9842100005', 'suresh@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'driver', 'tanker', 'ta'),
(6, 'Raja (Can Delivery Boy)', '9842100006', 'raja@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'driver', 'can', 'ta'),
(7, 'External Auditor', '9842100007', 'auditor@dkenterprises.in', '$2y$10$abcdefghijklmnopqrstuv', 'auditor', 'all', 'en');

-- 2. Vehicles (5 active + 2 spare tankers + Tata Ace)
INSERT INTO vehicles (id, vehicle_number, vehicle_type, capacity_kl, capacity_cans, ownership_type, gps_device_id, last_latitude, last_longitude, last_speed_kmh, last_ignition_on) VALUES
(1, 'TN 38 BX 4412', 'can_truck', NULL, 70, 'owned', 'GPS-TATA-ACE-01', 11.018221, 76.964119, 18.2, 1),
(2, 'TN 34 AF 4954', 'tanker', 24.00, NULL, 'owned', 'GPS-TANK-4954', 11.042100, 77.011200, 0.0, 1),
(3, 'TN 38 CY 5599', 'tanker', 16.00, NULL, 'owned', 'GPS-TANK-5599', 11.025500, 76.982100, 36.5, 1),
(4, 'TN 38 DZ 8841', 'tanker', 40.00, NULL, 'owned', 'GPS-TANK-8841', 11.081200, 77.042100, 48.0, 1),
(5, 'TN 34 BF 1120', 'tanker', 9.00, NULL, 'owned', 'GPS-TANK-1120', 11.011200, 76.951200, 0.0, 0),
(6, 'TN 38 AB 3340', 'tanker', 16.00, NULL, 'owned', 'GPS-TANK-3340', 11.002100, 76.941200, 0.0, 0),
(7, 'TN 34 KL 7701', 'tanker', 9.00, NULL, 'owned', 'GPS-TANK-7701', 11.034100, 76.974100, 0.0, 0);

-- 3. Drivers
INSERT INTO drivers (id, user_id, full_name, phone, license_number, assigned_division, wage_type, base_wage, default_batta_per_trip) VALUES
(1, 5, 'Suresh', '9842100005', 'TN-38-2018-00412', 'tanker', 'per_trip', 0.00, 250.00),
(2, 6, 'Raja', '9842100006', 'TN-38-2021-00891', 'can', 'weekly', 7000.00, 100.00),
(3, NULL, 'Ajith', '9842100011', 'TN-34-2019-00332', 'tanker', 'per_trip', 0.00, 250.00),
(4, NULL, 'Sher Bist', '9842100012', 'TN-38-2020-00142', 'tanker', 'per_trip', 0.00, 200.00),
(5, NULL, 'Kuppusamy', '9842100013', 'TN-38-2016-00991', 'tanker', 'per_trip', 0.00, 250.00);

-- 4. Trip Surcharges Master
INSERT INTO trip_surcharge_types (code, name_en, name_ta, billing_type, default_rate) VALUES
('motor_usage', 'Motor / Pump Unloading', 'மோட்டார் பயன்பாடு கட்டணம்', 'flat', 250.00),
('waiting_time', 'Waiting Time Detention', 'காத்திருப்பு கட்டணம்', 'per_hour', 150.00),
('long_distance', 'Long Distance Surcharge', 'தொலைதூர கூடுதல் கட்டணம்', 'per_km', 20.00),
('toll', 'Highway Toll / Gate Permit', 'டோல்கேட் / அனுமதி ரசீது', 'manual', 0.00);

-- 5. Real Customers (From Interview & Google Sheet)
INSERT INTO customers (id, company_name, customer_code, contact_person, phone, division_type, billing_cycle, credit_limit, current_credit_balance) VALUES
(1, 'Texvalley Corporate Campus', 'CUST-TEXVALLEY', 'Sundaram (Facility Mgr)', '9842199001', 'tanker', 'monthly_1_to_30', 200000.00, 85000.00),
(2, 'Amirtha Milk Dairy & Genset', 'CUST-AMIRTHA', 'Senthil', '9842199002', 'tanker', '15_days', 150000.00, 124000.00),
(3, 'The Chennai Silks Warehouse', 'CUST-TCS', 'Murugan', '9842199003', 'tanker', 'monthly_1_to_30', 100000.00, 42000.00),
(4, 'Vinayaga Spinning Mill', 'CUST-VINAYAGA', 'Manager', '9842199004', 'tanker', 'monthly_1_to_30', 150000.00, 95000.00),
(5, 'ATP Association - CRMS Project', 'CUST-ATP', 'Project Incharge', '9842199005', 'tanker', 'weekly', 50000.00, 25000.00),
(6, 'Muthampalayam Construction', 'CUST-MUTHAM', 'Site Supervisor', '9842199006', 'tanker', 'weekly', 30000.00, 12000.00),
(7, 'Aran Cafe - 1', 'CAN-ARAN-1', 'Aran Shop Owner', '9842199011', 'can', 'daily', 5000.00, 0.00),
(8, 'Aran Cafe - 2', 'CAN-ARAN-2', 'Branch Manager', '9842199012', 'can', 'daily', 5000.00, 100.00),
(9, 'Balaji Cafe', 'CAN-BALAJI', 'Balaji', '9842199013', 'can', 'daily', 5000.00, 0.00),
(10, 'Black Pekoe Tea', 'CAN-PEKOE', 'Tea Stall Owner', '9842199014', 'can', 'daily', 3000.00, 0.00),
(11, 'Surya Tex - 1', 'CAN-SURYA-1', 'Factory Incharge', '9842199015', 'can', 'weekly', 10000.00, 260.00),
(12, 'Santha Company', 'CAN-SANTHA', 'Admin', '9842199016', 'can', 'weekly', 15000.00, 740.00),
(13, 'Palani Hotel', 'CAN-PALANI', 'Palani', '9842199017', 'can', 'daily', 5000.00, 220.00);

-- 6. Rate Slabs
INSERT INTO customer_rate_slabs (customer_id, service_type, capacity_kl, price_per_load, can_sale_rate, gst_rate_percent, motor_charge_override) VALUES
(1, 'tanker_trip', 40.00, 3500.00, NULL, 0.00, 250.00),
(1, 'tanker_trip', 24.00, 2500.00, NULL, 0.00, 250.00),
(2, 'tanker_trip', 24.00, 2400.00, NULL, 0.00, 200.00),
(2, 'tanker_trip', 16.00, 1800.00, NULL, 0.00, 200.00),
(3, 'tanker_trip', 16.00, 1800.00, NULL, 0.00, 200.00),
(4, 'tanker_trip', 24.00, 2500.00, NULL, 0.00, 250.00),
(7, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL),
(8, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL),
(9, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL),
(10, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL),
(11, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL),
(12, 'can_delivery', NULL, 0.00, 20.00, 0.00, NULL);

-- 7. Bakery Items Master (From Image 2 Daily Purchases)
INSERT INTO bakery_items (item_name_en, item_name_ta, unit_of_measure, standard_price) VALUES
('Coriander', 'கொத்தமல்லி', 'bundle', 210.00),
('Tomato', 'தக்காளி', 'kg', 35.00),
('Cake & Bun', 'கேக் & பன்', 'tray', 390.00),
('Puffs', 'பப்ஸ்', 'tray', 300.00),
('Soft Drinks (7up, Pepsi, Slice)', 'குளிர்பானங்கள் (7up/Pepsi/Slice)', 'crate', 270.00),
('Sugar', 'சர்க்கரை', 'kg', 58.60),
('Vim Lemons Dishwash', 'விம் லெமன் பாத்திரம் கழுவும் திரவம்', 'bottle', 139.00),
('Brownies', 'பிரவுனி கேக்', 'box', 530.00),
('Disposables & Cups', 'டிஸ்போசபிள் பேப்பர் கப்', 'pack', 200.00),
('Giffy Green Lime', 'கிஃபி கிரீன் லைம்', 'pack', 206.00),
('Bottle Gourd', 'சுரைக்காய்', 'kg', 65.00),
('Palkova', 'பால் கோவா', 'kg', 500.00),
('Fresh Milk Packets', 'பசும்பால் பாக்கெட் (20 Pockets)', 'packet', 32.00);

-- 8. Bakery Vendors
INSERT INTO bakery_vendors (vendor_name, contact_person, phone, current_pending_balance) VALUES
('Balaji Food & Ingredients', 'Balaji', '9842155001', 3500.00),
('Sri Murugan Bakery Supplies', 'Murugan', '9842155002', 4800.00),
('Kavin Dairy Products', 'Kavin', '9842155003', 1200.00),
('City Packaging & Disposables', 'Rahman', '9842155004', 850.00);
