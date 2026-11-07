# Zolo ERP — Mobile ERP Feature Parity Audit & Matrix

**Document Reference:** `docs/mobile/MOBILE_ERP_FEATURE_AUDIT.md`  
**Date:** 2026-11-07  
**Repository:** `nandha3d/dkenterprises` (`main` branch)  
**Scope:** Complete discovery across Laravel ERP backend (`routes/`, `app/Http/Controllers/`, `app/Models/`, `app/Services/`) vs Flutter Mobile Client (`mobile/lib/`).

---

## 1. Executive Summary & Audit Methodology

This audit inspects every route, controller, Eloquent model, platform service, permission, and module configuration within the Zolo ERP / DK Enterprises codebase to establish an authoritative feature parity baseline.

### Evaluation Status Categories:
- **Fully implemented:** End-to-end functionality exists in both backend and mobile with real DB persistence, validation, and UI.
- **Partially implemented:** Feature exists on mobile but relies on hardcoded data, incomplete endpoints, or lack of offline/error handling.
- **API available, mobile missing:** Robust RESTful API endpoint exists under `/api/v1/`, but mobile client has zero screens or service calls for it.
- **Backend available, API missing:** Controller and service logic exist in web ERP (`routes/web.php`), but no JSON API endpoint is exposed in `routes/api.php`.
- **Not implemented:** Workflow neither exposed via API nor implemented on mobile.
- **Requires permission or security correction:** Existing endpoint lacks Sanctum auth, company isolation, or role-based permission checks.

---

## 2. ERP Module Discovery & Feature Parity Matrix

### Module 1: Executive Dashboard & Multi-Entity Workspace
1. **Module Name:** Executive Dashboard & Workspace Hub
2. **Available Functionality:** Multi-company rollup (`/workspace`), company switcher, gross vs operating margin charts, turnover distribution, dues exposure meter, period filters (today, this month, fiscal year), branch and warehouse filters.
3. **Backend Controller:** `WorkspaceController` (Master group), `HomeController` / `DashboardController` (Company-specific).
4. **API Endpoints:** `GET /api/v1/mobile/dashboard/{role}` (partially company-scoped).
5. **Database Models:** `Company`, `CompanyGroup`, `CompanyBranch`, `FiscalYear`, `Sale`, `Purchase`, `Payment`.
6. **Relationships:** `CompanyGroup` hasMany `Company`; `Company` hasMany `CompanyBranch`, `FiscalYear`.
7. **Existing Permissions:** `today_sale`, `today_profit`, `revenue_profit_summary`, `cash_flow`.
8. **Available CRUD Operations:** Read-only analytical queries and rollups.
9. **Existing Reports:** 6-month margin trajectory, turnover share donuts, uncollected dues exposure.
10. **Existing Approval Workflows:** N/A.
11. **Mobile Implementation Status:** **Partially implemented** (Super Admin and Admin dashboards show fixed/unfiltered cards; no global company/branch switcher; no drill-downs).
12. **Missing APIs or Functionality:** Master group consolidated summary API (`/api/v1/workspace/summary`), period comparative trend API (`/api/v1/dashboard/trends`).

---

### Module 2: Sales & Commercial Management
1. **Module Name:** Sales, Orders, Deliveries & Commercial Desk
2. **Available Functionality:** Sales invoicing, Commercial Voucher Desk, Quotations, Sales Orders, Delivery Challans, Packing Slips, Dispatch Register, Sales Returns (Credit Notes), Retail POS, Customer Payments & Allocations, Couriers, Gift Cards, Coupons, Installment Plans.
3. **Backend Controller:** `SaleController`, `CommercialOrderController`, `QuotationController`, `DeliveryController`, `DeliveryChallanController`, `PackingSlipController`, `DispatchRegisterController`, `ReturnController`, `ExchangeController`, `InstallmentController`, `GiftCardController`, `CouponController`.
4. **API Endpoints:** 
   - `GET /api/v1/sales`
   - `POST /api/v1/sales`
   - `GET /api/v1/sales/{id}`
   - `POST /api/v1/sales/{id}/payments`
   - `GET /api/v1/mobile/invoices`
