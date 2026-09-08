import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../../domain/capture.dart';
import '../../domain/extraction_result.dart';
import '../repositories/capture_repository.dart';
import 'demo_analysis.dart';
import 'mock_fixtures.dart';

/// In-memory capture pipeline. Simulates the real timings so the progressive
/// loader, the Inbox states and the confirmation screen can all be exercised
/// without a backend.
class MockCaptureRepository implements CaptureRepository {
  /// Copies the seed list rather than holding on to it. Callers pass
  /// `const []` to get an empty inbox, and inserting into a const list throws
  /// - which showed up as an enqueue that silently did nothing.
  MockCaptureRepository({DateTime? now, List<Capture>? captures})
    : _captures = [
        ...(captures ?? MockFixtures.captures(now ?? DateTime.now())),
      ];

  final List<Capture> _captures;
  final Map<String, AnalysisResult> _analyses = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  int _sequence = 0;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Capture>> inbox() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _captures.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Capture?> byId(String id) async {
    for (final capture in _captures) {
      if (capture.id == id) return capture;
    }
    return null;
  }

  @override
  Future<Capture> enqueue(CaptureDraft draft) async {
    final capture = Capture(
      id: 'cap-local-${++_sequence}',
      source: draft.source,
      kind: draft.kind,
      status: CaptureStatus.queued,
      title: draft.title ?? _defaultTitle(draft.kind),
      rawText: draft.text,
      sourceUrl: draft.url,
      localFilePath: draft.filePath,
      createdAt: DateTime.now().toUtc(),
    );
    _captures.insert(0, capture);
    _changes.add(null);
    return capture;
  }

  static String _defaultTitle(CaptureKind kind) => switch (kind) {
    CaptureKind.image => 'Screenshot',
    CaptureKind.pdf => 'Document',
    CaptureKind.text => 'Text',
    CaptureKind.url => 'Link',
  };

  @override
  Future<AnalysisResult> analyse(String captureId) async {
    _replace(captureId, (c) => c.copyWith(status: CaptureStatus.processing));

    await Future<void>.delayed(const Duration(milliseconds: 2200));

    final capture = await byId(captureId);
    if (capture == null) {
      throw const ExtractionFailure('Capture not found');
    }

    final result = DemoAnalysis.build(DateTime.now());
    final analysis = AnalysisResult(
      captureId: captureId,
      items: result.items,
      detectedLanguage: result.detectedLanguage,
      modelUsed: result.modelUsed,
      processingMillis: result.processingMillis,
    );
    _analyses[captureId] = analysis;

    _replace(
      captureId,
      (c) => c.copyWith(
        status: CaptureStatus.needsConfirmation,
        itemCount: analysis.items.length,
        processedAt: DateTime.now().toUtc(),
        detectedLanguage: analysis.detectedLanguage,
      ),
    );
    return analysis;
  }

  @override
  Future<AnalysisResult?> cachedAnalysis(String captureId) async {
    return _analyses[captureId] ??
        (captureId == 'cap-pending'
            ? DemoAnalysis.build(DateTime.now())
            : null);
  }

  @override
  Future<void> markCompleted(String captureId, {required int itemCount}) async {
    _replace(
      captureId,
      (c) => c.copyWith(status: CaptureStatus.completed, itemCount: itemCount),
    );
  }

  @override
  Future<void> archive(String captureId) async {
    _replace(captureId, (c) => c.copyWith(status: CaptureStatus.archived));
  }

  @override
  Future<void> delete(String captureId) async {
    _captures.removeWhere((c) => c.id == captureId);
    _changes.add(null);
  }

  void _replace(String id, Capture Function(Capture) transform) {
    final index = _captures.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _captures[index] = transform(_captures[index]);
    _changes.add(null);
  }
}
