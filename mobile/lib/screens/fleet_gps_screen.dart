import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum FleetViewMode { tankers, packagedWater }

class FleetGpsScreen extends StatefulWidget {
  final bool isTamil;
  final FleetViewMode initialMode;
  final UserRole? activeRole;
  final bool? lockMode;

  const FleetGpsScreen({
    super.key,
    required this.isTamil,
    this.initialMode = FleetViewMode.tankers,
    this.activeRole,
    this.lockMode,
  });

  @override
  State<FleetGpsScreen> createState() => _FleetGpsScreenState();
}

class _FleetGpsScreenState extends State<FleetGpsScreen> with SingleTickerProviderStateMixin {
  late FleetViewMode _mode;
  late AnimationController _radarController;
  Timer? _telemetryTimer;
  int _selectedVehicleIndex = 0;

  bool get _canSwitchMode {
    if (widget.lockMode == true) return false;
    if (widget.activeRole == UserRole.deliveryDriver ||
        widget.activeRole == UserRole.fieldAgent ||
        widget.activeRole == UserRole.tankerDriver) {
      return false;
    }
    return true;
  }

  // Live Tanker Telemetry Data
  final List<Map<String, dynamic>> _tankers = [
    {
      'id': 'TN-58-BW-2001',
      'model': 'Ashok Leyland 20KL',
      'driver': 'Murugan S.',
      'phone': '+91 98421 11201',
      'capacity': '20,000 Liters (20 KL)',
      'status': 'DECANTING',
      'statusColor': AppColors.brandEmerald,
      'location': 'Texvalley Mall (Gate #3 Commercial Sump)',
      'source': 'Borewell Plant #1, Perundurai',
      'speed': 0, // Decanting stationary
      'flowRate': '420 L/min',
      'decanted': '14,800 L',
      'remaining': '5,200 L',
      'fuel': '72%',
      'battery': '24.2 V',
      'valveStatus': 'SECURE (Anti-Tamper Lock)',
      'geofence': 'Inside Approved Sump Zone',
      'eta': 'Decanting ~12 mins left',
      'lat': 11.2954,
      'lng': 77.6128,
      'heading': 45.0,
      'odometerVariance': '0.3% (Clean)',
    },
    {
      'id': 'TN-58-BW-4001',
      'model': 'BharatBenz 40KL Multi-Axle',
      'driver': 'Selvam K.',
      'phone': '+91 98421 44001',
      'capacity': '40,000 Liters (40 KL)',
      'status': 'EN ROUTE',
      'statusColor': AppColors.roleTankerDriver,
      'location': 'NH-544 Salem-Kochi Highway (Near Bypass Toll)',
      'source': 'Borewell Plant #2, Chennimalai Road',
      'speed': 48,
      'flowRate': '0 L/min (Valves Sealed)',
      'decanted': '0 L',
      'remaining': '40,000 L',
      'fuel': '81%',
      'battery': '24.6 V',
      'valveStatus': 'SEALED & MONITORED',
      'geofence': 'Within Authorized Transit Corridor',
      'eta': 'ETA 16 mins (Destination: Chennai Silks Complex)',
      'lat': 11.3410,
      'lng': 77.7172,
      'heading': 110.0,
      'odometerVariance': '0.4% (Clean)',
    },
    {
      'id': 'TN-58-BW-1001',
      'model': 'Eicher Pro 10KL',
      'driver': 'Arumugam P.',
      'phone': '+91 98421 10001',
      'capacity': '10,000 Liters (10 KL)',
      'status': 'RETURNING EMPTY',
      'statusColor': AppColors.brandAmber,
      'location': 'Perundurai SIPCOT Ring Road',
      'source': 'Returning to Borewell Plant #1',
      'speed': 39,
      'flowRate': '0 L/min (Tank Cleaned)',
      'decanted': '10,000 L (Completed)',
      'remaining': '0 L',
      'fuel': '65%',
      'battery': '23.9 V',
      'valveStatus': 'SECURE',
      'geofence': 'Return Route Verified',
      'eta': 'ETA Plant: 11 mins',
      'lat': 11.2780,
      'lng': 77.5890,
      'heading': 260.0,
      'odometerVariance': '0.2% (Clean)',
    },
  ];

