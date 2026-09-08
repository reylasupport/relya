import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:relya/core/formatting/app_date_format.dart';
import 'package:relya/core/formatting/app_money_format.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('regional formatting', () {
    final moment = DateTime(2026, 9, 12, 15, 30);

    test('dates follow the locale, never a hardcoded pattern', () {
      expect(AppDateFormat.dayMonthYear(moment, 'pt_PT'), '12/09/2026');
      expect(AppDateFormat.dayMonthYear(moment, 'en_US'), '9/12/2026');
    });

    test('24-hour and 12-hour clocks come from the locale', () {
      expect(AppDateFormat.time(moment, 'pt_PT'), '15:30');
      expect(AppDateFormat.time(moment, 'en_US'), contains('3:30'));
      expect(AppDateFormat.time(moment, 'en_US'), contains('PM'));
    });

    test('currency is formatted for the reader, not for the currency', () {
      final pt = AppMoneyFormat.format(149.99, 'EUR', 'pt_PT');
      expect(pt, contains('149,99'));

      final us = AppMoneyFormat.format(149.99, 'USD', 'en_US');
      expect(us, contains('149.99'));
    });

    test('a same-day range renders as one line', () {
      final start = DateTime(2026, 9, 12, 14);
      final end = DateTime(2026, 9, 12, 18);
      expect(AppDateFormat.range(start, end, 'pt_PT'), '14:00 - 18:00');
    });

    test('calendar day difference ignores the clock', () {
      expect(
        AppDateFormat.calendarDaysBetween(
          DateTime(2026, 9, 3, 23, 59),
          DateTime(2026, 9, 4, 0, 1),
        ),
        1,
      );
    });
  });
}
