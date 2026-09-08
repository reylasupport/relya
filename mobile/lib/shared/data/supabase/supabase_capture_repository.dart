import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../../services/supabase/supabase_service.dart';
import '../../domain/capture.dart';
import '../../domain/extraction_result.dart';
import '../repositories/capture_repository.dart';

/// The real capture pipeline.
///
/// Order matters and is deliberate: hash first (so the same screenshot is never
/// paid for twice), then on-device OCR, then upload the original only if we
/// still need it, then ask the server to understand it. Each step that can be
/// skipped saves money and keeps one more byte off the network.
class SupabaseCaptureRepository implements CaptureRepository {
  SupabaseCaptureRepository(this._supabase, this._ocr);

  static const String _table = 'captures';
  static const String _bucket = 'captures';
  static const String _analyseFunction = 'analyze-capture';

  final SupabaseService _supabase;
  final OcrService _ocr;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Capture>> inbox() async {
    final rows = await _supabase
        .table(_table)
        .select()
        .not('status', 'in', '("archived")')
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map((row) => Capture.fromJson((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Capture?> byId(String id) async {
    final row = await _supabase
        .table(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Capture.fromJson(row);
  }

  @override
  Future<Capture> enqueue(CaptureDraft draft) async {
    final userId = _supabase.requireUserId;

    String? hash;
    String? ocrText;
    String? storagePath;

    if (draft.bytes != null || draft.filePath != null) {
      // On the web there is no file system to hand to ML Kit, so the draft
      // carries the bytes instead. Everything downstream is the same, and the
      // analyse function already reads pixels when no text came with them.
      final bytes = draft.bytes ?? await File(draft.filePath!).readAsBytes();
      hash = sha256.convert(bytes).toString();

      final existing = await _findByHash(hash);
      if (existing != null) {
        AppLogger.info('Capture already analysed, reusing it');
        return existing;
      }

      final onDeviceFile = kIsWeb || draft.filePath == null
          ? null
          : File(draft.filePath!);

      if (draft.kind == CaptureKind.image && onDeviceFile != null) {
        final result = await _ocr.recognise(onDeviceFile);
        if (result != null && result.isUsable) ocrText = result.text;
      }

      // The original is uploaded when the model still needs the pixels, or
      // when the file is a PDF we cannot read on the device.
      if (ocrText == null || draft.kind == CaptureKind.pdf) {
        storagePath = await _upload(
          userId,
          bytes,
          draft.title ?? 'capture',
          draft.mimeType,
        );
      }
    } else if (draft.text != null) {
      hash = sha256.convert(utf8.encode(draft.text!)).toString();
      final existing = await _findByHash(hash);
      if (existing != null) return existing;
    }

    final row = await _supabase
        .table(_table)
        .insert({
          'user_id': userId,
          'source': draft.source.wire,
          'kind': draft.kind.wire,
          'status': CaptureStatus.queued.wire,
          'title': draft.title,
          'raw_text': draft.text,
          'source_url': draft.url,
          'storage_path': storagePath,
          'content_hash': hash,
          'ocr_text': ocrText,
        })
        .select()
        .single();

    _changes.add(null);
    return Capture.fromJson(row);
  }

  Future<Capture?> _findByHash(String hash) async {
    final row = await _supabase
        .table(_table)
        .select()
        .eq('content_hash', hash)
        .not('status', 'in', '("failed")')
        .limit(1)
        .maybeSingle();
    return row == null ? null : Capture.fromJson(row);
  }

  /// Uploads bytes rather than a File, because a browser has no File to give.
  Future<String> _upload(
    String userId,
    Uint8List bytes,
    String name,
    String? mimeType,
  ) async {
    // Anything a picker can produce becomes a storage key here, so strip it
    // down to what an object path can hold rather than trusting the name.
    final safe = name
        .replaceAll(RegExp('[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp('_+'), '_');
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}-$safe';
    await _supabase.client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return path;
  }

  @override
  Future<AnalysisResult> analyse(String captureId) async {
    await _supabase
        .table(_table)
        .update({'status': CaptureStatus.processing.wire})
        .eq('id', captureId);
    _changes.add(null);

    try {
      final data = await _supabase.invoke<Map<String, dynamic>>(
        _analyseFunction,
        body: {'capture_id': captureId},
      );
      final analysis = AnalysisResult.fromJson(data);
      _changes.add(null);
      return analysis;
    } on FunctionException catch (error, stack) {
      // The monthly allowance is not a broken capture. The file is fine, and
      // the same request succeeds the moment the user upgrades or the period
      // rolls over, so it goes back to the queue rather than to failed - and
      // the caller gets an error it can turn into an offer instead of an
      // apology.
      if (error.status == 429) {
        AppLogger.warn('Capture quota reached');
        await _supabase
            .table(_table)
            .update({'status': CaptureStatus.queued.wire})
            .eq('id', captureId);
        _changes.add(null);
        throw QuotaExceeded('Monthly capture limit reached', cause: error);
      }
      await _markFailed(captureId, error, stack);
      throw ExtractionFailure('Could not analyse this capture', cause: error);
    } on Object catch (error, stack) {
      await _markFailed(captureId, error, stack);
      throw ExtractionFailure('Could not analyse this capture', cause: error);
    }
  }

  Future<void> _markFailed(
    String captureId,
    Object error,
    StackTrace stack,
  ) async {
    AppLogger.error('Analysis failed', error, stack);
    await _supabase
        .table(_table)
        .update({
          'status': CaptureStatus.failed.wire,
          'error_message': error.toString(),
        })
        .eq('id', captureId);
    _changes.add(null);
  }

  @override
  Future<AnalysisResult?> cachedAnalysis(String captureId) async {
    final row = await _supabase
        .table('capture_analyses')
        .select()
        .eq('capture_id', captureId)
        .maybeSingle();
    if (row == null) return null;
    return AnalysisResult.fromJson({
      'capture_id': captureId,
      ...(row['payload'] as Map).cast<String, dynamic>(),
    });
  }

  @override
  Future<void> markCompleted(String captureId, {required int itemCount}) async {
    await _supabase
        .table(_table)
        .update({
          'status': CaptureStatus.completed.wire,
          'item_count': itemCount,
          'processed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', captureId);
    _changes.add(null);
  }

  @override
  Future<void> archive(String captureId) async {
    await _supabase
        .table(_table)
        .update({'status': CaptureStatus.archived.wire})
        .eq('id', captureId);
    _changes.add(null);
  }

  @override
  Future<void> delete(String captureId) async {
    final capture = await byId(captureId);
    final path = capture?.storagePath;
    if (path != null) {
      await _supabase.client.storage.from(_bucket).remove([path]);
    }
    await _supabase.table(_table).delete().eq('id', captureId);
    _changes.add(null);
  }
}
