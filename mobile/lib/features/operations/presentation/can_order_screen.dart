import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/scrollable_counter_field.dart';
import 'can_sales_screen.dart';

/// Stage 1 of the Water Can Order-First Workflow:
/// Delivery boy (or Admin/Incharge) books a customer order (e.g., 7 cans)
/// BEFORE moving to the customer's place, immediately notifying Owner & Incharges.
class CanOrderScreen extends ConsumerStatefulWidget {
  final CanGpsFetcher? gpsFetcher;
  final int? initialCustomerId;
  final int? initialOrderedCans;

  const CanOrderScreen({
    super.key,
    this.gpsFetcher,
    this.initialCustomerId,
    this.initialOrderedCans,
  });

  @override
  ConsumerState<CanOrderScreen> createState() => _CanOrderScreenState();
}

class _CanOrderScreenState extends ConsumerState<CanOrderScreen> {
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();

  int _orderedCans = 7;
  String _selectedCanSize = '20L Can';
  double _canRate = 0.0;
  String _paymentMode = 'Cash';
  bool _startImmediately = false;
  late DateTime _deliveryDate = DateTime.now();
  String _scheduleFrequency = 'on_day';
  int _intervalDays = 2;
  late final Set<int> _selectedWeekdays = {DateTime.now().weekday};
  String _preferredTimeSlot = '';

