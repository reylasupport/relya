import 'package:flutter/widgets.dart';

/// Corner radii. Three steps only - controls, cards, sheets.
abstract final class AppRadii {
  const AppRadii._();

  static const double control = 12;
  static const double card = 16;
  static const double sheet = 28;
  static const double pill = 999;

  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetRadius = BorderRadius.only(
    topLeft: Radius.circular(sheet),
    topRight: Radius.circular(sheet),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
