import '../utils/screen_util.dart';

/// Consistent spacing scale (4px base unit) and corner radii.
/// All values are scaled proportionally to the device screen width
/// via [ScreenUtil.dp] so layouts fit naturally on any phone size.
class AppSpacing {
  AppSpacing._();

  static double get xs => ScreenUtil.dp(4);
  static double get sm => ScreenUtil.dp(8);
  static double get md => ScreenUtil.dp(12);
  static double get lg => ScreenUtil.dp(16);
  static double get xl => ScreenUtil.dp(24);
  static double get xxl => ScreenUtil.dp(32);
  static double get xxxl => ScreenUtil.dp(48);

  // Screen edge padding
  static double get screenPadding => ScreenUtil.dp(16);
}

class AppRadius {
  AppRadius._();

  static double get sm => ScreenUtil.dp(8);
  static double get md => ScreenUtil.dp(12);
  static double get lg => ScreenUtil.dp(16);
  // pill radius stays very large — scaling not needed
  static const double pill = 999;
}

class AppElevation {
  AppElevation._();

  // Soft shadows per spec — kept low so it reads as "gentle depth"
  // rather than heavy Material shadow.
  static const double card = 2;
  static const double modal = 8;
  static const double floatingBar = 6;
}
