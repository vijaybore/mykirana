import 'package:flutter/material.dart';

/// Warm, trustworthy palette — deep green primary (grocery/trust/growth),
/// saffron accent for CTAs (energy, familiar to Indian retail contexts).
/// Kept intentionally high-contrast and simple for low-literacy,
/// budget-Android readability in bright daylight (shops are often outdoors).
class AppColors {
  AppColors._();

  // Primary — deep green
  static const Color primary = Color(0xFF1B6B4A);
  static const Color primaryDark = Color(0xFF124A33);
  static const Color primaryLight = Color(0xFFE3F2EA);

  // Accent — saffron (CTAs, highlights, "action needed" cues)
  static const Color accent = Color(0xFFF5941F);
  static const Color accentDark = Color(0xFFD87D0C);
  static const Color accentLight = Color(0xFFFEF0DD);

  // Semantic
  static const Color success = Color(0xFF2E9E5B);
  static const Color danger = Color(0xFFDC3D3D);
  static const Color dangerLight = Color(0xFFFCE8E8);
  static const Color warning = Color(0xFFE0A800);

  // Udhari-specific (red = owing, green = clear — must stay unambiguous)
  static const Color udhariOwing = Color(0xFFDC3D3D);
  static const Color udhariOwingBg = Color(0xFFFCE8E8);
  static const Color udhariClear = Color(0xFF2E9E5B);
  static const Color udhariClearBg = Color(0xFFE3F2EA);

  // Neutrals
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E5E1);
  static const Color divider = Color(0xFFEDEEEA);

  // Text
  static const Color textPrimary = Color(0xFF1A1D1B);
  static const Color textSecondary = Color(0xFF6B7268);
  static const Color textMuted = Color(0xFF9AA096);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Out-of-stock / disabled
  static const Color disabledBg = Color(0xFFF0F1EE);
  static const Color disabledText = Color(0xFFB4B8B0);

  // Order status stepper
  static const Color stepDone = primary;
  static const Color stepPending = Color(0xFFD8DBD5);

  // Skeleton loader shimmer
  static const Color skeletonBase = Color(0xFFEBECE8);
  static const Color skeletonHighlight = Color(0xFFF7F8F6);
}