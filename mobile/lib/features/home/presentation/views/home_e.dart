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

/// Concept E: the cheerful one.
///
/// A sunny greeting with a line of reassurance under it, the next thing on a
/// card filled with its own category colour, and lists whose rows each carry
/// their own tint. No assistant bar: this design puts its warmth into colour
/// rather than into a prompt.
class HomeE extends HomeView {
  const HomeE({
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
              padding: EdgeInsets.fromLTRB(kit.gutter, 14, kit.gutter - 6, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${greeting(context)}! ☀️',
                          style: kit.heading(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.homeGreetingSubtitle,
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  inboxBell(context),
                  avatar(context),
                ],
              ),
            ),
          ),
        ),
        if (focus != null)
          SliverToBoxAdapter(
            child: Entrance(child: _Highlight(item: focus)),
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

/// The next thing, on a card filled with its own colour and carrying its own
/// glyph on a tile. Bigger and softer than the other designs' hero.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.item});

  final LifeItem item;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final accent = context.accentFor(item.type);
    final start = item.primaryInstant?.toLocal();
    final when = start == null || item.allDay
        ? context.l10n.itemAllDay
        : AppDateFormat.range(start, item.endAt?.toLocal(), context.localeTag);
    final subtitle = item.organization ?? item.location;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kit.gutter),
      child: kit.card(
        context,
        tint: accent.withValues(alpha: context.isDark ? 0.22 : 0.16),
        onTap: () => context.push(Routes.item(item.id)),
        semanticLabel: item.title,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.text.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    when,
                    style: context.text.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            kit.glyph(context, type: item.type, size: 56),
          ],
        ),
      ),
    );
  }
}
