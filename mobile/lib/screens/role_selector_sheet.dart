import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class RoleSelectorSheet extends StatefulWidget {
  final bool isTamil;
  final UserRole currentRole;
  final CompanyVertical currentVertical;
  final ValueChanged<UserRole> onSelectRole;
  final ValueChanged<CompanyVertical> onSelectVertical;

  const RoleSelectorSheet({
    super.key,
    required this.isTamil,
    required this.currentRole,
    required this.currentVertical,
    required this.onSelectRole,
    required this.onSelectVertical,
  });

  @override
  State<RoleSelectorSheet> createState() => _RoleSelectorSheetState();
}

class _RoleSelectorSheetState extends State<RoleSelectorSheet> {
  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final isDark = AppColors.isDark(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF021840).withOpacity(0.92) : Colors.white.withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(isDark ? 0.2 : 0.6),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim(context).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brandPurple, AppColors.brandNavy],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.switch_account, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t ? 'பயனர் பங்கு தேர்வு (Switch Role)' : 'Switch Operational Role',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.text(context),
                            ),
                          ),
                          Text(
                            t ? 'அனைத்து பாத்திரங்களும் சோதனைக்கு கிடைக்கும்' : 'All 6 Roles Available for Instant Access',
                            style: TextStyle(
                              color: AppColors.textMuted(context),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textDim(context), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live API Target Box
              GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                tintColor: AppColors.brandPurple,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, color: AppColors.brandEmerald, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE API: ${ApiService.activeBaseUrl.replaceFirst('https://', '')}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandEmerald.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ONLINE',
                        style: TextStyle(color: AppColors.brandEmerald, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Role List Cards
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: UserRole.values.map((role) {
                    final isSelected = widget.currentRole == role;
                    return GlassCard(
                      isInteractive: true,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      borderRadius: 14,
                      tintColor: isSelected ? role.color : null,
                      borderColor: isSelected ? role.color : null,
                      borderWidth: isSelected ? 1.5 : 1.0,
                      onTap: () {
                        widget.onSelectRole(role);
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: role.color.withOpacity(isSelected ? 0.95 : 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              role.icon,
                              color: isSelected ? Colors.white : role.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.title(t),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: isSelected ? role.color : AppColors.text(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.description(t),
                                  style: TextStyle(
                                    color: AppColors.textDim(context),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: role.color, size: 18)
                          else
                            Icon(Icons.chevron_right, color: AppColors.textDim(context), size: 18),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
