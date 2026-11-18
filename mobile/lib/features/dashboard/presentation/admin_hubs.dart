import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/ripple_components.dart';

/// Stitch A-10..A-22: Admin Trade Hub (Sales, Quotations, Purchases, Catalog, Inventory, Customers).
class TradeHubScreen extends ConsumerWidget {
  const TradeHubScreen({super.key});

  Future<void> _openQuotationsSheet(BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    final res = await client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.quotations,
      fromJson: (raw) {
        final map = raw is Map && raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
        final list = map['quotations'] is List
            ? map['quotations'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );

    if (!context.mounted) return;
    final quotations =
        res is ApiSuccess<List<Map<String, dynamic>>> ? res.data : const <Map<String, dynamic>>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final skin = RippleSkin.of(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.76,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sales Quotations (A-14)',
                      style: AppTypography.title.copyWith(color: skin.ink),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/sales/new');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Estimate'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Convert approved customer estimates directly into ERP sales invoices.',
                style: AppTypography.caption.copyWith(color: skin.muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: quotations.isEmpty
                    ? Center(
                        child: Text(
                          'No open quotations found for this company.',
                          style: AppTypography.caption.copyWith(color: skin.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: quotations.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: skin.hairline),
                        itemBuilder: (_, idx) {
                          final q = quotations[idx];
                          final id = int.tryParse((q['id'] ?? 0).toString()) ?? 0;
                          final refNo = (q['reference_no'] ?? 'QUO').toString();
                          final customer =
                              (q['customer_name'] ?? 'Customer').toString();
                          final total = (q['grand_total'] ?? 0).toString();
                          final status =
                              (q['status_label'] ?? 'pending').toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '$refNo · $customer',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: skin.ink),
                            ),
                            subtitle: Text(
                              'Total: ₹$total · Status: ${status.toUpperCase()}',
                              style: AppTypography.caption
                                  .copyWith(color: skin.muted),
                            ),
                            trailing: status == 'converted'
                                ? const Icon(Icons.check_circle_rounded,
                                    color: AppColors.rippleMint)
                                : FilledButton.tonal(
                                    onPressed: () async {
                                      final conv = await client
                                          .post<Map<String, dynamic>>(
                                        ApiEndpoints.quotationConvert(id),
                                        fromJson: (r) => r is Map
                                            ? Map<String, dynamic>.from(r)
                                            : <String, dynamic>{},
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      if (conv is ApiSuccess) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Converted $refNo to Sales Invoice!'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Convert'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreditLimitDialog(
      BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    final custRes = await client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.customers,
      fromJson: (raw) {
        final list = raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );

    if (!context.mounted) return;
    final customers = custRes is ApiSuccess<List<Map<String, dynamic>>>
        ? custRes.data
        : const <Map<String, dynamic>>[];

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customers found for credit limit update.')),
      );
      return;
    }

    int selectedCustomerId =
        int.tryParse((customers.first['id'] ?? 0).toString()) ?? 0;
    final limitCtrl = TextEditingController(
      text: (customers.first['credit_limit'] ?? '25000').toString(),
    );
    final reasonCtrl =
        TextEditingController(text: 'Manager credit limit revision');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Customer Credit Limit Override (F-03)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedCustomerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: customers
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: int.tryParse((c['id'] ?? 0).toString()) ?? 0,
                        child: Text((c['name'] ?? 'Customer').toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedCustomerId = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'New Credit Limit (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration:
                    const InputDecoration(labelText: 'Approval Note / Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Limit'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final newLimit = double.tryParse(limitCtrl.text.trim()) ?? 0;
    final res = await client.post<Map<String, dynamic>>(
      ApiEndpoints.customerCreditLimit(selectedCustomerId),
      data: {
        'credit_limit': newLimit,
        'reason': reasonCtrl.text.trim(),
      },
      fromJson: (r) =>
          r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{},
    );

    if (!context.mounted) return;
    if (res is ApiSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Customer credit limit updated to ₹${newLimit.toStringAsFixed(0)}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = RippleSkin.of(context);
    final activeCompany =
        ref.watch(authNotifierProvider.select((s) => s.activeCompany));
    final companyName = activeCompany?.name ?? 'Active Company';
    final industry = activeCompany?.industry ?? '';

    final (secondaryLabel, secondaryIcon, secondaryRoute) = switch (industry) {
      'bulk_water' => (
          'Tanker Trip',
          Icons.local_shipping_rounded,
          '/operations/tanker-trip'
        ),
      'packaged_water' => (
          'Can Sales POS',
          Icons.water_drop_rounded,
          '/operations/can-sales'
        ),
      _ => ('Open ERP POS', Icons.point_of_sale_rounded, '/operations/cafe-pos'),
    };

    return Scaffold(
      backgroundColor: skin.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          RippleHeroBanner(
            eyebrow: '$companyName · Trade & Supply Chain',
            headline: 'Orders, Stock & Parties',
            subheadline:
                'Direct ERP billing, quotations, supplier bills, SKU catalog, and live warehouse stock for $companyName.',
            pills: [
              RippleHeroPill(
                icon: Icons.add_circle_outline_rounded,
                label: 'New Sale Bill',
                isPrimary: true,
                onPressed: () => context.push('/sales/new'),
              ),
              RippleHeroPill(
                icon: secondaryIcon,
                label: secondaryLabel,
                onPressed: () => context.push(secondaryRoute),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Commercial & Billing',
              style: AppTypography.section.copyWith(color: skin.ink)),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.receipt_long_rounded,
            title: 'Sales Invoices',
            subtitle:
                'View bills, collect invoice balances, and check payment statuses.',
            onTap: () => context.push('/sales'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.request_quote_rounded,
            title: 'Sales Quotations & Estimates (A-14)',
            subtitle:
                'Review customer estimates and convert approved quotes to invoices.',
            accentColor: AppColors.rippleHoney,
            onTap: () => _openQuotationsSheet(context, ref),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.shopping_bag_rounded,
            title: 'Purchase Bills',
            subtitle: 'Track supplier invoices, GRNs, and payable balances.',
            accentColor: AppColors.rippleSky,
            onTap: () => context.push('/purchases'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.people_alt_rounded,
            title: 'Customers & Credit Directory',
            subtitle:
                'Manage customer profiles, credit dues, and onboard new accounts.',
            accentColor: AppColors.rippleMint,
            onTap: () => context.push('/customers'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.credit_score_rounded,
            title: 'Customer Credit Limit Override (F-03)',
            subtitle:
                'Adjust or approve customer credit limits with audit trail.',
            accentColor: skin.primary,
            onTap: () => _openCreditLimitDialog(context, ref),
          ),
          const SizedBox(height: 18),
          Text('Catalog & Inventory',
              style: AppTypography.section.copyWith(color: skin.ink)),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.inventory_2_rounded,
            title: 'Products & Pricing Catalog',
            subtitle: 'Search SKUs, update prices, or create a new item.',
            accentColor: AppColors.rippleHoney,
            onTap: () => context.push('/products'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.warehouse_rounded,
            title: 'Warehouse Valuation & Stock Audit',
            subtitle:
                'Inspect stock value by warehouse and run physical counts.',
            accentColor: skin.primary,
            onTap: () => context.push('/inventory'),
          ),
        ],
      ),
    );
  }
}

/// Stitch A-30..A-33 & A-41: Admin Money Hub (Collections, Supplier Pay, Expenses, Reports & Approvals).
class MoneyHubScreen extends ConsumerWidget {
  const MoneyHubScreen({super.key});

  Future<void> _openSupplierSettlementDialog(
      BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    final supRes = await client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.suppliers,
      fromJson: (raw) {
        final list = raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );

    if (!context.mounted) return;
    final suppliers = supRes is ApiSuccess<List<Map<String, dynamic>>>
        ? supRes.data
        : const <Map<String, dynamic>>[];

    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No suppliers found for this company.')),
      );
      return;
    }

    int selectedSupplierId =
        int.tryParse((suppliers.first['id'] ?? 0).toString()) ?? 0;
    final amountCtrl = TextEditingController(text: '5000');
    final noteCtrl = TextEditingController(text: 'FIFO supplier settlement');
    String paymentMethod = 'Cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Direct Supplier Settlement (A-33)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedSupplierId,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: suppliers
                    .map(
                      (s) => DropdownMenuItem<int>(
                        value: int.tryParse((s['id'] ?? 0).toString()) ?? 0,
                        child: Text(
                            (s['name'] ?? s['company_name'] ?? 'Supplier')
                                .toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedSupplierId = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Settlement Amount (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => paymentMethod = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Voucher Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Post Settlement'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    final res = await client.post<Map<String, dynamic>>(
      ApiEndpoints.supplierPay(selectedSupplierId),
      data: {
        'amount': amount,
        'paying_method': paymentMethod,
        'payment_note': noteCtrl.text.trim(),
      },
      fromJson: (r) =>
          r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{},
    );

    if (!context.mounted) return;
    if (res is ApiSuccess<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Supplier payment of ₹${amount.toStringAsFixed(0)} allocated cleanly.'),
        ),
      );
    } else if (res is ApiFailure<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.failure.message)),
      );
    }
  }

  Future<void> _openLeaveApprovalsSheet(
      BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    final res = await client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.leaves,
      fromJson: (raw) {
        final list = raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );

    if (!context.mounted) return;
    final leaves = res is ApiSuccess<List<Map<String, dynamic>>>
        ? res.data
        : const <Map<String, dynamic>>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final skin = RippleSkin.of(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff Leave Approvals (A-41)',
                style: AppTypography.title.copyWith(color: skin.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Approve or reject pending employee leave requests.',
                style: AppTypography.caption.copyWith(color: skin.muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: leaves.isEmpty
                    ? Center(
                        child: Text(
                          'No leave requests found.',
                          style:
                              AppTypography.caption.copyWith(color: skin.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: leaves.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: skin.hairline),
                        itemBuilder: (_, idx) {
                          final l = leaves[idx];
                          final id =
                              int.tryParse((l['id'] ?? 0).toString()) ?? 0;
                          final emp = (l['employee_name'] ?? 'Employee')
                              .toString();
                          final type =
                              (l['type_name'] ?? 'Leave').toString();
                          final days = (l['days'] ?? 1).toString();
                          final status =
                              (l['status'] ?? 'Pending').toString();
                          final isPending =
                              status.toLowerCase() == 'pending';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '$emp · $type ($days d)',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: skin.ink),
                            ),
                            subtitle: Text(
                              '${l['start_date'] ?? ''} to ${l['end_date'] ?? ''} · Status: $status',
                              style: AppTypography.caption
                                  .copyWith(color: skin.muted),
                            ),
                            trailing: !isPending
                                ? Text(
                                    status,
                                    style: AppTypography.caption.copyWith(
                                      color: skin.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Approve',
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: AppColors.rippleMint,
                                        ),
                                        onPressed: () async {
                                          await client.post<dynamic>(
                                            ApiEndpoints.leaveApprove(id),
                                            fromJson: (r) => r,
                                          );
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Reject',
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () async {
                                          await client.post<dynamic>(
                                            ApiEndpoints.leaveReject(id),
                                            fromJson: (r) => r,
                                          );
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = RippleSkin.of(context);
    final activeCompany =
        ref.watch(authNotifierProvider.select((s) => s.activeCompany));
    final companyName = activeCompany?.name ?? 'Active Company';
    final industry = activeCompany?.industry ?? '';
    final hasPosDrawer =
        industry == 'cafe_bakery' || industry == 'retail' || industry.isEmpty;

    return Scaffold(
      backgroundColor: skin.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          RippleHeroBanner(
            eyebrow: '$companyName · Finance & Treasury',
            headline: 'Collections & Books',
            subheadline:
                'Record customer receipts, supplier settlements, daily expenses, P&L, Trial Balance, and ledgers for $companyName.',
            pills: [
              RippleHeroPill(
                icon: Icons.payments_rounded,
                label: 'Collect Payment',
                isPrimary: true,
                onPressed: () => context.push('/accounting/collect'),
              ),
              RippleHeroPill(
                icon: Icons.money_off_rounded,
                label: 'Log Expense',
                onPressed: () => context.push('/expenses/new'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Cash & Accounting',
              style: AppTypography.section.copyWith(color: skin.ink)),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.account_balance_rounded,
            title: 'Accounting Books & Financial Statements',
            subtitle:
                'Trial Balance, Profit & Loss, Balance Sheet, Cash Book & Ageing.',
            onTap: () => context.push('/accounting/books'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Business Analytics Reports',
            subtitle: 'Sales, Purchases, and Stock Valuation breakdown.',
            accentColor: AppColors.rippleSky,
            onTap: () => context.push('/reports'),
          ),
          if (hasPosDrawer) ...[
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.point_of_sale_rounded,
              title: 'ERP POS Cash Register & X/Z Reports',
              subtitle:
                  'Inspect live drawer shifts, cash variance, and register handovers for $companyName.',
              accentColor: AppColors.chaiPrimary,
              onTap: () => context.push('/erp/pos-drawer'),
            ),
          ],
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.receipt_rounded,
            title: 'Record Business Expense',
            subtitle: 'Post company expenses directly to ERP expense ledgers.',
            accentColor: AppColors.rippleCoral,
            onTap: () => context.push('/expenses/new'),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Direct Supplier Settlement Voucher (A-33)',
            subtitle:
                'Allocate FIFO supplier payment across open purchase bills.',
            accentColor: AppColors.rippleMint,
            onTap: () => _openSupplierSettlementDialog(context, ref),
          ),
          const SizedBox(height: 10),
          RippleActionCard(
            icon: Icons.approval_rounded,
            title: 'HRM Staff Leave Approvals (A-41)',
            subtitle:
                'Review and approve or reject employee leave applications.',
            accentColor: AppColors.rippleHoney,
            onTap: () => _openLeaveApprovalsSheet(context, ref),
          ),
        ],
      ),
    );
  }
}
