import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent credentials and company context.
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUsername = 'auth_username';
  static const String _keyRole = 'auth_role';
  static const String _keyCompanyId = 'active_company_id';
  static const String _keyBranchId = 'active_branch_id';
  static const String _keyFinancialYearId = 'active_financial_year_id';
  static const String _keyLanguage = 'selected_language';
  static const String _keyServerUrl = 'custom_server_url';

  SecureStorageService(this._secureStorage, this._prefs);

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  Future<void> saveUserSession({
    required String token,
    required int userId,
    required String username,
    required String role,
  }) async {
    await _secureStorage.write(key: _keyToken, value: token);
    await _prefs.setInt(_keyUserId, userId);
    await _prefs.setString(_keyUsername, username);
    await _prefs.setString(_keyRole, role);
  }

  int? getUserId() => _prefs.getInt(_keyUserId);
  String? getUsername() => _prefs.getString(_keyUsername);
  String? getRole() => _prefs.getString(_keyRole);

  Future<void> setActiveContext({
    required int companyId,
    int? branchId,
    int? financialYearId,
  }) async {
    await _prefs.setInt(_keyCompanyId, companyId);
    if (branchId != null) {
      await _prefs.setInt(_keyBranchId, branchId);
    }
    if (financialYearId != null) {
      await _prefs.setInt(_keyFinancialYearId, financialYearId);
    }
  }

  int? getActiveCompanyId() => _prefs.getInt(_keyCompanyId);
  int? getActiveBranchId() => _prefs.getInt(_keyBranchId);
  int? getActiveFinancialYearId() => _prefs.getInt(_keyFinancialYearId);

  Future<void> setLanguage(String langCode) async {
    await _prefs.setString(_keyLanguage, langCode);
  }

  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'en';

  String getServerUrl() => _prefs.getString(_keyServerUrl) ?? 'https://dkenterprises.animazon.in/api/v1';

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url.trim());
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyCompanyId);
    await _prefs.remove(_keyBranchId);
    await _prefs.remove(_keyFinancialYearId);
  }
}

