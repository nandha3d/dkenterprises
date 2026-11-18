import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_endpoints.dart';
import '../network/api_result.dart';
import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Strips trailing generic business words and caps length so map customer pins stay readable.
String shortenCustomerMapName(String rawName, {int maxLength = 11}) {
  final cleaned = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return 'Customer';

  const genericSuffixes = <String>{
    'hotel',
    'hotels',
    'mess',
    'bakeries',
    'bakery',
    'cafe',
    'residency',
    'restaurant',
    'restaurants',
    'canteen',
    'stores',
    'store',
    'supermarket',
    'mart',
    'enterprises',
    'enterprise',
    'company',
    'co',
    'traders',
    'trading',
    'agency',
    'agencies',
    'water',
    'waters',
    'supply',
    'supplies',
    'sump',
    'depot',
    'hospital',
    'hospitals',
    'foods',
    'food',
    'dairy',
    'pvt',
    'ltd',
  };

  final words = cleaned.split(' ');
  while (words.length > 1) {
    final tail = words.last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (genericSuffixes.contains(tail)) {
      final candidate = words.sublist(0, words.length - 1).join(' ').trim();
      if (candidate.length >= 3) {
        words.removeLast();
        continue;
      }
    }
    break;
  }

  final shortened = words.join(' ').trim();
  if (shortened.length <= maxLength) {
    return shortened;
  }
  return '${shortened.substring(0, maxLength - 1).trimRight()}…';
}

double _toDouble(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

int _toInt(dynamic raw) => int.tryParse(raw?.toString() ?? '') ?? (double.tryParse(raw?.toString() ?? '0')?.round() ?? 0);

String _customerStatusOf(Map<String, dynamic> c) {
  final explicit = (c['payment_status'] ?? '').toString().toLowerCase();
  if (explicit == 'overdue' || _toDouble(c['overdue_amount']) > 0.01) {
    return 'overdue';
  }
  if (explicit == 'due' || _toDouble(c['due_amount']) > 0.01) {
    return 'due';
  }
  return 'paid';
}

Color _customerStatusColor(String status) {
  return switch (status) {
    'overdue' => AppColors.danger,
    'due' => AppColors.warning,
    _ => AppColors.success,
  };
}

/// Compact map marker pin showing shortened customer name and Paid/Due badge.
class CompactCustomerMapPin extends StatelessWidget {
  final String name;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final bool isSelected;
  final NumberFormat compactFormatter;

  const CompactCustomerMapPin({
    super.key,
    required this.name,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.isSelected,
    required this.compactFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final pinColor = _customerStatusColor(status);
    final shortName = shortenCustomerMapName(name);
    final amountLabel = dueAmount > 0.01
        ? '${status == 'overdue' ? 'OD' : 'Due'} ${compactFormatter.format(dueAmount)}'
        : 'Pd ${compactFormatter.format(paidAmount)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? pinColor : skin.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: pinColor,
              width: isSelected ? 2.2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.28 : 0.18),
                blurRadius: isSelected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : pinColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : skin.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.96)
                      : pinColor,
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(11, 5),
          painter: _MapCalloutPointerPainter(color: pinColor),
        ),
      ],
    );
  }
}

/// Pop-over bubble rendered over a selected customer pin. Tapping the bubble opens full history.
class CustomerMapCalloutBubble extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onOpenFullDetails;
  final VoidCallback onClose;

  const CustomerMapCalloutBubble({
    super.key,
    required this.customer,
    required this.onOpenFullDetails,
    required this.onClose,
  });

  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final status = _customerStatusOf(customer);
    final statusColor = _customerStatusColor(status);
    final fullName = customer['name']?.toString() ?? 'Customer';
    final address = [
      customer['address']?.toString() ?? '',
      customer['city']?.toString() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');
    final totalSales = _toDouble(customer['total_sales']);
    final totalPaid = _toDouble(customer['total_paid']);
    final dueAmt = _toDouble(customer['due_amount']);
    final ordersCount = _toInt(customer['orders_count']);
    final lastDate = (customer['last_order_date'] ?? '').toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: skin.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenFullDetails,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 310),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor, width: 1.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                              ),
                            ),
                            if (address.isNotEmpty)
                              Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: skin.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status == 'overdue'
                              ? 'OVERDUE'
                              : (status == 'due' ? 'DUE' : 'PAID'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: skin.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: skin.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BubbleMetricCell(
                            label: 'Should Pay',
                            value: _inrWhole.format(dueAmt),
                            color: dueAmt > 0.01 ? statusColor : skin.muted,
                          ),
                        ),
                        Container(width: 1, height: 24, color: skin.hairline),
                        Expanded(
                          child: _BubbleMetricCell(
                            label: 'Paid',
                            value: _inrWhole.format(totalPaid),
                            color: AppColors.success,
                          ),
                        ),
                        Container(width: 1, height: 24, color: skin.hairline),
                        Expanded(
                          child: _BubbleMetricCell(
                            label: 'Bought',
                            value: _inrWhole.format(totalSales),
                            color: skin.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ordersCount > 0 || lastDate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (ordersCount > 0) '$ordersCount Orders',
                        if (lastDate.isNotEmpty) 'Last: $lastDate',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Tap Bubble for Full History & Payments',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(16, 8),
          painter: _MapCalloutPointerPainter(color: statusColor),
        ),
      ],
    );
  }
}