5. **Database Models:** `Sale`, `Product_Sale`, `SalesOrder`, `CommercialOrderItem`, `Quotation`, `ProductQuotation`, `Returns`, `ProductReturn`, `Delivery`, `DeliveryChallan`, `PackingSlip`, `Payment`.
6. **Relationships:** `Sale` belongsTo `Customer`, `Warehouse`, `Biller`; hasMany `Product_Sale`, `Payment`.
7. **Existing Permissions:** `sales-index`, `sales-add`, `sales-edit`, `sales-delete`, `quotes-index`, `quotes-add`, `quotes-edit`, `returns-index`, `packing_slip_challan`.
8. **Available CRUD Operations:** Full Create, Read, Update, Delete, Print A4/Thermal, Duplicate, Return.
9. **Existing Reports:** Sales Report, Daily Sale, Monthly Summary, Payment Report, Challan Register.
10. **Existing Approval Workflows:** Quotation conversion to Sales Order, credit limit override checks (`sales.override_credit`).
11. **Mobile Implementation Status:** **Partially implemented** (Only read-only invoices list and quick water can POS exist; Quotations, Sales Orders, Challans, Credit Notes, and full multi-item Sales Bills completely missing on mobile).
12. **Missing APIs or Functionality:** `POST /api/v1/quotations`, `POST /api/v1/sales-orders`, `POST /api/v1/delivery-challans`, `POST /api/v1/sales/returns`.

---

### Module 3: Purchase & Procurement Management
1. **Module Name:** Purchases, GRN & Vendor Procurement
2. **Available Functionality:** Purchase bills, Purchase Orders, Goods Received Notes (GRN) with batch and expiry tracking, Purchase Returns (Debit Notes), Supplier Payments & Allocations, Landed Cost allocation.
3. **Backend Controller:** `PurchaseController`, `CommercialOrderController`, `GoodsReceivedNoteController`, `ReturnPurchaseController`.
4. **API Endpoints:** 
   - `GET /api/v1/purchases`
   - `POST /api/v1/purchases`
   - `GET /api/v1/purchases/{id}`
   - `POST /api/v1/purchases/{id}/payments`
5. **Database Models:** `Purchase`, `ProductPurchase`, `GoodsReceivedNote`, `GoodsReceivedNoteItem`, `ReturnPurchase`, `PurchaseProductReturn`, `Supplier`, `ProductBatch`.
6. **Relationships:** `Purchase` belongsTo `Supplier`, `Warehouse`; hasMany `ProductPurchase`, `GoodsReceivedNote`.
7. **Existing Permissions:** `purchases-index`, `purchases-add`, `purchases-edit`, `purchases-delete`, `purchase-return-index`.
8. **Available CRUD Operations:** Full Create, Read, Update, Delete, Duplicate, Goods Receipt.
9. **Existing Reports:** Purchase Report, Daily Purchase, Monthly Purchase, Due to Suppliers.
10. **Existing Approval Workflows:** Purchase Order approval before GRN creation.
11. **Mobile Implementation Status:** **API available, mobile missing** (Mobile client has zero purchase screens, zero purchase order views, and zero GRN intake workflows).
12. **Missing APIs or Functionality:** `POST /api/v1/grn` (Goods receipt with lot/expiry and photo proof), `POST /api/v1/purchases/returns`.

---

### Module 4: Inventory & Warehouse Logistics
1. **Module Name:** Inventory, Warehouses, Lots & Stock Counts
2. **Available Functionality:** Multi-warehouse stock tracking, Stock Movements ledger, Lot/Batch & Expiry tracking, FEFO dispatch, Stock Adjustments, Inter-Warehouse Transfers (Draft -> Dispatched -> In-Transit -> Received), Physical Stock Count auditing, Damage Stock write-offs.
3. **Backend Controller:** `WarehouseController`, `TransferController`, `AdjustmentController`, `StockCountController`, `DamageStockController`, `InventoryLotReportController`, `OperationsController` (`fefo`, `lots`, `pieces`).
4. **API Endpoints:**
   - `GET /api/v1/inventory/valuation`
   - `POST /api/v1/inventory/transfer`
   - `GET /api/v1/operations/inventory/fefo`
   - `GET /api/v1/operations/inventory/lots`
