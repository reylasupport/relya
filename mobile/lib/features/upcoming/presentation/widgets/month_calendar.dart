import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/tokens/app_durations.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/week_start.dart';
import '../../application/upcoming_controller.dart';

/// A month grid where each day carries the weight of what is on it.
///
/// The dots are the point: a person should be able to see, without reading
/// anything, that next Thursday is busy and that something is overdue. Colour
/// is never the only signal - the count is in the semantics label too.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.data,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final CalendarData data;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = context.localeTag;
    // Sunday-first in the United States, Monday-first in Portugal. Derived
    // from the region rather than from MaterialLocalizations, which gets
    // pt-PT and en-GB wrong.
    final firstWeekday = WeekStart.forLocaleTag(locale);

    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // DateTime.weekday is 1..7 with Monday=1; the grid index is 0..6.
    final leading = (firstOfMonth.weekday % 7 - firstWeekday + 7) % 7;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: [
        _WeekdayRow(firstWeekday: firstWeekday, locale: locale),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageInset - 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.82,
          ),
          itemCount: cells,
          itemBuilder: (context, index) {
            final dayNumber = index - leading + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(month.year, month.month, dayNumber);
            return _DayCell(
              day: day,
              data: data,
              isSelected: DateUtils.isSameDay(day, selected),
              isToday: DateUtils.isSameDay(day, data.now),
              onTap: () => onSelect(day),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.firstWeekday, required this.locale});

  final int firstWeekday;
  final String locale;

  @override
  Widget build(BuildContext context) {
    // Any known Monday, used only to read the seven localised initials.
    final monday = DateTime(2024, 1, 1);
    final format = DateFormat.E(locale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageInset - 4),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    format
                        .format(
                          monday.add(
                            Duration(days: (firstWeekday + i + 6) % 7),
                          ),
                        )
                        .substring(0, 1)
                        .toUpperCase(),
                    style: context.text.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.data,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final CalendarData data;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final items = data.on(day);
    final overdue = data.hasOverdue(day);

    final foreground = isSelected
        ? colors.onPrimary
        : isToday
        ? colors.primary
        : colors.onSurface;

    return Semantics(
      label: '${day.day}',
      value: context.l10n.lifeItemsCount(items.length),
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: context.text.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 3),
            _Dots(
              count: items.length,
              colour: overdue ? semantic.danger : colors.primary,
              muted: isSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three dots, then a plus. Counting past three at a glance is not
/// something anyone does, so the fourth dot would be decoration.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.colour, required this.muted});

  final int count;
  final Color colour;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: 5);
    final shown = count > 3 ? 3 : count;
    final tint = muted ? context.colors.primary : colour;

    return SizedBox(
      height: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < shown; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
