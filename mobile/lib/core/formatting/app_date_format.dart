import 'package:intl/intl.dart';

/// Locale-aware date and time formatting.
///
/// Never assume the American format. Every method takes the locale explicitly
/// so a Portuguese user sees 12/09/2026 15:30 and an American user sees
/// 09/12/2026 3:30 PM, driven entirely by ICU data rather than by our guesses.
abstract final class AppDateFormat {
  const AppDateFormat._();

  static String time(DateTime local, String locale) =>
      DateFormat.jm(locale).format(local);

  static String dayMonth(DateTime local, String locale) =>
      DateFormat.MMMd(locale).format(local);

  static String dayMonthYear(DateTime local, String locale) =>
      DateFormat.yMd(locale).format(local);

  static String weekday(DateTime local, String locale) =>
      DateFormat.EEEE(locale).format(local);

  static String weekdayShort(DateTime local, String locale) =>
      DateFormat.E(locale).format(local);

  /// "Tuesday, 3 September". The greeting line: weekday and day, no year,
  /// because nobody needs telling which year today is.
  static String weekdayAndDay(DateTime local, String locale) =>
      DateFormat.MMMMEEEEd(locale).format(local);

  /// "3 September". The agenda heading, where the weekday is already on the
  /// same line and an abbreviated month would look clipped next to it.
  static String dayAndMonthName(DateTime local, String locale) =>
      DateFormat.MMMMd(locale).format(local);

  /// "Sep". The band across the top of the little calendar block.
  static String monthShort(DateTime local, String locale) =>
      DateFormat.MMM(locale).format(local);

  static String fullDate(DateTime local, String locale) =>
      DateFormat.yMMMMd(locale).format(local);

  static String dateAndTime(DateTime local, String locale) =>
      '${DateFormat.MMMd(locale).format(local)} '
      '${DateFormat.jm(locale).format(local)}';

  /// Range on the same day renders as "14:00 - 18:00"; across days it falls
  /// back to two full stamps. Delivery windows are the common case.
  static String range(DateTime start, DateTime? end, String locale) {
    if (end == null) return time(start, locale);
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) return '${time(start, locale)} - ${time(end, locale)}';
    return '${dateAndTime(start, locale)} - ${dateAndTime(end, locale)}';
  }

  /// Whole calendar days between two local dates, ignoring the clock.
  /// "Tomorrow at 00:30" is 1 day away even if it is 40 minutes from now.
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}
