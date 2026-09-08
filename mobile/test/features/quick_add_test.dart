import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/capture/domain/known_service.dart';
import 'package:relya/shared/domain/life_item_type.dart';
import 'package:relya/shared/domain/recurrence.dart';

void main() {
  group('the quick-add catalogue', () {
    test('is big enough to cover a normal life', () {
      // The point of it is the cold start: a new account has nothing in it,
      // and a screen that answers "what is coming up" needs something to say
      // before the first receipt happens to arrive.
      expect(
        knownServices.length + GenericService.values.length,
        greaterThan(100),
      );
    });

    test('has no duplicate names', () {
      final names = knownServices.map((s) => s.name.toLowerCase()).toList();
      expect(names.toSet().length, names.length);
    });

    test('never suggests a category that carries no money or date', () {
      for (final service in knownServices) {
        expect(
          service.type,
          isNot(LifeItemType.other),
          reason: '${service.name} would land in the catch-all category',
        );
      }
    });

    test('every generic service has a frequency worth defaulting to', () {
      for (final service in GenericService.values) {
        expect(
          service.frequency,
          anyOf(RecurrenceFrequency.monthly, RecurrenceFrequency.yearly),
          reason: '$service repeats on a schedule nobody would expect',
        );
      }
    });

    test('a monthly service opens on a date that is not already past', () {
      // The sheet starts from today plus one period, which is the only default
      // that is never a deadline in the past.
      final now = DateTime(2026, 1, 31, 9);
      const monthly = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      expect(monthly.next(now).isAfter(now), isTrue);
    });
  });
}
