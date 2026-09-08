import 'package:intl/intl.dart';

/// Currency formatting driven by the display locale, not by the currency.
///
/// The same 149.99 EUR reads as "149,99 EUR" for pt-PT and "EUR149.99" for
/// en-US, which is what each user expects. Amounts are stored as decimals in
/// the database and only ever formatted at the edge.
abstract final class AppMoneyFormat {
  const AppMoneyFormat._();

  static String format(num amount, String? currencyCode, String locale) {
    final code = (currencyCode ?? 'EUR').toUpperCase();
    final format = NumberFormat.simpleCurrency(locale: locale, name: code);
    return format.format(amount);
  }

  /// Compact form for dense lists, e.g. a monthly subscription total.
  static String compact(num amount, String? currencyCode, String locale) {
    final code = (currencyCode ?? 'EUR').toUpperCase();
    return NumberFormat.compactSimpleCurrency(
      locale: locale,
      name: code,
    ).format(amount);
  }

  static String symbolFor(String? currencyCode, String locale) {
    final code = (currencyCode ?? 'EUR').toUpperCase();
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: code,
    ).currencySymbol;
  }
}
