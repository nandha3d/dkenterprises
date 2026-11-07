# Zolo ERP — Mobile API Coverage & Contract Parity Matrix

**Document Reference:** `docs/mobile/MOBILE_API_COVERAGE.md`  
**Date:** 2026-11-07  
**Scope:** Side-by-side comparison of Laravel REST API (`routes/api.php`, `routes/operations.php`) vs Mobile Client Services (`mobile/lib/services/api_service.dart`).

---

## 1. Executive Summary

Of the **54+ production RESTful endpoints** provided by the Laravel ERP backend, the existing mobile client interacts with only **18 endpoints**, and completely ignores the core ERP endpoints for Double-Entry Accounting, Purchasing, General Sales, Inventory Transfers, Quotations, Operations, and Repair Center.

Furthermore, existing mobile API integrations lack:
- Idempotency key headers (`Idempotency-Key: <UUID>`) on write operations.
- Offline persistence queues with exponential backoff retries.
- Pagination controls (endpoints are limited or unbounded).
- Standardized error parsing (silent mock data fallbacks instead of displaying server validation errors).

---

## 2. API Endpoint vs Mobile Service Coverage Matrix

| # | Endpoint & Method | Web/API Controller | Mobile Method (`api_service.dart`) | Auth & Context | Coverage Status | Deficiencies / Actions Needed |
|---|---|---|---|---|---|---|
| **1** | `POST /api/v1/auth/login` | `AuthController::login` | `login()` (fallback) | Public, Rate-limited | **Covered** | Wire as standard login |
| **2** | `GET /api/v1/me` | `MeApiController::me` | *None* | `auth:sanctum` | **Missing** | Call on startup to load roles/permissions/companies |
| **3** | `POST /api/v1/auth/logout` | `AuthController::logout` | `logout()` (local memory only) | `auth:sanctum` | **Missing** | Call server to revoke Sanctum personal access token |
| **4** | `GET /api/v1/addons/status` | `AddonApiController::status` | *None* | Public | **Missing** | Query tenant capabilities to gate mobile modules |
| **5** | `POST /api/v1/mobile/login` | `WaterLogisticsApiController::mobileLogin` | `login()` | Public | **Covered (Upgraded)**| Sanctum token authentication |
| **6** | `GET /api/v1/mobile/bootstrap` | `WaterLogisticsApiController::mobileBootstrap`| `fetchBootstrap()` | Public | **Covered** | Clean up response structure |
| **7** | `GET /api/v1/mobile/dashboard/{role}` | `WaterLogisticsApiController::roleDashboard` | `fetchRoleDashboard()` | `auth:sanctum` | **Covered** | Filter by `X-Company-ID` context |
| **8** | `GET /api/v1/mobile/customers` | `WaterLogisticsApiController::customersList` | `fetchCustomers()` | `auth:sanctum` | **Covered** | Eliminate fake customer fallback; add search & paging |
| **9** | `GET /api/v1/mobile/products` | `WaterLogisticsApiController::productsList` | `fetchProducts()` | `auth:sanctum` | **Covered** | Eliminate fake product fallback; add barcode lookup |
| **10**| `GET /api/v1/mobile/invoices` | `WaterLogisticsApiController::invoicesList` | `fetchInvoices()` | `auth:sanctum` | **Covered** | Eliminate fake invoice fallback; add date filter |
| **11**| `GET /api/v1/mobile/financials` | `WaterLogisticsApiController::financials` | `fetchFinancials()` | `auth:sanctum` | **Covered** | Live ledger balances per company |
| **12**| `POST /api/v1/mobile/customer-onboard` | `WaterLogisticsApiController::customerOnboard`| `onboardCustomer()` | `auth:sanctum` | **Covered** | Add GSTIN lookup and KYC photo attachment |
| **13**| `POST /api/v1/mobile/collect-payment` | `WaterLogisticsApiController::collectPayment` | `collectPayment()` | `auth:sanctum` | **Covered** | Add idempotency key and print receipt |
| **14**| `POST /api/v1/mobile/spot-audit` | `WaterLogisticsApiController::spotAudit` | `submitSpotAudit()` | `auth:sanctum` | **Covered (Upgraded)**| Real DB persistence in `water_can_spot_audits` |
| **15**| `POST /api/v1/mobile/driver-surrender` | `WaterLogisticsApiController::driverCashSurrender`| `surrenderShift()` | `auth:sanctum` | **Covered (Upgraded)**| Real DB persistence & GL deposit posting |
| **16**| `GET /api/v1/company-context/financial-years` | `CompanyFinancialYearController::index` | *None* | `auth:sanctum` | **Missing** | Allow switching active financial year |
| **17**| `POST /api/v1/company-context/financial-years`| `CompanyFinancialYearController::store` | *None* | `auth:sanctum` | **Missing** | Financial year setup |
| **18**| `GET /api/v1/sales` | `SaleApiController::index` | *None* | `auth:sanctum`, `company.context` | **Missing** | Browse sales bills with filter/search |
| **19**| `POST /api/v1/sales` | `SaleApiController::store` | *None* | `auth:sanctum`, `company.context` | **Missing** | Create full commercial sales invoice |
| **20**| `GET /api/v1/sales/{id}` | `SaleApiController::show` | *None* | `auth:sanctum`, `company.context` | **Missing** | View sales bill detail, lines, tax breakdown |
| **21**| `POST /api/v1/sales/{id}/payments` | `SaleApiController::addPayment` | *None* | `auth:sanctum`, `company.context` | **Missing** | Record payment on sales invoice |
| **22**| `GET /api/v1/purchases` | `PurchaseApiController::index` | *None* | `auth:sanctum`, `company.context` | **Missing** | Browse purchase bills |
| **23**| `POST /api/v1/purchases` | `PurchaseApiController::store` | *None* | `auth:sanctum`, `company.context` | **Missing** | Create purchase bill with supplier and items |
| **24**| `GET /api/v1/purchases/{id}` | `PurchaseApiController::show` | *None* | `auth:sanctum`, `company.context` | **Missing** | View purchase bill detail and payments |
| **25**| `POST /api/v1/purchases/{id}/payments` | `PurchaseApiController::addPayment` | *None* | `auth:sanctum`, `company.context` | **Missing** | Record supplier payment |
| **26**| `GET /api/v1/products` | `ProductApiController::index` | *None* | `auth:sanctum`, `company.context` | **Missing** | Master product catalog with stock by warehouse |
| **27**| `GET /api/v1/products/search/{term}` | `ProductApiController::search` | *None* | `auth:sanctum`, `company.context` | **Missing** | Barcode / SKU / title search |
| **28**| `GET /api/v1/products/{id}` | `ProductApiController::show` | *None* | `auth:sanctum`, `company.context` | **Missing** | Product detail with variants, batches, pricing |
| **29**| `GET /api/v1/inventory/valuation` | `InventoryApiController::valuation` | *None* | `auth:sanctum`, `company.context` | **Missing** | Inventory valuation by warehouse |
| **30**| `POST /api/v1/inventory/transfer` | `InventoryApiController::transfer` | *None* | `auth:sanctum`, `company.context` | **Missing** | Inter-warehouse stock transfer |
| **31**| `GET /api/v1/accounting/chart-of-accounts` | `AccountingApiController::chartOfAccounts` | *None* | `auth:sanctum`, `company.context` | **Missing** | View Chart of Accounts hierarchy |
| **32**| `GET /api/v1/accounting/trial-balance` | `AccountingApiController::trialBalance` | *None* | `auth:sanctum`, `company.context` | **Missing** | Real-time Trial Balance report |
| **33**| `GET /api/v1/accounting/profit-and-loss` | `AccountingApiController::profitAndLoss` | *None* | `auth:sanctum`, `company.context` | **Missing** | Real-time P&L Statement |
| **34**| `GET /api/v1/accounting/balance-sheet` | `AccountingApiController::balanceSheet` | *None* | `auth:sanctum`, `company.context` | **Missing** | Real-time Balance Sheet |
| **35**| `GET /api/v1/accounting/general-ledger/{id}` | `AccountingApiController::generalLedger` | *None* | `auth:sanctum`, `company.context` | **Missing** | General Ledger statement with running balances |
| **36**| `POST /api/v1/accounting/journal-entries` | `AccountingApiController::storeJournalEntry`| *None* | `auth:sanctum`, `company.context` | **Missing** | Manual Journal Entry creation |
| **37**| `POST /api/v1/accounting/vouchers` | `VoucherController::store` | *None* | `auth:sanctum`, `company.context` | **Missing** | Post Receipt/Payment/Contra vouchers |
| **38**| `POST /api/v1/accounting/journal-entries/{id}/reverse` | `VoucherController::reverse` | *None* | `auth:sanctum`, `company.context` | **Missing** | Reverse posted journal entry |
| **39**| `GET /api/v1/accounting/open-items` | `VoucherController::openItems` | *None* | `auth:sanctum`, `company.context` | **Missing** | Unsettled invoice open items for party |
| **40**| `POST /api/v1/accounting/allocations` | `VoucherController::allocate` | *None* | `auth:sanctum`, `company.context` | **Missing** | Allocate payment against open invoices |
| **41**| `GET /api/v1/accounting/day-book` | `VoucherController::book` (type=day) | *None* | `auth:sanctum`, `company.context` | **Missing** | Daily transaction day book |
| **42**| `GET /api/v1/accounting/cash-book` | `VoucherController::book` (type=cash) | *None* | `auth:sanctum`, `company.context` | **Missing** | Cash transactions book |
| **43**| `GET /api/v1/accounting/ageing` | `VoucherController::ageing` | *None* | `auth:sanctum`, `company.context` | **Missing** | Customer & Supplier aging analysis |
| **44**| `GET /api/v1/accounting/collections` | `CollectionController::index` | *None* | `auth:sanctum`, `company.context` | **Missing** | Field collections list |
| **45**| `POST /api/v1/accounting/collections` | `CollectionController::store` | *None* | `auth:sanctum`, `company.context` | **Missing** | Submit customer collection with allocation |
| **46**| `GET /api/v1/customers` | `PartnerApiController::customers` | *None* | `auth:sanctum`, `company.context` | **Missing** | Standard ERP customer directory |
| **47**| `GET /api/v1/suppliers` | `PartnerApiController::suppliers` | *None* | `auth:sanctum`, `company.context` | **Missing** | Standard ERP supplier directory |
| **48**| `GET /api/v1/water/routes` | `WaterLogisticsApiController::routes` | `fetchRoutes()` | `auth:sanctum` | **Covered** | Active routes and tanker fleet |
| **49**| `POST /api/v1/water/trip-sheets` | `WaterLogisticsApiController::storeTripSheet` | `logTripSheet()` | `auth:sanctum` | **Covered** | Bulk tanker trip sheet logging |
| **50**| `POST /api/v1/water/can-deliveries` | `WaterLogisticsApiController::storeCanDelivery`| `logCanDelivery()` | `auth:sanctum` | **Covered** | 20L can delivery ticketing |
| **51**| `POST /api/v1/water/plant-intakes` | `WaterLogisticsApiController::storePlantIntake` | `logPlantIntake()` | `auth:sanctum` | **Covered** | Multi-plant refill intake |
| **52**| `GET /api/v1/cafe/menu` | `CafeApiController::menu` | `fetchCafeMenu()` | `auth:sanctum` | **Covered** | Touch POS items and categories |
| **53**| `POST /api/v1/cafe/orders` | `CafeApiController::storeOrder` | `submitCafeOrder()` | `auth:sanctum` | **Covered** | Counter POS order creation |
| **54**| `POST /api/v1/cafe/drawer-reconcile`| `CafeApiController::reconcileDrawer` | `reconcileDrawer()` | `auth:sanctum` | **Covered** | Shift float & drawer reconciliation |
| **55**| `GET /api/v1/repair/jobs` | `RepairApiController::jobs` | *None* | `auth:sanctum` | **Missing** | Repair jobs list |
| **56**| `POST /api/v1/repair/jobs` | `RepairApiController::storeJob` | *None* | `auth:sanctum` | **Missing** | Repair intake job sheet |
| **57**| `PUT /api/v1/repair/jobs/{id}/status`| `RepairApiController::updateStatus` | *None* | `auth:sanctum` | **Missing** | Update repair job progress |
| **58**| `GET /api/v1/operations/{area}` | `OperationsController::hub` | *None* | `auth:sanctum`, `company.context` | **Missing** | Manufacturing BOM, Job Work, Projects |
| **59**| `POST /api/v1/operations/{action}`| `OperationsController::action` | *None* | `auth:sanctum`, `company.context` | **Missing** | Post BOM, production plans, job orders |

