import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../concept/concept.dart';
import '../tokens/accent_choice.dart';
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

  static ThemeData light(AppSkin skin, {AccentChoice? accent}) =>
      _build(Brightness.light, skin, accent);

  static ThemeData dark(AppSkin skin, {AccentChoice? accent}) =>
      _build(Brightness.dark, skin, accent);

  static ThemeData _build(
    Brightness brightness,
    AppSkin skin,
    AccentChoice? accent,
  ) {
    final isLight = brightness == Brightness.light;
    // The chosen accent applies to the one skin that offers the choice, and
    // is ignored everywhere else: the other four were drawn around their own
    // hue, and swapping it leaves a design wearing somebody else's colour.
    final chosen = skin.accentIsChosen
        ? (accent ?? AccentChoice.fallback)
        : null;
    final p = chosen == null
        ? skin.palette(brightness)
        : skin.palette(brightness).withAccent(chosen, brightness);
    final style = AppSkinStyle.of(skin, brightness);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: brightness,
        ).copyWith(
          primary: p.accent,
          // Every chosen accent was solved to carry white in both modes, so
          // the dark-mode near-black that the fixed palettes use would be the
          // one thing on the screen below AA.
          onPrimary:
              chosen?.onFill ??
              (isLight ? Colors.white : const Color(0xFF10121A)),
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
          accentText: p.accentText,
          subtleBorder: p.border,
          strongBorder: p.borderStrong,
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
          // The only thing that says a button is here.
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: style.control),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: p.accentText,
          minimumSize: const Size(48, 48),
        ),
      ),
      // The toggle is one of the loudest controls in the app, so it takes
      // the concept's opinion too: a solid accent block in the designs that
      // fill their primary control, a tint in the ones that do not.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: text.labelLarge,
          foregroundColor: p.accentText,
          // A filter you switch with your thumb, not a label you read.
          minimumSize: const Size(48, 48),
          selectedBackgroundColor: switch (concept) {
            // White type on the raw accent measured 3.87:1 to 4.35:1 across the
            // skins. accentText is the same hue already proven against a white
            // surface, and contrast is symmetric, so it carries white type.
            Concept.e || Concept.f => isLight ? p.accentText : p.accent,
            // The chosen accents are solid enough to fill in either mode, and
            // a 14% wash of one is not: the accent as type on its own tint
            // came out at 3.82:1.
            Concept.g => p.accent,
            _ => p.accent.withValues(alpha: isLight ? 0.14 : 0.24),
          },
          selectedForegroundColor: switch (concept) {
            Concept.e ||
            Concept.f => isLight ? Colors.white : const Color(0xFF17140F),
            Concept.g => chosen?.onFill ?? Colors.white,
            _ => p.accentText,
          },
          // Only the selected segment is filled, so this line is the whole of
          // what shows the others - and the extent of the control itself.
          side: BorderSide(color: p.borderStrong),
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
          // Filled is not enough on its own here: fillColor sits barely a
          // tenth of a contrast step off the page behind it.
          borderSide: BorderSide(color: p.borderStrong),
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
      // The pending badge on the Inbox bell took whatever red ColorScheme
      // .fromSeed produced, which is a different colour in each of the four
      // skins and designed in none of them - on cosy it came out at 1.97:1.
      // danger and onDanger are chosen, and carry 5.44:1.
      badgeTheme: BadgeThemeData(
        backgroundColor: semantic.danger,
        textColor: semantic.onDanger,
        // Bigger than the Material default on purpose. At the stock 16dp a
        // single digit is mostly the antialiased rim of the circle rather
        // than the circle, which is both hard to read at arm length and the
        // reason the contrast guideline was sampling a washed-out pink
        // instead of either of the two colours actually chosen here.
        largeSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        textStyle: text.labelSmall?.copyWith(
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
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
