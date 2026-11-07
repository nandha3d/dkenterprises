import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('Strict Vertical Isolation & Theme Policy', () {
    test('CompanyInfo correctly determines industry verticals', () {
      final aranCafe = CompanyInfo.fromJson({
        'id': 1,
        'code': 'ARANCAFE',
        'trade_name': 'Aran Cafe',
        'legal_name': 'Aran Cafe Private Limited',
        'industry': 'cafe_bakery',
        'subtype': 'bakery_production',
      });
      expect(aranCafe.industry, equals('cafe_bakery'));

      final tmws = CompanyInfo.fromJson({
        'id': 2,
        'code': 'TMWS',
        'trade_name': 'Tiruchendur Murugan Water Supply',
        'industry': 'bulk_water',
      });
      expect(tmws.industry, equals('bulk_water'));

      final dkWaters = CompanyInfo.fromJson({
        'id': 3,
        'code': 'DKWATERS',
        'trade_name': 'DK Waters',
        'industry': 'packaged_water',
      });
      expect(dkWaters.industry, equals('packaged_water'));

      final textiles = CompanyInfo.fromJson({
        'id': 4,
        'code': 'ZTEX',
        'trade_name': 'zoloERP Textiles',
        'industry': 'textile',
      });
      expect(textiles.industry, equals('textile'));
    });

    test('ThemeModeNotifier defaults to ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SecureStorageService(const FlutterSecureStorage(), prefs);

      final notifier = ThemeModeNotifier(storage);
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));
      expect(storage.getThemeMode(), equals('dark'));

      notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.light));
      expect(storage.getThemeMode(), equals('light'));
    });
  });
}

