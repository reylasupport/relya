import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/app.dart';
import 'package:relya/features/auth/application/auth_controller.dart';
import 'package:relya/features/auth/data/mock_auth_service.dart';
import 'package:relya/features/home/presentation/widgets/focus_card.dart';
import 'package:relya/services/prefs/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('a signed-in user lands on Home and sees what matters today', (
    tester,
  ) async {
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

    // Let the fixture repositories settle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining('Good'), findsOneWidget);

    // The poster carries the most urgent thing, and the list carries the rest
    // without repeating it.
    expect(find.byType(FocusCard), findsOneWidget);
    expect(find.text('Package arriving'), findsOneWidget);
    expect(find.text('Dentist appointment'), findsOneWidget);
    expect(find.text('TODAY'), findsWidgets);
  });

  testWidgets('a signed-out user is held at the sign-in gate', (tester) async {
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

    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
