import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/auth_models.dart';
import 'network/api_client.dart';
import 'storage/local_database.dart';
import 'storage/secure_storage_service.dart';
import 'sync/sync_worker.dart';

// SharedPreferences must be overridden in main()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const secureStorage = FlutterSecureStorage();
  return SecureStorageService(secureStorage, prefs);
});

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

final syncWorkerProvider = ChangeNotifierProvider<SyncWorker>((ref) {
  final client = ref.watch(apiClientProvider);
  final db = ref.watch(localDatabaseProvider);
  return SyncWorker(client, db);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(client, storage);
});

final localeProvider = StateProvider<Locale>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final langCode = storage.getLanguage();
  return Locale(langCode);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storage;

  ThemeModeNotifier(this._storage) : super(_parseMode(_storage.getThemeMode()));

  static ThemeMode _parseMode(String mode) {
    return switch (mode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light, // Default light theme!
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final modeStr = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await _storage.setThemeMode(modeStr);
  }

  void toggleTheme() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeModeNotifier(storage);
});

final dashboardRefreshSignalProvider = StateProvider<int>((ref) => 0);

