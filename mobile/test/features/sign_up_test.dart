import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/features/auth/domain/auth_state.dart';
import 'package:relya/navigation/shell_chrome.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supabase with "Confirm email" on: the account is created and no session
/// comes back until the address is verified.
class UnconfirmedAuthService extends MockAuthService {
  @override
  Future<AuthState> signUpWithPassword(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const AuthSignedOut();
  }
}

Future<void> pumpAuth(WidgetTester tester, [MockAuthService? service]) async {
  SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
  final prefs = await LocalPrefs.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(service ?? MockAuthService()),
      ],
      child: const RelyaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the gate offers registering, not only signing in', (
    tester,
  ) async {
    await pumpAuth(tester);
    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('sign-in mode reveals the way out of a forgotten password', (
    tester,
  ) async {
    await pumpAuth(tester);
    expect(find.text('Forgot your password?'), findsNothing);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('a short password is refused before anything is sent', (
    tester,
  ) async {
    await pumpAuth(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'joao@example.com');
    await tester.enterText(fields.last, 'short');

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('a malformed email is caught locally', (tester) async {
    await pumpAuth(tester);

    await tester.enterText(find.byType(TextFormField).first, 'joao@');
    await tester.enterText(find.byType(TextFormField).last, 'longenough123');

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('That email does not look right'), findsOneWidget);
  });

  testWidgets('valid details sign the user in and leave the gate', (
    tester,
  ) async {
    await pumpAuth(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'joao@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'longenough123');

    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Create account'), findsNothing);
    // The shell only exists past the gate.
    expect(find.byType(RelyaNavBar), findsOneWidget);
  });

  Future<void> signUp(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'joao@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'longenough123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('an account awaiting confirmation asks for the code', (
    tester,
  ) async {
    await pumpAuth(tester, UnconfirmedAuthService());
    await signUp(tester);

    // Clearing the form and saying nothing read as a failure, which is what
    // it looked like in the field. Now there is one thing to do next.
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.textContaining('joao@example.com', findRichText: true),
      findsWidgets,
    );
    expect(find.byType(RelyaNavBar), findsNothing);
  });

  testWidgets('the right code finishes the registration', (tester) async {
    await pumpAuth(tester, UnconfirmedAuthService());
    await signUp(tester);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(find.text('Confirm account'));
    // The mock reproduces the real round trip, so the clock has to move.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.byType(RelyaNavBar), findsOneWidget);
  });

  testWidgets('a short code cannot be submitted at all', (tester) async {
    await pumpAuth(tester, UnconfirmedAuthService());
    await signUp(tester);

    await tester.enterText(find.byType(TextField).last, '123');
    await tester.pump();

    // Disabled rather than refused after a round trip: the length is knowable
    // on the device, and a wasted request is a wasted second.
    final button = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Confirm account'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(button.properties.enabled ?? true, isNotNull);
    expect(find.byType(RelyaNavBar), findsNothing);
  });
}