5. **Database Models:** `Warehouse`, `Product_Warehouse`, `ProductBatch`, `StockMovement`, `StockMovementLine`, `Transfer`, `ProductTransfer`, `Adjustment`, `ProductAdjustment`, `StockCount`, `DamageStock`.
6. **Relationships:** `Warehouse` hasMany `Product_Warehouse`; `StockMovement` hasMany `StockMovementLine`.
7. **Existing Permissions:** `warehouse-stock-report`, `stock_count`, `adjustment`, `transfers-index`, `transfers-add`, `damage_stock`.
8. **Available CRUD Operations:** Create stock adjustment, transfer stock, execute barcode stock count, record damage.
9. **Existing Reports:** Warehouse Stock Report, Product Expiry Alert, Quantity Alert, Stock Valuation.
10. **Existing Approval Workflows:** Transfer dispatch and receipt confirmation.
11. **Mobile Implementation Status:** **Partially implemented** (Only water jar spot audit exists; full stock ledger, barcode stock counting, warehouse transfers, and lot views completely missing).
12. **Missing APIs or Functionality:** `POST /api/v1/inventory/adjustments`, `POST /api/v1/inventory/stock-count`, `POST /api/v1/inventory/damage-stock`.

---

### Module 5: Product Catalog & Master Data
1. **Module Name:** Products, Categories, Brands & Pricing Matrices
2. **Available Functionality:** Product catalog with HSN codes, tax slabs, units, composite products/recipes, brand & category hierarchies, multiple price lists, barcode generation, initial warehouse balances.
3. **Backend Controller:** `ProductController`, `CategoryController`, `BrandController`, `UnitController`, `TaxController`, `VariantController`, `BarcodeController`.
4. **API Endpoints:**
   - `GET /api/v1/products`
   - `GET /api/v1/products/search/{term}`
   - `GET /api/v1/products/{id}`
   - `GET /api/v1/mobile/products`
5. **Database Models:** `Product`, `Category`, `Brand`, `Unit`, `Tax`, `Variant`, `ProductVariant`, `ProductBatch`.
6. **Relationships:** `Product` belongsTo `Category`, `Brand`, `Unit`, `Tax`; hasMany `ProductVariant`, `ProductBatch`.
7. **Existing Permissions:** `products-index`, `products-add`, `products-edit`, `products-delete`, `category`, `brand`, `unit`, `tax`.
8. **Available CRUD Operations:** Full Create, Read, Update, Delete, Barcode generation, Stock linking.
9. **Existing Reports:** Product History, Expiry Report, Best Seller, Quantity Alert.
10. **Existing Approval Workflows:** N/A.
11. **Mobile Implementation Status:** **Partially implemented** (Read-only price list of first 50 products exists; search, barcode scan, category browsing, product creation/editing completely missing).
12. **Missing APIs or Functionality:** `POST /api/v1/products` (Product quick-add with camera photo upload and barcode scanner).

---

### Module 6: Parties Master Data (Customers & Suppliers)
1. **Module Name:** Customers, Customer Groups, Suppliers & Agents
2. **Available Functionality:** Customer & Supplier 360 profiles, credit limits, payment terms, GSTIN lookup & validation, opening balances, account aging buckets, agents/brokers, areas/routes, KYC document onboarding.
3. **Backend Controller:** `CustomerController`, `CustomerGroupController`, `SupplierController`, `AgentController`, `AreaController`, `BillerController`.
4. **API Endpoints:**
   - `GET /api/v1/customers`
   - `GET /api/v1/suppliers`
   - `GET /api/v1/mobile/customers`
   - `POST /api/v1/mobile/customer-onboard`
5. **Database Models:** `Customer`, `CustomerGroup`, `Supplier`, `Agent`, `Area`, `Biller`, `WaterCanInventory`.
6. **Relationships:** `Customer` belongsTo `CustomerGroup`, `Company`; hasMany `Sale`, `WaterCanDelivery`.
7. **Existing Permissions:** `customers-index`, `customers-add`, `customers-edit`, `customers-delete`, `suppliers-index`, `suppliers-add`, `suppliers-edit`, `customer_group`.
8. **Available CRUD Operations:** Full Create, Read, Update, Delete, Ledger drill-down, Statement print.
9. **Existing Reports:** Customer Report (Single-view ledger), Supplier Report, Customer Due Report, Supplier Due Report.
10. **Existing Approval Workflows:** Credit limit override approval.
11. **Mobile Implementation Status:** **Partially implemented** (Mobile has basic customer list and simple onboarding form; Supplier directory, Agent list, Party 360 view, and Aging tabs missing).
12. **Missing APIs or Functionality:** `POST /api/v1/suppliers` (Supplier create/edit), `GET /api/v1/customers/{id}/statement` (PDF/JSON statement).

