import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite Database Manager for offline caching and outbox sync engine.
class LocalDatabase {
  static Database? _database;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTime = {};

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'zolo_erp_offline.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          // Outbox table for offline mutations
          await db.execute('''
            CREATE TABLE outbox_mutations (
              id TEXT PRIMARY KEY,
              endpoint TEXT NOT NULL,
              method TEXT NOT NULL,
              payload TEXT NOT NULL,
              idempotency_key TEXT NOT NULL,
              client_timestamp TEXT NOT NULL,
              gps_lat REAL,
              gps_lng REAL,
              status TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          // Master records cache table (customers, products, invoices, financials)
          await db.execute('''
            CREATE TABLE cached_records (
              cache_key TEXT PRIMARY KEY,
              json_data TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (_) {
      // Re-throw or let cache operations fall back to memory
      rethrow;
    }
  }

  // ---------------- CACHE OPERATIONS ---------------- //

  Future<void> saveCache(String key, dynamic data) async {
    _memoryCache[key] = data;
    _memoryCacheTime[key] = DateTime.now();
    try {
      final db = await database;
      final jsonStr = jsonEncode(data);
      await db.insert(
        'cached_records',
        {
          'cache_key': key,
          'json_data': jsonStr,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Gracefully continue with in-memory cache
    }
  }

  Future<dynamic> getCache(String key) async {
    try {
      final db = await database;
      final res = await db.query(
        'cached_records',
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (res.isNotEmpty) {
        try {
          return jsonDecode(res.first['json_data'] as String);
        } catch (_) {
          return null;
        }
      }
    } catch (_) {
      // Fallback to in-memory cache
    }
    return _memoryCache[key];
  }

  Future<DateTime?> getCacheTimestamp(String key) async {
    try {
      final db = await database;
      final res = await db.query(
        'cached_records',
        columns: ['updated_at'],
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return DateTime.tryParse(res.first['updated_at'] as String);
      }
    } catch (_) {
      // Fallback to in-memory timestamp
    }
    return _memoryCacheTime[key];
  }

  // ---------------- OUTBOX OPERATIONS ---------------- //
  final List<Map<String, dynamic>> _memoryOutbox = [];

  Future<void> queueMutation({
    required String id,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final record = {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': jsonEncode(payload),
      'idempotency_key': idempotencyKey,
      'client_timestamp': DateTime.now().toIso8601String(),
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'status': 'pending',
      'attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    _memoryOutbox.add(record);

    try {
      final db = await database;
      await db.insert(
        'outbox_mutations',
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // In-memory fallback
    }
  }

  Future<List<Map<String, dynamic>>> getPendingMutations() async {
    try {
      final db = await database;
      return await db.query(
        'outbox_mutations',
        where: 'status = ? OR status = ?',
        whereArgs: ['pending', 'failed'],
        orderBy: 'created_at ASC',
      );
    } catch (_) {
      return List.from(_memoryOutbox.where((m) => m['status'] == 'pending' || m['status'] == 'failed'));
    }
  }

  Future<int> getPendingMutationsCount() async {
    try {
      final db = await database;
      final res = await db.rawQuery(
        "SELECT COUNT(*) as count FROM outbox_mutations WHERE status IN ('pending', 'failed')",
      );
      return Sqflite.firstIntValue(res) ?? 0;
    } catch (_) {
      return _memoryOutbox.where((m) => m['status'] == 'pending' || m['status'] == 'failed').length;
    }
  }

  Future<void> updateMutationStatus(
    String id,
    String status, {
    String? error,
  }) async {
    for (var m in _memoryOutbox) {
      if (m['id'] == id) {
        m['status'] = status;
        m['last_error'] = error;
        m['attempts'] = (m['attempts'] as int? ?? 0) + 1;
      }
    }
    try {
      final db = await database;
      await db.rawUpdate(
        '''
        UPDATE outbox_mutations
        SET status = ?, attempts = attempts + 1, last_error = ?
        WHERE id = ?
      ''',
        [status, error, id],
      );
    } catch (_) {
      // Handled in memory
    }
  }

  Future<void> deleteMutation(String id) async {
    _memoryOutbox.removeWhere((m) => m['id'] == id);
    try {
      final db = await database;
      await db.delete(
        'outbox_mutations',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {
      // Handled in memory
    }
  }

  Future<void> clearAll() async {
    _memoryOutbox.clear();
    _memoryCache.clear();
    _memoryCacheTime.clear();
    try {
      final db = await database;
      await db.delete('outbox_mutations');
      await db.delete('cached_records');
    } catch (_) {
      // Handled in memory
    }
  }
}

