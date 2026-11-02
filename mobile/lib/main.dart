import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/super_admin_screen.dart';
import 'screens/field_agent_screen.dart';
import 'screens/ticket_machine_screen.dart';
import 'screens/plant_refill_screen.dart';
import 'screens/tanker_trip_sheet_screen.dart';
import 'screens/cafe_pos_screen.dart';
import 'screens/spot_audit_screen.dart';
import 'screens/role_selector_sheet.dart';
import 'screens/customers_screen.dart';
import 'screens/products_screen.dart';
import 'screens/invoices_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/tmws_vertical_screen.dart';
import 'screens/dk_waters_vertical_screen.dart';
import 'screens/aran_cafe_vertical_screen.dart';
import 'screens/financials_screen.dart';
import 'screens/fleet_gps_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DKTrackApp());
}

class DKTrackApp extends StatefulWidget {
  const DKTrackApp({super.key});

  @override
  State<DKTrackApp> createState() => _DKTrackAppState();
}

class _DKTrackAppState extends State<DKTrackApp> {
  bool _isTamil = false; // Default English as requested by user
  bool _isDarkMode = false; // Default Light mode as requested by user
  bool _isLoggedIn = false; // Starts at Login Screen for demo role access & authentication
  CompanyVertical _activeVertical = CompanyVertical.dkWaters;
  UserRole _activeRole = UserRole.superAdmin;
  String _activeUserName = 'Super Admin';