/// Pop-over bubble rendered over a selected driver/delivery boy pin. Tapping opens today's full work & timelines.
class DriverMapCalloutBubble extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isTanker;
  final VoidCallback onOpenFullDetails;
  final VoidCallback onClose;

  const DriverMapCalloutBubble({
    super.key,
    required this.vehicle,
    required this.isTanker,
    required this.onOpenFullDetails,
    required this.onClose,
  });

  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final driverName = (vehicle['driver_name'] ??
            vehicle['assigned_driver'] ??
            (isTanker ? 'Tanker Driver' : 'Delivery Boy'))
        .toString();
    final vehicleNo = (vehicle['vehicle_number'] ??
            vehicle['vehicle_no'] ??
            vehicle['tanker_number'] ??
            vehicle['route_name'] ??
            'Unit')
        .toString();
    final speedKmh = _toDouble(vehicle['current_speed'] ?? vehicle['speed_kmh']);
    final summary = vehicle['today_summary'] is Map
        ? Map<String, dynamic>.from(vehicle['today_summary'] as Map)
        : <String, dynamic>{};

    final stat1Label = isTanker ? 'Trips' : 'Loaded';
    final stat1Val = isTanker
        ? '${_toInt(summary['trips_completed'])}'
        : '${_toInt(summary['total_loaded_cans'] ?? vehicle['daily_avg_cans'])}';
    final stat2Label = isTanker ? 'KL Supplied' : 'Delivered';
    final stat2Val = isTanker
        ? '${_toDouble(summary['total_kl_delivered']).toStringAsFixed(1)} KL'
        : '${_toInt(summary['cans_delivered'])} Cans';
    final stat3Label = isTanker ? 'Billed' : 'Cash Col.';
    final stat3Val = isTanker
        ? _inrWhole.format(_toDouble(summary['total_billed']))
        : _inrWhole.format(_toDouble(summary['cash_collected']));

    const accent = AppColors.rippleSky;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: skin.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenFullDetails,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 310),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent, width: 1.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          isTanker
                              ? Icons.local_shipping_rounded
                              : Icons.fire_truck_rounded,
                          size: 16,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                              ),
                            ),
                            Text(
                              '${isTanker ? 'Tanker Driver' : 'Delivery Boy'} · $vehicleNo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${speedKmh.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: skin.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: skin.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BubbleMetricCell(
                            label: stat1Label,
                            value: stat1Val,
                            color: accent,
                          ),
                        ),
                        Container(width: 1, height: 24, color: skin.hairline),
                        Expanded(
                          child: _BubbleMetricCell(
                            label: stat2Label,
                            value: stat2Val,
                            color: skin.ink,
                          ),
                        ),
                        Container(width: 1, height: 24, color: skin.hairline),
                        Expanded(
                          child: _BubbleMetricCell(
                            label: stat3Label,
                            value: stat3Val,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 14,
                          color: accent,
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "Tap Bubble for Today's Work & Timeline",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const CustomPaint(
          size: Size(16, 8),
          painter: _MapCalloutPointerPainter(color: accent),
        ),
      ],
    );
  }
}

class _BubbleMetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BubbleMetricCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: skin.muted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MapCalloutPointerPainter extends CustomPainter {
  final Color color;
  const _MapCalloutPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MapCalloutPointerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Opens the full Driver & Delivery Boy details modal showing today's summary and chronological timelines.
Future<void> showDriverFullDetailsSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Map<String, dynamic> vehicle,
  required bool isTanker,
  VoidCallback? onCenterOnMap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DriverFullDetailsSheet(
      vehicle: vehicle,
      isTanker: isTanker,
      onCenterOnMap: onCenterOnMap,
    ),
  );
}

class DriverFullDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> vehicle;
  final bool isTanker;
  final VoidCallback? onCenterOnMap;

  const DriverFullDetailsSheet({
    super.key,
    required this.vehicle,
    required this.isTanker,
    this.onCenterOnMap,
  });

  @override
  ConsumerState<DriverFullDetailsSheet> createState() =>
      _DriverFullDetailsSheetState();
}

