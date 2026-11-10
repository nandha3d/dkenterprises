import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_result.dart';
import '../storage/local_database.dart';

enum SyncStatus { synced, syncing, offline, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncState({
    required this.status,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Outbox Sync Worker responsible for draining local offline mutations.
class SyncWorker extends ChangeNotifier {
  final ApiClient _apiClient;
  final LocalDatabase _db;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  SyncState _state = const SyncState(status: SyncStatus.synced);
  SyncState get state => _state;

  SyncWorker(this._apiClient, this._db) {
    _init();
  }

  void _init() {
    refreshPendingCount();
    // Background polling timer every 30 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      drainOutbox();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshPendingCount() async {
    final count = await _db.getPendingMutationsCount();
    _state = _state.copyWith(
      pendingCount: count,
      status: count == 0 ? SyncStatus.synced : SyncStatus.offline,
    );
    notifyListeners();
  }

  Future<void> drainOutbox() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pending = await _db.getPendingMutations();
      if (pending.isEmpty) {
        _state = _state.copyWith(
          status: SyncStatus.synced,
          pendingCount: 0,
          lastSyncedAt: DateTime.now(),
          clearError: true,
        );
        notifyListeners();
        _isProcessing = false;
        return;
      }

      _state = _state.copyWith(
        status: SyncStatus.syncing,
        pendingCount: pending.length,
        clearError: true,
      );
      notifyListeners();

      for (final item in pending) {
        final id = item['id'] as String;
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
        final idempotencyKey = item['idempotency_key'] as String;

        ApiResult<dynamic> result;
        if (method == 'PUT') {
          result = await _apiClient.put(
            endpoint,
            data: payload,
            fromJson: (data) => data,
          );
        } else {
          result = await _apiClient.post(
            endpoint,
            data: payload,
            idempotencyKey: idempotencyKey,
            fromJson: (data) => data,
          );
        }

        if (result.isSuccess) {
          await _db.deleteMutation(id);
        } else {
          final failure = result.failureOrNull!;
          final errDetail = failure.statusCode != null
              ? 'HTTP ${failure.statusCode}: ${failure.message}'
              : failure.message;
          await _db.updateMutationStatus(
            id,
            'failed',
            error: errDetail,
          );
          _state = _state.copyWith(
            lastError: errDetail,
          );
        }
      }

      final remaining = await _db.getPendingMutationsCount();
      _state = _state.copyWith(
        status: remaining == 0 ? SyncStatus.synced : SyncStatus.error,
        pendingCount: remaining,
        lastSyncedAt: DateTime.now(),
        clearError: remaining == 0,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
      notifyListeners();
    } finally {
      _isProcessing = false;
    }
  }
}

