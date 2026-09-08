import 'package:flutter_test/flutter_test.dart';
import 'package:relya/shared/domain/recurrence.dart';

void main() {
  group('RecurrenceRule.tryParse', () {
    test('reads the RFC form the schema asks for', () {
      final rule = RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=2');
      expect(rule?.frequency, RecurrenceFrequency.monthly);
      expect(rule?.interval, 2);
      expect(rule?.toWire(), 'FREQ=MONTHLY;INTERVAL=2');
    });

    test('reads the loose words the model actually returns', () {
      // The extraction schema asks for a hint, not for RFC 5545, and a hint we
      // can read is worth more than one we discard.
      expect(
        RecurrenceRule.tryParse('mensal')?.frequency,
        RecurrenceFrequency.monthly,
      );
      expect(
        RecurrenceRule.tryParse('every year')?.frequency,
        RecurrenceFrequency.yearly,
      );
      expect(RecurrenceRule.tryParse('once in a while'), isNull);
      expect(RecurrenceRule.tryParse(null), isNull);
      expect(RecurrenceRule.tryParse('  '), isNull);
    });

    test('an interval of one is left out of the wire form', () {
      expect(
        const RecurrenceRule(frequency: RecurrenceFrequency.weekly).toWire(),
        'FREQ=WEEKLY',
      );
    });
  });

  group('RecurrenceRule.next', () {
    test('days and weeks are plain arithmetic', () {
      const daily = RecurrenceRule(frequency: RecurrenceFrequency.daily);
      expect(
        daily.next(DateTime.utc(2026, 3, 31, 9)),
        DateTime.utc(2026, 4, 1, 9),
      );

      const fortnightly = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
      );
      expect(
        fortnightly.next(DateTime.utc(2026, 9, 8)),
        DateTime.utc(2026, 9, 22),
      );
    });

    test('a monthly rule on the 31st clamps instead of overflowing', () {
      // Adding 31 days to 31 January lands in March, which is not what anyone
      // means by "every month".
      const monthly = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      expect(
        monthly.next(DateTime.utc(2026, 1, 31, 8, 30)),
        DateTime.utc(2026, 2, 28, 8, 30),
      );
      expect(
        monthly.next(DateTime.utc(2028, 1, 31)),
        DateTime.utc(2028, 2, 29),
      );
    });

    test('December rolls into January of the next year', () {
      const monthly = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      expect(
        monthly.next(DateTime.utc(2026, 12, 15, 10)),
        DateTime.utc(2027, 1, 15, 10),
      );
    });

    test('a yearly rule keeps the day and the clock', () {
      const yearly = RecurrenceRule(frequency: RecurrenceFrequency.yearly);
      expect(
        yearly.next(DateTime.utc(2026, 6, 4, 14, 45)),
        DateTime.utc(2027, 6, 4, 14, 45),
      );
    });

    test('a local instant stays local', () {
      // Reading the components off a local instant and reassembling them as
      // UTC would silently move the clock by the offset.
      const monthly = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      final next = monthly.next(DateTime(2026, 5, 10, 7, 15));
      expect(next.isUtc, isFalse);
      expect(next.hour, 7);
      expect(next.month, 6);
    });
  });
}
