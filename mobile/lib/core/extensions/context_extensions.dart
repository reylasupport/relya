import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

extension BuildContextX on BuildContext {
  /// Localised strings. Short name because it appears on nearly every line of
  /// UI code; the alternative is a 30-character call everywhere.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The locale to format dates, times and money with.
  ///
  /// Deliberately not just the interface locale. Portugal and Brazil share one
  /// translation file, so a Portuguese user resolves to plain "pt", which in
  /// ICU means Brazilian conventions: they would see the euro sign on the
  /// wrong side of the number. Keeping the region from the device fixes that,
  /// and it is what the specification asks for anyway - interface language and
  /// regional formatting are separate choices.
  String get localeTag {
    final ui = Localizations.localeOf(this);
    final device = WidgetsBinding.instance.platformDispatcher.locale;

    if (ui.languageCode == device.languageCode) {
      final region = device.countryCode;
      if (region != null && region.isNotEmpty) {
        return '${ui.languageCode}_$region';
      }
    }

    final region = ui.countryCode;
    return (region == null || region.isEmpty)
        ? ui.languageCode
        : '${ui.languageCode}_$region';
  }

  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
