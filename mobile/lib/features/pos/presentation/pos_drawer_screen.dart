import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/ripple_components.dart';
import '../domain/pos_models.dart';
import 'pos_notifier.dart';

/// Stitch C-20..C-24: Cash Drawer Float, Live X-Report & Shift Close Z-Report.
class PosDrawerScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const PosDrawerScreen({super.key, this.embedded = true});

  @override
  ConsumerState<PosDrawerScreen> createState() => _PosDrawerScreenState();
}

class _PosDrawerScreenState extends ConsumerState<PosDrawerScreen> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  PosShift? _shift;
  PosShift? _closedReceipt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadShift() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ref.read(posRepositoryProvider).fetchCurrentShift();
    if (!mounted) return;
    switch (res) {
      case ApiSuccess<PosShift?>(data: final shift):
        setState(() {
          _shift = shift;
          _isLoading = false;
        });
      case ApiFailure<PosShift?>(failure: final f):
        setState(() {
          _error = f.message;
          _isLoading = false;
        });
    }
  }

  Future<void> _openShift() async {
    final floatAmount = double.tryParse(_amountController.text.trim()) ?? -1;
    if (floatAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid opening float amount (0 or greater).')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ref.read(posNotifierProvider.notifier).openShift(cashInHand: floatAmount);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (res) {
      case ApiSuccess<PosShift>(data: final opened):
        _amountController.clear();
        setState(() {
          _shift = opened;
          _closedReceipt = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash register shift opened in ERP.'),
            backgroundColor: AppColors.rippleMint,
          ),
        );
      case ApiFailure<PosShift>(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message), backgroundColor: AppColors.danger),
        );
    }
  }

  Future<void> _closeShift() async {
    final actualCash = double.tryParse(_amountController.text.trim()) ?? -1;
    if (actualCash < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter physical counted cash in drawer.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ref.read(posNotifierProvider.notifier).closeShift(
          actualCash: actualCash,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (res) {
      case ApiSuccess<PosShift>(data: final closed):
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _shift = null;
          _closedReceipt = closed;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Z-Report generated and shift closed cleanly.'),
            backgroundColor: AppColors.rippleMint,
          ),
        );
      case ApiFailure<PosShift>(failure: final f):
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
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('ERP POS Cash Drawer & X/Z Report'),
            ),
      body: RefreshIndicator(
        onRefresh: _loadShift,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: skin.muted)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loadShift,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      if (_shift == null) ...[
                        const RippleHeroBanner(
                          eyebrow: 'ERP Cash Register',
                          headline: 'Shift Closed',
                          subheadline: 'Count opening cash float to start taking counter bills.',
                        ),
                        if (_closedReceipt != null) ...[
                          const SizedBox(height: 16),
                          _ShiftHandoverSummary(shift: _closedReceipt!, currency: _currency),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: skin.surface,
                            borderRadius: BorderRadius.circular(skin.cardRadius),
                            border: Border.all(color: skin.hairline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Open Shift', style: AppTypography.section.copyWith(color: skin.ink)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Opening Cash Float (₹)',
                                  hintText: 'e.g. 2000.00',
                                  prefixIcon: Icon(Icons.payments_rounded),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _openShift,
                                icon: const Icon(Icons.lock_open_rounded),
                                label: Text(_isSubmitting ? 'Opening Shift...' : 'Open Cash Register Shift'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        RippleHeroBanner(
                          eyebrow: 'Active Shift · X-Report',
                          headline: _currency.format(_shift!.expectedCash),
                          subheadline:
                              'Expected Cash in Drawer · ${_shift!.ordersCount} bills · Total Sales ${_currency.format(_shift!.totalSalesAmount)}',
                        ),
                        const SizedBox(height: 16),
                        _XReportBreakdown(shift: _shift!, currency: _currency),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: skin.surface,
                            borderRadius: BorderRadius.circular(skin.cardRadius),
                            border: Border.all(color: skin.hairline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Close & Handover (Z-Report)', style: AppTypography.section.copyWith(color: skin.ink)),
                              const SizedBox(height: 6),
                              Text(
                                'Count physical cash inside the drawer. Variance against ${_currency.format(_shift!.expectedCash)} will be logged automatically.',
                                style: AppTypography.caption.copyWith(color: skin.muted),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Counted Physical Cash (₹)',
                                  hintText: 'Enter exact drawer count',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Handover Note (optional)',
                                  hintText: 'e.g. Verified by manager',
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _closeShift,
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                icon: const Icon(Icons.lock_rounded),
                                label: Text(_isSubmitting ? 'Closing Shift...' : 'Close Shift & Generate Z-Report'),
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
}

class _XReportBreakdown extends StatelessWidget {
  final PosShift shift;
  final NumberFormat currency;

  const _XReportBreakdown({required this.shift, required this.currency});

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final rows = [
      ('Opening Float', shift.cashInHand),
      ('Cash Sales', shift.cashPayment),
      ('UPI Payments', shift.upiPayment),
      ('Card Payments', shift.cardPayment),
      ('Bank / Cheque / Gift', shift.bankPayment + shift.chequePayment + shift.giftCardPayment),
      ('Credit Sales (Due)', shift.creditSaleAmount),
      ('Less: Sale Returns', -shift.totalSaleReturn),
      ('Less: Cash Expenses', -shift.totalExpense),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tender Breakdown', style: AppTypography.section.copyWith(color: skin.ink)),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1, style: AppTypography.body.copyWith(color: skin.muted)),
                  Text(
                    currency.format(r.$2),
                    style: AppTypography.numberInline.copyWith(
                      color: r.$2 < 0 ? AppColors.danger : skin.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expected Cash in Drawer', style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
              Text(
                currency.format(shift.expectedCash),
                style: AppTypography.numberCard.copyWith(color: skin.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftHandoverSummary extends StatelessWidget {
  final PosShift shift;
  final NumberFormat currency;

  const _ShiftHandoverSummary({required this.shift, required this.currency});

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final variance = shift.variance ?? 0;
    final varianceColor = variance.abs() < 0.01 ? AppColors.rippleMint : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: AppColors.rippleMint.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.rippleMint),
              const SizedBox(width: 8),
              Text('Last Closed Z-Report (#${shift.id})', style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expected Cash', style: AppTypography.caption.copyWith(color: skin.muted)),
              Text(currency.format(shift.expectedCash), style: AppTypography.numberInline.copyWith(color: skin.ink)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Variance', style: AppTypography.caption.copyWith(color: skin.muted)),
              Text(
                currency.format(variance),
                style: AppTypography.numberInline.copyWith(color: varianceColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
