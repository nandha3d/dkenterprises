import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_parser.dart';
import '../../auth/domain/auth_models.dart';
import '../../operations/presentation/capture_location_dialog.dart';
import '../../operations/presentation/water_order_helpers.dart';

class CanDeliveryDriverDashboardScreen extends ConsumerStatefulWidget {
  const CanDeliveryDriverDashboardScreen({super.key});

  @override
  ConsumerState<CanDeliveryDriverDashboardScreen> createState() =>
      _CanDeliveryDriverDashboardScreenState();
}

class _CanDeliveryDriverDashboardScreenState
    extends ConsumerState<CanDeliveryDriverDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  Map<String, dynamic>? _manifest;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _asMap(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic val) {
    if (val is! List) return <Map<String, dynamic>>[];
    return val.map((e) => _asMap(e)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _startCanOrder(Map<String, dynamic> order) async {
    final orderId = int.tryParse((order['order_id'] ?? order['id'] ?? '').toString());
    if (orderId == null || orderId <= 0) return;
    final res = await ref.read(apiClientProvider).post(
          ApiEndpoints.waterCanOrderStart(orderId),
          data: <String, dynamic>{},
          fromJson: (d) => d,
        );
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order['order_no'] ?? ''} marked In Transit · Owner Notified'),
          backgroundColor: AppColors.aquaPrimary,
        ),
      );
      _loadManifest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Could not start movement for this order.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _loadManifest() async {
    setState(() {
      _isLoading = _manifest == null;
      _errorMessage = null;
    });

    final db = ref.read(localDatabaseProvider);
    const cacheKey = 'driver_manifest_can_delivery';

    try {
      final cached =
          await db.getCache(cacheKey).timeout(const Duration(milliseconds: 300));
      if (cached != null && mounted) {
        setState(() {
          _manifest = _asMap(cached);
          _isLoading = false;
        });
      }
    } catch (_) {}

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient
          .get(
            '/mobile/driver/manifest',
            fromJson: (data) => data is Map ? _asMap(data) : <String, dynamic>{},
          )
          .timeout(const Duration(seconds: 8));

      if (mounted) {
        if (res.isSuccess) {
          final raw = _asMap(res.dataOrNull);
          final data = raw['data'] != null ? _asMap(raw['data']) : raw;
          if (data.isNotEmpty) {
            await db.saveCache(cacheKey, data);
            setState(() {
              _manifest = data;
              _isLoading = false;
              _errorMessage = null;
            });
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = _manifest == null
                  ? 'No active delivery manifest assigned for today.'
                  : null;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = _manifest == null
                ? (res.failureOrNull?.message ??
                    'Could not load driver manifest.')
                : null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_manifest == null) {
            _errorMessage = 'Offline mode: no cached delivery manifest found.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<int>(
      syncWorkerProvider.select((w) => w.state.pendingCount),
      (previous, next) {
        if (previous != null && next < previous) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadManifest();
          });
        }
      },
    );

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadManifest();
        });
      }
    });

    final skin = RippleSkin.of(context);
    final authState = ref.watch(authNotifierProvider);
    final manifestData = _manifest ?? const <String, dynamic>{};
    final rawManifestName = manifestData['driver_name']?.toString().trim() ?? '';
    final driverName = rawManifestName.isNotEmpty && !UserProfile.looksLikeRoleSlug(rawManifestName)
        ? rawManifestName
        : (authState.user?.displayName ?? UserProfile.humanizeName('', 'deliveryDriver'));
    final vehicle = _asMap(manifestData['vehicle']);
    final canInventory = _asMap(manifestData['can_inventory']);
    final pendingOrders = _asListOfMaps(manifestData['pending_orders']);
    final pendingGpayProofs = _asListOfMaps(
      manifestData['pending_gpay_proofs'] ?? manifestData['pending_upi_verifications'],
    );
    final pendingGpayCount = (manifestData['pending_gpay_count'] as num?)?.toInt() ??
        pendingGpayProofs.length;
    final stops = _asListOfMaps(manifestData['stops']);
    final cash = _asMap(manifestData['cash']);

    final vehicleNo =
        vehicle['vehicle_number']?.toString() ?? 'Unassigned Vehicle';
    final routeName =
        vehicle['route_name']?.toString() ?? 'No Route Assigned';
    final vanCombined = '$vehicleNo $routeName'.toLowerCase();
    final String vanRouteBadge = vanCombined.contains('ev')
        ? 'Tata Ace EV · City <100km'
        : (vanCombined.contains('diesel') || vanCombined.contains('gobi') || vanCombined.contains('salem') || vanCombined.contains('coimbatore'))
            ? 'Tata Ace Diesel · Outer Highway'
            : (vanCombined.contains('tata ace') ? 'Tata Ace Van · Water + Bakery' : 'Water + Bakery Van');

    final loadedCans = (canInventory['loaded_cans'] as num?)?.toInt() ?? 0;
    final deliveredCans =
        (canInventory['delivered_cans'] as num?)?.toInt() ?? 0;
    final emptyCans =
        (canInventory['empty_cans_on_truck'] as num?)?.toInt() ?? 0;
    final remainingCans =
        (canInventory['remaining_full_cans'] as num?)?.toInt() ?? 0;
    final cashInHand = (cash['in_hand'] as num?)?.toDouble() ?? 0.0;

    final completionRatio =
        loadedCans > 0 ? (deliveredCans / loadedCans).clamp(0.0, 1.0) : 0.0;
    final completionPct = (completionRatio * 100).round();

    return Scaffold(
      backgroundColor: skin.canvas,
      body: RefreshIndicator(
        onRefresh: _loadManifest,
        color: AppColors.aquaPrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  if (_errorMessage != null && _manifest == null)
                    _buildErrorBanner(skin),

                  // 1. Driver Header Profile Card (Stitch D-01)
                  _buildDriverHeaderCard(
                    skin: skin,
                    driverName: driverName,
                    vehicleNo: vehicleNo,
                    routeName: routeName,
                    vanRouteBadge: vanRouteBadge,
                  ),
                  const SizedBox(height: 14),

                  // 2. Hero Card: Route Beat Completion & 2x2 Jar Bento (#0E8FB3 Aqua)
                  _buildHeroBeatCard(
                    skin: skin,
                    stopsCount: stops.length,
                    loadedCans: loadedCans,
                    deliveredCans: deliveredCans,
                    emptyCans: emptyCans,
                    remainingCans: remainingCans,
                    completionRatio: completionRatio,
                    completionPct: completionPct,
                  ),
                  const SizedBox(height: 14),

                  // 3. Primary Action Row (+ Customer & Spot Bill)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/parties/customer-onboard'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: skin.surface,
                              foregroundColor: skin.ink,
                              side: BorderSide(color: skin.hairline),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                              color: AppColors.aquaPrimary,
                            ),
                            label: const Text(
                              '+ Customer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await context.push('/operations/can-order');
                              if (mounted) _loadManifest();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.aquaAction,
                              foregroundColor: AppColors.rippleLightInk,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded,
                                size: 20),
                            label: const Text(
                              '+ Create Order',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 3a. Bakery & Biscuit Van Supply Quick Toggle + Pending GPay Proofs
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context.push(
                                '/operations/can-sales',
                                extra: const {'initial_mode': 'bakery_supply'},
                              );
                              if (mounted) _loadManifest();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: skin.surface,
                              foregroundColor: AppColors.chaiPrimary,
                              side: BorderSide(color: AppColors.chaiPrimary.withValues(alpha: 0.45)),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.bakery_dining_rounded, size: 18),
                            label: const Text(
                              'Bakery / Biscuit Supply',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _showPendingGpayProofsSheet(
                            skin: skin,
                            pendingProofs: pendingGpayProofs,
                            pendingCount: pendingGpayCount,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: pendingGpayCount > 0
                                ? AppColors.warning.withValues(alpha: 0.12)
                                : skin.surface,
                            foregroundColor: pendingGpayCount > 0 ? AppColors.warning : skin.ink,
                            side: BorderSide(
                              color: pendingGpayCount > 0 ? AppColors.warning : skin.hairline,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                          label: Text(
                            pendingGpayCount > 0 ? 'GPay ($pendingGpayCount)' : 'GPay Proofs',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3b. Open Customer Can Orders (Step 1 Booked -> Step 2 Move & Close)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Can Orders',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Owner Notified · Move & Close at Customer',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/operations/schedules?vertical=can'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          foregroundColor: AppColors.aquaPrimary,
                        ),
                        icon: const Icon(Icons.event_repeat_rounded, size: 15),
                        label: const Text(
                          'Schedules',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pendingOrders.isNotEmpty
                              ? AppColors.aquaPrimary.withValues(alpha: 0.14)
                              : skin.surface2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${pendingOrders.length} Open',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: pendingOrders.isNotEmpty
                                ? AppColors.aquaPrimary
                                : skin.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (pendingOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: skin.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: skin.hairline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.playlist_add_check_rounded,
                              size: 28, color: skin.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No open customer orders yet. Tap + Create Order when a customer asks for cans before moving.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...pendingOrders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildOpenOrderCard(
                          context: context,
                          skin: skin,
                          order: order,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // 4. Today's Completed Stops (Route Beat Customer Stops)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Scheduled Stops",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Route Beat Customer Stops',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: skin.surface2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${stops.length} Stops Left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: skin.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (stops.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: skin.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: skin.hairline),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.route_outlined,
                              size: 32, color: skin.muted),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ??
                                'No active delivery stops assigned for this beat today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: skin.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...stops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildStopCard(
                          context: context,
                          skin: skin,
                          index: idx + 1,
                          stop: stop,
                        ),
                      );
                    }),

                  const SizedBox(height: 10),

                  // 5. Collected Cash in Pouch & Surrender Card (Stitch D-01)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: skin.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COLLECTED CASH IN POUCH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: skin.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _inrWhole.format(cashInHand),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: skin.ink,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.rippleMint
                                    .withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.rippleMint,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.push('/operations/driver-surrender'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.aquaPrimary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.payments_rounded, size: 18),
                            label: const Text(
                              'Surrender Cash',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showPendingGpayProofsSheet({
    required RippleSkin skin,
    required List<Map<String, dynamic>> pendingProofs,
    required int pendingCount,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.72),
        decoration: BoxDecoration(
          color: skin.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: AppColors.aquaPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pending GPay / UPI Proofs ($pendingCount)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: skin.ink),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (pendingProofs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No pending GPay confirmations right now. Any "Pending (Pay Later)" GPay deliveries will appear here to attach screenshot/UTR proof.',
                  style: TextStyle(fontSize: 13, color: skin.muted),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingProofs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final item = pendingProofs[idx];
                    final entityId = int.tryParse((item['id'] ?? item['entity_id'] ?? 0).toString()) ?? 0;
                    final custName = (item['customer_name'] ?? item['name'] ?? 'Customer').toString();
                    final amt = double.tryParse((item['total_amount'] ?? item['amount'] ?? 0).toString()) ?? 0.0;
                    final refNo = (item['delivery_no'] ?? item['order_no'] ?? '#$entityId').toString();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: skin.hairline),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(custName, style: TextStyle(fontWeight: FontWeight.w800, color: skin.ink)),
                                Text(
                                  '$refNo · ${_inrWhole.format(amt)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: skin.muted),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: entityId <= 0
                                ? null
                                : () async {
                                    Navigator.of(ctx).pop();
                                    await _verifyPendingGpayProof(
                                      entityId: entityId,
                                      customerName: custName,
                                      amount: amt,
                                    );
                                  },
                            child: const Text('Verify Proof', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPendingGpayProof({
    required int entityId,
    required String customerName,
    required double amount,
  }) async {
    final utrCtrl = TextEditingController();
    var selectedAccount = 'GPAY - KAVIN AXIS';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Confirm GPay · $customerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${_inrWhole.format(amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedAccount,
                decoration: const InputDecoration(labelText: 'Received GPay Account'),
                items: const [
                  'GPAY - KAVIN AXIS',
                  'KAVIN KVB',
                  'KAVIN CANARA',
                  'SASI',
                  'AXIS OD LOAN',
                ].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedAccount = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: utrCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI UTR / Screenshot Ref',
                  hintText: 'e.g. WhatsApp screenshot / UTR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mark Confirmed')),
          ],
        ),
      ),
    );
    final utrVal = utrCtrl.text.trim();
    utrCtrl.dispose();
    if (confirmed != true || !mounted) return;

    final res = await ref.read(apiClientProvider).post(
          ApiEndpoints.waterVerifyPaymentProof,
          data: {
            'entity_type': 'can_delivery',
            'entity_id': entityId,
            'status': 'confirmed',
            'paid_amount': amount,
            'payment_account': selectedAccount,
            if (utrVal.isNotEmpty) 'upi_utr': utrVal,
            'payment_proof_ref': utrVal.isNotEmpty
                ? utrVal
                : 'GPAY-VERIFIED-${DateTime.now().millisecondsSinceEpoch}',
          },
          fromJson: (d) => d,
        );
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPay proof verified & confirmed for $customerName!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadManifest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Could not verify GPay proof.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildErrorBanner(RippleSkin skin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rippleHoney.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rippleHoney.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.rippleHoney),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Unable to load manifest',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: skin.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadManifest,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverHeaderCard({
    required RippleSkin skin,
    required String driverName,
    required String vehicleNo,
    required String routeName,
    required String vanRouteBadge,
  }) {
    final initials = driverName.isNotEmpty
        ? driverName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : 'DR';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.aquaPrimary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.aquaPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.rippleMint,
                        shape: BoxShape.circle,
                        border: Border.all(color: skin.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: skin.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.rippleMint.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'ACTIVE BEAT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rippleMint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleNo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.aquaPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        vanRouteBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.aquaPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    context.push('/fleet/gps?mode=packaged_water'),
                icon: const Icon(Icons.radar_rounded,
                    color: AppColors.aquaPrimary),
                tooltip: 'Route Radar',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: AppColors.aquaPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    routeName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: skin.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 7, color: AppColors.rippleMint),
                      SizedBox(width: 4),
                      Text(
                        'Synced ✓',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rippleMint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBeatCard({
    required RippleSkin skin,
    required int stopsCount,
    required int loadedCans,
    required int deliveredCans,
    required int emptyCans,
    required int remainingCans,
    required double completionRatio,
    required int completionPct,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.aquaPrimary, Color(0xFF0A6E8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.aquaPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE BEAT COMPLETION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$stopsCount stops scheduled today',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: completionRatio,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    Text(
                      '$completionPct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeroJarTile('LOADED', '$loadedCans'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroJarTile('DELIVERED', '$deliveredCans'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeroJarTile('EMPTY CANS', '$emptyCans'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroJarTile('REMAINING', '$remainingCans'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroJarTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard({
    required BuildContext context,
    required RippleSkin skin,
    required int index,
    required Map<String, dynamic> stop,
  }) {
    final customerId =
        (stop['customer_id'] as num? ?? stop['id'] as num? ?? 0).toInt();
    final customerName =
        (stop['name'] ?? stop['customer_name'] ?? 'Customer Stop').toString();
    final customerAddress =
        (stop['address'] ?? stop['city'] ?? 'Route Stop').toString();
    final lat = (stop['latitude'] as num?)?.toDouble();
    final lng = (stop['longitude'] as num?)?.toDouble();
    final hasGps = stop['has_gps'] == true ||
        (lat != null && lng != null && lat != 0 && lng != 0);
    final cansQty =
        stop['cans_to_deliver'] ?? stop['default_cans'] ?? stop['qty'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasGps
              ? skin.hairline
              : AppColors.rippleHoney.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: hasGps
                      ? AppColors.aquaPrimary
                      : AppColors.rippleLightInk,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerAddress,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: skin.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasGps
                      ? AppColors.rippleMint.withValues(alpha: 0.14)
                      : AppColors.rippleHoney.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasGps
                          ? Icons.my_location_rounded
                          : Icons.location_off_rounded,
                      size: 12,
                      color: hasGps
                          ? AppColors.rippleMint
                          : AppColors.rippleHoney,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasGps ? 'GPS Verified' : 'No GPS Set',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hasGps
                            ? AppColors.rippleMint
                            : AppColors.rippleHoney,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          size: 16, color: AppColors.aquaPrimary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          cansQty != null
                              ? '$cansQty Cans to Deliver'
                              : 'Water Can Stop Delivery',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: skin.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stop #$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: skin.muted,
                  ),
                ),
              ],
            ),
          ),
          if (!hasGps) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rippleHoney.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.rippleHoney),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Please capture customer GPS via WhatsApp or on-site first.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasGps && lat != null && lng != null) ...[
                IconButton.filledTonal(
                  onPressed: () => LocationParser.launchNavigation(lat, lng),
                  style: IconButton.styleFrom(
                    backgroundColor: skin.surface2,
                    foregroundColor: skin.ink,
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 18),
                  tooltip: 'Navigate',
                ),
                const SizedBox(width: 8),
              ],
              IconButton.filledTonal(
                onPressed: () {
                  CaptureLocationDialog.show(
                    context,
                    customerId: customerId,
                    customerName: customerName,
                    currentAddress: customerAddress,
                    currentLat: lat,
                    currentLng: lng,
                    onLocationUpdated: _loadManifest,
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF25D366).withValues(alpha: 0.14),
                  foregroundColor: const Color(0xFF25D366),
                ),
                icon: const Icon(Icons.share_location_rounded, size: 18),
                tooltip: 'Capture / WhatsApp GPS',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/operations/can-order',
                        extra: {
                          if (customerId > 0) 'customer_id': customerId,
                          if (cansQty != null) 'ordered_cans': cansQty,
                        },
                      );
                      if (mounted) _loadManifest();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aquaPrimary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text(
                      'Create Order',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpenOrderCard({
    required BuildContext context,
    required RippleSkin skin,
    required Map<String, dynamic> order,
  }) {
    final customerName = (order['customer_name'] ?? order['name'] ?? 'Customer').toString();
    final orderNo = (order['order_no'] ?? order['delivery_no'] ?? 'ORD').toString();
    final orderedCans = (order['ordered_cans'] as num?)?.toInt() ?? 0;
    final status = (order['status'] ?? 'ordered').toString().toLowerCase();
    final isTransit = status == 'in_transit';
    final lat = (order['latitude'] as num?)?.toDouble();
    final lng = (order['longitude'] as num?)?.toDouble();
    final hasGps = lat != null && lng != null && lat != 0 && lng != 0;
    final estAmount = (order['estimated_amount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTransit
              ? AppColors.aquaPrimary.withValues(alpha: 0.5)
              : AppColors.rippleHoney.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$orderNo · $orderedCans Cans · Est ${_inrWhole.format(estAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.aquaPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OrderOriginBadge(order: order),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isTransit ? AppColors.aquaPrimary : AppColors.rippleHoney)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isTransit ? 'IN TRANSIT' : 'ORDERED · OWNER NOTIFIED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isTransit ? AppColors.aquaPrimary : AppColors.rippleHoney,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => showAdjustWaterOrderSheet(
                      context: context,
                      ref: ref,
                      verticalType: 'can',
                      order: order,
                      onUpdated: _loadManifest,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      foregroundColor: skin.ink,
                      side: BorderSide(color: skin.hairline),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 13),
                    label: const Text(
                      'Adjust',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (order['order_notes'] != null && order['order_notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${order['order_notes']}',
              style: TextStyle(fontSize: 11, color: skin.muted, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasGps) ...[
                IconButton.filledTonal(
                  onPressed: () => LocationParser.launchNavigation(lat, lng),
                  style: IconButton.styleFrom(
                    backgroundColor: skin.surface2,
                    foregroundColor: skin.ink,
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 18),
                  tooltip: 'Navigate to Customer',
                ),
                const SizedBox(width: 8),
              ],
              if (!isTransit) ...[
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _startCanOrder(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.aquaPrimary,
                        side: const BorderSide(color: AppColors.aquaPrimary),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.directions_run_rounded, size: 18),
                      label: const Text(
                        'Start Moving',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.push('/operations/can-sales', extra: order);
                      if (mounted) _loadManifest();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.rippleMint,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Close & Deliver',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
