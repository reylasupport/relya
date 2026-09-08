import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ids/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../services/analytics/analytics_events.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../../services/prefs/local_prefs.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/data/repositories/feedback_repository.dart';
import '../../../shared/domain/extraction.dart';
import '../../../shared/domain/extraction_result.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/reminder.dart';

/// One extracted thing plus every choice the user has made about it. Nothing
/// here has touched the database yet.
class AnalysisDraft {
  const AnalysisDraft({
    required this.result,
    required this.accepted,
    required this.reminderChoices,
    required this.actionChoices,
    this.resolvedDateOverride,
  });

  final ExtractionResult result;
  final bool accepted;

  /// Index-aligned with result.suggestedReminders.
  final List<bool> reminderChoices;

  /// Index-aligned with result.suggestedActions.
  final List<bool> actionChoices;

  /// Set when the user picked between two readings of an ambiguous date.
  final DateTime? resolvedDateOverride;

  factory AnalysisDraft.initial(ExtractionResult result) => AnalysisDraft(
    result: result,
    // Anything the model is unsure about starts unticked: the user opts in
    // to a guess, never out of one.
    accepted: !result.needsUserAttention || result.confidence >= 0.55,
    reminderChoices: result.suggestedReminders
        .map((r) => r.enabledByDefault)
        .toList(),
    actionChoices: result.suggestedActions
        .map((a) => a.enabledByDefault)
        .toList(),
  );

  AnalysisDraft copyWith({
    bool? accepted,
    List<bool>? reminderChoices,
    List<bool>? actionChoices,
    DateTime? resolvedDateOverride,
    ExtractionResult? result,
  }) {
    return AnalysisDraft(
      result: result ?? this.result,
      accepted: accepted ?? this.accepted,
      reminderChoices: reminderChoices ?? this.reminderChoices,
      actionChoices: actionChoices ?? this.actionChoices,
      resolvedDateOverride: resolvedDateOverride ?? this.resolvedDateOverride,
    );
  }

  bool get blockedByAmbiguity =>
      result.hasAmbiguousDate && resolvedDateOverride == null;
}

sealed class AnalysisUiState {
  const AnalysisUiState();
}

class AnalysisRunning extends AnalysisUiState {
  const AnalysisRunning();
}

class AnalysisReady extends AnalysisUiState {
  const AnalysisReady({required this.drafts, required this.analysis});

  final AnalysisResult analysis;
  final List<AnalysisDraft> drafts;

  int get acceptedCount => drafts.where((d) => d.accepted).length;

  bool get canSubmit =>
      acceptedCount > 0 &&
      drafts.where((d) => d.accepted).every((d) => !d.blockedByAmbiguity);
}

class AnalysisFailed extends AnalysisUiState {
  const AnalysisFailed(this.error);

  final Object error;
}

class AnalysisSaved extends AnalysisUiState {
  const AnalysisSaved(this.itemCount);

  final int itemCount;
}

/// Runs the pipeline for one capture and holds the user choices until they
/// press Add. Nothing is written before that: an interpretation the user has
/// not seen never becomes part of their life (spec section 18).
class AnalysisController extends StateNotifier<AnalysisUiState> {
  AnalysisController(this._ref, this.captureId)
    : super(const AnalysisRunning()) {
    _start();
  }

  final Ref _ref;
  final String captureId;

  Future<void> _start() async {
    final captures = _ref.read(captureRepositoryProvider);
    try {
      final cached = await captures.cachedAnalysis(captureId);
      final analysis = cached ?? await captures.analyse(captureId);
      if (!mounted) return;
      state = AnalysisReady(
        analysis: analysis,
        drafts: analysis.items.map(AnalysisDraft.initial).toList(),
      );
    } catch (error) {
      if (!mounted) return;
      state = AnalysisFailed(error);
    }
  }

  void retry() {
    state = const AnalysisRunning();
    _start();
  }

  void _mutate(int index, AnalysisDraft Function(AnalysisDraft) transform) {
    final current = state;
    if (current is! AnalysisReady) return;
    final drafts = [...current.drafts];
    drafts[index] = transform(drafts[index]);
    state = AnalysisReady(analysis: current.analysis, drafts: drafts);
  }

  void toggleAccepted(int index) =>
      _mutate(index, (d) => d.copyWith(accepted: !d.accepted));

  void toggleReminder(int index, int reminderIndex) => _mutate(index, (d) {
    final choices = [...d.reminderChoices];
    choices[reminderIndex] = !choices[reminderIndex];
    return d.copyWith(reminderChoices: choices);
  });

  void toggleAction(int index, int actionIndex) => _mutate(index, (d) {
    final choices = [...d.actionChoices];
    choices[actionIndex] = !choices[actionIndex];
    return d.copyWith(actionChoices: choices);
  });

  void resolveAmbiguousDate(int index, DateTime chosen) =>
      _mutate(index, (d) => d.copyWith(resolvedDateOverride: chosen));

  void editTitle(int index, String title) => _mutate(
    index,
    (d) => d.copyWith(result: d.result.copyWith(title: title)),
  );

  void editDate(int index, DateTime when) => _mutate(index, (d) {
    final dates = d.result.dates.map((date) {
      if (date.kind != ExtractedDateKind.start &&
          date.kind != ExtractedDateKind.deadline) {
        return date;
      }
      return ExtractedDate(
        raw: date.raw,
        kind: date.kind,
        resolved: when.toUtc(),
        timezone: date.timezone,
        hasTime: date.hasTime,
        confidence: 1.0,
      );
    }).toList();
    return d.copyWith(
      result: d.result.copyWith(dates: dates),
      resolvedDateOverride: when.toUtc(),
    );
  });

