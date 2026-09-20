import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The assistant is only allowed to say what it can point at.
///
/// The ids came down with every answer from the first day and the screen threw
/// them away, which meant the one rule the assistant is built around - never
/// invent, always cite - was invisible to the person reading the answer. These
/// tests are about that: an answer shows its sources, and each one opens.
Future<void> _openAssistant(WidgetTester tester) async {
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

  await tester.tap(find.text('Assistant'));
  await tester.pumpAndSettle();
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  // The mock answers after a deliberate pause, so the thinking bubble is real.
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  // And the sources are looked up only once the answer is on screen. Nothing
  // animates while that happens, so pumpAndSettle alone never reaches it.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an answer shows what it was built from', (tester) async {
    await _openAssistant(tester);
    await _ask(tester, 'Anything important this week?');

    expect(find.text('BASED ON'), findsOneWidget);
    // The fixture week has the dentist appointment in it, and the strip names
    // it rather than just counting it.
    expect(find.text('Dentist appointment'), findsWidgets);
  });

  testWidgets('a source opens the item it points at', (tester) async {
    await _openAssistant(tester);
    await _ask(tester, 'Anything important this week?');

    await tester.tap(find.text('Dentist appointment').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // The detail screen, not another assistant bubble.
    expect(find.text('Clinica Central, Dr. Silva'), findsOneWidget);
  });

  testWidgets('an answer with nothing behind it cites nothing', (tester) async {
    await _openAssistant(tester);
    // Far enough out that the fixtures have nothing there, which is the one
    // case where the assistant has to answer without anything to point at.
    await _ask(tester, 'this week?');
    for (var i = 0; i < 7; i++) {
      await _ask(tester, 'and the week after that?');
    }

    // It says it cannot find anything, and does not dress the admission up
    // with a strip of unrelated items.
    expect(find.text('BASED ON'), findsNothing);
  });
}
