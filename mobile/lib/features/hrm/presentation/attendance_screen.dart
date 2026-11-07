import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/status_chip.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  bool _isSubmitting = false;

  Future<void> _toggleAttendance() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final endpoint = _isCheckedIn ? ApiEndpoints.checkOut : ApiEndpoints.checkIn;
    final now = DateTime.now();

    final payload = {
      'timestamp': now.toIso8601String(),
      'type': _isCheckedIn ? 'check_out' : 'check_in',
      'lat': 11.0168, // Default Coimbature/Tiruppur coords or geolocator
      'lng': 76.9558,
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      endpoint,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isSubmitting = false;
        if (!_isCheckedIn) {
          _isCheckedIn = true;
          _checkInTime = now;
        } else {
          _isCheckedIn = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCheckedIn ? 'Checked in successfully!' : 'Checked out successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Offline queue
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: endpoint,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      setState(() {
        _isSubmitting = false;
        if (!_isCheckedIn) {
          _isCheckedIn = true;
          _checkInTime = now;
        } else {
          _isCheckedIn = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance recorded offline! Will sync automatically.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance & Shift'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        children: [
          // Employee Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.name ?? 'Field Staff',
                          style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                        ),
                        Text(
                          'Designation: ${authState.user?.role.toUpperCase() ?? "STAFF"}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    status: _isCheckedIn ? DocumentStatus.approved : DocumentStatus.draft,
                    customLabel: _isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Big Circular Punch Button
          Center(
            child: InkWell(
              onTap: _isSubmitting ? null : _toggleAttendance,
              borderRadius: BorderRadius.circular(90),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCheckedIn ? AppColors.danger : AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: (_isCheckedIn ? AppColors.danger : AppColors.success).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCheckedIn ? Icons.logout_rounded : Icons.fingerprint_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('hh:mm a').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          if (_checkInTime != null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Shift Started Today at ${DateFormat('hh:mm a').format(_checkInTime!)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
