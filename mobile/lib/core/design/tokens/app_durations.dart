import 'package:flutter/animation.dart';

/// Motion should be felt, not watched. Nothing decorative, nothing over 300ms.
abstract final class AppDurations {
  const AppDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasised = Curves.easeOutQuart;
}
