import 'package:flutter/material.dart';
import 'screens/ticket_machine_screen.dart';
import 'screens/tanker_trip_sheet_screen.dart';
import 'screens/spot_audit_screen.dart';

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
  bool _isTamil = true; // Default Tamil for field drivers

  void _toggleLanguage() {
    setState(() {
      _isTamil = !_isTamil;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DK Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        cardColor: const Color(0xFF111827),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF059669),
          surface: Color(0xFF111827),
        ),
        fontFamily: 'Roboto',
      ),
      home: MainNavigationShell(
        isTamil: _isTamil,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final bool isTamil;
  final VoidCallback onToggleLanguage;

  const MainNavigationShell({
    super.key,
    required this.isTamil,
    required this.onToggleLanguage,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TicketMachineScreen(isTamil: widget.isTamil),
      TankerTripSheetScreen(isTamil: widget.isTamil),
      SpotAuditScreen(isTamil: widget.isTamil),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.local_shipping, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isTamil ? 'டிகே ட்ராக்' : 'DK TRACK',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.isTamil ? 'DK எண்டர்பிரைசஸ்' : 'DK ENTERPRISES',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onToggleLanguage,
            icon: const Icon(Icons.language, size: 16, color: Color(0xFF38BDF8)),
            label: Text(
              widget.isTamil ? 'English' : 'தமிழ்',
              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: const Color(0xFF64748B),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.water_drop),
            label: widget.isTamil ? 'வாட்டர் கேன்' : 'Water Cans',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fire_truck),
            label: widget.isTamil ? 'டேங்கர் லாரி' : 'Tanker Trip',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user),
            label: widget.isTamil ? 'ஸ்பாட் தணிக்கை' : 'Spot Audit',
          ),
        ],
      ),
    );
  }
}
