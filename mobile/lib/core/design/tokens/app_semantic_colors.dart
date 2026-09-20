import 'package:flutter/material.dart';

/// Meaning-carrying colours, kept out of ColorScheme so the palette stays
/// small and predictable. Danger is reserved for "this expires today" - if red
/// shows up for anything less, it stops meaning anything.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.accentText,
    required this.subtleBorder,
    required this.strongBorder,
    required this.elevatedSurface,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;

  /// The accent when it has to be read rather than filled. See
  /// SkinPalette.accentText.
  final Color accentText;

  /// Quiet separation. Dividers, and edges that only need to be sensed.
  final Color subtleBorder;

  /// The outline of a control that has nothing else to identify it.
  /// Cleared for 3:1 against every surface its skin can put behind it;
  /// see SkinPalette.borderStrong for why one border colour could not do
  /// both jobs.
  final Color strongBorder;

  final Color elevatedSurface;

  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF1B8A5A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE4F5EC),
    warning: Color(0xFFB25E02),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFDF0DF),
    danger: Color(0xFFC0392B),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFBE9E7),
    info: Color(0xFF3D5AFE),
    infoContainer: Color(0xFFEAEDFF),
    accentText: Color(0xFF4949AB),
    subtleBorder: Color(0x14000000),
    strongBorder: Color(0x6D000000),
    elevatedSurface: Color(0xFFFFFFFF),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF5FD3A0),
    onSuccess: Color(0xFF00301C),
    successContainer: Color(0xFF16342A),
    warning: Color(0xFFF3B564),
    onWarning: Color(0xFF3B2200),
    warningContainer: Color(0xFF3A2B15),
    danger: Color(0xFFFF8A80),
    onDanger: Color(0xFF3D0A05),
    dangerContainer: Color(0xFF3C1F1C),
    info: Color(0xFF93A5FF),
    infoContainer: Color(0xFF212645),
    accentText: Color(0xFFADABFF),
    subtleBorder: Color(0x1FFFFFFF),
    strongBorder: Color(0x57FFFFFF),
    elevatedSurface: Color(0xFF1A1C20),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
    Color? accentText,
    Color? subtleBorder,
    Color? strongBorder,
    Color? elevatedSurface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      accentText: accentText ?? this.accentText,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      strongBorder: strongBorder ?? this.strongBorder,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successContainer: mix(successContainer, other.successContainer),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningContainer: mix(warningContainer, other.warningContainer),
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      dangerContainer: mix(dangerContainer, other.dangerContainer),
      info: mix(info, other.info),
      infoContainer: mix(infoContainer, other.infoContainer),
      accentText: mix(accentText, other.accentText),
      subtleBorder: mix(subtleBorder, other.subtleBorder),
      strongBorder: mix(strongBorder, other.strongBorder),
      elevatedSurface: mix(elevatedSurface, other.elevatedSurface),
    );
  }
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
