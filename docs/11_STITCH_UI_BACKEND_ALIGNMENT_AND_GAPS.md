# Google Stitch UI — Backend API Alignment, Gap Implementation & ERP Security Audit

**Source Stitch Project:** `Complete Multi-Screen UI Design` (`projects/2098341959005560501`)  
**Design System:** Ripple (Light/Dark tokens, role-specific skins, `Manrope` tabular typography, `FluidCurvedNavBar`, English-only UI as requested)  
**Verified Backend Route Surface:** 166 routes under `/api/v1/*` (`php artisan route:list --path=api/v1`)  

---

## 1. Role Skins & Navigation Structure

| Role Profile | Skin Name | Primary Accent | Action / Fab Accent | Light Canvas | Dark Canvas | Bottom Navigation Tabs (English Only) |
|---|---|---|---|---|---|---|
| Executive / Admin (`A-*`) | **Lagoon** | `#0B5D52` | `#C9F36A` (`#13201B` ink) | `#F5F3EE` | `#0E1512` | `Home · Trade · (+) · Money · More` |
| Can & Tanker Driver (`D-*`, `T-*`) | **Aqua Day** | `#0E8FB3` | `#FFC933` (`#13201B` ink) | `#F3F8FA` | `#0E1512` | `Today · Work · Cash · Me` |
| Cafe / Cashier (`C-*`) | **Chai & Crema** | `#C2542D` | `#F4A62A` (`#13201B` ink) | `#FBF4EA` | `#0E1512` | `Counter · Orders · Drawer · Kitchen · Me` |
| Field Agent (`F-*`) | **Field Sage** | `#3F7D58` | `#C9F36A` (`#13201B` ink) | `#F5F3EE` | `#0E1512` | `Collect · Customers · Spend · Me` |

---

## 2. ERP POS & Kitchen Backend Module Integration (`/api/v1/pos/*`)

Mobile Cafe & POS (`C-01` .. `C-36`) is wired directly to the ERP POS module (`app/Http/Controllers/Api/V1/PosApiController.php`) using company-scoped `auth:sanctum` + `company.context` middleware (`X-Company-ID`):

| Endpoint | Method | ERP Tables / Services Touched | Stitch Screens Served |
|---|---|---|---|
| `/api/v1/pos/bootstrap` | `GET` | `Product`, `Category`, `Warehouse`, `Biller`, `Customer`, `Table`, `PosSetting`, `CashRegister` | `C-01`, `C-02`, `C-07`, `C-20` |
| `/api/v1/pos/tables` | `GET` | `Table`, open held `Sale` (`sale_status = 3`) occupancy | `C-02`, `C-07` |
| `/api/v1/pos/shifts/current` | `GET` | `CashRegister` + aggregated `Payment`, `Returns`, `Expense` | `C-01`, `C-20`, `C-23` |
| `/api/v1/pos/shifts/open` | `POST` | `CashRegister` (`cash_in_hand`, `warehouse_id`, `status = true`) | `C-21` |
| `/api/v1/pos/shifts/close` | `POST` | `CashRegister` closure + expected cash & variance calculation (`X`/`Z` report) | `C-22`, `C-23`, `C-24` |
| `/api/v1/pos/orders` | `GET` | `Sale`, `Product_Sale`, `Payment`, `Returns` counts (`completed`, `held`, `with_returns`) | `C-09`, `C-10` |
| `/api/v1/pos/orders/{id}` | `GET` | Full order lines, returnable qty, split payments, credit notes | `C-11` |
| `/api/v1/pos/orders` | `POST` | `Sale` (`sale_status = 3` held draft OR `sale_status = 1` posted), `Product_Sale`, `Payment`, `DocumentNumberService`, `InventoryMovementService`, `AccountingPostingService` | `C-02`, `C-04`, `C-05`, `C-06`, `C-09` |
| `/api/v1/pos/orders/{id}/resume` | `POST` | Updates or finalizes a held draft (`sale_status = 3` -> `1`), deducts stock, posts GL | `C-09`, `C-04`, `C-05` |
| `/api/v1/pos/orders/{id}/held` | `DELETE` | Discards held draft (`sale_status = 3`) with zero invoice sequence gap | `C-09` |
| `/api/v1/pos/orders/{id}/refund` | `POST` | `Returns` (`note_type = credit_note`), `ProductReturn`, `Payment`, optional stock restock (`InventoryMovementService::receive`), reversal `JournalEntry` | `C-12` |
| `/api/v1/pos/orders/{id}/print-job` | `POST` | Generates 80mm/58mm ESC/POS structured thermal receipt payload & audit stamp | `C-06`, `D-04` |
| `/api/v1/pos/kds` | `GET` | Active kitchen tickets (`NEW`, `PREPARING`, `READY`, `SERVED`) & status counts | `C-08` |
| `/api/v1/pos/kds/{id}/status` | `POST` | Bumps kitchen ticket status (`NEW` -> `PREPARING` -> `READY` -> `SERVED`) | `C-08` |
| `/api/v1/pos/products/{id}/availability` | `PATCH` | Instant 86 out-of-stock / menu availability toggle (`is_active`) | `C-34` |
| `/api/v1/pos/production-batches` | `POST` | Logs finished batch (`InventoryMovementService::receive`) + optional BOM raw material consumption (`issue`) | `C-30`, `C-32` |
| `/api/v1/pos/wastage` | `POST` | Writes off spoilt/damaged stock (`InventoryMovementService::issue`) + `Expense` & GL journal entry | `C-33` |
| `/api/v1/pos/reorder-requests` | `GET/POST` | Kitchen low-stock replenishment requisitions (`Quotation` / internal PO queue) | `C-36` |

