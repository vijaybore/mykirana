import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Lightweight responsive-scaling utility.
///
/// Call [ScreenUtil.init] inside [MaterialApp.builder] (where
/// [MediaQuery] is available) before the child is returned.
/// Everywhere else in the app, use the static helpers:
///
///   [dp]  — scale a design-pixel dimension (width-based)
///   [sp]  — scale a font size             (width-based, capped)
///   [vp]  — scale a vertical dimension    (height-based)
///
/// Design baseline: 390 × 844 logical pixels
/// (iPhone 14 / Pixel 7 — the most common reference size).
class ScreenUtil {
  ScreenUtil._();

  /// Width of the design reference device in logical pixels.
  static const double _designWidth = 390.0;

  /// Height of the design reference device in logical pixels.
  static const double _designHeight = 844.0;

  /// Maximum font-scale multiplier so text doesn't get absurdly large
  /// on wide/tall phones (e.g. fold-out or large tablets).
  static const double _maxFontScale = 1.20;

  static double _scaleW = 1.0;
  static double _scaleH = 1.0;
  static double _scaleFont = 1.0;

  /// Initialise from [MediaQueryData]. Call once in [MaterialApp.builder].
  static void init(MediaQueryData mq) {
    final width = mq.size.width;
    final height = mq.size.height;

    _scaleW = width / _designWidth;
    _scaleH = height / _designHeight;

    // Font scale uses width ratio with a gentle soft-cap so text on a 480px
    // wide phone is noticeably larger but doesn't break layouts.
    _scaleFont = math.min(_scaleW, _maxFontScale);
  }

  /// Scale a horizontal or general dimension proportionally to screen width.
  ///
  /// Example: dp(16) on a 390px phone → 16.0
  ///          dp(16) on a 320px phone → ~13.1
  ///          dp(16) on a 430px phone → ~17.6
  static double dp(double size) => size * _scaleW;

  /// Scale a font size. Uses a slightly capped multiplier so text stays
  /// legible on very wide devices without overflowing narrow ones.
  static double sp(double size) => size * _scaleFont;

  /// Scale a vertical dimension proportionally to screen height.
  ///
  /// Use for things that should grow/shrink with the screen height
  /// (e.g. hero image heights, modal sheet max-heights).
  static double vp(double size) => size * _scaleH;

  /// Current screen width (convenience accessor after [init]).
  static double get screenWidth => _designWidth * _scaleW;

  /// Current screen height (convenience accessor after [init]).
  static double get screenHeight => _designHeight * _scaleH;
}
