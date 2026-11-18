import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerSettings() {
    final storage = ref.read(secureStorageProvider);
    final apiClient = ref.read(apiClientProvider);
    final urlController = TextEditingController(text: storage.getServerUrl());
    String? testResult;
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, size: 22),
              SizedBox(width: 8),
              Text('ERP Server Settings', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the backend API base endpoint:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://dk-track.test/api/v1',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Local Laragon (dk-track.test)', style: TextStyle(fontSize: 11)),
                    onPressed: () => setModalState(() {
                      urlController.text = 'http://dk-track.test/api/v1';
                    }),
                  ),
                  ActionChip(
                    label: const Text('Local Artisan (127.0.0.1:8000)', style: TextStyle(fontSize: 11)),
                    onPressed: () => setModalState(() {
                      urlController.text = 'http://127.0.0.1:8000/api/v1';
                    }),
                  ),
                  ActionChip(
                    label: const Text('Cloud Production', style: TextStyle(fontSize: 11)),
                    onPressed: () => setModalState(() {
                      urlController.text = 'https://dkenterprises.animazon.in/api/v1';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (testResult != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: testResult!.contains('Success')
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      color: testResult!.contains('Success')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: isTesting
                    ? null
                    : () async {
                        setModalState(() {
                          isTesting = true;
                          testResult = null;
                        });
                        try {
                          final targetUrl = urlController.text.trim();
                          final dio = Dio(BaseOptions(
                            connectTimeout: const Duration(seconds: 8),
                            receiveTimeout: const Duration(seconds: 8),
                          ));
                          final cleanUrl = targetUrl.endsWith('/')
                              ? targetUrl.substring(0, targetUrl.length - 1)
                              : targetUrl;
                          final endpoint = cleanUrl.endsWith('/api/v1')
                              ? '$cleanUrl/health'
                              : (cleanUrl.endsWith('/')
                                  ? '${cleanUrl}api/v1/health'
                                  : '$cleanUrl/api/v1/health');
                          final res = await dio.get(endpoint);
                          setModalState(() {
                            isTesting = false;
                            testResult =
                                'Success: ERP Server Online (${res.statusCode} OK)';
                          });
                        } catch (e) {
                          setModalState(() {
                            isTesting = false;
                            testResult = 'Connection failed: $e';
                          });
                        }
                      },
                icon: isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 16),
                label: const Text('Test Server Connection'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = urlController.text.trim();
                if (newUrl.isNotEmpty) {
                  await storage.setServerUrl(newUrl);
                  apiClient.updateBaseUrl(newUrl);
                  if (mounted) {
                    setState(() {});
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server endpoint set to $newUrl')),
                    );
                  }
                }
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _populateDemoRole(String roleName, String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signing in as $roleName ($username)...'),
        duration: const Duration(seconds: 2),
      ),
    );
    _handleLogin();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.companies.length <= 1) {
        context.go('/home');
      } else {
        context.go('/workspace');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: skin.canvas,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Lagoon Brand Hero (Stitch G-02 - Full-bleed banner with centered 460px inner frame)
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 16,
                  bottom: 48,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lagoonPrimary, Color(0xFF063C35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      right: -40,
                      top: -30,
                      child: IgnorePointer(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                              width: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Utility Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.domain_rounded,
                                                size: 13,
                                                color: AppColors.lagoonAction),
                                            SizedBox(width: 5),
                                            Text(
                                              'DK Group',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.rippleMint
                                              .withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle,
                                                size: 7,
                                                color: AppColors.lagoonAction),
                                            SizedBox(width: 5),
                                            Text(
                                              'Live',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: _showServerSettings,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.12),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.settings_outlined,
                                        size: 18),
                                    tooltip: 'ERP Server Settings',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              // Centered Crest Badge
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.lagoonAction
                                        .withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  size: 30,
                                  color: AppColors.lagoonAction,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'DK Enterprises',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enterprise Field Mobile · powered by ZOLO ERP',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Overlapping Login Card + Fast-Login Grid (Exact matching 460px frame + 16px horizontal padding)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: skin.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: skin.hairline),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account Login',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: skin.ink,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Enter your assigned operational credentials',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: skin.muted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: skin.surface2,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.lock_person_rounded,
                                        size: 20,
                                        color: skin.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                if (authState.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.rippleRuby
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.rippleRuby
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 18,
                                          color: AppColors.rippleRuby,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authState.errorMessage!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.rippleRuby,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                Text(
                                  'Username / Phone',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: skin.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _usernameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. admin or +91 98421...',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: skin.muted,
                                    ),
                                    filled: true,
                                    fillColor: skin.surface2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                          ? 'Please enter username or phone'
                                          : null,
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: skin.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(
                                      Icons.key_rounded,
                                      color: skin.muted,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: skin.muted,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: skin.surface2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.isEmpty)
                                          ? 'Please enter your password'
                                          : null,
                                ),
                                const SizedBox(height: 18),

                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _handleLogin,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.lagoonPrimary,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign In to Account',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward_rounded,
                                                  size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3. Demo Role Fast-Login Options Grid (Stitch G-02)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Demo Role Fast-Login Options',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: skin.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '1-Tap Fill',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: skin.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Admin Console Full-Width Tile
                          _buildRoleTile(
                            skin: skin,
                            title: 'Admin',
                            subtitle: 'Multi-Company · Lagoon Executive Desk',
                            icon: Icons.shield_outlined,
                            accent: AppColors.lagoonPrimary,
                            onTap: () =>
                                _populateDemoRole('Admin', 'admin', 'admin'),
                            fullWidth: true,
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleTile(
                                  skin: skin,
                                  title: 'Can Driver',
                                  subtitle: 'Water Can Route Beat',
                                  icon: Icons.water_drop_outlined,
                                  accent: AppColors.aquaPrimary,
                                  onTap: () => _populateDemoRole(
                                      'Can Driver', 'driver', 'driver123'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRoleTile(
                                  skin: skin,
                                  title: 'Tanker Driver',
                                  subtitle: 'Bulk KL Trips',
                                  icon: Icons.local_shipping_outlined,
                                  accent: AppColors.aquaPrimary,
                                  onTap: () => _populateDemoRole('Tanker Driver',
                                      'tanker_driver', 'driver123'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleTile(
                                  skin: skin,
                                  title: 'Cafe Cashier',
                                  subtitle: 'Touch POS & KOT',
                                  icon: Icons.local_cafe_outlined,
                                  accent: AppColors.chaiPrimary,
                                  onTap: () => _populateDemoRole(
                                      'Cafe Cashier', 'cashier', 'cashier123'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRoleTile(
                                  skin: skin,
                                  title: 'Field Agent',
                                  subtitle: 'Collection & GPS',
                                  icon: Icons.pin_drop_outlined,
                                  accent: AppColors.sagePrimary,
                                  onTap: () => _populateDemoRole(
                                      'Field Agent', 'agent', 'agent123'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 4. Footer Status Capsule
                          Center(
                            child: InkWell(
                              onTap: _showServerSettings,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: skin.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: skin.hairline),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 8, color: AppColors.rippleMint),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Server Status: Online · API v1.0 Connected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: skin.ink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Secure Multi-Tenant Sanctum v1 Engine',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: skin.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile({
    required RippleSkin skin,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Material(
      color: skin.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: skin.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (fullWidth)
                Icon(Icons.chevron_right_rounded, size: 18, color: skin.muted),
            ],
          ),
        ),
      ),
    );
  }
}
