import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/entrance.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/life_item.dart';
import '../widgets/focus_card.dart';
import 'home_common.dart';

/// Concept D: the conventional one.
///
/// Greeting, the date under it, the single next thing on a soft lavender
/// card, a line inviting a question, and then two plainly labelled lists with
/// a "see all" beside each. There is nothing clever here, and that is the
/// design: it should be readable by someone who has never used the app.
class HomeD extends HomeView {
  const HomeD({
    super.key,
    required super.data,
    required super.profile,
    required super.pending,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final focus = data.focus;
    final today = data.today.where((i) => i.id != focus?.id).toList();
    final overdue = data.overdue.where((i) => i.id != focus?.id).toList();
    var index = 0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(kit.gutter, 14, kit.gutter - 6, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${greeting(context)} 👋',
                          style: kit.heading(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppDateFormat.weekdayAndDay(
                            DateTime.now(),
                            context.localeTag,
                          ),
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  avatar(context),
                ],
              ),
            ),
          ),
        ),
        if (focus != null)
          SliverToBoxAdapter(
            child: Entrance(
              child: FocusCard(
                item: focus,
                now: data.now,
                onTap: () => context.push(Routes.item(focus.id)),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AskBar(gutter: kit.gutter),
          ),
        ),
        ..._section(
          context,
          context.l10n.bucketOverdue,
          overdue,
          () => index++,
        ),
        ..._section(context, context.l10n.bucketToday, today, () => index++),
        ..._section(
          context,
          context.l10n.bucketLater,
          data.next,
          () => index++,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<LifeItem> items,
    int Function() next,
  ) {
    if (items.isEmpty) return const [];
    final kit = context.kit;
    return [
      SliverToBoxAdapter(
        child: kit.sectionHeader(
          context,
          title: title,
          onSeeAll: () => context.go(Routes.upcoming),
        ),
      ),
      SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) => Entrance(
          index: next(),
          child: kit.row(
            context,
            item: items[i],
            now: data.now,
            onTap: () => context.push(Routes.item(items[i].id)),
          ),
        ),
      ),
    ];
  }
}
