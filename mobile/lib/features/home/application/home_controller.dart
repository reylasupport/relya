import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/time_bucket.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_status.dart';

/// What Home needs in order to answer one question: what matters right now.
class HomeSnapshot {
  const HomeSnapshot({
    required this.overdue,
    required this.today,
    required this.next,
    required this.weekCount,
    required this.doneCount,
    required this.upcomingCount,
    required this.now,
  });

  final List<LifeItem> overdue;
  final List<LifeItem> today;

  /// The next few things beyond today. Capped, because a wall of items is the
  /// feeling this product exists to remove.
  final List<LifeItem> next;

  /// Everything due within seven days, including today. A count, not a list:
  /// it belongs in the header, not in the body.
  final int weekCount;

  /// Everything already dealt with. Only the poster design shows it, and only
  /// as a number: a finished item is worth counting, not worth listing.
  final int doneCount;

  /// Everything dated beyond today. `next` is a capped preview of this; the
  /// stat cell has to say how many there really are or it is lying.
  final int upcomingCount;

  final DateTime now;

  /// Today, including anything already late. What the first stat cell counts.
  int get todayCount => overdue.length + today.length;

  bool get isEmpty => overdue.isEmpty && today.isEmpty && next.isEmpty;

  /// The single thing the header should shout about. Overdue beats today,
  /// today beats whatever is next; if there is genuinely nothing pressing,
  /// there is no poster and the screen stays calm.
  LifeItem? get focus {
    if (overdue.isNotEmpty) return overdue.first;
    if (today.isNotEmpty) return today.first;
    return null;
  }
}

final homeSnapshotProvider = FutureProvider.autoDispose<HomeSnapshot>((
  ref,
) async {
  final repository = ref.watch(lifeItemRepositoryProvider);

  // Any write anywhere in the app refreshes Home.
  final subscription = repository.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);

  final now = DateTime.now();
  final items = await repository.upcoming();
  final done = await repository.byStatus(LifeItemStatus.done);

  final overdue = <LifeItem>[];
  final today = <LifeItem>[];
  final next = <LifeItem>[];
  var weekCount = 0;
  var upcomingCount = 0;

  for (final item in items) {
    // A snoozed item is out of sight until its moment, and then it is back
    // without anything having to run in between.
    if (item.isHiddenAt(now)) continue;
    // Home answers "what matters right now", so an item with no date has no
    // place on it. The Upcoming timeline lists those under their own heading.
    final instant = item.primaryInstant?.toLocal();
    if (instant == null) continue;
    final bucket = TimeBucketing.of(instant, now);

    if (bucket == TimeBucket.today ||
        bucket == TimeBucket.tomorrow ||
        bucket == TimeBucket.thisWeek) {
      weekCount++;
    }

    switch (bucket) {
      case TimeBucket.overdue:
        overdue.add(item);
      case TimeBucket.today:
        today.add(item);
      default:
        upcomingCount++;
        if (next.length < 5) next.add(item);
    }
  }

  return HomeSnapshot(
    overdue: overdue,
    today: today,
    next: next,
    weekCount: weekCount,
    doneCount: done.length,
    upcomingCount: upcomingCount,
    now: now,
  );
});
