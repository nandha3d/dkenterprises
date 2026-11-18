import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/ripple_components.dart';
import '../domain/pos_models.dart';
import 'pos_notifier.dart';

/// Stitch C-30..C-36 & C-08: Kitchen & Ingredient Ops Hub.
/// Fully connected to live ERP POS KDS, 86 Availability, Production Batches,
/// Spoilage Wastage, and Reorder Request endpoints.
class PosKitchenScreen extends ConsumerStatefulWidget {
  const PosKitchenScreen({super.key});

  @override
  ConsumerState<PosKitchenScreen> createState() => _PosKitchenScreenState();
}

class _PosKitchenScreenState extends ConsumerState<PosKitchenScreen> {
  bool _loadingKds = false;
  List<PosOrderSummary> _kdsTickets = const [];
  Map<String, int> _kdsCounts = const {
    'new': 0,
    'preparing': 0,
    'ready': 0,
    'served': 0,
  };
  List<Map<String, dynamic>> _reorderRequests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKitchenData();
    });
  }

  Future<void> _refreshKitchenData() async {
    if (!mounted) return;
    setState(() => _loadingKds = true);
    final repo = ref.read(posRepositoryProvider);

    final kdsRes = await repo.fetchKdsTickets();
    final reorderRes = await repo.fetchReorderRequests();

    if (!mounted) return;
    setState(() {
      _loadingKds = false;
      if (kdsRes is ApiSuccess<Map<String, dynamic>>) {
        final rawTickets = kdsRes.data['tickets'] as List<dynamic>? ?? const [];
        _kdsTickets = rawTickets
            .whereType<Map>()
            .map((e) => PosOrderSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final counts = kdsRes.data['counts'] is Map
            ? Map<String, dynamic>.from(kdsRes.data['counts'] as Map)
            : const <String, dynamic>{};
        _kdsCounts = {
          'new': int.tryParse((counts['new'] ?? 0).toString()) ?? 0,
          'preparing': int.tryParse((counts['preparing'] ?? 0).toString()) ?? 0,
          'ready': int.tryParse((counts['ready'] ?? 0).toString()) ?? 0,
          'served': int.tryParse((counts['served'] ?? 0).toString()) ?? 0,
        };
      }
      if (reorderRes is ApiSuccess<List<Map<String, dynamic>>>) {
        _reorderRequests = reorderRes.data;
      }
    });
  }

  Future<void> _bumpTicket(PosOrderSummary ticket, String nextStatus) async {
    final repo = ref.read(posRepositoryProvider);
    final res = await repo.updateKdsStatus(ticket.id, nextStatus);
    if (!mounted) return;
    if (res is ApiSuccess<PosOrderSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ticket.referenceNo} -> $nextStatus')),
      );
      await _refreshKitchenData();
    } else if (res is ApiFailure<PosOrderSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.failure.message)),
      );
    }
  }

  Future<void> _open86AvailabilitySheet(List<PosProduct> products) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final skin = RippleSkin.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final latestProducts =
                ref.watch(posNotifierProvider).bootstrap?.products ?? products;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.78,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: skin.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quick 86 / Menu Availability',
                          style: AppTypography.title.copyWith(color: skin.ink),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Toggle item availability at the counter without editing master SKU pricing.',
                    style: AppTypography.caption.copyWith(color: skin.muted),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: latestProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No menu items loaded yet.',
                              style: AppTypography.caption
                                  .copyWith(color: skin.muted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: latestProducts.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: skin.hairline),
                            itemBuilder: (_, index) {
                              final item = latestProducts[index];
                              return SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  item.name,
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: skin.ink),
                                ),
                                subtitle: Text(
                                  'SKU: ${item.code} · Stock: ${item.stockQty.toStringAsFixed(0)} · ₹${item.price.toStringAsFixed(0)}',
                                  style: AppTypography.caption
                                      .copyWith(color: skin.muted),
                                ),
                                value: item.isAvailable,
                                activeThumbColor: skin.primary,
                                onChanged: (val) async {
                                  final res = await ref
                                      .read(posRepositoryProvider)
                                      .toggleProductAvailability(
                                        item.id,
                                        isAvailable: val,
                                      );
                                  if (!ctx.mounted) return;
                                  if (res is ApiSuccess) {
                                    await ref
                                        .read(posNotifierProvider.notifier)
                                        .loadBootstrap();
                                    setModalState(() {});
                                  }
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
      },
    );
  }

  Future<void> _openBatchOrWastageDialog({
    required bool isWastage,
    required List<PosProduct> products,
  }) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load POS catalog first to select a SKU.')),
      );
      return;
    }

    int selectedProductId = products.first.id;
    final qtyCtrl = TextEditingController(text: isWastage ? '2' : '20');
    final noteCtrl = TextEditingController();
    String selectedReason = 'Expired / Spoiled';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isWastage
                ? 'Record Kitchen Wastage'
                : 'Log Production Batch',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProductId,
                  decoration:
                      const InputDecoration(labelText: 'Menu / Kitchen SKU'),
                  items: products
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                              '${p.name} (${p.stockQty.toStringAsFixed(0)})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedProductId = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText:
                        isWastage ? 'Wasted Quantity' : 'Produced Quantity',
                  ),
                ),
                if (isWastage) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration:
                        const InputDecoration(labelText: 'Wastage Reason'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Expired / Spoiled',
                        child: Text('Expired / Spoiled'),
                      ),
                      DropdownMenuItem(
                        value: 'Burnt / Prep Error',
                        child: Text('Burnt / Prep Error'),
                      ),
                      DropdownMenuItem(
                        value: 'Damaged Packaging',
                        child: Text('Damaged Packaging'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedReason = v);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Batch / Shift Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isWastage ? 'Write Off Stock' : 'Post Batch'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) return;

    final repo = ref.read(posRepositoryProvider);
    final res = isWastage
        ? await repo.createWastage(
            productId: selectedProductId,
            wastedQty: qty,
            reason: selectedReason,
            notes: noteCtrl.text.trim(),
          )
        : await repo.createProductionBatch(
            productId: selectedProductId,
            producedQty: qty,
            notes: noteCtrl.text.trim(),
          );

    if (!mounted) return;
    if (res is ApiSuccess<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWastage
                ? 'Wastage write-off recorded (${res.data['reference_no'] ?? 'OK'})'
                : 'Production batch added to stock (${res.data['batch_ref'] ?? 'OK'})',
          ),
        ),
      );
      await ref.read(posNotifierProvider.notifier).loadBootstrap();
    } else if (res is ApiFailure<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.failure.message)),
      );
    }
  }

  Future<void> _openReorderRequestDialog(List<PosProduct> products) async {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Load POS catalog first to request reorder.')),
      );
      return;
    }

    int selectedProductId = products.first.id;
    final qtyCtrl = TextEditingController(text: '25');
    final noteCtrl =
        TextEditingController(text: 'Kitchen counter replenishment');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Kitchen Reorder Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedProductId,
                decoration:
                    const InputDecoration(labelText: 'Ingredient / Item'),
                items: products
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(
                            '${p.name} (Stock: ${p.stockQty.toStringAsFixed(0)})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedProductId = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Requested Quantity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Procurement Note'),
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
              child: const Text('Submit Requisition'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) return;

    final res = await ref.read(posRepositoryProvider).createReorderRequest(
          items: [
            {
              'product_id': selectedProductId,
              'requested_qty': qty,
            },
          ],
          notes: noteCtrl.text.trim(),
        );

    if (!mounted) return;
    if (res is ApiSuccess<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reorder requisition submitted (${res.data['reference_no'] ?? 'PR'})',
          ),
        ),
      );
      await _refreshKitchenData();
    } else if (res is ApiFailure<Map<String, dynamic>>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.failure.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final posState = ref.watch(posNotifierProvider);
    final products = posState.bootstrap?.products ?? const <PosProduct>[];

    return Scaffold(
      backgroundColor: skin.canvas,
      body: RefreshIndicator(
        onRefresh: _refreshKitchenData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            RippleHeroBanner(
              eyebrow: 'Chai & Crema · Kitchen & Store',
              headline: 'Kitchen Display & Prep',
              subheadline:
                  'Live KOT bump board, 86 item availability, production batches, wastage, and stock audits.',
              pills: [
                RippleHeroPill(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh KDS',
                  isPrimary: true,
                  onPressed: _refreshKitchenData,
                ),
                RippleHeroPill(
                  icon: Icons.block_rounded,
                  label: '86 Menu Toggle',
                  onPressed: () => _open86AvailabilitySheet(products),
                ),
              ],
            ),
            if (_loadingKds)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kitchen Display Queue',
                    style: AppTypography.section.copyWith(color: skin.ink),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: skin.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(skin.pillRadius),
                  ),
                  child: Text(
                    '${_kdsCounts['new'] ?? 0} New · ${_kdsCounts['preparing'] ?? 0} Prep · ${_kdsCounts['ready'] ?? 0} Ready',
                    style: AppTypography.caption.copyWith(
                      color: skin.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_kdsTickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: skin.hairline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: skin.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All kitchen tickets are cleared. New counter KOTs appear here automatically.',
                        style: AppTypography.caption.copyWith(color: skin.muted),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._kdsTickets.take(6).map(
                    (ticket) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: skin.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: skin.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${ticket.referenceNo} · ${ticket.tableName ?? ticket.orderType.toUpperCase()}',
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: skin.ink),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: skin.primary.withValues(alpha: 0.14),
                                    borderRadius:
                                        BorderRadius.circular(skin.pillRadius),
                                  ),
                                  child: Text(
                                    ticket.kdsStatus,
                                    style: AppTypography.caption.copyWith(
                                      color: skin.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.items
                                  .map((i) =>
                                      '${i.qty.toStringAsFixed(0)}x ${i.productName}')
                                  .join(' · '),
                              style:
                                  AppTypography.body.copyWith(color: skin.muted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (ticket.kdsStatus == 'NEW')
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _bumpTicket(ticket, 'PREPARING'),
                                    icon: const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 16),
                                    label: const Text('Start Prep'),
                                  ),
                                if (ticket.kdsStatus == 'NEW' ||
                                    ticket.kdsStatus == 'PREPARING')
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _bumpTicket(ticket, 'READY'),
                                    icon: const Icon(
                                        Icons.notifications_active_rounded,
                                        size: 16),
                                    label: const Text('Mark Ready'),
                                  ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _bumpTicket(ticket, 'SERVED'),
                                  icon: const Icon(Icons.done_all_rounded,
                                      size: 16),
                                  label: const Text('Bump / Served'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            Text(
              'Kitchen Production, 86 & Replenishment',
              style: AppTypography.section.copyWith(color: skin.ink),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.block_rounded,
              title: 'Quick 86 / Menu Availability Toggle',
              subtitle:
                  'Instant out-of-stock toggle at the counter (${products.where((p) => !p.isAvailable).length} currently 86\'d).',
              accentColor: AppColors.danger,
              onTap: () => _open86AvailabilitySheet(products),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.blender_rounded,
              title: 'Log Production Batch',
              subtitle:
                  'Post freshly prepared bakery/tea batch directly to ERP inventory.',
              accentColor: skin.primary,
              onTap: () => _openBatchOrWastageDialog(
                isWastage: false,
                products: products,
              ),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.delete_sweep_rounded,
              title: 'Record Kitchen Wastage & Spoilage',
              subtitle:
                  'Write off spoilt or damaged kitchen stock with audit reason code.',
              accentColor: AppColors.warning,
              onTap: () => _openBatchOrWastageDialog(
                isWastage: true,
                products: products,
              ),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Kitchen Reorder Request / Internal PO',
              subtitle:
                  'Submit low-stock replenishment request (${_reorderRequests.length} active requests).',
              accentColor: AppColors.info,
              onTap: () => _openReorderRequestDialog(products),
            ),
            const SizedBox(height: 20),
            Text(
              'Store Audit & Petty Cash',
              style: AppTypography.section.copyWith(color: skin.ink),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.fact_check_rounded,
              title: 'Kitchen & Ingredient Stock Audit',
              subtitle:
                  'Submit physical closing stock counts directly to ERP inventory.',
              accentColor: skin.primary,
              onTap: () => context.push('/inventory/stock-count'),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.warehouse_rounded,
              title: 'Warehouse Stock Valuation',
              subtitle:
                  'Check current quantity on hand across kitchen & counter stores.',
              accentColor: AppColors.rippleSky,
              onTap: () => context.push('/inventory'),
            ),
            const SizedBox(height: 10),
            RippleActionCard(
              icon: Icons.receipt_long_rounded,
              title: 'Daily Cafe Expenses',
              subtitle:
                  'Record milk, gas, supplies, or cleaning expenses against the cafe.',
              accentColor: AppColors.rippleHoney,
              onTap: () => context.push('/expenses/new'),
            ),
          ],
        ),
      ),
    );
  }
}
