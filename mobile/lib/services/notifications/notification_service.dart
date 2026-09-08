import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/logging/app_logger.dart';
import '../../shared/domain/reminder.dart';

/// Local notifications, scheduled against a real timezone.
///
/// Reminders are scheduled with tz.TZDateTime rather than a plain DateTime so
/// that a user who flies from Lisbon to Tokyo is still warned two hours before
/// the appointment in the zone the appointment lives in, and so that daylight
/// saving does not move anything by an hour (spec section 48).
class NotificationService {
  NotificationService(this._plugin);

  static const String _channelId = 'reminders';

  final FlutterLocalNotificationsPlugin _plugin;

  final StreamController<String> _taps = StreamController<String>.broadcast();

  /// Item ids from tapped notifications, for deep linking.
  Stream<String> get taps => _taps.stream;

  static Future<NotificationService> initialise() async {
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));

    final plugin = FlutterLocalNotificationsPlugin();
    final service = NotificationService(plugin);

    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for later, in context, not at launch (spec section 50).
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) service._taps.add(payload);
      },
    );
    return service;
  }

  /// The item id carried by a notification that launched the app.
  ///
  /// onDidReceiveNotificationResponse only fires while the app is alive, so a
  /// reminder tapped after the process had been killed used to open the app on
  /// whatever screen it left off and drop the item on the floor - the one case
  /// where the reminder mattered most.
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final payload = details.notificationResponse?.payload;
    return (payload == null || payload.isEmpty) ? null : payload;
  }

  /// Asked the first time the user accepts a reminder, with the reason on
  /// screen. Never during onboarding.
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Reminders',
      channelDescription: 'Reminders for things that matter',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Returns the platform notification id, which is stored on the reminder so
  /// it can be cancelled later.
  Future<int?> schedule({
    required Reminder reminder,
    required String title,
    required String body,
  }) async {
    if (!reminder.fireAt.isAfter(DateTime.now().toUtc())) return null;

    final location = _locationFor(reminder.timezone);
    final when = tz.TZDateTime.from(reminder.fireAt, location);
    final id = reminder.id.hashCode & 0x7fffffff;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.itemId,
    );
    return id;
  }

  /// An unknown or stale IANA name must not stop a reminder being scheduled;
  /// falling back to the device zone is far better than dropping it.
  tz.Location _locationFor(String timezone) {
    try {
      return tz.getLocation(timezone);
    } catch (_) {
      AppLogger.warn('Unknown timezone $timezone, using the device zone');
      return tz.local;
    }
  }

  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Called when the device reports a different zone. Cancelling and
  /// rescheduling is the only way to move an already-queued OS notification.
  Future<void> onTimezoneChanged(String timezone) async {
    try {
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      AppLogger.warn('Could not switch to timezone $timezone');
    }
  }

  /// Quiet hours are enforced when scheduling rather than when firing: a
  /// notification that arrives at 03:00 has already woken someone up.
  static DateTime applyQuietHours(
    DateTime fireAt,
    int? quietStartHour,
    int? quietEndHour,
  ) {
    if (quietStartHour == null || quietEndHour == null) return fireAt;
    final hour = fireAt.toLocal().hour;
    final inQuiet = quietStartHour <= quietEndHour
        ? hour >= quietStartHour && hour < quietEndHour
        : hour >= quietStartHour || hour < quietEndHour;
    if (!inQuiet) return fireAt;

    final local = fireAt.toLocal();
    final movedTo = DateTime(local.year, local.month, local.day, quietEndHour);
    // If the end of quiet hours is already behind us, it belongs to tomorrow.
    final target = movedTo.isAfter(local)
        ? movedTo
        : movedTo.add(const Duration(days: 1));
    return target.toUtc();
  }

  Future<void> dispose() => _taps.close();
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw StateError('NotificationService was not initialised'),
);
