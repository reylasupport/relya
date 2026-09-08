import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/entrance.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../navigation/routes.dart';
import '../widgets/poster_card.dart';
import '../widgets/stats_grid.dart';
import 'home_common.dart';

/// Concept A: the dashboard.
///
/// A sentence about the week, four numbers that make that sentence checkable,
/// and then the list. This is the only design that opens with an aggregate
/// rather than with a single item, which is what makes it read as a product
/// that has already done some thinking.
class HomeA extends HomeView {
  const HomeA({
    super.key,
    required super.data,
    required super.profile,
    required super.pending,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                kit.gutter - 12,
                12,
                kit.gutter - 6,
                14,
              ),
              child: Row(
                children: [
                  // The concept puts a menu to the left of the greeting. It
                  // opens the two things that are not destinations - search
                  // and the account hub - rather than duplicating the avatar.
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: context.l10n.accountTitle,
                    onSelected: (value) => context.push(value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: Routes.search,
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 19),
                            const SizedBox(width: 10),
                            Text(context.l10n.searchTitle),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: Routes.settings,
                        child: Row(
                          children: [
                            const Icon(Icons.settings_outlined, size: 19),
                            const SizedBox(width: 10),
                            Text(context.l10n.settingsTitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Text(
                      greeting(context),
                      style: kit.heading(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  avatar(context),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Entrance(
            child: Column(
              children: [
                PosterCard(
                  weekCount: data.weekCount,
                  soonCount: data.todayCount,
                  onTap: () => context.go(Routes.upcoming),
                ),
                StatsGrid(
                  today: data.todayCount,
                  upcoming: data.upcomingCount,
                  week: data.weekCount,
                  done: data.doneCount,
                  onUpcomingTap: () => context.go(Routes.upcoming),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: kit.sectionHeader(
            context,
            title: context.l10n.homeNext,
            count: data.todayCount + data.next.length,
          ),
        ),
        SliverList.builder(
          itemCount: data.overdue.length + data.today.length + data.next.length,
          itemBuilder: (context, index) {
            final all = [...data.overdue, ...data.today, ...data.next];
            final item = all[index];
            return Entrance(
              index: index,
              child: kit.row(
                context,
                item: item,
                now: data.now,
                onTap: () => context.push(Routes.item(item.id)),
              ),
            );
          },
        ),
        if (data.upcomingCount > data.next.length)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kit.gutter),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => context.go(Routes.upcoming),
                  child: Text(
                    context.l10n.homeSeeAllUpcoming(data.upcomingCount),
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
