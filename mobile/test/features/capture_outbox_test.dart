import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/errors/app_exception.dart';
import 'package:relya/services/outbox/capture_outbox.dart';
import 'package:relya/shared/data/mock/mock_capture_repository.dart';
import 'package:relya/shared/data/repositories/capture_repository.dart';
import 'package:relya/shared/domain/capture.dart';

/// A repository that is offline until it is told otherwise.
class _FlakyRepository extends MockCaptureRepository {
  _FlakyRepository() : super(captures: const []);

  bool online = false;
  int attempts = 0;

  @override
  Future<Capture> enqueue(CaptureDraft draft) {
    attempts++;
    if (!online) throw const NetworkException();
    return super.enqueue(draft);
  }
}

void main() {
  late Directory dir;
  late CaptureOutbox outbox;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('relya-outbox');
    outbox = CaptureOutbox(root: dir);
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('a parked capture survives being written and read back', () async {
    await outbox.add(
      const CaptureDraft(
        source: CaptureSource.shareSheet,
        kind: CaptureKind.text,
        text: 'Dentista dia 17 as 15:30',
        title: 'Message',
      ),
    );

    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.text, 'Dentista dia 17 as 15:30');
    expect(pending.single.attempts, 0);
  });

  test('the original file is copied, not referenced', () async {
    final source = File('${dir.path}/picked.jpg')..writeAsBytesSync([1, 2, 3]);
    await outbox.add(
      CaptureDraft(
        source: CaptureSource.camera,
        kind: CaptureKind.image,
        filePath: source.path,
        title: 'Photo',
      ),
    );
    // The picker's temporary file can be swept up by the OS before the network
    // returns; the queue must not depend on it still being there.
    await source.delete();

    final pending = await outbox.pending();
    expect(pending.single.filePath, isNot(source.path));
    expect(File(pending.single.filePath!).existsSync(), isTrue);
  });

  test('a failed flush keeps the entry and counts the attempt', () async {
    final repository = _FlakyRepository();
    await outbox.add(
      const CaptureDraft(
        source: CaptureSource.shareSheet,
        kind: CaptureKind.text,
        text: 'still offline',
      ),
    );

    expect(await outbox.flush(repository), 0);
    final pending = await outbox.pending();
    expect(pending, hasLength(1), reason: 'nothing may be lost');
    expect(pending.single.attempts, 1);
  });

  test('the queue empties once the network is back', () async {
    final repository = _FlakyRepository();
    for (final text in ['one', 'two']) {
      await outbox.add(
        CaptureDraft(
          source: CaptureSource.shareSheet,
          kind: CaptureKind.text,
          text: text,
        ),
      );
    }
    await outbox.flush(repository);
    expect(await outbox.count(), 2);

    repository.online = true;
    expect(await outbox.flush(repository), 2);
    expect(await outbox.count(), 0);
    expect((await repository.inbox()), hasLength(2));
  });

  test('a hopeless entry stops being retried but is not deleted', () async {
    final repository = _FlakyRepository();
    await outbox.add(
      const CaptureDraft(
        source: CaptureSource.shareSheet,
        kind: CaptureKind.text,
        text: 'poison',
      ),
    );
    for (var i = 0; i < CaptureOutbox.maxAttempts + 3; i++) {
      await outbox.flush(repository);
    }

    expect(repository.attempts, CaptureOutbox.maxAttempts);
    expect(await outbox.count(), 1, reason: 'the user still gets told');
    expect(await outbox.stuck(), hasLength(1));
  });
}
