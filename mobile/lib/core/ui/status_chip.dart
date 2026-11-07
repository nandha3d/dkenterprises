import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum DocumentStatus {
  draft,
  pending,
  approved,
  paid,
  overdue,
  cancelled,
  synced,
  syncing,
  offline,
}

class StatusChip extends StatelessWidget {
  final DocumentStatus status;
  final String? customLabel;

  const StatusChip({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, icon, fgColor, bgColor) = switch (status) {
      DocumentStatus.draft => (
          customLabel ?? 'Draft',
          Icons.edit_note_rounded,
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
      DocumentStatus.pending => (
          customLabel ?? 'Pending',
          Icons.schedule_rounded,
          isDark ? AppColors.warningDark : AppColors.warning,
          isDark ? AppColors.chipWarningBgDark : AppColors.chipWarningBgLight,
        ),
      DocumentStatus.approved => (
          customLabel ?? 'Approved',
          Icons.check_circle_outline_rounded,
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.chipSuccessBgDark : AppColors.chipSuccessBgLight,
        ),
      DocumentStatus.paid => (
          customLabel ?? 'Paid',
          Icons.done_all_rounded,
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.chipSuccessBgDark : AppColors.chipSuccessBgLight,
        ),
      DocumentStatus.overdue => (
          customLabel ?? 'Overdue',
          Icons.error_outline_rounded,
          isDark ? AppColors.dangerDark : AppColors.danger,
          isDark ? AppColors.chipDangerBgDark : AppColors.chipDangerBgLight,
        ),
      DocumentStatus.cancelled => (
          customLabel ?? 'Cancelled',
          Icons.cancel_outlined,
          isDark ? AppColors.dangerDark : AppColors.danger,
          isDark ? AppColors.chipDangerBgDark : AppColors.chipDangerBgLight,
        ),
      DocumentStatus.synced => (
          customLabel ?? 'Synced',
          Icons.cloud_done_rounded,
          isDark ? AppColors.successDark : AppColors.success,
          isDark ? AppColors.chipSuccessBgDark : AppColors.chipSuccessBgLight,
        ),
      DocumentStatus.syncing => (
          customLabel ?? 'Syncing',
          Icons.sync_rounded,
          isDark ? AppColors.primaryDark : AppColors.primary,
          isDark ? AppColors.chipInfoBgDark : AppColors.chipInfoBgLight,
        ),
      DocumentStatus.offline => (
          customLabel ?? 'Offline',
          Icons.cloud_off_rounded,
          isDark ? AppColors.warningDark : AppColors.warning,
          isDark ? AppColors.chipWarningBgDark : AppColors.chipWarningBgLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fgColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