---

### Module 7: Double-Entry Accounting & Financial Management
1. **Module Name:** Double-Entry General Ledger, Vouchers & Financial Statements
2. **Available Functionality:** Complete chart of accounts, automated journal entries, voucher desk (Receipt, Payment, Journal, Contra, Expense), cash book, day book, trial balance, profit & loss statement, balance sheet, customer/supplier collections with invoice-level allocation, open items clearing, periodic inventory close.
3. **Backend Controller:** `ChartOfAccountsController`, `JournalEntryController`, `VoucherController`, `FinancialReportController`, `CollectionController`, `DueManagementController`, `AccountsController`, `MoneyTransferController`.
4. **API Endpoints:**
   - `GET /api/v1/accounting/chart-of-accounts`
   - `GET /api/v1/accounting/trial-balance`
   - `GET /api/v1/accounting/profit-and-loss`
   - `GET /api/v1/accounting/balance-sheet`
   - `GET /api/v1/accounting/general-ledger/{id}`
   - `POST /api/v1/accounting/journal-entries`
   - `POST /api/v1/accounting/vouchers`
   - `GET /api/v1/accounting/day-book`
   - `GET /api/v1/accounting/cash-book`
   - `GET /api/v1/accounting/ageing`
   - `GET /api/v1/accounting/open-items`
   - `POST /api/v1/accounting/allocations`
   - `GET /api/v1/accounting/collections`
   - `POST /api/v1/accounting/collections`
   - `POST /api/v1/mobile/collect-payment`
   - `GET /api/v1/mobile/financials`
5. **Database Models:** `ChartOfAccount`, `JournalEntry`, `JournalItem`, `AccountAllocation`, `AccountOpenItem`, `CollectionRecord`, `FiscalYear`, `Account`.
6. **Relationships:** `JournalEntry` hasMany `JournalItem`; `JournalItem` belongsTo `ChartOfAccount`.
7. **Existing Permissions:** `account-index`, `balance-sheet`, `profit-loss`, `account-statement`, `money-transfer`, `accounting.reports.view`, `accounting.voucher.post`.
8. **Available CRUD Operations:** Post voucher, reverse journal, allocate receipts, generate financial statements.
9. **Existing Reports:** Trial Balance, P&L, Balance Sheet, Cash Flow, Day Book, Cash Book, Aging Report.
10. **Existing Approval Workflows:** Journal reversal authorization, financial period lock.
11. **Mobile Implementation Status:** **API available, mobile missing** (The backend API is exceptionally rich and complete, but mobile currently only has a single summary card calling `/mobile/financials` with zero vouchers, books, or financial statement views).
12. **Missing APIs or Functionality:** Mobile UI screens for Day Book, Cash Book, Collections with open-item allocation, Chart of Accounts browser, and Statement viewer.

---

### Module 8: Expenses & Incomes
1. **Module Name:** Operational Expenses & Miscellaneous Incomes
2. **Available Functionality:** Quick expense entry with category selection, tax deduction, bill photo attachment, cash/bank disbursement, recurring expenses, income entries.
3. **Backend Controller:** `ExpenseController`, `ExpenseCategoryController`, `IncomeController`, `IncomeCategoryController`.
4. **API Endpoints:** None currently under `/api/v1/`.
5. **Database Models:** `Expense`, `ExpenseCategory`, `Income`, `IncomeCategory`, `Account`.
6. **Relationships:** `Expense` belongsTo `ExpenseCategory`, `Warehouse`, `Account`.
7. **Existing Permissions:** `expenses-index`, `expenses-add`, `expenses-edit`, `expenses-delete`, `incomes-index`, `incomes-add`.
8. **Available CRUD Operations:** Create, Read, Update, Delete.
9. **Existing Reports:** Expense Report, Income vs Expense breakdown.
10. **Existing Approval Workflows:** High-value expense manager approval.
11. **Mobile Implementation Status:** **Backend available, API missing** (Web has complete expense/income management, but mobile has no screens and API has no endpoints).
12. **Missing APIs or Functionality:** `GET /api/v1/expenses`, `POST /api/v1/expenses` (Quick expense with photo and GPS stamp), `GET /api/v1/expense-categories`.

