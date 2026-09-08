import '../../core/ids/ids.dart';
import 'extraction.dart';
import 'life_item.dart';
import 'life_item_status.dart';
import 'life_item_type.dart';
import 'recurrence.dart';

/// One understood thing, straight out of the analysis pipeline and validated
/// against the JSON schema in spec section 19.
///
/// This is deliberately not a LifeItem: nothing is written to the user life
/// until it is confirmed. [toLifeItem] is the conversion the confirmation
/// screen performs on accept.
class ExtractionResult {
  const ExtractionResult({
    required this.id,
    required this.type,
    required this.title,
    required this.confidence,
    this.summary,
    this.sourceLanguage,
    this.actionRequired = false,
    this.dates = const [],
    this.amount,
    this.currency,
    this.location,
    this.organization,
    this.people = const [],
    this.referenceNumbers = const [],
    this.relatedEntityHint,
    this.recurrence,
    this.suggestedReminders = const [],
    this.suggestedActions = const [],
    this.sensitivity = Sensitivity.normal,
    this.metadata = const {},
    this.unresolvedNote,
  });

  final String id;
  final LifeItemType type;
  final String title;
  final String? summary;

  /// BCP-47 tag of the document itself, independent of the interface language
  /// (spec section 46).
  final String? sourceLanguage;

  final double confidence;
  final bool actionRequired;

  final List<ExtractedDate> dates;

  final num? amount;
  final String? currency;
  final String? location;
  final String? organization;
  final List<String> people;
  final List<String> referenceNumbers;

  /// A hint such as a licence plate or a serial number, used later by the Life
  /// Graph to notice that two documents describe the same thing. Stored in V1,
  /// acted on in V2.
  final String? relatedEntityHint;

  /// RRULE-like string when the item repeats, e.g. a monthly subscription.
  final String? recurrence;

  final List<SuggestedReminder> suggestedReminders;
  final List<SuggestedAction> suggestedActions;
  final Sensitivity sensitivity;
  final Map<String, dynamic> metadata;

  /// Set when the model could not confirm something it would otherwise have
  /// asserted. Shown verbatim rather than hidden (spec section 5).
  final String? unresolvedNote;

  ExtractedDate? dateOfKind(ExtractedDateKind kind) {
    for (final date in dates) {
      if (date.kind == kind) return date;
    }
    return null;
  }

  DateTime? get startAt => dateOfKind(ExtractedDateKind.start)?.resolved;

  DateTime? get endAt => dateOfKind(ExtractedDateKind.end)?.resolved;

  DateTime? get deadlineAt =>
      dateOfKind(ExtractedDateKind.deadline)?.resolved ??
      dateOfKind(ExtractedDateKind.expiry)?.resolved ??
      dateOfKind(ExtractedDateKind.renewal)?.resolved;

  bool get hasAmbiguousDate => dates.any((d) => d.ambiguous);

  bool get needsUserAttention =>
      confidence < 0.85 || hasAmbiguousDate || unresolvedNote != null;

  LifeItem toLifeItem({
    required String captureId,
    required DateTime now,
    String? timezone,
  }) {
    final start = dateOfKind(ExtractedDateKind.start);
    return LifeItem(
      // Not [id]: that identifies the extraction inside the analysis payload
      // and is not a UUID, which the life_items primary key requires.
      id: newId(),
      captureId: captureId,
      type: type,
      title: title,
      description: summary,
      status: LifeItemStatus.active,
      startAt: start?.resolved,
      startTimezone: start?.timezone ?? timezone,
      endAt: endAt,
      deadlineAt: deadlineAt,
      allDay: start != null && !start.hasTime,
      amount: amount,
      currency: currency,
      location: location,
      organization: organization,
      confidence: confidence,
      sourceLanguage: sourceLanguage,
      // The model returns a hint in whatever words the document used; a hint
      // we can read becomes a real rule, and the rest stays in metadata.
      recurrence: RecurrenceRule.tryParse(recurrence),
      metadata: {
        ...metadata,
        if (people.isNotEmpty) 'people': people,
        if (referenceNumbers.isNotEmpty) 'reference_numbers': referenceNumbers,
        if (recurrence != null) 'recurrence': recurrence,
        if (relatedEntityHint != null) 'entity_hint': relatedEntityHint,
        'sensitivity': sensitivity.wire,
      },
      createdAt: now,
    );
  }

