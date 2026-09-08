/// Which day a week starts on.
///
/// Flutter's own MaterialLocalizations answers this wrongly for several
/// locales we ship: it reports Sunday for pt-PT, pt-BR and en-GB, all of which
/// start on Monday in practice. A calendar that opens on the wrong day is the
/// kind of small wrongness that makes an app feel foreign, so this derives it
/// from the region instead.
///
/// The list is the minority: everywhere not named here starts on Monday, which
/// is both the ISO 8601 rule and the majority of the world.
abstract final class WeekStart {
  const WeekStart._();

  /// Regions whose week starts on Sunday.
  static const Set<String> _sunday = {
    'US',
    'CA',
    'MX',
    'BR',
    'JP',
    'KR',
    'TW',
    'HK',
    'PH',
    'IL',
    'ZA',
    'CO',
    'PE',
    'VE',
    'AR',
    'CL',
    'DO',
    'GT',
    'HN',
    'NI',
    'PA',
    'PY',
    'SV',
    'BO',
    'EC',
    'JM',
    'TT',
    'BS',
    'BZ',
    'PR',
    'IN',
    'ID',
    'TH',
    'SG',
    'MY',
    'PK',
    'CN',
    'AU',
    'NZ',
  };

  /// Regions whose week starts on Saturday.
  static const Set<String> _saturday = {
    'AE',
    'AF',
    'BH',
    'DJ',
    'DZ',
    'EG',
    'IQ',
    'IR',
    'JO',
    'KW',
    'LY',
    'OM',
    'QA',
    'SA',
    'SD',
    'SY',
    'YE',
  };

  /// 0 = Sunday, 1 = Monday, 6 = Saturday. Matches the index Flutter's
  /// MaterialLocalizations uses, so it is a drop-in replacement.
  static int indexFor(String? region) {
    if (region == null || region.isEmpty) return 1;
    final code = region.toUpperCase();
    if (_sunday.contains(code)) return 0;
    if (_saturday.contains(code)) return 6;
    return 1;
  }

  /// Reads the region out of a formatting tag such as `pt_PT` or `en-GB`.
  static int forLocaleTag(String tag) {
    final parts = tag.split(RegExp('[_-]'));
    return indexFor(parts.length > 1 ? parts.last : null);
  }
}
