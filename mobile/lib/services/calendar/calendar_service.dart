import 'package:add_2_calendar/add_2_calendar.dart' as add2;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../shared/domain/life_item.dart';

/// Adds an event to whichever calendar the user already uses.
///
/// Deliberately hands off to the system sheet rather than writing to calendars
/// directly: it needs no calendar permission at all, the user sees exactly what
/// is being created, and we are not trying to replace Apple or Google Calendar
/// (spec section 49).
abstract interface class CalendarService {
  Future<bool> addEvent(LifeItem item);
}

class SystemCalendarService implements CalendarService {
  const SystemCalendarService();

  @override
  Future<bool> addEvent(LifeItem item) async {
    final start = (item.startAt ?? item.deadlineAt)?.toLocal();
    if (start == null) return false;

    final event = add2.Event(
      title: item.title,
      description: item.description ?? '',
      location: item.location ?? '',
      startDate: start,
      endDate: item.endAt?.toLocal() ?? start.add(const Duration(hours: 1)),
      allDay: item.allDay,
    );
    return add2.Add2Calendar.addEvent2Cal(event);
  }
}

/// Used with fixtures and in tests, where opening a system sheet would hang.
class NoopCalendarService implements CalendarService {
  const NoopCalendarService();

  @override
  Future<bool> addEvent(LifeItem item) async => true;
}

final calendarServiceProvider = Provider<CalendarService>((ref) {
  // The system sheet only exists on a phone. On fixtures, in tests and in a
  // browser preview the plugin is not there, and calling it throws where the
  // user just sees a dead button.
  final onDevice =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (kIsWeb || !onDevice || AppEnv.useMockData) {
    return const NoopCalendarService();
  }
  return const SystemCalendarService();
});
