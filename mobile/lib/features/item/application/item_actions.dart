import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ids/ids.dart';
import '../../../services/notifications/reminder_scheduler.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/data/repositories/life_item_repository.dart';
import '../../../shared/data/repositories/reminder_repository.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_status.dart';
import '../../../shared/domain/reminder.dart';

/// Everything that changes an item after it has been saved.
///
/// Kept out of the widgets because all three operations have the same second
/// half - the reminders have to follow the item - and a screen that forgets
/// that half leaves a notification pointing at a date nobody expects any more.
class ItemActions {
  ItemActions(this._ref);

  final Ref _ref;

  LifeItemRepository get _items => _ref.read(lifeItemRepositoryProvider);

  ReminderRepository get _reminders => _ref.read(reminderRepositoryProvider);

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);

  /// Marks [item] done. A repeating item writes its next occurrence first, so
  /// completing this month's rent is also what creates next month's.
  ///
  /// Returns the occurrence that was created, or null for a one-off.
  Future<LifeItem?> complete(LifeItem item) async {
    final next = await _nextOccurrence(item);
    await _items.update(
      item.copyWith(status: LifeItemStatus.done, snoozedUntil: null),
    );
    await _scheduler.cancelFor(item.id);
    return next;
  }

  /// Hides [item] until [until] and nudges then.
  ///
  /// The dates on the item are left alone: a bill that is due on the 8th is
  /// still due on the 8th after the user has said "not now". What moves is
  /// when they hear about it again.
  Future<void> snooze(LifeItem item, DateTime until, {String? label}) async {
    final moment = until.toUtc();
    await _scheduler.cancelFor(item.id);
    final snoozed = item.copyWith(
      status: LifeItemStatus.snoozed,
      snoozedUntil: moment,
    );
    await _items.update(snoozed);
    await _scheduler.scheduleAll(
      item: snoozed,
      reminders: [
        Reminder(
          id: newId(),
          itemId: item.id,
          fireAt: moment,
          timezone: item.startTimezone ?? DateTime.now().timeZoneName,
          anchor: ReminderAnchor.absolute,
          status: ReminderStatus.scheduled,
          label: label,
        ),
      ],
    );
  }

  /// Brings a snoozed item back now, with the reminders it had before.
  Future<void> resume(LifeItem item) async {
    final existing = await _reminders.forItem(item.id);
    await _scheduler.cancelFor(item.id);
    final active = item.copyWith(
      status: LifeItemStatus.active,
      snoozedUntil: null,
    );
    await _items.update(active);
    final restored = _rebuild(existing, active);
    if (restored.isNotEmpty) {
      await _scheduler.scheduleAll(item: active, reminders: restored);
    }
  }

  /// Writes an edited item and moves its reminders with it.
  Future<LifeItem> save(LifeItem edited, {required LifeItem original}) async {
    final updated = await _items.update(edited);

    final moved =
        original.startAt != edited.startAt ||
        original.deadlineAt != edited.deadlineAt;
    if (!moved) return updated;

    final existing = await _reminders.forItem(edited.id);
    await _scheduler.cancelFor(edited.id);
    final rebuilt = _rebuild(existing, updated);
    if (rebuilt.isNotEmpty) {
      await _scheduler.scheduleAll(item: updated, reminders: rebuilt);
    }
    return updated;
  }

  Future<LifeItem?> _nextOccurrence(LifeItem item) async {
    final rule = item.recurrence;
    if (rule == null) return null;

    final nextStart = item.startAt == null ? null : rule.next(item.startAt!);
    final nextDeadline = item.deadlineAt == null
        ? null
        : rule.next(item.deadlineAt!);
    final anchor = nextStart ?? nextDeadline;
    // The check constraint in the schema stops this from happening, but a row
    // written before it existed would otherwise loop forever on no date.
    if (anchor == null) return null;

    final until = item.recurrenceUntil;
    if (until != null && anchor.isAfter(until)) return null;

    final length = item.startAt != null && item.endAt != null
        ? item.endAt!.difference(item.startAt!)
        : null;

    final created = await _items.create(
      item.copyWith(
        id: newId(),
        status: LifeItemStatus.active,
        startAt: nextStart,
        endAt: length == null ? null : nextStart!.add(length),
        deadlineAt: nextDeadline,
        snoozedUntil: null,
        // The first occurrence is the series. Every one after it says so.
        seriesId: item.seriesId ?? item.id,
        createdAt: DateTime.now().toUtc(),
        updatedAt: null,
      ),
    );

    final reminders = _rebuild(await _reminders.forItem(item.id), created);
    if (reminders.isNotEmpty) {
      await _scheduler.scheduleAll(item: created, reminders: reminders);
    }
    return created;
  }

  /// Recomputes a set of reminders against the dates [item] has now.
  ///
  /// Only lead-time reminders travel: an absolute one - the nudge a snooze
  /// leaves behind - was a moment the user picked, not a rule to reapply.
  /// Duplicates are dropped by anchor and lead, so snoozing and resuming the
  /// same item repeatedly cannot multiply its notifications.
  List<Reminder> _rebuild(List<Reminder> source, LifeItem item) {
    final now = DateTime.now().toUtc();
    final seen = <String>{};
    final rebuilt = <Reminder>[];

    for (final reminder in source) {
      final lead = reminder.leadTime;
      if (lead == null) continue;
      if (!seen.add('${reminder.anchor.wire}:${lead.inSeconds}')) continue;

      final anchor = reminder.anchor == ReminderAnchor.deadline
          ? item.deadlineAt
          : item.startAt ?? item.deadlineAt;
      if (anchor == null) continue;

      final fireAt = anchor.subtract(lead);
      if (!fireAt.isAfter(now)) continue;

      rebuilt.add(
        Reminder(
          id: newId(),
          itemId: item.id,
          fireAt: fireAt,
          timezone: item.startTimezone ?? reminder.timezone,
          anchor: reminder.anchor,
          leadTime: lead,
          label: reminder.label,
          status: ReminderStatus.scheduled,
        ),
      );
    }
    return rebuilt;
  }
}

final itemActionsProvider = Provider<ItemActions>(ItemActions.new);
