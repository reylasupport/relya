import 'package:flutter/material.dart';

import '../../../../core/design/concept/concept.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../shared/domain/life_item.dart';

/// The one thing that matters most, right now.
///
/// Every other row on Home is a list item; this is a poster. It exists because
/// the honest answer to "what is important in my life now" is usually a single
/// thing, and burying it in a list of eight makes the user do the triage the
/// app was supposed to do for them.
///
/// The clean design tints it with the **brand** colour and puts a small
/// calendar beside it; the cosy design tints it with the item's own category
/// and sets the title in serif. Same card, two different claims about what
/// the colour means.
class FocusCard extends StatelessWidget {
  const FocusCard({
    super.key,
    required this.item,
    required this.now,
    this.onTap,
  });

  final LifeItem item;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final brandTinted = context.concept == Concept.d;
    final accent = brandTinted
        ? context.colors.primary
        : context.accentFor(item.type);
    final dark = context.isDark;

    final start = item.primaryInstant?.toLocal();
    final detail = [
      if (start != null && !item.allDay)
        AppDateFormat.range(start, item.endAt?.toLocal(), context.localeTag),
      if (item.location != null) item.location!,
      if (item.organization != null && item.location == null)
        item.organization!,
    ].join('  ·  ');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kit.gutter),
      child: kit.card(
        context,
        onTap: onTap,
        semanticLabel: item.title,
        tint: accent.withValues(alpha: dark ? 0.22 : 0.14),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(item.type.icon, size: 15, color: accent),
                      const SizedBox(width: 7),
                      Text(
                        _eyebrow(context).toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: kit.display(context).copyWith(fontSize: 23),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(detail, style: context.text.bodyLarge),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // The clean design shows a little calendar; the others show the
            // chevron, because their card is already carrying a category
            // colour and a second graphic would be one thing too many.
            if (brandTinted)
              _CalendarBlock(day: start ?? now, accent: accent)
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  /// Which day, in the fewest words that are still true.
  String _eyebrow(BuildContext context) {
    final l10n = context.l10n;
    final instant = item.primaryInstant?.toLocal();
    if (instant == null) return l10n.bucketToday;

    final days = AppDateFormat.calendarDaysBetween(now, instant);
    if (days < 0) return l10n.overdueByDays(-days);
    if (item.type.isDeadlineDriven) return l10n.daysLeft(days);
    return switch (days) {
      0 => l10n.bucketToday,
      1 => l10n.bucketTomorrow,
      _ => l10n.daysLeft(days),
    };
  }
}

/// A tear-off calendar page: month band, day number, weekday.
///
/// Drawn with widgets rather than an icon because the date has to be the real
/// one - a generic calendar glyph beside a real appointment reads as a stock
/// illustration, which is exactly the feeling this design avoids.
class _CalendarBlock extends StatelessWidget {
  const _CalendarBlock({required this.day, required this.accent});

  final DateTime day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final locale = context.localeTag;
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              AppDateFormat.monthShort(day, locale).toUpperCase(),
              textAlign: TextAlign.center,
              style: context.text.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
            child: Column(
              children: [
                Text(
                  '${day.day}',
                  style: context.text.headlineSmall?.copyWith(height: 1),
                ),
                Text(
                  AppDateFormat.weekdayShort(day, locale),
                  style: context.text.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
