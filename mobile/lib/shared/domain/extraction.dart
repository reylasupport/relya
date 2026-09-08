/// How careful we must be with the content (spec sections 29 and 30). Drives
/// retention defaults and whether the original file is kept at all.
enum Sensitivity {
  normal('normal'),
  personal('personal'),
  sensitive('sensitive');

  const Sensitivity(this.wire);

  final String wire;

  static Sensitivity fromWire(String? value) => values.firstWhere(
    (s) => s.wire == value,
    orElse: () => Sensitivity.normal,
  );
}

enum ExtractedDateKind {
  start('start'),
  end('end'),
  deadline('deadline'),
  purchase('purchase'),
  renewal('renewal'),
  expiry('expiry'),
  other('other');

  const ExtractedDateKind(this.wire);

  final String wire;

  static ExtractedDateKind fromWire(String? value) => values.firstWhere(
    (k) => k.wire == value,
    orElse: () => ExtractedDateKind.other,
  );
}

/// A date as the model found it, plus what we resolved it to.
///
/// [raw] is kept verbatim so the confirmation screen can show the user the
/// exact text it came from. [ambiguous] is set when the written form could mean
/// two different days (spec section 21) and the locale did not settle it: the
/// UI must ask rather than guess.
class ExtractedDate {
  const ExtractedDate({
    required this.raw,
    required this.kind,
    this.resolved,
    this.timezone,
    this.hasTime = false,
    this.ambiguous = false,
    this.alternative,
    this.confidence = 1.0,
  });

  final String raw;
  final ExtractedDateKind kind;
  final DateTime? resolved;
  final String? timezone;
  final bool hasTime;
  final bool ambiguous;

  /// The other reading of an ambiguous date, offered as a one-tap correction.
  final DateTime? alternative;
  final double confidence;

  factory ExtractedDate.fromJson(Map<String, dynamic> json) => ExtractedDate(
    raw: json['raw'] as String? ?? '',
    kind: ExtractedDateKind.fromWire(json['kind'] as String?),
    resolved: json['resolved'] == null
        ? null
        : DateTime.parse(json['resolved'] as String).toUtc(),
    timezone: json['timezone'] as String?,
    hasTime: json['has_time'] as bool? ?? false,
    ambiguous: json['ambiguous'] as bool? ?? false,
    alternative: json['alternative'] == null
        ? null
        : DateTime.parse(json['alternative'] as String).toUtc(),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'raw': raw,
    'kind': kind.wire,
    'resolved': resolved?.toIso8601String(),
    'timezone': timezone,
    'has_time': hasTime,
    'ambiguous': ambiguous,
    'alternative': alternative?.toIso8601String(),
    'confidence': confidence,
  };
}

/// A reminder the app proposes. Pre-ticked ones are the ones a reasonable
/// person would want; the user still taps once to accept (spec section 53).
class SuggestedReminder {
  const SuggestedReminder({
    required this.label,
    required this.leadSeconds,
    required this.anchor,
    this.enabledByDefault = true,
  });

  final String label;
  final int leadSeconds;
  final String anchor;
  final bool enabledByDefault;

  Duration get leadTime => Duration(seconds: leadSeconds);

  factory SuggestedReminder.fromJson(Map<String, dynamic> json) =>
      SuggestedReminder(
        label: json['label'] as String? ?? '',
        leadSeconds: json['lead_seconds'] as int? ?? 0,
        anchor: json['anchor'] as String? ?? 'start',
        enabledByDefault: json['default_on'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'lead_seconds': leadSeconds,
    'anchor': anchor,
    'default_on': enabledByDefault,
  };
}

/// Non-reminder actions offered on the confirmation screen. The set is closed:
/// nothing that comes out of a document can invent a new action, and nothing
/// here is destructive or spends money (spec section 52).
enum SuggestedActionType {
  addToCalendar('add_to_calendar'),
  saveDocument('save_document'),
  trackPayment('track_payment'),
  trackSubscription('track_subscription'),
  trackWarranty('track_warranty'),
  trackDelivery('track_delivery'),
  addTrip('add_trip'),
  unknown('unknown');

  const SuggestedActionType(this.wire);

  final String wire;

  static SuggestedActionType fromWire(String? value) => values.firstWhere(
    (a) => a.wire == value,
    orElse: () => SuggestedActionType.unknown,
  );
}

class SuggestedAction {
  const SuggestedAction({
    required this.type,
    required this.label,
    this.enabledByDefault = true,
  });

  final SuggestedActionType type;
  final String label;
  final bool enabledByDefault;

  factory SuggestedAction.fromJson(Map<String, dynamic> json) =>
      SuggestedAction(
        type: SuggestedActionType.fromWire(json['type'] as String?),
        label: json['label'] as String? ?? '',
        enabledByDefault: json['default_on'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'type': type.wire,
    'label': label,
    'default_on': enabledByDefault,
  };
}
