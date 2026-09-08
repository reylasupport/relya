import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Parity between the four translation files, checked rather than claimed.
///
/// The ARB files are edited by hand, one key at a time, in four places. A key
/// added to English and forgotten in Spanish does not fail the build - it
/// falls back silently, and the first person to notice is a Spanish user
/// reading English. This is the cheapest possible guard against that.
void main() {
  const dir = 'lib/l10n';
  const template = 'app_en.arb';
  const translations = ['app_pt.arb', 'app_pt_BR.arb', 'app_es.arb'];

  Map<String, dynamic> load(String name) =>
      jsonDecode(File('$dir/$name').readAsStringSync()) as Map<String, dynamic>;

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  test('every translation carries exactly the keys English carries', () {
    final expected = messageKeys(load(template));

    for (final file in translations) {
      final actual = messageKeys(load(file));
      expect(
        actual.difference(expected),
        isEmpty,
        reason: '$file has keys that no longer exist in $template',
      );
      expect(
        expected.difference(actual),
        isEmpty,
        reason: '$file is missing keys that $template defines',
      );
    }
  });

  test('no message is left as the English string in another language', () {
    final english = load(template);
    // Proper nouns and symbols legitimately match across languages.
    const allowed = {
      'appearanceMode',
      'settingsAnalytics',
      'assistantTitle',
      'settingsPrivacy',
      'errorAmount',
    };

    for (final file in translations) {
      final other = load(file);
      final untranslated = <String>[];
      for (final key in messageKeys(english)) {
        if (allowed.contains(key)) continue;
        final source = english[key];
        if (source is! String || source.length < 12) continue;
        if (other[key] == source) untranslated.add(key);
      }
      expect(
        untranslated,
        isEmpty,
        reason: '$file still holds the English text for these keys',
      );
    }
  });
}
