import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/scrollable_counter_field.dart';

/// Fallback TMWS 9-truck fleet specification when offline or before backend sync.
const List<Map<String, dynamic>> kDefaultTmwsTankerFleet = [
  {
    'id': 1,
    'vehicle_number': 'TN-33-TM-1401',
    'vehicle_variant': 'Comet',
    'model': 'Comet 14KL (#1)',
    'capacity_kl': 14.0,
    'supported_capacities': [14],
    'has_compartments': false,
    'compartment_notes': 'Single tank 14KL full load',
  },
  {
    'id': 2,
    'vehicle_number': 'TN-33-TM-1402',
    'vehicle_variant': 'Comet',
    'model': 'Comet 14KL (#2)',
    'capacity_kl': 14.0,
    'supported_capacities': [14],
    'has_compartments': false,
    'compartment_notes': 'Single tank 14KL full load',
  },
  {
    'id': 3,
    'vehicle_number': 'TN-33-TM-2501',
    'vehicle_variant': 'Taurus',
    'model': 'Taurus 25KL (#1)',
    'capacity_kl': 25.0,
    'supported_capacities': [25],
    'has_compartments': false,
    'compartment_notes': 'Single tank 25KL full load',
  },
  {
    'id': 4,
    'vehicle_number': 'TN-33-TM-2502',
    'vehicle_variant': 'Taurus',
    'model': 'Taurus 25KL (#2)',
    'capacity_kl': 25.0,
    'supported_capacities': [25],
    'has_compartments': false,
    'compartment_notes': 'Single tank 25KL full load',
  },
  {
    'id': 5,
    'vehicle_number': 'TN-33-TM-2503',
    'vehicle_variant': 'Taurus',
    'model': 'Taurus 25KL (#3)',
    'capacity_kl': 25.0,
    'supported_capacities': [25],
    'has_compartments': false,
    'compartment_notes': 'Single tank 25KL full load',
  },
  {
    'id': 6,
    'vehicle_number': 'TN-33-TM-0901',
    'vehicle_variant': 'Eicher',
    'model': 'Eicher 9KL (#1)',
    'capacity_kl': 9.0,
    'supported_capacities': [4, 5, 6, 7, 8, 9],
    'has_compartments': true,
    'compartment_notes': 'Compartments: 4KL–9KL flexible loads',
  },
  {
    'id': 7,
    'vehicle_number': 'TN-33-TM-0902',
    'vehicle_variant': 'Eicher',
    'model': 'Eicher 9KL (#2)',
    'capacity_kl': 9.0,
    'supported_capacities': [4, 5, 6, 7, 8, 9],
    'has_compartments': true,
    'compartment_notes': 'Compartments: 4KL–9KL flexible loads',
  },
  {
    'id': 8,
    'vehicle_number': 'TN-33-TM-0501',
    'vehicle_variant': 'Tata 407',
    'model': 'Tata 407 5KL',
    'capacity_kl': 5.0,
    'supported_capacities': [2, 3, 4, 5],
    'has_compartments': true,
    'compartment_notes': '2 Compartments (2KL + 3KL)',
  },
  {
    'id': 9,
    'vehicle_number': 'TN-33-TM-2599',
    'vehicle_variant': 'Pondicherry Trailer',
    'model': 'Pondicherry 25ft Trailer',
    'capacity_kl': 25.0,
    'supported_capacities': [25, 30, 35, 40],
    'has_compartments': false,
    'compartment_notes': '25ft outer industrial/construction trailer (wide roads only)',
  },
];

/// Fallback 8 TMWS Water Pickup / Borewell Points across Erode.
const List<Map<String, dynamic>> kDefaultWaterPickupPoints = [
  {
    'id': 1,
    'code': 'PP-VPM',
    'name': 'Veerappampalayam Borewell',
    'location_type': 'regular_borewell',
    'settlement_cycle': 'own',
  },
  {
    'id': 2,
    'code': 'PP-KPR',
    'name': 'Karungalpalayam River-Side Bore',
    'location_type': 'regular_borewell',
    'settlement_cycle': 'own',
  },
  {
    'id': 3,
    'code': 'PP-SLR',
    'name': 'Solar Borewell',
    'location_type': 'regular_borewell',
    'settlement_cycle': 'own',
  },
  {
    'id': 4,
    'code': 'PP-SRP',
    'name': 'Surampatti Point',
    'location_type': 'regular_borewell',
    'settlement_cycle': 'own',
  },
  {
    'id': 5,
    'code': 'PP-MKD',
    'name': 'Mettukadai Point',
    'location_type': 'regular_borewell',
    'settlement_cycle': 'own',
  },
  {
    'id': 6,
    'code': 'PP-CHT',
    'name': 'Chithode Outer Point',
    'location_type': 'outer_paid_borewell',
    'settlement_cycle': 'weekly',
  },
  {
    'id': 7,
    'code': 'PP-LKN',
    'name': 'Lakshmi Nagar Outer Point',
    'location_type': 'outer_paid_borewell',
    'settlement_cycle': 'weekly',
  },
  {
    'id': 8,
    'code': 'PP-PND',
    'name': 'Perundurai Outer Point',
    'location_type': 'outer_paid_borewell',
    'settlement_cycle': 'monthly',
  },
];

