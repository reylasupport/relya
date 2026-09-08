import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../concept/concept.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_semantic_colors.dart';
import '../tokens/app_skin.dart';
import '../tokens/app_skin_style.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// The whole visual language, built from whichever skin the user picked.
///
/// Two rules survive every skin: elevation is essentially zero (separation
/// comes from surface colour and whitespace, not shadow), and the accent
/// appears only on things the user can act on.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light(AppSkin skin) => _build(Brightness.light, skin);

  static ThemeData dark(AppSkin skin) => _build(Brightness.dark, skin);

  static ThemeData _build(Brightness brightness, AppSkin skin) {
    final isLight = brightness == Brightness.light;
    final p = skin.palette(brightness);
    final style = AppSkinStyle.of(skin, brightness);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          onPrimary: isLight ? Colors.white : const Color(0xFF10121A),
          secondary: p.accentSecondary,
          surface: p.surface,
          surfaceContainerLowest: p.surfaceContainerLowest,
          surfaceContainerLow: p.surfaceContainerLowest,
          surfaceContainer: p.surfaceContainer,
          surfaceContainerHigh: p.surfaceContainerHighest,
          surfaceContainerHighest: p.surfaceContainerHighest,
          onSurface: p.onSurface,
          onSurfaceVariant: p.onSurfaceVariant,
          outlineVariant: p.border,
        );

    final semantic =
        (isLight ? AppSemanticColors.light : AppSemanticColors.dark).copyWith(
          subtleBorder: p.border,
          elevatedSurface: p.surfaceContainer,
        );

    final text = AppTypography.textTheme(p.onSurface, p.onSurfaceVariant);
    final concept = skin.concept;
    // Screen titles carry the concept's heading voice. Doing it here rather
    // than per screen means every AppBar in the app - settings, search,
    // paywall - is set in the serif when the cosy design is active.
    final barTitle = conceptHeading(concept, text.headlineSmall!);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: p.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[semantic, style],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: barTitle,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: p.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: style.card,
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: style.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: text.labelLarge,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: style.control),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          minimumSize: const Size(48, 44),
        ),
      ),
      // The toggle is one of the loudest controls in the app, so it takes
      // the concept's opinion too: a solid accent block in the designs that
      // fill their primary control, a tint in the ones that do not.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: text.labelLarge,
          selectedBackgroundColor: switch (concept) {
            Concept.e || Concept.f => p.accent,
            _ => p.accent.withValues(alpha: isLight ? 0.14 : 0.24),
          },
          selectedForegroundColor: switch (concept) {
            Concept.e ||
            Concept.f => isLight ? Colors.white : const Color(0xFF17140F),
            _ => p.accent,
          },
          side: BorderSide(color: p.border),
          shape: switch (concept) {
            Concept.e || Concept.f => const StadiumBorder(),
            _ => RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          },
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: text.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: style.control,
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: style.control,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: style.control,
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: p.accent.withValues(alpha: isLight ? 0.14 : 0.20),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: style.control),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceContainerHighest,
        side: BorderSide.none,
        labelStyle: text.labelSmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.md,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
