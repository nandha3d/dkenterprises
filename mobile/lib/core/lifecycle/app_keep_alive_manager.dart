import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/push_notification_service.dart';
import '../sync/sync_worker.dart';

/// Preserves operational state across multi-app switching while gracefully trimming
/// disposable image bitmaps on backgrounding or OS memory pressure signals.
class AppKeepAliveManager with WidgetsBindingObserver {
  static const String lastAliveStorageKey = 'erp_keep_alive_heartbeat_iso';
  static const int activeImageCacheBytes = 80 << 20;
  static const int suspendedImageCacheBytes = 20 << 20;

  final SharedPreferences _prefs;
  final SyncWorker _syncWorker;
  final PushNotificationService _pushService;

  bool _attached = false;
  int _memoryTrimCount = 0;

  AppKeepAliveManager({
    required SharedPreferences prefs,
    required SyncWorker syncWorker,
    required PushNotificationService pushService,
  })  : _prefs = prefs,
        _syncWorker = syncWorker,
        _pushService = pushService;

  int get memoryTrimCount => _memoryTrimCount;
  bool get isAttached => _attached;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _restoreImageBudget();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Trims live decoded image bitmaps without resetting Riverpod state, routes, or timers.
  void trimNonEssentialMemory({int budgetBytes = suspendedImageCacheBytes}) {
    _memoryTrimCount += 1;
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.clearLiveImages();
      cache.maximumSizeBytes = budgetBytes;
    } catch (_) {}
  }

  void _restoreImageBudget() {
    try {
      PaintingBinding.instance.imageCache.maximumSizeBytes =
          activeImageCacheBytes;
    } catch (_) {}
  }

  void _persistHeartbeat() {
    unawaited(
      _prefs
          .setString(lastAliveStorageKey, DateTime.now().toIso8601String())
          .catchError((_) => false),
    );
  }

  @override
  void didHaveMemoryPressure() {
    trimNonEssentialMemory(budgetBytes: suspendedImageCacheBytes);
    _persistHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _restoreImageBudget();
        _persistHeartbeat();
        unawaited(_pushService.pollNow(notifyOnNew: true));
        unawaited(_syncWorker.drainOutbox().catchError((_) {}));
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _persistHeartbeat();
        trimNonEssentialMemory(budgetBytes: suspendedImageCacheBytes);
        unawaited(_syncWorker.drainOutbox().catchError((_) {}));
      case AppLifecycleState.detached:
        _persistHeartbeat();
    }
  }
}

