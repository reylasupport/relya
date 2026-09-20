import 'package:flutter/material.dart';

/// The accent, when the skin lets the user pick one.
///
/// Four values per colour, not one, because an accent does four different
/// jobs and a single hex can only do one of them well. A colour dark enough
/// to carry white type on a button is too dark to read as a colour; a colour
/// bright enough to read as type on a dark ground washes out on a light one.
/// So each choice ships a fill and a text tone per mode, plus the wash behind
/// an icon.
///
/// Every value was solved rather than chosen: the fills carry white type at
/// 4.5:1 or better, and the text tones clear 4.5:1 on every surface their
/// mode can put behind them. The accessibility suite runs over each skin, so
/// a hand-picked hex that looked nice would have failed there instead.
enum AccentChoice {
  /// The one the design was drawn in.
  azul(
    'azul',
    fillLight: Color(0xFF2B5FE3),
    textLight: Color(0xFF2B5FE3),
    washLight: Color(0xFFE1E9FB),
    fillDark: Color(0xFF3C6CE5),
    textDark: Color(0xFF6D91EC),
    washDark: Color(0xFF1D2E55),
  ),

  verde(
    'verde',
    fillLight: Color(0xFF2F6B5E),
    textLight: Color(0xFF2F6B5E),
    washLight: Color(0xFFE2EAE8),
    fillDark: Color(0xFF40776B),
    textDark: Color(0xFF749C93),
    washDark: Color(0xFF1E303D),
  ),

  terracota(
    'terracota',
    fillLight: Color(0xFFB4541E),
    textLight: Color(0xFFAB501D),
    washLight: Color(0xFFF5E7E0),
    fillDark: Color(0xFFB45F2F),
    textDark: Color(0xFFCC8863),
    washDark: Color(0xFF362C32),
  ),

  ameixa(
    'ameixa',
    fillLight: Color(0xFF6B4BCC),
    textLight: Color(0xFF6B4BCC),
    washLight: Color(0xFFEAE6F8),
    fillDark: Color(0xFF7759D0),
    textDark: Color(0xFF9C86DD),
    washDark: Color(0xFF292A51),
  ),

  ardosia(
    'ardosia',
    fillLight: Color(0xFF3D5A73),
    textLight: Color(0xFF3D5A73),
    washLight: Color(0xFFE4E8EB),
    fillDark: Color(0xFF4D677E),
    textDark: Color(0xFF8395A5),
    washDark: Color(0xFF202D41),
  ),

  carmim(
    'carmim',
    fillLight: Color(0xFFB03A5B),
    textLight: Color(0xFFB03A5B),
    washLight: Color(0xFFF4E3E8),
    fillDark: Color(0xFFB64A68),
    textDark: Color(0xFFCB7D93),
    washDark: Color(0xFF35273D),
  );

  const AccentChoice(
    this.wire, {
    required this.fillLight,
    required this.textLight,
    required this.washLight,
    required this.fillDark,
    required this.textDark,
    required this.washDark,
  });

  /// What is persisted. Stays stable if the display name ever changes.
  final String wire;

  /// A block of this colour, with white type on it.
  final Color fillLight;

  /// This colour as type, on a light ground.
  final Color textLight;

  /// The tint behind an icon, on a light ground.
  final Color washLight;

  final Color fillDark;
  final Color textDark;
  final Color washDark;

  static AccentChoice get fallback => AccentChoice.azul;

  static AccentChoice fromWire(String? value) =>
      values.firstWhere((a) => a.wire == value, orElse: () => fallback);

  Color fill(Brightness brightness) =>
      brightness == Brightness.light ? fillLight : fillDark;

  Color text(Brightness brightness) =>
      brightness == Brightness.light ? textLight : textDark;

  Color wash(Brightness brightness) =>
      brightness == Brightness.light ? washLight : washDark;

  /// What sits on top of [fill]. White in both modes: every fill above was
  /// solved against white and nothing else.
  Color get onFill => const Color(0xFFFFFFFF);
}
