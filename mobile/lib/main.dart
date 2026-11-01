import 'package:flutter/material.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/super_admin_screen.dart';
import 'screens/admin_screen.dart';
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
import 'screens/financials_screen.dart';

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
  bool _isTamil = true; // Default Tamil for field ground operators
  bool _isDarkMode = false; // Default to crisp sunlight-optimized Light Theme!
  bool _isLoggedIn = false; // Starts at Login Screen for role selection & credentials authentication
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
      } else if (role == UserRole.deliveryDriver) {
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
      } else if (role == UserRole.deliveryDriver) {
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
    if (oldWidget.activeVertical != widget.activeVertical || oldWidget.activeRole != widget.activeRole) {
      _currentIndex = 0;
    }
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
      leading: Icon(icon, color: iconColor ?? AppColors.textMuted(context), size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.text(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? const Color(0xFF0284C7)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor ?? const Color(0xFF0284C7),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final r = widget.activeRole;
    final v = widget.activeVertical;

    // Role screens configuration
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    switch (r) {
      case UserRole.superAdmin:
        screens = [
          SuperAdminScreen(isTamil: t, onSelectVertical: widget.onSelectVertical),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.admin_panel_settings),
            label: t ? 'குரூப் மேற்பார்வை' : 'Group Command',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: t ? 'மோசடி தணிக்கை' : 'Audit Radar',
          ),
        ];
        break;

      case UserRole.admin:
        screens = [
          AdminScreen(isTamil: t, vertical: v),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_center),
            label: t ? 'நிறுவன அட்மின்' : 'Operations',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: t ? 'ஸ்பாட் ஆய்வு' : 'Spot Audit',
          ),
        ];
        break;

      case UserRole.fieldAgent:
        screens = [
          FieldAgentScreen(isTamil: t, vertical: v),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_ind),
            label: t ? 'வசூல் & KYC' : 'Field Sales',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2),
            label: t ? 'நேரடி தணிக்கை' : 'Jar Audit',
          ),
        ];
        break;

      case UserRole.deliveryDriver:
        screens = [
          TicketMachineScreen(isTamil: t),
          PlantRefillScreen(isTamil: t),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.water_drop),
            label: t ? 'குடிநீர் டிக்கெட்' : 'Delivery Ticket',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.factory),
            label: t ? 'ஆலை லோடிங்' : 'Plant Refill',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: t ? 'கேன் ஆய்வு' : 'Empty Audit',
          ),
        ];
        break;

      case UserRole.tankerDriver:
        screens = [
          TankerTripSheetScreen(isTamil: t),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.fire_truck),
            label: t ? 'டேங்கர் ட்ரிப்' : 'Tanker Trips',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: t ? 'ஸ்பாட் தணிக்கை' : 'Spot Audit',
          ),
        ];
        break;

      case UserRole.cashier:
        screens = [
          CafePosScreen(isTamil: t),
          SpotAuditScreen(isTamil: t),
        ];
        navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.point_of_sale),
            label: t ? 'விரைவு பில்லிங்' : 'Touch POS',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: t ? 'டிராயர் தணிக்கை' : 'Cash Audit',
          ),
        ];
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white70),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: InkWell(
          onTap: _openRoleSelector,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: r.color,
                    borderRadius: BorderRadius.circular(6),
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                      Text(
                        '${widget.activeUserName} • ${v.name(t)}',
                        style: TextStyle(fontSize: 10, color: v.primaryColor, fontWeight: FontWeight.w600),
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
          // Live API ping indicator chip
          Tooltip(
            message: 'Target API: ${ApiService.activeBaseUrl}',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                  SizedBox(width: 4),
                  Text('API LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Theme Toggle Button (☀️ Light / 🌙 Dark)
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: widget.isDarkMode ? Colors.amber : Colors.white70,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          // Language toggle
          IconButton(
            tooltip: t ? 'Switch to English' : 'தமிழுக்கு மாறுக',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t ? 'EN' : 'தமிழ்',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            onPressed: widget.onToggleLanguage,
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Comprehensive ERP Menus Navigation Drawer
      drawer: Drawer(
        backgroundColor: AppColors.card(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [r.color, const Color(0xFF0F172A)],
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DK Track ERP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            widget.activeUserName,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(r.title(t), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'API: ${ApiService.activeBaseUrl}',
                      style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // SECTION 1: ERP Executive & Operations
            _buildDrawerSectionHeader(t ? 'கட்டளை மையம் & மாஸ்டர்கள்' : 'COMMAND & MASTERS'),
            _buildDrawerMenuItem(
              icon: Icons.dashboard,
              iconColor: const Color(0xFF8B5CF6),
              title: t ? 'முதன்மை டாஷ்போர்டு' : 'Executive Dashboard',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            _buildDrawerMenuItem(
              icon: Icons.people_alt,
              iconColor: const Color(0xFF0EA5E9),
              title: t ? 'வாடிக்கையாளர் பட்டியல் (Customers)' : 'Customers Directory',
              badge: 'ERP Master',
              badgeColor: const Color(0xFF0EA5E9),
              onTap: () => _navigateToScreen(CustomersScreen(isTamil: t)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.category,
              iconColor: const Color(0xFF10B981),
              title: t ? 'பொருட்கள் விலைப்பட்டியல் (Products)' : 'Products & Price Matrix',
              badge: 'Matrix',
              badgeColor: const Color(0xFF10B981),
              onTap: () => _navigateToScreen(ProductsScreen(isTamil: t)),
            ),

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 2: Water Logistics Suite
            _buildDrawerSectionHeader(t ? 'குடிநீர் தளவாடங்கள் (WATER LOGISTICS)' : 'WATER LOGISTICS SUITE'),
            _buildDrawerMenuItem(
              icon: Icons.water_drop,
              iconColor: const Color(0xFF0284C7),
              title: t ? 'குடிநீர் விநியோக டிக்கெட் (<15s)' : 'Packaged Water Delivery',
              badge: 'Fast Ticketing',
              badgeColor: const Color(0xFF0284C7),
              onTap: () => _navigateToScreen(TicketMachineScreen(isTamil: t)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.fire_truck,
              iconColor: const Color(0xFF2563EB),
              title: t ? 'பல்க் டேங்கர் ட்ரிப் & இறக்குதல்' : 'Bulk Tanker Trips & Decanting',
              badge: 'TMWS Fleet',
              badgeColor: const Color(0xFF2563EB),
              onTap: () => _navigateToScreen(TankerTripSheetScreen(isTamil: t)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.factory,
              iconColor: const Color(0xFF0D9488),
              title: t ? 'ஆலை லோடிங் & கேட் பாஸ்' : 'Plant Refill & Gate Passes',
              onTap: () => _navigateToScreen(PlantRefillScreen(isTamil: t)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.verified_user,
              iconColor: const Color(0xFFDC2626),
              title: t ? 'கேன் ஆய்வு & இருப்பு தணிக்கை' : 'Empty Jar Custody & Audit',
              badge: 'Anti-Theft',
              badgeColor: const Color(0xFFDC2626),
              onTap: () => _navigateToScreen(SpotAuditScreen(isTamil: t)),
            ),

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 3: Sales, Invoicing & Accounts
            _buildDrawerSectionHeader(t ? 'விற்பனை & கணக்குகள் (FINANCE & ACCOUNTS)' : 'FINANCE & ACCOUNTS'),
            _buildDrawerMenuItem(
              icon: Icons.receipt_long,
              iconColor: const Color(0xFF10B981),
              title: t ? 'விற்பனை ரசீதுகள் (Invoices)' : 'Sales Invoices & Slips',
              badge: 'Invoices',
              badgeColor: const Color(0xFF10B981),
              onTap: () => _navigateToScreen(InvoicesScreen(isTamil: t)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.assignment_turned_in,
              iconColor: const Color(0xFF10B981),
              title: t ? 'வசூல் போர்ட்டல் & KYC' : 'Field Collections & KYC',
              onTap: () => _navigateToScreen(FieldAgentScreen(isTamil: t, vertical: v)),
            ),
            _buildDrawerMenuItem(
              icon: Icons.account_balance,
              iconColor: const Color(0xFFF59E0B),
              title: t ? 'நிதி லெட்ஜர் இருப்பு (GL 1010-1030)' : 'GL Financial Balances',
              badge: 'GL Ledger',
              badgeColor: const Color(0xFFF59E0B),
              onTap: () => _navigateToScreen(FinancialsScreen(isTamil: t)),
            ),

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 4: Cafe POS
            _buildDrawerSectionHeader(t ? 'அரண் கஃபே பில்லிங்' : 'ARAN CAFE COUNTER'),
            _buildDrawerMenuItem(
              icon: Icons.point_of_sale,
              iconColor: const Color(0xFFD97706),
              title: t ? 'விரைவு டச் POS & டிராயர்' : 'Express Touch POS & Drawer',
              badge: 'Cafe POS',
              badgeColor: const Color(0xFFD97706),
              onTap: () => _navigateToScreen(CafePosScreen(isTamil: t)),
            ),

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 5: Roles & Enterprise Switching
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

            Divider(color: AppColors.border(context), height: 16),

            // SECTION 6: Session & Logout
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, color: Colors.red, size: 20),
              title: Text(
                t ? 'வெளியேறு (Logout Session)' : 'Sign Out (Logout)',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t ? 'வெற்றிகரமாக வெளியேறினீர்கள்' : 'Logged out successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0,
        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < navItems.length ? _currentIndex : 0,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.bottomNavBg(context),
        selectedItemColor: r.color,
        unselectedItemColor: AppColors.textDim(context),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
