import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analysis/presentation/analysis_screen.dart';
import '../features/assistant/presentation/assistant_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/capture/presentation/manual_entry_screen.dart';
import '../features/capture/presentation/paste_text_screen.dart';
import '../features/capture/presentation/quick_add_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/item/presentation/item_detail_screen.dart';
import '../features/item/presentation/item_edit_screen.dart';
import '../features/life/presentation/entity_detail_screen.dart';
import '../features/life/presentation/life_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/account_screen.dart';
import '../features/settings/presentation/appearance_screen.dart';
import '../features/settings/presentation/email_inbox_screen.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';

import '../features/subscription/presentation/paywall_screen.dart';
import '../features/upcoming/presentation/upcoming_screen.dart';
import '../services/prefs/local_prefs.dart';
import 'app_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// One router, one place where "where should this user be" is decided.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final seenOnboarding = ref.read(onboardingSeenProvider);
      // Read the stream state directly rather than a derived provider: a
      // cached Provider that nothing is watching can still be holding the
      // previous value when redirect runs, which would strand a user who has
      // just signed in on the sign-in screen.
      final authState =
          ref.read(authStateProvider).valueOrNull ??
          ref.read(authServiceProvider).current;
      final signedIn = authState is AuthSignedIn;
      final location = state.matchedLocation;

      if (!seenOnboarding) {
        return location == Routes.onboarding ? null : Routes.onboarding;
      }
      if (!signedIn) {
        return location == Routes.signIn ? null : Routes.signIn;
      }
      // A signed-in user has no business on the gates.
      if (location == Routes.onboarding || location == Routes.signIn) {
        return Routes.home;
      }
      return null;
    },
    refreshListenable: _Refresh(ref),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inbox,
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.upcoming,
                builder: (context, state) => const UpcomingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.life,
                builder: (context, state) => const LifeScreen(),
                routes: [
                  GoRoute(
                    path: Routes.entityPattern,
                    builder: (context, state) => EntityDetailScreen(
                      entityId: state.pathParameters['entityId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.assistant,
                builder: (context, state) => const AssistantScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.analysisPattern,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            AnalysisScreen(captureId: state.pathParameters['captureId']!),
      ),
      GoRoute(
        path: Routes.itemPattern,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ItemDetailScreen(itemId: state.pathParameters['itemId']!),
      ),
      GoRoute(
        path: Routes.itemEditPattern,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            ItemEditScreen(itemId: state.pathParameters['itemId']!),
      ),
      GoRoute(
        path: Routes.captureText,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PasteTextScreen(),
      ),
      GoRoute(
        path: Routes.captureManual,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ManualEntryScreen(),
      ),
      GoRoute(
        path: Routes.captureQuickAdd,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const QuickAddScreen(),
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.paywall,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AccountScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'email',
            builder: (context, state) => const EmailInboxScreen(),
          ),
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearanceScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Rebuilds the router when the gates change, so completing onboarding or
/// signing out moves the user without any explicit navigation call.
class _Refresh extends ChangeNotifier {
  _Refresh(Ref ref) {
    ref.listen(onboardingSeenProvider, (_, __) => notifyListeners());
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
