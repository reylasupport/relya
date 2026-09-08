import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/formatting/week_start.dart';

void main() {
  group('week start', () {
    test('Monday is the default, because most of the world starts there', () {
      expect(WeekStart.indexFor('PT'), 1);
      expect(WeekStart.indexFor('GB'), 1);
      expect(WeekStart.indexFor('FR'), 1);
      expect(WeekStart.indexFor('DE'), 1);
      // An unknown or missing region must not crash a calendar.
      expect(WeekStart.indexFor(null), 1);
      expect(WeekStart.indexFor(''), 1);
      expect(WeekStart.indexFor('ZZ'), 1);
    });

    test('Sunday and Saturday regions are honoured', () {
      expect(WeekStart.indexFor('US'), 0);
      expect(WeekStart.indexFor('BR'), 0);
      expect(WeekStart.indexFor('JP'), 0);
      expect(WeekStart.indexFor('SA'), 6);
      expect(WeekStart.indexFor('EG'), 6);
    });

    test('reads the region out of either tag spelling', () {
      expect(WeekStart.forLocaleTag('pt_PT'), 1);
      expect(WeekStart.forLocaleTag('pt-BR'), 0);
      expect(WeekStart.forLocaleTag('en_US'), 0);
      // No region at all: fall back rather than guess from the language.
      expect(WeekStart.forLocaleTag('pt'), 1);
    });

    test('is case insensitive', () {
      expect(WeekStart.indexFor('us'), 0);
      expect(WeekStart.indexFor('pt'), 1);
    });
  });
}
