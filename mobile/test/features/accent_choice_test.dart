import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/accent_choice.dart';
import 'package:relya/core/design/tokens/app_skin.dart';
import 'package:relya/shared/domain/user_preferences.dart';

/// The relative luminance of a colour, per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final x = _luminance(a);
  final y = _luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// The accents claim, in their own doc comment, that every value was solved
/// rather than chosen. This is what holds that claim to account: the numbers
/// are checked here rather than trusted, so a seventh colour added by eye
/// fails before anyone ships it.
void main() {
  group('every accent is legible', () {
    for (final accent in AccentChoice.values) {
      test('${accent.wire} carries white type on its fill', () {
        for (final brightness in Brightness.values) {
          expect(
            _contrast(accent.fill(brightness), accent.onFill),
            greaterThanOrEqualTo(4.5),
            reason: '${accent.wire} on $brightness',
          );
        }
      });

      test('${accent.wire} reads as type on the surfaces behind it', () {
        for (final brightness in Brightness.values) {
          final palette = AppSkin.suave
              .palette(brightness)
              .withAccent(accent, brightness);
          // Every surface the app can put behind a line of accent text: the
          // page, a card, and the highest container a chip sits on.
          final grounds = [
            palette.surface,
            palette.surfaceContainerLowest,
            palette.surfaceContainer,
            palette.surfaceContainerHighest,
          ];
          for (final ground in grounds) {
            expect(
              _contrast(accent.text(brightness), ground),
              greaterThanOrEqualTo(4.5),
              reason: '${accent.wire} text on $ground ($brightness)',
            );
          }
        }
      });

      test('${accent.wire} keeps its wash behind the text, not on top', () {
        for (final brightness in Brightness.values) {
          // The wash is a tint behind an icon. If it were as dark as the fill
          // the icon on it would vanish, so it has to stay on the same side of
          // the page as the surface it sits on.
          final palette = AppSkin.suave.palette(brightness);
          final washIsLighter =
              _luminance(accent.wash(brightness)) >
              _luminance(accent.fill(brightness));
          expect(
            washIsLighter,
            brightness == Brightness.light,
            reason: '${accent.wire} on $brightness',
          );
          expect(
            _contrast(accent.text(brightness), palette.surface),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    }
  });

  group('the accent applies where it was offered', () {
    test('only one design lets the user choose', () {
      final choosers = AppSkin.values.where((s) => s.accentIsChosen).toList();
      expect(choosers, [AppSkin.suave]);
    });

    test('choosing one changes that design', () {
      final azul = AppTheme.light(
        AppSkin.suave,
        accent: AccentChoice.azul,
      ).colorScheme;
      final carmim = AppTheme.light(
        AppSkin.suave,
        accent: AccentChoice.carmim,
      ).colorScheme;

      expect(azul.primary, isNot(carmim.primary));
      // Only the accent moves. The surfaces are what make the design
      // recognisable, and a colour picker must not quietly restyle them.
      expect(azul.surface, carmim.surface);
      expect(azul.onSurface, carmim.onSurface);
      expect(azul.surfaceContainer, carmim.surfaceContainer);
    });

    test('the other designs ignore it', () {
      for (final skin in AppSkin.values.where((s) => !s.accentIsChosen)) {
        final plain = AppTheme.dark(skin).colorScheme.primary;
        final asked = AppTheme.dark(
          skin,
          accent: AccentChoice.carmim,
        ).colorScheme.primary;
        // Each of these was drawn around its own hue; swapping it leaves the
        // design wearing somebody else's colour.
        expect(asked, plain, reason: skin.wire);
      }
    });
  });

  group('the choice is remembered', () {
    test('it round-trips', () {
      const prefs = UserPreferences(themeAccent: AccentChoice.terracota);
      final restored = UserPreferences.fromJson(prefs.toJson());
      expect(restored.themeAccent, AccentChoice.terracota);
    });

    test('an accent from a later version falls back instead of throwing', () {
      expect(AccentChoice.fromWire('octarine'), AccentChoice.fallback);
      expect(AccentChoice.fromWire(null), AccentChoice.fallback);
    });

    test('it travels on the wire under its own key', () {
      const prefs = UserPreferences(themeAccent: AccentChoice.ameixa);
      // The column the migration adds. If this key ever drifts, the upsert
      // fails and takes every other preference down with it.
      expect(prefs.toJson()['theme_accent'], 'ameixa');
    });
  });
}
