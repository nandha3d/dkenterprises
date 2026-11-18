import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_worker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/ripple_components.dart';

/// Stitch G-04: Notifications & Offline Sync Center (English-only).
/// Connected to `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`,
/// `POST /api/v1/devices/push-token`, and live inventory low-stock alerts.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoadingStock = true;
  List<Map<String, dynamic>> _lowStockAlerts = [];
  List<Map<String, dynamic>> _inboxNotifications = [];
  int _unreadCount = 0;
  String? _stockError;

  @override
  void initState() {
    super.initState();
    _loadNotificationsAndStock();
  }

  Future<void> _loadNotificationsAndStock() async {
    setState(() {
      _isLoadingStock = true;
      _stockError = null;
    });

    final client = ref.read(apiClientProvider);

    final (notifRes, stockRes) = await (
      client.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        fromJson: (raw) {
          if (raw is Map && raw['data'] is Map) {
            return Map<String, dynamic>.from(raw['data'] as Map);
          }
          if (raw is Map) {
            return Map<String, dynamic>.from(raw);
          }
          return <String, dynamic>{};
        },
      ),
      client.get<List<Map<String, dynamic>>>(
        ApiEndpoints.reportStock,
        fromJson: (data) {
          dynamic payload = data;
          if (payload is Map && payload['data'] is Map) {
            final inner = payload['data'] as Map;
            payload = inner['low_stock'] ??
                inner['items'] ??
                inner['stock_items'] ??
                inner['data'] ??
                const [];
          } else if (payload is Map) {
            payload = payload['low_stock'] ??
                payload['items'] ??
                payload['stock_items'] ??
                payload['data'] ??
                const [];
          }
          if (payload is! List) return const <Map<String, dynamic>>[];
          return payload
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        },
      ),
    ).wait;

    if (!mounted) return;

    if (notifRes is ApiSuccess<Map<String, dynamic>>) {
      final list = notifRes.data['notifications'] as List<dynamic>? ?? const [];
      _inboxNotifications = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _unreadCount =
          int.tryParse((notifRes.data['unread_count'] ?? 0).toString()) ?? 0;
    }

    switch (stockRes) {
      case ApiSuccess<List<Map<String, dynamic>>>(data: final items):
        final alerts = items.where((item) {
          final qty = double.tryParse((item['qty'] ??
                      item['stock_qty'] ??
                      item['stock'] ??
                      item['quantity'] ??
                      0)
                  .toString()) ??
              0;
          final alertQty =
              double.tryParse(item['alert_quantity']?.toString() ?? '5') ?? 5;
          return qty <= alertQty;
        }).take(12).toList();
        setState(() {
          _lowStockAlerts = alerts;
          _isLoadingStock = false;
        });
      case ApiFailure<List<Map<String, dynamic>>>(failure: final f):
        setState(() {
          _stockError = f.message;
          _isLoadingStock = false;
        });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final client = ref.read(apiClientProvider);
    final res = await client.post<Map<String, dynamic>>(
      ApiEndpoints.notificationRead(notificationId),
      fromJson: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    if (!mounted) return;
    if (res is ApiSuccess) {
      await _loadNotificationsAndStock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final syncWorker = ref.watch(syncWorkerProvider);
    final syncState = syncWorker.state;

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: AppBar(
        title: const Text('Notifications & Sync Center'),
        actions: [
          if (_inboxNotifications.isNotEmpty)
            TextButton.icon(
              onPressed: () => _markAsRead('all'),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark All Read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh alerts & drain outbox',
            onPressed: () {
              syncWorker.drainOutbox();
              _loadNotificationsAndStock();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await syncWorker.drainOutbox();
          await _loadNotificationsAndStock();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RippleHeroBanner(
              eyebrow: 'Sync Telemetry · $_unreadCount Unread Alerts',
              headline: syncState.status == SyncStatus.synced
                  ? 'All Caught Up'
                  : '${syncState.pendingCount} Queued',
              subheadline: syncState.lastError ??
                  (syncState.status == SyncStatus.synced
                      ? 'Offline SQLite outbox is empty and synchronized with the ERP server.'
                      : 'Tap Retry Sync to transmit queued transactions.'),
              trailing: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: syncState.status == SyncStatus.syncing
                        ? null
                        : () => syncWorker.drainOutbox(),
                    style: FilledButton.styleFrom(
                      backgroundColor: skin.action,
                      foregroundColor: skin.actionInk,
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(syncState.status == SyncStatus.syncing
                        ? 'Syncing'
                        : 'Retry Sync'),
                  ),
                  if (syncState.pendingCount > 0 && syncState.lastError != null)
                    TextButton.icon(
                      onPressed: () => syncWorker.discardFailedMutations(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 17),
                      label: const Text('Clear Failed'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ERP Alert Inbox',
                    style: AppTypography.section.copyWith(color: skin.ink),
                  ),
                ),
                if (_unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: skin.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(skin.pillRadius),
                    ),
                    child: Text(
                      '$_unreadCount Unread',
                      style: AppTypography.caption.copyWith(
                        color: skin.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_inboxNotifications.isEmpty && !_isLoadingStock)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: skin.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your ERP notification feed is clear.',
                        style: AppTypography.body.copyWith(color: skin.ink),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._inboxNotifications.map((notif) {
                final id = (notif['id'] ?? '').toString();
                final title = (notif['title'] ?? 'ERP Alert').toString();
                final body = (notif['body'] ?? '').toString();
                final isRead = notif['is_read'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RippleActionCard(
                    icon: isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    accentColor:
                        isRead ? skin.muted : AppColors.rippleHoney,
                    title: title,
                    subtitle: body,
                    badge: isRead ? 'Read' : 'New',
                    onTap: () => _markAsRead(id),
                  ),
                );
              }),
            const SizedBox(height: 16),
            Text(
              'Inventory Low-Stock Alerts',
              style: AppTypography.section.copyWith(color: skin.ink),
            ),
            const SizedBox(height: 10),
            if (_isLoadingStock)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stockError != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                ),
                child: Text(
                  'Could not fetch stock signals: $_stockError',
                  style: AppTypography.caption.copyWith(color: AppColors.danger),
                ),
              )
            else if (_lowStockAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.rippleMint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No items below alert threshold right now.',
                        style: AppTypography.body.copyWith(color: skin.ink),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._lowStockAlerts.map((item) {
                final name =
                    (item['name'] ?? item['product_name'] ?? 'Product')
                        .toString();
                final qty = (item['qty'] ??
                        item['stock_qty'] ??
                        item['stock'] ??
                        item['quantity'] ??
                        0)
                    .toString();
                final alert = (item['alert_quantity'] ?? 5).toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RippleActionCard(
                    icon: Icons.warning_amber_rounded,
                    accentColor: AppColors.rippleHoney,
                    title: name,
                    subtitle: 'On hand: $qty (Alert threshold: $alert)',
                    badge: 'Low Stock',
                    onTap: () => context.push('/inventory'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