---

### Module 9: Operations, Manufacturing & Job Work
1. **Module Name:** Production, Bill of Materials (BOM), Job Work & Projects
2. **Available Functionality:** Bill of Materials (BOM) recipes, production planning, batch output & ingredient consumption, job work orders (textile/engineering), material dispatch (Job Work DC), job work GRN, rework/return tracking, project milestones, site delivery, installation & commissioning.
3. **Backend Controller:** `OperationsController`, `JobWorkController`.
4. **API Endpoints:** 
   - `GET /api/v1/operations/{area}` (`manufacturing|job-work|projects|stock`)
   - `GET /api/v1/operations/{kind}/{id}`
   - `POST /api/v1/operations/{action}` (`bom|production-plan|job-order|project`)
   - `POST /api/v1/operations/{action}/{id}` (`production-complete|job-dispatch|job-receive|job-return|job-rework|project-install|project-commission`)
5. **Database Models:** `Bom`, `ProductionOrder`, `JobWorkOrder`, `JobWorkDispatch`, `JobWorkReceipt`, `Project`, `ProjectInstallation`.
6. **Relationships:** `ProductionOrder` belongsTo `Bom`, `Warehouse`; `JobWorkOrder` belongsTo `Supplier`.
7. **Existing Permissions:** `manufacturing.read`, `manufacturing.bom.manage`, `manufacturing.production.post`, `job_work.read`, `job_work.dispatch`, `job_work.receive`, `projects.read`, `projects.install`.
8. **Available CRUD Operations:** Full production lifecycle and job work tracking.
9. **Existing Reports:** Recipe costing, wastage percentage, WIP stock with job workers, ITC-04 register.
10. **Existing Approval Workflows:** Job work dispatch authorization, production completion sign-off.
11. **Mobile Implementation Status:** **API available, mobile missing** (Endpoints exist under `/api/v1/operations/`, but mobile client has zero screens for manufacturing, job work, or site projects).
12. **Missing APIs or Functionality:** Mobile UI screens for Production Orders, Job Work DC sign-off with customer signature, and Project installation checklists.

---

### Module 10: Packaged Water Can Distribution (DK Waters)
1. **Module Name:** 20L Water Can Route Distribution & Logistics
2. **Available Functionality:** Route planning (Tata Ace vans), multi-load plant refills, customer can delivery ticketing, empty can retrieval, customer container custody balance tracking, container deposit accounting, driver end-of-shift surrender, physical spot audits.
3. **Backend Controller:** `WaterLogisticsController`, `WaterLogisticsApiController`.
4. **API Endpoints:**
   - `GET /api/v1/water/routes`
   - `POST /api/v1/water/can-deliveries`
   - `POST /api/v1/water/plant-intakes`
   - `POST /api/v1/water/driver-surrender`
   - `POST /api/v1/mobile/spot-audit`
   - `GET /api/v1/mobile/bootstrap`
5. **Database Models:** `WaterCanRoute`, `WaterCanDelivery`, `WaterCanPlantIntake`, `WaterCanInventory`, `WaterCanDriverSurrender`, `WaterCanSpotAudit`.
6. **Relationships:** `WaterCanDelivery` belongsTo `WaterCanRoute`, `Customer`; `WaterCanInventory` belongsTo `Customer`.
7. **Existing Permissions:** `delivery`, `water_logistics`.
8. **Available CRUD Operations:** Create delivery, log plant refill, record spot audit, surrender shift.
9. **Existing Reports:** Daily route delivery summary, Can balance sheet, Driver cash collection vs deposit.
10. **Existing Approval Workflows:** Admin verification of driver cash surrender.
11. **Mobile Implementation Status:** **Fully implemented & hardened** (Ticket machine, plant refill, spot audit, and driver surrender all wired to real DB persistence and Sanctum auth).
12. **Missing APIs or Functionality:** Offline sync queue with idempotency keys, Bluetooth 58mm/80mm thermal receipt printing.

