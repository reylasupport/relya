import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/empty_state.dart';
import '../../../../core/design/tokens/app_skin_style.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../navigation/app_shell.dart';
import '../../../../shared/domain/life_item.dart';
import '../../application/upcoming_controller.dart';

/// Everything ahead as one running day-by-day timeline.
///
/// The grouped list answers "how urgent is this"; the timeline answers "what
/// does Thursday look like". Same items, and the difference is the left rail:
/// a clock time and a dot per row, so the eye can walk down the day instead
/// of reading every title.
class AgendaTimeline extends ConsumerWidget {
  const AgendaTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(upcomingProvider);
    final now = DateTime.now();
    final locale = context.localeTag;

    return sections.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.errorGeneric,
        message: context.l10n.errorNetwork,
        actionLabel: context.l10n.actionRetry,
        onAction: () => ref.invalidate(upcomingProvider),
      ),
      data: (data) => _timeline(context, data, now, locale),
    );
  }
}

/// Regroups by calendar day. The urgency buckets exist for the other view; a
/// timeline that jumped from "this week" to "later" would be lying about the
/// shape of the week.
Widget _timeline(
  BuildContext context,
  List<UpcomingSection> data,
  DateTime now,
  String locale,
) {
  final byDay = <DateTime, List<LifeItem>>{};
  for (final section in data) {
    for (final item in section.items) {
      final at = item.primaryInstant?.toLocal();
      if (at == null) continue;
      byDay
          .putIfAbsent(DateTime(at.year, at.month, at.day), () => [])
          .add(item);
    }
  }

  if (byDay.isEmpty) {
    return EmptyState(
      icon: Icons.event_note_rounded,
      title: context.l10n.upcomingEmptyTitle,
      message: context.l10n.upcomingEmptyMessage,
      actionLabel: context.l10n.captureTitle,
      onAction: () => openCaptureSheet(context),
    );
  }

  final days = byDay.keys.toList()..sort();
  final today = DateTime(now.year, now.month, now.day);

  return ListView.builder(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
    itemCount: days.length,
    itemBuilder: (context, index) {
      final day = days[index];
      final items = byDay[day]!;
      final diff = day.difference(today).inDays;
      final name = switch (diff) {
        0 => context.l10n.bucketToday,
        1 => context.l10n.bucketTomorrow,
        _ => AppDateFormat.weekday(day, locale),
      };
      final heading =
          '${name.toUpperCase()}  ·  '
          '${AppDateFormat.dayAndMonthName(day, locale).toUpperCase()}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageInset,
              AppSpacing.xl,
              AppSpacing.pageInset,
              AppSpacing.sm,
            ),
            child: Text(
              heading,
              style: context.text.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: diff == 0
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in items) _AgendaRow(item: item, locale: locale),
        ],
      );
    },
  );
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.item, required this.locale});

  final LifeItem item;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentFor(item.type);
    final at = item.primaryInstant?.toLocal();
    final time = at == null || item.allDay
        ? context.l10n.itemAllDay
        : AppDateFormat.time(at, locale);
    final subtitle = item.location ?? item.organization;

    return InkWell(
      onTap: () => context.push(Routes.item(item.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageInset,
          vertical: 5,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                time,
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _Body(item: item, accent: accent, sub: subtitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.accent, this.sub});

  final LifeItem item;
  final Color accent;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: context.skin.control,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.accentContainerFor(item.type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.type.icon, size: 16, color: accent),
          ),
        ],
      ),
    );
  }
}
