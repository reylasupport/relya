import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/app_skin.dart';
import 'package:relya/core/design/tokens/app_skin_style.dart';
import 'package:relya/features/analysis/presentation/analysis_screen.dart';
import 'package:relya/features/assistant/presentation/assistant_screen.dart';
import 'package:relya/features/auth/presentation/sign_in_screen.dart';
import 'package:relya/features/capture/presentation/manual_entry_screen.dart';
import 'package:relya/features/capture/presentation/paste_text_screen.dart';
import 'package:relya/features/home/presentation/home_screen.dart';
import 'package:relya/features/inbox/presentation/inbox_screen.dart';
import 'package:relya/features/item/presentation/item_detail_screen.dart';
import 'package:relya/features/life/presentation/entity_detail_screen.dart';
import 'package:relya/features/life/presentation/life_screen.dart';
import 'package:relya/features/onboarding/presentation/onboarding_screen.dart';
import 'package:relya/features/onboarding/presentation/widgets/how_to_add.dart';
import 'package:relya/features/onboarding/presentation/widgets/live_demo.dart';
import 'package:relya/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:relya/features/settings/presentation/account_screen.dart';
import 'package:relya/features/search/presentation/search_screen.dart';
import 'package:relya/features/settings/presentation/appearance_screen.dart';
import 'package:relya/features/settings/presentation/notification_settings_screen.dart';
import 'package:relya/features/settings/presentation/privacy_settings_screen.dart';
import 'package:relya/features/subscription/presentation/paywall_screen.dart';
import 'package:relya/navigation/app_shell.dart';
import 'package:relya/navigation/shell_chrome.dart';
import 'package:relya/shared/data/mock/mock_capture_repository.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/shared/data/providers.dart';
import 'package:relya/features/upcoming/presentation/upcoming_screen.dart';
import 'package:relya/l10n/gen/app_localizations.dart';

/// Renders real screens to PNG, with fixtures, at phone size.
///
///     flutter test tool/generate_screenshots.dart
///
/// Design review without a device, and repeatable: the same screens come out
/// the same way every run, so a change that breaks a layout is visible in a
/// diff rather than discovered on someone's phone.
const Size _phone = Size(390, 844);

/// The test binding draws boxes instead of glyphs unless a real font is
/// registered. Roboto ships inside the Flutter SDK, so the screenshots come
/// out looking like the Android build rather than like a wireframe.
Future<void> loadFonts() async {
  // The bundled serif first: it lives in the project, not in the SDK cache,
  // and Concept F is unreadable without it.
  await _loadBundled('Merriweather', [
    'assets/fonts/merriweather/Merriweather-Light.ttf',
    'assets/fonts/merriweather/Merriweather-Regular.ttf',
  ]);

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var found = false;
    for (final name in files) {
      final file = File('${dir.path}/$name');
      if (!file.existsSync()) continue;
      found = true;
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }
    if (found) await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

Future<void> _loadBundled(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var found = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    found = true;
    loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
  }
  if (found) await loader.load();
}

Future<void> shoot({
  required WidgetTester tester,
  required Widget child,
  required String name,
  Brightness brightness = Brightness.dark,
  AppSkin skin = AppSkin.soft,
  Locale locale = const Locale('pt', 'PT'),
  List<Override> overrides = const [],
  Duration settle = const Duration(milliseconds: 900),

  /// Runs after the first settle, for screens that need a tap or some typing
  /// to reach the state worth photographing.
  Future<void> Function(WidgetTester)? after,
}) async {
  tester.view.physicalSize = _phone * 3;
  tester.view.devicePixelRatio = 3;
  // The formatting locale reads the device region, so the screenshots have to
  // say where the device is or they show Brazilian number formats.
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await loadFonts();
  final key = GlobalKey();

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _withFont(
            brightness == Brightness.light
                ? AppTheme.light(skin)
                : AppTheme.dark(skin),
          ),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: child,
          ),
        ),
      ),
    ),
  );

  // Repeated small pumps rather than one big jump: staggered entrances only
  // start their controller once the row has been built, so a single long
  // pump captures them mid-fade.
  await tester.pump();
  final steps = (settle.inMilliseconds / 100).ceil() + 12;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  if (after != null) {
    await after(tester);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File('build/screenshots/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path}');
  });

  // Tear the tree down and let any in-flight timers drain. A mock repository
  // that simulates a two-second analysis leaves a pending Future behind, and
  // the test binding is right to complain about it.
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Wraps a tab screen in the real app frame, so a screenshot shows what the
/// user actually sees: the navigation bar and the capture button included.
Widget framed(Widget screen, int index) {
  const assistantTab = 4;
  return Builder(
    builder: (context) => Scaffold(
      body: screen,
      floatingActionButton:
          index == assistantTab || context.appSkin.nav == SkinNav.centre
          ? null
          : CaptureButton(
              tooltip: AppLocalizations.of(context).captureTitle,
              onPressed: () {},
            ),
      bottomNavigationBar: RelyaNavBar(
        selectedIndex: index,
        onSelected: (_) {},
        onCapture: () {},
        pendingCount: index == 1 ? 0 : 1,
      ),
    ),
  );
}

