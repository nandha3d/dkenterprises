import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Canonical Stitch UI role profiles ("Ripple" Design System).
enum RippleRole {
  admin,
  driver,
  cafe,
  fieldAgent,
}

/// Distinguishes Can Delivery vs Tanker drivers within the Aqua Day driver skin.
enum RippleDriverFlavor {
  none,
  canDelivery,
  tanker,
}

/// Resolves the canonical [RippleRole] from authenticated user metadata.
RippleRole resolveRippleRole({
  String? role,
  String? username,
  String? email,
  List<String> roles = const [],
}) {
  final tokens = <String>[
    (role ?? '').toLowerCase(),
    (username ?? '').toLowerCase(),
    (email ?? '').toLowerCase(),
    ...roles.map((r) => r.toLowerCase()),
  ];
  bool hasAny(bool Function(String s) test) => tokens.any(test);

  if (hasAny((s) => s.contains('tanker')) ||
      hasAny((s) => s.contains('delivery') || s.contains('driver'))) {
    return RippleRole.driver;
  }
  if (hasAny((s) => s.contains('cashier') || s.contains('cafe') || s.contains('barista'))) {
    return RippleRole.cafe;
  }
  if (hasAny((s) => s.contains('agent') || s.contains('field'))) {
    return RippleRole.fieldAgent;
  }
  return RippleRole.admin;
}

/// Resolves whether a driver user runs packaged-can delivery or bulk tanker logistics.
RippleDriverFlavor resolveDriverFlavor({
  String? role,
  String? username,
  String? email,
  List<String> roles = const [],
}) {
  final tokens = <String>[
    (role ?? '').toLowerCase(),
    (username ?? '').toLowerCase(),
    (email ?? '').toLowerCase(),
    ...roles.map((r) => r.toLowerCase()),
  ];
  if (tokens.any((s) => s.contains('tanker'))) {
    return RippleDriverFlavor.tanker;
  }
  if (tokens.any((s) => s.contains('delivery') || s.contains('driver'))) {
    return RippleDriverFlavor.canDelivery;
  }
  return RippleDriverFlavor.none;
}

/// Immutable Stitch "Ripple" design tokens attached to Material [ThemeData] via [ThemeExtension].
@immutable
class RippleSkin extends ThemeExtension<RippleSkin> {
  final RippleRole role;
  final String skinName;
  final Color primary;
  final Color action;
  final Color actionInk;
  final Color canvas;
  final Color surface;
  final Color surface2;
  final Color hairline;
  final Color ink;
  final Color muted;
  final Color navBackground;
  final Color navActiveCircle;
  final Color navActiveIcon;
  final Color navInactiveIcon;
  final double heroRadius;
  final double cardRadius;
  final double inputRadius;
  final double pillRadius;

  const RippleSkin({
    required this.role,
    required this.skinName,
    required this.primary,
    required this.action,
    required this.actionInk,
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.hairline,
    required this.ink,
    required this.muted,
    required this.navBackground,
    required this.navActiveCircle,
    required this.navActiveIcon,
    required this.navInactiveIcon,
    this.heroRadius = 28,
    this.cardRadius = 20,
    this.inputRadius = 14,
    this.pillRadius = 9999,
  });

  static RippleSkin of(BuildContext context) {
    final ext = Theme.of(context).extension<RippleSkin>();
    if (ext != null) return ext;
    return forRole(RippleRole.admin, Theme.of(context).brightness);
  }

