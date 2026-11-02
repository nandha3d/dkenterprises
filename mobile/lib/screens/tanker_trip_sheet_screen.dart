import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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

  final _odometerStartController = TextEditingController(text: '142810');
  final _odometerEndController = TextEditingController(text: '142865');
  final _waitingHoursController = TextEditingController(text: '2.0');
  final _tollController = TextEditingController(text: '180');
  final _dieselController = TextEditingController(text: '1200');
  final _receiverController = TextEditingController(text: 'Site Receiver');

  bool _motorUsed = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFleetAndDestinations();
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
          // Dynamic fallback based on TMWS specs
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

  double _calculateTotalFare() {
    if (_selectedTanker == null) return 0.0;
    final capKl = (_selectedTanker!['capacity_kl'] as num? ?? 20.0).toDouble();
    final baseFare = capKl * 150.0;
    final motorCharge = _motorUsed ? 250.0 : 0.0;
    final waitingCharge = (double.tryParse(_waitingHoursController.text) ?? 0.0) * 150.0;
    final toll = double.tryParse(_tollController.text) ?? 0.0;

    final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
    final endKm = int.tryParse(_odometerEndController.text) ?? 142865;
    final totalKm = (endKm - startKm).clamp(0, 9999);
    final excessKm = (totalKm - 40).clamp(0, 9999);
    final excessKmCharge = excessKm * 15.0;

    return baseFare + motorCharge + waitingCharge + excessKmCharge + toll;
  }

  Future<void> _submitTripSheet() async {
    if (_selectedTanker == null) return;
    setState(() => _isSubmitting = true);

    final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
    final endKm = int.tryParse(_odometerEndController.text) ?? 142865;
    final totalKm = (endKm - startKm).clamp(0, 9999);
    final excessKm = (totalKm - 40).clamp(0, 9999);

    final totalFare = _calculateTotalFare();
    final tripNo = 'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final destinationName = _selectedDestination != null ? (_selectedDestination!['name'] ?? 'Site') : 'Commercial Site';

    final tripRecord = TankerTripRecord(
      tripNumber: tripNo,
      tankerId: _selectedTanker!['id'] as int? ?? 1,
      vehicleNumber: (_selectedTanker!['number'] ?? _selectedTanker!['tanker_no'] ?? 'TN-34-AF').toString(),
      capacityKl: (_selectedTanker!['capacity_kl'] as num? ?? 20.0).toDouble(),
      customerName: destinationName,
      loadSource: 'Borewell Plant (Perundurai)',
      destinationSite: destinationName,
      startKm: startKm,
      endKm: endKm,
      excessKm: excessKm,
      excessKmCharge: excessKm * 15.0,
      motorUsed: _motorUsed,
      motorMinutes: 45,
      motorCharge: _motorUsed ? 250.0 : 0.0,
      waitingHours: double.tryParse(_waitingHoursController.text) ?? 2.0,
      waitingCharge: (double.tryParse(_waitingHoursController.text) ?? 2.0) * 150.0,
      tollExpense: double.tryParse(_tollController.text) ?? 180.0,
      driverBatta: 250.0,
      dieselExpense: double.tryParse(_dieselController.text) ?? 1200.0,
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
                ? 'டேங்கர் ட்ரிப் ஷீட் [$tripNo] பதிவானது! கட்டணம்: ₹${totalFare.toStringAsFixed(2)}'
                : 'Tanker trip sheet [$tripNo] posted to ERP! Total: ₹${totalFare.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final totalFare = _calculateTotalFare();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fleet Header Card
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    tintColor: AppColors.brandNavy,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandNavy, AppColors.brandPurple],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.fire_truck, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t ? 'பல்க் டேங்கர் ட்ரிப் & இறக்குதல்' : 'Bulk Tanker Trips & Logistics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t ? 'TMWS வணிக நீர் விநியோக கப்பற்படை' : 'TMWS Commercial Bulk Fleet (10KL - 40KL)',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tanker Fleet Selector
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t ? 'டேங்கர் வாகனத் தேர்வு' : 'Select Tanker Vehicle',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedTanker,
                          style: TextStyle(color: AppColors.text(context), fontSize: 13),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Distance & Motor Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _odometerStartController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: t ? 'துவக்க KM' : 'Start KM',
                                  labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _odometerEndController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: t ? 'முடிவு KM' : 'End KM',
                                  labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t ? 'இறக்குதல் மோட்டார் பயன்பாடு (+₹250)' : 'Unloading Motor Used (+₹250)',
                              style: TextStyle(fontSize: 12, color: AppColors.text(context), fontWeight: FontWeight.w600),
                            ),
                            Switch(
                              value: _motorUsed,
                              activeColor: AppColors.brandPurple,
                              onChanged: (v) => setState(() => _motorUsed = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tollController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: t ? 'டோல் கேட் கட்டணம் (₹)' : 'Toll Expense (₹)',
                                  labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _dieselController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppColors.text(context), fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: t ? 'டீசல் செலவு (₹)' : 'Diesel Voucher (₹)',
                                  labelStyle: TextStyle(color: AppColors.textDim(context), fontSize: 11),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Fare & Submit Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 22,
                    tintColor: AppColors.brandPurple,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t ? 'ட்ரிப் மொத்த கட்டணம்' : 'Total Billed Fare',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)),
                            ),
                            Text(
                              '₹${totalFare.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brandEmerald),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
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
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
