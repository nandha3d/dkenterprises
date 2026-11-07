library;

/// Authentication Domain Models for Zolo ERP Mobile.

class BranchInfo {
  final int id;
  final String name;
  final String? code;

  const BranchInfo({
    required this.id,
    required this.name,
    this.code,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 'Main Branch',
      code: json['code']?.toString(),
    );
  }
}

class FinancialYearInfo {
  final int id;
  final String name;
  final bool isCurrent;

  const FinancialYearInfo({
    required this.id,
    required this.name,
    this.isCurrent = false,
  });

  factory FinancialYearInfo.fromJson(Map<String, dynamic> json) {
    return FinancialYearInfo(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: (json['financial_year'] ?? json['name'])?.toString() ?? 'FY Current',
      isCurrent: json['is_current'] == true || json['is_current'] == 1,
    );
  }
}

class CompanyInfo {
  final int id;
  final String name;
  final String? code;
  final String? industry;
  final List<BranchInfo> branches;
  final List<FinancialYearInfo> financialYears;

  const CompanyInfo({
    required this.id,
    required this.name,
    this.code,
    this.industry,
    this.branches = const [],
    this.financialYears = const [],
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    final branchesJson = json['branches'] as List<dynamic>? ?? [];
    final fyJson = (json['financial_years'] ?? json['open_financial_years']) as List<dynamic>? ?? [];

    return CompanyInfo(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 'Company',
      code: json['code']?.toString(),
      industry: json['industry']?.toString(),
      branches: branchesJson.map((b) => BranchInfo.fromJson(b as Map<String, dynamic>)).toList(),
      financialYears: fyJson.map((f) => FinancialYearInfo.fromJson(f as Map<String, dynamic>)).toList(),
    );
  }
}

class UserProfile {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? phone;
  final String role;

  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'user',
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final UserProfile? user;
  final List<String> roles;
  final List<String> permissions;
  final List<CompanyInfo> companies;
  final CompanyInfo? activeCompany;
  final BranchInfo? activeBranch;
  final FinancialYearInfo? activeFinancialYear;
  final List<String> activeModules;
  final Map<String, dynamic> capabilities;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.roles = const [],
    this.permissions = const [],
    this.companies = const [],
    this.activeCompany,
    this.activeBranch,
    this.activeFinancialYear,
    this.activeModules = const [],
    this.capabilities = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  bool hasPermission(String permission) {
    if (permissions.contains('*') || roles.contains('admin') || roles.contains('super_admin')) {
      return true;
    }
    return permissions.contains(permission);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    UserProfile? user,
    List<String>? roles,
    List<String>? permissions,
    List<CompanyInfo>? companies,
    CompanyInfo? activeCompany,
    BranchInfo? activeBranch,
    FinancialYearInfo? activeFinancialYear,
    List<String>? activeModules,
    Map<String, dynamic>? capabilities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      companies: companies ?? this.companies,
      activeCompany: activeCompany ?? this.activeCompany,
      activeBranch: activeBranch ?? this.activeBranch,
      activeFinancialYear: activeFinancialYear ?? this.activeFinancialYear,
      activeModules: activeModules ?? this.activeModules,
      capabilities: capabilities ?? this.capabilities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