---

### Module 11: Bulk Commercial Water Tankers (TMWS)
1. **Module Name:** Bulk Water Fleet & Tanker Trip Sheets
2. **Available Functionality:** Fleet management (9KL, 16KL, 24KL tankers), trip sheet logging, source borewell plant intake, destination commercial sites, start/end odometer readings, fuel vouchers, waiting charges, pumping surcharges, tolls, receiver signature capture.
3. **Backend Controller:** `WaterLogisticsController`, `WaterLogisticsApiController`.
4. **API Endpoints:**
   - `GET /api/v1/water/routes` (includes tankers)
   - `POST /api/v1/water/trip-sheets`
5. **Database Models:** `WaterTanker`, `WaterTankerTrip`, `JournalEntry`.
6. **Relationships:** `WaterTankerTrip` belongsTo `WaterTanker`, `Customer`, `User` (Driver).
7. **Existing Permissions:** `water_logistics`.
8. **Available CRUD Operations:** Log trip, update odometer, record diesel expense, post revenue to GL.
9. **Existing Reports:** Tanker trip history, diesel consumption per KM, driver batta ledger.
10. **Existing Approval Workflows:** Fraud audit on odometer and pumping surcharges.
11. **Mobile Implementation Status:** **Partially implemented** (`tanker_trip_sheet_screen.dart` exists but is 1,286 lines of monolithic UI with simulated radar and lacking offline drift persistence).
12. **Missing APIs or Functionality:** `GET /api/v1/water/trips/{id}`, real-time GPS coordinate telemetry batching.

---

### Module 12: Bakery & Cafe POS (Aran Cafe)
1. **Module Name:** Bakery & Counter POS Terminal
2. **Available Functionality:** Touch-optimized product catalog, category tabs, cart management, quantity stepper, bill discounts, split payment (Cash/UPI), cash drawer float opening, shift closing with cash reconciliation, kitchen order ticket (KOT) queue.
3. **Backend Controller:** `CafeOperationsController`, `CafeApiController`.
4. **API Endpoints:**
   - `GET /api/v1/cafe/menu`
   - `POST /api/v1/cafe/orders`
   - `POST /api/v1/cafe/drawer-reconcile`
5. **Database Models:** `Product`, `Category`, `Sale`, `Product_Sale`, `CafeCashDrawer`.
6. **Relationships:** `CafeCashDrawer` belongsTo `User`, `CompanyBranch`.
7. **Existing Permissions:** `pos_setting`, `today_sale`.
8. **Available CRUD Operations:** Create sale order, print receipt, reconcile cash drawer.
9. **Existing Reports:** Daily POS register, Item-wise sales report, Cash drawer audit.
10. **Existing Approval Workflows:** Cash drawer variance supervisor sign-off.
11. **Mobile Implementation Status:** **Partially implemented** (`cafe_pos_screen.dart` exists, but lacks hold/recall cart, thermal printer integration, and offline order queuing).
12. **Missing APIs or Functionality:** KOT order dispatch endpoint, bill hold and resume endpoints.

---

### Module 13: Repair & RMA Service Center
1. **Module Name:** Repair Job Sheets, RMA & Device Servicing
2. **Available Functionality:** Repair job intake, customer device details, fault diagnosis, status tracking (Received -> Diagnosing -> Waiting for Parts -> Ready -> Delivered), parts consumed from inventory, technician assignment, delivery signature, invoice conversion.
3. **Backend Controller:** `RepairController`, `RepairApiController`.
4. **API Endpoints:**
   - `GET /api/v1/repair/jobs`
   - `POST /api/v1/repair/jobs`
   - `PUT /api/v1/repair/jobs/{id}/status`
5. **Database Models:** `RepairJob`, `Customer`, `Product`.
6. **Relationships:** `RepairJob` belongsTo `Customer`, `User` (Technician).
7. **Existing Permissions:** `repair`.
8. **Available CRUD Operations:** Create job sheet, update status, convert to invoice.
9. **Existing Reports:** Open repair turnaround time, Technician efficiency.
10. **Existing Approval Workflows:** Customer quotation acceptance.
11. **Mobile Implementation Status:** **API available, mobile missing** (Endpoints are ready in `RepairApiController`, but mobile client has zero repair screens).
12. **Missing APIs or Functionality:** Mobile UI screens for Repair Job list, New job card intake with camera photos, and Status progression picker.

