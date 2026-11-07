import 'package:flutter_test/flutter_test.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';

void main() {
  group('Auth Domain Models & Permissions', () {
    test('parses UserProfile from json correctly', () {
      final json = {
        'id': 1,
        'name': 'DK Field Driver',
        'username': 'driver',
        'email': 'driver@dk.local',
        'phone': '9876543210',
        'role': 'driver',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, 1);
      expect(profile.name, 'DK Field Driver');
      expect(profile.username, 'driver');
      expect(profile.role, 'driver');
    });

    test('parses CompanyInfo with branches and financial years', () {
      final json = {
        'id': 1,
        'name': 'DK Waters',
        'code': 'DKW',
        'industry': 'packaged_water',
        'branches': [
          {'id': 1, 'name': 'Main Godown', 'code': 'HQ'},
        ],
        'financial_years': [
          {'id': 1, 'financial_year': 'FY 2026-27', 'is_current': true},
        ],
      };

      final company = CompanyInfo.fromJson(json);
      expect(company.id, 1);
      expect(company.name, 'DK Waters');
      expect(company.industry, 'packaged_water');
      expect(company.branches.length, 1);
      expect(company.branches.first.name, 'Main Godown');
      expect(company.financialYears.length, 1);
      expect(company.financialYears.first.name, 'FY 2026-27');
    });

    test('evaluates permissions correctly including admin superuser bypass', () {
      const userState = AuthState(
        permissions: ['sales-index', 'sales-add'],
        roles: ['staff'],
      );

      expect(userState.hasPermission('sales-index'), isTrue);
      expect(userState.hasPermission('purchases-index'), isFalse);

      const adminState = AuthState(
        permissions: [],
        roles: ['admin'],
      );

      expect(adminState.hasPermission('purchases-index'), isTrue);
      expect(adminState.hasPermission('accounting-ledger'), isTrue);
    });
  });
}

