import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/time_bucket.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';

class UpcomingSection {
  const UpcomingSection({required this.bucket, required this.items});

  final TimeBucket bucket;
  final List<LifeItem> items;
}

/// The timeline, grouped by urgency. Empty buckets are dropped: a heading with
/// nothing under it is noise.
final upcomingProvider = FutureProvider.autoDispose<List<UpcomingSection>>((
  ref,
) async {
  final repository = ref.watch(lifeItemRepositoryProvider);
  final subscription = repository.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);

  final now = DateTime.now();
  final items = await repository.upcoming();

  final grouped = <TimeBucket, List<LifeItem>>{};
  for (final item in items) {
    if (item.isHiddenAt(now)) continue;
    final instant = item.primaryInstant?.toLocal();
    final bucket = instant == null
        ? TimeBucket.undated
        : TimeBucketing.of(instant, now);
    grouped.putIfAbsent(bucket, () => []).add(item);
  }

  return TimeBucket.values
      .where((bucket) => grouped[bucket]?.isNotEmpty ?? false)
      .map((bucket) => UpcomingSection(bucket: bucket, items: grouped[bucket]!))
      .toList();
});

/// Three ways to look at the same items. Agenda only appears in the design
/// that asks for it; the other two are always available.
enum UpcomingViewMode { calendar, list, agenda }

/// Everything the calendar needs, indexed the way it draws: by local day.
class CalendarData {
  const CalendarData({required this.byDay, required this.now});

  /// Keys are local midnights. Lookups from a grid cell are then O(1) rather
  /// than a scan of every item per cell, which matters at 42 cells a month.
  final Map<DateTime, List<LifeItem>> byDay;
  final DateTime now;

  List<LifeItem> on(DateTime day) =>
      byDay[DateTime(day.year, day.month, day.day)] ?? const [];

  int countOn(DateTime day) => on(day).length;

  bool hasOverdue(DateTime day) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.year, day.month, day.day);
    return target.isBefore(today) && countOn(day) > 0;
  }
}

final calendarDataProvider = FutureProvider.autoDispose<CalendarData>((
  ref,
) async {
  final repository = ref.watch(lifeItemRepositoryProvider);
  final subscription = repository.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);

  final now = DateTime.now();
  // A year back and a year forward: enough to browse without paging the
  // database every time the user swipes a month.
  final items = await repository.upcoming(
    from: now.toUtc().subtract(const Duration(days: 365)),
    limit: 1000,
  );

  final byDay = <DateTime, List<LifeItem>>{};
  for (final item in items) {
    if (item.isHiddenAt(now)) continue;
    // A grid of days has nowhere to put an undated item; the list view is
    // where those live.
    final instant = item.primaryInstant?.toLocal();
    if (instant == null) continue;
    final key = DateTime(instant.year, instant.month, instant.day);
    byDay.putIfAbsent(key, () => []).add(item);
  }
  for (final list in byDay.values) {
    list.sort((a, b) {
      final ai = a.primaryInstant;
      final bi = b.primaryInstant;
      if (ai == null || bi == null) return 0;
      return ai.compareTo(bi);
    });
  }

  return CalendarData(byDay: byDay, now: now);
});

final upcomingViewModeProvider = StateProvider<UpcomingViewMode>(
  (ref) => UpcomingViewMode.calendar,
);

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final selectedDayProvider = StateProvider<DateTime>((ref) => _today());

/// The month the grid is showing, which is not always the month of the
/// selected day: you can browse ahead without losing your selection.
final visibleMonthProvider = StateProvider<DateTime>((ref) {
  final today = _today();
  return DateTime(today.year, today.month);
});