  void _toggleLanguage() {
    setState(() => _isTamil = !_isTamil);
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  void _selectVertical(CompanyVertical vertical) {
    setState(() => _activeVertical = vertical);
  }

  void _selectRole(UserRole role) {
    setState(() {
      _activeRole = role;
      if (role == UserRole.tankerDriver) {
        _activeVertical = CompanyVertical.tmws;
      } else if (role == UserRole.deliveryDriver || role == UserRole.fieldAgent) {
        _activeVertical = CompanyVertical.dkWaters;
      } else if (role == UserRole.cashier) {
        _activeVertical = CompanyVertical.aranCafe;
      }
    });
  }

  void _handleLoginSuccess(UserRole role, String userName, String token) {
    setState(() {
      _activeRole = role;
      _activeUserName = userName;
      _isLoggedIn = true;
      if (role == UserRole.tankerDriver) {
        _activeVertical = CompanyVertical.tmws;
      } else if (role == UserRole.deliveryDriver || role == UserRole.fieldAgent) {
        _activeVertical = CompanyVertical.dkWaters;
      } else if (role == UserRole.cashier) {
        _activeVertical = CompanyVertical.aranCafe;
      }
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _activeUserName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Track — Field ERP Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(_activeRole.color),
      darkTheme: AppTheme.getDarkTheme(_activeRole.color),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isLoggedIn
          ? MainNavigationShell(
              isTamil: _isTamil,
              isDarkMode: _isDarkMode,
              activeVertical: _activeVertical,
              activeRole: _activeRole,
              activeUserName: _activeUserName,
              onToggleLanguage: _toggleLanguage,
              onToggleTheme: _toggleTheme,
              onSelectVertical: _selectVertical,
              onSelectRole: _selectRole,
              onLogout: _handleLogout,
            )
          : LoginScreen(
              isTamil: _isTamil,
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
              onToggleLanguage: _toggleLanguage,
              onLoginSuccess: _handleLoginSuccess,
            ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isTamil;
  final bool isDarkMode;
  final CompanyVertical activeVertical;
  final UserRole activeRole;
  final String activeUserName;
  final VoidCallback onToggleLanguage;
  final VoidCallback onToggleTheme;
  final ValueChanged<CompanyVertical> onSelectVertical;
  final ValueChanged<UserRole> onSelectRole;
  final VoidCallback onLogout;

  const MainNavigationShell({
    super.key,
    required this.isTamil,
    required this.isDarkMode,
    required this.activeVertical,
    required this.activeRole,
    required this.activeUserName,
    required this.onToggleLanguage,
    required this.onToggleTheme,
    required this.onSelectVertical,
    required this.onSelectRole,
    required this.onLogout,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeVertical != widget.activeVertical) {
      if (widget.activeRole == UserRole.superAdmin || widget.activeRole == UserRole.admin) {
        if (widget.activeVertical == CompanyVertical.tmws) {
          _currentIndex = 1;
        } else if (widget.activeVertical == CompanyVertical.dkWaters) {
          _currentIndex = 2;
        } else if (widget.activeVertical == CompanyVertical.aranCafe) {
          _currentIndex = 3;
        }
      } else {
        _currentIndex = 0;
      }
    } else if (oldWidget.activeRole != widget.activeRole) {
      _currentIndex = 0;
    }
  }

  Color _getNavTabColor(int index, UserRole role) {
    if (role == UserRole.superAdmin || role == UserRole.admin) {
      switch (index) {
        case 0:
          return AppColors.brandPurple;
        case 1:
          return AppColors.roleTankerDriver;
        case 2:
          return AppColors.brandSky;
        case 3:
          return AppColors.roleCashier;
        case 4:
          return AppColors.brandEmerald;
        default:
          return role.color;
      }
    } else if (role == UserRole.deliveryDriver) {
      switch (index) {
        case 0:
          return AppColors.roleDeliveryDriver;
        case 1:
          return const Color(0xFF0D9488);
        case 2:
          return AppColors.brandEmerald;
        case 3:
          return AppColors.brandPurple;
        case 4:
          return AppColors.brandDanger;
        default:
          return role.color;
      }
    } else if (role == UserRole.fieldAgent) {
      switch (index) {
        case 0:
          return AppColors.roleDeliveryDriver;
        case 1:
          return AppColors.roleFieldAgent;
        case 2:
          return AppColors.brandSky;
        case 3:
          return AppColors.brandEmerald;
        case 4:
          return AppColors.brandDanger;
        default:
          return role.color;
      }
    }
    return role.color;
  }

  void _openRoleSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoleSelectorSheet(
        isTamil: widget.isTamil,
        currentRole: widget.activeRole,
        currentVertical: widget.activeVertical,
        onSelectRole: widget.onSelectRole,
        onSelectVertical: widget.onSelectVertical,
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => screen),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.brandPurple).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.brandPurple, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.brandSky).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor ?? AppColors.brandSky,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Icon(Icons.chevron_right, size: 16, color: AppColors.textDim(context)),
      onTap: onTap,
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textDim(context),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final r = widget.activeRole;
    final v = widget.activeVertical;
    final isDark = AppColors.isDark(context);

    // Role screens configuration
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    switch (r) {
      case UserRole.superAdmin:
      case UserRole.admin:
        screens = [
          SuperAdminScreen(isTamil: t, onSelectVertical: widget.onSelectVertical),
          TmwsVerticalScreen(isTamil: t),
          DkWatersVerticalScreen(isTamil: t),
          AranCafeVerticalScreen(isTamil: t),
          FleetGpsScreen(isTamil: t, activeRole: r),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: t ? 'டாஷ்போர்டு' : 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fire_truck_rounded),
            label: t ? 'TMWS பல்க்' : 'TMWS Tanker',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.water_drop_rounded),
            label: t ? 'DK குடிநீர்' : 'DK Waters',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_cafe_rounded),
            label: t ? 'அரண் கஃபே' : 'Aran Cafe',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.radar_rounded),
            label: t ? 'லைவ் GPS' : 'Live GPS',
          ),
        ];
        break;

      case UserRole.fieldAgent:
        screens = [
          TicketMachineScreen(isTamil: t),
          FieldAgentScreen(isTamil: t, vertical: v),
          CustomersScreen(isTamil: t),
          FleetGpsScreen(isTamil: t, initialMode: FleetViewMode.packagedWater, activeRole: r),
          SpotAuditScreen(isTamil: t, activeRole: r),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: t ? 'குடிநீர் விற்பனை' : 'Can Sales POS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_ind_rounded),
            label: t ? 'வசூல் & KYC' : 'Field Sales',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: t ? 'வாடிக்கையாளர்' : 'Customers',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.radar_rounded),
            label: t ? 'பீட் GPS' : 'Beat GPS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: t ? 'நேரடி தணிக்கை' : 'Jar Audit',
          ),
        ];
        break;

      case UserRole.deliveryDriver:
        screens = [
          TicketMachineScreen(isTamil: t),
          PlantRefillScreen(isTamil: t),
          FleetGpsScreen(isTamil: t, initialMode: FleetViewMode.packagedWater, activeRole: r),
          InvoicesScreen(isTamil: t),
          SpotAuditScreen(isTamil: t, activeRole: r),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: t ? 'குடிநீர் விற்பனை' : 'Can Sales POS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.factory_rounded),
            label: t ? 'ஆலை லோடிங்' : 'Plant Refill',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.radar_rounded),
            label: t ? 'பீட் GPS' : 'Beat GPS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: t ? 'விற்பனை ரசீது' : 'Sales Slips',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: t ? 'கேன் ஆய்வு' : 'Empty Audit',
          ),
        ];
        break;

      case UserRole.tankerDriver:
        screens = [
          TankerTripSheetScreen(isTamil: t),
          TmwsVerticalScreen(isTamil: t),
          FleetGpsScreen(isTamil: t, initialMode: FleetViewMode.tankers, activeRole: r),
          SpotAuditScreen(isTamil: t, activeRole: r),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.fire_truck_rounded),
            label: t ? 'டேங்கர் ட்ரிப்' : 'Tanker Trips',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_shipping_rounded),
            label: t ? 'TMWS மையம்' : 'TMWS Bulk',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.radar_rounded),
            label: t ? 'டேங்கர் GPS' : 'Tanker GPS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user_rounded),
            label: t ? 'ஸ்பாட் ஆய்வு' : 'Spot Audit',
          ),
        ];
        break;

      case UserRole.cashier:
        screens = [
          CafePosScreen(isTamil: t),
          AranCafeVerticalScreen(isTamil: t),
          SpotAuditScreen(isTamil: t, activeRole: r),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: t ? 'விரைவு பில்லிங்' : 'Touch POS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_cafe_rounded),
            label: t ? 'அரண் கஃபே' : 'Aran Cafe',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user_rounded),
            label: t ? 'டிராயர் தணிக்கை' : 'Cash Audit',
          ),
        ];
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandNavy.withOpacity(isDark ? 0.92 : 0.88),
                    AppColors.brandPurple.withOpacity(isDark ? 0.70 : 0.50),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(isDark ? 0.14 : 0.4),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: InkWell(
          onTap: (r == UserRole.superAdmin || r == UserRole.admin) ? _openRoleSelector : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: r.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: r.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(r.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.title(t),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r == UserRole.superAdmin || r == UserRole.admin)
                            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                      Text(
                        '${widget.activeUserName} • ${v.name(t)}',
                        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Live API Badge
          Tooltip(
            message: 'API: ${ApiService.activeBaseUrl}',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandEmerald.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandEmerald.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: AppColors.brandEmerald, size: 6),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: AppColors.brandEmerald, fontSize: 8.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          // Theme Toggle
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? const Color(0xFFFBBF24) : Colors.white,
              size: 19,
            ),
            onPressed: widget.onToggleTheme,
          ),
          // Language Toggle
          IconButton(
            tooltip: t ? 'Switch to English' : 'தமிழுக்கு மாறுக',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t ? 'EN' : 'தமிழ்',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            onPressed: widget.onToggleLanguage,
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Glassmorphic ERP Menus Drawer
      drawer: Drawer(
        backgroundColor: AppColors.card(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Frosted Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandNavy, AppColors.brandPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DK Track ERP',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              widget.activeUserName,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(r.title(t), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'API: ${ApiService.activeBaseUrl.replaceFirst('https://', '')}',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // GATED DRAWER SECTIONS BY ACTIVE ROLE
            if (r == UserRole.superAdmin || r == UserRole.admin) ...[
              // SECTION 1: MASTER DASHBOARD & REGISTRIES
              _buildDrawerSectionHeader(t ? 'முதன்மை மையம் & மாஸ்டர்கள்' : 'DASHBOARD & MASTERS'),
              _buildDrawerMenuItem(
                icon: Icons.dashboard,
                iconColor: AppColors.brandPurple,
                title: t ? 'முதன்மை டாஷ்போர்டு' : 'Executive Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.people_alt,
                iconColor: AppColors.brandSky,
                title: t ? 'வாடிக்கையாளர் பட்டியல் (Customers)' : 'Customers Directory',
                badge: 'Master',
                badgeColor: AppColors.brandSky,
                onTap: () => _navigateToScreen(CustomersScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.category,
                iconColor: AppColors.brandEmerald,
                title: t ? 'பொருட்கள் விலைப்பட்டியல் (Products)' : 'Products & Price Matrix',
                badge: 'Matrix',
                badgeColor: AppColors.brandEmerald,
                onTap: () => _navigateToScreen(ProductsScreen(isTamil: t)),
              ),

              Divider(color: AppColors.border(context), height: 16),

              // SECTION 2: ENTERPRISE VERTICALS
              _buildDrawerSectionHeader(t ? 'நிறுவனங்களின் போர்ட்டல்கள்' : 'ENTERPRISE VERTICALS'),
              _buildDrawerMenuItem(
                icon: Icons.fire_truck,
                iconColor: AppColors.roleTankerDriver,
                title: 'TMWS Bulk Logistics',
                badge: 'Tankers',
                badgeColor: AppColors.roleTankerDriver,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.water_drop,
                iconColor: AppColors.roleDeliveryDriver,
                title: 'DK Waters Distribution',
                badge: '20L Jars',
                badgeColor: AppColors.roleDeliveryDriver,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.point_of_sale_rounded,
                iconColor: AppColors.brandSky,
                title: t ? 'குடிநீர் விற்பனை POS (Sell Cans)' : 'Can Sales POS (Sell Cans)',
                badge: '20L POS',
                badgeColor: AppColors.brandSky,
                onTap: () => _navigateToScreen(TicketMachineScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.local_cafe,
                iconColor: AppColors.roleCashier,
                title: 'Aran Cafe & Bakery Express',
                badge: 'Cafe & POS',
                badgeColor: AppColors.roleCashier,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.radar,
                iconColor: AppColors.brandEmerald,
                title: t ? 'நேரடி GPS கப்பற்படை ரேடார்' : 'Universal Fleet GPS Radar',
                badge: 'Live Radar',
                badgeColor: AppColors.brandEmerald,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
              ),

              Divider(color: AppColors.border(context), height: 16),

              // SECTION 3: FINANCE & AUDIT
              _buildDrawerSectionHeader(t ? 'நிதி & தணிக்கை' : 'FINANCE & AUDIT'),
              _buildDrawerMenuItem(
                icon: Icons.receipt_long,
                iconColor: AppColors.brandEmerald,
                title: t ? 'விற்பனை ரசீதுகள் (Invoices)' : 'Sales Invoices & Slips',
                onTap: () => _navigateToScreen(InvoicesScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.account_balance,
                iconColor: AppColors.brandAmber,
                title: t ? 'நிதி லெட்ஜர் இருப்பு (GL 1010-1030)' : 'GL Financial Balances',
                badge: 'GL Ledger',
                badgeColor: AppColors.brandAmber,
                onTap: () => _navigateToScreen(FinancialsScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.verified_user,
                iconColor: AppColors.brandDanger,
                title: t ? 'களத் தணிக்கை & மோசடி எதிர்ப்பு' : 'Anti-Theft Field Spot Audit',
                badge: 'Audit',
                badgeColor: AppColors.brandDanger,
                onTap: () => _navigateToScreen(SpotAuditScreen(isTamil: t, activeRole: r)),
              ),

              Divider(color: AppColors.border(context), height: 16),

              // SECTION 4: ROLES & ENTERPRISES
              _buildDrawerSectionHeader(t ? 'பாத்திரங்கள் & நிறுவனங்கள்' : 'ROLES & ENTERPRISES'),
              _buildDrawerMenuItem(
                icon: Icons.switch_account,
                iconColor: r.color,
                title: t ? 'பாத்திரத்தை மாற்று (Role Selector)' : 'Switch Active Role',
                badge: r.title(t),
                badgeColor: r.color,
                onTap: () {
                  Navigator.pop(context);
                  _openRoleSelector();
                },
              ),
            ] else if (r == UserRole.deliveryDriver) ...[
              // DK WATERS DELIVERY DRIVER ONLY
              _buildDrawerSectionHeader(t ? 'DK குடிநீர் விநியோகம்' : 'DK WATERS LOGISTICS'),
              _buildDrawerMenuItem(
                icon: Icons.point_of_sale_rounded,
                iconColor: AppColors.roleDeliveryDriver,
                title: t ? 'குடிநீர் விற்பனை POS (Sell Cans)' : 'Can Sales POS (Sell Cans)',
                badge: 'POS',
                badgeColor: AppColors.roleDeliveryDriver,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.factory,
                iconColor: const Color(0xFF0D9488),
                title: t ? 'ஆலை லோடிங் & காலி கேன்கள்' : 'Plant Refill & Gate Passes',
                badge: 'Plant',
                badgeColor: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.radar,
                iconColor: AppColors.brandEmerald,
                title: t ? 'நேரலை பீட் GPS ரேடார்' : 'Beat Delivery GPS Radar',
                badge: 'Live',
                badgeColor: AppColors.brandEmerald,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.receipt_long,
                iconColor: AppColors.brandPurple,
                title: t ? 'இன்றைய விநியோக ரசீதுகள்' : 'Today Delivery Invoices',
                badge: 'Slips',
                badgeColor: AppColors.brandPurple,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.people_alt,
                iconColor: AppColors.brandSky,
                title: t ? 'வழித்தட வாடிக்கையாளர்கள்' : 'Route Customers Directory',
                onTap: () => _navigateToScreen(CustomersScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.verified_user,
                iconColor: AppColors.brandDanger,
                title: t ? 'காலி கேன் இருப்பு ஆய்வு' : 'Empty Jar Audit',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
              ),
            ] else if (r == UserRole.fieldAgent) ...[
              // DK WATERS FIELD AGENT ONLY
              _buildDrawerSectionHeader(t ? 'கள விற்பனை & KYC' : 'DK WATERS SALES & KYC'),
              _buildDrawerMenuItem(
                icon: Icons.point_of_sale_rounded,
                iconColor: AppColors.roleDeliveryDriver,
                title: t ? 'குடிநீர் விற்பனை POS (Sell Cans)' : 'Can Sales POS (Sell Cans)',
                badge: 'POS',
                badgeColor: AppColors.roleDeliveryDriver,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.assignment_ind,
                iconColor: AppColors.roleFieldAgent,
                title: t ? 'கள விற்பனை, KYC & வசூல்' : 'Field Sales & Collections',
                badge: 'KYC',
                badgeColor: AppColors.roleFieldAgent,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.people_alt,
                iconColor: AppColors.brandSky,
                title: t ? 'வாடிக்கையாளர் பட்டியல்' : 'Customers Directory',
                badge: 'Directory',
                badgeColor: AppColors.brandSky,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.radar,
                iconColor: AppColors.brandEmerald,
                title: t ? 'நேரலை பீட் GPS ரேடார்' : 'Beat Delivery GPS Radar',
                badge: 'Live',
                badgeColor: AppColors.brandEmerald,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.receipt_long,
                iconColor: AppColors.brandPurple,
                title: t ? 'விற்பனை & வசூல் ரசீதுகள்' : 'Invoices & Slips',
                onTap: () => _navigateToScreen(InvoicesScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.inventory_2,
                iconColor: AppColors.brandDanger,
                title: t ? 'கேன் லெட்ஜர் தணிக்கை' : 'Jar Ledger Spot Audit',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
              ),
            ] else if (r == UserRole.tankerDriver) ...[
              // TMWS BULK TANKER DRIVER ONLY
              _buildDrawerSectionHeader(t ? 'TMWS பல்க் டேங்கர் தளவாடங்கள்' : 'TMWS BULK LOGISTICS'),
              _buildDrawerMenuItem(
                icon: Icons.fire_truck,
                iconColor: AppColors.roleTankerDriver,
                title: t ? 'டேங்கர் ட்ரிப் ஷீட் பதிவு' : 'Tanker Trip Sheet',
                badge: 'Trip Sheet',
                badgeColor: AppColors.roleTankerDriver,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.local_shipping,
                iconColor: const Color(0xFF2563EB),
                title: t ? 'TMWS பல்க் மையம் & பதிவுகள்' : 'TMWS Bulk Hub & Trips',
                badge: 'Hub',
                badgeColor: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.radar,
                iconColor: AppColors.brandEmerald,
                title: t ? 'டேங்கர் நேரலை GPS ரேடார்' : 'Live Tanker GPS Radar',
                badge: 'Live',
                badgeColor: AppColors.brandEmerald,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.verified_user,
                iconColor: AppColors.brandDanger,
                title: t ? 'ஓடோமீட்டர் & எரிபொருள் சரிபார்ப்பு' : 'Odometer & Diesel Check',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
            ] else if (r == UserRole.cashier) ...[
              // ARAN CAFE CASHIER ONLY
              _buildDrawerSectionHeader(t ? 'அரண் கஃபே & பேக்கரி' : 'ARAN CAFE & BAKERY'),
              _buildDrawerMenuItem(
                icon: Icons.point_of_sale,
                iconColor: AppColors.roleCashier,
                title: t ? 'விரைவு டச் பில்லிங் (POS)' : 'Express Touch POS Counter',
                badge: 'Counter',
                badgeColor: AppColors.roleCashier,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.local_cafe,
                iconColor: const Color(0xFFD97706),
                title: t ? 'அரண் கஃபே போர்ட்டல்' : 'Aran Cafe Portal',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              _buildDrawerMenuItem(
                icon: Icons.category,
                iconColor: AppColors.brandEmerald,
                title: t ? 'மெனு & பொருட்கள் விலை' : 'Menu & Product Catalog',
                onTap: () => _navigateToScreen(ProductsScreen(isTamil: t)),
              ),
              _buildDrawerMenuItem(
                icon: Icons.verified_user,
                iconColor: AppColors.brandDanger,
                title: t ? 'ரொக்க டிராயர் தணிக்கை' : 'Cash Drawer Shift Audit',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
            ],

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 6: Session & Logout
            ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandDanger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: AppColors.brandDanger, size: 18),
              ),
              title: Text(
                t ? 'வெளியேறு (Logout Session)' : 'Sign Out (Logout)',
                style: GoogleFonts.inter(color: AppColors.brandDanger, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t ? 'வெற்றிகரமாக வெளியேறினீர்கள்' : 'Logged out successfully',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppColors.brandDanger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      extendBody: true,

      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),

      // Modern Floating Pill Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.brandNavy.withOpacity(0.92),
                            AppColors.brandPurple.withOpacity(0.85),
                          ]
                        : [
                            Colors.white.withOpacity(0.95),
                            const Color(0xFFF3E8FF).withOpacity(0.92),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.20) : AppColors.brandPurple.withOpacity(0.30),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: r.color.withOpacity(isDark ? 0.35 : 0.20),
                      blurRadius: 22,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isSelected = (_currentIndex < navItems.length ? _currentIndex : 0) == index;
                    final tabColor = _getNavTabColor(index, r);

                    return InkWell(
                      onTap: () => setState(() => _currentIndex = index),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 12 : 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? tabColor.withOpacity(0.28) : tabColor.withOpacity(0.18))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: isSelected
                              ? Border.all(
                                  color: isDark ? tabColor.withOpacity(0.65) : tabColor.withOpacity(0.45),
                                  width: 1.2,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (item.icon as Icon).icon,
                              color: isSelected
                                  ? (isDark ? Colors.white : tabColor)
                                  : (isDark ? Colors.white60 : AppColors.textDim(context)),
                              size: isSelected ? 19 : 21,
                            ),
                            if (isSelected && item.label != null) ...[
                              const SizedBox(width: 5),
                              Text(
                                item.label!,
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : tabColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
