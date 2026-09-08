import 'package:flutter/material.dart';

import 'app_skin.dart';

/// The parts of a skin that are not colours: shape, tinting, and the brand
/// gradient for that theme.
///
/// Carried on the ThemeData so any widget can ask the theme what shape it
/// should be, instead of importing a const and ignoring the user's choice.
@immutable
class AppSkinStyle extends ThemeExtension<AppSkinStyle> {
  const AppSkinStyle({
    required this.skin,
    required this.cardRadius,
    required this.tintedRows,
    required this.tintStrength,
    required this.gradient,
  });

  factory AppSkinStyle.of(AppSkin skin, Brightness brightness) => AppSkinStyle(
    skin: skin,
    cardRadius: skin.cardRadius,
    tintedRows: skin.tintedRows,
    tintStrength: skin.tintStrength,
    gradient: skin.palette(brightness).gradient,
  );

  final AppSkin skin;
  final double cardRadius;
  final bool tintedRows;
  final double tintStrength;
  final Gradient gradient;

  BorderRadius get card => BorderRadius.circular(cardRadius);

  BorderRadius get control => BorderRadius.circular(cardRadius - 4);

  @override
  AppSkinStyle copyWith({
    AppSkin? skin,
    double? cardRadius,
    bool? tintedRows,
    double? tintStrength,
    Gradient? gradient,
  }) {
    return AppSkinStyle(
      skin: skin ?? this.skin,
      cardRadius: cardRadius ?? this.cardRadius,
      tintedRows: tintedRows ?? this.tintedRows,
      tintStrength: tintStrength ?? this.tintStrength,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  AppSkinStyle lerp(ThemeExtension<AppSkinStyle>? other, double t) {
    if (other is! AppSkinStyle) return this;
    return AppSkinStyle(
      // Shape and tinting swap at the halfway point rather than interpolating:
      // a card cannot be half-rounded and half-tinted in any meaningful way.
      skin: t < 0.5 ? skin : other.skin,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      tintedRows: t < 0.5 ? tintedRows : other.tintedRows,
      tintStrength: tintStrength + (other.tintStrength - tintStrength) * t,
      gradient: t < 0.5 ? gradient : other.gradient,
    );
  }
}

extension AppSkinStyleX on BuildContext {
  AppSkinStyle get skin =>
      Theme.of(this).extension<AppSkinStyle>() ??
      AppSkinStyle.of(AppSkin.fallback, Theme.of(this).brightness);

  /// The active design, for the layout decisions that travel with it.
  AppSkin get appSkin => skin.skin;
}
