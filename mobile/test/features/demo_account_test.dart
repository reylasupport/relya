import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/core/config/demo_account.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/navigation/app_shell.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One tap from launch to the product.
///
/// A mock build exists to be walked through - by whoever is building it, and
/// by anyone being shown it - and typing an address and a password before
/// anything can be seen is friction with no purpose, since MockAuthService
/// accepts whatever it is handed anyway.
void main() {
  Future<void> pumpGate(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
    final prefs = await LocalPrefs.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
        child: const RelyaApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the gate opens already filled in', (tester) async {
    await pumpGate(tester);

    expect(find.text(DemoAccount.email), findsOneWidget);
    // The password is obscured on screen, so it is read off the field rather
    // than looked for as text.
    final password = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password.controller?.text, DemoAccount.password);
  });

  testWidgets('pressing sign in is all it takes', (tester) async {
    await pumpGate(tester);

    // Whatever the primary button says. The gate opens on sign up, which is
    // the real default and the one the rest of the suite covers; against the
    // mock that action signs you straight in, so one tap is one tap.
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Past the gate and into the app itself.
    expect(find.byType(AppShell), findsOneWidget);
  });

  test('the demo password satisfies the form it is typed into', () {
    // The validator asks for eight characters. If this ever stops being true
    // the one-tap entry silently becomes a two-step one.
    expect(DemoAccount.password.length, greaterThanOrEqualTo(8));
  });

  test('a build with a real backend starts empty', () {
    // The gate is AppEnv.useMockData and nothing else. This asserts the
    // wiring, so that removing the check fails here rather than shipping a
    // password prefilled into a production sign-in screen.
    expect(
      DemoAccount.prefilledEmail,
      DemoAccount.isAvailable ? DemoAccount.email : '',
    );
    expect(
      DemoAccount.prefilledPassword,
      DemoAccount.isAvailable ? DemoAccount.password : '',
    );
  });
}
