import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/formatting/time_bucket.dart';

void main() {
  final now = DateTime(2026, 9, 3, 14, 30);

  group('TimeBucketing', () {
    test('groups by calendar day, not by elapsed hours', () {
      // 40 minutes away, but a different calendar day: tomorrow, not today.
      expect(
        TimeBucketing.of(DateTime(2026, 9, 4, 0, 30), now),
        TimeBucket.tomorrow,
      );
      // Ten hours earlier the same day is still today.
      expect(
        TimeBucketing.of(DateTime(2026, 9, 3, 4, 0), now),
        TimeBucket.today,
      );
    });

    test('anything before today is overdue', () {
      expect(
        TimeBucketing.of(DateTime(2026, 9, 2, 23, 59), now),
        TimeBucket.overdue,
      );
    });

    test('week and month boundaries', () {
      expect(TimeBucketing.of(DateTime(2026, 9, 10), now), TimeBucket.thisWeek);
      expect(
        TimeBucketing.of(DateTime(2026, 9, 11), now),
        TimeBucket.next30Days,
      );
      expect(
        TimeBucketing.of(DateTime(2026, 10, 3), now),
        TimeBucket.next30Days,
      );
      expect(TimeBucketing.of(DateTime(2026, 10, 4), now), TimeBucket.later);
    });

    test('only overdue and today count as urgent', () {
      expect(TimeBucket.overdue.isUrgent, isTrue);
      expect(TimeBucket.today.isUrgent, isTrue);
      expect(TimeBucket.tomorrow.isUrgent, isFalse);
    });
  });
}
