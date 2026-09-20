import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/l10n/gen/app_localizations.dart';
import 'package:relya/navigation/shell_chrome.dart';
import 'package:relya/shared/domain/user_profile.dart';
import 'package:relya/shared/widgets/profile_avatar.dart';

/// The way to your account, from anywhere.
///
/// The avatar lives in the Home header, so it is gone the moment somebody
/// scrolls and absent altogether on the other four tabs. It follows them into
/// the bar instead - and the thing worth pinning down is that it arrives
/// without taking a destination away, because covering a tab to reach the
/// account would trade one way in for another.
void main() {
  const profile = UserProfile(
    id: 'u1',
    displayName: 'Joao Mendes',
    email: 'joao@example.com',
    plan: PlanTier.free,
  );

  /// How much of its own width the slot is letting the row see. The avatar
  /// keeps its size throughout; it is the fold around it that animates.
  double? foldFactor(WidgetTester tester) => tester
      .widget<Align>(
        find
            .ancestor(
              of: find.byType(ProfileAvatar),
              matching: find.byType(Align),
            )
            .first,
      )
      .widthFactor;

  Future<void> pumpBar(WidgetTester tester, {required bool showProfile}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: RelyaNavBar(
            selectedIndex: 2,
            onSelected: (_) {},
            showProfile: showProfile,
            profile: profile,
            onProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('at the top of Home the bar carries no avatar', (tester) async {
    await pumpBar(tester, showProfile: false);

    // Present in the tree but folded to nothing, and deliberately not a
    // target: a keyboard and a screen reader must not find a button that
    // nobody can see.
    final avatar = tester.widget<ProfileAvatar>(find.byType(ProfileAvatar));
    expect(avatar.onTap, isNull);
    expect(foldFactor(tester), 0);
  });

  testWidgets('once the header is gone the avatar is there and tappable', (
    tester,
  ) async {
    await pumpBar(tester, showProfile: true);

    final avatar = tester.widget<ProfileAvatar>(find.byType(ProfileAvatar));
    expect(avatar.onTap, isNotNull);
    expect(foldFactor(tester), 1);
  });

  testWidgets('it arrives beside the destinations, never on top of one', (
    tester,
  ) async {
    await pumpBar(tester, showProfile: true);

    // All five areas still reachable.
    for (final label in ['Home', 'Inbox', 'Upcoming', 'Life', 'Assistant']) {
      expect(find.text(label), findsOneWidget, reason: '$label went missing');
    }

    // And the avatar sits to the right of the last of them.
    final assistant = tester.getCenter(find.text('Assistant'));
    final avatar = tester.getCenter(find.byType(ProfileAvatar));
    expect(avatar.dx, greaterThan(assistant.dx));
  });

  testWidgets('the bar still works with no profile loaded yet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: RelyaNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            showProfile: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The first frame after a cold start has no profile. The bar must not
    // wait for one.
    expect(find.byType(ProfileAvatar), findsOneWidget);
  });
}
