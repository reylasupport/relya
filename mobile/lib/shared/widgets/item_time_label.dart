import 'package:flutter/material.dart';

import '../../core/design/tokens/app_semantic_colors.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/formatting/app_date_format.dart';
import '../../core/formatting/time_bucket.dart';
import '../domain/life_item.dart';

/// The one line of time information a row shows, plus the colour it earns.
///
/// Deadlines read as "3 days left" because that is the number the user acts on;
/// appointments read as a clock time because that is what they need to be
/// somewhere. Same widget, two different questions.
class ItemTimeLabel {
  const ItemTimeLabel({required this.text, required this.colour});

  final String text;
  final Color? colour;

  static ItemTimeLabel of(BuildContext context, LifeItem item, DateTime now) {
    final l10n = context.l10n;
    final semantic = context.semantic;
    final locale = context.localeTag;

    final instant = item.primaryInstant?.toLocal();
    if (instant == null) {
      return const ItemTimeLabel(text: '', colour: null);
    }

    final bucket = TimeBucketing.of(instant, now);
    final days = AppDateFormat.calendarDaysBetween(now, instant);

    // Anything measured in days is about a deadline; anything today is about
    // a clock.
    if (bucket == TimeBucket.overdue) {
      return ItemTimeLabel(
        text: l10n.overdueByDays(-days),
        colour: semantic.danger,
      );
    }

    if (item.type.isDeadlineDriven ||
        item.deadlineAt != null && item.startAt == null) {
      final colour = switch (bucket) {
        TimeBucket.today || TimeBucket.tomorrow => semantic.warning,
        TimeBucket.thisWeek => semantic.warning,
        _ => null,
      };
      return ItemTimeLabel(text: l10n.daysLeft(days), colour: colour);
    }

    if (bucket == TimeBucket.today) {
      return ItemTimeLabel(
        text: AppDateFormat.range(instant, item.endAt?.toLocal(), locale),
        colour: null,
      );
    }

    if (bucket == TimeBucket.tomorrow) {
      return ItemTimeLabel(
        text: '${l10n.bucketTomorrow} ${AppDateFormat.time(instant, locale)}',
        colour: null,
      );
    }

    return ItemTimeLabel(
      text: AppDateFormat.dateAndTime(instant, locale),
      colour: null,
    );
  }
}
