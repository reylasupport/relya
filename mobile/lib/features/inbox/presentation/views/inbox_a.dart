import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/capture.dart';
import '../../application/inbox_controller.dart';
import 'capture_rows.dart';
import 'inbox_filters.dart';

/// Concept A: the processing queue.
///
/// This design treats the inbox as a manifest of files the AI has been
/// through, grouped by the day they arrived, each one saying what came of it.
/// Search and filter live in the header because a queue is something you
/// interrogate.
class InboxA extends StatelessWidget {
  const InboxA({
    super.key,
    required this.items,
    required this.counts,
    required this.empty,
  });

  final List<Capture> items;
  final Map<InboxFilter, int> counts;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    if (empty != null) return empty!;

    final groups = <String, List<Capture>>{};
    final now = DateTime.now();
    for (final capture in items) {
      final at = capture.createdAt.toLocal();
      final days = AppDateFormat.calendarDaysBetween(now, at);
      final key = switch (days) {
        0 => context.l10n.bucketToday,
        -1 => context.l10n.bucketYesterday,
        _ => AppDateFormat.dayMonth(at, context.localeTag),
      };
      groups.putIfAbsent(key, () => []).add(capture);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(kit.gutter, 8, kit.gutter - 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.inboxTitle,
                    style: kit.heading(context),
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(Routes.search),
                  icon: const Icon(Icons.search_rounded),
                  tooltip: context.l10n.searchTitle,
                ),
                const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: InboxFilters(counts: counts, fused: true)),
        for (final entry in groups.entries) ...[
          SliverToBoxAdapter(
            child: kit.sectionHeader(context, title: entry.key),
          ),
          SliverList.builder(
            itemCount: entry.value.length,
            itemBuilder: (context, i) => FileRow(capture: entry.value[i]),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
