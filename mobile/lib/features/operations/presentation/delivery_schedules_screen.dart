import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/adaptive_layout.dart';
import '../../../core/ui/empty_state.dart';
import 'water_order_helpers.dart';

/// Recurring & Customizable Delivery Schedule Management Screen
/// Supports both 20L Water Can routes (`can`) and Bulk Tanker Lorries (`tanker`),
/// strictly locked to the active vertical unless the signed-in user is Super Admin.
class DeliverySchedulesScreen extends ConsumerStatefulWidget {
  final String? initialVerticalType;

  const DeliverySchedulesScreen({super.key, this.initialVerticalType});

  @override
  ConsumerState<DeliverySchedulesScreen> createState() =>
      _DeliverySchedulesScreenState();
}

class _DeliverySchedulesScreenState
    extends ConsumerState<DeliverySchedulesScreen> {
  bool _isLoading = true;
  bool _isGeneratingDue = false;
  late String _verticalType;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _tankers = [];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider);
    final role = (auth.user?.role ?? '').toLowerCase();
    final industry = (auth.activeCompany?.industry ?? '').toLowerCase();
    if (widget.initialVerticalType == 'tanker' ||
        role == 'tankerdriver' ||
        industry == 'bulk_water') {
      _verticalType = 'tanker';
    } else {
      _verticalType = 'can';
    }
    _loadSchedules();
  }

  bool get _isSuperAdmin {
    final auth = ref.read(authNotifierProvider);
    final role = (auth.user?.role ?? '').toLowerCase();
    return role == 'superadmin' ||
        role == 'super_admin' ||
        role == 'admin' ||
        role == 'owner' ||
        auth.roles.any((r) => const {'superadmin', 'super_admin', 'admin', 'owner'}.contains(r.toLowerCase()));
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final client = ref.read(apiClientProvider);
    final res = await client.get<Map<String, dynamic>>(
      '${ApiEndpoints.waterSchedules}?vertical_type=$_verticalType',
      fromJson: (raw) {
        if (raw is Map && raw['data'] is Map) {
          return Map<String, dynamic>.from(raw['data'] as Map);
        }
        return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      },
    );
    if (!mounted) return;
    final d = res.dataOrNull ?? const <String, dynamic>{};
    setState(() {
      _isLoading = false;
      _verticalType = (d['vertical_type']?.toString().isNotEmpty ?? false)
          ? d['vertical_type'].toString()
          : _verticalType;
      _schedules = _toMapList(d['schedules']);
      _customers = _toMapList(d['customers']);
      _routes = _toMapList(d['routes']);
      _tankers = _toMapList(d['tankers']);
    });
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _generateDueToday() async {
    setState(() => _isGeneratingDue = true);
    final res = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
      ApiEndpoints.waterSchedulesGenerateDue,
      data: {'vertical_type': _verticalType},
      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
    );
    if (!mounted) return;
    setState(() => _isGeneratingDue = false);
    if (res.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.dataOrNull?['message']?.toString() ?? 'Due scheduled Sales Orders generated.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Unable to generate due orders.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _callScheduleAction(String endpoint, String okMessage) async {
    final res = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
      endpoint,
      data: {'vertical_type': _verticalType},
      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
    );
    if (!mounted) return;
    if (res.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(okMessage), backgroundColor: AppColors.aquaPrimary),
      );
      await _loadSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Action failed.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openScheduleEditor({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final isTanker = _verticalType == 'tanker';

    int? selectedCustomerId = existing != null
        ? int.tryParse(existing['customer_id']?.toString() ?? '')
        : (_customers.isNotEmpty ? int.tryParse(_customers.first['id'].toString()) : null);
    int? selectedRouteId = existing != null
        ? int.tryParse(existing['route_id']?.toString() ?? '')
        : (_routes.isNotEmpty ? int.tryParse(_routes.first['id'].toString()) : null);
    int? selectedTankerId = existing != null
        ? int.tryParse(existing['tanker_id']?.toString() ?? '')
        : (_tankers.isNotEmpty ? int.tryParse(_tankers.first['id'].toString()) : null);

    final qtyCtrl = TextEditingController(
      text: existing != null
          ? (isTanker
              ? ((existing['ordered_qty'] as num?)?.toString() ?? '10')
              : ((existing['ordered_qty'] as num?)?.toInt().toString() ?? '7'))
          : (isTanker ? '10' : '7'),
    );
    final rateCtrl = TextEditingController(
      text: existing?['unit_rate'] != null
          ? ((existing!['unit_rate'] as num).toStringAsFixed(0))
          : (isTanker ? '1800' : '35'),
    );
    final intervalCtrl = TextEditingController(
      text: (existing?['interval_days'] ?? 2).toString(),
    );
    final slotCtrl = TextEditingController(
      text: (existing?['preferred_time_slot'] ?? '').toString(),
    );
    final notesCtrl = TextEditingController(
      text: (existing?['notes'] ?? '').toString(),
    );

    var frequency = (existing?['frequency'] ?? 'daily').toString();
    var startDate = (existing?['start_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString();
    var paymentMode = (existing?['payment_mode'] ?? (isTanker ? 'Credit' : 'Cash')).toString();
    var generateImmediately = !isEdit;
    final weekdays = <int>{
      ...(existing?['days_of_week'] is List
          ? (existing!['days_of_week'] as List)
              .map((e) => int.tryParse(e.toString()))
              .whereType<int>()
          : <int>[DateTime.now().weekday]),
    };
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SheetLifecycleScope(
        onDispose: () {
          qtyCtrl.dispose();
          rateCtrl.dispose();
          intervalCtrl.dispose();
          slotCtrl.dispose();
          notesCtrl.dispose();
        },
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
          final skin = RippleSkin.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit
                        ? 'Customize Delivery Schedule'
                        : 'Create Recurring Schedule (${isTanker ? 'Bulk Tanker' : 'Water Can'})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: skin.ink),
                  ),
                  const SizedBox(height: 12),
                  if (!isEdit && _customers.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedCustomerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(),
                      ),
                      items: _customers
                          .map((c) => DropdownMenuItem<int>(
                                value: int.tryParse(c['id'].toString()),
                                child: Text((c['name'] ?? 'Customer').toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedCustomerId = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!isTanker && _routes.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedRouteId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Beat Route',
                        border: OutlineInputBorder(),
                      ),
                      items: _routes
                          .map((r) => DropdownMenuItem<int>(
                                value: int.tryParse(r['id'].toString()),
                                child: Text((r['route_name'] ?? 'Route').toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedRouteId = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (isTanker && _tankers.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedTankerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Tanker Lorry',
                        border: OutlineInputBorder(),
                      ),
                      items: _tankers
                          .map((t) => DropdownMenuItem<int>(
                                value: int.tryParse(t['id'].toString()),
                                child: Text((t['vehicle_number'] ?? 'Tanker').toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedTankerId = v),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: isTanker ? 'Qty (KL) *' : 'Ordered Cans *',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: isTanker ? 'Trip Rate (₹)' : 'Rate/Can (₹)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'every_n_days', child: Text('Every N Days (e.g. Every 2 Days)')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly (Selected Days)')),
                      DropdownMenuItem(value: 'biweekly', child: Text('Every 2 Weeks (Biweekly)')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'one_time', child: Text('One-Time Planned')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => frequency = v);
                    },
                  ),
                  if (frequency == 'every_n_days') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: intervalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Every N Days (e.g. 2 for alternate days)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (frequency == 'weekly') ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: const [
                        (1, 'Mon'), (2, 'Tue'), (3, 'Wed'), (4, 'Thu'), (5, 'Fri'), (6, 'Sat'), (7, 'Sun'),
                      ].map((pair) {
                        final active = weekdays.contains(pair.$1);
                        return FilterChip(
                          selected: active,
                          label: Text(pair.$2, style: const TextStyle(fontSize: 11)),
                          onSelected: (v) {
                            setModalState(() {
                              if (v) {
                                weekdays.add(pair.$1);
                              } else if (weekdays.length > 1) {
                                weekdays.remove(pair.$1);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final init = DateTime.tryParse(startDate) ?? DateTime.now();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: init,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() => startDate = picked.toIso8601String().substring(0, 10));
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text('Start: $startDate'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['Cash', 'UPI', 'Credit'].contains(paymentMode) ? paymentMode : 'Cash',
                          decoration: const InputDecoration(
                            labelText: 'Payment Mode',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                            DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => paymentMode = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: slotCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Time Slot (e.g. 07:00 AM - 09:00 AM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Custom Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: generateImmediately,
                      onChanged: (v) => setModalState(() => generateImmediately = v),
                      title: const Text('Create first Sales Order immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              final client = ref.read(apiClientProvider);
                              final payload = <String, dynamic>{
                                'vertical_type': _verticalType,
                                if (!isEdit && selectedCustomerId != null) 'customer_id': selectedCustomerId,
                                if (selectedRouteId != null && !isTanker) 'route_id': selectedRouteId,
                                if (selectedTankerId != null && isTanker) 'tanker_id': selectedTankerId,
                                'ordered_qty': double.tryParse(qtyCtrl.text.trim()) ?? (isTanker ? 10 : 7),
                                'unit_rate': double.tryParse(rateCtrl.text.trim()),
                                'payment_mode': paymentMode,
                                'frequency': frequency,
                                'interval_days': int.tryParse(intervalCtrl.text.trim()) ?? 2,
                                'days_of_week': weekdays.toList()..sort(),
                                'start_date': startDate,
                                if (slotCtrl.text.trim().isNotEmpty) 'preferred_time_slot': slotCtrl.text.trim(),
                                if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                                if (!isEdit) 'generate_immediately': generateImmediately,
                              };
                              final res = isEdit
                                  ? await client.put<Map<String, dynamic>>(
                                      ApiEndpoints.waterScheduleDetail(int.parse(existing['id'].toString())),
                                      data: payload,
                                      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
                                    )
                                  : await client.post<Map<String, dynamic>>(
                                      ApiEndpoints.waterSchedules,
                                      data: payload,
                                      fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
                                    );
                              if (!ctx.mounted) return;
                              setModalState(() => saving = false);
                              if (res.isSuccess) {
                                Navigator.of(ctx).pop();
                                ref.read(dashboardRefreshSignalProvider.notifier).state++;
                                await _loadSchedules();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit ? 'Schedule updated.' : 'Recurring schedule created.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(res.failureOrNull?.message ?? 'Unable to save schedule.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      child: Text(
                        saving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Schedule'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isTanker = _verticalType == 'tanker';

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: AppBar(
        backgroundColor: skin.canvas,
        foregroundColor: skin.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Schedules', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              isTanker ? 'Bulk Water Tanker Recurring Plans' : 'Water Can Recurring Plans',
              style: TextStyle(fontSize: 11, color: skin.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isGeneratingDue ? null : _generateDueToday,
            tooltip: 'Generate Due Orders Today',
            icon: _isGeneratingDue
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bolt_rounded),
          ),
          IconButton(
            onPressed: () => _openScheduleEditor(),
            tooltip: 'Create Schedule',
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleEditor(),
        backgroundColor: AppColors.aquaPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_repeat_rounded),
        label: const Text('Create Schedule', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: AdaptivePageConstraint(
        maxWidth: 1080,
        child: RefreshIndicator(
          onRefresh: _loadSchedules,
          child: Column(
            children: [
              if (_isSuperAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      ChoiceChip(
                        selected: !isTanker,
                        label: const Text('Water Can'),
                        onSelected: (_) {
                          if (_verticalType != 'can') {
                            setState(() => _verticalType = 'can');
                            _loadSchedules();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        selected: isTanker,
                        label: const Text('Bulk Tanker Lorry'),
                        onSelected: (_) {
                          if (_verticalType != 'tanker') {
                            setState(() => _verticalType = 'tanker');
                            _loadSchedules();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _schedules.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: const [
                              EmptyState(
                                title: 'No Recurring Schedules Yet',
                                message: 'Create Daily, Every 2 Days, Weekly, or Custom delivery schedules for regular customers.',
                                icon: Icons.event_repeat_rounded,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: _schedules.length,
                            itemBuilder: (_, idx) {
                              final s = _schedules[idx];
                              final active = s['is_active'] == true;
                              final qtyUnit = isTanker ? 'KL' : 'Cans';
                              final qtyText = isTanker
                                  ? ((s['ordered_qty'] as num?)?.toStringAsFixed(1) ?? '10.0')
                                  : ((s['ordered_qty'] as num?)?.toInt().toString() ?? '7');
                              final sid = int.parse(s['id'].toString());

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s['customer_name']?.toString() ?? 'Customer',
                                              style: AppTypography.label.copyWith(
                                                color: skin.ink,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (active ? AppColors.rippleMint : skin.muted)
                                                  .withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              active ? 'ACTIVE' : 'PAUSED',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: active ? AppColors.rippleMint : skin.muted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.aquaPrimary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              s['schedule_label']?.toString() ?? 'Regular',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.aquaPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '$qtyText $qtyUnit · ₹${s['unit_rate'] ?? 0}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: skin.ink),
                                          ),
                                          Text(
                                            'Next: ${s['next_run_date'] ?? 'Completed'}',
                                            style: TextStyle(fontSize: 12, color: skin.muted, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          FilledButton.tonalIcon(
                                            onPressed: () => _callScheduleAction(
                                              ApiEndpoints.waterScheduleGenerateNow(sid),
                                              'Created Sales Order for today.',
                                            ),
                                            icon: const Icon(Icons.bolt_rounded, size: 16),
                                            label: const Text('Create Today'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _openScheduleEditor(existing: s),
                                            icon: const Icon(Icons.tune_rounded, size: 16),
                                            label: const Text('Customize'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => _callScheduleAction(
                                              ApiEndpoints.waterScheduleSkip(sid),
                                              'Skipped next occurrence.',
                                            ),
                                            child: const Text('Skip Next'),
                                          ),
                                          OutlinedButton(
                                            onPressed: () => _callScheduleAction(
                                              ApiEndpoints.waterScheduleToggle(sid),
                                              active ? 'Schedule paused.' : 'Schedule resumed.',
                                            ),
                                            child: Text(active ? 'Pause' : 'Resume'),
                                          ),
                                        ],
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
      ),
    );
  }
}

