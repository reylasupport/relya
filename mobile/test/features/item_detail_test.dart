import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/core/design/components/app_card.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  testWidgets('tapping a scheduled item opens its detail', (tester) async {
    await pumpSignedIn(tester);

    expect(find.text('Dentist appointment'), findsOneWidget);
    await tester.tap(find.text('Dentist appointment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // The detail screen must actually say what the thing is.
    expect(find.text('Dentist appointment'), findsWidgets);
    expect(find.text('Clinica Central'), findsWidgets);
  });

  testWidgets('the detail screen actually shows the facts', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.text('Dentist appointment'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Title, type, and the fact rows the layout crash used to swallow.
    expect(find.text('Clinica Central, Dr. Silva'), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('Add to calendar'), findsOneWidget);
    expect(find.text('This is wrong'), findsOneWidget);
  });

  testWidgets('the buttons on the detail screen respond', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.text('Dentist appointment'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsWidgets);

    await tester.tap(find.text('This is wrong'));
    await tester.pumpAndSettle();
    expect(find.text('This is wrong'), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('an item with a money amount renders its amount', (tester) async {
    await pumpSignedIn(tester);

    await tester.scrollUntilVisible(
      find.text('Netflix renews'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netflix renews'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // The label is asserted rather than the formatted number, which changes
    // with the device region.
    expect(find.text('Amount'), findsOneWidget);
    expect(find.textContaining('15'), findsWidgets);
  });

  testWidgets('the category is shown as a word, not as an enum value', (
    tester,
  ) async {
    await pumpSignedIn(tester);
    await tester.tap(find.text('Dentist appointment'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Case is a design decision - the eyebrow is small caps in three of the
    // four - so the assertion is about the word, not about its casing.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').toLowerCase() == 'appointment',
      ),
      findsOneWidget,
    );
    // The wire value is for the database and the model, never for a person.
    // It is lower case, so this would still catch it leaking through.
    expect(find.text('appointment'), findsNothing);
  });
}
