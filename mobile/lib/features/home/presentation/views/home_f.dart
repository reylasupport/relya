import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/entrance.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/life_item.dart';
import 'home_common.dart';

/// Concept F: the editorial one.
///
/// A serif greeting, one olive card for the thing happening now, a quiet line
/// inviting a question, and small-caps section labels with a count on the
/// right. Nothing is bright; everything is warm. It should look like a page
/// rather than like a screen.
class HomeF extends HomeView {
  const HomeF({
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
    var index = 0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(kit.gutter, 16, kit.gutter - 6, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      greeting(context),
                      style: kit.heading(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  inboxBell(context, icon: Icons.notifications_none_rounded),
                  avatar(context),
                ],
              ),
            ),
          ),
        ),
        if (focus != null)
          SliverToBoxAdapter(
            child: Entrance(
              child: _OliveCard(item: focus, now: data.now),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: AskBar(gutter: kit.gutter, radius: 16),
          ),
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
        child: kit.sectionHeader(context, title: title, count: items.length),
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

/// The card for the thing happening now. Filled with a muted version of the
/// item's colour rather than outlined, and labelled in small caps above the
/// title - the layout of a magazine standfirst, not of a notification.
class _OliveCard extends StatelessWidget {
  const _OliveCard({required this.item, required this.now});

  final LifeItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final accent = context.accentFor(item.type);
    final start = item.primaryInstant?.toLocal();
    final when = start == null || item.allDay
        ? context.l10n.itemAllDay
        : AppDateFormat.range(start, item.endAt?.toLocal(), context.localeTag);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kit.gutter),
      child: kit.card(
        context,
        tint: accent.withValues(alpha: 0.18),
        onTap: () => context.push(Routes.item(item.id)),
        semanticLabel: item.title,
        padding: const EdgeInsets.all(18),
        child: Row(
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
                        context.l10n.bucketToday.toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: kit.display(context).copyWith(fontSize: 24),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(when, style: context.text.bodyLarge),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