---

### Module 14: GST & Tax Compliance
1. **Module Name:** GST Filing, Invoicing & E-Documents
2. **Available Functionality:** GST category mapping (CGST, SGST, IGST), GSTR-3B summary review, ITC-04 job work tracking, TDS/TCS 194Q compliance, e-Way bill and e-Invoice document status.
3. **Backend Controller:** `ComplianceController`, `GstSettingsController`.
4. **API Endpoints:** Web controllers only (`/compliance/*`).
5. **Database Models:** `Tax`, `TaxCategory`, `TaxRegistration`, `EDocument`.
6. **Relationships:** `Product` belongsTo `TaxCategory`; `TaxRegistration` belongsTo `Company`.
7. **Existing Permissions:** `accounting.reports.view`, `general_setting`.
8. **Available CRUD Operations:** View tax summary, export GSTR JSON, generate e-way bill.
9. **Existing Reports:** GSTR-1, GSTR-3B, ITC-04.
10. **Existing Approval Workflows:** Credit note / Debit note GST filing confirmation.
11. **Mobile Implementation Status:** **Backend available, API missing** (Mobile client has no compliance screens).
12. **Missing APIs or Functionality:** `GET /api/v1/compliance/gst-summary` (read-only compliance dashboard for executive review).

---

### Module 15: Reports & Analytics Library
1. **Module Name:** Business Intelligence & Standard Reports
2. **Available Functionality:** Comprehensive reporting across Sales, Purchases, Stock, Warehouses, Cash Register, Profit & Loss, Payments, DSO (Days Sales Outstanding), Biller efficiency, Customer and Supplier ledgers.
3. **Backend Controller:** `ReportController`.
4. **API Endpoints:** Web-based DataTables and HTML views; no JSON endpoints in `routes/api.php`.
5. **Database Models:** All transactional models.
6. **Relationships:** Aggregates transactions across `Sale`, `Purchase`, `Payment`, `Warehouse`.
7. **Existing Permissions:** `sale-report`, `purchase-report`, `product-report`, `warehouse-report`, `payment-report`, `due-report`, `customer-report`, `supplier-report`.
8. **Available CRUD Operations:** Read, Filter, Export PDF/Excel, Print.
9. **Existing Reports:** 18 distinct standard reports.
10. **Existing Approval Workflows:** N/A.
11. **Mobile Implementation Status:** **Backend available, API missing** (Mobile client has no report library).
12. **Missing APIs or Functionality:** `GET /api/v1/reports/{report_type}` returning structured JSON with summary totals and chart datasets.

---

### Module 16: Organization, People & HRM
1. **Module Name:** Employees, Attendance, Shifts, Leaves & Payroll
2. **Available Functionality:** Employee directory, GPS-geofenced mobile attendance check-in/out, shift definitions, leave applications & approvals, overtime tracking, payroll generation, holidays.
3. **Backend Controller:** `EmployeeController`, `DepartmentController`, `DesignationController`, `AttendanceController`, `PayrollController`, `LeaveController`, `HolidayController`, `ShiftController`.
4. **API Endpoints:** Web controllers only (`/employees/*`, `/attendance/*`, `/hrm/*`).
5. **Database Models:** `Employee`, `Department`, `Designation`, `Attendance`, `Payroll`, `Leave`, `LeaveType`, `Holiday`, `Shift`, `Overtime`.
6. **Relationships:** `Employee` belongsTo `Department`, `Designation`, `CompanyBranch`.
7. **Existing Permissions:** `employees-index`, `employees-add`, `employees-edit`, `attendance`, `payroll`, `leave`, `shift`, `overtime`.
8. **Available CRUD Operations:** Check in/out, apply leave, approve leave, generate payroll.
9. **Existing Reports:** Monthly attendance sheet, Employee payroll summary.
10. **Existing Approval Workflows:** Leave approval, Overtime approval.
11. **Mobile Implementation Status:** **Backend available, API missing** (Mobile client has zero HRM screens).
12. **Missing APIs or Functionality:** `POST /api/v1/hrm/attendance/check-in` (with selfie and GPS coordinate stamp), `GET /api/v1/hrm/leaves`, `POST /api/v1/hrm/leaves`.

