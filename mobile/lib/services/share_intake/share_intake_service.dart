import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/logging/app_logger.dart';
import '../../shared/data/providers.dart';
import '../../shared/data/repositories/capture_repository.dart';
import '../../shared/domain/capture.dart';

/// The Share Sheet path (spec section 41). This is the feature.
///
/// Two entry points have to work: the app being launched by a share while it
/// was closed, and a share arriving while it is already running. Both end in
/// the same place, a queued capture and a route to the confirmation screen.
class ShareIntakeService {
  ShareIntakeService(this._ref);

  final Ref _ref;

  StreamSubscription<List<SharedMediaFile>>? _subscription;

  /// Emits the id of every capture created from a share, so the router can
  /// take the user straight to it.
  final StreamController<String> _created =
      StreamController<String>.broadcast();

  Stream<String> get createdCaptures => _created.stream;

  Future<void> start() async {
    // Cold start: the app was launched by the share itself.
    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initial.isNotEmpty) await _handle(initial);
    await ReceiveSharingIntent.instance.reset();

    // Warm: shares arriving while the app is alive.
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handle,
    );
  }

  Future<void> _handle(List<SharedMediaFile> media) async {
    final repository = _ref.read(captureRepositoryProvider);
    for (final item in media) {
      try {
        final draft = _toDraft(item);
        if (draft == null) continue;
        final capture = await repository.enqueue(draft);
        _created.add(capture.id);
      } catch (error, stack) {
        AppLogger.error('Could not accept a shared item', error, stack);
      }
    }
  }

  CaptureDraft? _toDraft(SharedMediaFile item) {
    switch (item.type) {
      case SharedMediaType.image:
        return CaptureDraft(
          source: CaptureSource.shareSheet,
          kind: CaptureKind.image,
          filePath: item.path,
          mimeType: item.mimeType ?? 'image/jpeg',
          title: 'Screenshot',
        );
      case SharedMediaType.file:
        final isPdf = item.path.toLowerCase().endsWith('.pdf');
        return CaptureDraft(
          source: CaptureSource.shareSheet,
          kind: isPdf ? CaptureKind.pdf : CaptureKind.image,
          filePath: item.path,
          mimeType: item.mimeType,
          title: item.path.split(Platform.pathSeparator).last,
        );
      case SharedMediaType.url:
        return CaptureDraft(
          source: CaptureSource.shareSheet,
          kind: CaptureKind.url,
          url: item.path,
          title: Uri.tryParse(item.path)?.host ?? 'Link',
        );
      case SharedMediaType.text:
        return CaptureDraft(
          source: CaptureSource.shareSheet,
          kind: CaptureKind.text,
          text: item.path,
          title: 'Shared text',
        );
      case SharedMediaType.video:
        // Nothing useful to extract from a video in V1.
        return null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _created.close();
  }
}

final shareIntakeServiceProvider = Provider<ShareIntakeService>((ref) {
  final service = ShareIntakeService(ref);
  ref.onDispose(service.dispose);
  return service;
});