class _DriverFullDetailsSheetState
    extends ConsumerState<DriverFullDetailsSheet> {
  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _loading = false;
  String _timelineFilter = 'all';
  late Map<String, dynamic> _summary;
  late List<Map<String, dynamic>> _timeline;

  @override
  void initState() {
    super.initState();
    _summary = _extractOrSynthesizeSummary(widget.vehicle);
    _timeline = _extractOrSynthesizeTimeline(widget.vehicle);
    unawaited(_fetchLiveDriverTimeline());
  }

  Map<String, dynamic> _extractOrSynthesizeSummary(Map<String, dynamic> v) {
    if (v['today_summary'] is Map) {
      return Map<String, dynamic>.from(v['today_summary'] as Map);
    }
    if (widget.isTanker) {
      return <String, dynamic>{
        'activity_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'is_today': true,
        'trips_completed': _toInt(v['trips_today'] ?? 0),
        'open_trips_count': _toInt(v['open_trips_count'] ?? 0),
        'total_kl_delivered': _toDouble(v['total_kl_delivered'] ?? 0),
        'total_km_run': _toInt(v['total_km_run'] ?? 0),
        'motor_pumping_minutes': _toInt(v['motor_pumping_minutes'] ?? 0),
        'site_dwell_minutes': _toInt(v['site_dwell_minutes'] ?? 0),
        'total_billed': _toDouble(v['total_billed'] ?? 0),
        'total_paid': _toDouble(v['total_paid'] ?? 0),
        'diesel_expense': _toDouble(v['diesel_expense'] ?? 0),
      };
    }
    final baseline = _toInt(v['daily_avg_cans'] ?? 60);
    return <String, dynamic>{
      'activity_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'is_today': true,
      'morning_loaded_cans': baseline,
      'plant_refills_count': 0,
      'plant_refilled_cans': 0,
      'total_loaded_cans': baseline,
      'deliveries_completed': _toInt(v['deliveries_completed'] ?? 0),
      'open_orders_count': _toInt(v['open_orders_count'] ?? 0),
      'cans_delivered': _toInt(v['cans_delivered'] ?? 0),
      'empty_cans_returned': _toInt(v['empty_cans_returned'] ?? 0),
      'remaining_cans': baseline,
      'total_billed': _toDouble(v['total_billed'] ?? 0),
      'cash_collected': _toDouble(v['cash_collected'] ?? 0),
      'digital_collected': _toDouble(v['digital_collected'] ?? 0),
      'credit_given': _toDouble(v['credit_given'] ?? 0),
      'cash_surrendered': _toDouble(v['cash_surrendered'] ?? 0),
      'cash_in_hand': _toDouble(v['cash_in_hand'] ?? 0),
    };
  }

  List<Map<String, dynamic>> _extractOrSynthesizeTimeline(
    Map<String, dynamic> v,
  ) {
    final raw = v['today_timeline'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final speed = _toDouble(v['current_speed'] ?? v['speed_kmh']);
    final reg = (v['vehicle_number'] ??
            v['vehicle_no'] ??
            v['tanker_number'] ??
            v['route_name'] ??
            'Unit')
        .toString();
    final ping = (v['last_ping_at'] ?? '').toString();
    final baseline = _toInt(v['daily_avg_cans'] ?? 60);
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'time': '07:00 AM',
        'type': 'shift_start',
        'title': widget.isTanker
            ? 'Tanker Duty & Valve Seal Check'
            : 'Morning Van Dispatch & Stock Load',
        'subtitle': widget.isTanker
            ? '$reg ready for borewell dispatch'
            : '$reg · Baseline $baseline Cans loaded',
        'location': widget.isTanker ? 'Mother Plant Depot' : 'DK Waters RO Plant',
        'badge': widget.isTanker ? 'READY' : '$baseline CANS',
        'status': 'completed',
      },
      <String, dynamic>{
        'time': ping.isNotEmpty ? 'LIVE' : 'NOW',
        'type': 'gps',
        'title': 'Live GPS Telemetry · ${speed.toStringAsFixed(0)} km/h',
        'subtitle': ping.isNotEmpty
            ? 'Last ping: $ping'
            : '$reg · Active GPS tracking locked',
        'location': widget.isTanker
            ? (v['model_type']?.toString() ?? 'Bulk Water Route')
            : (v['route_name']?.toString() ?? 'Active Delivery Beat'),
        'badge': speed > 2 ? 'MOVING' : 'STOPPED',
        'status': 'live',
      },
    ];
  }

  Future<void> _fetchLiveDriverTimeline() async {
    final id = _toInt(widget.vehicle['id']);
    if (id <= 0) return;

    if (mounted) setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            ApiEndpoints.fleetDriverActivity,
            queryParameters: <String, dynamic>{
              'vehicle_type': widget.isTanker ? 'tanker' : 'route',
              'vehicle_id': id,
            },
            fromJson: (raw) {
              if (raw is Map && raw['data'] is Map) {
                return Map<String, dynamic>.from(raw['data'] as Map);
              }
              if (raw is Map) {
                return Map<String, dynamic>.from(raw);
              }
              return <String, dynamic>{};
            },
          );
      if (!mounted) return;
      if (res is ApiSuccess<Map<String, dynamic>>) {
        final data = res.data;
        final remoteSummary = data['today_summary'];
        final remoteTimeline = data['today_timeline'];
        setState(() {
          if (remoteSummary is Map && remoteSummary.isNotEmpty) {
            _summary = Map<String, dynamic>.from(remoteSummary);
          }
          if (remoteTimeline is List && remoteTimeline.isNotEmpty) {
            _timeline = remoteTimeline
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTimeline {
    if (_timelineFilter == 'all') return _timeline;
    return _timeline.where((e) {
      final t = (e['type'] ?? '').toString().toLowerCase();
      return switch (_timelineFilter) {
        'deliveries' => t == 'delivery' || t == 'order',
        'loading' => t == 'loading' || t == 'shift_start',
        'cash' => t == 'cash_surrender' || t == 'pumping',
        'gps' => t == 'gps',
        _ => true,
      };
    }).toList();
  }

  Future<void> _callPhone(String phone) async {
    try {
      await launchUrl(
        Uri.parse('tel:$phone'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to place call on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final driverName = (widget.vehicle['driver_name'] ??
            widget.vehicle['assigned_driver'] ??
            (widget.isTanker ? 'Tanker Driver' : 'Delivery Boy'))
        .toString();
    final vehicleNo = (widget.vehicle['vehicle_number'] ??
            widget.vehicle['vehicle_no'] ??
            widget.vehicle['tanker_number'] ??
            widget.vehicle['route_name'] ??
            'Unit')
        .toString();
    final routeOrModel = widget.isTanker
        ? (widget.vehicle['model_type']?.toString() ?? 'Bulk Water Tanker')
        : (widget.vehicle['route_name']?.toString() ?? 'Can Delivery Beat');
    final phone =
        (widget.vehicle['driver_phone'] ?? widget.vehicle['phone'] ?? '')
            .toString();
    final speedKmh =
        _toDouble(widget.vehicle['current_speed'] ?? widget.vehicle['speed_kmh']);
    final isToday = _summary['is_today'] != false;
    final activityDate = (_summary['activity_date'] ?? 'Today').toString();

    final summaryCards = widget.isTanker
        ? <({String label, String value, String sub, Color color, IconData icon})>[
            (
              label: 'Trips Done',
              value: '${_toInt(_summary['trips_completed'])}',
              sub: '${_toInt(_summary['open_trips_count'])} Open Queue',
              color: AppColors.rippleSky,
              icon: Icons.local_shipping_rounded,
            ),
            (
              label: 'Water Supplied',
              value:
                  '${_toDouble(_summary['total_kl_delivered']).toStringAsFixed(1)} KL',
              sub: '${_toInt(_summary['total_km_run'])} km run',
              color: AppColors.aquaPrimary,
              icon: Icons.water_drop_rounded,
            ),
            (
              label: 'Motor & Dwell',
              value: '${_toInt(_summary['motor_pumping_minutes'])}m Motor',
              sub: '${_toInt(_summary['site_dwell_minutes'])}m Site Dwell',
              color: AppColors.warning,
              icon: Icons.timer_rounded,
            ),
            (
              label: 'Billed & Spend',
              value: _inrWhole.format(_toDouble(_summary['total_billed'])),
              sub:
                  'Diesel ${_inrWhole.format(_toDouble(_summary['diesel_expense']))}',
              color: AppColors.success,
              icon: Icons.payments_rounded,
            ),
          ]
        : <({String label, String value, String sub, Color color, IconData icon})>[
            (
              label: 'Cans Loaded',
              value: '${_toInt(_summary['total_loaded_cans'])}',
              sub:
                  '${_toInt(_summary['remaining_cans'])} Left · ${_toInt(_summary['plant_refills_count'])} Refills',
              color: AppColors.rippleSky,
              icon: Icons.inventory_2_rounded,
            ),
            (
              label: 'Delivered Today',
              value: '${_toInt(_summary['cans_delivered'])} Cans',
              sub:
                  '${_toInt(_summary['deliveries_completed'])} Stops · ${_toInt(_summary['open_orders_count'])} Open',
              color: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
            (
              label: 'Empty Returned',
              value: '${_toInt(_summary['empty_cans_returned'])} Jars',
              sub:
                  'Billed ${_inrWhole.format(_toDouble(_summary['total_billed']))}',
              color: AppColors.warning,
              icon: Icons.recycling_rounded,
            ),
            (
              label: 'Cash & Surrender',
              value: _inrWhole.format(_toDouble(_summary['cash_collected'])),
              sub:
                  'In Hand ${_inrWhole.format(_toDouble(_summary['cash_in_hand']))}',
              color: skin.primary,
              icon: Icons.account_balance_wallet_rounded,
            ),
          ];

    final events = _filteredTimeline;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: skin.hairline)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: skin.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.rippleSky.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.isTanker
                                ? Icons.local_shipping_rounded
                                : Icons.fire_truck_rounded,
                            color: AppColors.rippleSky,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: AppTypography.section
                                    .copyWith(color: skin.ink),
                              ),
                              Text(
                                '${widget.isTanker ? 'Bulk Tanker Driver' : 'Can Delivery Boy'} · $vehicleNo',
                                style: AppTypography.caption
                                    .copyWith(color: skin.muted),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _SheetBadgeTag(
                                    label:
                                        '${speedKmh.toStringAsFixed(0)} km/h',
                                    color: AppColors.success,
                                  ),
                                  _SheetBadgeTag(
                                    label: isToday
                                        ? "Today's Work"
                                        : 'Shift: $activityDate',
                                    color: AppColors.rippleSky,
                                  ),
                                  _SheetBadgeTag(
                                    label: routeOrModel,
                                    color: skin.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_loading)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.rippleSky,
                  backgroundColor: skin.hairline,
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    // Action buttons
                    Row(
                      children: [
                        if (phone.isNotEmpty) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _callPhone(phone),
                              icon: const Icon(Icons.call_rounded, size: 17),
                              label: const Text('Call Driver'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (widget.onCenterOnMap != null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                widget.onCenterOnMap!();
                              },
                              icon: const Icon(
                                Icons.my_location_rounded,
                                size: 17,
                              ),
                              label: const Text('Center on Map'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isToday
                          ? "Today's Work Summary"
                          : 'Shift Summary ($activityDate)',
                      style: AppTypography.bodyMedium.copyWith(color: skin.ink),
                    ),
                    const SizedBox(height: 8),
                    // 2x2 Summary Bento
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMiniTile(
                                data: summaryCards[0],
                                skin: skin,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryMiniTile(
                                data: summaryCards[1],
                                skin: skin,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMiniTile(
                                data: summaryCards[2],
                                skin: skin,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryMiniTile(
                                data: summaryCards[3],
                                skin: skin,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Today's Activity Timeline (${events.length})",
                            style: AppTypography.bodyMedium
                                .copyWith(color: skin.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in [
                            (key: 'all', label: 'All Events'),
                            (
                              key: 'deliveries',
                              label: widget.isTanker ? 'Trips' : 'Deliveries'
                            ),
                            (key: 'loading', label: 'Loading & Dispatch'),
                            (
                              key: 'cash',
                              label: widget.isTanker ? 'Motor / Decant' : 'Cash'
                            ),
                            (key: 'gps', label: 'GPS Live'),
                          ]) ...[
                            ChoiceChip(
                              selected: _timelineFilter == f.key,
                              label: Text(
                                f.label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _timelineFilter = f.key),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: skin.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: skin.hairline),
                        ),
                        child: Text(
                          'No events matched this filter yet.',
                          style: AppTypography.caption
                              .copyWith(color: skin.muted),
                        ),
                      )
                    else
                      for (int i = 0; i < events.length; i++)
                        _TimelineRowCard(
                          event: events[i],
                          isLast: i == events.length - 1,
                          skin: skin,
                          inrWhole: _inrWhole,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryMiniTile extends StatelessWidget {
  final ({String label, String value, String sub, Color color, IconData icon})
      data;
  final RippleSkin skin;

  const _SummaryMiniTile({required this.data, required this.skin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: skin.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 15, color: data.color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: skin.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: data.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: skin.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRowCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  final RippleSkin skin;
  final NumberFormat inrWhole;

  const _TimelineRowCard({
    required this.event,
    required this.isLast,
    required this.skin,
    required this.inrWhole,
  });

  @override
  Widget build(BuildContext context) {
    final type = (event['type'] ?? '').toString().toLowerCase();
    final (IconData icon, Color color) = switch (type) {
      'delivery' => (Icons.check_circle_rounded, AppColors.success),
      'loading' => (Icons.local_drink_rounded, AppColors.rippleSky),
      'pumping' => (Icons.water_rounded, AppColors.aquaPrimary),
      'cash_surrender' => (Icons.payments_rounded, AppColors.warning),
      'order' => (Icons.pending_actions_rounded, AppColors.warning),
      'gps' => (Icons.gps_fixed_rounded, AppColors.rippleSky),
      _ => (Icons.play_circle_fill_rounded, skin.primary),
    };
    final amount = event['amount'] != null ? _toDouble(event['amount']) : null;
    final badge = (event['badge'] ?? '').toString();
    final location = (event['location'] ?? '').toString();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                (event['time'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: skin.muted,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: skin.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: skin.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: skin.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (event['title'] ?? 'Activity').toString(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: skin.ink,
                          ),
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _SheetBadgeTag(label: badge, color: color),
                      ],
                    ],
                  ),
                  if ((event['subtitle'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event['subtitle'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: skin.muted,
                      ),
                    ),
                  ],
                  if (location.isNotEmpty || (amount != null && amount > 0)) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (location.isNotEmpty) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: skin.muted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (amount != null && amount > 0)
                          Text(
                            inrWhole.format(amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens interactive Customer 360° History Sheet (how much to pay, when/where/how much bought, payment details).
Future<void> showCustomerFullDetailsSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Map<String, dynamic> customer,
  required bool isPackagedWater,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CustomerFullDetailsSheet(
      customer: customer,
      isPackagedWater: isPackagedWater,
    ),
  );
}

class CustomerFullDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;
  final bool isPackagedWater;

  const CustomerFullDetailsSheet({
    super.key,
    required this.customer,
    required this.isPackagedWater,
  });

  @override
  ConsumerState<CustomerFullDetailsSheet> createState() =>
      _CustomerFullDetailsSheetState();
}

class _CustomerFullDetailsSheetState
    extends ConsumerState<CustomerFullDetailsSheet> {
  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _loading = false;
  int _activeTab = 0; // 0: Purchases, 1: Payment Details, 2: Full Timeline
  String _purchaseFilter = 'all'; // all | due | paid
  final Set<int> _expandedPurchaseIndices = <int>{};

  late Map<String, dynamic> _customer;
  late List<Map<String, dynamic>> _purchases;
  late List<Map<String, dynamic>> _payments;
  late List<Map<String, dynamic>> _timeline;

  @override
  void initState() {
    super.initState();
    _customer = Map<String, dynamic>.from(widget.customer);
    _purchases = _initialPurchases(_customer);
    _payments = _initialPayments(_customer, _purchases);
    _timeline = _buildFallbackTimeline(_purchases, _payments);
    unawaited(_fetchFullCustomerHistory());
  }

  List<Map<String, dynamic>> _initialPurchases(Map<String, dynamic> c) {
    final raw = c['recent_purchases'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final totalSales = _toDouble(c['total_sales']);
    final totalPaid = _toDouble(c['total_paid']);
    final dueAmt = _toDouble(c['due_amount']);
    if (totalSales <= 0.01) return <Map<String, dynamic>>[];

    final addr = [
      c['address']?.toString() ?? '',
      c['city']?.toString() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');
    final lastDate =
        (c['last_order_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toString();

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'type': widget.isPackagedWater ? 'water_can' : 'water_tanker',
        'reference_no': 'LEDGER-${c['id'] ?? 1}',
        'date': lastDate,
        'time': 'Account Ledger',
        'item_summary': widget.isPackagedWater
            ? 'Packaged Water Supply Summary'
            : 'Bulk Water Tanker Summary',
        'qty': _toInt(c['total_cans_bought'] ?? 1),
        'unit': widget.isPackagedWater ? 'Cans' : 'Trips',
        'unit_rate': 0.0,
        'empty_cans_returned': 0,
        'total_amount': totalSales,
        'paid_amount': totalPaid,
        'due_amount': dueAmt,
        'payment_mode': dueAmt > 0.01 ? 'Credit / Split' : 'Cash / UPI',
        'payment_status': _customerStatusOf(c),
        'where_address': addr.isNotEmpty ? addr : 'Customer Site',
        'driver_name': 'Assigned Route',
        'vehicle_number': '',
        'order_origin': 'on_day',
      },
    ];
  }

  List<Map<String, dynamic>> _initialPayments(
    Map<String, dynamic> c,
    List<Map<String, dynamic>> purchases,
  ) {
    final raw = c['recent_payments'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final totalPaid = _toDouble(c['total_paid']);
    if (totalPaid <= 0.01) return <Map<String, dynamic>>[];
    final lastDate =
        (c['last_order_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toString();
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'payment_reference': 'RCPT-${c['id'] ?? 1}',
        'invoice_ref': purchases.isNotEmpty
            ? (purchases.first['reference_no'] ?? '')
            : '',
        'amount': totalPaid,
        'payment_mode': 'Cash / UPI',
        'date': lastDate,
        'time': 'Recorded',
        'note': 'Total settled payments on account',
      },
    ];
  }

  List<Map<String, dynamic>> _buildFallbackTimeline(
    List<Map<String, dynamic>> purchases,
    List<Map<String, dynamic>> payments,
  ) {
    final events = <Map<String, dynamic>>[];
    var running = 0.0;
    for (final p in purchases.reversed) {
      final tot = _toDouble(p['total_amount']);
      running += tot;
      events.add(<String, dynamic>{
        'date': p['date'],
        'time': p['time'],
        'type': 'purchase',
        'title': p['item_summary'],
        'subtitle': '${p['where_address']} · ${p['driver_name']}',
        'reference': p['reference_no'],
        'debit': tot,
        'credit': 0.0,
        'running_balance': running,
      });
    }
    for (final pay in payments.reversed) {
      final amt = _toDouble(pay['amount']);
      running -= amt;
      events.add(<String, dynamic>{
        'date': pay['date'],
        'time': pay['time'],
        'type': 'payment',
        'title': 'Payment Received (${pay['payment_mode']})',
        'subtitle': pay['note'] ?? '',
        'reference': pay['payment_reference'],
        'debit': 0.0,
        'credit': amt,
        'running_balance': running,
      });
    }
    return events.reversed.toList();
  }

  Future<void> _fetchFullCustomerHistory() async {
    final cid = _toInt(_customer['id']);
    if (cid <= 0) return;

    if (mounted) setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            ApiEndpoints.customerHistory(cid),
            fromJson: (raw) {
              if (raw is Map && raw['data'] is Map) {
                return Map<String, dynamic>.from(raw['data'] as Map);
              }
              if (raw is Map) {
                return Map<String, dynamic>.from(raw);
              }
              return <String, dynamic>{};
            },
          );
      if (!mounted) return;
      if (res is ApiSuccess<Map<String, dynamic>>) {
        final data = res.data;
        final remoteCust = data['customer'];
        final remotePurchases = data['purchases'];
        final remotePayments = data['payments'];
        final remoteTimeline = data['timeline'];
        setState(() {
          if (remoteCust is Map && remoteCust.isNotEmpty) {
            _customer = <String, dynamic>{
              ..._customer,
              ...Map<String, dynamic>.from(remoteCust),
            };
          }
          if (remotePurchases is List && remotePurchases.isNotEmpty) {
            _purchases = remotePurchases
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          if (remotePayments is List && remotePayments.isNotEmpty) {
            _payments = remotePayments
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          if (remoteTimeline is List && remoteTimeline.isNotEmpty) {
            _timeline = remoteTimeline
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPurchases {
    return _purchases.where((p) {
      final due = _toDouble(p['due_amount']);
      return switch (_purchaseFilter) {
        'due' => due > 0.01,
        'paid' => due <= 0.01,
        _ => true,
      };
    }).toList();
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to launch external app on this device.'),
        ),
      );
    }
  }

  void _safePush(BuildContext ctx, String route) {
    Navigator.of(ctx).pop();
    try {
      context.push(route);
    } catch (_) {}
  }

  Future<void> _openVerifyGpayProofDialog(Map<String, dynamic> purchase) async {
    final entityId = _toInt(purchase['id']);
    if (entityId <= 0) return;
    final rawType = (purchase['type'] ?? '').toString().toLowerCase();
    final entityType = rawType.contains('can') ? 'can_delivery' : 'tanker_trip';
    final totalAmt = _toDouble(purchase['total_amount']);
    final currentPaid = _toDouble(purchase['paid_amount']);
    final defaultAmt = currentPaid > 0.01 ? currentPaid : totalAmt;

    final amountCtrl = TextEditingController(text: defaultAmt.toStringAsFixed(0));
    final refCtrl = TextEditingController(text: (purchase['payment_ref'] ?? '').toString());
    final pathCtrl = TextEditingController();
    var selectedStatus = 'confirmed';
    var selectedAccount = 'GPAY - KAVIN AXIS';
    String? base64Proof;
    Uint8List? previewBytes;
    String? fileError;
    var isSaving = false;

    const accounts = ['GPAY - KAVIN AXIS', 'KAVIN KVB', 'KAVIN CANARA', 'SASI'];

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> loadProofPath(String rawPath) async {
            final clean = rawPath.trim().replaceAll('"', '');
            if (clean.isEmpty) {
              setDialogState(() {
                previewBytes = null;
                base64Proof = null;
                fileError = null;
              });
              return;
            }
            if (kIsWeb) {
              setDialogState(() => fileError = 'Local path upload unavailable on Web; enter UPI Ref #.');
              return;
            }
            try {
              final f = File(clean);
              if (!await f.exists()) {
                setDialogState(() {
                  previewBytes = null;
                  base64Proof = null;
                  fileError = 'File not found at that path.';
                });
                return;
              }
              final bytes = await f.readAsBytes();
              setDialogState(() {
                previewBytes = bytes;
                base64Proof = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                fileError = null;
              });
            } catch (e) {
              setDialogState(() => fileError = 'Unable to read image: $e');
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: AppColors.aquaPrimary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verify GPay Payment Proof',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${purchase['reference_no'] ?? '#$entityId'} · ${purchase['item_summary'] ?? 'Water Supply'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        selected: selectedStatus == 'confirmed',
                        label: const Text('Confirmed Received', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onSelected: (_) => setDialogState(() => selectedStatus = 'confirmed'),
                      ),
                      ChoiceChip(
                        selected: selectedStatus == 'pending_verification',
                        label: const Text('Keep Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onSelected: (_) => setDialogState(() => selectedStatus = 'pending_verification'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: accounts.map((acc) {
                      return ChoiceChip(
                        selected: selectedAccount == acc,
                        label: Text(acc, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                        onSelected: (_) => setDialogState(() => selectedAccount = acc),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: refCtrl,
                    decoration: InputDecoration(
                      labelText: 'UPI Transaction Ref / Note',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        onPressed: () async {
                          final clip = await Clipboard.getData(Clipboard.kTextPlain);
                          final text = clip?.text?.trim() ?? '';
                          if (text.isNotEmpty) refCtrl.text = text;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pathCtrl,
                    decoration: InputDecoration(
                      labelText: 'Screenshot Path (Optional)',
                      border: const OutlineInputBorder(),
                      errorText: fileError,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        onPressed: () => loadProofPath(pathCtrl.text),
                      ),
                    ),
                  ),
                  if (previewBytes != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        previewBytes!,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final paidVal = double.tryParse(amountCtrl.text.trim()) ?? defaultAmt;
                        final res = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
                          ApiEndpoints.waterVerifyPaymentProof,
                          data: {
                            'entity_type': entityType,
                            'entity_id': entityId,
                            'status': selectedStatus,
                            'paid_amount': paidVal,
                            'payment_account': selectedAccount,
                            if (refCtrl.text.trim().isNotEmpty) 'payment_ref': refCtrl.text.trim(),
                            if (base64Proof != null) 'payment_proof_base64': base64Proof,
                          },
                          fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
                        );
                        if (!dialogCtx.mounted) return;
                        setDialogState(() => isSaving = false);
                        if (res.isSuccess) {
                          Navigator.of(dialogCtx).pop();
                          ref.read(dashboardRefreshSignalProvider.notifier).state++;
                          unawaited(_fetchFullCustomerHistory());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('GPay payment proof verified & synced!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(
                              content: Text(res.failureOrNull?.message ?? 'Unable to verify payment proof.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_rounded, size: 16),
                label: const Text('Verify & Save'),
              ),
            ],
          );
        },
      ),
    );

    amountCtrl.dispose();
    refCtrl.dispose();
    pathCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final status = _customerStatusOf(_customer);
    final statusColor = _customerStatusColor(status);

    final totalSales = _toDouble(_customer['total_sales']);
    final totalPaid = _toDouble(_customer['total_paid']);
    final dueAmt = _toDouble(_customer['due_amount']);
    final overdueAmt = _toDouble(_customer['overdue_amount']);
    final cansHeld = _toInt(_customer['cans_held']);
    final depositHeld = _toDouble(_customer['deposit_held']);
    final cashPaid = _toDouble(_customer['cash_paid_total']);
    final digitalPaid = _toDouble(_customer['digital_paid_total']);
    final paidRatio =
        totalSales > 0.01 ? (totalPaid / totalSales).clamp(0.0, 1.0) : 1.0;

    final phone =
        (_customer['phone_number'] ?? _customer['phone'] ?? '').toString();
    final gstin = (_customer['tax_no'] ?? '').toString();
    final lat = double.tryParse(_customer['latitude']?.toString() ?? '');
    final lng = double.tryParse(_customer['longitude']?.toString() ?? '');
    final hasGps =
        lat != null && lng != null && (lat.abs() > 0.0001 || lng.abs() > 0.0001);
    final cid = _toInt(_customer['id']);
    final address = [
      _customer['address']?.toString() ?? '',
      _customer['city']?.toString() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');

    final visiblePurchases = _filteredPurchases;

    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: skin.hairline)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: skin.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customer['name']?.toString() ?? 'Customer',
                                style: AppTypography.section
                                    .copyWith(color: skin.ink),
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style: AppTypography.caption
                                      .copyWith(color: skin.muted),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _SheetBadgeTag(
                                    label: status == 'overdue'
                                        ? 'OVERDUE'
                                        : (status == 'due'
                                            ? 'PAYMENT DUE'
                                            : 'SETTLED'),
                                    color: statusColor,
                                  ),
                                  if (gstin.isNotEmpty)
                                    _SheetBadgeTag(
                                      label: 'GSTIN: $gstin',
                                      color: skin.primary,
                                    ),
                                  _SheetBadgeTag(
                                    label:
                                        '${_customer['geofence_radius'] ?? 150}m Fence',
                                    color: skin.muted,
                                  ),
                                  if (cid > 0)
                                    _SheetBadgeTag(
                                      label:
                                          'QR ${_customer['shop_qr_code'] ?? 'DKW-SHOP-$cid'}',
                                      color: skin.muted,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_loading)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: statusColor,
                  backgroundColor: skin.hairline,
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    // 1. Payment Obligation ("How Much He Should Pay") Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: skin.canvas,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dueAmt > 0.01
                              ? statusColor.withValues(alpha: 0.45)
                              : skin.hairline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dueAmt > 0.01
                                      ? 'Should Pay Now: ${_inrWhole.format(dueAmt)}'
                                      : 'Account Fully Settled',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: dueAmt > 0.01
                                        ? statusColor
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                              Text(
                                '${(paidRatio * 100).round()}% Paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: skin.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: paidRatio,
                              minHeight: 7,
                              backgroundColor:
                                  statusColor.withValues(alpha: 0.16),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                dueAmt > 0.01
                                    ? statusColor
                                    : AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _CustomerLedgerMetric(
                                  label: 'Total Billed',
                                  value: _inrWhole.format(totalSales),
                                  color: skin.ink,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: skin.hairline,
                              ),
                              Expanded(
                                child: _CustomerLedgerMetric(
                                  label: 'Paid Amount',
                                  value: _inrWhole.format(totalPaid),
                                  color: AppColors.success,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: skin.hairline,
                              ),
                              Expanded(
                                child: _CustomerLedgerMetric(
                                  label: 'Due Amount',
                                  value: _inrWhole.format(dueAmt),
                                  color: dueAmt > 0.01
                                      ? statusColor
                                      : skin.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (overdueAmt > 0.01)
                                _SheetBadgeTag(
                                  label:
                                      'Overdue: ${_inrWhole.format(overdueAmt)}',
                                  color: AppColors.danger,
                                ),
                              if (cashPaid > 0.01)
                                _SheetBadgeTag(
                                  label: 'Cash: ${_inrWhole.format(cashPaid)}',
                                  color: AppColors.success,
                                ),
                              if (digitalPaid > 0.01)
                                _SheetBadgeTag(
                                  label:
                                      'UPI/Bank: ${_inrWhole.format(digitalPaid)}',
                                  color: AppColors.rippleSky,
                                ),
                              if (cansHeld > 0 || depositHeld > 0)
                                _SheetBadgeTag(
                                  label:
                                      '$cansHeld Jars Held · Dep ${_inrWhole.format(depositHeld)}',
                                  color: skin.primary,
                                ),
                              _SheetBadgeTag(
                                label: '${_purchases.length} Purchases',
                                color: skin.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (phone.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _launchExternal(Uri.parse('tel:$phone')),
                            icon: const Icon(Icons.call_rounded, size: 17),
                            label: const Text('Call'),
                          ),
                        if (hasGps)
                          OutlinedButton.icon(
                            onPressed: () => _launchExternal(
                              Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                              ),
                            ),
                            icon:
                                const Icon(Icons.directions_rounded, size: 17),
                            label: const Text('Directions'),
                          ),
                        if (dueAmt > 0.01)
                          FilledButton.icon(
                            onPressed: () =>
                                _safePush(ctx, '/accounting/collect'),
                            style: FilledButton.styleFrom(
                              backgroundColor: statusColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.payments_rounded, size: 17),
                            label: const Text('Collect Payment'),
                          ),
                        FilledButton.icon(
                          onPressed: () => _safePush(
                            ctx,
                            widget.isPackagedWater
                                ? '/operations/can-sales'
                                : '/operations/tanker-trip',
                          ),
                          icon: Icon(
                            widget.isPackagedWater
                                ? Icons.water_drop_rounded
                                : Icons.local_shipping_rounded,
                            size: 17,
                          ),
                          label: Text(
                            widget.isPackagedWater
                                ? 'Can Order'
                                : 'Tanker Trip',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Interactive 3-Tab History Explorer
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: skin.surface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          for (final tab in [
                            (idx: 0, label: 'Purchases (${_purchases.length})'),
                            (idx: 1, label: 'Payments (${_payments.length})'),
                            (idx: 2, label: 'Timeline (${_timeline.length})'),
                          ])
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _activeTab = tab.idx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _activeTab == tab.idx
                                        ? skin.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _activeTab == tab.idx
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.08),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    tab.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _activeTab == tab.idx
                                          ? skin.primary
                                          : skin.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_activeTab == 0) ...[
                      Row(
                        children: [
                          for (final f in [
                            (key: 'all', label: 'All (${_purchases.length})'),
                            (
                              key: 'due',
                              label:
                                  'Due (${_purchases.where((p) => _toDouble(p['due_amount']) > 0.01).length})'
                            ),
                            (
                              key: 'paid',
                              label:
                                  'Paid (${_purchases.where((p) => _toDouble(p['due_amount']) <= 0.01).length})'
                            ),
                          ]) ...[
                            ChoiceChip(
                              selected: _purchaseFilter == f.key,
                              label: Text(
                                f.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _purchaseFilter = f.key),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (visiblePurchases.isEmpty)
                        _EmptyHistoryBox(
                          skin: skin,
                          message: 'No purchase records under this filter.',
                        )
                      else
                        for (int i = 0; i < visiblePurchases.length; i++)
                          _CustomerPurchaseCard(
                            purchase: visiblePurchases[i],
                            expanded: _expandedPurchaseIndices.contains(i),
                            onToggleExpand: () {
                              setState(() {
                                if (_expandedPurchaseIndices.contains(i)) {
                                  _expandedPurchaseIndices.remove(i);
                                } else {
                                  _expandedPurchaseIndices.add(i);
                                }
                              });
                            },
                            onVerifyGpayProof: () =>
                                _openVerifyGpayProofDialog(visiblePurchases[i]),
                            skin: skin,
                            inrWhole: _inrWhole,
                          ),
                    ] else if (_activeTab == 1) ...[
                      if (_payments.isEmpty)
                        _EmptyHistoryBox(
                          skin: skin,
                          message: 'No payment receipts recorded yet.',
                        )
                      else
                        for (final pay in _payments)
                          _CustomerPaymentCard(
                            payment: pay,
                            skin: skin,
                            inrWhole: _inrWhole,
                          ),
                    ] else ...[
                      if (_timeline.isEmpty)
                        _EmptyHistoryBox(
                          skin: skin,
                          message: 'No ledger timeline events yet.',
                        )
                      else
                        for (int i = 0; i < _timeline.length; i++)
                          _CustomerLedgerTimelineRow(
                            event: _timeline[i],
                            isLast: i == _timeline.length - 1,
                            skin: skin,
                            inrWhole: _inrWhole,
                          ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerPurchaseCard extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onVerifyGpayProof;
  final RippleSkin skin;
  final NumberFormat inrWhole;

  const _CustomerPurchaseCard({
    required this.purchase,
    required this.expanded,
    required this.onToggleExpand,
    this.onVerifyGpayProof,
    required this.skin,
    required this.inrWhole,
  });

  @override
  Widget build(BuildContext context) {
    final tot = _toDouble(purchase['total_amount']);
    final paid = _toDouble(purchase['paid_amount']);
    final due = _toDouble(purchase['due_amount']);
    final pStatus = (purchase['payment_status'] ?? 'paid').toString();
    final isGpayPending =
        (purchase['payment_verification_status'] ?? '').toString().toLowerCase() ==
            'pending_verification';
    final color = pStatus == 'overdue'
        ? AppColors.danger
        : (due > 0.01 ? AppColors.warning : AppColors.success);
    final refNo = (purchase['reference_no'] ?? '').toString();
    final dateStr = (purchase['date'] ?? '').toString();
    final timeStr = (purchase['time'] ?? '').toString();
    final whereAddr = (purchase['where_address'] ?? 'Customer Site').toString();
    final driver = (purchase['driver_name'] ?? '').toString();
    final vehicle = (purchase['vehicle_number'] ?? '').toString();
    final empties = _toInt(purchase['empty_cans_returned']);
    final mode = (purchase['payment_mode'] ?? 'Cash').toString();
    final saleNo = (purchase['sale_no'] ?? '').toString();
    final soNo = (purchase['sales_order_no'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: skin.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGpayPending
              ? AppColors.warning.withValues(alpha: 0.55)
              : skin.hairline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (purchase['item_summary'] ?? 'Water Supply').toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isGpayPending) ...[
                    const _SheetBadgeTag(
                      label: 'GPay Pending',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                  ],
                  _SheetBadgeTag(
                    label: due > 0.01
                        ? 'Due ${inrWhole.format(due)}'
                        : 'PAID',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: skin.muted),
                  const SizedBox(width: 4),
                  Text(
                    'When: $dateStr${timeStr.isNotEmpty ? ' · $timeStr' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: skin.muted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    refNo,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: skin.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 13, color: skin.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Where: $whereAddr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Billed: ${inrWhole.format(tot)} · Paid: ${inrWhole.format(paid)} ($mode)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: skin.ink,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: skin.muted,
                  ),
                ],
              ),
              if (isGpayPending && onVerifyGpayProof != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onVerifyGpayProof,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 15),
                    label: const Text(
                      'Upload Proof / Verify',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
              if (expanded) ...[
                const Divider(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (driver.isNotEmpty)
                      _SheetBadgeTag(
                        label:
                            'Driver: $driver${vehicle.isNotEmpty ? ' ($vehicle)' : ''}',
                        color: AppColors.rippleSky,
                      ),
                    if (empties > 0)
                      _SheetBadgeTag(
                        label: 'Empties Returned: $empties',
                        color: skin.primary,
                      ),
                    if (soNo.isNotEmpty)
                      _SheetBadgeTag(label: 'SO: $soNo', color: skin.muted),
                    if (saleNo.isNotEmpty)
                      _SheetBadgeTag(
                        label: 'Invoice: $saleNo',
                        color: skin.muted,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final RippleSkin skin;
  final NumberFormat inrWhole;

  const _CustomerPaymentCard({
    required this.payment,
    required this.skin,
    required this.inrWhole,
  });

  @override
  Widget build(BuildContext context) {
    final amt = _toDouble(payment['amount']);
    final mode = (payment['payment_mode'] ?? 'Cash').toString();
    final refNo = (payment['payment_reference'] ?? '').toString();
    final invRef = (payment['invoice_ref'] ?? '').toString();
    final dateStr = (payment['date'] ?? '').toString();
    final timeStr = (payment['time'] ?? '').toString();
    final note = (payment['note'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skin.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 18,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        refNo.isNotEmpty ? refNo : 'Payment Receipt',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: skin.ink,
                        ),
                      ),
                    ),
                    Text(
                      '+${inrWhole.format(amt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateStr${timeStr.isNotEmpty ? ' · $timeStr' : ''} · $mode${invRef.isNotEmpty ? ' · $invRef' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: skin.muted,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: skin.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerLedgerTimelineRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  final RippleSkin skin;
  final NumberFormat inrWhole;

  const _CustomerLedgerTimelineRow({
    required this.event,
    required this.isLast,
    required this.skin,
    required this.inrWhole,
  });

  @override
  Widget build(BuildContext context) {
    final isPayment = (event['type'] ?? '').toString() == 'payment';
    final color = isPayment ? AppColors.success : AppColors.warning;
    final debit = _toDouble(event['debit']);
    final credit = _toDouble(event['credit']);
    final bal = _toDouble(event['running_balance']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 68,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${event['date'] ?? ''}\n${event['time'] ?? ''}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: skin.muted,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(
                  isPayment
                      ? Icons.south_west_rounded
                      : Icons.shopping_bag_rounded,
                  size: 12,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: skin.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: skin.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: skin.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (event['title'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: skin.ink,
                          ),
                        ),
                      ),
                      Text(
                        isPayment
                            ? '-${inrWhole.format(credit)}'
                            : '+${inrWhole.format(debit)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if ((event['subtitle'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event['subtitle'].toString(),
                      style: TextStyle(fontSize: 10.5, color: skin.muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Running Due: ${inrWhole.format(bal)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: bal > 0.01 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryBox extends StatelessWidget {
  final RippleSkin skin;
  final String message;

  const _EmptyHistoryBox({required this.skin, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: skin.hairline),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.caption.copyWith(color: skin.muted),
        ),
      ),
    );
  }
}

class _CustomerLedgerMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CustomerLedgerMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: skin.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SheetBadgeTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SheetBadgeTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
