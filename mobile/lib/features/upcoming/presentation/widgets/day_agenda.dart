import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/app_durations.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/life_item.dart';

/// What is actually on the selected day, on a vertical rail.
///
/// The rail is what makes this read as a day rather than as another list:
/// times run down the left, and an all-day item sits at the top without a
/// time rather than being given a fake one.
class DayAgenda extends StatelessWidget {
  const DayAgenda({super.key, required this.day, required this.items});

  final DateTime day;
  final List<LifeItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: AppDurations.curve,
      child: items.isEmpty
          ? Padding(
              key: ValueKey('empty-$day'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageInset,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 28,
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.upcomingNothingOnDay,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.upcomingNothingOnDayHint,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            )
          : Column(
              key: ValueKey('day-$day-${items.length}'),
              children: [for (final item in items) _AgendaRow(item: item)],
            ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.item});

  final LifeItem item;

  @override
  Widget build(BuildContext context) {
    final locale = context.localeTag;
    final start = item.startAt?.toLocal();

    // A deadline has no clock time worth showing; a dash keeps the rail
    // aligned without inventing an hour the document never gave us.
    final timeLabel = item.allDay || start == null
        ? '--:--'
        : AppDateFormat.time(start, locale);

    // Same colour language as every other list in the app: the kind of thing
    // decides the hue, so the eye can sort a day before reading it.
    final accent = context.accentFor(item.type);

    return InkWell(
      onTap: () => context.push(Routes.item(item.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageInset,
          vertical: AppSpacing.sm,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    timeLabel,
                    style: context.text.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: AppSpacing.md),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm - 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.text.titleMedium),
                      if (item.description != null ||
                          item.location != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description ?? item.location!,
                          style: context.text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(item.type.icon, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
