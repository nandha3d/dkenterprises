import 'package:flutter/material.dart';

class TankerTripSheetScreen extends StatefulWidget {
  final bool isTamil;

  const TankerTripSheetScreen({super.key, required this.isTamil});

  @override
  State<TankerTripSheetScreen> createState() => _TankerTripSheetScreenState();
}

class _TankerTripSheetScreenState extends State<TankerTripSheetScreen> {
  final _odometerController = TextEditingController(text: '142865');
  final _waitingHoursController = TextEditingController(text: '2.0');
  final _tollController = TextEditingController(text: '180');
  bool _motorUsed = true;
  bool _tripSubmitted = false;

  void _submitTripSheet() {
    setState(() => _tripSubmitted = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _tripSubmitted = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: const Color(0xFF0284C7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TRP-2026-0841',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('24.0 KL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'டெக்ஸ்வேலி கேம்பஸ் (Texvalley Corporate)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'வண்டி: TN 34 AF 4954 • ஓட்டுனர்: Suresh',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_tripSubmitted)
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
                      widget.isTamil ? 'ட்ரிப் சீட் வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது!' : 'Trip sheet submitted successfully!',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // 1. Odometer Closing
          Text(
            widget.isTamil ? 'இறுதி கிலோமீட்டர் (End Odometer KM):' : 'Closing Odometer (KM):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _odometerController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Motor Used Toggle (Extra Surcharge)
          SwitchListTile(
            value: _motorUsed,
            onChanged: (val) => setState(() => _motorUsed = val),
            title: Text(
              widget.isTamil ? 'மோட்டார் மூலம் இறைக்கப்பட்டது (Motor Used)' : 'Water Pumping Motor Used',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              widget.isTamil ? 'கூடுதல் கட்டணம்: +₹250' : 'Surcharge: +₹250',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
            ),
            tileColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            activeThumbColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 16),

          // 3. Waiting Time
          Text(
            widget.isTamil ? 'காத்திருப்பு நேரம் (Waiting Hours):' : 'Waiting Detention Time (Hours):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _waitingHoursController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Toll & Miscellaneous
          Text(
            widget.isTamil ? 'டோல்கேட் & இதர செலவு (Toll / Misc ₹):' : 'Toll / Miscellaneous (₹):',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _tollController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitTripSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                widget.isTamil ? 'ட்ரிப் சீட் சமர்ப்பி (SUBMIT TRIP)' : 'SUBMIT TRIP SHEET',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