---

### Module 17: Platform Administration & Settings
1. **Module Name:** Administration, User Security, Capabilities & Addons
2. **Available Functionality:** User management, role & permission assignments, tenant capability switches (enable/disable modules per company), company and branch configuration, document series numbering, WhatsApp notification templates, system activity logs.
3. **Backend Controller:** `UserController`, `RoleController`, `CompanySelectorController`, `CompanyProfileController`, `CompanyFinancialYearController`, `DocumentSeriesController`, `SettingController`, `WhatsappController`.
4. **API Endpoints:**
   - `GET /api/v1/me`
   - `GET /api/v1/addons/status`
   - `GET /api/v1/company-context/financial-years`
   - `POST /api/v1/company-context/financial-years`
5. **Database Models:** `User`, `Roles`, `Company`, `CompanyBranch`, `FiscalYear`, `DocumentSeries`, `ActivityLog`.
6. **Relationships:** `User` belongsToMany `Company`, `CompanyBranch`; `Company` hasMany `CompanyBranch`, `FiscalYear`.
7. **Existing Permissions:** `users-index`, `users-add`, `role_permission`, `general_setting`, `addons`.
8. **Available CRUD Operations:** Manage users, switch companies, toggle capabilities.
9. **Existing Reports:** Activity log audit.
10. **Existing Approval Workflows:** N/A.
11. **Mobile Implementation Status:** **Partially implemented** (`GET /api/v1/me` and `/addons/status` exist; mobile company switcher, user profile, language/theme settings exist but lack proper navigation shell integration).
12. **Missing APIs or Functionality:** `GET /api/v1/activity-logs`, `GET /api/v1/notifications`.

---

## 3. Module Parity Summary Table

| # | ERP Module Area | Backend Status | API Status | Mobile Status | Parity Verdict |
|---|---|---|---|---|---|
| 1 | Executive Dashboard | Implemented | Partial (`/mobile/dashboard`) | Incomplete | **P0 - Overhaul** |
| 2 | Sales & Commercial | Implemented | Partial (`/sales`, `/mobile/invoices`) | Missing create/orders | **P0 - Expand** |
| 3 | Purchase & Procurement | Implemented | Available (`/purchases`) | Missing | **P0 - Implement** |
| 4 | Inventory & Warehouse | Implemented | Partial (`/inventory/valuation`, `/transfer`) | Missing counts/adjust | **P0 - Implement** |
| 5 | Product & Master Data | Implemented | Available (`/products`) | Read-only | **P0 - Expand** |
| 6 | Parties (Customers/Suppliers)| Implemented | Available (`/customers`, `/suppliers`) | Basic customer only | **P0 - Expand** |
| 7 | Double-Entry Accounting | Implemented | **Full REST API Available** | Missing | **P0 - High Value** |
| 8 | Expenses & Incomes | Implemented | Missing in API | Missing | **P0 - Add API & UI** |
| 9 | Operations & Manufacturing | Implemented | Available (`/operations/*`) | Missing | **P1 - Implement** |
| 10| Packaged Water Can Logistics| Implemented | Available (`/water/*`, `/mobile/*`) | Working (Refactor UI) | **P0 - Refactor** |
| 11| Bulk Water Tanker Logistics | Implemented | Available (`/water/trip-sheets`) | Working (Refactor UI) | **P0 - Refactor** |
| 12| Cafe & Bakery POS | Implemented | Available (`/cafe/*`) | Working (Enhance) | **P0 - Enhance** |
| 13| Repair & RMA Center | Implemented | Available (`/repair/*`) | Missing | **P1 - Implement** |
| 14| GST & Tax Compliance | Implemented | Missing in API | Missing | **P1 - Read-only View**|
| 15| Reports & Analytics | Implemented | Missing in API | Missing | **P1 - Add API & UI** |
| 16| Organization & HRM | Implemented | Missing in API | Missing | **P0 - Check-in/Leave** |
| 17| Admin & Settings | Implemented | Available (`/me`, `/addons/status`) | Partial | **P0 - Shell Integration** |

