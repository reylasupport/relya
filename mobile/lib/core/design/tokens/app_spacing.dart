/// 4pt spacing scale. Nothing in the UI uses a raw number.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page inset. Generous on purpose: whitespace is the product.
  static const double pageInset = 20;
}