---

## 3. Required New Endpoints to Achieve Full ERP Coverage

To fulfill all requirements of the Master ERP Specification without code duplication, the following lightweight API controller methods should be wired in Laravel:

1. **Expenses & Incomes API (`app/Http/Controllers/Api/V1/ExpenseApiController.php`):**
   - `GET /api/v1/expenses`: List expenses filtered by date, category, warehouse.
   - `POST /api/v1/expenses`: Quick expense capture (under 20 seconds) with category, amount, payment mode, GPS coordinates, and bill photo upload.
   - `GET /api/v1/expense-categories`: List active expense categories.
2. **HRM Attendance & Leaves API (`app/Http/Controllers/Api/V1/HrmApiController.php`):**
   - `POST /api/v1/hrm/attendance/check-in`: Geofenced employee check-in with GPS coordinates and optional selfie photo.
   - `POST /api/v1/hrm/attendance/check-out`: Employee check-out.
   - `GET /api/v1/hrm/leaves`: Leave applications list with approval status.
   - `POST /api/v1/hrm/leaves`: Submit new leave request.
3. **Reports API (`app/Http/Controllers/Api/V1/ReportApiController.php`):**
   - `GET /api/v1/reports/{type}`: Structured JSON reporting for Sales, Purchases, Stock Valuation, DSO, and Customer/Supplier account ledgers with date range filtering.

