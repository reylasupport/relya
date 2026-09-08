import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/outbox/outbox_providers.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/data/repositories/capture_repository.dart';
import '../../../shared/domain/capture.dart';

/// What happened to an attempted capture.
///
/// A nullable Capture could not tell "the user backed out of the picker" apart
/// from "there was no network", and those need different words on screen -
/// silence for one, reassurance for the other.
enum CaptureOutcome { created, parked, cancelled }

class CaptureAttempt {
  const CaptureAttempt._(this.outcome, this.capture);

  const CaptureAttempt.created(Capture value)
    : this._(CaptureOutcome.created, value);

  const CaptureAttempt.parked() : this._(CaptureOutcome.parked, null);

  const CaptureAttempt.cancelled() : this._(CaptureOutcome.cancelled, null);

  final CaptureOutcome outcome;

  /// Only set when [outcome] is created.
  final Capture? capture;
}

/// Turns a raw input into a queued capture and hands back its id so the caller
/// can push the confirmation screen. Everything else in the pipeline is the
/// repository job.
class CaptureController {
  CaptureController(this._ref);

  final Ref _ref;

  CaptureRepository get _repository => _ref.read(captureRepositoryProvider);

  /// Sends a draft, and parks it if there is no network.
  ///
  /// Returns null when the capture went to the outbox instead of the server.
  /// The caller uses that to say "saved, waiting for a connection" rather than
  /// pushing a confirmation screen that has nothing to confirm yet.
  ///
  /// Only connection failures are parked. A quota error or a rejected file
  /// would fail again on every retry, so those are raised to the user now.
  Future<CaptureAttempt> _send(CaptureDraft draft) async {
    try {
      return CaptureAttempt.created(await _repository.enqueue(draft));
    } on NetworkException {
      return await _park(draft);
    } on AppException {
      rethrow;
    } catch (error) {
      // A socket error from a package that does not speak our exception type.
      if (_looksOffline(error)) return await _park(draft);
      rethrow;
    }
  }

  /// Parks the draft, or gives up honestly.
  ///
  /// The web has no outbox - no filesystem, and no Share Sheet to feed it. If
  /// we claimed "saved, waiting for a connection" there, we would be telling
  /// the user their receipt is safe when it is already gone.
  Future<CaptureAttempt> _park(CaptureDraft draft) async {
    final entry = await _ref.read(captureOutboxProvider).add(draft);
    if (entry == null) throw const NetworkException();
    await _ref.read(outboxCountProvider.notifier).refresh();
    return const CaptureAttempt.parked();
  }

  static bool _looksOffline(Object error) {
    final text = error.toString().toLowerCase();
    return error is SocketException ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection closed') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable');
  }

  /// A browser has no path worth anything - image_picker hands back a blob
  /// URL - so on the web the bytes travel instead. Everything downstream
  /// already accepts either.
  static Future<Uint8List?> _bytesIfWeb(XFile file) async =>
      kIsWeb ? await file.readAsBytes() : null;

  Future<CaptureAttempt> fromCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null) return const CaptureAttempt.cancelled();
    return _send(
      CaptureDraft(
        source: CaptureSource.camera,
        kind: CaptureKind.image,
        filePath: kIsWeb ? null : picked.path,
        bytes: await _bytesIfWeb(picked),
        mimeType: picked.mimeType ?? 'image/jpeg',
        title: picked.name,
      ),
    );
  }

  Future<CaptureAttempt> fromLibrary() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null) return const CaptureAttempt.cancelled();
    return _send(
      CaptureDraft(
        source: CaptureSource.photoLibrary,
        kind: CaptureKind.image,
        filePath: kIsWeb ? null : picked.path,
        bytes: await _bytesIfWeb(picked),
        mimeType: picked.mimeType ?? 'image/jpeg',
        title: picked.name,
      ),
    );
  }

  Future<CaptureAttempt> fromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'heic'],
      // Without this the web picker returns a name and nothing to upload.
      withData: kIsWeb,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return const CaptureAttempt.cancelled();
    if (file.path == null && file.bytes == null) {
      return const CaptureAttempt.cancelled();
    }
    final isPdf = file.extension?.toLowerCase() == 'pdf';
    return _send(
      CaptureDraft(
        source: CaptureSource.fileUpload,
        kind: isPdf ? CaptureKind.pdf : CaptureKind.image,
        filePath: kIsWeb ? null : file.path,
        bytes: kIsWeb ? file.bytes : null,
        mimeType: isPdf ? 'application/pdf' : 'image/jpeg',
        title: file.name,
      ),
    );
  }

  Future<CaptureAttempt> fromText(String text) => _send(
    CaptureDraft(
      source: CaptureSource.pastedText,
      kind: CaptureKind.text,
      text: text,
      title: 'Text',
    ),
  );
}

final captureControllerProvider = Provider<CaptureController>(
  CaptureController.new,
);
