import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/pos_print_preview_sheet.dart';
import '../../../core/ui/ripple_components.dart';
import '../../auth/domain/auth_models.dart';
import '../../pos/domain/pos_models.dart';
import '../../pos/presentation/pos_notifier.dart';

/// Stitch C-02..C-07: ERP-Connected Counter & Cafe POS Terminal.
///
/// Adapts dynamically by available constraints (`adaptive-layout` skill):
/// - Compact (`< 720px`): Single-pane catalog with Rush Hour row, 2-column grid,
///   and sticky bottom cart bar (`Hold`, `Pay ₹...`).
/// - Medium / Expanded / Large Tablet (`>= 720px`): Two-pane split layout matching
///   the Web POS 1:1 (Left 62%: Order Type, Table/Customer bar, Search, Category
///   chips, Rush Hour Super-Fast row, and 3-to-4 column responsive menu grid;
///   Right 38%: Persistent live Order Ticket with line-item steppers, discount,
///   tender selector, Hold/KOT, and 1-tap ERP checkout).
class CafePosScreen extends ConsumerStatefulWidget {
  const CafePosScreen({super.key});

  @override
  ConsumerState<CafePosScreen> createState() => _CafePosScreenState();
}

class _CafePosScreenState extends ConsumerState<CafePosScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _currencyExact = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _searchController = TextEditingController();
  final _tabletDiscountController = TextEditingController(text: '0');
  final _tabletPackingController = TextEditingController(text: '0');
  String _tabletTenderMethod = 'Cash';
  PosOrderSummary? _lastCompletedOrder;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final st = ref.read(posNotifierProvider);
      final activeCompanyId = ref.read(authNotifierProvider).activeCompany?.id;
      if (st.bootstrap == null || (activeCompanyId != null && st.bootstrap!.companyId != activeCompanyId)) {
        ref.read(posNotifierProvider.notifier).loadBootstrap();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabletDiscountController.dispose();
    _tabletPackingController.dispose();
    super.dispose();
  }

  Future<void> _showTablesSheet() async {
    final tables = ref.read(posNotifierProvider).bootstrap?.tables ?? const [];
    final selectedId = ref.read(posNotifierProvider).selectedTableId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final skin = RippleSkin.of(ctx);
        final sheetHeight = MediaQuery.sizeOf(ctx).height * 0.72;
        return Container(
          constraints: BoxConstraints(maxHeight: sheetHeight),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dining Tables', style: AppTypography.title.copyWith(color: skin.ink)),
                  TextButton(
                    onPressed: () {
                      ref.read(posNotifierProvider.notifier).setTable(null);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear Table'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tables.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'No dining tables configured in ERP for this company.',
                      style: AppTypography.body.copyWith(color: skin.muted),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Builder(
                    builder: (gridCtx) {
                      final cols = MediaQuery.sizeOf(gridCtx).width >= 580 ? 3 : 2;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: rippleGridTileExtent(
                            gridCtx,
                            baseHeight: 68,
                            textBudget: 56,
                          ),
                        ),
                        itemCount: tables.length,
                        itemBuilder: (_, idx) {
                          final table = tables[idx];
                          final isSelected = table.id == selectedId;
                          final accent = isSelected
                              ? skin.primary
                              : (table.isOccupied
                                  ? AppColors.rippleHoney
                                  : AppColors.rippleMint);
                          return RippleMenuTileCard(
                            icon: table.isOccupied
                                ? Icons.restaurant_rounded
                                : Icons.table_restaurant_rounded,
                            title: table.name,
                            subtitle: table.isOccupied
                                ? 'Occupied · ${_currency.format(table.heldGrandTotal ?? 0)}'
                                : '${table.seats} seats · Free',
                            accentColor: accent,
                            badge: isSelected
                                ? 'ACTIVE'
                                : (table.isOccupied ? 'BUSY' : 'FREE'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (table.isOccupied && table.heldSaleId != null) {
                                await ref
                                    .read(posNotifierProvider.notifier)
                                    .loadHeldOrder(table.heldSaleId!);
                              } else {
                                ref
                                    .read(posNotifierProvider.notifier)
                                    .setTable(table.id);
                              }
                            },
                          );
                        },
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

  Future<void> _showCustomerPicker() async {
    final customers = ref.read(posNotifierProvider).bootstrap?.customers ?? const [];
    final selectedId = ref.read(posNotifierProvider).selectedCustomerId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final skin = RippleSkin.of(ctx);
        final sheetHeight = MediaQuery.sizeOf(ctx).height * 0.65;
        return Container(
          constraints: BoxConstraints(maxHeight: sheetHeight),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Customer', style: AppTypography.title.copyWith(color: skin.ink)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (_, idx) {
                    final c = customers[idx];
                    final selected = c.id == selectedId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: skin.primary.withValues(alpha: 0.14),
                        child: Text(
                          c.name.isEmpty ? 'W' : c.name[0].toUpperCase(),
                          style: TextStyle(color: skin.primary, fontWeight: FontWeight.w800),
                        ),
                      ),
                      title: Text(c.name, style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
                      subtitle: c.phone != null ? Text(c.phone!) : null,
                      trailing: selected ? Icon(Icons.check_circle_rounded, color: skin.primary) : null,
                      onTap: () {
                        ref.read(posNotifierProvider.notifier).setCustomer(c.id);
                        Navigator.pop(ctx);
                      },
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

  Future<void> _toggleProduct86(PosProduct item) async {
    final nextAvailable = !item.isAvailable;
    final res = await ref.read(posRepositoryProvider).toggleProductAvailability(
          item.id,
          isAvailable: nextAvailable,
        );
    if (!mounted) return;
    if (res is ApiSuccess<Map<String, dynamic>>) {
      await ref.read(posNotifierProvider.notifier).loadBootstrap();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextAvailable
                ? '${item.name} restored to active POS menu.'
                : '${item.name} marked 86 (Sold Out).',
          ),
          backgroundColor: nextAvailable ? AppColors.rippleMint : AppColors.rippleHoney,
        ),
      );
    }
  }

  Future<void> _holdBill() async {
    final posState = ref.read(posNotifierProvider);
    final res = await ref.read(posNotifierProvider.notifier).submitOrder(
          hold: true,
          payments: const [],
          saleNote: posState.kotFirstMode
              ? 'KOT First Fire Ticket (${posState.priceTier})'
              : 'Held / KOT from Counter POS (${posState.priceTier})',
        );
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final order):
        _lastCompletedOrder = order;
        _tabletDiscountController.text = '0';
        _tabletPackingController.text = '0';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.referenceNo} held / sent to KOT.'),
            backgroundColor: AppColors.rippleHoney,
          ),
        );
      case ApiFailure<PosOrderSummary>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  Future<void> _quickPayTablet(PosTerminalState posState) async {
    if (posState.cart.isEmpty) return;
    final discount = double.tryParse(_tabletDiscountController.text.trim()) ?? 0;
    final packing = double.tryParse(_tabletPackingController.text.trim()) ?? 0;
    final notifier = ref.read(posNotifierProvider.notifier);
    notifier.setOrderDiscount(discount);
    notifier.setPackingCharge(packing);

    final updatedState = ref.read(posNotifierProvider);
    final totalDue = updatedState.grandTotal;
    final paidAmount = _tabletTenderMethod == 'Credit' ? 0.0 : totalDue;
    final shortfall = updatedState.customerCreditShortfall(paidAmount);
    if (shortfall > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Credit Limit Exceeded by ${_currencyExact.format(shortfall)} for ${updatedState.selectedCustomer?.name ?? 'Customer'}. Collect Cash/UPI or reduce balance.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final splits = _tabletTenderMethod == 'Credit'
        ? const <PosPaymentSplit>[PosPaymentSplit(method: 'Credit', amount: 0)]
        : <PosPaymentSplit>[PosPaymentSplit(method: _tabletTenderMethod, amount: totalDue)];

    final res = await notifier.submitOrder(
          hold: false,
          payments: splits,
          saleNote: 'Tablet Counter POS (${updatedState.orderType.toUpperCase()} · ${updatedState.priceTier})',
        );
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final order):
        _lastCompletedOrder = order;
        _tabletDiscountController.text = '0';
        _tabletPackingController.text = '0';
        _showReceiptSuccessSheet(order);
      case ApiFailure<PosOrderSummary>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  Future<void> _showCartLineModifierSheet(PosCartItem line) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartLineModifierSheet(line: line),
    );
  }

  Future<void> _openCheckoutSheet() async {
    final posState = ref.read(posNotifierProvider);
    final methods = posState.bootstrap?.paymentMethods ?? const ['Cash', 'UPI', 'Card', 'Credit'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PosCheckoutSheet(
        state: posState,
        paymentMethods: methods,
        currencyExact: _currencyExact,
        onCompleted: (order) {
          Navigator.pop(ctx);
          _lastCompletedOrder = order;
          _tabletDiscountController.text = '0';
          _tabletPackingController.text = '0';
          _showReceiptSuccessSheet(order);
        },
      ),
    );
  }

  void _openPrintStudio({
    PosOrderSummary? completedOrder,
    PosPrintFormat initialFormat = PosPrintFormat.thermal80mm,
  }) {
    final posState = ref.read(posNotifierProvider);
    final bootstrap = posState.bootstrap;
    final activeCompany = ref.read(authNotifierProvider).activeCompany;
    final companyName = (bootstrap?.companyName?.isNotEmpty == true ? bootstrap!.companyName! : null) ??
        activeCompany?.name ??
        'POS Terminal';
    final gstin = bootstrap?.gstin ?? activeCompany?.gstin;
    final upiVpa = bootstrap?.upiVpa ?? activeCompany?.upiVpa;
    final order = completedOrder ?? _lastCompletedOrder;

    final printItems = posState.cart.isNotEmpty
        ? posState.cart
            .map(
              (c) => PosPrintLineItem(
                name: c.product.name,
                code: c.product.code.isNotEmpty ? c.product.code : 'SKU-${c.product.id}',
                qty: c.qty,
                unitPrice: c.unitPrice,
                note: c.note,
              ),
            )
            .toList()
        : (order != null && order.items.isNotEmpty
            ? order.items
                .map(
                  (i) => PosPrintLineItem(
                    name: i.productName,
                    code: i.productCode.isNotEmpty ? i.productCode : 'SKU-${i.productId}',
                    qty: i.qty,
                    unitPrice: i.netUnitPrice,
                    note: i.note,
                  ),
                )
                .toList()
            : <PosPrintLineItem>[]);

    if (printItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add items to cart or select a completed bill before opening Print Studio.'),
        ),
      );
      return;
    }

    final total = posState.cart.isNotEmpty
        ? posState.grandTotal
        : (order?.grandTotal ?? 0.0);

    PosPrintPreviewSheet.show(
      context,
      companyName: companyName,
      branchName: 'Counter POS Terminal',
      gstin: gstin,
      upiVpa: upiVpa,
      referenceNo: order?.referenceNo ??
          'POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      tokenNumber: ((order?.id ?? 0) % 999).toString().padLeft(4, '0'),
      customerName: order?.customerName ?? posState.selectedCustomer?.name ?? 'Walk-in Customer',
      orderType: posState.orderType.toUpperCase(),
      priceTier: posState.priceTier,
      paymentMethod: _tabletTenderMethod,
      items: printItems,
      discount: posState.orderDiscount,
      packingCharge: posState.cart.isNotEmpty ? posState.packingCharge : 0.0,
      roundOff: posState.cart.isNotEmpty ? posState.roundOffAmount : 0.0,
      grandTotal: total,
      paidAmount: total,
      initialFormat: initialFormat,
    );
  }

  Future<void> _printLastReceipt() async {
    final order = _lastCompletedOrder;
    if (order != null && order.id > 0) {
      await ref.read(posRepositoryProvider).printOrderJob(order.id, format: '80mm');
    }
    if (!mounted) return;
    _openPrintStudio(completedOrder: order, initialFormat: PosPrintFormat.thermal80mm);
  }

  void _showReceiptSuccessSheet(PosOrderSummary order) {
    final skin = RippleSkin.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: skin.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.rippleMint.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.rippleMint, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              order.isOfflineQueued ? 'Queued Offline (Sync Pending)' : 'Bill Posted to ERP',
              style: AppTypography.title.copyWith(color: skin.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Ref: ${order.referenceNo} · ${_currencyExact.format(order.grandTotal)}',
              style: AppTypography.bodyMedium.copyWith(color: skin.primary),
            ),
            const SizedBox(height: 18),
            if (!order.isOfflineQueued && order.id > 0) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openPrintStudio(completedOrder: order);
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Open SensiblePOS Print & Label Studio'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/pos/orders');
                    },
                    child: const Text('View Orders'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Next Bill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final posState = ref.watch(posNotifierProvider);
    final bootstrap = posState.bootstrap;
    final products = posState.filteredProducts;
    final allProducts = bootstrap?.products ?? const <PosProduct>[];

    final cartQuantities = <int, double>{
      for (final item in posState.cart) item.product.id: item.qty,
    };

    final rushHourProducts = allProducts.where((p) => p.isFeatured).take(4).toList();
    final topSellers = rushHourProducts.isNotEmpty
        ? rushHourProducts
        : allProducts.take(4).toList();

    String selectedCustomerName = 'Walk-in';
    for (final c in bootstrap?.customers ?? const <PosPartyOption>[]) {
      if (c.id == posState.selectedCustomerId) {
        selectedCustomerName = c.name;
        break;
      }
    }

    String? selectedTableName;
    for (final t in bootstrap?.tables ?? const <PosTable>[]) {
      if (t.id == posState.selectedTableId) {
        selectedTableName = t.name;
        break;
      }
    }

    final authState = ref.watch(authNotifierProvider);
    final activeCompany = authState.activeCompany;
    final activeBranch = authState.activeBranch;
    final companyLabel = activeCompany?.name ?? 'ERP Company';
    final branchLabel = _formatBranchLabel(activeBranch);
    final shiftText = posState.activeShift != null
        ? 'Shift #${posState.activeShift!.id} Open · ${bootstrap?.heldOrdersCount ?? 0} Held'
        : 'No open drawer shift';

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Counter POS Terminal'),
            Text(
              '$companyLabel ($branchLabel) · $shiftText',
              style: AppTypography.caption.copyWith(
                color: posState.activeShift != null ? AppColors.rippleMint : AppColors.warning,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if ((bootstrap?.tables.isNotEmpty ?? false))
            IconButton(
              icon: const Icon(Icons.table_restaurant_rounded),
              tooltip: 'Tables',
              onPressed: _showTablesSheet,
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Print & Barcode Label Studio',
            onPressed: () => _openPrintStudio(initialFormat: PosPrintFormat.stickerLabel50x25),
          ),
          IconButton(
            icon: const Icon(Icons.soup_kitchen_outlined),
            tooltip: 'Kitchen Display & 86 Stock',
            onPressed: () => context.push('/pos/kitchen'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Held & Recent Orders',
            onPressed: () => context.push('/pos/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Catalog',
            onPressed: () => ref.read(posNotifierProvider.notifier).loadBootstrap(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final width = MediaQuery.sizeOf(context).width;
          final isTablet = width >= 840;
          if (isTablet) {
            return _buildTabletSplitLayout(
              context: context,
              skin: skin,
              posState: posState,
              bootstrap: bootstrap,
              products: products,
              topSellers: topSellers,
              cartQuantities: cartQuantities,
              selectedCustomerName: selectedCustomerName,
              selectedTableName: selectedTableName,
              maxWidth: width,
            );
          }

          return _buildCompactPhoneLayout(
            context: context,
            skin: skin,
            posState: posState,
            bootstrap: bootstrap,
            products: products,
            topSellers: topSellers,
            cartQuantities: cartQuantities,
            selectedCustomerName: selectedCustomerName,
            selectedTableName: selectedTableName,
          );
        },
      ),
    );
  }

  String _formatBranchLabel(BranchInfo? b) {
    if (b == null) return 'Main';
    final code = (b.code ?? '').trim().toUpperCase();
    final name = b.name.trim();
    if (code == 'ARAN1' || name.toUpperCase().contains('ARAN1')) return 'ARAN1 (Shop 1)';
    if (code == 'ARAN2' || name.toUpperCase().contains('ARAN2')) return 'ARAN2 (Shop 2)';
    return code.isNotEmpty ? code : name;
  }

  Widget _buildBranchSwitcherBar(RippleSkin skin) {
    final authState = ref.watch(authNotifierProvider);
    final activeCompany = authState.activeCompany;
    final activeBranch = authState.activeBranch;
    final branches = activeCompany?.branches ?? const <BranchInfo>[];
    final isAdmin = ref.watch(activeRippleRoleProvider) == RippleRole.admin;
    final canSwitch = isAdmin && activeCompany != null && branches.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (canSwitch) ...[
              Icon(Icons.store_mall_directory_rounded, size: 15, color: skin.primary),
              const SizedBox(width: 6),
              Text(
                'Branch:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: skin.muted),
              ),
              const SizedBox(width: 8),
              for (final branch in branches) ...[
                ChoiceChip(
                  selected: activeBranch?.id == branch.id,
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    _formatBranchLabel(branch),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onSelected: (selected) async {
                    if (!selected || activeBranch?.id == branch.id) return;
                    await ref.read(authNotifierProvider.notifier).switchCompany(
                          activeCompany,
                          branch: branch,
                          fy: authState.activeFinancialYear,
                        );
                    await ref.read(posNotifierProvider.notifier).loadBootstrap();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: skin.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: skin.primary.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin ? Icons.store_rounded : Icons.lock_outline_rounded,
                      size: 13,
                      color: skin.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Branch: ${_formatBranchLabel(activeBranch)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: skin.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogHeaderControls({
    required RippleSkin skin,
    required PosTerminalState posState,
    required PosBootstrapData? bootstrap,
    required String selectedCustomerName,
    required String? selectedTableName,
    required List<PosProduct> topSellers,
    required Map<int, double> cartQuantities,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (posState.isFromCache)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.chipWarningBgLight,
            child: const Text(
              'Offline mode: showing cached POS menu. Counter checkouts will queue for sync.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        _buildBranchSwitcherBar(skin),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'dine_in', label: Text('Dine-In', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 'takeaway', label: Text('Takeaway', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: 'delivery', label: Text('Delivery', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {posState.orderType},
                  onSelectionChanged: (set) {
                    ref.read(posNotifierProvider.notifier).setOrderType(set.first);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showCustomerPicker,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.person_outline_rounded, size: 17),
                  label: Text(selectedCustomerName, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showTablesSheet,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.table_bar_rounded, size: 17),
                  label: Text(selectedTableName ?? 'No Table', overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openPrintStudio(initialFormat: PosPrintFormat.thermal80mm),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print / Labels', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        // SensiblePOS Rate Tier Selector & Billing Mode Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'RATE SLAB: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: skin.muted,
                  ),
                ),
                for (final tier in const ['Retail MRP', 'Wholesale', 'Staff Rate', 'Online Aggregator'])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: posState.priceTier == tier,
                      visualDensity: VisualDensity.compact,
                      label: Text(tier, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onSelected: (_) => ref.read(posNotifierProvider.notifier).setPriceTier(tier),
                    ),
                  ),
                const SizedBox(width: 4),
                FilterChip(
                  selected: posState.kotFirstMode,
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    posState.kotFirstMode ? Icons.restaurant_menu_rounded : Icons.bolt_rounded,
                    size: 14,
                  ),
                  label: Text(
                    posState.kotFirstMode ? 'KOT First' : 'Fast Bill',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onSelected: (v) => ref.read(posNotifierProvider.notifier).setKotFirstMode(v),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Search menu items or scan barcode + Enter...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              suffixIcon: posState.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(posNotifierProvider.notifier).setSearchQuery('');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      tooltip: 'Add exact PLU / Barcode',
                      onPressed: () {
                        final added = ref.read(posNotifierProvider.notifier).addByBarcodeOrQuery(_searchController.text);
                        if (added) _searchController.clear();
                      },
                    ),
            ),
            onChanged: (v) => ref.read(posNotifierProvider.notifier).setSearchQuery(v),
            onSubmitted: (v) {
              final added = ref.read(posNotifierProvider.notifier).addByBarcodeOrQuery(v);
              if (added) {
                _searchController.clear();
              } else if (v.trim().isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No exact SKU/PLU match for "${v.trim()}"')),
                );
              }
            },
          ),
        ),
        if ((bootstrap?.categories ?? []).isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: posState.selectedCategoryId == null,
                  onSelected: (_) => ref.read(posNotifierProvider.notifier).setCategory(null),
                ),
                const SizedBox(width: 8),
                ...bootstrap!.categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.name),
                      selected: posState.selectedCategoryId == cat.id,
                      onSelected: (_) => ref.read(posNotifierProvider.notifier).setCategory(cat.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (topSellers.isNotEmpty && posState.searchQuery.isEmpty && posState.selectedCategoryId == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 18, color: skin.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Rush Hour Super-Fast',
                              style: AppTypography.label.copyWith(
                                color: skin.ink,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.rippleHoney.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                      ),
                      child: Text(
                        'Top Sellers',
                        style: AppTypography.caption.copyWith(
                          color: skin.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topSellers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final item = topSellers[idx];
                      final qty = cartQuantities[item.id] ?? 0;
                      final livePrice = posState.priceForProduct(item);
                      final qtyTxt = (qty - qty.roundToDouble()).abs() < 0.001 ? qty.round().toString() : qty.toStringAsFixed(2);
                      return InkWell(
                        onTap: () => ref.read(posNotifierProvider.notifier).addProduct(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 196,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: skin.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: qty > 0 ? skin.primary : skin.hairline,
                              width: qty > 0 ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.label.copyWith(
                                        color: skin.ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_currency.format(livePrice)}${qty > 0 ? ' · ${qtyTxt}x' : ''}',
                                      style: AppTypography.caption.copyWith(
                                        color: skin.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: skin.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCatalogGrid({
    required RippleSkin skin,
    required PosTerminalState posState,
    required List<PosProduct> products,
    required Map<int, double> cartQuantities,
    required int crossAxisCount,
  }) {
    if (posState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return Center(
        child: Text(
          posState.errorMessage ?? 'No products available in this company catalog.',
          style: AppTypography.body.copyWith(color: skin.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: rippleGridTileExtent(
          context,
          baseHeight: 92,
          textBudget: 66,
        ),
      ),
      itemCount: products.length,
      itemBuilder: (_, idx) {
        final item = products[idx];
        final qty = cartQuantities[item.id] ?? 0;
        return _PosProductCard(
          product: item,
          displayPrice: posState.priceForProduct(item),
          qtyInCart: qty,
          currency: _currency,
          onAdd: () => ref.read(posNotifierProvider.notifier).addProduct(item),
          onIncrement: () => ref.read(posNotifierProvider.notifier).incrementItem(item.id),
          onDecrement: () => ref.read(posNotifierProvider.notifier).decrementItem(item.id),
          onToggle86: () => _toggleProduct86(item),
        );
      },
    );
  }

  Widget _buildCompactPhoneLayout({
    required BuildContext context,
    required RippleSkin skin,
    required PosTerminalState posState,
    required PosBootstrapData? bootstrap,
    required List<PosProduct> products,
    required List<PosProduct> topSellers,
    required Map<int, double> cartQuantities,
    required String selectedCustomerName,
    required String? selectedTableName,
  }) {
    return Column(
      children: [
        _buildCatalogHeaderControls(
          skin: skin,
          posState: posState,
          bootstrap: bootstrap,
          selectedCustomerName: selectedCustomerName,
          selectedTableName: selectedTableName,
          topSellers: topSellers,
          cartQuantities: cartQuantities,
        ),
        Expanded(
          child: _buildCatalogGrid(
            skin: skin,
            posState: posState,
            products: products,
            cartQuantities: cartQuantities,
            crossAxisCount: 2,
          ),
        ),
        if (posState.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: skin.surface,
              border: Border(top: BorderSide(color: skin.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${posState.totalItemsCount} items · ${posState.priceTier}${posState.resumingOrderId != null ? ' · Resuming Held' : ''}',
                          style: AppTypography.label.copyWith(color: skin.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 19),
                            tooltip: 'Edit Qty / Kitchen Notes',
                            onPressed: posState.cart.isEmpty
                                ? null
                                : () => _showCartLineModifierSheet(posState.cart.last),
                          ),
                          Text(
                            _currencyExact.format(posState.grandTotal),
                            style: AppTypography.numberCard.copyWith(color: skin.ink),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            tooltip: 'Clear Cart',
                            onPressed: () => ref.read(posNotifierProvider.notifier).clearCart(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: posState.isSubmitting ? null : _holdBill,
                          icon: Icon(
                            posState.kotFirstMode ? Icons.restaurant_menu_rounded : Icons.pause_circle_outline_rounded,
                            size: 18,
                          ),
                          label: Text(posState.kotFirstMode ? 'Fire KOT' : 'Hold'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: posState.isSubmitting ? null : _openCheckoutSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: skin.action,
                            foregroundColor: skin.actionInk,
                          ),
                          icon: const Icon(Icons.payments_rounded, size: 18),
                          label: Text(
                            posState.isSubmitting
                                ? 'Posting...'
                                : 'Pay ${_currencyExact.format(posState.grandTotal)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabletSplitLayout({
    required BuildContext context,
    required RippleSkin skin,
    required PosTerminalState posState,
    required PosBootstrapData? bootstrap,
    required List<PosProduct> products,
    required List<PosProduct> topSellers,
    required Map<int, double> cartQuantities,
    required String selectedCustomerName,
    required String? selectedTableName,
    required double maxWidth,
  }) {
    final catalogWidth = maxWidth * 0.62;
    final crossCount = catalogWidth >= 760 ? 4 : 3;
    final methods = bootstrap?.paymentMethods ?? const ['Cash', 'UPI', 'Card', 'Credit'];
    final orderTypeLabel = switch (posState.orderType) {
      'takeaway' => 'Takeaway',
      'delivery' => 'Delivery',
      _ => 'Dine-In',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT PANE: Menu Catalog
        Expanded(
          flex: 62,
          child: Column(
            children: [
              _buildCatalogHeaderControls(
                skin: skin,
                posState: posState,
                bootstrap: bootstrap,
                selectedCustomerName: selectedCustomerName,
                selectedTableName: selectedTableName,
                topSellers: topSellers,
                cartQuantities: cartQuantities,
              ),
              Expanded(
                child: _buildCatalogGrid(
                  skin: skin,
                  posState: posState,
                  products: products,
                  cartQuantities: cartQuantities,
                  crossAxisCount: crossCount,
                ),
              ),
            ],
          ),
        ),

        // RIGHT PANE: Persistent Tablet Order Ticket (Matches Web POS 1:1)
        Container(
          width: (maxWidth * 0.38).clamp(340.0, 440.0),
          margin: const EdgeInsets.fromLTRB(0, 10, 16, 12),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: skin.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Current Order Ticket',
                                  style: AppTypography.section.copyWith(color: skin.ink),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.rippleHoney.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(skin.pillRadius),
                                ),
                                child: Text(
                                  '${posState.totalItemsCount} items',
                                  style: AppTypography.caption.copyWith(
                                    color: skin.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$orderTypeLabel · ${selectedTableName ?? 'Counter'} · $selectedCustomerName',
                            style: AppTypography.caption.copyWith(color: skin.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      tooltip: 'Clear Cart',
                      onPressed: posState.cart.isEmpty
                          ? null
                          : () => ref.read(posNotifierProvider.notifier).clearCart(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: skin.hairline),

              // Cart Line Items
              Expanded(
                child: posState.cart.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 32, color: skin.muted),
                              const SizedBox(height: 6),
                              Text(
                                'Tap any menu item on the left to build bill',
                                style: AppTypography.bodyMedium.copyWith(color: skin.ink),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Supports Dine-In KOT, Hold Bill & Split Tender',
                                style: AppTypography.caption.copyWith(color: skin.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: posState.cart.length,
                        separatorBuilder: (_, __) => Divider(height: 14, color: skin.hairline),
                        itemBuilder: (_, idx) {
                          final line = posState.cart[idx];
                          return InkWell(
                            onTap: () => _showCartLineModifierSheet(line),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.product.name,
                                          style: AppTypography.label.copyWith(
                                            color: skin.ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${_currencyExact.format(line.unitPrice)} each${line.note != null && line.note!.isNotEmpty ? ' · ${line.note}' : ' · Tap to add note'}',
                                          style: AppTypography.caption.copyWith(
                                            color: line.note != null && line.note!.isNotEmpty ? skin.primary : skin.muted,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: skin.primary),
                                        onPressed: () => ref
                                            .read(posNotifierProvider.notifier)
                                            .decrementItem(line.product.id),
                                      ),
                                      InkWell(
                                        onTap: () => _showCartLineModifierSheet(line),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Text(
                                            line.qtyLabel,
                                            style: AppTypography.label.copyWith(
                                              color: skin.ink,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(Icons.add_circle_rounded, size: 20, color: skin.primary),
                                        onPressed: () => ref
                                            .read(posNotifierProvider.notifier)
                                            .incrementItem(line.product.id),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 68,
                                    child: Text(
                                      _currencyExact.format(line.lineTotal),
                                      textAlign: TextAlign.right,
                                      style: AppTypography.label.copyWith(
                                        color: skin.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Totals, Tender Mode & Checkout Controls
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: skin.surface2,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (posState.selectedCustomer != null && posState.selectedCustomer!.creditLimit > 0) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_tabletTenderMethod == 'Credit' && posState.isCreditBlocked(0))
                              ? AppColors.danger.withValues(alpha: 0.12)
                              : skin.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_tabletTenderMethod == 'Credit' && posState.isCreditBlocked(0))
                                ? AppColors.danger
                                : skin.hairline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${posState.selectedCustomer!.name} Due: ${_currencyExact.format(posState.selectedCustomer!.dueAmount)} / ${_currencyExact.format(posState.selectedCustomer!.creditLimit)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: (_tabletTenderMethod == 'Credit' && posState.isCreditBlocked(0))
                                      ? AppColors.danger
                                      : skin.muted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_tabletTenderMethod == 'Credit' && posState.isCreditBlocked(0))
                              const Text(
                                'LIMIT EXCEEDED',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.danger),
                              ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal (${posState.priceTier})', style: AppTypography.caption.copyWith(color: skin.muted)),
                        Text(
                          _currencyExact.format(posState.subtotal),
                          style: AppTypography.label.copyWith(color: skin.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Order Discount (₹)',
                            style: AppTypography.caption.copyWith(color: skin.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          height: 32,
                          child: TextField(
                            controller: _tabletDiscountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: AppTypography.label.copyWith(color: skin.ink),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onChanged: (v) {
                              final d = double.tryParse(v.trim()) ?? 0;
                              ref.read(posNotifierProvider.notifier).setOrderDiscount(d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Packing / Parcel (₹)',
                            style: AppTypography.caption.copyWith(color: skin.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          height: 32,
                          child: TextField(
                            controller: _tabletPackingController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            style: AppTypography.label.copyWith(color: skin.ink),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onChanged: (v) {
                              final p = double.tryParse(v.trim()) ?? 0;
                              ref.read(posNotifierProvider.notifier).setPackingCharge(p);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Auto Round-Off', style: AppTypography.caption.copyWith(color: skin.muted)),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              value: posState.autoRoundOff,
                              onChanged: (v) => ref.read(posNotifierProvider.notifier).setAutoRoundOff(v),
                            ),
                          ],
                        ),
                        Text(
                          posState.autoRoundOff
                              ? '${posState.roundOffAmount >= 0 ? '+' : ''}${posState.roundOffAmount.toStringAsFixed(2)}'
                              : '₹0.00',
                          style: AppTypography.caption.copyWith(color: skin.muted, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Grand Total', style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
                        Text(
                          _currencyExact.format(posState.grandTotal),
                          style: AppTypography.numberCard.copyWith(color: skin.primary, fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...methods.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(m, style: const TextStyle(fontSize: 12)),
                                selected: _tabletTenderMethod == m,
                                onSelected: (_) => setState(() => _tabletTenderMethod = m),
                              ),
                            ),
                          ),
                          ActionChip(
                            label: const Text('Split', style: TextStyle(fontSize: 12)),
                            onPressed: posState.cart.isEmpty ? null : _openCheckoutSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (posState.cart.isEmpty || posState.isSubmitting) ? null : _holdBill,
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                            icon: Icon(
                              posState.kotFirstMode ? Icons.restaurant_menu_rounded : Icons.pause_circle_outline_rounded,
                              size: 16,
                            ),
                            label: Text(
                              posState.kotFirstMode ? 'Fire KOT First' : 'Hold / KOT',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _printLastReceipt,
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print 80mm', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (posState.cart.isEmpty || posState.isSubmitting)
                            ? null
                            : () => _quickPayTablet(posState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: skin.action,
                          foregroundColor: skin.actionInk,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: Text(
                          posState.isSubmitting
                              ? 'Posting to ERP...'
                              : 'Pay $_tabletTenderMethod (${_currencyExact.format(posState.grandTotal)})',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PosProductCard extends StatelessWidget {
  final PosProduct product;
  final double displayPrice;
  final double qtyInCart;
  final NumberFormat currency;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onToggle86;

  const _PosProductCard({
    required this.product,
    required this.displayPrice,
    required this.qtyInCart,
    required this.currency,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggle86,
  });

  String get _qtyBadge {
    final formatted = (qtyInCart - qtyInCart.roundToDouble()).abs() < 0.001
        ? qtyInCart.round().toString()
        : qtyInCart.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return '$formatted×';
  }

  ({IconData icon, Color color}) _productVisual(RippleSkin skin) {
    final lower = '${product.name} ${product.code} ${product.type}'.toLowerCase();
    if (lower.contains('water') ||
        lower.contains('20l') ||
        lower.contains('jar') ||
        lower.contains('can ')) {
      return (icon: Icons.water_drop_rounded, color: AppColors.aquaPrimary);
    }
    if (lower.contains('chai') ||
        lower.contains('tea') ||
        lower.contains('coffee') ||
        lower.contains('espresso') ||
        lower.contains('latte') ||
        lower.contains('filter')) {
      return (icon: Icons.local_cafe_rounded, color: AppColors.chaiPrimary);
    }
    if (lower.contains('juice') ||
        lower.contains('shake') ||
        lower.contains('soda') ||
        lower.contains('lime') ||
        lower.contains('lassi') ||
        lower.contains('cooler')) {
      return (icon: Icons.local_bar_rounded, color: const Color(0xFF0284C7));
    }
    if (lower.contains('puff') ||
        lower.contains('cake') ||
        lower.contains('bun') ||
        lower.contains('bread') ||
        lower.contains('croissant') ||
        lower.contains('muffin') ||
        lower.contains('bakery')) {
      return (icon: Icons.bakery_dining_rounded, color: const Color(0xFFD97706));
    }
    if (lower.contains('samosa') ||
        lower.contains('sandwich') ||
        lower.contains('burger') ||
        lower.contains('roll') ||
        lower.contains('snack') ||
        lower.contains('vada')) {
      return (icon: Icons.lunch_dining_rounded, color: AppColors.brandEmerald);
    }
    if (product.type == 'service') {
      return (icon: Icons.room_service_rounded, color: AppColors.info);
    }
    return (icon: Icons.local_mall_rounded, color: skin.primary);
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = qtyInCart > 0;
    final soldOut = !product.isAvailable;
    final visual = _productVisual(skin);
    final tileAccent = selected ? skin.primary : visual.color;

    return InkWell(
      onTap: soldOut ? null : onAdd,
      onLongPress: onToggle86,
      borderRadius: BorderRadius.circular(skin.cardRadius),
      child: Opacity(
        opacity: soldOut ? 0.58 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                Color.alphaBlend(
                  tileAccent.withValues(
                    alpha: selected ? (isDark ? 0.16 : 0.08) : (isDark ? 0.09 : 0.045),
                  ),
                  skin.surface,
                ),
                skin.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(skin.cardRadius),
            border: Border.all(
              color: selected
                  ? skin.primary
                  : tileAccent.withValues(alpha: isDark ? 0.24 : 0.16),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  RippleIconBadge(
                    icon: visual.icon,
                    accentColor: visual.color,
                    size: 36,
                    iconSize: 19,
                    radius: 11,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: soldOut
                              ? AppColors.danger.withValues(alpha: 0.14)
                              : skin.surface2,
                          borderRadius: BorderRadius.circular(skin.pillRadius),
                        ),
                        child: Text(
                          soldOut
                              ? '86 Sold Out'
                              : (product.type == 'service'
                                  ? 'Service'
                                  : '${product.stockQty.toStringAsFixed(0)} left'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: soldOut ? AppColors.danger : skin.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: skin.primary,
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                      ),
                      child: Text(
                        _qtyBadge,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                product.name,
                style: AppTypography.bodyMedium.copyWith(color: skin.ink, fontSize: 13.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (selected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currency.format(displayPrice),
                      style: AppTypography.numberInline.copyWith(color: skin.primary),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: onDecrement,
                          child: Icon(Icons.remove_circle_outline_rounded, size: 22, color: skin.primary),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onIncrement,
                          child: Icon(Icons.add_circle_rounded, size: 22, color: skin.primary),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currency.format(displayPrice),
                      style: AppTypography.numberCard.copyWith(color: skin.primary, fontSize: 17),
                    ),
                    Icon(
                      soldOut ? Icons.block_rounded : Icons.add_circle_outline_rounded,
                      size: 20,
                      color: soldOut ? AppColors.danger : skin.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLineModifierSheet extends ConsumerStatefulWidget {
  final PosCartItem line;

  const _CartLineModifierSheet({required this.line});

  @override
  ConsumerState<_CartLineModifierSheet> createState() => _CartLineModifierSheetState();
}

class _CartLineModifierSheetState extends ConsumerState<_CartLineModifierSheet> {
  static const _presetModifiers = [
    'No Sugar',
    'Less Sugar',
    'Extra Strong',
    'Extra Hot',
    'Parcel Pack',
    'Spicy',
    'No Onion',
    'Low Ice',
  ];
  static const _quickFractions = [0.25, 0.5, 1.0, 1.5, 2.0, 5.0];

  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.line.qtyLabel);
    _priceCtrl = TextEditingController(text: widget.line.unitPrice.toStringAsFixed(2));
    _noteCtrl = TextEditingController(text: widget.line.note ?? '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentTags = _noteCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.line.product.name} · Line Modifiers',
                    style: AppTypography.title.copyWith(color: skin.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Fractional / Quick Qty', style: AppTypography.label.copyWith(color: skin.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickFractions.map((q) {
                final label = (q - q.roundToDouble()).abs() < 0.001
                    ? q.round().toString()
                    : q.toStringAsFixed(2);
                return ActionChip(
                  label: Text('${label}x'),
                  onPressed: () => setState(() => _qtyCtrl.text = label),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity (e.g. 0.50, 1.5)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Rate (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Kitchen Prep Modifiers', style: AppTypography.label.copyWith(color: skin.muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presetModifiers.map((tag) {
                final selected = currentTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      final next = List<String>.from(currentTags);
                      if (v) {
                        if (!next.contains(tag)) next.add(tag);
                      } else {
                        next.remove(tag);
                      }
                      _noteCtrl.text = next.join(', ');
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Custom KOT / Line Prep Note',
                hintText: 'e.g. Less oil, separate chutney...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(posNotifierProvider.notifier).setItemQuantity(widget.line.product.id, 0);
                      Navigator.pop(context);
                    },
                    child: const Text('Remove Item'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skin.action,
                      foregroundColor: skin.actionInk,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply Line Changes'),
                    onPressed: () {
                      final parsedQty = double.tryParse(_qtyCtrl.text.trim()) ?? widget.line.qty;
                      final parsedPrice = double.tryParse(_priceCtrl.text.trim()) ?? widget.line.unitPrice;
                      ref.read(posNotifierProvider.notifier).setItemPriceAndModifiers(
                            widget.line.product.id,
                            qty: parsedQty,
                            unitPriceOverride: parsedPrice,
                            note: _noteCtrl.text,
                          );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PosCheckoutSheet extends ConsumerStatefulWidget {
  final PosTerminalState state;
  final List<String> paymentMethods;
  final NumberFormat currencyExact;
  final ValueChanged<PosOrderSummary> onCompleted;

  const _PosCheckoutSheet({
    required this.state,
    required this.paymentMethods,
    required this.currencyExact,
    required this.onCompleted,
  });

  @override
  ConsumerState<_PosCheckoutSheet> createState() => _PosCheckoutSheetState();
}

class _PosCheckoutSheetState extends ConsumerState<_PosCheckoutSheet> {
  late String _primaryMethod;
  bool _splitTender = false;
  late TextEditingController _primaryAmountCtrl;
  late TextEditingController _secondaryAmountCtrl;
  String _secondaryMethod = 'UPI';
  final _discountCtrl = TextEditingController(text: '0');
  final _packingCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _primaryMethod = widget.paymentMethods.first;
    if (_primaryMethod == 'UPI' && widget.paymentMethods.contains('Cash')) {
      _secondaryMethod = 'Cash';
    }
    _discountCtrl.text = widget.state.orderDiscount.toStringAsFixed(0);
    _packingCtrl.text = widget.state.packingCharge.toStringAsFixed(0);
    _primaryAmountCtrl = TextEditingController(
      text: widget.state.grandTotal.toStringAsFixed(2),
    );
    _secondaryAmountCtrl = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _primaryAmountCtrl.dispose();
    _secondaryAmountCtrl.dispose();
    _discountCtrl.dispose();
    _packingCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndPost() async {
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    final packing = double.tryParse(_packingCtrl.text.trim()) ?? 0;
    final notifier = ref.read(posNotifierProvider.notifier);
    notifier.setOrderDiscount(discount);
    notifier.setPackingCharge(packing);

    final latestState = ref.read(posNotifierProvider);
    final totalDue = latestState.grandTotal;
    final splits = <PosPaymentSplit>[];

    double paidSum = 0;
    if (_primaryMethod == 'Credit') {
      splits.add(const PosPaymentSplit(method: 'Credit', amount: 0));
    } else if (_splitTender) {
      final p1 = double.tryParse(_primaryAmountCtrl.text.trim()) ?? 0;
      final p2 = double.tryParse(_secondaryAmountCtrl.text.trim()) ?? 0;
      if (p1 > 0) splits.add(PosPaymentSplit(method: _primaryMethod, amount: p1));
      if (p2 > 0) splits.add(PosPaymentSplit(method: _secondaryMethod, amount: p2));
      paidSum = p1 + p2;
    } else {
      final paid = double.tryParse(_primaryAmountCtrl.text.trim()) ?? totalDue;
      splits.add(PosPaymentSplit(method: _primaryMethod, amount: paid.toDouble()));
      paidSum = paid.toDouble();
    }

    final shortfall = latestState.customerCreditShortfall(paidSum);
    if (shortfall > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Credit Limit Exceeded by ${widget.currencyExact.format(shortfall)}. Collect Cash/UPI before posting.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final res = await notifier.submitOrder(
          hold: false,
          payments: splits,
          saleNote: 'Counter POS (${latestState.orderType.toUpperCase()} · ${latestState.priceTier})',
        );
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final order):
        widget.onCompleted(order);
      case ApiFailure<PosOrderSummary>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final posState = ref.watch(posNotifierProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final customer = posState.selectedCustomer;
    final creditBlocked = posState.isCreditBlocked(_primaryMethod == 'Credit' ? 0 : posState.grandTotal);

    return Container(
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment & Checkout', style: AppTypography.title.copyWith(color: skin.ink)),
                Text(
                  widget.currencyExact.format(posState.grandTotal),
                  style: AppTypography.numberCard.copyWith(color: skin.primary),
                ),
              ],
            ),
            if (customer != null && customer.creditLimit > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: creditBlocked ? AppColors.danger.withValues(alpha: 0.12) : skin.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: creditBlocked ? AppColors.danger : skin.hairline),
                ),
                child: Text(
                  creditBlocked
                      ? '${customer.name}: Credit Limit Exceeded (Due ${widget.currencyExact.format(customer.dueAmount)} / Limit ${widget.currencyExact.format(customer.creditLimit)})'
                      : '${customer.name}: Due ${widget.currencyExact.format(customer.dueAmount)} / Limit ${widget.currencyExact.format(customer.creditLimit)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: creditBlocked ? AppColors.danger : skin.muted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text('Primary Tender', style: AppTypography.label.copyWith(color: skin.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.paymentMethods.map((m) {
                return ChoiceChip(
                  label: Text(m),
                  selected: _primaryMethod == m,
                  onSelected: (_) {
                    setState(() {
                      _primaryMethod = m;
                      if (m == 'Credit') {
                        _splitTender = false;
                        _primaryAmountCtrl.text = '0.00';
                      } else if ((double.tryParse(_primaryAmountCtrl.text) ?? 0) == 0) {
                        _primaryAmountCtrl.text = posState.grandTotal.toStringAsFixed(2);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_primaryMethod != 'Credit') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _primaryAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: '$_primaryMethod Amount (₹)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Discount (₹)'),
                      onChanged: (v) {
                        ref.read(posNotifierProvider.notifier).setOrderDiscount(double.tryParse(v.trim()) ?? 0);
                        if (!_splitTender) {
                          _primaryAmountCtrl.text = ref.read(posNotifierProvider).grandTotal.toStringAsFixed(2);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _packingCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Packing (₹)'),
                      onChanged: (v) {
                        ref.read(posNotifierProvider.notifier).setPackingCharge(double.tryParse(v.trim()) ?? 0);
                        if (!_splitTender) {
                          _primaryAmountCtrl.text = ref.read(posNotifierProvider).grandTotal.toStringAsFixed(2);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Auto Round-Off (${posState.roundOffAmount >= 0 ? '+' : ''}${posState.roundOffAmount.toStringAsFixed(2)})',
                  style: AppTypography.label.copyWith(color: skin.ink),
                ),
                value: posState.autoRoundOff,
                onChanged: (v) {
                  ref.read(posNotifierProvider.notifier).setAutoRoundOff(v);
                  if (!_splitTender) {
                    _primaryAmountCtrl.text = ref.read(posNotifierProvider).grandTotal.toStringAsFixed(2);
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Split payment across 2 methods', style: AppTypography.label.copyWith(color: skin.ink)),
                value: _splitTender,
                onChanged: (v) {
                  setState(() {
                    _splitTender = v;
                    if (v) {
                      final half = (posState.grandTotal / 2);
                      _primaryAmountCtrl.text = half.toStringAsFixed(2);
                      _secondaryAmountCtrl.text = (posState.grandTotal - half).toStringAsFixed(2);
                    }
                  });
                },
              ),
              if (_splitTender) ...[
                Wrap(
                  spacing: 8,
                  children: widget.paymentMethods
                      .where((m) => m != 'Credit' && m != _primaryMethod)
                      .map((m) => ChoiceChip(
                            label: Text(m),
                            selected: _secondaryMethod == m,
                            onSelected: (_) => setState(() => _secondaryMethod = m),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _secondaryAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: '$_secondaryMethod Amount (₹)'),
                ),
              ],
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: posState.isSubmitting ? null : _confirmAndPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: skin.action,
                foregroundColor: skin.actionInk,
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(posState.isSubmitting ? 'Posting to ERP...' : 'Complete & Post Bill'),
            ),
          ],
        ),
      ),
    );
  }
}
