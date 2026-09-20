import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handing an item to the calendar, once.
///
/// add_2_calendar can add an event and nothing else: it cannot read a
/// calendar and it cannot delete from one. So the button happily made a
/// second copy of something already there, said "Done" either way, and left
/// no way back - which is why it was not obvious what it had done at all.
void main() {
  late LocalPrefs prefs;

  Future<void> openDentist(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
    prefs = await LocalPrefs.load();
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

    await tester.tap(find.text('Dentist appointment'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('it offers to add, then says where the event went', (
    tester,
  ) async {
    await openDentist(tester);
    expect(find.text('Add to calendar'), findsOneWidget);

    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();

    // The button now reports a state rather than repeating an offer.
    expect(find.text('Add to calendar'), findsNothing);
    expect(find.text('In your calendar'), findsWidgets);
  });

  testWidgets('it remembers, so the same event is not added twice', (
    tester,
  ) async {
    await openDentist(tester);
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();

    expect(prefs.isInCalendar('itm-dentist'), isTrue);
  });

  testWidgets('tapping it again explains where to remove it', (tester) async {
    await openDentist(tester);
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('In your calendar').first);
    await tester.pumpAndSettle();

    // There is no Remove here and there cannot be one, so the app says so
    // rather than pretending the button is broken.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining('removing it has to happen there'),
      findsOneWidget,
    );
    // Adding a second copy stays possible - deliberately, and on purpose.
    expect(find.text('Add it again'), findsOneWidget);
  });

  testWidgets('a fresh install offers to add again', (tester) async {
    await openDentist(tester);

    // Nothing remembered means nothing was handed over on this device.
    expect(prefs.isInCalendar('itm-dentist'), isFalse);
    expect(find.text('Add to calendar'), findsOneWidget);
  });
}
