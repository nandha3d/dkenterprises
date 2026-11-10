import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/sync/sync_worker.dart';

class FakeApiClient extends ApiClient {
  bool shouldSucceed = true;
  int postCalls = 0;

  FakeApiClient(super.storage);

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    postCalls++;
    if (shouldSucceed) {
      return ApiSuccess(fromJson({'success': true}));
    }
    return const ApiFailure(
      NetworkFailure(
        statusCode: 422,
        message: 'Validation failed',
      ),
    );
  }
}

class InMemoryTestDatabase extends LocalDatabase {
  final List<Map<String, dynamic>> _items = [];

  @override
  Future<void> queueMutation({
    required String id,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    double? gpsLat,
    double? gpsLng,
  }) async {
    _items.add({
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': '{"grand_total": 100.0, "order_items": [{"item_id": 1, "qty": 1, "price": 100.0}]}',
      'idempotency_key': idempotencyKey,
      'status': 'pending',
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingMutations() async {
    return List<Map<String, dynamic>>.from(
      _items.where((m) => m['status'] == 'pending' || m['status'] == 'failed'),
    );
  }

  @override
  Future<int> getPendingMutationsCount() async {
    return _items.where((m) => m['status'] == 'pending' || m['status'] == 'failed').length;
  }

  @override
  Future<void> updateMutationStatus(String id, String status, {String? error}) async {
    for (final m in _items) {
      if (m['id'] == id) {
        m['status'] = status;
        m['last_error'] = error;
      }
    }
  }

  @override
  Future<void> deleteMutation(String id) async {
    _items.removeWhere((m) => m['id'] == id);
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SyncWorker & Offline Outbox Parity Tests', () {
    late FakeApiClient fakeClient;
    late InMemoryTestDatabase fakeDb;
    late SyncWorker syncWorker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SecureStorageService(const FlutterSecureStorage(), prefs);
      fakeClient = FakeApiClient(storage);
      fakeDb = InMemoryTestDatabase();
      syncWorker = SyncWorker(fakeClient, fakeDb);
    });

    tearDown(() {
      syncWorker.dispose();
    });

    test('Queues 5 pending POS mutations, surfaces 422 error on rejection, then drains cleanly on 201 recovery', () async {
      for (int i = 1; i <= 5; i++) {
        await fakeDb.queueMutation(
          id: 'pos-$i',
          endpoint: '/cafe/orders',
          method: 'POST',
          payload: {'grand_total': 100.0 * i},
          idempotencyKey: 'idem-$i',
        );
      }

      await syncWorker.refreshPendingCount();
      expect(syncWorker.state.pendingCount, equals(5));
      expect(syncWorker.state.status, equals(SyncStatus.offline));

      // 1. Server returns 422 -> items stay pending/failed and lastError is populated
      fakeClient.shouldSucceed = false;
      await syncWorker.drainOutbox();

      expect(syncWorker.state.pendingCount, equals(5));
      expect(syncWorker.state.status, equals(SyncStatus.error));
      expect(syncWorker.state.lastError, contains('422'));

      // 2. Server schema fixed (returns 201) -> drainOutbox succeeds & clears all 5 and clears error
      fakeClient.shouldSucceed = true;
      await syncWorker.drainOutbox();

      expect(syncWorker.state.pendingCount, equals(0));
      expect(syncWorker.state.status, equals(SyncStatus.synced));
      expect(syncWorker.state.lastError, isNull);
    });
  });
}

