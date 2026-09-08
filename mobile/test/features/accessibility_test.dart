import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/app_skin.dart';
import 'package:relya/core/design/tokens/app_typography.dart';
import 'package:relya/features/assistant/presentation/assistant_screen.dart';
import 'package:relya/features/home/presentation/home_screen.dart';
import 'package:relya/features/inbox/presentation/inbox_screen.dart';
import 'package:relya/features/life/presentation/life_screen.dart';
import 'package:relya/features/upcoming/presentation/upcoming_screen.dart';
import 'package:relya/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Large text is not an edge case.
///
/// The app clamps Dynamic Type at 1.6x, which means 1.6x is a size real users
/// will see - so every screen has to survive it. A RenderFlex overflow at that
/// scale is a yellow-and-black bar across somebody's appointment.
///
/// Runs on a small phone on purpose: the narrowest screen at the largest text
/// is the worst case, and it is the combination nobody tries by hand.
void main() {
  Future<void> pump(WidgetTester tester, Widget screen, AppSkin skin) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 690) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('pt', 'PT'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(skin),
          darkTheme: AppTheme.dark(skin),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(AppTypography.maxTextScale),
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));
  }

  final screens = <String, Widget Function()>{
    'home': HomeScreen.new,
    'inbox': InboxScreen.new,
    'upcoming': UpcomingScreen.new,
    'life': LifeScreen.new,
    'assistant': AssistantScreen.new,
  };

  for (final skin in AppSkin.values) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} survives 1.6x text on ${skin.wire}', (
        tester,
      ) async {
        await pump(tester, entry.value(), skin);

        final error = tester.takeException();
        expect(
          error,
          isNull,
          reason:
              '${entry.key} on ${skin.wire} overflows at the largest text '
              'size the app allows',
        );
      });
    }
  }
}
