import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The dialog that now stands between accepting a suggestion and saving it.
///
/// It exists because iOS spends the system notification prompt once and never
/// again, so it must not be triggered from behind a spinner with nothing on
/// screen to explain it. That makes it a gate on the product's main action,
/// which is exactly why it needs a test: the one outcome that would be worse
/// than never asking is asking and losing the user's work.
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

Future<void> openTheWaitingCapture(WidgetTester tester) async {
  await tester.tap(find.text('Inbox'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Screenshot'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('accepting reminders explains itself before the system asks', (
    tester,
  ) async {
    await pumpSignedIn(tester);
    await openTheWaitingCapture(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add all'));
    await tester.pumpAndSettle();

    expect(find.text('Allow notifications'), findsOneWidget);
    expect(
      find.text('Without them I cannot remind you of anything.'),
      findsOneWidget,
    );
    // Declining has to be as reachable as accepting, or this is a nag rather
    // than a question.
    expect(find.widgetWithText(TextButton, 'Not now'), findsOneWidget);
  });

  testWidgets('continuing past the explanation still saves the items', (
    tester,
  ) async {
    await pumpSignedIn(tester);
    await openTheWaitingCapture(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add all'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Allow notifications'), findsNothing);
    expect(find.text('Added. I will remind you.'), findsOneWidget);
  });

  testWidgets('saying not now still saves what the user accepted', (
    tester,
  ) async {
    await pumpSignedIn(tester);
    await openTheWaitingCapture(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add all'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Not now'));
    await tester.pumpAndSettle();

    // Refusing to be asked by the operating system is not refusing the item.
    // The reminders are stored either way and start working the moment
    // notifications are granted later.
    expect(find.text('Allow notifications'), findsNothing);
    expect(find.text('Added. I will remind you.'), findsOneWidget);
  });
}
