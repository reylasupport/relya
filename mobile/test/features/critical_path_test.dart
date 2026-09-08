import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/analysis/application/analysis_controller.dart';
import 'package:relya/shared/data/mock/mock_capture_repository.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/shared/data/mock/mock_simple_repositories.dart';
import 'package:relya/shared/data/providers.dart';
import 'package:relya/shared/data/repositories/capture_repository.dart';
import 'package:relya/shared/domain/capture.dart';
import 'package:relya/shared/domain/life_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The path this product exists for: something arrives, the AI reads it, the
/// user accepts it, and a reminder is waiting afterwards.
///
/// Every step of it was covered by a separate test and the seam between them
/// by none, which is exactly where a regression would hide. This walks the
/// whole thing once, through the real controllers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockCaptureRepository captures;
  late MockLifeItemRepository items;
  late MockReminderRepository reminders;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    captures = MockCaptureRepository(captures: <Capture>[]);
    items = MockLifeItemRepository(items: <LifeItem>[]);
    reminders = MockReminderRepository();
    container = ProviderContainer(
      overrides: [
        captureRepositoryProvider.overrideWithValue(captures),
        lifeItemRepositoryProvider.overrideWithValue(items),
        reminderRepositoryProvider.overrideWithValue(reminders),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<AnalysisReady> analyse(String captureId) async {
    final provider = analysisControllerProvider(captureId);
    container.listen(provider, (_, __) {});
    // The mock reproduces the real timings, so this waits rather than pumps.
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (container.read(provider) is AnalysisRunning) {
      if (DateTime.now().isAfter(deadline)) fail('analysis never finished');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final state = container.read(provider);
    if (state is! AnalysisReady) fail('analysis failed: $state');
    return state;
  }

  test('shared text becomes an item with a reminder waiting', () async {
    // 1. Something arrives through the Share Sheet.
    final capture = await captures.enqueue(
      const CaptureDraft(
        source: CaptureSource.shareSheet,
        kind: CaptureKind.text,
        text: 'Consulta de dentista dia 17 de setembro as 15:30.',
        title: 'Message from Joana',
      ),
    );
    expect(capture.status, CaptureStatus.queued);

    // 2. The AI reads it.
    final ready = await analyse(capture.id);
    expect(ready.drafts, isNotEmpty, reason: 'nothing was understood');

    // 3. The user accepts. Nothing may be written before this point.
    expect(await items.upcoming(), isEmpty, reason: 'written before consent');

    final controller = container.read(
      analysisControllerProvider(capture.id).notifier,
    );
    final written = await controller.submit();
    expect(written, greaterThan(0));

    // 4. The item is there, and so is the reminder.
    final stored = await items.upcoming();
    expect(stored, hasLength(written));

    final scheduled = await reminders.forItem(stored.first.id);
    expect(
      scheduled,
      isNotEmpty,
      reason: 'an accepted suggestion must leave a reminder behind',
    );
    for (final reminder in scheduled) {
      expect(
        reminder.fireAt.isAfter(DateTime.now().toUtc()),
        isTrue,
        reason: 'a reminder for a moment that has passed helps nobody',
      );
    }
  });

  test('declining every suggestion writes nothing at all', () async {
    final capture = await captures.enqueue(
      const CaptureDraft(
        source: CaptureSource.shareSheet,
        kind: CaptureKind.text,
        text: 'Consulta de dentista dia 17 de setembro as 15:30.',
      ),
    );
    final ready = await analyse(capture.id);
    final controller = container.read(
      analysisControllerProvider(capture.id).notifier,
    );
    for (var i = 0; i < ready.drafts.length; i++) {
      controller.toggleAccepted(i);
    }

    expect(await controller.submit(), 0);
    expect(await items.upcoming(), isEmpty);
  });
}
