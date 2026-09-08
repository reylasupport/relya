/// One thing the user changed about what the model understood.
///
/// Field names are stable strings rather than an enum on purpose: these rows
/// are read as a corpus long after the release that wrote them, and a renamed
/// enum value would silently split the same mistake into two.
class ExtractionCorrection {
  const ExtractionCorrection({
    required this.captureId,
    required this.field,
    this.itemId,
    this.originalValue,
    this.correctedValue,
    this.note,
  });

  final String captureId;
  final String? itemId;

  /// 'title', 'date', or 'item' for an extraction the user threw away.
  final String field;

  final String? originalValue;
  final String? correctedValue;
  final String? note;

  Map<String, dynamic> toJson() => {
    'capture_id': captureId,
    if (itemId != null) 'item_id': itemId,
    'field': field,
    'original_value': originalValue,
    'corrected_value': correctedValue,
    if (note != null) 'note': note,
  };
}

/// Every correction the user makes, kept because it is the only honest measure
/// of how good the extraction actually is - and the seed corpus for making it
/// better. The table has existed since the first migration; nothing wrote to
/// it, so the confirmation screen was throwing this signal away.
abstract interface class FeedbackRepository {
  /// Never throws. Losing a correction must not cost the user the save it
  /// arrived with.
  Future<void> record(List<ExtractionCorrection> corrections);
}
