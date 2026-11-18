import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_models.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthNotifier(this._apiClient, this._storage) : super(const AuthState()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    state = state.copyWith(isLoading: true, token: token);
    await refreshMe();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginResult = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'email': username,
        'name': username,
        'password': password,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (loginResult.isFailure) {
      final failure = loginResult.failureOrNull;
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure?.message ?? 'Login failed. Please check credentials.',
      );
      return false;
    }

    final rawData = loginResult.dataOrNull ?? <String, dynamic>{};
    if (rawData['success'] == false) {
      final message = rawData['message']?.toString() ?? 'Authentication failed.';
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: message,
      );
      return false;
    }

    final data = rawData['data'] is Map<String, dynamic>
        ? rawData['data'] as Map<String, dynamic>
        : (rawData['data'] is Map ? Map<String, dynamic>.from(rawData['data'] as Map) : rawData);
    final token = data['token']?.toString() ??
        rawData['token']?.toString() ??
        data['access_token']?.toString() ??
        rawData['access_token']?.toString() ??
        '';
    if (token.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Invalid authentication response: Missing token.',
      );
      return false;
    }

    await _storage.saveToken(token);

    // Seed user & accessible companies directly from /mobile/login so the company list
    // is available immediately even before /me completes or on older servers.
    final loginUserMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    final loginUser = loginUserMap.isNotEmpty ? UserProfile.fromJson(loginUserMap) : state.user;
    final loginRoles = (data['roles'] as List<dynamic>? ?? [])
        .map((r) => r.toString())
        .toList();
    if (loginRoles.isEmpty && data['role'] != null) {
      loginRoles.add(data['role'].toString());
    }
    final loginPermissions = (data['permissions'] as List<dynamic>? ?? [])
        .map((p) => p.toString())
        .toList();
    final loginCompaniesJson = data['companies'] as List<dynamic>? ?? [];
    final loginCompanies = loginCompaniesJson
        .whereType<Map>()
        .map((c) => CompanyInfo.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final mergedLoginCompanies = _mergeCompanyLists(loginCompanies, state.companies);
    final initialContext = await _resolveAndPersistContext(mergedLoginCompanies);

    state = state.copyWith(
      token: token,
      isAuthenticated: true,
      user: loginUser,
      roles: loginRoles.isNotEmpty ? loginRoles : state.roles,
      permissions: loginPermissions.isNotEmpty ? loginPermissions : state.permissions,
      companies: mergedLoginCompanies,
      activeCompany: initialContext.company,
      activeBranch: initialContext.branch,
      activeFinancialYear: initialContext.fy,
    );

    // Fetch full user profile, branches, fiscal years, and capabilities from /me
    await refreshMe();
    return true;
  }

  List<CompanyInfo> _mergeCompanyLists(
    List<CompanyInfo> primary,
    List<CompanyInfo> fallback,
  ) {
    final byId = <int, CompanyInfo>{};
    for (final c in fallback) {
      byId[c.id] = c;
    }
    for (final c in primary) {
      final prev = byId[c.id];
      if (prev == null) {
        byId[c.id] = c;
      } else {
        byId[c.id] = CompanyInfo(
          id: c.id,
          name: (c.name.trim().isNotEmpty && c.name != 'DK Enterprises')
              ? c.name
              : (prev.name.trim().isNotEmpty ? prev.name : c.name),
          code: (c.code ?? '').trim().isNotEmpty ? c.code : prev.code,
          industry: (c.industry != null && c.industry!.isNotEmpty && c.industry != 'general')
              ? c.industry
              : prev.industry,
          gstin: (c.gstin ?? '').trim().isNotEmpty ? c.gstin : prev.gstin,
          upiVpa: (c.upiVpa ?? '').trim().isNotEmpty ? c.upiVpa : prev.upiVpa,
          branches: c.branches.isNotEmpty ? c.branches : prev.branches,
          financialYears: c.financialYears.isNotEmpty ? c.financialYears : prev.financialYears,
        );
      }
    }
    return byId.values.toList();
  }

  Future<({CompanyInfo? company, BranchInfo? branch, FinancialYearInfo? fy})>
      _resolveAndPersistContext(List<CompanyInfo> companies) async {
    final savedCompanyId = _storage.getActiveCompanyId();
    CompanyInfo? activeComp;
    if (savedCompanyId != null) {
      activeComp = companies.cast<CompanyInfo?>().firstWhere(
            (c) => c?.id == savedCompanyId,
            orElse: () => companies.isNotEmpty ? companies.first : null,
          );
    } else if (companies.isNotEmpty) {
      activeComp = companies.first;
    }

    BranchInfo? activeBranch;
    FinancialYearInfo? activeFY;

    if (activeComp != null) {
      final savedBranchId = _storage.getActiveBranchId();
      if (savedBranchId != null) {
        activeBranch = activeComp.branches.cast<BranchInfo?>().firstWhere(
              (b) => b?.id == savedBranchId,
              orElse: () => activeComp?.branches.isNotEmpty == true ? activeComp?.branches.first : null,
            );
      } else if (activeComp.branches.isNotEmpty) {
        activeBranch = activeComp.branches.first;
      }

      final savedFYId = _storage.getActiveFinancialYearId();
      if (savedFYId != null) {
        activeFY = activeComp.financialYears.cast<FinancialYearInfo?>().firstWhere(
              (f) => f?.id == savedFYId,
              orElse: () => activeComp?.financialYears.isNotEmpty == true ? activeComp?.financialYears.first : null,
            );
      } else if (activeComp.financialYears.isNotEmpty) {
        activeFY = activeComp.financialYears.first;
      }

      await _storage.setActiveContext(
        companyId: activeComp.id,
        branchId: activeBranch?.id,
        financialYearId: activeFY?.id,
      );
    }

    return (company: activeComp, branch: activeBranch, fy: activeFY);
  }

  Future<void> syncCompaniesFromWorkspace(List<CompanyInfo> workspaceCompanies) async {
    if (workspaceCompanies.isEmpty) return;
    final merged = _mergeCompanyLists(state.companies, workspaceCompanies);
    final ctx = await _resolveAndPersistContext(merged);
    state = state.copyWith(
      companies: merged,
      activeCompany: ctx.company ?? state.activeCompany,
      activeBranch: ctx.branch ?? state.activeBranch,
      activeFinancialYear: ctx.fy ?? state.activeFinancialYear,
    );
  }

  Future<void> refreshMe() async {
    final result = await _apiClient.get(
      ApiEndpoints.me,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (result.isFailure) {
      final failure = result.failureOrNull;
      if (failure?.isUnauthorized == true) {
        await logout();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure?.message ?? 'Failed to retrieve profile',
        );
      }
      return;
    }

    final rawData = result.dataOrNull ?? <String, dynamic>{};
    final data = rawData['data'] is Map<String, dynamic>
        ? rawData['data'] as Map<String, dynamic>
        : (rawData['data'] is Map ? Map<String, dynamic>.from(rawData['data'] as Map) : rawData);
    final userJson = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    final user = userJson.isNotEmpty ? UserProfile.fromJson(userJson) : state.user;

    final roles = (data['roles'] as List<dynamic>? ?? [])
        .map((r) => r.toString())
        .toList();
    final permissions = (data['permissions'] as List<dynamic>? ?? [])
        .map((p) => p.toString())
        .toList();

    final companiesJson = data['companies'] as List<dynamic>? ?? [];
    final parsedCompanies = companiesJson
        .whereType<Map>()
        .map((c) => CompanyInfo.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final companies = _mergeCompanyLists(parsedCompanies, state.companies);

    final activeModules = (data['active_modules'] as List<dynamic>? ?? [])
        .map((m) => m.toString())
        .toList();

    final capabilities = data['capabilities'] is Map
        ? Map<String, dynamic>.from(data['capabilities'] as Map)
        : state.capabilities;

    final ctx = await _resolveAndPersistContext(companies);

    state = state.copyWith(
      isAuthenticated: true,
      isLoading: false,
      user: user,
      roles: roles.isNotEmpty ? roles : state.roles,
      permissions: permissions.isNotEmpty ? permissions : state.permissions,
      companies: companies,
      activeCompany: ctx.company,
      activeBranch: ctx.branch,
      activeFinancialYear: ctx.fy,
      activeModules: activeModules,
      capabilities: capabilities,
      errorMessage: null,
    );
  }

  Future<void> switchCompany(CompanyInfo company, {BranchInfo? branch, FinancialYearInfo? fy}) async {
    final chosenBranch = branch ?? (company.branches.isNotEmpty ? company.branches.first : null);
    final chosenFY = fy ?? (company.financialYears.isNotEmpty ? company.financialYears.first : null);

    await _storage.setActiveContext(
      companyId: company.id,
      branchId: chosenBranch?.id,
      financialYearId: chosenFY?.id,
    );

    state = state.copyWith(
      activeCompany: company,
      activeBranch: chosenBranch,
      activeFinancialYear: chosenFY,
    );
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState();
  }
}
