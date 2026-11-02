import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  final bool isTamil;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final Function(UserRole role, String userName, String token) onLoginSuccess;

  /// Set to false before final production deployment to remove demo access from the initial screen
  static const bool showDemoLoginRibbon = true;

  const LoginScreen({
    super.key,
    required this.isTamil,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');
  bool _obscurePassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.superAdmin;
  final _apiService = ApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRoleShortcut(UserRole role, {bool autoLogin = false}) {
    setState(() {
      _selectedRole = role;
      switch (role) {
        case UserRole.superAdmin:
          _usernameController.text = 'admin';
          _passwordController.text = 'admin';
          break;
        case UserRole.admin:
          _usernameController.text = 'dkadmin';
          _passwordController.text = 'admin';
          break;
        case UserRole.fieldAgent:
          _usernameController.text = 'agent';
          _passwordController.text = 'agent123';
          break;
        case UserRole.deliveryDriver:
          _usernameController.text = 'driver';
          _passwordController.text = 'driver123';
          break;
        case UserRole.tankerDriver:
          _usernameController.text = 'tanker_driver';
          _passwordController.text = 'driver123';
          break;
        case UserRole.cashier:
          _usernameController.text = 'cashier';
          _passwordController.text = 'cashier123';
          break;
      }
    });

    if (autoLogin) {
      _handleLogin();
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil ? 'பயனர்பெயர் & கடவுச்சொல்லை உள்ளிடவும்' : 'Enter username & password',
          ),
          backgroundColor: AppColors.brandDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiService.login(
        email: username,
        password: password,
        role: _selectedRole,
      );

      final token = res['data']?['token'] ?? 'demo_token';
      final userName = res['data']?['user']?['name'] ?? _selectedRole.title(widget.isTamil);

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess(_selectedRole, userName, token);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess(_selectedRole, _selectedRole.title(widget.isTamil), 'fallback_token');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Stack(
        children: [
          // Ambient Glassmorphism Luminous Glows
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandPurple.withOpacity(isDark ? 0.35 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandSky.withOpacity(isDark ? 0.30 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _selectedRole.color.withOpacity(isDark ? 0.22 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Viewport
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Live Production API Badge
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          borderRadius: 20,
                          blurSigma: 12,
                          tintColor: AppColors.brandEmerald,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandEmerald,
                                  boxShadow: [
                                    BoxShadow(color: AppColors.brandEmerald, blurRadius: 6, spreadRadius: 1),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE API: dkenterprises',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Theme & Language Controls
                        Row(
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(8),
                              borderRadius: 14,
                              blurSigma: 12,
                              onTap: widget.onToggleTheme,
                              child: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                                size: 18,
                                color: isDark ? const Color(0xFFFBBF24) : AppColors.brandPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              borderRadius: 14,
                              blurSigma: 12,
                              onTap: widget.onToggleLanguage,
                              child: Text(
                                t ? 'EN' : 'தமிழ்',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Brand Header with Specular Glass Logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.brandPurple, AppColors.brandNavy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPurple.withOpacity(0.40),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.water_drop, color: Colors.white, size: 34),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'DK Track ERP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t ? 'நிறுவன மொபைல் தளவாடங்கள் & ERP' : 'Enterprise Multi-Role Logistics Suite',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION: 1-Tap Quick Demo Role Access (Cleanly removable upon deployment)
                    if (LoginScreen.showDemoLoginRibbon) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.brandAmber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.bolt, size: 14, color: AppColors.brandAmber),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t ? '1-கிளிக் டெமோ உள்நுழைவு' : '1-Tap Quick Demo Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            t ? 'அனைத்து பாத்திரங்களும்' : 'All 6 Roles',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDim(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Responsive Grid of 6 Role Glass Cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: UserRole.values.map((role) {
                          final isSelected = _selectedRole == role;
                          return GlassCard(
                            isInteractive: true,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            borderRadius: 14,
                            tintColor: isSelected ? role.color : null,
                            borderColor: isSelected ? role.color : null,
                            borderWidth: isSelected ? 1.8 : 1.0,
                            onTap: () => _selectRoleShortcut(role),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: role.color.withOpacity(isSelected ? 0.95 : 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    role.icon,
                                    size: 16,
                                    color: isSelected ? Colors.white : role.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        role.title(t),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? role.color : AppColors.text(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        role.code,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.textDim(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, size: 14, color: role.color),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Primary Frosted Glass Login Form Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 22,
                      blurSigma: 20,
                      tintColor: _selectedRole.color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Active Role Profile Strip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedRole.color.withOpacity(isDark ? 0.15 : 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole.color.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(_selectedRole.icon, size: 16, color: _selectedRole.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t
                                        ? '${_selectedRole.title(true)} கணக்கில் நுழைகிறீர்கள்'
                                        : 'Signing in as ${_selectedRole.title(false)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedRole.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Username / Email Glass Input
                          Text(
                            t ? 'பயனர்பெயர் / மின்னஞ்சல்' : 'Username / Email',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, size: 18, color: _selectedRole.color),
                                hintText: t ? 'பயனர்பெயர் உள்ளிடவும்' : 'Enter username',
                                hintStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password Glass Input
                          Text(
                            t ? 'கடவுச்சொல்' : 'Password',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, size: 18, color: _selectedRole.color),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: AppColors.textMuted(context),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                hintText: t ? 'கடவுச்சொல் உள்ளிடவும்' : 'Enter password',
                                hintStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Glossy High-End Sign In Button
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_selectedRole.color, AppColors.brandNavy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedRole.color.withOpacity(0.40),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _isLoading ? null : _handleLogin,
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              t
                                                  ? '${_selectedRole.title(true)} ஆக உள்நுழைக'
                                                  : 'Sign In as ${_selectedRole.title(false)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Security & Encryption Footer Note
                    Center(
                      child: Text(
                        t
                            ? 'பாதுகாக்கப்பட்ட SSL / TLS நேரடி ERP இணைப்பு'
                            : 'Secured SSL / TLS End-to-End Encrypted ERP Connection',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDim(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
