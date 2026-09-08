/// How often a repeating item comes back.
///
/// A deliberately small subset of RFC 5545: a frequency and an interval, and
/// nothing else. "Every second Tuesday of the month" is a calendar feature;
/// a subscription, a rent payment and an annual inspection are all covered by
/// what is here, and every occurrence stays predictable enough to explain in
/// one line of interface.
enum RecurrenceFrequency {
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY'),
  yearly('YEARLY');

  const RecurrenceFrequency(this.wire);

  final String wire;

  static RecurrenceFrequency? fromWire(String? value) {
    if (value == null) return null;
    final upper = value.toUpperCase();
    for (final frequency in values) {
      if (frequency.wire == upper) return frequency;
    }
    return null;
  }
}

class RecurrenceRule {
  const RecurrenceRule({required this.frequency, this.interval = 1});

  final RecurrenceFrequency frequency;

  /// Every [interval] units of [frequency]. Always at least 1.
  final int interval;

  /// Parses `FREQ=MONTHLY;INTERVAL=2`.
  ///
  /// Also accepts the loose strings the model tends to produce - "monthly",
  /// "every year" - because the extraction schema asks for a hint, not for
  /// RFC 5545, and a hint we can read is worth more than one we discard.
  static RecurrenceRule? tryParse(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    final upper = text.toUpperCase();
    if (upper.contains('FREQ=')) {
      RecurrenceFrequency? frequency;
      var interval = 1;
      for (final part in upper.split(';')) {
        final pair = part.split('=');
        if (pair.length != 2) continue;
        switch (pair[0].trim()) {
          case 'FREQ':
            frequency = RecurrenceFrequency.fromWire(pair[1].trim());
          case 'INTERVAL':
            interval = int.tryParse(pair[1].trim()) ?? 1;
        }
      }
      if (frequency == null) return null;
      return RecurrenceRule(frequency: frequency, interval: interval.abs());
    }

    // The loose forms, in the four languages the app speaks. Ordered from the
    // most specific word to the least, because "semanas" also contains "ana"
    // and a set would have no say in which one won.
    const words = <(String, RecurrenceFrequency)>[
      ('DAILY', RecurrenceFrequency.daily),
      ('WEEKLY', RecurrenceFrequency.weekly),
      ('MONTHLY', RecurrenceFrequency.monthly),
      ('YEARLY', RecurrenceFrequency.yearly),
      ('ANNUAL', RecurrenceFrequency.yearly),
      ('DIÁRI', RecurrenceFrequency.daily),
      ('DIARI', RecurrenceFrequency.daily),
      ('SEMANA', RecurrenceFrequency.weekly),
      ('SEMANAL', RecurrenceFrequency.weekly),
      ('MENSUAL', RecurrenceFrequency.monthly),
      ('MENSAL', RecurrenceFrequency.monthly),
      ('ANUAL', RecurrenceFrequency.yearly),
      ('WEEK', RecurrenceFrequency.weekly),
      ('MONTH', RecurrenceFrequency.monthly),
      ('YEAR', RecurrenceFrequency.yearly),
      ('MES', RecurrenceFrequency.monthly),
      ('ANO', RecurrenceFrequency.yearly),
      ('AÑO', RecurrenceFrequency.yearly),
      ('DIA', RecurrenceFrequency.daily),
      ('DÍA', RecurrenceFrequency.daily),
      ('DAY', RecurrenceFrequency.daily),
    ];
    for (final (needle, frequency) in words) {
      if (upper.contains(needle)) return RecurrenceRule(frequency: frequency);
    }
    return null;
  }

  String toWire() => interval == 1
      ? 'FREQ=${frequency.wire}'
      : 'FREQ=${frequency.wire};INTERVAL=$interval';

  /// The next occurrence strictly after [from].
  ///
  /// Month and year steps clamp rather than overflow: the 31st of January
  /// repeated monthly lands on the 28th of February, not the 3rd of March,
  /// which is what a person means by "every month on the 31st".
  DateTime next(DateTime from) {
    final step = interval < 1 ? 1 : interval;
    return switch (frequency) {
      RecurrenceFrequency.daily => from.add(Duration(days: step)),
      RecurrenceFrequency.weekly => from.add(Duration(days: 7 * step)),
      RecurrenceFrequency.monthly => _addMonths(from, step),
      RecurrenceFrequency.yearly => _addMonths(from, 12 * step),
    };
  }

  static DateTime _addMonths(DateTime from, int months) {
    final totalMonths = from.month - 1 + months;
    final year = from.year + (totalMonths ~/ 12);
    final month = totalMonths % 12 + 1;
    final lastDay = _daysIn(year, month);
    final day = from.day <= lastDay ? from.day : lastDay;
    // Built in the same zone it arrived in: reading the components off a local
    // instant and reassembling them as UTC would move the clock.
    return from.isUtc
        ? DateTime.utc(year, month, day, from.hour, from.minute, from.second)
        : DateTime(year, month, day, from.hour, from.minute, from.second);
  }

  static int _daysIn(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.frequency == frequency &&
      other.interval == interval;

  @override
  int get hashCode => Object.hash(frequency, interval);

  @override
  String toString() => toWire();
}
