import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/app_skin.dart';
import 'package:relya/l10n/gen/app_localizations.dart';
import 'package:relya/navigation/shell_chrome.dart';

/// A skin is a design, not a palette.
///
/// These tests exist because the easy failure mode of a theme system is that
/// every theme ends up being the same screen in a different colour. Each of
/// the four came from a different concept, and the concepts disagree about
/// where the capture button lives and what the top of Home is.
void main() {
  group('a skin carries layout, not only colour', () {
    test('exactly one design sinks the capture button into the bar', () {
      final centre = AppSkin.values
          .where((s) => s.nav == SkinNav.centre)
          .toList();
      expect(centre, [AppSkin.pastel]);
    });

    test('the three hero styles are all in use', () {
      expect(AppSkin.values.map((s) => s.hero).toSet(), {
        SkinHero.focus,
        SkinHero.highlight,
        SkinHero.poster,
      });
    });

    test('all four open on a different first screen', () {
      final welcomes = AppSkin.values.map((s) => s.welcome).toList();
      expect(welcomes.toSet().length, 4);
      // Two of them are pictures that fill the screen; two sit on the wash.
      expect(AppSkin.values.where((s) => s.welcomeIsFullBleed).toList(), [
        AppSkin.cosy,
        AppSkin.midnight,
      ]);
    });

    test('no two skins announce a section the same way', () {
      final styles = AppSkin.values.map((s) => s.sectionStyle).toList();
      expect(styles.toSet().length, styles.length);
    });

    test('the bar without an inbox destination keeps a way in', () {
      for (final skin in AppSkin.values) {
        if (skin.nav == SkinNav.centre) {
          // Otherwise the inbox, and its pending badge, would be unreachable.
          expect(skin.headerBell, isTrue, reason: skin.wire);
        }
      }
    });
  });

  testWidgets('the centre design drops a destination and gains a button', (
    tester,
  ) async {
    Future<void> pump(AppSkin skin) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(skin),
        home: Scaffold(
          bottomNavigationBar: RelyaNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            onCapture: () {},
          ),
        ),
      ),
    );

    await pump(AppSkin.soft);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.byType(CaptureButton), findsNothing);

    // MaterialApp animates between themes, and AppSkinStyle.lerp snaps the
    // skin at the halfway point, so the bar is still the old design until the
    // transition finishes.
    await pump(AppSkin.pastel);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsNothing);
    expect(find.byType(CaptureButton), findsOneWidget);
  });
}
