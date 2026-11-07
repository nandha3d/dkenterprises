# API Contract & Calculation Ownership Audit

**Application:** DK Enterprises ERP (Laravel 11 + Flutter Mobile)  
**Specification:** `docs/DK_Enterprises_Antigravity_ERP_Mobile_Web_Audit_and_Fix_Spec.md`  
**Date:** 2026-11-07  
**Status:** Enforced & Validated  

---

## 1. Absolute Rule: Backend-Only Business Calculations

The backend is the **sole source of truth** for all business data, financial totals, ledger movements, tax, discounts, dues, and inventory valuations. 
- The Flutter mobile app and Blade web frontend format and render values.
- Neither frontend may calculate financial balances, totals, tax, discounts, stock valuation, outstanding amounts, ledger balances, route totals, commissions, profit, or payroll.
- A frontend must never silently fabricate or recalculate a missing API value.

---

## 2. Calculation Ownership Register

| Business Metric / Calculation | Authoritative Backend Owner | Database Table / Source of Truth | API Endpoint | Frontend Role |
|---|---|---|---|---|
| **Cash in Hand (1010)** | `WaterLogisticsApiController::financials` | `journal_items` + `chart_of_accounts` (`code = '1010'` / `control_type = 'cash'`) + `accounts` table fallback | `GET /api/v1/mobile/financials` | Read-only render via `AmountText` |
| **Bank Balances (1020)** | `WaterLogisticsApiController::financials` | `journal_items` + `chart_of_accounts` (`code = '1020'` / `control_type = 'bank'`) + `accounts` table fallback | `GET /api/v1/mobile/financials` | Read-only render via `AmountText` |
| **Accounts Receivable (1030)** | `WaterLogisticsApiController::financials` | `sales` (`grand_total - paid_amount`) + journal AR (`code = '1030'`) | `GET /api/v1/mobile/financials` | Read-only render via `AmountText` |
| **Accounts Payable (2010)** | `WaterLogisticsApiController::financials` | `purchases` (`grand_total - paid_amount`) + journal AP (`code = '2010'`) | `GET /api/v1/mobile/financials` | Read-only render via `AmountText` |
| **Customer Outstanding Dues** | `WaterLogisticsApiController::customersList` | `sales` due + customer opening balances | `GET /api/v1/mobile/customers` | Rendered alongside customer row; zero client calculation |
| **Customer Can Balances** | `WaterLogisticsApiController::customersList` | `water_can_inventories.total_cans_held` | `GET /api/v1/mobile/customers` | Read-only display of cans in market |
| **Customer Container Deposits** | `WaterLogisticsApiController::financials` | `water_can_inventories.deposit_held` | `GET /api/v1/mobile/financials` | Read-only display |
| **Today's Verified Collections** | `WaterLogisticsApiController::financials` | `payments` + `water_can_deliveries.paid_amount` for `created_at = today` | `GET /api/v1/mobile/financials` | Read-only display on dashboard hero card |
| **Invoiced Revenue Summary** | `ReportApiController::sales` | `sales.grand_total` sum for period | `GET /api/v1/reports/sales` | Rendered on reports screen; zero fabricated fallbacks |
| **Stock Valuation** | `ReportApiController::stock` | `product_warehouse.qty * products.cost` + `stock_movement_lines` | `GET /api/v1/reports/stock` | Rendered on reports screen; zero fabricated fallbacks |
| **Tanker Trip Surcharges** | `WaterLogisticsController::calculateTankerTrip` | Base rate + distance surcharge + motor pumping + waiting | `POST /api/v1/water-logistics/calculate-trip` | Dispatched to backend for validation |
| **Spot Audit Cash & Unit Difference** | `WaterLogisticsApiController::spotAudit` | `physical_units - expected_units`, `physical_cash - expected_cash` | `POST /api/v1/mobile/spot-audit` | Computed and verified server-side |

---

## 3. Standardized API Envelope Unwrapping

Laravel standardizes API responses using `BaseApiController::sendResponse($data, $message)`:
```json
{
  "success": true,
  "message": "...",
  "data": [ ... ]
}
```

### Remediation of `data is List` Bug
Previously, several mobile screens (`sales_invoices_screen.dart`, `purchase_bills_screen.dart`, `stock_overview_screen.dart`) used:
```dart
// BUGGY: data is Map with key 'data', so 'data is List' evaluated to false!
fromJson: (data) {
  if (data is List) return data.cast<Map<String, dynamic>>();
  return <Map<String, dynamic>>[];
}
```
This bug resulted in empty `[]` lists even when the backend returned live records.

### Unified Pattern Implemented Across All Repositories & Screens
```dart
fromJson: (data) {
  final list = data is Map && data['data'] is List
      ? data['data'] as List
      : (data is List ? data : []);
  return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}
```
This safely unwraps both wrapped payloads (`{"data": [...]}`) and raw arrays (`[...]`), guaranteeing 100% data fidelity between Laravel and Flutter.