  // Live Packaged Water Tata Ace Beat Telemetry Data
  final List<Map<String, dynamic>> _waterTrucks = [
    {
      'id': 'TN-58-WA-101',
      'model': 'Tata Ace Gold (84 Jars Capacity)',
      'driver': 'Kumar R.',
      'phone': '+91 98421 55101',
      'beatName': 'Perundurai Commercial Beat #1',
      'status': 'BEAT ACTIVE',
      'statusColor': AppColors.brandSky,
      'location': 'Near Green Garden Hotel, Market Road',
      'speed': 26,
      'completedStops': 12,
      'totalStops': 18,
      'currentStop': 'Stop #13: Green Garden Hotel (Drop: 6 Jars)',
      'cansDelivered': 68,
      'emptiesCollected': 54,
      'jarsLeftInTruck': 16,
      'fuel': '74%',
      'battery': '12.6 V',
      'geofence': 'Inside Route Beat Perimeter',
      'eta': 'Next Stop ETA: 3 mins',
      'lat': 11.2812,
      'lng': 77.5994,
      'heading': 80.0,
      'odometerVariance': '0.1% (Match)',
    },
    {
      'id': 'TN-58-WA-102',
      'model': 'Tata Ace Mega (96 Jars Capacity)',
      'driver': 'Manikandan V.',
      'phone': '+91 98421 55102',
      'beatName': 'SIPCOT Industrial Park Beat #2',
      'status': 'DELIVERING AT SITE',
      'statusColor': AppColors.brandEmerald,
      'location': 'Texvalley Tech Hub (Building B Reception)',
      'speed': 0, // Unloading
      'completedStops': 17,
      'totalStops': 22,
      'currentStop': 'Stop #18: Texvalley Tech Hub (Drop: 10 Jars)',
      'cansDelivered': 76,
      'emptiesCollected': 68,
      'jarsLeftInTruck': 20,
      'fuel': '88%',
      'battery': '12.8 V',
      'geofence': 'Site Check-In Geostamp Confirmed',
      'eta': 'Unloading in progress (~5 mins)',
      'lat': 11.3015,
      'lng': 77.6201,
      'heading': 195.0,
      'odometerVariance': '0.5% (Clean)',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.activeRole == UserRole.deliveryDriver || widget.activeRole == UserRole.fieldAgent) {
      _mode = FleetViewMode.packagedWater;
    } else if (widget.activeRole == UserRole.tankerDriver) {
      _mode = FleetViewMode.tankers;
    } else {
      _mode = widget.initialMode;
    }
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Subtle real-time jitter simulation for speed/coordinates
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        for (var t in _tankers) {
          if (t['speed'] > 0) {
            final delta = (math.Random().nextInt(5) - 2);
            t['speed'] = math.max(20, (t['speed'] as int) + delta);
          }
        }
        for (var w in _waterTrucks) {
          if (w['speed'] > 0) {
            final delta = (math.Random().nextInt(5) - 2);
            w['speed'] = math.max(15, (w['speed'] as int) + delta);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  void _callDriver(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isTamil ? 'டிரைவர் தொடர்பு: $phone' : 'Calling Fleet Driver: $phone',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.brandEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final isDark = AppColors.isDark(context);
    final activeList = _mode == FleetViewMode.tankers ? _tankers : _waterTrucks;
    final selectedVehicle = activeList[_selectedVehicleIndex < activeList.length ? _selectedVehicleIndex : 0];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandEmerald.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share_location, color: AppColors.brandEmerald, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t ? 'நேரடி GPS கண்காணிப்பு & ரேடார்' : 'Live Fleet GPS & Radar Tracking',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  t ? '12 செயற்கைக்கோள்கள் இணைக்கப்பட்டது · 4G LTE' : '12 GPS Satellites Locked · Real-Time LTE',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.brandEmerald, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandEmerald.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandEmerald.withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.brandEmerald, size: 7),
                SizedBox(width: 5),
                Text('ACTIVE RADAR', style: TextStyle(color: AppColors.brandEmerald, fontSize: 9, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical Switcher Segmented Bar (Gated strictly to Admins / Super Admin)
            if (_canSwitchMode)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mode = FleetViewMode.tankers;
                            _selectedVehicleIndex = 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == FleetViewMode.tankers
                                ? AppColors.roleTankerDriver
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _mode == FleetViewMode.tankers
                                ? [
                                    BoxShadow(
                                      color: AppColors.roleTankerDriver.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fire_truck,
                                size: 18,
                                color: _mode == FleetViewMode.tankers ? Colors.white : AppColors.textDim(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t ? 'TMWS பல்க் டேங்கர் (3)' : 'TMWS Tankers (3)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _mode == FleetViewMode.tankers ? Colors.white : AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mode = FleetViewMode.packagedWater;
                            _selectedVehicleIndex = 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == FleetViewMode.packagedWater
                                ? AppColors.brandSky
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _mode == FleetViewMode.packagedWater
                                ? [
                                    BoxShadow(
                                      color: AppColors.brandSky.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 18,
                                color: _mode == FleetViewMode.packagedWater ? Colors.white : AppColors.textDim(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t ? 'DK குடிநீர் வேன்கள் (2)' : 'DK Waters Beats (2)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _mode == FleetViewMode.packagedWater ? Colors.white : AppColors.text(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                decoration: BoxDecoration(
                  color: (_mode == FleetViewMode.tankers ? AppColors.roleTankerDriver : AppColors.brandSky).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_mode == FleetViewMode.tankers ? AppColors.roleTankerDriver : AppColors.brandSky).withOpacity(0.40),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _mode == FleetViewMode.tankers ? AppColors.roleTankerDriver : AppColors.brandSky,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _mode == FleetViewMode.tankers ? Icons.fire_truck : Icons.water_drop,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mode == FleetViewMode.tankers
                                ? (t ? 'TMWS பல்க் டேங்கர் கப்பற்படை ரேடார்' : 'TMWS Bulk Tanker Fleet Radar')
                                : (t ? 'DK குடிநீர் விநியோக பீட் ரேடார்' : 'DK Waters Beat Delivery Fleet Radar'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text(context),
                            ),
                          ),
                          Text(
                            _mode == FleetViewMode.tankers
                                ? (t ? '3 டேங்கர்கள் செயலில் · நேரலை GPS டெலிமெட்ரி' : '3 Tankers Active · Live Telemetry & Anti-Siphon Gate')
                                : (t ? '2 டாடா ஏஸ் வேன்கள் · நேரலை பீட் வழித்தடம்' : '2 Tata Ace Trucks · Live Delivery Stops & Jars'),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textDim(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandEmerald.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brandEmerald.withOpacity(0.4)),
                      ),
                      child: Text(
                        t ? 'நேரலை' : 'ACTIVE',
                        style: const TextStyle(
                          color: AppColors.brandEmerald,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // High-Tech Interactive Radar Map Box
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF030A16) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.15) : AppColors.brandNavy.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_mode == FleetViewMode.tankers ? AppColors.roleTankerDriver : AppColors.brandSky)
                          .withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Radar Animated Canvas
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: FleetRadarPainter(
                            sweepAngle: _radarController.value * 2 * math.pi,
                            isDark: isDark,
                            accentColor: _mode == FleetViewMode.tankers
                                ? AppColors.roleTankerDriver
                                : AppColors.brandSky,
                          ),
                        );
                      },
                    ),

                    // Borewell Hub Origin Landmark
                    Positioned(
                      left: 45,
                      top: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.brandEmerald,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandEmerald.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.water, color: Colors.white, size: 14),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.brandEmerald.withOpacity(0.5)),
                            ),
                            child: Text(
                              _mode == FleetViewMode.tankers
                                  ? (t ? 'போர்வெல் ஆலை' : 'TMWS Borewell Hub')
                                  : (t ? 'DK குடிநீர் ஆலை' : 'DK Waters Plant'),
                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Destination Landmark: Texvalley Mall
                    Positioned(
                      right: 50,
                      top: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.business, color: Colors.white, size: 13),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Texvalley Mall', style: TextStyle(color: Colors.white, fontSize: 8)),
                          ),
                        ],
                      ),
                    ),

