import 'package:flutter/material.dart';

/// What a piece of life actually is. The AI classifies into this set; the user
/// is never asked to pick a category (spec section 23).
///
/// The set is closed on the client but open in the database: unknown wire
/// values decode to [other] instead of throwing, so a server that learns a new
/// category does not crash older builds.
enum LifeItemType {
  appointment('appointment', Icons.event_available_rounded),
  bill('bill', Icons.receipt_long_rounded),
  subscription('subscription', Icons.autorenew_rounded),
  purchase('purchase', Icons.shopping_bag_rounded),
  returnDeadline('return', Icons.assignment_return_rounded),
  warranty('warranty', Icons.verified_user_rounded),
  travel('travel', Icons.flight_takeoff_rounded),
  document('document', Icons.description_rounded),
  insurance('insurance', Icons.shield_rounded),
  vehicle('vehicle', Icons.directions_car_rounded),
  home('home', Icons.home_rounded),
  event('event', Icons.celebration_rounded),
  delivery('delivery', Icons.local_shipping_rounded),
  reservation('reservation', Icons.restaurant_rounded),
  education('education', Icons.school_rounded),
  task('task', Icons.check_circle_outline_rounded),
  other('other', Icons.bookmark_border_rounded);

  const LifeItemType(this.wire, this.icon);

  final String wire;
  final IconData icon;

  static LifeItemType fromWire(String? value) => values.firstWhere(
    (t) => t.wire == value,
    orElse: () => LifeItemType.other,
  );

  /// Types where money is the point. Drives whether the amount is shown large.
  bool get isFinancial =>
      this == bill || this == subscription || this == purchase;

  /// Types whose deadline matters more than their start time.
  bool get isDeadlineDriven =>
      this == returnDeadline || this == warranty || this == document;
}
