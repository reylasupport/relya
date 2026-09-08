/// How the Upcoming timeline and the Home screen group things in time.
/// Ordered by urgency: the list is sorted by bucket first, then by instant.
enum TimeBucket {
  overdue,
  today,
  tomorrow,
  thisWeek,
  next30Days,
  later,

  /// A task or a warranty with no date at all. Last, because nothing about it
  /// is pressing - but it still has to appear somewhere, or the item is only
  /// findable through search.
  undated;

  bool get isUrgent => this == overdue || this == today;
}

abstract final class TimeBucketing {
  const TimeBucketing._();

  /// [when] and [now] must already be in the user's local timezone.
  static TimeBucket of(DateTime when, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(when.year, when.month, when.day);
    final days = target.difference(today).inDays;

    if (days < 0) return TimeBucket.overdue;
    if (days == 0) return TimeBucket.today;
    if (days == 1) return TimeBucket.tomorrow;
    if (days <= 7) return TimeBucket.thisWeek;
    if (days <= 30) return TimeBucket.next30Days;
    return TimeBucket.later;
  }
}