/// Repositories with nothing in them, for the empty states.
List<Override> get emptyData => [
  lifeItemRepositoryProvider.overrideWithValue(
    MockLifeItemRepository(items: const []),
  ),
  captureRepositoryProvider.overrideWithValue(
    MockCaptureRepository(captures: const []),
  ),
];
ThemeData _withFont(ThemeData theme) {
  const family = 'Roboto';
  ButtonStyle pin(ButtonStyle? style) =>
      (style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(fontFamily: family),
        ),
      );

  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: family),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: family,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: pin(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: pin(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: pin(theme.textButtonTheme.style),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: pin(theme.segmentedButtonTheme.style),
    ),
  );
}

void main() {
  // ------------------------------------------------------- before sign-in --

  testWidgets('01 onboarding welcome', (tester) async {
    await shoot(
      tester: tester,
      name: '01-onboarding-welcome',
      child: const OnboardingScreen(),
    );
  });

  testWidgets('02 onboarding demo', (tester) async {
    await shoot(
      tester: tester,
      name: '02-onboarding-demo',
      settle: const Duration(seconds: 6),
      child: const Scaffold(
        body: OnboardingBackdrop(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: DemoPage(),
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('03 onboarding how to add', (tester) async {
    await shoot(
      tester: tester,
      name: '03-onboarding-how',
      child: const Scaffold(
        body: OnboardingBackdrop(child: SafeArea(child: HowToAdd())),
      ),
    );
  });

  testWidgets('04 sign up', (tester) async {
    await shoot(
      tester: tester,
      name: '04-auth-signup',
      child: const SignInScreen(),
    );
  });

  testWidgets('05 sign in', (tester) async {
    await shoot(
      tester: tester,
      name: '05-auth-signin',
      child: const SignInScreen(),
      after: (tester) async {
        await tester.tap(find.text('Entrar').first);
        await tester.pumpAndSettle();
      },
    );
  });

  // ---------------------------------------------------------------- tabs --

  testWidgets('06 home', (tester) async {
    await shoot(
      tester: tester,
      name: '06-home',
      child: framed(const HomeScreen(), 0),
    );
  });

  testWidgets('07 home light', (tester) async {
    await shoot(
      tester: tester,
      name: '07-home-light',
      brightness: Brightness.light,
      child: framed(const HomeScreen(), 0),
    );
  });

  testWidgets('08 home empty', (tester) async {
    await shoot(
      tester: tester,
      name: '08-home-empty',
      overrides: emptyData,
      child: framed(const HomeScreen(), 0),
    );
  });

  testWidgets('09 inbox', (tester) async {
    await shoot(
      tester: tester,
      name: '09-inbox',
      child: framed(const InboxScreen(), 1),
    );
  });

  testWidgets('10 inbox empty', (tester) async {
    await shoot(
      tester: tester,
      name: '10-inbox-empty',
      overrides: emptyData,
      child: framed(const InboxScreen(), 1),
    );
  });

  testWidgets('11 upcoming calendar', (tester) async {
    await shoot(
      tester: tester,
      name: '11-upcoming-calendar',
      child: framed(const UpcomingScreen(), 2),
    );
  });

  testWidgets('12 upcoming list', (tester) async {
    await shoot(
      tester: tester,
      name: '12-upcoming-list',
      child: framed(const UpcomingScreen(), 2),
      after: (tester) async {
        await tester.tap(find.text('Lista'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('13 life', (tester) async {
    await shoot(
      tester: tester,
      name: '13-life',
      child: framed(const LifeScreen(), 3),
    );
  });

  testWidgets('14 assistant empty', (tester) async {
    await shoot(
      tester: tester,
      name: '14-assistant-empty',
      child: framed(const AssistantScreen(), 4),
    );
  });

  testWidgets('15 assistant chat', (tester) async {
    await shoot(
      tester: tester,
      name: '15-assistant-chat',
      child: framed(const AssistantScreen(), 4),
      settle: const Duration(seconds: 2),
      after: (tester) async {
        await tester.tap(
          find.text('Tenho alguma coisa importante esta semana?'),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      },
    );
  });

  // ------------------------------------------------------------- capture --

  testWidgets('16 capture sheet', (tester) async {
    await shoot(
      tester: tester,
      name: '16-capture-sheet',
      child: framed(const HomeScreen(), 0),
      after: (tester) async {
        // The framed button is inert on purpose, so open the real sheet with
        // the same call the shell makes.
        openCaptureSheet(tester.element(find.byType(HomeScreen)));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('17 paste text', (tester) async {
    await shoot(
      tester: tester,
      name: '17-capture-paste',
      child: const PasteTextScreen(),
    );
  });

  testWidgets('18 manual entry', (tester) async {
    await shoot(
      tester: tester,
      name: '18-capture-manual',
      child: const ManualEntryScreen(),
    );
  });

  // -------------------------------------------------------- the core flow --

  testWidgets('19 analysing', (tester) async {
    await shoot(
      tester: tester,
      name: '19-analysis-loading',
      settle: const Duration(milliseconds: 300),
      // A capture with no cached analysis, so the pipeline actually runs and
      // the progressive loader is on screen when the shutter goes.
      child: const AnalysisScreen(captureId: 'cap-insurance'),
    );
  });

  testWidgets('20 confirmation', (tester) async {
    await shoot(
      tester: tester,
      name: '20-analysis-confirm',
      settle: const Duration(seconds: 3),
      child: const AnalysisScreen(captureId: 'cap-pending'),
    );
  });

  testWidgets('21 item detail', (tester) async {
    await shoot(
      tester: tester,
      name: '21-item-detail',
      child: const ItemDetailScreen(itemId: 'itm-dentist'),
    );
  });

  testWidgets('22 entity detail', (tester) async {
    await shoot(
      tester: tester,
      name: '22-entity-detail',
      child: const EntityDetailScreen(entityId: 'ent-car'),
    );
  });

  // -------------------------------------------------- search and settings --

  testWidgets('23 search empty', (tester) async {
    await shoot(
      tester: tester,
      name: '23-search-empty',
      child: const SearchScreen(),
    );
  });

  testWidgets('24 search results', (tester) async {
    await shoot(
      tester: tester,
      name: '24-search-results',
      child: const SearchScreen(),
      after: (tester) async {
        await tester.enterText(find.byType(TextField), 'seguro');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('25 account', (tester) async {
    await shoot(
      tester: tester,
      name: '25-account',
      child: const AccountScreen(),
    );
  });

  testWidgets('26 appearance', (tester) async {
    await shoot(
      tester: tester,
      name: '26-appearance',
      child: const AppearanceScreen(),
    );
  });

  testWidgets('27 notification settings', (tester) async {
    await shoot(
      tester: tester,
      name: '27-settings-notifications',
      child: const NotificationSettingsScreen(),
    );
  });

  testWidgets('28 privacy settings', (tester) async {
    await shoot(
      tester: tester,
      name: '28-settings-privacy',
      child: const PrivacySettingsScreen(),
    );
  });

  testWidgets('29 paywall', (tester) async {
    await shoot(
      tester: tester,
      name: '29-paywall',
      settle: const Duration(seconds: 1),
      child: const PaywallScreen(),
    );
  });

  // ------------------------------------------------------------- the skins --

  // Each theme is drawn in the brightness it was designed for, and Home is
  // the fairest test: it has a gradient, a poster, coloured rows and money.
  for (final skin in AppSkin.values) {
    testWidgets('30 skin ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '30-skin-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const HomeScreen(), 0),
      );
    });

    // And in the other mode, because a phone that flips at sunset must not
    // turn the app into something nobody designed.
    testWidgets('31 skin ${skin.wire} inverted', (tester) async {
      await shoot(
        tester: tester,
        name: '31-skin-${skin.wire}-inverted',
        skin: skin,
        brightness: skin.nativeBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        child: framed(const HomeScreen(), 0),
      );
    });
  }

  // Four more per skin, because the difference between the concepts is not
  // only Home: the bar, the welcome, the timeline and the category grid are
  // all part of what makes each one itself.
  for (final skin in AppSkin.values) {
    testWidgets('33 welcome ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '33-welcome-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: const OnboardingScreen(),
      );
    });

    testWidgets('34 upcoming ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '34-upcoming-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const UpcomingScreen(), 2),
      );
    });

    testWidgets('35 life ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '35-life-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const LifeScreen(), 3),
      );
    });

    testWidgets('37 inbox ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '37-inbox-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const InboxScreen(), 1),
      );
    });

    testWidgets('38 upcoming list ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '38-upcoming-list-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const UpcomingScreen(), 2),
        after: (tester) async {
          final list = find.text('Lista');
          if (list.evaluate().isNotEmpty) {
            await tester.tap(list.first);
            await tester.pumpAndSettle();
          }
        },
      );
    });

    testWidgets('39 assistant ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '39-assistant-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const AssistantScreen(), 4),
      );
    });

    testWidgets('40 auth ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '40-auth-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: const SignInScreen(),
      );
    });

    testWidgets('41 add ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '41-add-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: framed(const HomeScreen(), 0),
        after: (tester) async {
          openCaptureSheet(tester.element(find.byType(HomeScreen)));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('42 item ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '42-item-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        child: const ItemDetailScreen(itemId: 'itm-dentist'),
      );
    });

    testWidgets('36 inbox empty ${skin.wire}', (tester) async {
      await shoot(
        tester: tester,
        name: '36-inbox-empty-${skin.wire}',
        skin: skin,
        brightness: skin.nativeBrightness,
        overrides: emptyData,
        child: framed(const InboxScreen(), 1),
      );
    });
  }

  testWidgets('32 appearance picker', (tester) async {
    await shoot(
      tester: tester,
      name: '32-appearance',
      brightness: Brightness.light,
      child: const AppearanceScreen(),
    );
  });
}

/// The demo slide, without the pager chrome around it.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingTitle3,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.onboardingBody3,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        const LiveDemo(),
      ],
    );
  }
}
