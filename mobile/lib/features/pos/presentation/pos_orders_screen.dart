import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/pos_models.dart';
import 'pos_notifier.dart';

/// Stitch C-09..C-12: POS Orders Log, Held Drafts, Order Detail & Credit-Note Refund.
class PosOrdersScreen extends ConsumerStatefulWidget {
  const PosOrdersScreen({super.key});

  @override
  ConsumerState<PosOrdersScreen> createState() => _PosOrdersScreenState();
}

class _PosOrdersScreenState extends ConsumerState<PosOrdersScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  int? _statusFilter; // null = all, 3 = held, 1 = completed
  PosOrdersPage _page = const PosOrdersPage();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ref.read(posRepositoryProvider).fetchOrders(
          saleStatus: _statusFilter,
          query: _searchController.text,
        );

    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosOrdersPage>(data: final data):
        setState(() {
          _page = data;
          _isLoading = false;
        });
      case ApiFailure<PosOrdersPage>(failure: final f):
        setState(() {
          _error = f.message;
          _isLoading = false;
        });
    }
  }

  Future<void> _resumeDraft(PosOrderSummary order) async {
    final ok = await ref.read(posNotifierProvider.notifier).loadHeldOrder(order.id);
    if (!mounted) return;
    if (ok) {
      context.push('/operations/cafe-pos');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(posNotifierProvider).errorMessage ?? 'Could not load draft'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _cancelHeldDraft(PosOrderSummary order) async {
    final res = await ref.read(posRepositoryProvider).cancelHeldOrder(order.id);
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<bool>():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Held draft ${order.referenceNo} discarded.')),
        );
        await _loadOrders();
        ref.read(posNotifierProvider.notifier).loadBootstrap();
      case ApiFailure<bool>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  Future<void> _openOrderDetail(PosOrderSummary summary) async {
    final res = await ref.read(posRepositoryProvider).fetchOrderDetail(summary.id);
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final full):
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _OrderDetailSheet(
            order: full,
            currency: _currency,
            onResume: full.isHeld
                ? () {
                    Navigator.pop(context);
                    _resumeDraft(full);
                  }
                : null,
            onRefunded: () {
              Navigator.pop(context);
              _loadOrders();
              ref.read(posNotifierProvider.notifier).loadBootstrap();
            },
          ),
        );
      case ApiFailure<PosOrderSummary>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);

    return Scaffold(
      backgroundColor: skin.canvas,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('POS Orders & Held Bills', style: AppTypography.title.copyWith(color: skin.ink)),
                      const SizedBox(height: 2),
                      Text(
                        '${_page.completedCount} completed · ${_page.heldCount} held drafts',
                        style: AppTypography.caption.copyWith(color: skin.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/operations/cafe-pos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: skin.action,
                    foregroundColor: skin.actionInk,
                  ),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  label: const Text('New Bill'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by invoice ref or customer...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _loadOrders();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadOrders(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterPill(
                  label: 'All (${_page.completedCount + _page.heldCount})',
                  selected: _statusFilter == null,
                  onTap: () {
                    setState(() => _statusFilter = null);
                    _loadOrders();
                  },
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Held Drafts (${_page.heldCount})',
                  selected: _statusFilter == 3,
                  onTap: () {
                    setState(() => _statusFilter = 3);
                    _loadOrders();
                  },
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Completed (${_page.completedCount})',
                  selected: _statusFilter == 1,
                  onTap: () {
                    setState(() => _statusFilter = 1);
                    _loadOrders();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: TextStyle(color: skin.muted), textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _loadOrders,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: _page.orders.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'No POS bills match this filter.',
                                      style: AppTypography.body.copyWith(color: skin.muted),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _page.orders.length,
                                itemBuilder: (context, idx) {
                                  final order = _page.orders[idx];
                                  return _OrderCard(
                                    order: order,
                                    currency: _currency,
                                    onTap: () => _openOrderDetail(order),
                                    onResume: order.isHeld ? () => _resumeDraft(order) : null,
                                    onDiscard: order.isHeld ? () => _cancelHeldDraft(order) : null,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: skin.primary,
      backgroundColor: skin.surface,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: selected ? Colors.white : skin.ink,
      ),
      side: BorderSide(color: selected ? skin.primary : skin.hairline),
      shape: const StadiumBorder(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PosOrderSummary order;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback? onResume;
  final VoidCallback? onDiscard;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
    this.onResume,
    this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isHeld = order.isHeld;
    final badgeColor = isHeld ? AppColors.rippleHoney : AppColors.rippleMint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(skin.cardRadius),
              border: Border.all(color: skin.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.referenceNo,
                        style: AppTypography.bodyMedium.copyWith(color: skin.ink),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                      ),
                      child: Text(
                        isHeld ? 'HELD DRAFT' : order.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${order.customerName} · ${order.orderType.replaceAll('_', ' ').toUpperCase()}'
                        '${order.tableName != null ? ' · ${order.tableName}' : ''}',
                        style: AppTypography.caption.copyWith(color: skin.muted),
                      ),
                    ),
                    Text(
                      currency.format(order.grandTotal),
                      style: AppTypography.numberCard.copyWith(color: skin.primary, fontSize: 17),
                    ),
                  ],
                ),
                if (isHeld) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDiscard,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            foregroundColor: AppColors.danger,
                          ),
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: onResume,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            backgroundColor: skin.primary,
                          ),
                          child: const Text('Resume at Counter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  final PosOrderSummary order;
  final NumberFormat currency;
  final VoidCallback? onResume;
  final VoidCallback onRefunded;

  const _OrderDetailSheet({
    required this.order,
    required this.currency,
    this.onResume,
    required this.onRefunded,
  });

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  String _refundMethod = 'Cash';
  bool _restock = true;
  bool _isRefunding = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    setState(() => _isRefunding = true);
    final res = await ref.read(posRepositoryProvider).refundOrder(
          widget.order.id,
          refundMethod: _refundMethod,
          restock: _restock,
          reason: _reasonController.text.trim(),
          cashRegisterId: ref.read(posNotifierProvider).activeShift?.id,
        );
    if (!mounted) return;
    setState(() => _isRefunding = false);

    switch (res) {
      case ApiSuccess<Map<String, dynamic>>(data: final data):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Credit Note ${data['reference_no'] ?? ''} posted to ERP ledger.'),
            backgroundColor: AppColors.rippleMint,
          ),
        );
        widget.onRefunded();
      case ApiFailure<Map<String, dynamic>>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final order = widget.order;
    final hasReturnable = order.items.any((i) => i.returnableQty > 0);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.referenceNo, style: AppTypography.title.copyWith(color: skin.ink)),
                        Text(
                          '${order.customerName} · ${order.orderType.replaceAll('_', ' ')}',
                          style: AppTypography.caption.copyWith(color: skin.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.currency.format(order.grandTotal),
                    style: AppTypography.numberCard.copyWith(color: skin.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Items', style: AppTypography.section.copyWith(color: skin.ink)),
              const SizedBox(height: 8),
              ...order.items.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.productName, style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
                            Text(
                              '${line.qtyLabel} × ${widget.currency.format(line.netUnitPrice)}'
                              '${line.note != null && line.note!.isNotEmpty ? ' · ${line.note}' : ''}'
                              '${line.returnQty > 0 ? ' (Returned: ${line.returnQty.toStringAsFixed(0)})' : ''}',
                              style: AppTypography.caption.copyWith(color: skin.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        widget.currency.format(line.total),
                        style: AppTypography.numberInline.copyWith(color: skin.ink),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.payments.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Payments', style: AppTypography.section.copyWith(color: skin.ink)),
                const SizedBox(height: 8),
                ...order.payments.map(
                  (p) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.method, style: AppTypography.body.copyWith(color: skin.ink)),
                      Text(widget.currency.format(p.amount), style: AppTypography.numberInline.copyWith(color: skin.ink)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final res = await ref
                      .read(posRepositoryProvider)
                      .printOrderJob(order.id, format: '80mm');
                  if (!context.mounted) return;
                  if (res is ApiSuccess<Map<String, dynamic>>) {
                    final receiptText =
                        (res.data['receipt_text'] ?? 'Receipt queued').toString();
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Thermal Print Job · ${order.referenceNo}'),
                        content: SingleChildScrollView(
                          child: SelectableText(
                            receiptText,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontMono,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print 80mm Thermal Receipt'),
              ),
              if (widget.onResume != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: widget.onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume & Checkout'),
                ),
              ] else if (!order.isHeld && hasReturnable) ...[
                const Divider(height: 28),
                Text('Issue Credit Note / Refund', style: AppTypography.section.copyWith(color: skin.ink)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['Cash', 'UPI', 'Card'].map((m) {
                    return ChoiceChip(
                      label: Text(m),
                      selected: _refundMethod == m,
                      onSelected: (_) => setState(() => _refundMethod = m),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Restock returned items to inventory', style: AppTypography.label.copyWith(color: skin.ink)),
                  value: _restock,
                  onChanged: (v) => setState(() => _restock = v),
                ),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Reason (optional)',
                    hintText: 'e.g. Damaged item / Customer cancellation',
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _isRefunding ? null : _submitRefund,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: Text(_isRefunding ? 'Posting Credit Note...' : 'Post Full Credit Note Refund'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
