/// Consistent spacing scale (4px base unit) and corner radii.
/// 12-16px rounded corners on cards per design spec.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Screen edge padding
  static const double screenPadding = 16;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
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