> **Offline & Legacy Server Resilience:** If the POS terminal is offline during counter checkout, completed bills queue in the encrypted SQLite outbox targeting `/api/v1/cafe/orders` and drain automatically via `SyncWorker`. In addition, if a remote server has not yet deployed `/api/v1/pos/bootstrap` (returning HTTP `404`), `PosRepository` automatically falls back to `/api/v1/mobile/products` + `/api/v1/cafe/menu` + `/api/v1/mobile/customers`, scopes items strictly to `activeCompanyId`, caches them locally, and renders the POS terminal without interruption.

---

## 3. Stitch Screen-to-Backend Mapping

### Shared Core (`G-*`)
| Stitch ID & Title | Flutter Screen | Backend API | Status |
|---|---|---|---|
| `G-01` Splash & Boot | `main.dart` + `AuthNotifier` | `GET /api/v1/auth/me`, `GET /api/v1/mobile/bootstrap` | **Connected** |
| `G-02` Login & Company Context | `LoginScreen` | `POST /api/v1/auth/login`, `POST /api/v1/mobile/login`, `GET /api/v1/companies` | **Connected** |
| `G-03` Workspace / Company Switcher | `CompanySwitcherSheet`, `WorkspaceScreen` | `GET /api/v1/mobile/workspace`, `GET /api/v1/workspace` | **Connected** |
| `G-04` Notifications & Sync Center | `NotificationsScreen` | `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/devices/push-token`, `SyncWorker` + `GET /api/v1/reports/stock` | **Connected** |
| `G-05` Global Quick Actions | `QuickActionSheet` | Role-scoped navigation into connected modules | **Connected** |

### Admin / Executive (`A-*`)
| Stitch ID & Title | Flutter Screen | Backend API | Status |
|---|---|---|---|
| `A-01` Admin Home & Fluid Nav | `ExecutiveDashboardScreen` | `GET /api/v1/mobile/dashboard/admin`, `/api/v1/mobile/financials`, `/api/v1/mobile/fleet/live` | **Connected** |
| `A-10..A-12` Trade — Sales, Bills & New Bill | `SalesInvoicesScreen`, `NewSaleBillScreen`, `PurchaseBillsScreen` | `GET/POST /api/v1/sales`, `/api/v1/purchases`, `POST /api/v1/sales/{id}/payments` | **Connected** |
| `A-13` Customers & Credit Collection | `PaymentCollectionScreen`, `CustomerFormScreen` | `GET /api/v1/customers`, `POST /api/v1/mobile/customer-onboard`, `POST /api/v1/mobile/collect-payment` | **Connected** |
| `A-14` Quotations / Estimates & Credit Approval | `TradeHubScreen` (`_openQuotationsSheet`, `_openCreditLimitDialog`) | `GET/POST /api/v1/quotations`, `POST /api/v1/quotations/{id}/convert`, `POST /api/v1/customers/{id}/credit-limit` | **Connected** |
| `A-20..A-22` Products & Stock Valuation | `ProductsCatalogScreen`, `ProductFormScreen`, `StockOverviewScreen`, `StockCountScreen` | `GET/POST/PUT /api/v1/products`, `GET /api/v1/inventory/valuation`, `POST /api/v1/inventory/stock-count`, `POST /api/v1/inventory/transfer` | **Connected** |
| `A-30..A-32` Money — Reports, Ledgers & Expenses | `ReportsScreen`, `AccountingBooksScreen`, `QuickExpenseScreen` | `/api/v1/reports/{sales,purchases,stock}`, `/api/v1/accounting/{trial-balance,profit-and-loss,balance-sheet,day-book,cash-book,ageing}`, `/api/v1/expenses` | **Connected** |
| `A-33` Supplier Payment Settlement | `MoneyHubScreen` (`_openSupplierSettlementDialog`) | `POST /api/v1/suppliers/{id}/pay` (FIFO allocation + GL 2010/1010/1020) | **Connected** |
| `A-40` More — Modules, Attendance & Profile | `ModuleLauncherScreen`, `AttendanceScreen`, `ProfileScreen` | `/api/v1/hrm/attendance/{check-in,check-out}`, `/api/v1/hrm/leaves`, `/api/v1/repair/jobs` | **Connected** |
| `A-41` Team Leave & Roster Approval | `MoneyHubScreen` (`_openLeaveApprovalsSheet`) | `GET /api/v1/hrm/leaves`, `POST /api/v1/hrm/leaves/{id}/approve`, `POST /api/v1/hrm/leaves/{id}/reject` | **Connected** |

