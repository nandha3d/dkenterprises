import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PlantRefillScreen extends StatefulWidget {
  final bool isTamil;

  const PlantRefillScreen({super.key, required this.isTamil});

  @override
  State<PlantRefillScreen> createState() => _PlantRefillScreenState();
}

class _PlantRefillScreenState extends State<PlantRefillScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _slipController = TextEditingController(text: 'RO-2026-9941');
  final TextEditingController _odometerController = TextEditingController(text: '54210');

  int _loadSequence = 2; // Load 2
  int _cansLoaded = 84;
  final String _plantName = 'Main RO Water Treatment Plant (Erode)';
  bool _isSubmitting = false;
  bool _slipPhotoAttached = true;
  String? _successMessage;

  // History of loads today
  final List<Map<String, dynamic>> _loadsToday = [
    {'sequence': 1, 'time': '07:30 AM', 'cans': 72, 'slip': 'RO-2026-9912'},
  ];

  void _stepLoaded(int delta) {
    setState(() {
      final next = _cansLoaded + delta;
      if (next >= 5) _cansLoaded = next;
    });
  }

  Future<void> _submitRefill() async {
    setState(() => _isSubmitting = true);

    final record = PlantRefillRecord(
      loadSequence: _loadSequence,
      plantName: _plantName,
      cansLoaded: _cansLoaded,
      ratePerCan: 8.00,
      slipNumber: _slipController.text,
      odometerKm: int.tryParse(_odometerController.text) ?? 54210,
      timestamp: DateTime.now(),
    );

    await _apiService.submitPlantRefill(record, 1);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _loadsToday.add({
          'sequence': _loadSequence,
          'time': DateTime.now().toLocal().toString().substring(11, 16),
          'cans': _cansLoaded,
          'slip': _slipController.text,
        });
        _loadSequence++;
        _successMessage = widget.isTamil
            ? 'ஆலை கேன் ஏற்றுதல் வெற்றிகரமாக பதிவானது! வண்டியில் +$_cansLoaded கேன்கள் சேர்க்கப்பட்டன.'
            : 'Plant refill logged! +$_cansLoaded units added to Tata Ace truck stock.';
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _successMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalShiftCans = _loadsToday.fold<int>(0, (sum, item) => sum + (item['cans'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF059669)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.factory, color: Color(0xFF34D399), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTamil ? 'ஆலை கேன் ஏற்றுதல் (Plant Refill)' : 'Plant Refill Intake Logger',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      Text(
                        '$_plantName · ${widget.isTamil ? "லோடு" : "Load"} #$_loadSequence',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
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

          // 1. Cans Loaded Counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Text(
                  widget.isTamil ? 'ஏற்றப்படும் குடிநீர் கேன்கள் எண்ணிக்கை:' : 'Packaged Water Units Loaded:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_cansLoaded',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepBtn('-10', () => _stepLoaded(-10)),
                    const SizedBox(width: 8),
                    _buildStepBtn('-5', () => _stepLoaded(-5)),
                    const SizedBox(width: 8),
                    _buildStepBtn('+5', () => _stepLoaded(5)),
                    const SizedBox(width: 8),
                    _buildStepBtn('+10', () => _stepLoaded(10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Slip Number & Odometer Reading
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isTamil ? 'ஆலை ரசீது எண் (Slip No):' : 'Plant Slip No:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _slipController,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isTamil ? 'ஓடோமீட்டர் (KM):' : 'Odometer Reading:',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111827),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Photo Proof Attachment
          GestureDetector(
            onTap: () => setState(() => _slipPhotoAttached = !_slipPhotoAttached),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _slipPhotoAttached ? const Color(0xFF10B981) : const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Icon(_slipPhotoAttached ? Icons.check_circle : Icons.camera_alt, color: _slipPhotoAttached ? const Color(0xFF34D399) : const Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _slipPhotoAttached
                          ? (widget.isTamil ? '📸 ஆலை ரசீது புகைப்படம் இணைக்கப்பட்டது' : '📸 Plant slip photo captured')
                          : (widget.isTamil ? '📸 ஆலை ரசீது படம் எடு (Snap Slip Photo)' : '📸 Snap Plant Slip Photo'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _slipPhotoAttached ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRefill,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isTamil ? '✅ ஏற்றுதல் உறுதிசெய் (CONFIRM LOAD #$_loadSequence)' : '✅ CONFIRM LOAD #$_loadSequence',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // 5. Shift Refill History
          Text(
            widget.isTamil ? 'இன்றைய ஆலை லோடுகள் (Shift Loads):' : 'Today’s Plant Loads Summary:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                ..._loadsToday.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text('Load #${item['sequence']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                            ),
                            const SizedBox(width: 8),
                            Text('${item['time']} · Slip: ${item['slip']}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        Text('+${item['cans']} Units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  );
                }),
                const Divider(color: Color(0xFF334155)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.isTamil ? 'மொத்த ஏற்றப்பட்ட இருப்பு:' : 'Total Shift Loaded:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('$totalShiftCans Units', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 34,
      width: 48,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
