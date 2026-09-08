import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/extensions/context_extensions.dart';
import 'package:relya/l10n/gen/app_localizations.dart';
import 'package:relya/l10n/supported_locales.dart';

/// Portugal and Brazil share one translation file, so a Portuguese user
/// resolves to plain "pt" - which in ICU means Brazilian conventions. The
/// formatting locale has to keep the device region or they see the euro on the
/// wrong side of the number.
Future<String> tagFor(WidgetTester tester, {required Locale device}) async {
  tester.platformDispatcher.localeTestValue = device;
  tester.platformDispatcher.localesTestValue = [device];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  late String tag;
  await tester.pumpWidget(
    MaterialApp(
      locale: device,
      supportedLocales: SupportedLocales.locales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          tag = context.localeTag;
          return const SizedBox();
        },
      ),
    ),
  );
  return tag;
}

void main() {
  testWidgets('a Portuguese device keeps its region', (tester) async {
    expect(await tagFor(tester, device: const Locale('pt', 'PT')), 'pt_PT');
  });

  testWidgets('a Brazilian device keeps its region', (tester) async {
    expect(await tagFor(tester, device: const Locale('pt', 'BR')), 'pt_BR');
  });

  testWidgets('a region-less locale still produces a usable tag', (
    tester,
  ) async {
    expect(await tagFor(tester, device: const Locale('es')), 'es');
  });

  testWidgets('an American device is unaffected', (tester) async {
    expect(await tagFor(tester, device: const Locale('en', 'US')), 'en_US');
  });
}