### Cafe / Cashier (`C-*`)
| Stitch ID & Title | Flutter Screen | Backend API | Status |
|---|---|---|---|
| `C-01` Cafe Home (Counter Status) | `CashierDashboardScreen` | `GET /api/v1/mobile/dashboard/cashier`, `GET /api/v1/pos/bootstrap`, `GET /api/v1/pos/shifts/current` | **Connected** |
| `C-02..C-06` Cafe POS Terminal, Cart, Split Payment & Thermal Receipt | `CafePosScreen` | `GET /api/v1/pos/bootstrap`, `POST /api/v1/pos/orders`, `POST /api/v1/pos/orders/{id}/resume`, `POST /api/v1/pos/orders/{id}/print-job` | **Connected** |
| `C-07` Dining Tables & Occupancy Plan | `PosTablesSheet` / `CafePosScreen` | `GET /api/v1/pos/tables` | **Connected** |
| `C-08` Kitchen Orders & Live KDS Bump Queue | `PosKitchenScreen` | `GET /api/v1/pos/kds`, `POST /api/v1/pos/kds/{id}/status` | **Connected** |
| `C-09..C-12` Orders, Held Drafts, Detail & Void/Refund | `PosOrdersScreen` | `GET /api/v1/pos/orders`, `GET /api/v1/pos/orders/{id}`, `DELETE /api/v1/pos/orders/{id}/held`, `POST /api/v1/pos/orders/{id}/refund` | **Connected** |
| `C-20..C-24` Cash Drawer Float, X/Z Report & Close Shift | `PosDrawerScreen` | `GET /api/v1/pos/shifts/current`, `POST /api/v1/pos/shifts/open`, `POST /api/v1/pos/shifts/close` | **Connected** |
| `C-30, C-32..C-34, C-36` Production Batches, Wastage, 86 Toggle & Reorder PO | `PosKitchenScreen` | `PATCH /api/v1/pos/products/{id}/availability`, `POST /api/v1/pos/production-batches`, `POST /api/v1/pos/wastage`, `GET/POST /api/v1/pos/reorder-requests` | **Connected** |
| `C-31` Kitchen & Ingredient Stock Audit | `PosKitchenScreen` -> `StockCountScreen` & `StockOverviewScreen` | `GET /api/v1/inventory/valuation`, `POST /api/v1/inventory/stock-count`, `GET /api/v1/reports/stock` | **Connected** |
| `C-35` Daily Cafe Expenses | `PosKitchenScreen` -> `QuickExpenseScreen` | `GET/POST /api/v1/expenses`, `GET /api/v1/expenses/categories` | **Connected** |
| `C-40..C-45` Collection, Invoices, Attendance, Queue, Me | Shared role-skinned screens | `/api/v1/mobile/collect-payment`, `/api/v1/sales`, `/api/v1/hrm/*`, `SyncWorker` | **Connected** |

