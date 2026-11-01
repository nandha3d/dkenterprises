import 'package:flutter/material.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'screens/super_admin_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/field_agent_screen.dart';
import 'screens/ticket_machine_screen.dart';
import 'screens/plant_refill_screen.dart';
import 'screens/tanker_trip_sheet_screen.dart';
import 'screens/cafe_pos_screen.dart';
import 'screens/spot_audit_screen.dart';
import 'screens/role_selector_sheet.dart';

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
  CompanyVertical _activeVertical = CompanyVertical.dkWaters;
  UserRole _activeRole = UserRole.superAdmin; // Default to Super Admin for full client visibility

  void _toggleLanguage() {
    setState(() => _isTamil = !_isTamil);
  }

  void _selectVertical(CompanyVertical vertical) {
    setState(() => _activeVertical = vertical);
  }

  void _selectRole(UserRole role) {
    setState(() {
      _activeRole = role;
      // Auto-align vertical to role
      if (role == UserRole.tankerDriver) {
        _activeVertical = CompanyVertical.tmws;
      } else if (role == UserRole.deliveryDriver) {
        _activeVertical = CompanyVertical.dkWaters;
      } else if (role == UserRole.cashier) {
        _activeVertical = CompanyVertical.aranCafe;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Track — Field ERP Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        cardColor: const Color(0xFF111827),
        colorScheme: ColorScheme.dark(
          primary: _activeRole.color,
          secondary: const Color(0xFF10B981),
          surface: const Color(0xFF111827),
        ),
        fontFamily: 'Roboto',
      ),
      home: MainNavigationShell(
        isTamil: _isTamil,
        activeVertical: _activeVertical,
        activeRole: _activeRole,
        onToggleLanguage: _toggleLanguage,
        onSelectVertical: _selectVertical,
        onSelectRole: _selectRole,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isTamil;
  final CompanyVertical activeVertical;
  final UserRole activeRole;
  final VoidCallback onToggleLanguage;
  final ValueChanged<CompanyVertical> onSelectVertical;
  final ValueChanged<UserRole> onSelectRole;

  const MainNavigationShell({
    super.key,
    required this.isTamil,
    required this.activeVertical,
    required this.activeRole,
    required this.onToggleLanguage,
    required this.onSelectVertical,
    required this.onSelectRole,
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

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final r = widget.activeRole;
    final v = widget.activeVertical;

    // Build role-driven screens and navigation items
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
                        v.name(t),
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
                  Text('API LIVE', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Language toggle
          IconButton(
            tooltip: t ? 'Switch to English' : 'தமிழுக்கு மாறுக',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38),
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

      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DK Track ERP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Enterprise Field Suite', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'API: ${ApiService.activeBaseUrl}',
                      style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Role selection in drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t ? 'பயனர் பாத்திரங்கள் (Roles):' : 'Switch Operational Role:',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            ...UserRole.values.map((role) {
              final isSel = r == role;
              return ListTile(
                dense: true,
                leading: Icon(role.icon, color: isSel ? role.color : Colors.white60, size: 20),
                title: Text(
                  role.title(t),
                  style: TextStyle(color: isSel ? role.color : Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                ),
                trailing: isSel ? Icon(Icons.check, color: role.color, size: 16) : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onSelectRole(role);
                },
              );
            }),

            const Divider(color: Color(0xFF1E293B)),

            // Enterprise Vertical selector in drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t ? 'நிறுவனப் பிரிவு (Enterprises):' : 'Switch Enterprise Profile:',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            ...CompanyVertical.values.map((vert) {
              final isSel = v == vert;
              return ListTile(
                dense: true,
                leading: Icon(vert.icon, color: isSel ? vert.primaryColor : Colors.white60, size: 20),
                title: Text(
                  vert.name(t),
                  style: TextStyle(color: isSel ? vert.primaryColor : Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                ),
                subtitle: Text(vert.tagline(t), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                trailing: isSel ? Icon(Icons.check, color: vert.primaryColor, size: 16) : null,
                onTap: () {
                  Navigator.pop(context);
                  widget.onSelectVertical(vert);
                },
              );
            }),
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
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: r.color,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