  String _formatYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isMockGps = false;
  double? _currentLat;
  double? _currentLng;
  int? _routeId;
  int _vanRemainingCans = 0;
  int? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];

  static const List<int> _quickQuantities = [1, 2, 5, 7, 10, 15, 20, 25];

  @override
  void initState() {
    super.initState();
    _orderedCans = widget.initialOrderedCans != null && widget.initialOrderedCans! > 0
        ? widget.initialOrderedCans!
        : 7;
    _loadData();
    _captureGpsFix();
  }

  Future<void> _loadData() async {
    final client = ref.read(apiClientProvider);
    final custFuture = client.get(
      ApiEndpoints.customers,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      },
    );
    final manifestFuture = client.get(
      ApiEndpoints.driverManifest,
      fromJson: (data) {
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      },
    );

    final custRes = await custFuture;
    final manifestRes = await manifestFuture;
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (manifestRes.isSuccess) {
        final m = manifestRes.dataOrNull ?? const <String, dynamic>{};
        final veh = m['vehicle'];
        if (veh is Map) {
          _routeId = int.tryParse((veh['id'] ?? '').toString());
        }
        final inv = m['can_inventory'];
        if (inv is Map) {
          _vanRemainingCans = int.tryParse((inv['remaining_full_cans'] ?? 0).toString()) ?? 0;
        }
      }
      if (custRes.isSuccess) {
        _customers = custRes.dataOrNull ?? [];
        if (_customers.isNotEmpty) {
          Map<String, dynamic>? match;
          if (widget.initialCustomerId != null) {
            for (final c in _customers) {
              if (int.tryParse((c['id'] ?? '').toString()) == widget.initialCustomerId) {
                match = c;
                break;
              }
            }
          }
          _applyCustomer(match ?? _customers.first);
        }
      }
    });
  }

  void _applyCustomer(Map<String, dynamic> c) {
    _selectedCustomerId = int.tryParse((c['id'] ?? '').toString());
    _customerController.text = c['name']?.toString() ?? '';
    final rate = double.tryParse(
          (c['master_can_rate'] ?? c['can_rate'] ?? c['unit_price'] ?? 0).toString(),
        ) ??
        0.0;
    if (rate > 0) {
      _canRate = rate;
    } else if (_canRate <= 0) {
      _canRate = 35.0;
    }
  }

  Future<void> _captureGpsFix() async {
    try {
      if (widget.gpsFetcher != null) {
        final fix = await widget.gpsFetcher!.call();
        if (!mounted) return;
        setState(() {
          if (fix != null) {
            _currentLat = fix.lat;
            _currentLng = fix.lng;
            _isMockGps = fix.isMocked;
          }
        });
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      if (!mounted) return;
      setState(() {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _isMockGps = pos.isMocked;
      });
    } catch (_) {}
  }

  void _setQuantity(int qty) {
    final safe = qty.clamp(1, 1000);
    setState(() {
      _orderedCans = safe;
    });
  }

  double get _estimatedTotal => _orderedCans * (_canRate > 0 ? _canRate : 35.0);

  Future<void> _submitOrder() async {
    if (_orderedCans < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordered cans must be at least 1.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedCustomerId == null && _customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or enter a customer before creating order.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isMockGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mock/Spoofed GPS detected! Turn off fake GPS apps before booking an order.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);
    final idempotencyKey = const Uuid().v4();

    final payload = <String, dynamic>{
      if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
      if (_customerController.text.trim().isNotEmpty) 'customer_name': _customerController.text.trim(),
      if (_routeId != null) 'route_id': _routeId,
      'ordered_cans': _orderedCans,
      'can_size': _selectedCanSize,
      'can_rate': _canRate > 0 ? _canRate : 35.0,
      'payment_mode': _paymentMode,
      'start_immediately': _startImmediately,
      'delivery_date': _formatYmd(_deliveryDate),
      if (_scheduleFrequency != 'on_day') ...{
        'create_schedule': true,
        'schedule_frequency': _scheduleFrequency,
        if (_scheduleFrequency == 'every_n_days') 'interval_days': _intervalDays,
        if (_scheduleFrequency == 'weekly' && _selectedWeekdays.isNotEmpty)
          'days_of_week': (_selectedWeekdays.toList()..sort()),
        if (_preferredTimeSlot.trim().isNotEmpty) 'preferred_time_slot': _preferredTimeSlot.trim(),
      },
      if (_notesController.text.trim().isNotEmpty) 'order_notes': _notesController.text.trim(),
      'order_source': 'mobile_driver',
      'is_mock_gps': _isMockGps,
      if (_currentLat != null) 'latitude': _currentLat,
      if (_currentLng != null) 'longitude': _currentLng,
    };

    final result = await client.post<Map<String, dynamic>>(
      ApiEndpoints.waterCanOrders,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (raw) {
        if (raw is Map && raw['data'] is Map) {
          return Map<String, dynamic>.from(raw['data'] as Map);
        }
        return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      },
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      final orderData = result.dataOrNull ?? <String, dynamic>{};
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      await _showCreatedDialog(orderData, offlineQueued: false);
    } else if (result.failureOrNull?.statusCode == 422 || result.failureOrNull?.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Unable to create can order.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      final offlineRef = 'ORD-OFFLINE-${DateTime.now().millisecondsSinceEpoch}';
      final offlinePayload = {
        ...payload,
        'client_order_ref': offlineRef,
      };
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.waterCanOrders,
        method: 'POST',
        payload: offlinePayload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      final offlineOrder = {
        ...offlinePayload,
        'order_no': offlineRef,
        'customer_name': _customerController.text.trim().isNotEmpty
            ? _customerController.text.trim()
            : 'Customer',
        'master_can_rate': _canRate > 0 ? _canRate : 35.0,
        'status': _startImmediately ? 'in_transit' : 'ordered',
      };
      await _showCreatedDialog(offlineOrder, offlineQueued: true);
    }
  }

  Future<void> _showCreatedDialog(
    Map<String, dynamic> orderData, {
    required bool offlineQueued,
  }) async {
    final orderNo = orderData['order_no']?.toString() ?? 'ORD-NEW';
    final salesOrderNo = orderData['sales_order_no']?.toString().trim();
    final scheduleLabel = orderData['schedule_label']?.toString().trim();
    final customerName = orderData['customer_name']?.toString() ?? _customerController.text.trim();
    final qty = orderData['ordered_cans'] ?? _orderedCans;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          offlineQueued ? Icons.cloud_upload_rounded : Icons.notifications_active_rounded,
          color: offlineQueued ? AppColors.warning : AppColors.success,
          size: 46,
        ),
        title: Text(offlineQueued ? 'Sales Order Saved Offline' : 'Sales Order Created & Owner Notified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${salesOrderNo != null && salesOrderNo.isNotEmpty ? "Sales Order $salesOrderNo ($orderNo)" : "Order #$orderNo"} created for $qty × $_selectedCanSize to $customerName.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (scheduleLabel != null && scheduleLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.aquaPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  scheduleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.aquaPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              offlineQueued
                  ? 'Order will automatically sync and notify the owner as soon as network connectivity resumes. You can still deliver and close this order offline.'
                  : 'Super Admin and Vertical Incharge have received a real-time push alert. Next, move to the customer location and close the order on arrival.',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.pop(orderData);
            },
            child: const Text('Back to Queue'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                context.pushReplacement('/operations/can-sales', extra: orderData);
              }
            },
            icon: const Icon(Icons.local_shipping_rounded, size: 18),
            label: const Text('Arrive & Close Order'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: AppBar(
        backgroundColor: skin.canvas,
        foregroundColor: skin.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Water Can Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              'Owner Notified Before Delivery',
              style: TextStyle(fontSize: 11, color: skin.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                // Owner Alert Guarantee Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.aquaPrimary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.aquaPrimary.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.aquaPrimary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Step 1 of 2: Set customer & requested cans first. Owner & Incharge get instant notification before you move & close.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: skin.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Customer Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Customer / Shop',
                              style: AppTypography.section.copyWith(color: skin.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_vanRemainingCans > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: skin.surface2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$_vanRemainingCans Cans in Van',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: skin.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_customers.isNotEmpty) ...[
                        DropdownButtonFormField<int>(
                          value: _customers.any(
                                  (c) => int.tryParse((c['id'] ?? '').toString()) == _selectedCustomerId)
                              ? _selectedCustomerId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Route Customer',
                            prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                          ),
                          items: _customers
                              .map((c) {
                                final id = int.tryParse((c['id'] ?? '').toString());
                                if (id == null) return null;
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(
                                    '${c['name'] ?? 'Customer'} · ₹${(c['master_can_rate'] ?? 35).toString()}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .whereType<DropdownMenuItem<int>>()
                              .toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            for (final c in _customers) {
                              if (int.tryParse((c['id'] ?? '').toString()) == id) {
                                setState(() => _applyCustomer(c));
                                break;
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'Shop / Customer Name',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Ordered Cans Qty Stepper + Quick Chips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Units Asked by Customer',
                              style: AppTypography.section.copyWith(color: skin.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${(_canRate > 0 ? _canRate : 35).toStringAsFixed(0)} / unit',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.aquaPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WaterContainerSizeSelector(
                        selectedSize: _selectedCanSize,
                        onChanged: (size) => setState(() => _selectedCanSize = size),
                      ),
                      const SizedBox(height: 14),
                      ScrollableHeroCounter(
                        value: _orderedCans,
                        min: 1,
                        max: 1000,
                        unitLabel: 'Ordered $_selectedCanSize',
                        quickPresets: _quickQuantities,
                        onChanged: _setQuantity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Expected Payment Mode & Notes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Settlement & Notes',
                        style: AppTypography.section.copyWith(color: skin.ink),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Cash', 'UPI', 'Credit'].map((mode) {
                          final isSelected = _paymentMode == mode;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                selected: isSelected,
                                label: Center(
                                  child: Text(
                                    mode,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                onSelected: (_) => setState(() => _paymentMode = mode),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('can-rate-${_selectedCustomerId ?? 'custom'}'),
                              initialValue: (_canRate > 0 ? _canRate : 35.0).toStringAsFixed(0),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rate per Can (₹)',
                                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v.trim());
                                if (parsed != null && parsed > 0) {
                                  setState(() => _canRate = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _deliveryDate,
                                  firstDate: now.subtract(const Duration(days: 1)),
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null && mounted) {
                                  setState(() => _deliveryDate = picked);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(
                                _formatYmd(_deliveryDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Order Schedule Type (Regular vs On-Day)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: skin.muted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          ('on_day', 'On-Day (Today Only)'),
                          ('daily', 'Daily'),
                          ('every_n_days', 'Every N Days'),
                          ('weekly', 'Weekly'),
                          ('biweekly', 'Biweekly'),
                          ('monthly', 'Monthly'),
                        ].map((item) {
                          final selected = _scheduleFrequency == item.$1;
                          return ChoiceChip(
                            selected: selected,
                            selectedColor: AppColors.aquaPrimary.withValues(alpha: 0.16),
                            label: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.aquaPrimary : skin.ink,
                              ),
                            ),
                            onSelected: (_) => setState(() => _scheduleFrequency = item.$1),
                          );
                        }).toList(),
                      ),
                      if (_scheduleFrequency == 'every_n_days') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: skin.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: skin.hairline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Repeat every $_intervalDays days',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: skin.ink,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _intervalDays > 1
                                        ? () => setState(() => _intervalDays--)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Text(
                                    '$_intervalDays',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                  ),
                                  IconButton(
                                    onPressed: _intervalDays < 30
                                        ? () => setState(() => _intervalDays++)
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                children: [2, 3, 4, 5, 10]
                                    .map(
                                      (d) => ChoiceChip(
                                        label: Text('Every $d d', style: const TextStyle(fontSize: 11)),
                                        selected: _intervalDays == d,
                                        onSelected: (_) => setState(() => _intervalDays = d),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_scheduleFrequency == 'weekly') ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: const [
                            (1, 'Mon'),
                            (2, 'Tue'),
                            (3, 'Wed'),
                            (4, 'Thu'),
                            (5, 'Fri'),
                            (6, 'Sat'),
                            (7, 'Sun'),
                          ].map((day) {
                            final active = _selectedWeekdays.contains(day.$1);
                            return FilterChip(
                              label: Text(day.$2, style: const TextStyle(fontSize: 11)),
                              selected: active,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedWeekdays.add(day.$1);
                                  } else if (_selectedWeekdays.length > 1) {
                                    _selectedWeekdays.remove(day.$1);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (_scheduleFrequency != 'on_day') ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: const ['Morning (6-9 AM)', 'Midday (11-2 PM)', 'Evening (4-7 PM)']
                              .map((slot) => ChoiceChip(
                                    label: Text(slot, style: const TextStyle(fontSize: 11)),
                                    selected: _preferredTimeSlot == slot,
                                    onSelected: (v) => setState(
                                      () => _preferredTimeSlot = v ? slot : '',
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Order Notes (e.g. Call on arrival)',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Moving Immediately',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: skin.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Marks order In Transit right away and alerts the owner',
                                  style: TextStyle(fontSize: 11, color: skin.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: _startImmediately,
                            onChanged: (v) => setState(() => _startImmediately = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skin.surface,
          border: Border(top: BorderSide(color: skin.hairline)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_orderedCans Cans · Est. Value',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: skin.muted),
                    ),
                    AmountText(
                      amount: _estimatedTotal,
                      style: AppTypography.title.copyWith(color: AppColors.aquaPrimary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.aquaPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(156, 48),
                  shape: const StadiumBorder(),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text(
                  'Create Sales Order',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
