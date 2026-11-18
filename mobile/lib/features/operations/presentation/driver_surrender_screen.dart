import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/scrollable_counter_field.dart';

class DriverSurrenderScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const DriverSurrenderScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DriverSurrenderScreen> createState() => _DriverSurrenderScreenState();
}

class _DriverSurrenderScreenState extends ConsumerState<DriverSurrenderScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _collectedController = TextEditingController();
  final _expensesController = TextEditingController();
  final _notesController = TextEditingController();

  final Map<int, TextEditingController> _noteControllers = {
    500: TextEditingController(),
    200: TextEditingController(),
    100: TextEditingController(),
    50: TextEditingController(),
    20: TextEditingController(),
    10: TextEditingController(),
  };
  final _coinsController = TextEditingController();

  int _filledCansReturned = 0;
  int _emptyCansReturned = 0;
  int _damagedCansReported = 0;
  int _expectedFilledOnTruck = 0;
  int _expectedEmptiesOnTruck = 0;
  double _expectedCashCollected = 0.0;
  int _resolvedRouteOrVehicleId = 1;
  String _tankerVehicleNo = 'Assigned Tanker';
  int _completedTripsToday = 0;
  double _totalKlDispatched = 0.0;
  bool _manifestLoaded = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRouteManifestAndFinancials();
  }

  Future<void> _loadRouteManifestAndFinancials() async {
    final client = ref.read(apiClientProvider);
    final manifestRes = await client.get(
      ApiEndpoints.driverManifest,
      fromJson: (data) {
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      },
    );

    if (!mounted) return;
    if (manifestRes.isSuccess) {
      final raw = manifestRes.dataOrNull ?? <String, dynamic>{};
      final inv = raw['can_inventory'] is Map ? raw['can_inventory'] as Map : const {};
      final cashMap = raw['cash'] is Map ? raw['cash'] as Map : const {};
      final vehicleMap = raw['vehicle'] is Map ? raw['vehicle'] as Map : const {};
      final statsMap = raw['stats'] is Map ? raw['stats'] as Map : const {};
      final activeTripMap = raw['active_trip'] is Map ? raw['active_trip'] as Map : const {};
      setState(() {
        _manifestLoaded = true;
        _resolvedRouteOrVehicleId = int.tryParse((vehicleMap['id'] ?? 1).toString()) ?? 1;
        _tankerVehicleNo = vehicleMap['vehicle_number']?.toString() ?? 'Assigned Tanker';
        _completedTripsToday = int.tryParse((statsMap['trips_today'] ?? 0).toString()) ?? 0;
        _totalKlDispatched = double.tryParse((statsMap['total_kl'] ?? 0).toString()) ?? 0.0;
        _expectedFilledOnTruck = int.tryParse((inv['remaining_full_cans'] ?? 0).toString()) ?? 0;
        _expectedEmptiesOnTruck = int.tryParse((inv['empty_cans_on_truck'] ?? 0).toString()) ?? 0;
        final tankerTripCash = double.tryParse((activeTripMap['trip_rate'] ?? 0).toString()) ?? 0.0;
        _expectedCashCollected = double.tryParse((cashMap['cash_collected_today'] ?? cashMap['in_hand'] ?? 0).toString()) ?? tankerTripCash;
        if (_filledCansReturned == 0) _filledCansReturned = _expectedFilledOnTruck;
        if (_emptyCansReturned == 0) _emptyCansReturned = _expectedEmptiesOnTruck;
      });
    }
  }

  @override
  void dispose() {
    _collectedController.dispose();
    _expensesController.dispose();
    _notesController.dispose();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    _coinsController.dispose();
    super.dispose();
  }

  double get _denominationTotal {
    var total = 0.0;
    _noteControllers.forEach((denom, ctrl) {
      final count = int.tryParse(ctrl.text.trim()) ?? 0;
      total += denom * (count < 0 ? 0 : count);
    });
    final coins = double.tryParse(_coinsController.text.trim()) ?? 0.0;
    return total + (coins < 0 ? 0.0 : coins);
  }

  void _syncDenominationToGross() {
    final denomSum = _denominationTotal;
    setState(() {
      _collectedController.text = denomSum > 0 ? denomSum.toStringAsFixed(0) : '';
    });
  }

  double get _grossCollected {
    final manual = double.tryParse(_collectedController.text.trim());
    if (manual != null) return manual;
    return _denominationTotal;
  }

  double get _routeExpenses => double.tryParse(_expensesController.text.trim()) ?? 0;
  double get _netSurrender => _grossCollected - _routeExpenses;
  double get _expectedNetCash => (_expectedCashCollected - _routeExpenses).clamp(0.0, double.infinity);
  double get _cashVariance => _netSurrender - _expectedNetCash;
  bool get _hasDenomInput =>
      _noteControllers.values.any((c) => (int.tryParse(c.text.trim()) ?? 0) > 0) ||
      (double.tryParse(_coinsController.text.trim()) ?? 0) > 0;

  Future<void> _submitSurrender() async {
    if (_netSurrender < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expenses cannot exceed total collected cash.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final authState = ref.read(authNotifierProvider);
    final isTanker = ref.read(activeDriverFlavorProvider) == RippleDriverFlavor.tanker ||
        (authState.activeCompany?.industry ?? '') == 'bulk_water';

    final denominationsPayload = <String, dynamic>{
      for (final entry in _noteControllers.entries)
        entry.key.toString(): int.tryParse(entry.value.text.trim()) ?? 0,
      'coins': double.tryParse(_coinsController.text.trim()) ?? 0.0,
    };

    final payload = {
      'driver_id': authState.user?.id ?? 1,
      'route_id': _resolvedRouteOrVehicleId,
      'settlement_type': isTanker ? 'tanker_freight' : 'can_route',
      'cash_surrendered': _netSurrender,
      'empty_cans_returned': isTanker ? 0 : _emptyCansReturned,
      'filled_cans_returned': isTanker ? 0 : _filledCansReturned,
      'damaged_cans_reported': isTanker ? 0 : _damagedCansReported,
      'gross_cash_collected': _grossCollected,
      'route_expenses': _routeExpenses,
      'net_cash_surrendered': _netSurrender,
      'denominations': denominationsPayload,
      'notes': _notesController.text.trim(),
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.driverCashSurrender,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      final raw = result.dataOrNull;
      final dataMap = raw is Map && raw['data'] is Map ? raw['data'] as Map : (raw is Map ? raw : {});
      final audit = dataMap['audit_summary'] is Map ? dataMap['audit_summary'] as Map : const {};
      final isFlagged = audit['is_shortage_flagged'] == true;
      final shortage = double.tryParse((audit['cash_shortage'] ?? 0).toString()) ?? 0.0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFlagged
                ? 'Surrender logged with shortage alert (₹${shortage.toStringAsFixed(0)} short · Owner alerted)!'
                : 'Blind cash & can surrender verified and posted to ledger!',
          ),
          backgroundColor: isFlagged ? AppColors.warning : AppColors.success,
        ),
      );
      if (widget.embedded) {
        _expensesController.clear();
        _notesController.clear();
      } else {
        Navigator.of(context).pop();
      }
    } else if (result.failureOrNull?.statusCode == 422 || result.failureOrNull?.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Validation error on surrender.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.driverCashSurrender,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash surrender record queued in offline Outbox!'),
          backgroundColor: AppColors.warning,
        ),
      );
      if (widget.embedded) {
        _expensesController.clear();
        _notesController.clear();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final authState = ref.watch(authNotifierProvider);
    final isTanker = ref.watch(activeDriverFlavorProvider) == RippleDriverFlavor.tanker ||
        (authState.activeCompany?.industry ?? '') == 'bulk_water';

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(
                isTanker
                    ? 'Bulk Tanker Freight Settlement'
                    : 'Driver Blind Cash & Can Surrender',
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Blind Note Denomination Calculator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Blind Note Denomination Tally',
                        style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Notes: ₹${_denominationTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _noteControllers.entries.map((entry) {
                      final denom = entry.key;
                      final ctrl = entry.value;
                      final qty = int.tryParse(ctrl.text.trim()) ?? 0;
                      return SizedBox(
                        width: 145,
                        child: TextFormField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _syncDenominationToGross(),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: '₹$denom Notes',
                            suffixText: qty > 0 ? '= ₹${denom * qty}' : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _coinsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _syncDenominationToGross(),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Loose Coins (₹)',
                      prefixIcon: Icon(Icons.monetization_on_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tanker Freight Summary OR Can Van Jar Reconciliation (strict vertical isolation)
          if (isTanker)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Bulk Tanker Trip & Freight Settlement',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.aquaPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _tankerVehicleNo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.aquaPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTankerMetricTile('Completed Trips', '$_completedTripsToday Trips', textCol),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTankerMetricTile(
                            'Total Water KL',
                            '${_totalKlDispatched.toStringAsFixed(1)} KL',
                            textCol,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final skin = RippleSkin.of(context);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: skin.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: skin.primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Van Jar Count Reconciliation',
                                    style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                                  ),
                                  Text(
                                    'Count empty, unsold & damaged jars on van',
                                    style: AppTypography.caption.copyWith(color: skin.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ScrollableCounterRow(
                          title: 'Empty Jars Returned',
                          subtitle: 'Scroll wheel or tap to type',
                          value: _emptyCansReturned,
                          onChanged: (v) => setState(() => _emptyCansReturned = v),
                          titleColor: textCol,
                        ),
                        const Divider(height: 18),
                        ScrollableCounterRow(
                          title: 'Filled Cans Left on Van',
                          subtitle: 'Scroll wheel or tap to type',
                          value: _filledCansReturned,
                          onChanged: (v) => setState(() => _filledCansReturned = v),
                          titleColor: textCol,
                        ),
                        const Divider(height: 18),
                        ScrollableCounterRow(
                          title: 'Damaged / Leaked Jars',
                          subtitle: 'Scroll wheel or tap to type',
                          value: _damagedCansReported,
                          onChanged: (v) => setState(() => _damagedCansReported = v),
                          titleColor: textCol,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),

          Builder(
            builder: (context) {
              final skin = RippleSkin.of(context);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.success,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTanker ? 'Daily Tanker Freight Settlement' : 'Daily Route Cash Settlement',
                                  style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                                ),
                                Text(
                                  'Verified gross collection less route spend',
                                  style: AppTypography.caption.copyWith(color: skin.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        isTanker ? 'Freight Cash Collected (₹)' : 'Counted Gross Cash (₹)',
                        style: AppTypography.label.copyWith(color: textCol),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _collectedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.payments_rounded, size: 20),
                          hintText: 'Auto-calculated from denominations above',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isTanker
                            ? 'Less: Diesel, Toll, Motor & Batta Expenses (₹)'
                            : 'Less: Fuel & Route Expenses (₹)',
                        style: AppTypography.label.copyWith(color: textCol),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _expensesController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.local_gas_station_rounded, size: 20),
                          hintText: '0',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: skin.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: skin.hairline),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Net Cash Surrendered to Cashier',
                                style: AppTypography.section.copyWith(fontSize: 14.5, color: textCol),
                              ),
                            ),
                            AmountText(
                              amount: _netSurrender,
                              style: AppTypography.title.copyWith(
                                color: AppColors.success,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_manifestLoaded && (_hasDenomInput || _collectedController.text.trim().isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_cashVariance < -1 ? AppColors.danger : AppColors.success).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _cashVariance < -1 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: _cashVariance < -1 ? AppColors.danger : AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _cashVariance < -1
                                      ? 'Cash Variance: ₹${_cashVariance.abs().toStringAsFixed(0)} SHORT vs route cash (₹${_expectedNetCash.toStringAsFixed(0)})'
                                      : 'Matches route expected net cash (₹${_expectedNetCash.toStringAsFixed(0)})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _cashVariance < -1 ? AppColors.danger : AppColors.success,
                                  ),
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
            },
          ),
          const SizedBox(height: 16),

          Builder(
            builder: (context) {
              final skin = RippleSkin.of(context);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: skin.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.note_alt_rounded,
                              color: skin.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isTanker ? 'Plant Supervisor Handover Notes' : 'Cashier Handover Notes',
                              style: AppTypography.label.copyWith(color: textCol, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: isTanker
                              ? 'e.g. Freight cash + diesel/toll slips handed over to Plant Supervisor'
                              : 'e.g. Handed over counted notes + empties to Head Cashier',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSurrender,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(isTanker ? 'Confirm Freight Cash Settlement' : 'Confirm Blind Cash Surrender'),
          ),
        ],
      ),
    );
  }

  Widget _buildTankerMetricTile(String label, String value, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.aquaPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textCol),
          ),
        ],
      ),
    );
  }
}

