import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:relya/features/item/presentation/item_edit_screen.dart';
import 'package:relya/l10n/gen/app_localizations.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/shared/data/mock/mock_simple_repositories.dart';
import 'package:relya/shared/data/providers.dart';
import 'package:relya/shared/domain/life_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Editing something already saved.
///
/// Two hundred lines of form, validation and a write, at zero coverage. It is
/// also the screen where a mistake costs more than anywhere else in the app:
/// a wrong reading on the confirmation screen can simply be thrown away, but
/// this one overwrites something the user already accepted as correct.
void main() {
  late MockLifeItemRepository items;
  late MockReminderRepository reminders;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    items = MockLifeItemRepository();
    reminders = MockReminderRepository();
  });

  /// The screen pops through GoRouter once the save lands, so the test needs a
  /// real one. Without it the tap throws behind the saving spinner, and a
  /// spinner that never stops is a test that never finishes.
  Future<void> pumpEdit(WidgetTester tester, String id) async {
    // A viewport tall enough for the whole form. Scrolling to the button on a
    // phone-sized surface works on a phone and is only a source of flake in a
    // test: the form is what is under test, not the ListView.
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('behind')),
          routes: [
            GoRoute(
              path: 'edit/:id',
              builder: (_, state) =>
                  ItemEditScreen(itemId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lifeItemRepositoryProvider.overrideWithValue(items),
          reminderRepositoryProvider.overrideWithValue(reminders),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/edit/$id');
    await tester.pumpAndSettle();
  }

  /// Read through runAsync, always.
  ///
  /// The repository sleeps 120ms to imitate a network, and inside testWidgets
  /// that sleep is on a fake clock nobody is winding. Awaiting it directly
  /// deadlocks the test rather than failing it, which is a considerably worse
  /// way to find out.
  Future<LifeItem> stored(WidgetTester tester, String id) async {
    final item = await tester.runAsync(() => items.byId(id));
    return item!;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('the form opens on what the item already says', (tester) async {
    await pumpEdit(tester, 'itm-dentist');

    expect(find.text('Dentist appointment'), findsOneWidget);
    expect(find.text('Clinica Central, Dr. Silva'), findsOneWidget);
  });

  testWidgets('an empty title is refused before anything is written', (
    tester,
  ) async {
    await pumpEdit(tester, 'itm-dentist');
    final before = await stored(tester, 'itm-dentist');

    await tester.enterText(find.byType(TextFormField).first, '   ');
    await save(tester);

    expect(find.text('Give it a title first.'), findsOneWidget);
    // Still on the form, and the item untouched.
    expect(find.byType(ItemEditScreen), findsOneWidget);
    expect((await stored(tester, 'itm-dentist')).title, before.title);
  });

  testWidgets('a title the user typed is what gets saved', (tester) async {
    await pumpEdit(tester, 'itm-dentist');

    await tester.enterText(
      find.byType(TextFormField).first,
      'Dentist, second floor',
    );
    await save(tester);

    expect(
      (await stored(tester, 'itm-dentist')).title,
      'Dentist, second floor',
    );
  });

  testWidgets('an edited item stops being a guess', (tester) async {
    await pumpEdit(tester, 'itm-dentist');
    // The fixture was read by the model at 0.96 and never by a person.
    expect((await stored(tester, 'itm-dentist')).confidence, lessThan(1.0));

    await tester.enterText(
      find.byType(TextFormField).first,
      'Dentist, second floor',
    );
    await save(tester);

    // A field somebody corrected by hand is not a reading any more, and no
    // screen should go on asking the user to check it.
    expect((await stored(tester, 'itm-dentist')).confidence, 1.0);
  });

  testWidgets('a description wiped to spaces becomes absent, not blank', (
    tester,
  ) async {
    await pumpEdit(tester, 'itm-dentist');

    await tester.enterText(find.byType(TextFormField).at(1), '    ');
    await save(tester);

    // Null and empty read differently on every screen that shows this.
    expect((await stored(tester, 'itm-dentist')).description, isNull);
  });
}
