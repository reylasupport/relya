import 'package:flutter/widgets.dart';

/// A language the interface ships in.
class AppLocale {
  const AppLocale(this.locale, this.nativeName);

  final Locale locale;

  /// Shown in its own language, never translated. A Polish speaker looking for
  /// their language scans for "Polski", not for "Polish".
  final String nativeName;

  String get tag => locale.toLanguageTag();
}

/// Tier 1 of the launch plan (spec section 46). Tier 2 and 3 are added by
/// dropping in an ARB file and one line here; nothing else changes.
abstract final class SupportedLocales {
  const SupportedLocales._();

  static const List<AppLocale> all = [
    AppLocale(Locale('en'), 'English'),
    AppLocale(Locale('pt', 'PT'), 'Portugues (Portugal)'),
    AppLocale(Locale('pt', 'BR'), 'Portugues (Brasil)'),
    AppLocale(Locale('es'), 'Espanol'),
  ];

  static List<Locale> get locales => all.map((l) => l.locale).toList();

  /// Right-to-left languages, for when Arabic joins tier 3. Listed here so the
  /// layout work is a data change rather than a code change.
  static const Set<String> rtlLanguages = {'ar', 'he', 'fa', 'ur'};

  static Locale? fromTag(String? tag) {
    if (tag == null) return null;
    for (final entry in all) {
      if (entry.tag == tag) return entry.locale;
    }
    return null;
  }
}
