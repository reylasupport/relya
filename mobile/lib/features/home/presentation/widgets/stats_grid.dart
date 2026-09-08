import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_skin_style.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Four numbers: today, upcoming, this week, done.
///
/// A count is a promise that the list underneath is complete. They are here
/// only in the poster design, where the hero says something about the week
/// rather than about one item, and the numbers are what make that claim
/// checkable.
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.today,
    required this.upcoming,
    required this.week,
    required this.done,
    this.onTodayTap,
    this.onUpcomingTap,
  });

  final int today;
  final int upcoming;
  final int week;
  final int done;
  final VoidCallback? onTodayTap;
  final VoidCallback? onUpcomingTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.lg,
        AppSpacing.pageInset,
        0,
      ),
      child: Row(
        children: [
          _Cell(
            icon: Icons.today_outlined,
            value: today,
            label: l10n.bucketToday,
            onTap: onTodayTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Cell(
            icon: Icons.schedule_rounded,
            value: upcoming,
            label: l10n.navUpcoming,
            onTap: onUpcomingTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Cell(
            icon: Icons.date_range_rounded,
            value: week,
            label: l10n.bucketThisWeek,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Cell(
            icon: Icons.check_circle_outline_rounded,
            value: done,
            label: l10n.statDone,
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.skin.control;

    return Expanded(
      child: Semantics(
        label: '$label: $value',
        button: onTap != null,
        child: Material(
          color: colors.surfaceContainer,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: context.semantic.subtleBorder),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 15, color: colors.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$value',
                    style: context.text.headlineSmall?.copyWith(height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
