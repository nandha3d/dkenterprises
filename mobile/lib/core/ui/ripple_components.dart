import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Computes a responsive grid tile height scaled to the user's font scale
/// so action/menu cards stay compact at default scale and never overflow
/// when large accessibility text is enabled.
double rippleGridTileExtent(
  BuildContext context, {
  double baseHeight = 72.0,
  double textBudget = 58.0,
}) {
  final textScale = math.max(
    1.0,
    MediaQuery.textScalerOf(context).scale(14.0) / 14.0,
  );
  return baseHeight + (textBudget * textScale);
}

/// Honest status badge + info banner for Stitch UI features that require
/// additional backend API endpoints (see docs/11_STITCH_UI_BACKEND_ALIGNMENT_AND_GAPS.md).
class BackendPendingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String proposedEndpoint;
  final IconData icon;

  const BackendPendingTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.proposedEndpoint,
    this.icon = Icons.pending_actions_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = isDark ? AppColors.chipWarningBgDark : AppColors.chipWarningBgLight;
    final badgeFg = isDark ? AppColors.warningDark : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: skin.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: badgeFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: AppTypography.bodyMedium.copyWith(color: skin.ink)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                        border: Border.all(color: badgeFg.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'Backend API Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption.copyWith(color: skin.muted)),
                const SizedBox(height: 4),
                Text(
                  'Planned endpoint: $proposedEndpoint',
                  style: TextStyle(
                    fontFamily: AppTypography.fontMono,
                    fontSize: 11,
                    color: skin.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch "Ripple" Role Hero Card with 28px corner radius and primary gradient.
class RippleHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String? subheadline;
  final Widget? trailing;
  final List<Widget> pills;

  const RippleHeroBanner({
    super.key,
    required this.eyebrow,
    required this.headline,
    this.subheadline,
    this.trailing,
    this.pills = const [],
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradStart = isDark ? skin.surface2 : skin.primary;
    final gradEnd = isDark
        ? skin.primary.withValues(alpha: 0.25)
        : Color.lerp(skin.primary, Colors.black, 0.22)!;
    final onHero = isDark ? skin.ink : Colors.white;
    final onHeroMuted = isDark ? skin.muted : Colors.white.withValues(alpha: 0.82);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(skin.heroRadius),
        border: isDark ? Border.all(color: skin.hairline) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: isDark ? skin.primary : skin.action,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      headline,
                      style: AppTypography.numberDisplay.copyWith(color: onHero, fontSize: 26),
                    ),
                    if (subheadline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subheadline!,
                        style: AppTypography.caption.copyWith(color: onHeroMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: pills),
          ],
        ],
      ),
    );
  }
}

/// Layered gradient squircle medallion for operation, module, and action icons.
class RippleIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final double size;
  final double iconSize;
  final double radius;

  const RippleIconBadge({
    super.key,
    required this.icon,
    required this.accentColor,
    this.size = 46,
    this.iconSize = 24,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? Color.lerp(accentColor, Colors.white, 0.28)!
        : Color.lerp(accentColor, Colors.black, 0.08)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
                  accentColor.withValues(alpha: 0.34),
                  accentColor.withValues(alpha: 0.14),
                ]
              : [
                  accentColor.withValues(alpha: 0.22),
                  accentColor.withValues(alpha: 0.08),
                ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.44 : 0.26),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.20 : 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: 2,
            start: 3,
            end: 3,
            height: size * 0.36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular((radius - 2).clamp(4.0, radius)),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.14 : 0.50),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(icon, color: foreground, size: iconSize),
        ],
      ),
    );
  }
}

/// Compact, visually balanced bento menu tile with layered icon medallion,
/// optional pill badge, launch affordance, and subtle background watermark.
class RippleMenuTileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? accentColor;
  final String? badge;
  final IconData trailingIcon;
  final bool enabled;
  final double iconBoxSize;
  final double iconSize;

  const RippleMenuTileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.badge,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.enabled = true,
    this.iconBoxSize = 44,
    this.iconSize = 23,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawAccent = accentColor ?? skin.primary;
    final effectiveAccent = enabled ? rawAccent : skin.muted;
    final tint = isDark
        ? Color.lerp(effectiveAccent, Colors.white, 0.24)!
        : effectiveAccent;

    final cardGradient = LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        Color.alphaBlend(
          effectiveAccent.withValues(alpha: isDark ? 0.14 : 0.065),
          skin.surface,
        ),
        skin.surface,
      ],
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.52,
      child: Container(
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          border: Border.all(
            color: enabled
                ? effectiveAccent.withValues(alpha: isDark ? 0.30 : 0.20)
                : skin.hairline,
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : effectiveAccent)
                  .withValues(alpha: isDark ? 0.18 : 0.055),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(skin.cardRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(skin.cardRadius),
              child: Stack(
                children: [
                  PositionedDirectional(
                    end: -10,
                    bottom: -10,
                    child: ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: 62,
                        color: effectiveAccent.withValues(
                          alpha: isDark ? 0.075 : 0.055,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RippleIconBadge(
                              icon: icon,
                              accentColor: effectiveAccent,
                              size: iconBoxSize,
                              iconSize: iconSize,
                              radius: 13,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (badge != null && badge!.isNotEmpty) ...[
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: effectiveAccent.withValues(
                                            alpha: isDark ? 0.22 : 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              skin.pillRadius),
                                          border: Border.all(
                                            color: effectiveAccent
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Text(
                                          badge!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.caption.copyWith(
                                            color: tint,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 9.5,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: effectiveAccent.withValues(
                                        alpha: isDark ? 0.20 : 0.10,
                                      ),
                                    ),
                                    child: Icon(
                                      trailingIcon,
                                      size: 15,
                                      color: tint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                color: skin.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: skin.muted,
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive card action tile following Ripple 20px geometry and min-44px touch targets.
class RippleActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final String? badge;

  const RippleActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final accent = accentColor ?? skin.primary;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(skin.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(skin.cardRadius),
              border: Border.all(color: skin.hairline),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.bodyMedium.copyWith(color: skin.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(skin.pillRadius),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(color: skin.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: skin.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// High-contrast clickable pill button inside [RippleHeroBanner].
/// Uses explicit [Material] + [Container] colors instead of Material 3 [ActionChip]
/// so text and icon contrast remains legible over hero gradients in all themes.
class RippleHeroPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const RippleHeroPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final bgColor = isPrimary ? skin.action : Colors.black.withValues(alpha: 0.28);
    final fgColor = isPrimary ? skin.actionInk : Colors.white;
    final borderColor = isPrimary ? skin.action : Colors.white.withValues(alpha: 0.34);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(skin.pillRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(skin.pillRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(skin.pillRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fgColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