### Can & Tanker Drivers (`D-*`, `T-*`)
| Stitch ID & Title | Flutter Screen | Backend API | Status |
|---|---|---|---|
| `D-01` Can Driver Today | `CanDeliveryDriverDashboardScreen` | `GET /api/v1/mobile/driver/manifest`, `GET /api/v1/mobile/dashboard/can_driver` | **Connected** |
| `D-02` Plant Refill Manifest | `PlantRefillScreen` | `POST /api/v1/water/plant-intakes` | **Connected** |
| `D-03..D-05` 15s Can Sales POS, Thermal Slip Preview & Stop Sheet | `CanSalesScreen` | `POST /api/v1/water/can-deliveries`, `GET /api/v1/water/routes`, `POST /api/v1/pos/orders/{id}/print-job` | **Connected** |
| `D-07` Spot Empty Can Audit | `SpotAuditScreen` | `POST /api/v1/mobile/spot-audit` | **Connected** |
| `D-08..D-09, D-12` Driver Cash Surrender & Receipt | `DriverSurrenderScreen` | `POST /api/v1/water/driver-surrender` | **Connected** |
| `D-10` Driver Route Map & GPS Ping | `CanDeliveryDriverDashboardScreen`, `TankerDriverDashboardScreen` | `POST /api/v1/mobile/fleet/ping`, `POST /api/v1/mobile/customers/{id}/location` | **Connected** |
| `D-11..D-16, T-07..T-11` Work Tab, Fuel Expenses, Attendance, Tasks, Profile | Shared role-skinned screens | `/api/v1/expenses`, `/api/v1/hrm/*`, `SyncWorker` | **Connected** |
| `T-01..T-06, T-12` Tanker Today, Auto Trip Sheet, Surcharges, Decanting, Completion & History | `TankerDriverDashboardScreen`, `TankerTripScreen`, `CustomerFormScreen` | `POST /api/v1/water/trip-sheets`, `GET /api/v1/water/trips`, `GET /api/v1/water/trips/{id}/trail` | **Connected** |

### Field Agent (`F-*`)
| Stitch ID & Title | Flutter Screen | Backend API | Status |
|---|---|---|---|
| `F-01` Field Collection & KYC Desk | `FieldAgentDashboardScreen` | `GET /api/v1/mobile/dashboard/field_agent`, `GET /api/v1/customers` | **Connected** |
| `F-02..F-05` Collection, Onboard + GPS Pin, Credit Limit, Overdue Ageing, Field Expense | `PaymentCollectionScreen`, `CustomerFormScreen`, `AccountingBooksScreen`, `QuickExpenseScreen` | `/api/v1/mobile/collect-payment`, `/api/v1/mobile/customer-onboard`, `/api/v1/customers/{id}/credit-limit`, `/api/v1/accounting/ageing`, `/api/v1/expenses` | **Connected** |

---

## 4. Backend Gaps Matrix — Implementation Status (10 / 10 Implemented)

All 10 previously identified backend & mobile gaps have been implemented, secured with multi-company isolation, and verified by automated feature tests (`tests/Feature/ErpSecurityAndGapsTest.php`):

| Priority | Feature Area | Stitch Screens | Implemented Laravel Endpoint(s) | Status |
|---|---|---|---|---|
| **P1** | **Cafe KDS & Kitchen Tickets** | `C-08` | `GET /api/v1/pos/kds`, `POST /api/v1/pos/kds/{id}/status` (`PosApiController`) | **Implemented & Connected** |
| **P1** | **Menu 86 / Availability Toggle** | `C-34` | `PATCH /api/v1/pos/products/{id}/availability` (`PosApiController`) | **Implemented & Connected** |
| **P1** | **Cafe Production Batch & Wastage** | `C-32`, `C-33` | `POST /api/v1/pos/production-batches`, `POST /api/v1/pos/wastage` (`PosApiController`) | **Implemented & Connected** |
| **P1** | **Kitchen Reorder Request / Internal PO** | `C-36` | `GET /api/v1/pos/reorder-requests`, `POST /api/v1/pos/reorder-requests` (`PosApiController`) | **Implemented & Connected** |
| **P2** | **Notification & Alert Feed** | `G-04` | `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/devices/push-token` (`WaterLogisticsApiController`) | **Implemented & Connected** |
| **P2** | **Quotations & Customer Credit Override** | `A-14`, `F-03` | `GET /api/v1/quotations`, `POST /api/v1/quotations`, `POST /api/v1/quotations/{id}/convert` (`SaleApiController`), `POST /api/v1/customers/{id}/credit-limit` (`PartnerApiController`) | **Implemented & Connected** |
| **P2** | **HRM Leave & Shift Approval** | `A-41` | `POST /api/v1/hrm/leaves/{id}/approve`, `POST /api/v1/hrm/leaves/{id}/reject` (`HrmApiController`) | **Implemented & Connected** |
| **P2** | **Tanker Trip History & GPS Breadcrumbs** | `T-12` | `GET /api/v1/water/trips`, `GET /api/v1/water/trips/{id}/trail` (`WaterLogisticsApiController`) | **Implemented & Connected** |
| **P3** | **Direct Supplier Payment Voucher** | `A-33` | `POST /api/v1/suppliers/{id}/pay` (`PartnerApiController`) | **Implemented & Connected** |
| **P3** | **Mobile Thermal Print Job** | `D-04`, `C-06` | `POST /api/v1/pos/orders/{id}/print-job` (`PosApiController`) | **Implemented & Connected** |