/// Default GPay / bank collection accounts matching DK Enterprises' ledger.
const List<String> kGpayVerificationAccounts = [
  'GPAY - KAVIN AXIS',
  'KAVIN KVB',
  'KAVIN CANARA',
  'SASI',
];

/// Returns compartment/load KL capacities supported by [tanker].
List<double> supportedCapacitiesForTanker(Map<String, dynamic>? tanker) {
  if (tanker == null) return const [];
  final raw = tanker['supported_capacities'] ?? tanker['supported_capacities_json'];
  if (raw is List && raw.isNotEmpty) {
    final parsed = raw
        .map((e) => double.tryParse(e.toString()) ?? 0.0)
        .where((v) => v > 0)
        .toList();
    if (parsed.isNotEmpty) return parsed;
  } else if (raw is String && raw.trim().startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final parsed = decoded
            .map((e) => double.tryParse(e.toString()) ?? 0.0)
            .where((v) => v > 0)
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {}
  }

  final hint = [
    tanker['vehicle_variant'] ?? '',
    tanker['model'] ?? '',
    tanker['model_type'] ?? '',
    tanker['vehicle_number'] ?? '',
  ].join(' ').toLowerCase();

  if (hint.contains('eicher')) return const [4, 5, 6, 7, 8, 9];
  if (hint.contains('407') || hint.contains('tata')) return const [2, 3, 4, 5];
  if (hint.contains('comet')) return const [14];
  if (hint.contains('taurus')) return const [25];
  if (hint.contains('pondicherry') || hint.contains('trailer')) {
    return const [25, 30, 35, 40];
  }

  final cap = double.tryParse((tanker['capacity_kl'] ?? '0').toString()) ?? 0.0;
  return cap > 0 ? [cap] : const [];
}

/// Returns true when the selected tanker is a single-chamber full-load unit (Comet 14KL / Taurus 25KL).
bool isFullTankOnlyVariant(Map<String, dynamic>? tanker) {
  if (tanker == null) return false;
  final hint = [
    tanker['vehicle_variant'] ?? '',
    tanker['model'] ?? '',
    tanker['model_type'] ?? '',
    tanker['vehicle_number'] ?? '',
  ].join(' ').toLowerCase();
  if (hint.contains('comet') || hint.contains('taurus')) return true;
  final caps = supportedCapacitiesForTanker(tanker);
  return caps.length == 1 && tanker['has_compartments'] != true;
}

/// Formats a readable label for a tanker vehicle dropdown item.
String formatTankerOptionLabel(Map<String, dynamic> tanker) {
  final number = (tanker['vehicle_number'] ?? tanker['number'] ?? tanker['tanker_no'] ?? 'Tanker').toString().trim();
  final variant = (tanker['vehicle_variant'] ?? tanker['model'] ?? tanker['model_type'] ?? '').toString().trim();
  final cap = double.tryParse((tanker['capacity_kl'] ?? '0').toString()) ?? 0.0;
  final caps = supportedCapacitiesForTanker(tanker);
  final capLabel = caps.length > 1
      ? '[${caps.first.toStringAsFixed(0)}-${caps.last.toStringAsFixed(0)}KL]'
      : (cap > 0 ? '${cap.toStringAsFixed(cap % 1 == 0 ? 0 : 1)}KL' : '');
  final parts = <String>[
    if (number.isNotEmpty) number,
    if (variant.isNotEmpty && !number.toLowerCase().contains(variant.toLowerCase())) variant,
    if (capLabel.isNotEmpty && !variant.toLowerCase().contains(capLabel.toLowerCase())) capLabel,
  ];
  return parts.join(' · ');
}

