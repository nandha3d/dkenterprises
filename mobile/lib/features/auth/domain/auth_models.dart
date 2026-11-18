library;

/// Authentication Domain Models for Zolo ERP Mobile.

String _firstNonEmpty(List<dynamic> candidates, String fallback) {
  for (final candidate in candidates) {
    final s = candidate?.toString().trim() ?? '';
    if (s.isNotEmpty && s.toLowerCase() != 'null') {
      return s;
    }
  }
  return fallback;
}

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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 1,
      name: _firstNonEmpty([json['name'], json['code']], 'Main Branch'),
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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 1,
      name: _firstNonEmpty([json['financial_year'], json['name']], 'FY Current'),
      isCurrent: json['is_current'] == true || json['is_current'] == 1,
    );
  }
}

class CompanyInfo {
  final int id;
  final String name;
  final String? code;
  final String? industry;
  final String? gstin;
  final String? upiVpa;
  final List<BranchInfo> branches;
  final List<FinancialYearInfo> financialYears;

  const CompanyInfo({
    required this.id,
    required this.name,
    this.code,
    this.industry,
    this.gstin,
    this.upiVpa,
    this.branches = const [],
    this.financialYears = const [],
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    final branchesJson = json['branches'] as List<dynamic>? ?? [];
    final fyJson = (json['fiscal_years'] ?? json['financial_years'] ?? json['open_financial_years']) as List<dynamic>? ?? [];
    final resolvedIndustry = _firstNonEmpty(
      [json['industry'], json['profile_key']],
      'general',
    );

    return CompanyInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 1,
      name: _firstNonEmpty(
        [json['trade_name'], json['name'], json['legal_name'], json['code']],
        'DK Enterprises',
      ),
      code: json['code']?.toString(),
      industry: resolvedIndustry,
      gstin: json['gstin']?.toString(),
      upiVpa: json['upi_vpa']?.toString(),
      branches: branchesJson
          .whereType<Map>()
          .map((b) => BranchInfo.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      financialYears: fyJson
          .whereType<Map>()
          .map((f) => FinancialYearInfo.fromJson(Map<String, dynamic>.from(f)))
          .toList(),
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
  final String roleLabel;

  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    required this.role,
    this.roleLabel = '',
  });

  static const Map<String, String> _canonicalNames = {
    'tanker_driver': 'K. Murugan',
    'tanker': 'K. Murugan',
    'tankerdriver': 'K. Murugan',
    'driver': 'S. Karthik',
    'can_driver': 'S. Karthik',
    'can_delivery': 'S. Karthik',
    'candelivery': 'S. Karthik',
    'delivery_driver': 'S. Karthik',
    'deliverydriver': 'S. Karthik',
    'cashier': 'A. Priya',
    'agent': 'R. Senthil',
    'field_agent': 'R. Senthil',
    'fieldagent': 'R. Senthil',
    'admin': 'DK Super Admin',
    'super_admin': 'DK Super Admin',
    'superadmin': 'DK Super Admin',
  };

  static bool looksLikeRoleSlug(String? value) {
    final trimmed = (value ?? '').trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (_canonicalNames.containsKey(trimmed)) return true;
    return RegExp(r'^[a-z0-9]+(_[a-z0-9]+)+$').hasMatch(trimmed);
  }

  static String humanizeName(String raw, String roleSlug) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isNotEmpty && !looksLikeRoleSlug(trimmed)) {
      return trimmed;
    }
    if (_canonicalNames.containsKey(lower)) {
      return _canonicalNames[lower]!;
    }
    final roleLower = roleSlug.trim().toLowerCase();
    if (_canonicalNames.containsKey(roleLower)) {
      return _canonicalNames[roleLower]!;
    }
    if (trimmed.isNotEmpty) {
      return trimmed
          .split(RegExp(r'[_\s-]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }
    return roleDisplayLabel(roleSlug);
  }

  static String roleDisplayLabel(String roleSlug) {
    return switch (roleSlug.trim().toLowerCase()) {
      'tankerdriver' || 'tanker_driver' => 'Bulk Tanker Driver',
      'deliverydriver' ||
      'delivery_driver' ||
      'can_delivery' ||
      'candelivery' ||
      'can_driver' ||
      'driver' =>
        'Water Can Delivery Driver',
      'cashier' => 'Cafe POS Cashier',
      'fieldagent' || 'field_agent' || 'agent' => 'Field Collection Incharge',
      'superadmin' || 'super_admin' || 'admin' => 'Super Admin',
      _ => 'Operations Staff',
    };
  }

  String get displayName => humanizeName(name, role);
  String get effectiveRoleLabel => roleLabel.isNotEmpty ? roleLabel : roleDisplayLabel(role);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawUsername = (json['username'] ?? json['name'])?.toString() ?? '';
    final rawName = (json['display_name'] ?? json['name'])?.toString() ?? '';
    final resolvedRole = (json['role_slug'] ?? json['role'])?.toString() ?? 'user';
    final cleanName = humanizeName(rawName, resolvedRole);
    return UserProfile(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: cleanName,
      username: rawUsername,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: resolvedRole,
      roleLabel: json['role_label']?.toString() ?? roleDisplayLabel(resolvedRole),
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