---

## 5. Complete ERP Security & Error Audit Summary

| Severity | Finding | Location | Resolution Applied |
|---|---|---|---|
| **Critical** | **Unthrottled Mobile Login Brute-Force:** `POST /api/v1/mobile/login` lacked rate limiting while `/api/v1/auth/login` used `throttle:api-login`. | `routes/api.php` | Attached `->middleware('throttle:api-login')` to `/api/v1/mobile/login`. |
| **Critical** | **Role Escalation in Mobile Login:** `mobileLogin()` echoed any client-supplied `$request->input('role')` (e.g., `superAdmin`) even for non-admin users. | `WaterLogisticsApiController::mobileLogin` | Restricted role preview override strictly to verified Admin accounts (`role_id == 1` or `'Admin'`). Non-admin users always receive their true database role slug. |
| **Critical** | **Cross-Tenant Customer Ledger IDOR:** `customerLedger($id)` called `Customer::findOrFail($id)` and queried `Sale` / `payments` without checking `company_id`. | `ReportApiController::customerLedger` | Scoped `Customer`, `Sale`, and `payments` strictly by authorized `$companyId` via `CompanyContextResolver::authorizedCompany()`. |
| **High** | **Cross-Tenant GPS Overwrite IDOR:** `updateCustomerLocation($id)` updated `customers` by primary key without verifying company ownership. | `WaterLogisticsApiController::updateCustomerLocation` | Enforced `where('company_id', $companyId)` before updating customer GPS coordinates (`404` on foreign company customer). |
| **High** | **Unvalidated Mass Assignment in Product API:** `ProductApiController::store` and `update` passed `$request->all()` into `Product::create()` / `update()` and did not verify `warehouse_id` ownership. | `ProductApiController::store`, `update` | Replaced `$request->all()` with explicit `$validated` whitelist and verified `Warehouse::where('company_id', $companyId)` before writing `product_warehouse`. |
| **High** | **Cross-Tenant Report & Expense Leakage:** `ReportApiController::{sales,purchases,stock}` and `ExpenseApiController::index` only filtered by `company_id` when `activeCompanyId()` was truthy. | `ReportApiController`, `ExpenseApiController` | Enforced mandatory `$companyId` resolution and `where('company_id', $companyId)` filtering across all report and expense queries. |
| **Medium** | **Hardcoded `company_id = 1` & Fake Metrics in Role Dashboards:** `roleDashboard('cashier')` and `roleDashboard('field_agent')` used hardcoded `company_id = 1` and fallback numbers (`2100.0`, `1450.0`, `overdue_accounts = 4`). | `WaterLogisticsApiController::roleDashboard` | Scoped all dashboard queries to the authenticated `$companyId` and removed all fake fallback numbers. |
| **Medium** | **Broken GL Journal Call in Repair API:** `RepairApiController::updateStatus` called `postJournalEntry()` with positional arguments and invalid `'account_code'` key, silently failing in `catch`. | `RepairApiController::updateStatus` | Resolved leaf `ChartOfAccount` IDs (`1010`, `4010`) for the active company and passed the canonical `postJournalEntry([...])` array structure. |
| **Medium** | **SQL Column Mismatch in HRM Leaves API:** `HrmApiController::{leaves,leaveTypes}` queried non-existent `leave_types.type_name` and `days` columns (actual schema is `name`, `annual_quota`). | `HrmApiController` | Updated queries to select `leave_types.name as type_name` and `leave_types.annual_quota as days`, and scoped HRM attendance/leave actions by company. |
| **Medium** | **Multi-Branch POS/Quotation 422 without `X-Branch-ID`:** Multi-branch admin accounts calling `/api/v1/pos/*` or `/api/v1/quotations` without an explicit `X-Branch-ID` header hit `422 Select an authorized branch`. | `ResolveCompanyContext` | Auto-resolves the user's primary active branch (preferring branches with an active warehouse) when `X-Branch-ID` is omitted on mobile API calls. |
