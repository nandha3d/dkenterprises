# ERP Web ↔ Mobile Feature Parity Matrix

**Application:** DK Enterprises ERP (Laravel 11 + Flutter Mobile)  
**Specification:** `docs/DK_Enterprises_Antigravity_ERP_Mobile_Web_Audit_and_Fix_Spec.md`  
**Date:** 2026-11-07  
**Status:** Audited & Enforced  

---

## 1. 17-Module ERP Parity Matrix

| # | ERP Module Domain | Web Route & View | API Endpoint(s) | Mobile Screen & Route | Calculation Owner | Company Isolation | Parity Status |
|---|---|---|---|---|---|---|---|
| 1 | **Multi-Company Group Workspace** | `/workspace` (`backend.workspace.home`) | `GET /api/v1/mobile/workspace` | `/workspace` (`WorkspaceScreen`) | Backend `WaterLogisticsApiController::groupWorkspaceInsights` | **Only** screen permitted to show all accessible companies | **FULL PARITY** |
| 2 | **Executive Dashboard** | `/dashboard` (`backend.index`) | `GET /api/v1/mobile/financials` | `/home` (`ExecutiveDashboardScreen`) | Backend `HomeController::dashboard` / `WaterLogisticsApiController::financials` | Strictly scoped to active company (`X-Company-ID`) | **FULL PARITY** |
| 3 | **Authentication & Roles** | `/login`, `/logout` | `POST /api/v1/mobile/login`, `GET /api/v1/me` | `/login` (`LoginScreen`) | Backend Sanctum Token Engine | Server-issued token; demo chips back real accounts | **FULL PARITY** |
| 4 | **Sales Invoicing** | `/sales` (`backend.sale.index`) | `GET /api/v1/sales`, `POST /api/v1/sales` | `/sales` (`SalesInvoicesScreen`), `/sales/new` (`NewSaleBillScreen`) | Backend `SaleController` / `SaleApiController` | Scoped to active company sales & customers | **FULL PARITY** |
| 5 | **Procurement & Purchase Bills** | `/purchases` (`backend.purchase.index`) | `GET /api/v1/purchases`, `POST /api/v1/purchases` | `/purchases` (`PurchaseBillsScreen`) | Backend `PurchaseController` / `PurchaseApiController` | Scoped to active company purchases & suppliers | **FULL PARITY** |
| 6 | **Cash & Bank Books** | `/accounts` (`backend.account.index`) | `GET /api/v1/mobile/financials` | `/accounting/books` (`AccountingBooksScreen`) | Backend `AccountController` / `WaterLogisticsApiController::financials` | Scoped to active company GL accounts 1010/1020 | **FULL PARITY** |
| 7 | **Customer Payment Collection** | `/payments` (`backend.sale.add_payment`) | `POST /api/v1/mobile/collect-payment` | `/accounting/collect` (`PaymentCollectionScreen`) | Backend `WaterLogisticsApiController::collectPayment` | Scoped to active company customers | **FULL PARITY** |
| 8 | **Warehouse Stock Valuation** | `/report/warehouse_stock` | `GET /api/v1/reports/stock`, `GET /api/v1/products` | `/inventory` (`StockOverviewScreen`) | Backend `ReportApiController::stock` (`product_warehouse.qty * cost`) | Scoped to active company godowns & products | **FULL PARITY** |
| 9 | **Physical Stock Count** | `/stock-count` (`backend.stock_count.index`) | `POST /api/v1/inventory/stock-count` | `/inventory/stock-count` (`StockCountScreen`) | Backend `InventoryApiController` | Scoped to active company warehouse SKUs | **FULL PARITY** |
| 10 | **20L Packaged Water Can POS** | `/water-logistics` (Can Beat section) | `POST /api/v1/water-logistics/can-deliveries` | `/operations/can-sales` (`CanSalesScreen`) | Backend `WaterLogisticsApiController` | Strictly gated to `packaged_water` (DK Waters) | **FULL PARITY** |
| 11 | **Bulk Water Tanker Dispatch** | `/water-logistics` (Tanker section) | `POST /api/v1/water-logistics/trip-sheets` | `/operations/tanker-trip` (`TankerTripScreen`) | Backend `WaterLogisticsApiController` | Strictly gated to `bulk_water` (TMWS) | **FULL PARITY** |
| 12 | **Fleet GPS Radar Telematics** | `/fleet/tracking` (`backend.water_logistics.fleet_tracking`) | `GET /api/v1/mobile/fleet/live`, `POST /api/v1/mobile/fleet/ping` | `/fleet/gps` (`FleetGpsScreen`) | Backend `WaterLogisticsController` (`water_tankers` / `water_can_routes`) | Scoped: TMWS gets tankers; DK Waters gets can vans | **FULL PARITY** |
| 13 | **Bakery & Cafe Touch POS** | `/cafe/pos` (`backend.cafe.pos`) | `POST /api/v1/cafe/orders`, `GET /api/v1/products` | `/operations/cafe-pos` (`CafePosScreen`) | Backend `CafeOperationsController` / `CafeApiController` | Strictly gated to `cafe_bakery` (Aran Cafe) | **FULL PARITY** |
| 14 | **Spot Empty Can Audit** | Anti-fraud command center | `POST /api/v1/mobile/spot-audit` | `/operations/spot-audit` (`SpotAuditScreen`) | Backend `WaterLogisticsApiController::spotAudit` | Scoped to DK Waters customer inventory accounts | **FULL PARITY** |
| 15 | **Driver Cash Surrender** | `/water-logistics` driver surrender desk | `POST /api/v1/mobile/driver-surrender` | `/operations/driver-surrender` (`DriverSurrenderScreen`) | Backend `WaterLogisticsApiController::driverCashSurrender` | Scoped to active company driver accounts | **FULL PARITY** |
| 16 | **Quick Expense Capture** | `/expenses` (`backend.expense.index`) | `POST /api/v1/expenses` | `/expenses/new` (`QuickExpenseScreen`) | Backend `ExpenseApiController` | Scoped to active company expense GL accounts | **FULL PARITY** |
| 17 | **Financial & Sales Reports** | `/report/profit_loss`, `/report/sales` | `GET /api/v1/reports/sales`, `GET /api/v1/reports/stock` | `/reports` (`ReportsScreen`) | Backend `ReportApiController` / `FinancialReportService` | Scoped to active company revenue & stock | **FULL PARITY** |

---

## 2. Key Architecture Standards Achieved

1. **Zero Client-Side Calculation:**
   - Both Web and Flutter rely 100% on API-computed values. Neither frontend performs financial arithmetic, stock costing, or tax calculation.
2. **Unified Data Format:**
   - Standardized `{"code": 200, "data": [...]}` envelope unwrapping across all mobile feature screens.
3. **No Fabricated Fallbacks:**
   - Empty data returns truthful `EmptyState`; network timeouts return retryable error states.