/// Fetches active TMWS fleet tankers and water pickup points, falling back to seeded defaults when offline/404.
Future<({List<Map<String, dynamic>> tankers, List<Map<String, dynamic>> pickupPoints})>
    fetchTmwsFleetAndPickupPoints(ApiClient client) async {
  List<Map<String, dynamic>> tankers = [];
  List<Map<String, dynamic>> pickupPoints = [];

  try {
    final results = await Future.wait([
      client.get<List<Map<String, dynamic>>>(
        ApiEndpoints.waterCanRoutes,
        fromJson: (data) {
          final map = data is Map && data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
          final list = map['tankers'] is List ? map['tankers'] as List : const [];
          return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        },
      ),
      client.get<List<Map<String, dynamic>>>(
        ApiEndpoints.waterPickupPoints,
        fromJson: (data) {
          final raw = data is Map && data['data'] != null ? data['data'] : data;
          final list = raw is Map && raw['pickup_points'] is List
              ? raw['pickup_points'] as List
              : (raw is List ? raw : const []);
          return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        },
      ),
    ]);

    tankers = results[0].dataOrNull ?? [];
    pickupPoints = results[1].dataOrNull ?? [];
  } catch (_) {}

  if (tankers.isEmpty) {
    tankers = kDefaultTmwsTankerFleet.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (pickupPoints.isEmpty) {
    pickupPoints = kDefaultWaterPickupPoints.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  return (tankers: tankers, pickupPoints: pickupPoints);
}

/// Captured GPay / UPI verification proof payload (transaction ref, payment account, and/or base64 image).
class GpayProofAttachment {
  final String referenceNo;
  final String paymentAccount;
  final String? filePath;
  final String? base64Data;
  final Uint8List? previewBytes;

  const GpayProofAttachment({
    required this.referenceNo,
    required this.paymentAccount,
    this.filePath,
    this.base64Data,
    this.previewBytes,
  });

  bool get hasProof =>
      referenceNo.trim().isNotEmpty ||
      (base64Data != null && base64Data!.isNotEmpty) ||
      (filePath != null && filePath!.trim().isNotEmpty);
}

/// Opens a clean dialog to attach a GPay / UPI screenshot path (encoded to base64) and/or transaction reference.
Future<GpayProofAttachment?> showAttachGpayProofDialog(
  BuildContext context, {
  String? initialRef,
  String? initialPath,
  String initialAccount = 'GPAY - KAVIN AXIS',
}) async {
  final refCtrl = TextEditingController(text: initialRef ?? '');
  final pathCtrl = TextEditingController(text: initialPath ?? '');
  var selectedAccount = kGpayVerificationAccounts.contains(initialAccount)
      ? initialAccount
      : kGpayVerificationAccounts.first;
  Uint8List? previewBytes;
  String? base64Data;
  String? fileError;

  if (!kIsWeb && initialPath != null && initialPath.trim().isNotEmpty) {
    try {
      final f = File(initialPath.trim());
      if (f.existsSync()) {
        final bytes = f.readAsBytesSync();
        previewBytes = bytes;
        base64Data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    } catch (_) {}
  }

  final result = await showDialog<GpayProofAttachment>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        Future<void> tryLoadImageFromPath(String rawPath) async {
          final clean = rawPath.trim().replaceAll('"', '');
          if (clean.isEmpty) {
            setDialogState(() {
              previewBytes = null;
              base64Data = null;
              fileError = null;
            });
            return;
          }
          if (kIsWeb) {
            setDialogState(() {
              fileError = 'Local file path reading is unavailable on Web; enter UPI Ref #.';
            });
            return;
          }
          try {
            final file = File(clean);
            if (!await file.exists()) {
              setDialogState(() {
                previewBytes = null;
                base64Data = null;
                fileError = 'File not found at that path.';
              });
              return;
            }
            final bytes = await file.readAsBytes();
            setDialogState(() {
              previewBytes = bytes;
              base64Data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              fileError = null;
            });
          } catch (e) {
            setDialogState(() {
              fileError = 'Could not read image: $e';
            });
          }
        }

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.aquaPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attach GPay / UPI Proof',
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
                const Text(
                  'Receiving GPay Account',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kGpayVerificationAccounts.map((acc) {
                    return ChoiceChip(
                      selected: selectedAccount == acc,
                      label: Text(acc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onSelected: (_) => setDialogState(() => selectedAccount = acc),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: 'UPI Transaction ID / Ref #',
                    hintText: 'e.g. 432198765432',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Paste from clipboard',
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      onPressed: () async {
                        final clip = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = clip?.text?.trim() ?? '';
                        if (text.isNotEmpty) {
                          refCtrl.text = text;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pathCtrl,
                  decoration: InputDecoration(
                    labelText: 'Screenshot / Photo File Path (Optional)',
                    hintText: '/storage/emulated/0/Pictures/gpay.jpg',
                    border: const OutlineInputBorder(),
                    errorText: fileError,
                    suffixIcon: IconButton(
                      tooltip: 'Load Screenshot Preview',
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      onPressed: () => tryLoadImageFromPath(pathCtrl.text),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.trim().endsWith('.jpg') ||
                        v.trim().endsWith('.jpeg') ||
                        v.trim().endsWith('.png')) {
                      tryLoadImageFromPath(v);
                    }
                  },
                ),
                if (previewBytes != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      previewBytes!,
                      height: 130,
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
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogCtx).pop(
                  GpayProofAttachment(
                    referenceNo: refCtrl.text.trim(),
                    paymentAccount: selectedAccount,
                    filePath: pathCtrl.text.trim().isNotEmpty ? pathCtrl.text.trim() : null,
                    base64Data: base64Data,
                    previewBytes: previewBytes,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Attach Proof'),
            ),
          ],
        );
      },
    ),
  );

  refCtrl.dispose();
  pathCtrl.dispose();
  return result;
}

/// Shared pill badges & modal helpers for Water Can & Bulk Tanker Sales Orders:
/// - Distinguishes Regular Scheduled Orders vs Created Today (On-Day)
/// - Displays ERP Sales Order (`SO-...`) and Fulfilled Sales Bill (`INV/SL-...`) references
/// - Lets drivers/admins adjust open orders before closing, or create Bulk Tanker Sales Orders.
class OrderOriginBadge extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderOriginBadge({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isRegular = order['is_regular_scheduled'] == true ||
        (order['order_origin']?.toString().toLowerCase() == 'scheduled') ||
        order['schedule_id'] != null;
    final label = (order['schedule_label']?.toString().trim().isNotEmpty ?? false)
        ? order['schedule_label'].toString().trim()
        : (isRegular ? 'Regular · Scheduled' : 'Created Today (On-Day)');
    final soNo = order['sales_order_no']?.toString().trim();
    final billNo = order['sale_no']?.toString().trim();
    final skin = RippleSkin.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (isRegular ? AppColors.aquaPrimary : AppColors.rippleHoney)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (isRegular ? AppColors.aquaPrimary : AppColors.rippleHoney)
                  .withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRegular ? Icons.event_repeat_rounded : Icons.today_rounded,
                size: 12,
                color: isRegular ? AppColors.aquaPrimary : skin.ink,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isRegular ? AppColors.aquaPrimary : skin.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (soNo != null && soNo.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: skin.hairline),
            ),
            child: Text(
              soNo,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: skin.ink,
              ),
            ),
          ),
        if (billNo != null && billNo.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.rippleMint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Bill $billNo',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.rippleMint,
              ),
            ),
          ),
      ],
    );
  }
}

