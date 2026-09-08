import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The confirmation screen is the product. It is also a list of cards, which
/// is exactly the layout that used to blow up, so it gets its own test.
Future<void> pumpSignedIn(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
  final prefs = await LocalPrefs.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(
          MockAuthService(startSignedIn: true),
        ),
      ],
      child: const RelyaApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the confirmation screen shows what was understood', (
    tester,
  ) async {
    await pumpSignedIn(tester);

    // Inbox tab, then the capture that is waiting for a look.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Screenshot'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Found 3 important things'), findsOneWidget);
    expect(find.text('Dentist appointment'), findsOneWidget);
    expect(find.text('Payment due'), findsOneWidget);
    // The third one is below the fold, which is itself worth asserting: the
    // list has to scroll rather than clip.
    await tester.scrollUntilVisible(
      find.text('Return deadline'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Return deadline'), findsOneWidget);

    // 0.72 confidence is the middle band: ask the user to check, do not cry
    // wolf with the red badge.
    expect(find.text('Please check'), findsOneWidget);
    expect(
      find.text('I could not confirm which purchase this refers to.'),
      findsOneWidget,
    );

    // And the primary action is reachable and enabled.
    final button = find.widgetWithText(FilledButton, 'Add all');
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
}
