import 'life_item_status.dart';
import 'life_item_type.dart';
import 'recurrence.dart';

/// The central object of the product: one thing in the user's life that has a
/// time, a cost, or a consequence.
///
/// Instants are UTC. [startTimezone] carries the IANA zone the event actually
/// happens in, because a flight booked in Lisbon still departs at 07:20 local
/// after the user has landed somewhere else.
class LifeItem {
  const LifeItem({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    this.captureId,
    this.description,
    this.startAt,
    this.startTimezone,
    this.endAt,
    this.deadlineAt,
    this.allDay = false,
    this.amount,
    this.currency,
    this.location,
    this.organization,
    this.entityId,
    this.confidence = 1.0,
    this.sourceLanguage,
    this.metadata = const {},
    this.snoozedUntil,
    this.recurrence,
    this.recurrenceUntil,
    this.seriesId,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? captureId;
  final LifeItemType type;
  final String title;
  final String? description;
  final LifeItemStatus status;

  final DateTime? startAt;
  final String? startTimezone;
  final DateTime? endAt;
  final DateTime? deadlineAt;
  final bool allDay;

  final num? amount;
  final String? currency;

  final String? location;
  final String? organization;

  /// Life Graph link. Null in V1 for most items.
  final String? entityId;

  final double confidence;
  final String? sourceLanguage;

  /// Type-specific fields that do not deserve a column: flight_number,
  /// warranty_months, tracking_url, and so on.
  final Map<String, dynamic> metadata;

  /// Set while the item is [LifeItemStatus.snoozed]. The moment it comes back
  /// on its own - no background job, the lists simply stop hiding it.
  final DateTime? snoozedUntil;

  /// Null for a one-off. When set, completing this occurrence writes the next.
  final RecurrenceRule? recurrence;

  /// The last moment the series may produce an occurrence. Null means forever.
  final DateTime? recurrenceUntil;

  /// Shared by every occurrence of the same repeating thing. The first
  /// occurrence carries its own id here.
  final String? seriesId;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// The instant this item should be sorted and bucketed by. A return deadline
  /// has no start time but very much has a moment that matters.
  DateTime? get primaryInstant => startAt ?? deadlineAt;

  bool get hasMoney => amount != null;

  bool get needsConfirmation => status == LifeItemStatus.pendingConfirmation;

  bool get isRecurring => recurrence != null;

  /// True while a snooze is still running. A snooze whose moment has passed is
  /// not hidden any more, which is what makes the item come back by itself.
  bool isHiddenAt(DateTime now) {
    final until = snoozedUntil;
    if (status != LifeItemStatus.snoozed || until == null) return false;
    return until.isAfter(now.toUtc());
  }

  LifeItem copyWith({
    String? id,
    Object? captureId = _sentinel,
    LifeItemType? type,
    String? title,
    Object? description = _sentinel,
    LifeItemStatus? status,
    Object? startAt = _sentinel,
    Object? startTimezone = _sentinel,
    Object? endAt = _sentinel,
    Object? deadlineAt = _sentinel,
    bool? allDay,
    Object? amount = _sentinel,
    Object? currency = _sentinel,
    Object? location = _sentinel,
    Object? organization = _sentinel,
    Object? entityId = _sentinel,
    double? confidence,
    Object? sourceLanguage = _sentinel,
    Map<String, dynamic>? metadata,
    Object? snoozedUntil = _sentinel,
    Object? recurrence = _sentinel,
    Object? recurrenceUntil = _sentinel,
    Object? seriesId = _sentinel,
    DateTime? createdAt,
    Object? updatedAt = _sentinel,
  }) {
    return LifeItem(
      id: id ?? this.id,
      captureId: captureId == _sentinel ? this.captureId : captureId as String?,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description == _sentinel
          ? this.description
          : description as String?,
      status: status ?? this.status,
      startAt: startAt == _sentinel ? this.startAt : startAt as DateTime?,
      startTimezone: startTimezone == _sentinel
          ? this.startTimezone
          : startTimezone as String?,
      endAt: endAt == _sentinel ? this.endAt : endAt as DateTime?,
      deadlineAt: deadlineAt == _sentinel
          ? this.deadlineAt
          : deadlineAt as DateTime?,
      allDay: allDay ?? this.allDay,
      amount: amount == _sentinel ? this.amount : amount as num?,
      currency: currency == _sentinel ? this.currency : currency as String?,
      location: location == _sentinel ? this.location : location as String?,
      organization: organization == _sentinel
          ? this.organization
          : organization as String?,
      entityId: entityId == _sentinel ? this.entityId : entityId as String?,
      confidence: confidence ?? this.confidence,
      sourceLanguage: sourceLanguage == _sentinel
          ? this.sourceLanguage
          : sourceLanguage as String?,
      metadata: metadata ?? this.metadata,
      snoozedUntil: snoozedUntil == _sentinel
          ? this.snoozedUntil
          : snoozedUntil as DateTime?,
      recurrence: recurrence == _sentinel
          ? this.recurrence
          : recurrence as RecurrenceRule?,
      recurrenceUntil: recurrenceUntil == _sentinel
          ? this.recurrenceUntil
          : recurrenceUntil as DateTime?,
      seriesId: seriesId == _sentinel ? this.seriesId : seriesId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _sentinel
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  factory LifeItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String key) {
      final raw = json[key];
      return raw == null ? null : DateTime.parse(raw as String).toUtc();
    }

    return LifeItem(
      id: json['id'] as String,
      captureId: json['capture_id'] as String?,
      type: LifeItemType.fromWire(json['type'] as String?),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: LifeItemStatus.fromWire(json['status'] as String?),
      startAt: parse('start_at'),
      startTimezone: json['start_tz'] as String?,
      endAt: parse('end_at'),
      deadlineAt: parse('deadline_at'),
      allDay: json['all_day'] as bool? ?? false,
      amount: json['amount'] as num?,
      currency: json['currency'] as String?,
      location: json['location'] as String?,
      organization: json['organization'] as String?,
      entityId: json['entity_id'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      sourceLanguage: json['source_language'] as String?,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      snoozedUntil: parse('snoozed_until'),
      recurrence: RecurrenceRule.tryParse(json['recurrence_rule'] as String?),
      recurrenceUntil: parse('recurrence_until'),
      seriesId: json['series_id'] as String?,
      createdAt: parse('created_at') ?? DateTime.now().toUtc(),
      updatedAt: parse('updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'capture_id': captureId,
    'type': type.wire,
    'title': title,
    'description': description,
    'status': status.wire,
    'start_at': startAt?.toIso8601String(),
    'start_tz': startTimezone,
    'end_at': endAt?.toIso8601String(),
    'deadline_at': deadlineAt?.toIso8601String(),
    'all_day': allDay,
    'amount': amount,
    'currency': currency,
    'location': location,
    'organization': organization,
    'entity_id': entityId,
    'confidence': confidence,
    'source_language': sourceLanguage,
    'metadata': metadata,
    'snoozed_until': snoozedUntil?.toIso8601String(),
    'recurrence_rule': recurrence?.toWire(),
    'recurrence_until': recurrenceUntil?.toIso8601String(),
    'series_id': seriesId,
  };

  @override
  bool operator ==(Object other) => other is LifeItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Distinguishes "not provided" from "explicitly set to null" in copyWith.
const Object _sentinel = Object();
