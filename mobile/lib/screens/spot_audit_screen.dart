import 'package:flutter/material.dart';

class SpotAuditScreen extends StatefulWidget {
  final bool isTamil;

  const SpotAuditScreen({super.key, required this.isTamil});

  @override
  State<SpotAuditScreen> createState() => _SpotAuditScreenState();
}

class _SpotAuditScreenState extends State<SpotAuditScreen> {
  final _cansObservedController = TextEditingController(text: '25');
  final _cashObservedController = TextEditingController(text: '1810');
  bool _auditDone = false;

  final int _expectedCans = 25;
  final double _expectedCash = 1810.0;

  void _runAudit() {
    setState(() => _auditDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final observedCans = int.tryParse(_cansObservedController.text) ?? 0;
    final observedCash = double.tryParse(_cashObservedController.text) ?? 0.0;
    final canDiff = observedCans - _expectedCans;
    final cashDiff = observedCash - _expectedCash;
    final isClean = (canDiff == 0 && cashDiff == 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFFFBBF24), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTamil ? 'திடீர் களத் தணிக்கை (ஸ்பாட் ஆடிட்)' : 'Surprise Field Spot Audit',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        widget.isTamil ? 'டாடா ஏஸ் (TN 38 BX 4412) • ராஜா' : 'Tata Ace (TN 38 BX 4412) • Raja',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Physical Inspection Inputs
          Text(
            widget.isTamil ? 'வண்டியில் நேரில் எண்ணப்பட்ட கேன்கள்:' : 'Physical Cans Counted on Truck:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cansObservedController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            widget.isTamil ? 'ஓட்டுனரிடம் உள்ள நேரடி பணம் (Cash ₹):' : 'Physical Cash in Driver Hand (₹):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cashObservedController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _runAudit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.fact_check, color: Colors.white),
            label: Text(
              widget.isTamil ? 'கணக்கை சரிபார் (VERIFY AUDIT)' : 'RUN SPOT AUDIT RECONCILER',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),

          // Audit Results Box
          if (_auditDone)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isClean ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isClean ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
              ),
              child: Column(
                children: [
                  Icon(isClean ? Icons.check_circle : Icons.warning_amber, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    isClean
                        ? (widget.isTamil ? '100% கணக்கு சரியானது! திருட்டு இல்லை' : '100% RECONCILED! ZERO PILFERAGE')
                        : (widget.isTamil ? 'வித்தியாசம் கண்டறியப்பட்டது! விளக்கம் தேவை' : 'DISCREPANCY FLAGGED! INVESTIGATE'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(widget.isTamil ? 'எதிர்பார்க்கப்பட்டது' : 'Expected Cans', style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                          Text('$_expectedCans Cans', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(widget.isTamil ? 'நேரில் இருந்தது' : 'Observed Cans', style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                          Text('$observedCans Cans', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(widget.isTamil ? 'வித்தியாசம்' : 'Variance', style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                          Text('$canDiff Cans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: canDiff == 0 ? const Color(0xFF34D399) : const Color(0xFFFCA5A5))),
                        ],
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
}
