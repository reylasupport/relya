import 'package:flutter/material.dart';

/// Nine steps, no more. Uses the platform system face (SF on iOS, Roboto on
/// Android) rather than a bundled font: it renders natively, respects the
/// user's accessibility text size, and costs nothing in bundle weight.
///
/// Sizes are logical pixels at a 1.0 text scale. Dynamic Type scales them; no
/// widget may hardcode a font size.
abstract final class AppTypography {
  const AppTypography._();

  static const String? _family = null;

  static TextTheme textTheme(Color primary, Color muted) => TextTheme(
    // Reserved for the one number or word a screen is really about.
    displaySmall: TextStyle(
      fontFamily: _family,
      fontSize: 34,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: primary,
    ),
    // Screen titles: "Good morning, Joao".
    headlineMedium: TextStyle(
      fontFamily: _family,
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: primary,
    ),
    headlineSmall: TextStyle(
      fontFamily: _family,
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: primary,
    ),
    // Card and row titles.
    titleMedium: TextStyle(
      fontFamily: _family,
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: primary,
    ),
    titleSmall: TextStyle(
      fontFamily: _family,
      fontSize: 15,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _family,
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyMedium: TextStyle(
      fontFamily: _family,
      fontSize: 14.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: muted,
    ),
    labelLarge: TextStyle(
      fontFamily: _family,
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: primary,
    ),
    // Section headers and metadata. Quiet by design.
    labelSmall: TextStyle(
      fontFamily: _family,
      fontSize: 12.5,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: muted,
    ),
  );

  /// Upper bound on Dynamic Type. Beyond this, dense screens stop fitting
  /// even with wrapping, so we clamp rather than break the layout.
  static const double maxTextScale = 1.6;
}