                    // Destination Landmark: Chennai Silks Complex
                    Positioned(
                      right: 80,
                      bottom: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amberAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.storefront, color: Colors.black, size: 13),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Chennai Silks', style: TextStyle(color: Colors.white, fontSize: 8)),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Vehicle Blips
                    ...List.generate(activeList.length, (index) {
                      final v = activeList[index];
                      final isSelected = index == _selectedVehicleIndex;
                      // Predefined visual coordinates on radar canvas
                      final List<Offset> positions = _mode == FleetViewMode.tankers
                          ? const [Offset(190, 75), Offset(130, 150), Offset(70, 185)]
                          : const [Offset(140, 100), Offset(220, 140)];
                      final pos = positions[index < positions.length ? index : 0];

                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedVehicleIndex = index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: EdgeInsets.all(isSelected ? 8 : 6),
                                decoration: BoxDecoration(
                                  color: v['statusColor'] as Color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 2.5 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (v['statusColor'] as Color).withOpacity(0.7),
                                      blurRadius: isSelected ? 16 : 8,
                                      spreadRadius: isSelected ? 3 : 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _mode == FleetViewMode.tankers ? Icons.fire_truck : Icons.local_shipping,
                                  color: Colors.white,
                                  size: isSelected ? 18 : 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? (v['statusColor'] as Color) : Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${v['id']} · ${v['speed']} km/h',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Top Radar HUD Overlay
                    Positioned(
                      top: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.radar, color: AppColors.brandEmerald, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              t ? 'எரோடு-பெருந்துறை மண்டலம்' : 'Erode-Perundurai Fleet Zone',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          'GRID: 30 KM RADIUS',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Horizontal Selector Chips for Vehicles
            Text(
              t ? 'வாகனங்கள் கண்காணிப்புப் பட்டியல்' : 'Fleet Vehicle Live Telemetry',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text(context)),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: activeList.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final v = activeList[index];
                  final isSel = index == _selectedVehicleIndex;
                  return InkWell(
                    onTap: () => setState(() => _selectedVehicleIndex = index),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (v['statusColor'] as Color).withOpacity(0.18)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel
                              ? (v['statusColor'] as Color)
                              : AppColors.border(context),
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mode == FleetViewMode.tankers ? Icons.fire_truck : Icons.water_drop,
                            size: 16,
                            color: isSel ? (v['statusColor'] as Color) : AppColors.textDim(context),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                v['id'] as String,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  height: 1.15,
                                  color: isSel ? AppColors.text(context) : AppColors.textDim(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v['speed']} km/h · ${v['status']}',
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: v['statusColor'] as Color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Detailed Telemetry Card for Selected Vehicle
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              tintColor: selectedVehicle['statusColor'] as Color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Top Identity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (selectedVehicle['statusColor'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _mode == FleetViewMode.tankers ? Icons.fire_truck : Icons.local_shipping,
                              color: selectedVehicle['statusColor'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedVehicle['id'] as String,
                                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.text(context)),
                              ),
                              Text(
                                selectedVehicle['model'] as String,
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (selectedVehicle['statusColor'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (selectedVehicle['statusColor'] as Color).withOpacity(0.6)),
                        ),
                        child: Text(
                          selectedVehicle['status'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: selectedVehicle['statusColor'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Location & ETA Pill
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pin_drop, color: AppColors.brandDanger, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedVehicle['location'] as String,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: AppColors.brandEmerald, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                selectedVehicle['eta'] as String,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandEmerald),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Live Metric Grid: Speed, Fuel, Battery, Odometer Variance
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricMiniCard(
                          icon: Icons.speed,
                          label: t ? 'வேகம் (Speed)' : 'Live Speed',
                          value: '${selectedVehicle['speed']} km/h',
                          accentColor: selectedVehicle['statusColor'] as Color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricMiniCard(
                          icon: Icons.local_gas_station,
                          label: t ? 'டீசல் இருப்பு' : 'Fuel Level',
                          value: selectedVehicle['fuel'] as String,
                          accentColor: AppColors.brandAmber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricMiniCard(
                          icon: Icons.battery_charging_full,
                          label: t ? 'பேட்டரி வோல்ட்' : 'ECU Battery',
                          value: selectedVehicle['battery'] as String,
                          accentColor: AppColors.brandSky,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mode-Specific Details:
                  if (_mode == FleetViewMode.tankers) ...[
                    // Decanting Flow Sensor & Valve Security
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.roleTankerDriver.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.roleTankerDriver.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'இறக்கும் ஃப்ளோ ரேட் மீட்டர்' : 'Decanting Flow Sensor Meter',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.roleTankerDriver),
                              ),
                              Text(
                                selectedVehicle['flowRate'] as String,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.roleTankerDriver),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'டேங்கர் கொள்ளளவு:' : 'Tank Capacity:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                selectedVehicle['capacity'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'ஆன்ட்டி-சைபனிங் வால்வு பாதுகாப்பு:' : 'Anti-Siphoning Valve:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                selectedVehicle['valveStatus'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandEmerald),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'ஓடோமீட்டர்-GPS மாறுபாடு:' : 'Odometer vs GPS Diff:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                selectedVehicle['odometerVariance'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandEmerald),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Packaged Water Tata Ace Beat Progress
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandSky.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.brandSky.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedVehicle['beatName'] as String,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandSky),
                              ),
                              Text(
                                '${selectedVehicle['completedStops']} / ${selectedVehicle['totalStops']} Stops',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (selectedVehicle['completedStops'] as int) / (selectedVehicle['totalStops'] as int),
                            backgroundColor: AppColors.border(context),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandEmerald),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'விநியோகிக்கப்பட்ட கேன்கள்:' : 'Jars Delivered:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                '${selectedVehicle['cansDelivered']} Cans',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'சேகரித்த காலி கேன்கள்:' : 'Empties Collected:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                '${selectedVehicle['emptiesCollected']} Cans',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandEmerald),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t ? 'லாரியில் மீதமுள்ள கேன்கள்:' : 'Jars Left on Truck:',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                              Text(
                                '${selectedVehicle['jarsLeftInTruck']} Jars Available',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandSky),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Driver Contact & Live Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.phone, size: 16),
                          label: Text(
                            '${selectedVehicle['driver']}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text(context),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            side: BorderSide(color: AppColors.border(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _callDriver(selectedVehicle['phone'] as String),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location, size: 16),
                        label: Text(
                          t ? 'லைவ் லொகேஷன்' : 'Track Pin',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedVehicle['statusColor'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'GPS Coordinates: ${selectedVehicle['lat']}, ${selectedVehicle['lng']}',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: selectedVehicle['statusColor'] as Color,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 9.5, color: AppColors.textDim(context))),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.text(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Animated Radar Sweep & Grid
class FleetRadarPainter extends CustomPainter {
  final double sweepAngle;
  final bool isDark;
  final Color accentColor;

  FleetRadarPainter({
    required this.sweepAngle,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;

    // Background Grid Rings
    final ringPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), ringPaint);
    }

    // Grid Axis Crosshair
    final axisPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    // Dynamic Rotating Radar Sweep Wedge
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 0.5,
        colors: [
          accentColor.withOpacity(0.0),
          accentColor.withOpacity(0.28),
        ],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Pulsing Outer Radar Border
    final outerRing = Paint()
      ..color = accentColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius, outerRing);
  }

  @override
  bool shouldRepaint(covariant FleetRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.accentColor != accentColor;
  }
}
