import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TankerTripSheetScreen extends StatefulWidget {
  final bool isTamil;

  const TankerTripSheetScreen({super.key, required this.isTamil});

  @override
  State<TankerTripSheetScreen> createState() => _TankerTripSheetScreenState();
}

class _TankerTripSheetScreenState extends State<TankerTripSheetScreen> {
  final ApiService _apiService = ApiService();

  // Dynamic Tanker fleet (TMWS)
  final List<Map<String, dynamic>> _tankers = [
    {'id': 1, 'number': 'TN 34 AF 4954', 'capacity_kl': 20.0, 'chambers': 2, 'driver': 'Suresh Kumar'},
    {'id': 2, 'number': 'TN 33 BK 8821', 'capacity_kl': 40.0, 'chambers': 3, 'driver': 'P. Murugan'},
    {'id': 3, 'number': 'TN 38 CH 1204', 'capacity_kl': 10.0, 'chambers': 1, 'driver': 'K. Raman'},
  ];

  late Map<String, dynamic> _selectedTanker;

  final _odometerStartController = TextEditingController(text: '142810');
  final _odometerEndController = TextEditingController(text: '142865');
  final _waitingHoursController = TextEditingController(text: '2.0');
  final _tollController = TextEditingController(text: '180');
  final _dieselController = TextEditingController(text: '1200');
  final _receiverController = TextEditingController(text: 'Kaliappan (Site In-charge)');

  bool _motorUsed = true;
  final int _motorMinutes = 45;
  final String _selectedDestination = 'டெக்ஸ்வேலி கார்ப்பரேட் (Texvalley Corporate, Erode)';
  int _selectedChamber = 0; // 0 for All, 1 for Chamber 1, 2 for Chamber 2

  bool _isSubmitting = false;
  bool _gatePassAttached = true;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _selectedTanker = _tankers[0];
  }

  double _calculateTotalFare() {
    final capKl = (_selectedTanker['capacity_kl'] as num).toDouble();
    final baseFare = capKl * 150.0; // Dynamic rate per KL
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
    setState(() => _isSubmitting = true);

    final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
    final endKm = int.tryParse(_odometerEndController.text) ?? 142865;
    final totalKm = (endKm - startKm).clamp(0, 9999);
    final excessKm = (totalKm - 40).clamp(0, 9999);

    final totalFare = _calculateTotalFare();
    final tripNo = 'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    final tripRecord = TankerTripRecord(
      tripNumber: tripNo,
      tankerId: _selectedTanker['id'] as int,
      vehicleNumber: _selectedTanker['number'] as String,
      capacityKl: (_selectedTanker['capacity_kl'] as num).toDouble(),
      customerName: _selectedDestination,
      loadSource: 'Borewell Plant 1 (Perundurai)',
      destinationSite: _selectedDestination,
      startKm: startKm,
      endKm: endKm,
      excessKm: excessKm,
      excessKmCharge: excessKm * 15.0,
      motorUsed: _motorUsed,
      motorMinutes: _motorMinutes,
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
      setState(() {
        _isSubmitting = false;
        _successMessage = widget.isTamil
            ? 'ட்ரிப் சீட் [$tripNo] வெற்றிகரமாக முடிக்கப்பட்டு கணக்கு ஏட்டில் சேர்க்கப்பட்டது! பில்: ₹${totalFare.toStringAsFixed(2)}'
            : 'Trip sheet [$tripNo] completed & posted to General Ledger! Amount: ₹${totalFare.toStringAsFixed(2)}';
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _successMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startKm = int.tryParse(_odometerStartController.text) ?? 142810;
    final endKm = int.tryParse(_odometerEndController.text) ?? 142865;
    final totalKm = (endKm - startKm).clamp(0, 9999);
    final totalFare = _calculateTotalFare();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Trip Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2563EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTanker['number'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_selectedTanker['capacity_kl']} KL (${_selectedTanker['chambers']} Chambers)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.isTamil ? "ஓட்டுனர்" : "Driver"}: ${_selectedTanker['driver']}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDestination,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // 1. Tanker Vehicle Selector
          Text(
            widget.isTamil ? 'டேங்கர் லாரி தேர்வு (Vehicle):' : 'Select Water Tanker Fleet:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: _selectedTanker,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: _tankers.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${t['number']} — ${t['capacity_kl']} KL (${t['driver']})',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTanker = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Chamber Split Decanting
          if ((_selectedTanker['chambers'] as int) > 1) ...[
            Text(
              widget.isTamil ? 'சேம்பர் இறக்குதல் (Chamber Split Decanting):' : 'Compartment Chamber Split:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChamberPill(0, widget.isTamil ? 'முழு கொள்ளளவு' : 'Full Tanker'),
                const SizedBox(width: 8),
                _buildChamberPill(1, widget.isTamil ? 'சேம்பர் 1' : 'Chamber 1'),
                const SizedBox(width: 8),
                _buildChamberPill(2, widget.isTamil ? 'சேம்பர் 2' : 'Chamber 2'),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 3. Odometer Reading (Start -> End)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isTamil ? 'தொடக்க ஓடோமீட்டர்:' : 'Start Odometer:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _odometerStartController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isTamil ? 'முடிவு ஓடோமீட்டர்:' : 'End Odometer:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _odometerEndController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(widget.isTamil ? 'மொத்தம்' : 'Total KM', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text('$totalKm km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Ground Surcharges (Motor Pumping + Site Waiting + Toll)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                // Motor Pumping Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFBBF24), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.isTamil ? 'மோட்டார் மூலம் இறைப்பு (+₹250):' : 'Motor Pumping Surcharge (+₹250):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    Switch(
                      value: _motorUsed,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (val) => setState(() => _motorUsed = val),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B)),

                // Waiting Hours
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isTamil ? 'தளத்தில் காத்திருப்பு (மணி):' : 'Site Waiting Delay (Hrs):',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _waitingHoursController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tollgate
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isTamil ? 'டோல்கேட் கட்டணம் (₹):' : 'Toll Plaza / Misc (₹):',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _tollController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total Fare Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isTamil ? 'மொத்த வாடகை பில் தொகை:' : 'Grand Trip Invoice:',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '₹ ${totalFare.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Gate Pass & Site Receiver
          TextField(
            controller: _receiverController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: widget.isTamil ? 'வாங்கியவர் பெயர் / கையெழுத்து:' : 'Receiver Name / Gate Pass Signature:',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => setState(() => _gatePassAttached = !_gatePassAttached),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gatePassAttached ? const Color(0xFF10B981) : const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Icon(_gatePassAttached ? Icons.check_circle : Icons.camera_alt, color: _gatePassAttached ? const Color(0xFF34D399) : const Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gatePassAttached
                          ? (widget.isTamil ? '📸 கேட் பாஸ் ரசீது படம் இணைக்கப்பட்டது' : '📸 Gate pass slip photo attached')
                          : (widget.isTamil ? '📸 கேட் பாஸ் புகைப்படம் எடு' : '📸 Snap Gate Pass Photo'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gatePassAttached ? Colors.white : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Complete Trip Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTripSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isTamil ? '✅ பயணத்தை முடி (COMPLETE TRIP SHEET)' : '✅ COMPLETE TRIP SHEET',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberPill(int chamberIndex, String label) {
    final isSelected = _selectedChamber == chamberIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChamber = chamberIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
