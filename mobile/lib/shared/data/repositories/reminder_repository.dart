import '../../domain/reminder.dart';

abstract interface class ReminderRepository {
  Future<List<Reminder>> forItem(String itemId);

  Future<List<Reminder>> pending();

  Future<Reminder> create(Reminder reminder);

  Future<List<Reminder>> createAll(List<Reminder> reminders);

  Future<void> cancel(String reminderId);

  /// Called when the device timezone changes. Reminders anchored to a local
  /// wall-clock moment are recomputed so a traveller is still warned two hours
  /// before the appointment, in the timezone the appointment lives in.
  Future<void> rescheduleForTimezone(String timezone);
}
