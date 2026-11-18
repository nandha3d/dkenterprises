import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'ripple_components.dart';

class ModuleTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final int? badgeCount;
  final VoidCallback onTap;

  const ModuleTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? skin.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(skin.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              Color.alphaBlend(
                accent.withValues(alpha: isDark ? 0.10 : 0.045),
                skin.surface,
              ),
              skin.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(skin.cardRadius),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.24 : 0.16),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            RippleIconBadge(
              icon: icon,
              accentColor: accent,
              size: 46,
              iconSize: 24,
              radius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: skin.ink,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(color: skin.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? Color.lerp(accent, Colors.white, 0.24)
                      : accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