  static RippleSkin forRole(RippleRole role, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    if (isDark) {
      return switch (role) {
        RippleRole.admin => const RippleSkin(
            role: RippleRole.admin,
            skinName: 'Lagoon',
            primary: AppColors.lagoonDarkPrimary,
            action: AppColors.lagoonAction,
            actionInk: AppColors.rippleLightInk,
            canvas: AppColors.rippleDarkCanvas,
            surface: AppColors.rippleDarkSurface,
            surface2: AppColors.rippleDarkSurface2,
            hairline: AppColors.rippleDarkHairline,
            ink: AppColors.rippleDarkInk,
            muted: AppColors.rippleDarkMuted,
            navBackground: AppColors.rippleDarkSurface,
            navActiveCircle: AppColors.lagoonDarkPrimary,
            navActiveIcon: AppColors.rippleDarkCanvas,
            navInactiveIcon: AppColors.rippleDarkMuted,
          ),
        RippleRole.driver => const RippleSkin(
            role: RippleRole.driver,
            skinName: 'Aqua Day',
            primary: AppColors.aquaDarkPrimary,
            action: AppColors.aquaAction,
            actionInk: AppColors.rippleLightInk,
            canvas: AppColors.rippleDarkCanvas,
            surface: AppColors.rippleDarkSurface,
            surface2: AppColors.rippleDarkSurface2,
            hairline: AppColors.rippleDarkHairline,
            ink: AppColors.rippleDarkInk,
            muted: AppColors.rippleDarkMuted,
            navBackground: AppColors.rippleDarkSurface,
            navActiveCircle: AppColors.aquaDarkPrimary,
            navActiveIcon: AppColors.rippleDarkCanvas,
            navInactiveIcon: AppColors.rippleDarkMuted,
          ),
        RippleRole.cafe => const RippleSkin(
            role: RippleRole.cafe,
            skinName: 'Chai & Crema',
            primary: AppColors.chaiDarkPrimary,
            action: AppColors.chaiAction,
            actionInk: AppColors.rippleLightInk,
            canvas: AppColors.rippleDarkCanvas,
            surface: AppColors.rippleDarkSurface,
            surface2: AppColors.rippleDarkSurface2,
            hairline: AppColors.rippleDarkHairline,
            ink: AppColors.rippleDarkInk,
            muted: AppColors.rippleDarkMuted,
            navBackground: AppColors.rippleDarkSurface,
            navActiveCircle: AppColors.chaiDarkPrimary,
            navActiveIcon: AppColors.rippleDarkCanvas,
            navInactiveIcon: AppColors.rippleDarkMuted,
          ),
        RippleRole.fieldAgent => const RippleSkin(
            role: RippleRole.fieldAgent,
            skinName: 'Field Sage',
            primary: AppColors.sageDarkPrimary,
            action: AppColors.sageAction,
            actionInk: AppColors.rippleLightInk,
            canvas: AppColors.rippleDarkCanvas,
            surface: AppColors.rippleDarkSurface,
            surface2: AppColors.rippleDarkSurface2,
            hairline: AppColors.rippleDarkHairline,
            ink: AppColors.rippleDarkInk,
            muted: AppColors.rippleDarkMuted,
            navBackground: AppColors.rippleDarkSurface,
            navActiveCircle: AppColors.sageDarkPrimary,
            navActiveIcon: AppColors.rippleDarkCanvas,
            navInactiveIcon: AppColors.rippleDarkMuted,
          ),
      };
    }

    return switch (role) {
      RippleRole.admin => const RippleSkin(
          role: RippleRole.admin,
          skinName: 'Lagoon',
          primary: AppColors.lagoonPrimary,
          action: AppColors.lagoonAction,
          actionInk: AppColors.rippleLightInk,
          canvas: AppColors.rippleLightCanvas,
          surface: AppColors.rippleLightSurface,
          surface2: AppColors.rippleLightSurface2,
          hairline: AppColors.rippleLightHairline,
          ink: AppColors.rippleLightInk,
          muted: AppColors.rippleLightMuted,
          navBackground: AppColors.lagoonPrimary,
          navActiveCircle: Colors.white,
          navActiveIcon: AppColors.lagoonPrimary,
          navInactiveIcon: Color(0xFFDCEEE9),
        ),
      RippleRole.driver => const RippleSkin(
          role: RippleRole.driver,
          skinName: 'Aqua Day',
          primary: AppColors.aquaPrimary,
          action: AppColors.aquaAction,
          actionInk: AppColors.rippleLightInk,
          canvas: AppColors.aquaCanvasLight,
          surface: AppColors.rippleLightSurface,
          surface2: Color(0xFFE3F0F5),
          hairline: Color(0xFFD5E6EE),
          ink: AppColors.rippleLightInk,
          muted: Color(0xFF536B76),
          navBackground: AppColors.aquaPrimary,
          navActiveCircle: Colors.white,
          navActiveIcon: AppColors.aquaPrimary,
          navInactiveIcon: Color(0xFFDFF4FB),
        ),
      RippleRole.cafe => const RippleSkin(
          role: RippleRole.cafe,
          skinName: 'Chai & Crema',
          primary: AppColors.chaiPrimary,
          action: AppColors.chaiAction,
          actionInk: AppColors.chaiInkLight,
          canvas: AppColors.chaiCanvasLight,
          surface: AppColors.rippleLightSurface,
          surface2: Color(0xFFF3E6D6),
          hairline: Color(0xFFEBD9C5),
          ink: AppColors.chaiInkLight,
          muted: Color(0xFF7B5D50),
          navBackground: AppColors.chaiPrimary,
          navActiveCircle: Colors.white,
          navActiveIcon: AppColors.chaiPrimary,
          navInactiveIcon: Color(0xFFFCE7DE),
        ),
      RippleRole.fieldAgent => const RippleSkin(
          role: RippleRole.fieldAgent,
          skinName: 'Field Sage',
          primary: AppColors.sagePrimary,
          action: AppColors.sageAction,
          actionInk: AppColors.rippleLightInk,
          canvas: AppColors.rippleLightCanvas,
          surface: AppColors.rippleLightSurface,
          surface2: AppColors.rippleLightSurface2,
          hairline: AppColors.rippleLightHairline,
          ink: AppColors.rippleLightInk,
          muted: AppColors.rippleLightMuted,
          navBackground: AppColors.sagePrimary,
          navActiveCircle: Colors.white,
          navActiveIcon: AppColors.sagePrimary,
          navInactiveIcon: Color(0xFFDFF2E6),
        ),
    };
  }

