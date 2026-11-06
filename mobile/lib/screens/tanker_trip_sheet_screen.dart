import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum TripTrackingStatus {
  notStarted,
  enRoute,
  atSite,
  completed,
}

class TankerTripSheetScreen extends StatefulWidget {
  final bool isTamil;

  const TankerTripSheetScreen({super.key, required this.isTamil});

  @override
  State<TankerTripSheetScreen> createState() => _TankerTripSheetScreenState();
}

class _TankerTripSheetScreenState extends State<TankerTripSheetScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tankers = [];
  Map<String, dynamic>? _selectedTanker;
  List<Map<String, dynamic>> _destinations = [];
  Map<String, dynamic>? _selectedDestination;

  // Controllers for Odometer and Expenses
  final _odometerStartController = TextEditingController(text: '142810');
  final _odometerEndController = TextEditingController(text: '142858');
  final _motorMinutesController = TextEditingController(text: '40');
  final _waitingMinutesController = TextEditingController(text: '30');
  final _tollController = TextEditingController(text: '180');
  final _dieselController = TextEditingController(text: '1200');
  final _receiverController = TextEditingController(text: 'Site Receiver');

  // Operational State
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Requirement 1: GPS Trip Tracking State & Dual Verification
  TripTrackingStatus _trackingStatus = TripTrackingStatus.notStarted;
  bool _isGpsActive = false;
  bool _useManualOverride = false;
  double _gpsDistanceKm = 0.0;
  Position? _lastGpsPosition;
  StreamSubscription<Position>? _positionStreamSub;
  Timer? _tripClockTimer;
  DateTime? _tripStartTime;
  DateTime? _siteArrivalTime;
  int _elapsedTripSeconds = 0;
  double _currentSpeedKmh = 0.0;

  // Requirement 2: Automatic Halt Timing (Idle Detection)
  int _autoHaltSeconds = 0;
  bool _isIdleDetected = false;

  // Requirement 3: Motor Pumping Manual Entry & Live Stopwatch
  bool _motorUsed = true;
  bool _isPumpRunning = false;
  int _pumpStopwatchSeconds = 0;
  Timer? _pumpTimer;

  // Predefined Product Rates
  final double _baseFreeKm = 10.0;
  final double _excessKmRate = 40.0;
  final double _motorRatePerMin = 10.0;
  final double _waitingRatePerMin = 15.0;
  final int _freeWaitingGraceMins = 15;

  @override
  void initState() {
    super.initState();
    _loadFleetAndDestinations();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _tripClockTimer?.cancel();
    _pumpTimer?.cancel();
    _odometerStartController.dispose();
    _odometerEndController.dispose();
    _motorMinutesController.dispose();
    _waitingMinutesController.dispose();
    _tollController.dispose();
    _dieselController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  Future<void> _loadFleetAndDestinations() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _apiService.fetchRoutes(),
      _apiService.fetchCustomers(),
    ]);

    if (mounted) {
      setState(() {
        final routesData = results[0] as Map<String, dynamic>;
        if (routesData['tankers'] is List && (routesData['tankers'] as List).isNotEmpty) {
          _tankers = List<Map<String, dynamic>>.from(routesData['tankers'] as List);
        } else {
          _tankers = [
            {'id': 1, 'number': 'TN 34 AF 4954', 'capacity_kl': 20.0, 'driver': 'Suresh Kumar'},
            {'id': 2, 'number': 'TN 33 BK 8821', 'capacity_kl': 40.0, 'driver': 'P. Murugan'},
          ];
        }
        _selectedTanker = _tankers.first;

        _destinations = List<Map<String, dynamic>>.from(results[1] as List);
        if (_destinations.isNotEmpty) {
          _selectedDestination = _destinations.first;
        }

        _isLoading = false;
      });
    }
  }

  // =========================================================================
  // Requirement 1: GPS Trip Tracking Engine & Override
  // =========================================================================

  Future<void> _startTrip() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _trackingStatus = TripTrackingStatus.enRoute;
      _tripStartTime = DateTime.now();
      _gpsDistanceKm = 0.0;
      _autoHaltSeconds = 0;
      _elapsedTripSeconds = 0;
    });

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackToManualOdometer('Location services are disabled on device');
        _startTripClock();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackToManualOdometer('Location permissions denied');
          _startTripClock();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fallbackToManualOdometer('Location permissions permanently denied');
        _startTripClock();
        return;
      }

      // GPS is permitted and available
      _isGpsActive = true;
      _useManualOverride = false;

      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastGpsPosition = initialPos;

      // Start streaming location updates
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Updates every 10 meters
        ),
      ).listen(
        (Position position) => _onGpsPositionUpdate(position),
        onError: (e) {
          _fallbackToManualOdometer('GPS stream interrupted: $e');
        },
      );

      _startTripClock();
    } catch (e) {
      _fallbackToManualOdometer('GPS initialisation error: $e');
      _startTripClock();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onGpsPositionUpdate(Position position) {
    if (!mounted) return;

    final speedKmh = (position.speed * 3.6).clamp(0.0, 140.0);

    double deltaKm = 0.0;
    if (_lastGpsPosition != null) {
      final meters = Geolocator.distanceBetween(
        _lastGpsPosition!.latitude,
        _lastGpsPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      // Filter out GPS drift (only count movements >= 5m)
      if (meters >= 5.0) {
        deltaKm = meters / 1000.0;
      }
    }

    setState(() {
      _lastGpsPosition = position;
      _currentSpeedKmh = speedKmh;
      _gpsDistanceKm += deltaKm;

      // Automatically sync End KM with Start KM + GPS Distance unless manually overridden
      if (!_useManualOverride) {
        final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
        final endKm = (startKm + _gpsDistanceKm.round());
        _odometerEndController.text = endKm.toString();
      }

      // Requirement 2: Detect vehicle idle if speed < 2.5 km/h
      _isIdleDetected = speedKmh < 2.5;
    });
  }

  void _fallbackToManualOdometer(String reason) {
    if (!mounted) return;
    setState(() {
      _isGpsActive = false;
      _useManualOverride = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isTamil
              ? 'GPS கிடைக்கவில்லை. ஓடோமீட்டர் முறைக்கு மாறியது ($reason)'
              : 'GPS offline. Switched to manual Odometer mode ($reason)',
        ),
        backgroundColor: Colors.amber.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startTripClock() {
    _tripClockTimer?.cancel();
    _tripClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedTripSeconds++;

        // Requirement 2: Accumulate halt/waiting time automatically
        // If vehicle is at customer site or GPS detected idle (< 2.5 km/h)
        if (_trackingStatus == TripTrackingStatus.atSite || _isIdleDetected) {
          _autoHaltSeconds++;
          final haltMinutes = (_autoHaltSeconds / 60).floor();
          _waitingMinutesController.text = haltMinutes.toString();
        }
      });
    });
  }

  void _markArrivedAtSite() {
    setState(() {
      _trackingStatus = TripTrackingStatus.atSite;
      _siteArrivalTime = DateTime.now();
      _isIdleDetected = true;
      _currentSpeedKmh = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isTamil
              ? 'வாடிக்கையாளர் இடம் அடைந்தது! தானியங்கி காத்திருப்பு நேரம் துவங்கியது.'
              : 'Arrived at site! Automatic halt/waiting timer is now tracking.',
        ),
        backgroundColor: AppColors.roleTankerDriver,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _finishTrip() {
    _positionStreamSub?.cancel();
    _tripClockTimer?.cancel();

    setState(() {
      _trackingStatus = TripTrackingStatus.completed;
      _currentSpeedKmh = 0.0;
      _isIdleDetected = false;
    });
  }

  void _resetTrip() {
    _positionStreamSub?.cancel();
    _tripClockTimer?.cancel();
    _pumpTimer?.cancel();

    setState(() {
      _trackingStatus = TripTrackingStatus.notStarted;
      _isGpsActive = false;
      _useManualOverride = false;
      _gpsDistanceKm = 0.0;
      _autoHaltSeconds = 0;
      _elapsedTripSeconds = 0;
      _currentSpeedKmh = 0.0;
      _isIdleDetected = false;
      _isPumpRunning = false;
      _pumpStopwatchSeconds = 0;
    });
  }

  // =========================================================================
  // Requirement 3: Live Motor Pumping Stopwatch
  // =========================================================================

  void _toggleMotorPumpStopwatch() {
    if (_isPumpRunning) {
      // Stop pump
      _pumpTimer?.cancel();
      setState(() {
        _isPumpRunning = false;
        final minutes = (_pumpStopwatchSeconds / 60).ceil();
        _motorMinutesController.text = minutes > 0 ? minutes.toString() : '1';
      });
    } else {
      // Start pump
      setState(() {
        _isPumpRunning = true;
        _motorUsed = true;
        _pumpStopwatchSeconds = 0;
      });
      _pumpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _pumpStopwatchSeconds++;
          final minutes = (_pumpStopwatchSeconds / 60).ceil();
          _motorMinutesController.text = minutes.toString();
        });
      });
    }
  }

  // =========================================================================
  // Fare Calculations & Bill Generation
  // =========================================================================

  double _getEffectiveDistanceKm() {
    if (_useManualOverride || !_isGpsActive) {
      final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
      final endKm = int.tryParse(_odometerEndController.text) ?? 142858;
      return (endKm - startKm).clamp(0, 9999).toDouble();
    }
    return _gpsDistanceKm;
  }

  int _getBillableWaitingMinutes() {
    final totalWait = int.tryParse(_waitingMinutesController.text) ?? (_autoHaltSeconds ~/ 60);
    return (totalWait - _freeWaitingGraceMins).clamp(0, 9999);
  }

  double _calculateTotalFare() {
    if (_selectedTanker == null) return 0.0;
    final capKl = (_selectedTanker!['capacity_kl'] as num? ?? 20.0).toDouble();

    // 1. Base Water Trip Fare
    final baseFare = capKl * 140.0; // ₹2,800 for 20KL

    // 2. Distance Charge (Excess over base limit)
    final distanceKm = _getEffectiveDistanceKm();
    final excessKm = (distanceKm - _baseFreeKm).clamp(0.0, 9999.0);
    final distanceCharge = excessKm * _excessKmRate;

    // 3. Motor Pumping Charge (Only manual entry)
    final motorMins = int.tryParse(_motorMinutesController.text) ?? 0;
    final motorCharge = _motorUsed ? (motorMins * _motorRatePerMin) : 0.0;

    // 4. Waiting / Delay Charge
    final billableWaitMins = _getBillableWaitingMinutes();
    final waitingCharge = billableWaitMins * _waitingRatePerMin;

    // 5. Toll Gate Expense
    final toll = double.tryParse(_tollController.text) ?? 0.0;

    return baseFare + distanceCharge + motorCharge + waitingCharge + toll;
  }

  Future<void> _submitTripSheet() async {
    if (_selectedTanker == null) return;
    setState(() => _isSubmitting = true);

    final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
    final endKm = int.tryParse(_odometerEndController.text) ?? 142858;
    final distanceKm = _getEffectiveDistanceKm();
    final excessKm = (distanceKm - _baseFreeKm).clamp(0.0, 9999.0).toInt();

    final motorMins = int.tryParse(_motorMinutesController.text) ?? 0;
    final motorCharge = _motorUsed ? (motorMins * _motorRatePerMin) : 0.0;

    final billableWaitMins = _getBillableWaitingMinutes();
    final waitingCharge = billableWaitMins * _waitingRatePerMin;

    final totalFare = _calculateTotalFare();
    final tripNo = 'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final destinationName = _selectedDestination != null
        ? (_selectedDestination!['name'] ?? 'Site')
        : 'Commercial Site';

    final tripRecord = TankerTripRecord(
      tripNumber: tripNo,
      tankerId: _selectedTanker!['id'] as int? ?? 1,
      vehicleNumber: (_selectedTanker!['number'] ?? _selectedTanker!['tanker_no'] ?? 'TN-34-AF').toString(),
      capacityKl: (_selectedTanker!['capacity_kl'] as num? ?? 20.0).toDouble(),
      customerName: destinationName,
      loadSource: 'Borewell Hub (Perundurai)',
      destinationSite: destinationName,
      startKm: startKm,
      endKm: endKm,
      excessKm: excessKm,
      excessKmCharge: excessKm * _excessKmRate,
      motorUsed: _motorUsed,
      motorMinutes: motorMins,
      motorCharge: motorCharge,
      waitingHours: billableWaitMins / 60.0,
      waitingCharge: waitingCharge,
      tollExpense: double.tryParse(_tollController.text) ?? 0.0,
      driverBatta: 250.0,
      dieselExpense: double.tryParse(_dieselController.text) ?? 0.0,
      billedAmount: totalFare,
      siteReceiverName: _receiverController.text,
      tripDate: DateTime.now(),
    );

    await _apiService.submitTankerTrip(tripRecord);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil
                ? 'டேங்கர் ட்ரிப் ஷீட் [$tripNo] லெட்ஜரில் பதிவானது! மொத்தம்: ₹${totalFare.toStringAsFixed(2)}'
                : 'Tanker trip sheet [$tripNo] posted to ERP! Total: ₹${totalFare.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final totalFare = _calculateTotalFare();
    final canPop = Navigator.canPop(context);

    final distanceKm = _getEffectiveDistanceKm();
    final excessKm = (distanceKm - _baseFreeKm).clamp(0.0, 9999.0);
    final odoKm = ((int.tryParse(_odometerEndController.text) ?? 142858) -
            (int.tryParse(_odometerStartController.text) ?? 142810))
        .clamp(0, 9999);
    final varianceKm = (distanceKm - odoKm).abs();

    final billableWaitMins = _getBillableWaitingMinutes();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: canPop
          ? AppBar(
              title: Text(
                t ? 'டேங்கர் ஆட்டோ ட்ரிப் ஷீட்' : 'Auto Tanker Trip Sheet',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              actions: [
                if (_trackingStatus != TripTrackingStatus.notStarted)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Trip',
                    onPressed: _resetTrip,
                  ),
              ],
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.roleTankerDriver))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Live Trip Telematics Status & Start Trip Master Bar
                  _buildTripStatusMasterBar(t),
                  const SizedBox(height: 14),

                  // 2. Tanker Fleet & Customer Selector
                  _buildFleetSelectorCard(t),
                  const SizedBox(height: 14),

                  // 3. Dual Distance Tracking Card (GPS Auto + Odometer Override)
                  _buildDualDistanceTrackingCard(t, distanceKm, excessKm, odoKm, varianceKm),
                  const SizedBox(height: 14),

                  // 4. Automatic Halt / Idle Waiting Card
                  _buildAutoHaltCard(t, billableWaitMins),
                  const SizedBox(height: 14),

                  // 5. The ONLY Manual Entry: Motor Pumping Card
                  _buildMotorPumpingCard(t),
                  const SizedBox(height: 14),

                  // 6. Fleet Expenses (Diesel & Toll)
                  _buildExpenseCard(t),
                  const SizedBox(height: 16),

                  // 7. Live Bill Fare Preview & Submit Button
                  _buildLiveBillPreviewCard(t, totalFare, excessKm, billableWaitMins),
                ],
              ),
            ),
    );
  }

  // =========================================================================
  // UI Section Builders
  // =========================================================================

  Widget _buildTripStatusMasterBar(bool t) {
    Color barColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    switch (_trackingStatus) {
      case TripTrackingStatus.notStarted:
        barColor = AppColors.brandNavy;
        statusTitle = t ? 'ட்ரிப் துவங்க தயாராக உள்ளது' : 'Trip Ready to Dispatch';
        statusSubtitle = t ? 'தானியங்கி GPS & காத்திருப்பு கண்காணிப்பு' : 'Auto GPS Kilometers & Idle Halt Tracking';
        statusIcon = Icons.fire_truck;
        break;
      case TripTrackingStatus.enRoute:
        barColor = AppColors.brandEmerald;
        statusTitle = t ? 'பயணத்தில் உள்ளது (GPS இயங்குகிறது)' : 'En Route (Live GPS Tracking Active)';
        statusSubtitle = '${_formatDuration(_elapsedTripSeconds)} · ${_currentSpeedKmh.toStringAsFixed(0)} km/h · ${_gpsDistanceKm.toStringAsFixed(1)} KM';
        statusIcon = Icons.navigation;
        break;
      case TripTrackingStatus.atSite:
        barColor = AppColors.roleTankerDriver;
        statusTitle = t ? 'வாடிக்கையாளர் இடத்தில் உள்ளது' : 'At Customer Site (Decanting)';
        statusSubtitle = '${t ? "நிறுத்த நேரம்" : "Halted"}: ${_formatDuration(_autoHaltSeconds)} · Speed: 0 km/h';
        statusIcon = Icons.location_on;
        break;
      case TripTrackingStatus.completed:
        barColor = AppColors.brandPurple;
        statusTitle = t ? 'ட்ரிப் நிறைவடைந்தது' : 'Trip Completed · Ready to Bill';
        statusSubtitle = '${t ? "பயண தூரம்" : "Total Distance"}: ${_getEffectiveDistanceKm().toStringAsFixed(1)} KM';
        statusIcon = Icons.check_circle;
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      tintColor: barColor,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: barColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textDim(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (_trackingStatus == TripTrackingStatus.enRoute)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandEmerald.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.brandEmerald, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons based on State
          if (_trackingStatus == TripTrackingStatus.notStarted)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  t ? 'ட்ரிப் துவங்கு (ஆட்டோ GPS)' : 'Start Trip (Auto GPS Tracking)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _startTrip,
              ),
            )
          else if (_trackingStatus == TripTrackingStatus.enRoute)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.place, size: 16),
                    label: Text(
                      t ? 'இடத்தை அடைந்தது' : 'Arrived at Site',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roleTankerDriver,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _markArrivedAtSite,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_rounded, size: 16),
                    label: Text(
                      t ? 'ட்ரிப் முடி' : 'Finish Trip',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text(context),
                      side: BorderSide(color: AppColors.border(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _finishTrip,
                  ),
                ),
              ],
            )
          else if (_trackingStatus == TripTrackingStatus.atSite)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  t ? 'இறக்குதல் முடித்து பில் தயார் செய்' : 'Decanting Done · Generate Bill',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _finishTrip,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFleetSelectorCard(bool t) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 16, color: AppColors.textMuted(context)),
              const SizedBox(width: 8),
              Text(
                t ? 'வாகனம் மற்றும் வாடிக்கையாளர்' : 'Tanker Vehicle & Customer Site',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedTanker,
            style: TextStyle(color: AppColors.text(context), fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: t ? 'டேங்கர் வாகனம்' : 'Assigned Tanker',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _tankers.map((tanker) {
              final number = tanker['number'] ?? tanker['tanker_no'] ?? 'Tanker';
              final kl = tanker['capacity_kl'] ?? 20;
              return DropdownMenuItem<Map<String, dynamic>>(
                value: tanker,
                child: Text('$number ($kl KL)'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedTanker = val),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedDestination,
            style: TextStyle(color: AppColors.text(context), fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: t ? 'வாடிக்கையாளர் / தளம்' : 'Customer Delivery Site',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _destinations.map((c) {
              final name = c['name'] ?? 'Site';
              return DropdownMenuItem<Map<String, dynamic>>(
                value: c,
                child: Text(name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDestination = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDualDistanceTrackingCard(
    bool t,
    double distanceKm,
    double excessKm,
    int odoKm,
    double varianceKm,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (_isGpsActive ? AppColors.brandEmerald : Colors.amber).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isGpsActive ? Icons.share_location : Icons.speed,
                      color: _isGpsActive ? AppColors.brandEmerald : Colors.amber.shade800,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t ? 'தூரம் & வழித்தடம் (GPS + ஓடோமீட்டர்)' : 'Distance Tracking (Dual Verification)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isGpsActive ? AppColors.brandEmerald : Colors.amber).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isGpsActive ? '🛰️ GPS LIVE' : '⚠️ ODOMETER MODE',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: _isGpsActive ? AppColors.brandEmerald : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dual Numbers Comparison Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t ? 'GPS பதிவு தூரம்' : 'GPS Tracked Distance',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_gpsDistanceKm.toStringAsFixed(1)} KM',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _isGpsActive ? AppColors.brandEmerald : AppColors.textDim(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t ? 'ஓடோமீட்டர் தூரம்' : 'Odometer Reading',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$odoKm KM',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _useManualOverride ? AppColors.roleTankerDriver : AppColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dual Match Verification Chip
          Row(
            children: [
              Icon(
                varianceKm <= 1.5 ? Icons.verified : Icons.info_outline,
                size: 13,
                color: varianceKm <= 1.5 ? AppColors.brandEmerald : Colors.amber.shade800,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _isGpsActive
                      ? 'Dual Match: ${varianceKm.toStringAsFixed(1)} KM variance · Using ${_useManualOverride ? "Odometer Override" : "GPS Automatic Distance"}'
                      : 'GPS offline · Billing calculated via Odometer Start & End KM',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Odometer Inputs & Manual Override Switch
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _odometerStartController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.text(context), fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t ? 'துவக்க KM' : 'Start KM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _odometerEndController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.text(context), fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t ? 'முடிவு KM' : 'End KM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {
                    _useManualOverride = true; // Auto-activate override when user manually types End KM
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Override Switch
          SwitchListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            contentPadding: EdgeInsets.zero,
            title: Text(
              t ? 'ஓடோமீட்டர் கொண்டு மேலெழுத (Override)' : 'Override GPS with Manual Odometer',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
            ),
            value: _useManualOverride,
            activeColor: AppColors.roleTankerDriver,
            onChanged: (val) => setState(() => _useManualOverride = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoHaltCard(bool t, int billableWaitMins) {
    final totalHaltMins = (_autoHaltSeconds / 60).floor();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandSky.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.brandSky, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t ? 'தானியங்கி காத்திருப்பு நேரம் (GPS Idle)' : 'Automatic Halt / Waiting Timing',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.text(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandSky.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AUTO TRACKED',
                  style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.brandSky),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t
                ? 'வாகனம் நின்ற நேரத்தை GPS தானாகவே கணக்கிடுகிறது. இலவச நேரம்: $_freeWaitingGraceMins நிமிடங்கள்.'
                : 'GPS automatically logs site idle time. Free grace period: $_freeWaitingGraceMins mins.',
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textDim(context)),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? 'மொத்த நிறுத்த நேரம்' : 'Total Halted Time',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context)),
                    ),
                    Text(
                      '$totalHaltMins Mins (${_formatDuration(_autoHaltSeconds)})',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text(context)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t ? 'கட்டணக் காத்திருப்பு' : 'Billable Waiting',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim(context)),
                    ),
                    Text(
                      '$billableWaitMins Mins (+₹${(billableWaitMins * _waitingRatePerMin).toStringAsFixed(0)})',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorPumpingCard(bool t) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      borderColor: AppColors.brandPurple.withOpacity(0.5),
      tintColor: AppColors.brandPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt, color: AppColors.brandPurple, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t ? 'இறக்குதல் மோட்டார் (ஒரே மேனுவல் பதிவு)' : 'Motor Pumping (Only Manual Entry)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.text(context)),
                      ),
                      Text(
                        t ? 'பயன்படுத்திய நேரத்தை மட்டும் உள்ளிடவும்' : 'Simply enter pumping duration',
                        style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textDim(context)),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _motorUsed,
                activeColor: AppColors.brandPurple,
                onChanged: (v) => setState(() => _motorUsed = v),
              ),
            ],
          ),

          if (_motorUsed) ...[
            const SizedBox(height: 14),

            // Live Pump Stopwatch Button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPumpRunning
                              ? (t ? 'மோட்டார் இயங்குகிறது...' : 'Motor Pumping Active...')
                              : (t ? 'மோட்டார் நேர அளவி' : 'Live Pump Stopwatch'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isPumpRunning ? AppColors.brandEmerald : AppColors.text(context),
                          ),
                        ),
                        Text(
                          _formatDuration(_pumpStopwatchSeconds),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandPurple),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(_isPumpRunning ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(_isPumpRunning ? (t ? 'நிறுத்து' : 'Stop') : (t ? 'துவங்கு' : 'Start Pump')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPumpRunning ? Colors.red.shade700 : AppColors.brandPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _toggleMotorPumpStopwatch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Minute input field & quick preset pills
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _motorMinutesController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: t ? 'மோட்டார் நிமிடங்கள்' : 'Pumping Minutes',
                      suffixText: 'mins',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                // Preset chips
                ...[15, 30, 45, 60].map((mins) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _motorMinutesController.text = mins.toString();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${mins}m',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brandPurple),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rate: ₹$_motorRatePerMin/min · Charge: +₹${((int.tryParse(_motorMinutesController.text) ?? 0) * _motorRatePerMin).toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.brandEmerald),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(bool t) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t ? 'வாகன செலவு சீட்டுகள் (விருப்பத்தேர்வு)' : 'Vehicle Trip Vouchers (Optional)',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDim(context)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tollController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.text(context), fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t ? 'டோல் கேட் (₹)' : 'Toll Gate (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _dieselController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.text(context), fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: t ? 'டீசல் சீட்டு (₹)' : 'Diesel Voucher (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _receiverController,
            style: TextStyle(color: AppColors.text(context), fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              labelText: t ? 'தள மேற்பார்வையாளர் பெயர்' : 'Site Receiver / Contact',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBillPreviewCard(
    bool t,
    double totalFare,
    double excessKm,
    int billableWaitMins,
  ) {
    final capKl = (_selectedTanker?['capacity_kl'] as num? ?? 20.0).toDouble();
    final baseFare = capKl * 140.0;
    final excessKmCharge = excessKm * _excessKmRate;
    final motorMins = int.tryParse(_motorMinutesController.text) ?? 0;
    final motorCharge = _motorUsed ? (motorMins * _motorRatePerMin) : 0.0;
    final waitCharge = billableWaitMins * _waitingRatePerMin;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      tintColor: AppColors.brandPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t ? 'மொத்த பில் கட்டணம்' : 'Total Billed Amount',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
              ),
              Text(
                '₹ ${totalFare.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border(context)),
          const SizedBox(height: 6),

          // Transparent Bill Line Items
          _buildBillLineItem(
            t ? '${capKl.toStringAsFixed(0)}KL பல்க் நீர் அடிப்படை கட்டணம்' : '${capKl.toStringAsFixed(0)}KL Bulk Water Base Trip (incl. ${_baseFreeKm.toStringAsFixed(0)} KM)',
            '₹ ${baseFare.toStringAsFixed(2)}',
          ),
          if (excessKm > 0)
            _buildBillLineItem(
              'Excess Distance (${excessKm.toStringAsFixed(1)} KM @ ₹$_excessKmRate/KM)',
              '₹ ${excessKmCharge.toStringAsFixed(2)}',
            ),
          if (_motorUsed && motorCharge > 0)
            _buildBillLineItem(
              'Motor Pumping Service ($motorMins mins @ ₹$_motorRatePerMin/min)',
              '₹ ${motorCharge.toStringAsFixed(2)}',
            ),
          if (waitCharge > 0)
            _buildBillLineItem(
              'Site Waiting Delay ($billableWaitMins mins @ ₹$_waitingRatePerMin/min)',
              '₹ ${waitCharge.toStringAsFixed(2)}',
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTripSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      t ? 'ட்ரிப் தாள் சமர்ப்பித்து லெட்ஜரில் பதிவு செய்' : 'Submit Tanker Trip Sheet & Post to ERP',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillLineItem(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '• $title',
              style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text(context)),
          ),
        ],
      ),
    );
  }
}
