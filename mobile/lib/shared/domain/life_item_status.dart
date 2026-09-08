/// Lifecycle of a single life item.
enum LifeItemStatus {
  /// Extracted but not yet accepted by the user. Never acted on.
  pendingConfirmation('pending_confirmation'),
  active('active'),
  done('done'),
  snoozed('snoozed'),
  archived('archived');

  const LifeItemStatus(this.wire);

  final String wire;

  static LifeItemStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => LifeItemStatus.active,
  );

  bool get isVisibleInTimeline =>
      this == active || this == snoozed || this == pendingConfirmation;
}
