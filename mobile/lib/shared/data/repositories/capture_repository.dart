import 'dart:typed_data';

import '../../domain/capture.dart';
import '../../domain/extraction_result.dart';

/// A capture in flight, before it has been persisted anywhere.
class CaptureDraft {
  const CaptureDraft({
    required this.source,
    required this.kind,
    this.text,
    this.url,
    this.filePath,
    this.bytes,
    this.mimeType,
    this.title,
  });

  final CaptureSource source;
  final CaptureKind kind;
  final String? text;
  final String? url;
  final String? filePath;
  final Uint8List? bytes;
  final String? mimeType;
  final String? title;
}

abstract interface class CaptureRepository {
  Future<List<Capture>> inbox();

  Future<Capture?> byId(String id);

  /// Records the capture locally and returns immediately. Analysis is a
  /// separate step so a capture taken offline is never lost.
  Future<Capture> enqueue(CaptureDraft draft);

  /// Runs the pipeline: on-device OCR, then the analyze-capture function.
  /// Throws [ExtractionFailure] rather than returning an empty result when the
  /// model output could not be trusted.
  Future<AnalysisResult> analyse(String captureId);

  Future<AnalysisResult?> cachedAnalysis(String captureId);

  Future<void> markCompleted(String captureId, {required int itemCount});

  Future<void> archive(String captureId);

  Future<void> delete(String captureId);

  Stream<void> get changes;
}