  ExtractionResult copyWith({
    LifeItemType? type,
    String? title,
    String? summary,
    List<ExtractedDate>? dates,
    num? amount,
    String? currency,
    String? location,
    List<SuggestedReminder>? suggestedReminders,
    List<SuggestedAction>? suggestedActions,
  }) {
    return ExtractionResult(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      sourceLanguage: sourceLanguage,
      confidence: confidence,
      actionRequired: actionRequired,
      dates: dates ?? this.dates,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      organization: organization,
      people: people,
      referenceNumbers: referenceNumbers,
      relatedEntityHint: relatedEntityHint,
      recurrence: recurrence,
      suggestedReminders: suggestedReminders ?? this.suggestedReminders,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      sensitivity: sensitivity,
      metadata: metadata,
      unresolvedNote: unresolvedNote,
    );
  }

  factory ExtractionResult.fromJson(Map<String, dynamic> json) =>
      ExtractionResult(
        id: json['id'] as String? ?? '',
        type: LifeItemType.fromWire(json['category'] as String?),
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String?,
        sourceLanguage: json['source_language'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        actionRequired: json['action_required'] as bool? ?? false,
        dates:
            (json['dates'] as List?)
                ?.map((e) => ExtractedDate.fromJson((e as Map).cast()))
                .toList() ??
            const [],
        amount: json['amount'] as num?,
        currency: json['currency'] as String?,
        location: json['location'] as String?,
        organization: json['organization'] as String?,
        people: (json['people'] as List?)?.cast<String>() ?? const [],
        referenceNumbers:
            (json['reference_numbers'] as List?)?.cast<String>() ?? const [],
        relatedEntityHint: json['related_entity'] as String?,
        recurrence: json['recurrence'] as String?,
        suggestedReminders:
            (json['suggested_reminders'] as List?)
                ?.map((e) => SuggestedReminder.fromJson((e as Map).cast()))
                .toList() ??
            const [],
        suggestedActions:
            (json['suggested_actions'] as List?)
                ?.map((e) => SuggestedAction.fromJson((e as Map).cast()))
                .toList() ??
            const [],
        sensitivity: Sensitivity.fromWire(json['sensitivity'] as String?),
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
        unresolvedNote: json['unresolved_note'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': type.wire,
    'title': title,
    'summary': summary,
    'source_language': sourceLanguage,
    'confidence': confidence,
    'action_required': actionRequired,
    'dates': dates.map((d) => d.toJson()).toList(),
    'amount': amount,
    'currency': currency,
    'location': location,
    'organization': organization,
    'people': people,
    'reference_numbers': referenceNumbers,
    'related_entity': relatedEntityHint,
    'recurrence': recurrence,
    'suggested_reminders': suggestedReminders.map((r) => r.toJson()).toList(),
    'suggested_actions': suggestedActions.map((a) => a.toJson()).toList(),
    'sensitivity': sensitivity.wire,
    'metadata': metadata,
    'unresolved_note': unresolvedNote,
  };
}

/// Everything one capture produced. A single screenshot can legitimately
/// contain three important things, and the confirmation screen shows them all.
class AnalysisResult {
  const AnalysisResult({
    required this.captureId,
    required this.items,
    this.detectedLanguage,
    this.modelUsed,
    this.processingMillis,
  });

  final String captureId;
  final List<ExtractionResult> items;
  final String? detectedLanguage;
  final String? modelUsed;
  final int? processingMillis;

  bool get isEmpty => items.isEmpty;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    captureId: json['capture_id'] as String? ?? '',
    items:
        (json['items'] as List?)
            ?.map((e) => ExtractionResult.fromJson((e as Map).cast()))
            .toList() ??
        const [],
    detectedLanguage: json['detected_language'] as String?,
    modelUsed: json['model'] as String?,
    processingMillis: json['processing_ms'] as int?,
  );
}
