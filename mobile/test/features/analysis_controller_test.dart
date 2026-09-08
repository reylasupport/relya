import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/analysis/application/analysis_controller.dart';
import 'package:relya/shared/data/mock/mock_capture_repository.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/shared/data/mock/mock_simple_repositories.dart';
import 'package:relya/shared/data/providers.dart';

void main() {
  late ProviderContainer container;
  late MockLifeItemRepository items;
  late MockReminderRepository reminders;
  late MockFeedbackRepository feedback;

  setUp(() {
    items = MockLifeItemRepository();
    reminders = MockReminderRepository();
    feedback = MockFeedbackRepository();
    container = ProviderContainer(
      overrides: [
        lifeItemRepositoryProvider.overrideWithValue(items),
        reminderRepositoryProvider.overrideWithValue(reminders),
        captureRepositoryProvider.overrideWithValue(MockCaptureRepository()),
        feedbackRepositoryProvider.overrideWithValue(feedback),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<AnalysisReady> ready() async {
    final provider = analysisControllerProvider('cap-pending');
    container.listen(provider, (_, __) {});
    while (container.read(provider) is AnalysisRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return container.read(provider) as AnalysisReady;
  }

  test('the demo capture yields three understood things', () async {
    final state = await ready();
    expect(state.drafts, hasLength(3));
  });

  test('a low-confidence result still starts accepted but flagged', () async {
    final state = await ready();
    final uncertain = state.drafts.firstWhere(
      (d) => d.result.confidence < 0.85,
    );
    expect(uncertain.result.needsUserAttention, isTrue);
  });

  test('submitting writes only the accepted items', () async {
    await ready();
    final notifier = container.read(
      analysisControllerProvider('cap-pending').notifier,
    );

    // Drop one of the three.
    notifier.toggleAccepted(2);
    final saved = await notifier.submit();

    expect(saved, 2);
    final stored = await items.byCapture('cap-pending');
    expect(stored, hasLength(2));
  });

  test('accepted reminders are scheduled alongside their item', () async {
    await ready();
    final notifier = container.read(
      analysisControllerProvider('cap-pending').notifier,
    );
    await notifier.submit();

    final pending = await reminders.pending();
    expect(pending, isNotEmpty);
    // Every reminder must fire in the future; a past reminder is dropped.
    for (final reminder in pending) {
      expect(reminder.fireAt.isAfter(DateTime.now().toUtc()), isTrue);
    }
  });

  group('corrections reach extraction_feedback', () {
    test('an edited title is recorded against the item it produced', () async {
      await ready();
      final notifier = container.read(
        analysisControllerProvider('cap-pending').notifier,
      );

      notifier.editTitle(0, 'Dentist, second floor');
      await notifier.submit();

      final title = feedback.recorded.singleWhere((c) => c.field == 'title');
      expect(title.correctedValue, 'Dentist, second floor');
      expect(title.originalValue, isNot('Dentist, second floor'));
      expect(title.itemId, isNotNull);
    });

    test('a rejected extraction is recorded as a wrong reading', () async {
      await ready();
      final notifier = container.read(
        analysisControllerProvider('cap-pending').notifier,
      );

      notifier.toggleAccepted(2);
      await notifier.submit();

      final rejected = feedback.recorded.where((c) => c.field == 'item');
      expect(rejected, hasLength(1));
      expect(rejected.single.note, 'rejected');
    });

    test('an untouched extraction records nothing at all', () async {
      await ready();
      final notifier = container.read(
        analysisControllerProvider('cap-pending').notifier,
      );

      await notifier.submit();

      expect(feedback.recorded, isEmpty);
    });
  });
}