  @override
  RippleSkin copyWith({
    RippleRole? role,
    String? skinName,
    Color? primary,
    Color? action,
    Color? actionInk,
    Color? canvas,
    Color? surface,
    Color? surface2,
    Color? hairline,
    Color? ink,
    Color? muted,
    Color? navBackground,
    Color? navActiveCircle,
    Color? navActiveIcon,
    Color? navInactiveIcon,
  }) {
    return RippleSkin(
      role: role ?? this.role,
      skinName: skinName ?? this.skinName,
      primary: primary ?? this.primary,
      action: action ?? this.action,
      actionInk: actionInk ?? this.actionInk,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      hairline: hairline ?? this.hairline,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      navBackground: navBackground ?? this.navBackground,
      navActiveCircle: navActiveCircle ?? this.navActiveCircle,
      navActiveIcon: navActiveIcon ?? this.navActiveIcon,
      navInactiveIcon: navInactiveIcon ?? this.navInactiveIcon,
      heroRadius: heroRadius,
      cardRadius: cardRadius,
      inputRadius: inputRadius,
      pillRadius: pillRadius,
    );
  }

  @override
  RippleSkin lerp(covariant ThemeExtension<RippleSkin>? other, double t) {
    if (other is! RippleSkin) return this;
    return RippleSkin(
      role: t < 0.5 ? role : other.role,
      skinName: t < 0.5 ? skinName : other.skinName,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      action: Color.lerp(action, other.action, t) ?? action,
      actionInk: Color.lerp(actionInk, other.actionInk, t) ?? actionInk,
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surface2: Color.lerp(surface2, other.surface2, t) ?? surface2,
      hairline: Color.lerp(hairline, other.hairline, t) ?? hairline,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      navBackground: Color.lerp(navBackground, other.navBackground, t) ?? navBackground,
      navActiveCircle: Color.lerp(navActiveCircle, other.navActiveCircle, t) ?? navActiveCircle,
      navActiveIcon: Color.lerp(navActiveIcon, other.navActiveIcon, t) ?? navActiveIcon,
      navInactiveIcon: Color.lerp(navInactiveIcon, other.navInactiveIcon, t) ?? navInactiveIcon,
      heroRadius: heroRadius,
      cardRadius: cardRadius,
      inputRadius: inputRadius,
      pillRadius: pillRadius,
    );
  }
}

/// Centralized Material 3 Themes built on Stitch "Ripple" tokens.
abstract final class AppTheme {
  static ThemeData get lightTheme => themeForRole(RippleRole.admin, Brightness.light);
  static ThemeData get darkTheme => themeForRole(RippleRole.admin, Brightness.dark);

  static ThemeData themeForRole(RippleRole role, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final skin = RippleSkin.forRole(role, brightness);
    final baseTheme = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final textTheme = AppTypography.manropeTextTheme(baseTheme.textTheme).apply(
      bodyColor: skin.ink,
      displayColor: skin.ink,
    );

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: skin.primary,
            onPrimary: AppColors.rippleDarkCanvas,
            secondary: skin.action,
            onSecondary: skin.actionInk,
            error: AppColors.dangerDark,
            onError: AppColors.rippleDarkCanvas,
            surface: skin.surface,
            onSurface: skin.ink,
          )
        : ColorScheme.light(
            primary: skin.primary,
            onPrimary: Colors.white,
            secondary: skin.action,
            onSecondary: skin.actionInk,
            error: AppColors.danger,
            onError: Colors.white,
            surface: skin.surface,
            onSurface: skin.ink,
          );

    return baseTheme.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: skin.canvas,
      primaryColor: skin.primary,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [skin],
      cardTheme: CardThemeData(
        color: skin.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(skin.cardRadius),
          side: BorderSide(color: skin.hairline, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: skin.surface,
        foregroundColor: skin.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: skin.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: skin.ink, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: skin.primary,
          foregroundColor: isDark ? AppColors.rippleDarkCanvas : Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.inputRadius),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: skin.ink,
          elevation: 0,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: skin.hairline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.inputRadius),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: skin.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.hairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(color: skin.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(skin.inputRadius),
          borderSide: BorderSide(
            color: isDark ? AppColors.dangerDark : AppColors.danger,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(color: skin.muted, fontSize: 14),
        labelStyle: TextStyle(
          color: skin.muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: skin.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