/// Shared bottom-sheet editor for adjusting an open Water Can or Bulk Tanker Sales Order before closing.
Future<void> showAdjustWaterOrderSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String verticalType,
  required Map<String, dynamic> order,
  required VoidCallback onUpdated,
}) async {
  final isTanker = verticalType == 'tanker';
  final orderId = int.tryParse((order['order_id'] ?? order['trip_id'] ?? order['id'] ?? '').toString());
  if (orderId == null || orderId <= 0) return;

  final client = ref.read(apiClientProvider);
  final fleetMeta = isTanker
      ? await fetchTmwsFleetAndPickupPoints(client)
      : (tankers: const <Map<String, dynamic>>[], pickupPoints: const <Map<String, dynamic>>[]);
  if (!context.mounted) return;

  final tankers = fleetMeta.tankers;
  final pickupPoints = fleetMeta.pickupPoints;
  int? selectedTankerId = int.tryParse((order['tanker_id'] ?? '').toString());
  if (selectedTankerId != null && !tankers.any((t) => int.tryParse((t['id'] ?? '').toString()) == selectedTankerId)) {
    selectedTankerId = tankers.isNotEmpty ? int.tryParse((tankers.first['id'] ?? '').toString()) : null;
  }
  int? selectedPickupId = int.tryParse((order['pickup_point_id'] ?? '').toString());
  if (selectedPickupId != null && !pickupPoints.any((p) => int.tryParse((p['id'] ?? '').toString()) == selectedPickupId)) {
    selectedPickupId = null;
  }

  var orderedCans = (order['ordered_cans'] as num?)?.toInt() ?? 1;
  var canSize = (order['can_size']?.toString().trim().isNotEmpty ?? false)
      ? order['can_size'].toString().trim()
      : '20L Can';
  final qtyCtrl = TextEditingController(
    text: isTanker
        ? ((order['water_quantity_kl'] as num?)?.toString() ?? '10')
        : '$orderedCans',
  );
  final rateCtrl = TextEditingController(
    text: isTanker
        ? ((order['trip_rate'] as num?)?.toStringAsFixed(0) ?? '1800')
        : ((order['can_rate'] as num?)?.toStringAsFixed(0) ??
            (order['master_can_rate'] as num?)?.toStringAsFixed(0) ??
            '35'),
  );
  final destCtrl = TextEditingController(
    text: (order['destination_site'] ?? order['customer_name'] ?? '').toString(),
  );
  final notesCtrl = TextEditingController(
    text: (order['order_notes'] ?? order['notes'] ?? '').toString(),
  );
  var dateStr = (order['delivery_date'] ?? order['trip_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString();
  if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);
  var paymentMode = (order['payment_mode'] ?? 'Cash').toString();
  var isSaving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SheetLifecycleScope(
      onDispose: () {
        qtyCtrl.dispose();
        rateCtrl.dispose();
        destCtrl.dispose();
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
                  isTanker
                      ? 'Adjust Tanker Sales Order (${order['sales_order_no'] ?? order['trip_number'] ?? '#$orderId'})'
                      : 'Adjust Can Sales Order (${order['sales_order_no'] ?? order['order_no'] ?? '#$orderId'})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: skin.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order['customer_name'] ?? 'Customer'} · Updates backend Sales Order before closing',
                  style: TextStyle(fontSize: 12, color: skin.muted),
                ),
                const SizedBox(height: 14),
                if (isTanker) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Water Qty (KL)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Trip Rate (₹)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tankers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTankerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Tanker Vehicle',
                        border: OutlineInputBorder(),
                      ),
                      items: tankers
                          .map((t) => DropdownMenuItem<int>(
                                value: int.tryParse((t['id'] ?? '').toString()),
                                child: Text(formatTankerOptionLabel(t), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedTankerId = v),
                    ),
                  ],
                  if (pickupPoints.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedPickupId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Water Pickup / Borewell Point',
                        border: OutlineInputBorder(),
                      ),
                      items: pickupPoints
                          .map((p) => DropdownMenuItem<int>(
                                value: int.tryParse((p['id'] ?? '').toString()),
                                child: Text((p['name'] ?? 'Pickup Point').toString(), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedPickupId = v),
                    ),
                  ],
                ] else ...[
                  WaterContainerSizeSelector(
                    selectedSize: canSize,
                    onChanged: (v) => setModalState(() => canSize = v),
                  ),
                  const SizedBox(height: 12),
                  ScrollableCounterRow(
                    title: 'Ordered $canSize',
                    subtitle: 'Scroll wheel or tap to type',
                    value: orderedCans,
                    min: 1,
                    max: 1000,
                    onChanged: (v) => setModalState(() {
                      orderedCans = v;
                      qtyCtrl.text = '$v';
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Rate / Unit (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final initial = DateTime.tryParse(dateStr) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              dateStr = picked.toIso8601String().substring(0, 10);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(dateStr),
                      ),
                    ),
                    if (!isTanker) ...[
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
                  ],
                ),
                if (isTanker) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: destCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination Site / Sump',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final endpoint = isTanker
                                ? ApiEndpoints.waterTankerOrderAdjust(orderId)
                                : ApiEndpoints.waterCanOrderAdjust(orderId);
                            final selectedPickup = selectedPickupId != null
                                ? pickupPoints.firstWhere(
                                    (p) => int.tryParse((p['id'] ?? '').toString()) == selectedPickupId,
                                    orElse: () => <String, dynamic>{},
                                  )
                                : <String, dynamic>{};
                            final payload = isTanker
                                ? <String, dynamic>{
                                    'water_quantity_kl': double.tryParse(qtyCtrl.text.trim()) ?? 10.0,
                                    'trip_rate': double.tryParse(rateCtrl.text.trim()) ?? 1800.0,
                                    'trip_date': dateStr,
                                    'destination_site': destCtrl.text.trim(),
                                    'notes': notesCtrl.text.trim(),
                                    if (selectedTankerId != null) 'tanker_id': selectedTankerId,
                                    if (selectedPickupId != null) 'pickup_point_id': selectedPickupId,
                                    if ((selectedPickup['name'] ?? '').toString().isNotEmpty) ...{
                                      'pickup_point_name': selectedPickup['name'].toString(),
                                      'source_plant': selectedPickup['name'].toString(),
                                    },
                                  }
                                : <String, dynamic>{
                                    'ordered_cans': orderedCans,
                                    'can_size': canSize,
                                    'can_rate': double.tryParse(rateCtrl.text.trim()) ?? 35.0,
                                    'delivery_date': dateStr,
                                    'payment_mode': paymentMode,
                                    'order_notes': notesCtrl.text.trim(),
                                  };
                            final res = await client.post<Map<String, dynamic>>(
                              endpoint,
                              data: payload,
                              fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
                            );
                            if (!ctx.mounted) return;
                            setModalState(() => isSaving = false);
                            if (res.isSuccess) {
                              Navigator.of(ctx).pop();
                              ref.read(dashboardRefreshSignalProvider.notifier).state++;
                              onUpdated();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sales Order customized & synced with ERP.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(res.failureOrNull?.message ?? 'Unable to update order.'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save Adjusted Sales Order', style: TextStyle(fontWeight: FontWeight.w800)),
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

/// Shared bottom-sheet to Create a Bulk Water Tanker Sales Order (with inline walk-in customer, fleet variants, pickup points & recurring schedule).
Future<void> showCreateTankerOrderSheet({
  required BuildContext context,
  required WidgetRef ref,
  int? tankerId,
  required VoidCallback onCreated,
}) async {
  final client = ref.read(apiClientProvider);
  final custFuture = client.get<List<Map<String, dynamic>>>(
    ApiEndpoints.customers,
    fromJson: (data) {
      final list = data is Map && data['data'] is List
          ? data['data'] as List
          : (data is List ? data : []);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    },
  );
  final fleetFuture = fetchTmwsFleetAndPickupPoints(client);
  final custRes = await custFuture;
  final fleetMeta = await fleetFuture;
  if (!context.mounted) return;

  final customers = custRes.dataOrNull ?? [];
  final tankers = fleetMeta.tankers;
  final pickupPoints = fleetMeta.pickupPoints;

  var isWalkInCustomer = customers.isEmpty;
  int? selectedCustomerId = customers.isNotEmpty ? int.tryParse(customers.first['id'].toString()) : null;
  final customerNameCtrl = TextEditingController(
    text: customers.isNotEmpty ? (customers.first['name'] ?? '').toString() : '',
  );
  final walkInPhoneCtrl = TextEditingController();
  final walkInAreaCtrl = TextEditingController();
  final siteCtrl = TextEditingController(
    text: customers.isNotEmpty ? (customers.first['address'] ?? customers.first['name'] ?? '').toString() : '',
  );

  var isOutsourcedVehicle = false;
  int? selectedTankerId = tankerId ??
      (tankers.isNotEmpty ? int.tryParse((tankers.first['id'] ?? '').toString()) : null);
  if (selectedTankerId != null &&
      !tankers.any((t) => int.tryParse((t['id'] ?? '').toString()) == selectedTankerId)) {
    selectedTankerId = tankers.isNotEmpty ? int.tryParse((tankers.first['id'] ?? '').toString()) : null;
  }
  Map<String, dynamic>? currentTanker() {
    if (selectedTankerId == null) return null;
    for (final t in tankers) {
      if (int.tryParse((t['id'] ?? '').toString()) == selectedTankerId) return t;
    }
    return null;
  }

  final initialTanker = currentTanker();
  final initialCap = (initialTanker?['capacity_kl'] as num?)?.toDouble() ?? 14.0;
  final klCtrl = TextEditingController(text: initialCap.toStringAsFixed(0));
  final rateCtrl = TextEditingController(text: (initialCap * 150).toStringAsFixed(0));
  final extVehicleCtrl = TextEditingController();
  final extVendorCtrl = TextEditingController();
  final vendorPayableCtrl = TextEditingController(text: '0');

  int? selectedPickupId =
      pickupPoints.isNotEmpty ? int.tryParse((pickupPoints.first['id'] ?? '').toString()) : null;

  final intervalCtrl = TextEditingController(text: '2');
  final notesCtrl = TextEditingController();
  var tripDate = DateTime.now().toIso8601String().substring(0, 10);
  var frequency = 'on_day';
  final selectedWeekdays = <int>{DateTime.now().weekday};
  var isSaving = false;
  String? validationError;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SheetLifecycleScope(
      onDispose: () {
        customerNameCtrl.dispose();
        walkInPhoneCtrl.dispose();
        walkInAreaCtrl.dispose();
        siteCtrl.dispose();
        klCtrl.dispose();
        rateCtrl.dispose();
        extVehicleCtrl.dispose();
        extVendorCtrl.dispose();
        vendorPayableCtrl.dispose();
        intervalCtrl.dispose();
        notesCtrl.dispose();
      },
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final skin = RippleSkin.of(ctx);
          final activeTanker = currentTanker();
          final supportedCaps = isOutsourcedVehicle
              ? const <double>[5, 9, 12, 14, 25]
              : supportedCapacitiesForTanker(activeTanker);
          final fullLoadLocked = !isOutsourcedVehicle && isFullTankOnlyVariant(activeTanker);
          final currentKlVal = double.tryParse(klCtrl.text.trim()) ?? 0.0;

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
                    'Create Bulk Tanker Sales Order',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: skin.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports corporate & instant walk-in residential orders, compartments & 8 borewell points.',
                    style: TextStyle(fontSize: 12, color: skin.muted),
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        validationError!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Inline Walk-in / New Customer toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: skin.ink),
                      ),
                      FilterChip(
                        selected: isWalkInCustomer,
                        label: const Text(
                          'Walk-in / New Customer',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        avatar: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                        onSelected: customers.isEmpty
                            ? null
                            : (v) {
                                setModalState(() {
                                  isWalkInCustomer = v;
                                  validationError = null;
                                  if (v) {
                                    selectedCustomerId = null;
                                    customerNameCtrl.clear();
                                    siteCtrl.clear();
                                  } else if (customers.isNotEmpty) {
                                    selectedCustomerId = int.tryParse(customers.first['id'].toString());
                                    customerNameCtrl.text = (customers.first['name'] ?? '').toString();
                                    siteCtrl.text =
                                        (customers.first['address'] ?? customers.first['name'] ?? '').toString();
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isWalkInCustomer && customers.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedCustomerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Existing Customer',
                        border: OutlineInputBorder(),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem<int>(
                                value: int.tryParse(c['id'].toString()),
                                child: Text((c['name'] ?? 'Customer').toString()),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setModalState(() {
                          selectedCustomerId = v;
                          final match = customers.firstWhere(
                            (c) => int.tryParse(c['id'].toString()) == v,
                            orElse: () => {},
                          );
                          if (match.isNotEmpty) {
                            customerNameCtrl.text = (match['name'] ?? '').toString();
                            siteCtrl.text = (match['address'] ?? match['name'] ?? '').toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    TextField(
                      controller: customerNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer / House Name *',
                        hintText: 'e.g. Keerthi Residency / Suresh House',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: walkInPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '10-digit mobile',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: walkInAreaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Area / Location',
                              hintText: 'e.g. Mettukadai',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              if (siteCtrl.text.trim().isEmpty || siteCtrl.text == v) {
                                siteCtrl.text = v;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  TextField(
                    controller: siteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination Site / Unloading Sump',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fleet Variant Selector + Outside Tie-Up Vehicle Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tanker Fleet & Capacity',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: skin.ink),
                      ),
                      FilterChip(
                        selected: isOutsourcedVehicle,
                        label: const Text(
                          'Outside / வெளி வண்டி',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        avatar: const Icon(Icons.swap_horiz_rounded, size: 15),
                        onSelected: (v) {
                          setModalState(() {
                            isOutsourcedVehicle = v;
                            validationError = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isOutsourcedVehicle && tankers.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedTankerId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select TMWS Tanker Vehicle',
                        border: OutlineInputBorder(),
                      ),
                      items: tankers
                          .map((t) => DropdownMenuItem<int>(
                                value: int.tryParse((t['id'] ?? '').toString()),
                                child: Text(formatTankerOptionLabel(t), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setModalState(() {
                          selectedTankerId = v;
                          final picked = currentTanker();
                          final caps = supportedCapacitiesForTanker(picked);
                          final defaultCap = caps.isNotEmpty
                              ? caps.last
                              : ((picked?['capacity_kl'] as num?)?.toDouble() ?? 14.0);
                          klCtrl.text = defaultCap.toStringAsFixed(defaultCap % 1 == 0 ? 0 : 1);
                        });
                      },
                    ),
                    if ((activeTanker?['compartment_notes'] ?? '').toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        activeTanker!['compartment_notes'].toString(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: skin.muted),
                      ),
                    ],
                  ] else if (isOutsourcedVehicle) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: extVehicleCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'External Vehicle No *',
                              hintText: 'TN-33-XX-1234',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: extVendorCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Outside Vendor Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: vendorPayableCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Vendor Payable Rate (₹)',
                        hintText: 'Amount payable to tie-up owner',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  if (supportedCaps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: supportedCaps.map((cap) {
                        final selected = (currentKlVal - cap).abs() < 0.01;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(
                            fullLoadLocked
                                ? '${cap.toStringAsFixed(0)}KL Full Load'
                                : '${cap.toStringAsFixed(cap % 1 == 0 ? 0 : 1)}KL',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              klCtrl.text = cap.toStringAsFixed(cap % 1 == 0 ? 0 : 1);
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
                        child: TextField(
                          controller: klCtrl,
                          readOnly: fullLoadLocked,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: fullLoadLocked ? 'Volume (KL · Full Tank)' : 'Volume (KL) *',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Agreed Price (₹) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 8 Water Pickup / Borewell Points Dropdown
                  if (pickupPoints.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: selectedPickupId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Water Pickup / Borewell Point (தண்ணி பிடிக்கிற இடம்)',
                        border: OutlineInputBorder(),
                      ),
                      items: pickupPoints.map((p) {
                        final id = int.tryParse((p['id'] ?? '').toString());
                        final name = (p['name'] ?? 'Pickup Point').toString();
                        final isOuter = (p['location_type'] ?? '') == 'outer_paid_borewell';
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            isOuter ? '$name (Outer Paid)' : name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedPickupId = v),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: frequency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Schedule / Order Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'on_day', child: Text('Today Only (On-Day)')),
                            DropdownMenuItem(value: 'daily', child: Text('Regular · Daily')),
                            DropdownMenuItem(value: 'every_n_days', child: Text('Regular · Every N Days')),
                            DropdownMenuItem(value: 'weekly', child: Text('Regular · Weekly')),
                            DropdownMenuItem(value: 'biweekly', child: Text('Regular · Every 2 Weeks')),
                            DropdownMenuItem(value: 'monthly', child: Text('Regular · Monthly')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => frequency = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final init = DateTime.tryParse(tripDate) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: init,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() => tripDate = picked.toIso8601String().substring(0, 10));
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(tripDate),
                      ),
                    ],
                  ),
                  if (frequency == 'every_n_days') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: intervalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repeat Every N Days (e.g. 2)',
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
                        final active = selectedWeekdays.contains(pair.$1);
                        return FilterChip(
                          selected: active,
                          label: Text(pair.$2, style: const TextStyle(fontSize: 11)),
                          onSelected: (v) {
                            setModalState(() {
                              if (v) {
                                selectedWeekdays.add(pair.$1);
                              } else if (selectedWeekdays.length > 1) {
                                selectedWeekdays.remove(pair.$1);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (isWalkInCustomer && customerNameCtrl.text.trim().isEmpty) {
                                setModalState(() => validationError = 'Please enter walk-in customer name.');
                                return;
                              }
                              if (isOutsourcedVehicle && extVehicleCtrl.text.trim().isEmpty) {
                                setModalState(() => validationError = 'Please enter outside vehicle number.');
                                return;
                              }
                              setModalState(() {
                                isSaving = true;
                                validationError = null;
                              });
                              final kl = double.tryParse(klCtrl.text.trim()) ?? 10.0;
                              final rate = double.tryParse(rateCtrl.text.trim()) ?? (kl * 180);
                              final isSched = frequency != 'on_day';
                              final selectedPickup = selectedPickupId != null
                                  ? pickupPoints.firstWhere(
                                      (p) => int.tryParse((p['id'] ?? '').toString()) == selectedPickupId,
                                      orElse: () => <String, dynamic>{},
                                    )
                                  : <String, dynamic>{};
                              final pickupName = (selectedPickup['name'] ?? '').toString();
                              final destText = siteCtrl.text.trim().isNotEmpty
                                  ? siteCtrl.text.trim()
                                  : (walkInAreaCtrl.text.trim().isNotEmpty
                                      ? walkInAreaCtrl.text.trim()
                                      : customerNameCtrl.text.trim());

                              final payload = <String, dynamic>{
                                if (!isWalkInCustomer && selectedCustomerId != null)
                                  'customer_id': selectedCustomerId,
                                if (customerNameCtrl.text.trim().isNotEmpty)
                                  'customer_name': customerNameCtrl.text.trim(),
                                if (isWalkInCustomer) ...{
                                  'walk_in_customer_name': customerNameCtrl.text.trim(),
                                  if (walkInPhoneCtrl.text.trim().isNotEmpty) ...{
                                    'walk_in_customer_phone': walkInPhoneCtrl.text.trim(),
                                    'customer_phone': walkInPhoneCtrl.text.trim(),
                                  },
                                  if (walkInAreaCtrl.text.trim().isNotEmpty)
                                    'location_area': walkInAreaCtrl.text.trim(),
                                },
                                if (!isOutsourcedVehicle && selectedTankerId != null) 'tanker_id': selectedTankerId,
                                if (isOutsourcedVehicle) ...{
                                  'is_outsourced_vehicle': true,
                                  'external_vehicle_no': extVehicleCtrl.text.trim(),
                                  if (extVendorCtrl.text.trim().isNotEmpty)
                                    'external_vendor_name': extVendorCtrl.text.trim(),
                                  'vendor_payable_amount':
                                      double.tryParse(vendorPayableCtrl.text.trim()) ?? 0.0,
                                },
                                if (selectedPickupId != null) 'pickup_point_id': selectedPickupId,
                                if (pickupName.isNotEmpty) ...{
                                  'pickup_point_name': pickupName,
                                  'source_plant': pickupName,
                                },
                                'destination_site': destText,
                                'water_quantity_kl': kl,
                                'trip_rate': rate,
                                'trip_date': tripDate,
                                'status': 'dispatched',
                                if (isSched) 'create_schedule': true,
                                if (isSched) 'schedule_frequency': frequency,
                                if (frequency == 'every_n_days')
                                  'interval_days': int.tryParse(intervalCtrl.text.trim()) ?? 2,
                                if (frequency == 'weekly') 'days_of_week': selectedWeekdays.toList()..sort(),
                                if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                              };
                              final res = await client.post<Map<String, dynamic>>(
                                ApiEndpoints.waterTankerOrders,
                                data: payload,
                                fromJson: (d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
                              );
                              if (!ctx.mounted) return;
                              setModalState(() => isSaving = false);
                              if (res.isSuccess) {
                                Navigator.of(ctx).pop();
                                ref.read(dashboardRefreshSignalProvider.notifier).state++;
                                onCreated();
                                if (context.mounted) {
                                  final inner = res.dataOrNull?['data'];
                                  final soNo = inner is Map ? inner['sales_order_no']?.toString() : null;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tanker Sales Order ${soNo ?? ''} created & owner notified.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(res.failureOrNull?.message ?? 'Unable to create tanker order.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_task_rounded),
                      label: const Text('Create Sales Order', style: TextStyle(fontWeight: FontWeight.w800)),
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

/// Defers disposal of modal controllers until the sheet route finishes its exit animation.
class SheetLifecycleScope extends StatefulWidget {
  final VoidCallback onDispose;
  final Widget child;

  const SheetLifecycleScope({
    super.key,
    required this.onDispose,
    required this.child,
  });

  @override
  State<SheetLifecycleScope> createState() => _SheetLifecycleScopeState();
}

class _SheetLifecycleScopeState extends State<SheetLifecycleScope> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

