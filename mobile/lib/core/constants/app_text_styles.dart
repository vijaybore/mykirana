import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/screen_util.dart';

/// Type scale tuned for readability on small budget-Android screens.
/// Bold prices, medium product names, muted secondary text — per spec.
/// All font sizes are scaled via [ScreenUtil.sp] so they adapt to the
/// device screen width while respecting system accessibility settings.
class AppTextStyles {
  AppTextStyles._();

  // Display / headline — screen titles
  static TextStyle get h1 => TextStyle(
        fontSize: ScreenUtil.sp(26),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: ScreenUtil.sp(21),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get h3 => TextStyle(
        fontSize: ScreenUtil.sp(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Body
  static TextStyle get bodyLarge => TextStyle(
        fontSize: ScreenUtil.sp(16),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: ScreenUtil.sp(14),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: ScreenUtil.sp(12),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Product name — medium weight per spec
  static TextStyle get productName => TextStyle(
        fontSize: ScreenUtil.sp(14),
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Price — bold, prominent per spec
  static TextStyle get priceLarge => TextStyle(
        fontSize: ScreenUtil.sp(20),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get priceMedium => TextStyle(
        fontSize: ScreenUtil.sp(16),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // Secondary / muted
  static TextStyle get caption => TextStyle(
        fontSize: ScreenUtil.sp(12),
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.3,
      );

  // Buttons
  static TextStyle get button => TextStyle(
        fontSize: ScreenUtil.sp(16),
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  // Labels (form fields, section headers)
  static TextStyle get label => TextStyle(
        fontSize: ScreenUtil.sp(13),
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  // Balance card (udhari) — large, glanceable
  static TextStyle get balanceAmount => TextStyle(
        fontSize: ScreenUtil.sp(32),
        fontWeight: FontWeight.w800,
        height: 1.1,
      );
}
