import 'package:flutter/material.dart';

/// Centralized Stitch "Ripple" & Enterprise Design Colors for DK Enterprises Mobile.
/// Preserves legacy semantic aliases while introducing the 4 role-specific Ripple skins.
abstract final class AppColors {
  // Ripple Core Light Tokens
  static const Color rippleLightCanvas = Color(0xFFF5F3EE);
  static const Color rippleLightSurface = Color(0xFFFFFFFF);
  static const Color rippleLightSurface2 = Color(0xFFECEFEA);
  static const Color rippleLightHairline = Color(0xFFE3E1DA);
  static const Color rippleLightInk = Color(0xFF13201B);
  static const Color rippleLightMuted = Color(0xFF66736C);

  // Ripple Core Dark Tokens
  static const Color rippleDarkCanvas = Color(0xFF0E1512);
  static const Color rippleDarkSurface = Color(0xFF17221D);
  static const Color rippleDarkSurface2 = Color(0xFF1F2E27);
  static const Color rippleDarkHairline = Color(0xFF25372E);
  static const Color rippleDarkInk = Color(0xFFEDF3EF);
  static const Color rippleDarkMuted = Color(0xFF93A39B);

  // Ripple Semantic Accents
  static const Color rippleMint = Color(0xFF1FA971);
  static const Color rippleCoral = Color(0xFFE8505B);
  static const Color rippleHoney = Color(0xFFE9A23B);
  static const Color rippleSky = Color(0xFF2E90FA);
  static const Color rippleRuby = Color(0xFFD92D20);

  // Role Skins — Light Primary & Action Accents
  // 1. Admin ("Lagoon")
  static const Color lagoonPrimary = Color(0xFF0B5D52);
  static const Color lagoonAction = Color(0xFFC9F36A);
  static const Color lagoonDarkPrimary = Color(0xFF3FD5B3);

  // 2. Can & Tanker Driver ("Aqua Day")
  static const Color aquaPrimary = Color(0xFF0E8FB3);
  static const Color aquaAction = Color(0xFFFFC933);
  static const Color aquaCanvasLight = Color(0xFFF3F8FA);
  static const Color aquaDarkPrimary = Color(0xFF38BDF8);

  // 3. Cafe / Cashier ("Chai & Crema")
  static const Color chaiPrimary = Color(0xFFC2542D);
  static const Color chaiAction = Color(0xFFF4A62A);
  static const Color chaiCanvasLight = Color(0xFFFBF4EA);
  static const Color chaiInkLight = Color(0xFF2B1B14);
  static const Color chaiDarkPrimary = Color(0xFFF58D64);

  // 4. Field Agent ("Field Sage")
  static const Color sagePrimary = Color(0xFF3F7D58);
  static const Color sageAction = Color(0xFFC9F36A);
  static const Color sageDarkPrimary = Color(0xFF69C68D);

  // Legacy Brand & Action Aliases (mapped cleanly for backwards compatibility)
  static const Color primary = lagoonPrimary;
  static const Color primaryDark = lagoonDarkPrimary;
  static const Color brandNavy = Color(0xFF021840);
  static const Color brandPurple = Color(0xFF7D287E);
  static const Color brandSky = aquaPrimary;
  static const Color brandCyan = Color(0xFF38BDF8);
  static const Color brandEmerald = rippleMint;
  static const Color brandAmber = rippleHoney;
  static const Color brandDanger = rippleCoral;

  // Semantics
  static const Color success = rippleMint;
  static const Color successDark = Color(0xFF34D399);
  static const Color danger = rippleRuby;
  static const Color dangerDark = rippleCoral;
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = rippleHoney;
  static const Color info = rippleSky;

  // Light Surfaces (mapped to Ripple core tokens)
  static const Color lightCanvas = rippleLightCanvas;
  static const Color lightCard = rippleLightSurface;
  static const Color lightBorder = rippleLightHairline;
  static const Color lightTextPrimary = rippleLightInk;
  static const Color lightTextSecondary = rippleLightMuted;
  static const Color lightDivider = rippleLightHairline;

  // Dark Surfaces (mapped to Ripple dark tokens)
  static const Color darkCanvas = rippleDarkCanvas;
  static const Color darkCard = rippleDarkSurface;
  static const Color darkSurface = rippleDarkSurface;
  static const Color darkBorder = rippleDarkHairline;
  static const Color darkTextPrimary = rippleDarkInk;
  static const Color darkTextSecondary = rippleDarkMuted;
  static const Color darkDivider = rippleDarkHairline;

  // Chip backgrounds
  static const Color chipSuccessBgLight = Color(0xFFE8F7F0);
  static const Color chipDangerBgLight = Color(0xFFFEECEC);
  static const Color chipWarningBgLight = Color(0xFFFEF6E7);
  static const Color chipInfoBgLight = Color(0xFFEAF3FE);

  static const Color chipSuccessBgDark = Color(0xFF0E3325);
  static const Color chipDangerBgDark = Color(0xFF3B1518);
  static const Color chipWarningBgDark = Color(0xFF382810);
  static const Color chipInfoBgDark = Color(0xFF102840);
}