  /// Writes the accepted items and their reminders. One call, so the user
  /// never ends up with the appointment saved but the reminder missing.
  Future<int> submit() async {
    final current = state;
    if (current is! AnalysisReady) return 0;

    final now = DateTime.now().toUtc();
    final accepted = current.drafts.where((d) => d.accepted).toList();
    if (accepted.isEmpty) return 0;

    final items = <LifeItem>[];
    final remindersByItem = <String, List<Reminder>>{};
    final corrections = <ExtractionCorrection>[];

    // Anything the user threw away is a wrong extraction, and saying so is
    // half the signal. Recorded from the full draft list, not the accepted
    // one, which is the only place it can be seen.
    for (var i = 0; i < current.drafts.length; i++) {
      if (current.drafts[i].accepted) continue;
      corrections.add(
        ExtractionCorrection(
          captureId: captureId,
          field: 'item',
          originalValue: current.analysis.items[i].title,
          note: 'rejected',
        ),
      );
    }

    for (final draft in accepted) {
      final item = draft.result.toLifeItem(captureId: captureId, now: now);
      items.add(item);
      corrections.addAll(_correctionsFor(draft, current.analysis, item));
      final itemReminders = <Reminder>[];

      for (var i = 0; i < draft.result.suggestedReminders.length; i++) {
        if (!draft.reminderChoices[i]) continue;
        final suggestion = draft.result.suggestedReminders[i];
        final anchor = suggestion.anchor == 'deadline'
            ? item.deadlineAt
            : item.startAt ?? item.deadlineAt;
        if (anchor == null) continue;

        final fireAt = anchor.subtract(suggestion.leadTime);
        // A reminder for a moment that has already passed helps nobody.
        if (fireAt.isBefore(now)) continue;

        itemReminders.add(
          Reminder(
            id: newId(),
            itemId: item.id,
            fireAt: fireAt,
            timezone: item.startTimezone ?? 'UTC',
            anchor: suggestion.anchor == 'deadline'
                ? ReminderAnchor.deadline
                : ReminderAnchor.start,
            leadTime: suggestion.leadTime,
            label: suggestion.label,
            status: ReminderStatus.scheduled,
          ),
        );
      }
      remindersByItem[item.id] = itemReminders;
    }

    await _ref.read(lifeItemRepositoryProvider).createAll(items);

    // Scheduled per item, because quiet hours and muted categories are decided
    // per item type. An item saved without its notification is a note, not a
    // reminder, so this is part of the same user action.
    final scheduler = _ref.read(reminderSchedulerProvider);
    for (final item in items) {
      final pending = remindersByItem[item.id];
      if (pending == null || pending.isEmpty) continue;
      await scheduler.scheduleAll(item: item, reminders: pending);
    }

    await _ref.read(feedbackRepositoryProvider).record(corrections);

    await _ref
        .read(captureRepositoryProvider)
        .markCompleted(captureId, itemCount: items.length);

    await _trackSuccess(items.length);

    if (mounted) state = AnalysisSaved(items.length);
    return items.length;
  }

  /// What the user changed about one extraction, by comparing the draft with
  /// the reading the model handed over. Only the two fields the confirmation
  /// screen can actually edit, because inventing a diff for a field with no
  /// editor would pollute the corpus with noise.
  List<ExtractionCorrection> _correctionsFor(
    AnalysisDraft draft,
    AnalysisResult analysis,
    LifeItem item,
  ) {
    final original = analysis.items.firstWhere(
      (candidate) => candidate.id == draft.result.id,
      orElse: () => draft.result,
    );
    final found = <ExtractionCorrection>[];

    if (original.title != draft.result.title) {
      found.add(
        ExtractionCorrection(
          captureId: captureId,
          itemId: item.id,
          field: 'title',
          originalValue: original.title,
          correctedValue: draft.result.title,
        ),
      );
    }

    final was = original.startAt ?? original.deadlineAt;
    final now = draft.resolvedDateOverride ?? item.startAt ?? item.deadlineAt;
    if (was != now) {
      found.add(
        ExtractionCorrection(
          captureId: captureId,
          itemId: item.id,
          field: 'date',
          originalValue: was?.toIso8601String(),
          correctedValue: now?.toIso8601String(),
          // An ambiguous date the user disambiguated is not the same mistake
          // as a date the model simply got wrong.
          note: original.hasAmbiguousDate ? 'ambiguous' : null,
        ),
      );
    }

    return found;
  }

  /// Counts only what actually worked: an extraction the user accepted.
  /// first_successful_capture is the activation metric the whole funnel is
  /// judged on, so it fires once per install and never on a dismissal.
  Future<void> _trackSuccess(int itemCount) async {
    // Telemetry must never be able to lose a save the user already made, so
    // every failure here is swallowed on purpose.
    try {
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.track(
        AnalyticsEvents.captureCompleted,
        properties: {AnalyticsProps.itemCount: itemCount},
      );

      final prefs = _ref.read(localPrefsProvider);
      if (prefs.firstCaptureTracked) return;
      await prefs.setFirstCaptureTracked();
      await analytics.track(AnalyticsEvents.firstSuccessfulCapture);
    } catch (error, stack) {
      AppLogger.error('Could not record capture analytics', error, stack);
    }
  }
}

final analysisControllerProvider = StateNotifierProvider.autoDispose
    .family<AnalysisController, AnalysisUiState, String>(
      (ref, captureId) => AnalysisController(ref, captureId),
    );
