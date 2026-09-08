import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/app_semantic_colors.dart';
import 'package:relya/core/design/tokens/app_skin.dart';
import 'package:relya/core/design/tokens/app_skin_style.dart';
import 'package:relya/shared/domain/user_preferences.dart';

void main() {
  group('skins', () {
    test('every skin is usable in both brightnesses', () {
      for (final skin in AppSkin.values) {
        for (final theme in [AppTheme.light(skin), AppTheme.dark(skin)]) {
          // The surfaces are ours, not whatever fromSeed would have picked.
          expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
          expect(theme.extension<AppSemanticColors>(), isNotNull);
          expect(theme.extension<AppSkinStyle>(), isNotNull);
        }
      }
    });

    test('a skin is a whole palette, not just an accent', () {
      final cosy = AppTheme.dark(AppSkin.cosy).colorScheme;
      final midnight = AppTheme.dark(AppSkin.midnight).colorScheme;

      expect(cosy.primary, isNot(midnight.primary));
      // Surfaces differ too: warm near-black against deep navy.
      expect(cosy.surface, isNot(midnight.surface));
      expect(cosy.onSurfaceVariant, isNot(midnight.onSurfaceVariant));
    });

    test('the meaning colours never change with the skin', () {
      final a = AppTheme.dark(AppSkin.cosy).extension<AppSemanticColors>()!;
      final b = AppTheme.dark(AppSkin.midnight).extension<AppSemanticColors>()!;

      // If overdue were sage in one theme and red in another, the colour
      // would stop meaning anything.
      expect(a.danger, b.danger);
      expect(a.success, b.success);
      expect(a.warning, b.warning);
    });

    test('shape belongs to the skin', () {
      double radius(AppSkin skin) =>
          AppTheme.dark(skin).extension<AppSkinStyle>()!.cardRadius;

      expect(radius(AppSkin.pastel), greaterThan(radius(AppSkin.midnight)));
      expect(AppSkin.pastel.tintedRows, isTrue);
      expect(AppSkin.midnight.tintedRows, isFalse);
    });
  });

  group('preferences', () {
    test('an unknown stored skin falls back instead of throwing', () {
      expect(
        AppSkin.fromWire('a-theme-from-a-later-version'),
        AppSkin.fallback,
      );
    });

    test('the chosen skin round-trips', () {
      const prefs = UserPreferences(themeSkin: AppSkin.cosy);
      final restored = UserPreferences.fromJson(prefs.toJson());
      expect(restored.themeSkin, AppSkin.cosy);
      expect(restored.resolvedSkin, AppSkin.cosy);
    });

    test('no stored skin means the default', () {
      const prefs = UserPreferences();
      expect(prefs.themeSkin, isNull);
      expect(prefs.resolvedSkin, AppSkin.fallback);
      expect(prefs.toJson()['theme_skin'], isNull);
    });

    test('theme mode survives a round-trip too', () {
      const prefs = UserPreferences(themeMode: ThemeMode.dark);
      expect(
        UserPreferences.fromJson(prefs.toJson()).themeMode,
        ThemeMode.dark,
      );
    });
  });
}
