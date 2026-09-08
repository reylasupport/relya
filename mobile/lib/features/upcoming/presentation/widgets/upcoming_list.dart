import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/time_bucket.dart';
import '../../../../navigation/routes.dart';
import '../../../../navigation/app_shell.dart';
import '../../application/upcoming_controller.dart';

/// The linear view: everything ahead, grouped by urgency. Useful when the
/// question is "what is next" rather than "what is on the 14th".
class UpcomingList extends ConsumerWidget {
  const UpcomingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(upcomingProvider);
    final now = DateTime.now();

    return sections.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      error: (error, _) => context.kit.empty(
        context,
        icon: Icons.cloud_off_rounded,
        title: context.l10n.errorGeneric,
        message: context.l10n.errorNetwork,
        actionLabel: context.l10n.actionRetry,
        onAction: () => ref.invalidate(upcomingProvider),
      ),
      data: (data) {
        if (data.isEmpty) {
          return context.kit.empty(
            context,
            icon: Icons.event_note_rounded,
            title: context.l10n.upcomingEmptyTitle,
            message: context.l10n.upcomingEmptyMessage,
            actionLabel: context.l10n.captureTitle,
            onAction: () => openCaptureSheet(context),
          );
        }
        return CustomScrollView(
          slivers: [
            for (final section in data) ...[
              SliverToBoxAdapter(
                child: context.kit.sectionHeader(
                  context,
                  title: _label(context, section.bucket),
                  count: section.items.length,
                  onSeeAll: null,
                ),
              ),
              SliverList.builder(
                itemCount: section.items.length,
                itemBuilder: (context, index) {
                  final item = section.items[index];
                  return context.kit.row(
                    context,
                    item: item,
                    now: now,
                    onTap: () => context.push(Routes.item(item.id)),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxl * 2),
            ),
          ],
        );
      },
    );
  }

  String _label(BuildContext context, TimeBucket bucket) => switch (bucket) {
    TimeBucket.overdue => context.l10n.bucketOverdue,
    TimeBucket.today => context.l10n.bucketToday,
    TimeBucket.tomorrow => context.l10n.bucketTomorrow,
    TimeBucket.thisWeek => context.l10n.bucketThisWeek,
    TimeBucket.next30Days => context.l10n.bucketNext30Days,
    TimeBucket.later => context.l10n.bucketLater,
    TimeBucket.undated => context.l10n.bucketUndated,
  };
}
