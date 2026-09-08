import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../features/settings/application/preferences_controller.dart';
import '../../shared/data/providers.dart';
import '../../shared/domain/life_item.dart';
import '../../shared/domain/reminder.dart';
import 'notification_service.dart';

/// Turns accepted suggestions into notifications the operating system will
/// actually deliver.
///
/// This is the last step of the promise: an item saved without a notification
/// scheduled is a note, not a reminder. Kept out of the controllers because
/// three of them need it, and because it is where permission, quiet hours and
/// muted categories all have to agree.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  /// Persists the reminders and schedules each one locally.
  ///
  /// Returns the reminders as stored, with their platform notification ids, so
  /// they can be cancelled later. Never throws: failing to schedule must not
  /// lose the item the user just accepted.
  Future<List<Reminder>> scheduleAll({
    required LifeItem item,
    required List<Reminder> reminders,
  }) async {
    if (reminders.isEmpty) return const [];

    final prefs = _ref.read(preferencesProvider);
    if (!prefs.notificationsEnabled || prefs.isMuted(item.type.wire)) {
      // Still stored, so the item detail shows what was asked for and the
      // reminder starts working the moment the category is unmuted.
      return _ref.read(reminderRepositoryProvider).createAll(reminders);
    }

    final service = _notifications();
    if (service == null) {
      return _ref.read(reminderRepositoryProvider).createAll(reminders);
    }

    // Asked here, in context, the first time it actually matters (spec 50).
    final granted = await service.requestPermission();

    final adjusted = <Reminder>[];
    for (final reminder in reminders) {
      final fireAt = NotificationService.applyQuietHours(
        reminder.fireAt,
        prefs.quietHoursStart?.hour,
        prefs.quietHoursEnd?.hour,
      );
      adjusted.add(reminder.copyWith(fireAt: fireAt));
    }

    final stored = await _ref
        .read(reminderRepositoryProvider)
        .createAll(adjusted);
    if (!granted) return stored;

    final scheduled = <Reminder>[];
    for (final reminder in stored) {
      try {
        final id = await service.schedule(
          reminder: reminder,
          title: item.title,
          body: reminder.label ?? '',
        );
        scheduled.add(reminder.copyWith(localNotificationId: id));
      } catch (error, stack) {
        AppLogger.error('Could not schedule a reminder', error, stack);
        scheduled.add(reminder);
      }
    }
    return scheduled;
  }

  Future<void> cancelFor(String itemId) async {
    final repository = _ref.read(reminderRepositoryProvider);
    final existing = await repository.forItem(itemId);
    final service = _notifications();
    for (final reminder in existing) {
      final id = reminder.localNotificationId;
      if (id != null && service != null) await service.cancel(id);
      await repository.cancel(reminder.id);
    }
  }

  /// Null on a build or a test where notifications were never initialised.
  NotificationService? _notifications() {
    try {
      return _ref.read(notificationServiceProvider);
    } on StateError {
      return null;
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);
