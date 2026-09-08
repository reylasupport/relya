import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/components/empty_state.dart';
import '../../../core/design/tokens/app_skin.dart';
import '../../../core/design/tokens/app_skin_style.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../application/upcoming_controller.dart';
import 'widgets/agenda_timeline.dart';
import 'widgets/day_agenda.dart';
import 'widgets/month_calendar.dart';
import 'widgets/upcoming_list.dart';

/// Two ways to look at the same thing.
///
/// Calendar answers "what does this month look like" and "what is on that
/// day"; List answers "what is coming up next". Home already answers "what is
/// important right now", so this screen deliberately does not repeat it.
class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // The poster design opens on the timeline and keeps the month grid behind
    // an icon; the others open on the month and offer the plain list.
    final agendaFirst = context.appSkin.upcomingStartsOnAgenda;
    var mode = ref.watch(upcomingViewModeProvider);
    if (agendaFirst && mode == UpcomingViewMode.calendar) {
      mode = UpcomingViewMode.agenda;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.upcomingTitle),
        actions: [
          if (agendaFirst)
            IconButton(
              tooltip: l10n.upcomingCalendar,
              onPressed: () =>
                  ref.read(upcomingViewModeProvider.notifier).state =
                      UpcomingViewMode.calendar,
              icon: const Icon(Icons.calendar_month_rounded),
            ),
          if (mode == UpcomingViewMode.calendar)
            TextButton(
              onPressed: () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                ref.read(selectedDayProvider.notifier).state = today;
                ref.read(visibleMonthProvider.notifier).state = DateTime(
                  today.year,
                  today.month,
                );
              },
              child: Text(l10n.upcomingJumpToToday),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageInset,
              0,
              AppSpacing.pageInset,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<UpcomingViewMode>(
                segments: [
                  ButtonSegment(
                    value: agendaFirst
                        ? UpcomingViewMode.agenda
                        : UpcomingViewMode.calendar,
                    label: Text(
                      agendaFirst ? l10n.upcomingAgenda : l10n.upcomingCalendar,
                    ),
                    icon: Icon(
                      agendaFirst
                          ? Icons.view_timeline_outlined
                          : Icons.calendar_month_rounded,
                      size: 18,
                    ),
                  ),
                  ButtonSegment(
                    value: UpcomingViewMode.list,
                    label: Text(l10n.upcomingList),
                    icon: const Icon(Icons.view_agenda_outlined, size: 18),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    ref.read(upcomingViewModeProvider.notifier).state =
                        selection.first,
              ),
            ),
          ),
        ),
      ),
      body: switch (mode) {
        UpcomingViewMode.calendar => const _CalendarView(),
        UpcomingViewMode.agenda => const AgendaTimeline(),
        UpcomingViewMode.list => const UpcomingList(),
      },
    );
  }
}

class _CalendarView extends ConsumerWidget {
  const _CalendarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(calendarDataProvider);
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDayProvider);

    return data.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.errorGeneric,
        message: context.l10n.errorNetwork,
        actionLabel: context.l10n.actionRetry,
        onAction: () => ref.invalidate(calendarDataProvider),
      ),
      data: (calendar) => ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
        children: [
          _MonthHeader(month: month),
          const SizedBox(height: AppSpacing.md),
          MonthCalendar(
            month: month,
            selected: selected,
            data: calendar,
            onSelect: (day) =>
                ref.read(selectedDayProvider.notifier).state = day,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          _SelectedDayHeader(day: selected),
          DayAgenda(day: selected, items: calendar.on(selected)),
        ],
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = DateFormat.yMMMM(context.localeTag).format(month);

    void shift(int months) {
      ref.read(visibleMonthProvider.notifier).state = DateTime(
        month.year,
        month.month + months,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // The month name is a proper noun in the locale, not a title.
              label[0].toUpperCase() + label.substring(1),
              style: context.text.headlineSmall,
            ),
          ),
          IconButton(
            onPressed: () => shift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: l10n.upcomingPreviousMonth,
          ),
          IconButton(
            onPressed: () => shift(1),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: l10n.upcomingNextMonth,
          ),
        ],
      ),
    );
  }
}

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    final label = DateFormat.MMMMEEEEd(context.localeTag).format(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.xl,
        AppSpacing.pageInset,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          isToday
              ? '${context.l10n.bucketToday}  ·  $label'
              : label[0].toUpperCase() + label.substring(1),
          style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
        ),
      ),
    );
  }
}
