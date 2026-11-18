import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Shared messenger key for foreground activity push banners across all routes.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Real-time foreground & resume activity notification poller and heads-up banner dispatcher.
class PushNotificationService extends ChangeNotifier {
  final ApiClient _apiClient;
  void Function(String route)? onNavigate;

  Timer? _pollTimer;
  bool _isRunning = false;
  bool _isFetching = false;
  bool _seededInitialIds = false;
  int _unreadCount = 0;
  final Set<String> _knownIds = <String>{};
  List<Map<String, dynamic>> _latestItems = const [];

  PushNotificationService(this._apiClient, {this.onNavigate});

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get latestItems => _latestItems;
  bool get isRunning => _isRunning;

  /// Starts periodic background/foreground polling and registers this device channel.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    unawaited(_registerDeviceChannel());
    unawaited(pollNow(notifyOnNew: false));
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 18), (_) {
      unawaited(pollNow(notifyOnNew: true));
    });
  }

  /// Stops polling and resets transient session state on logout.
  void stop() {
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _seededInitialIds = false;
    _knownIds.clear();
    if (_unreadCount != 0 || _latestItems.isNotEmpty) {
      _unreadCount = 0;
      _latestItems = const [];
      notifyListeners();
    }
  }

  Future<void> _registerDeviceChannel() async {
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'windows';
      await _apiClient.post(
        ApiEndpoints.devicePushToken,
        data: {
          'device_token': 'erp-$platform-channel-active',
          'platform': platform,
          'app_version': '2.0.0',
        },
        fromJson: (d) => d,
      );
    } catch (_) {}
  }

  /// Polls `/api/v1/notifications` for new operational activities and fires a banner on arrivals.
  Future<void> pollNow({bool notifyOnNew = true}) async {
    if (!_isRunning || _isFetching) return;
    _isFetching = true;
    try {
      final res = await _apiClient
          .get(
            ApiEndpoints.notifications,
            fromJson: (d) =>
                d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
          )
          .timeout(const Duration(seconds: 6));

      if (!res.isSuccess) return;

      final root = res.dataOrNull ?? const <String, dynamic>{};
      final data = root['data'] is Map
          ? Map<String, dynamic>.from(root['data'] as Map)
          : root;
      final rawList = data['notifications'] as List<dynamic>? ?? const [];
      final parsed = rawList
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      final unread = (data['unread_count'] as num?)?.toInt() ??
          parsed.where((n) => n['is_read'] != true).length;

      final newUnreads = <Map<String, dynamic>>[];
      for (final item in parsed) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (_seededInitialIds && !_knownIds.contains(id) && item['is_read'] != true) {
          newUnreads.add(item);
        }
        _knownIds.add(id);
      }

      _seededInitialIds = true;
      _latestItems = parsed;
      final countChanged = _unreadCount != unread;
      _unreadCount = unread;
      if (countChanged) {
        notifyListeners();
      }

      if (notifyOnNew && newUnreads.isNotEmpty) {
        _showHeadsUpBanner(newUnreads.first);
      }
    } catch (_) {
      // Keep polling resilient across transient offline gaps.
    } finally {
      _isFetching = false;
    }
  }

  void markLocalRead() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _showHeadsUpBanner(Map<String, dynamic> alert) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final title = alert['title']?.toString() ?? 'Operational Activity';
    final body = alert['body']?.toString() ?? '';
    final severity = alert['severity']?.toString() ?? 'info';
    final bannerBg = switch (severity) {
      'danger' => const Color(0xFFB91C1C),
      'warning' => const Color(0xFFB45309),
      _ => const Color(0xFF0F292E),
    };

    HapticFeedback.mediumImpact();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bannerBg,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.90),
                ),
              ),
            ],
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.amberAccent,
          onPressed: () {
            onNavigate?.call('/notifications');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
