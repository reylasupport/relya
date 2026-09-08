/// What the reminder is measured from.
enum ReminderAnchor {
  start('start'),
  deadline('deadline'),
  absolute('absolute');

  const ReminderAnchor(this.wire);

  final String wire;

  static ReminderAnchor fromWire(String? value) => values.firstWhere(
    (a) => a.wire == value,
    orElse: () => ReminderAnchor.start,
  );
}

enum ReminderStatus {
  scheduled('scheduled'),
  delivered('delivered'),
  dismissed('dismissed'),
  cancelled('cancelled');

  const ReminderStatus(this.wire);

  final String wire;

  static ReminderStatus fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => ReminderStatus.scheduled,
  );
}

/// A scheduled nudge.
///
/// [fireAt] is UTC and [timezone] is the IANA zone it was computed in. Both are
/// stored because a user who flies to Tokyo must still be reminded at 09:00
/// wherever the event is, not at 09:00 Lisbon time. When the device zone
/// changes, reminders anchored to a local wall-clock time are recomputed.
class Reminder {
  const Reminder({
    required this.id,
    required this.itemId,
    required this.fireAt,
    required this.timezone,
    required this.anchor,
    required this.status,
    this.leadTime,
    this.label,
    this.localNotificationId,
  });

  final String id;
  final String itemId;
  final DateTime fireAt;
  final String timezone;
  final ReminderAnchor anchor;

  /// How far before the anchor this fires. Null for absolute reminders.
  final Duration? leadTime;

  /// Human description used in the UI and in the notification body,
  /// e.g. "24 hours before".
  final String? label;

  final ReminderStatus status;

  /// Identifier handed to flutter_local_notifications, so it can be cancelled.
  final int? localNotificationId;

  bool get isPending =>
      status == ReminderStatus.scheduled &&
      fireAt.isAfter(DateTime.now().toUtc());

  Reminder copyWith({
    DateTime? fireAt,
    String? timezone,
    ReminderStatus? status,
    int? localNotificationId,
  }) {
    return Reminder(
      id: id,
      itemId: itemId,
      fireAt: fireAt ?? this.fireAt,
      timezone: timezone ?? this.timezone,
      anchor: anchor,
      leadTime: leadTime,
      label: label,
      status: status ?? this.status,
      localNotificationId: localNotificationId ?? this.localNotificationId,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    itemId: json['item_id'] as String,
    fireAt: DateTime.parse(json['fire_at'] as String).toUtc(),
    timezone: json['timezone'] as String? ?? 'UTC',
    anchor: ReminderAnchor.fromWire(json['anchor'] as String?),
    leadTime: json['lead_seconds'] == null
        ? null
        : Duration(seconds: json['lead_seconds'] as int),
    label: json['label'] as String?,
    status: ReminderStatus.fromWire(json['status'] as String?),
    localNotificationId: json['local_notification_id'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'fire_at': fireAt.toIso8601String(),
    'timezone': timezone,
    'anchor': anchor.wire,
    'lead_seconds': leadTime?.inSeconds,
    'label': label,
    'status': status.wire,
    'local_notification_id': localNotificationId,
  };

  @override
  bool operator ==(Object other) => other is Reminder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
