import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/entrance.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/concept/kit_g.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/life_item.dart';
import '../widgets/focus_card.dart';
import 'home_common.dart';

/// Concept G: soft depth.
///
/// Three planes and nothing else. The next thing sits highest, on the biggest
/// shadow; the four counts sit lower, on small ones; everything after that
/// lies almost flat. Reading the screen is reading the elevation, which is
/// why there is not a single rule or border anywhere on it.
class HomeG extends HomeView {
  const HomeG({
    super.key,
    required super.data,
    required super.profile,
    required super.pending,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final focus = data.focus;
    final rest = [
      ...data.overdue.where((i) => i.id != focus?.id),
      ...data.today.where((i) => i.id != focus?.id),
      ...data.next,
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(kit.gutter + 6, 14, kit.gutter, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateFormat.weekdayAndDay(
                            DateTime.now(),
                            context.localeTag,
                          ),
                          style: context.text.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          greeting(context),
                          style: kit.heading(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
            padding: EdgeInsets.fromLTRB(kit.gutter, 12, kit.gutter, 0),
            child: _Counts(
              active: data.upcomingCount,
              pending: pending,
              week: data.weekCount,
              done: data.doneCount,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: AskBar(gutter: kit.gutter),
          ),
        ),

        if (rest.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: kit.sectionHeader(
              context,
              title: context.l10n.bucketLater,
              count: rest.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kit.gutter),
              child: KitG.panel(
                context,
                child: Column(
                  children: [
                    for (var i = 0; i < rest.length && i < 6; i++)
                      Entrance(
                        index: i,
                        child: _FlatRow(
                          item: rest[i],
                          now: data.now,
                          last: i == rest.length - 1 || i == 5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 130)),
      ],
    );
  }
}

/// Four numbers on their own small planes.
class _Counts extends StatelessWidget {
  const _Counts({
    required this.active,
    required this.pending,
    required this.week,
    required this.done,
  });

  final int active;
  final int pending;
  final int week;
  final int done;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        _Count(value: active, label: l10n.navUpcoming),
        const SizedBox(width: 10),
        _Count(value: pending, label: l10n.bucketToday, accent: true),
        const SizedBox(width: 10),
        _Count(value: week, label: l10n.bucketThisWeek),
        const SizedBox(width: 10),
        _Count(value: done, label: l10n.statDone),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, this.accent = false});

  final int value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (context.isDark ? Colors.black : const Color(0xFF111520))
                  .withValues(alpha: context.isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: accent
                    ? context.semantic.accentText
                    : context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row inside a panel: no card of its own, because the panel is the plane.
class _FlatRow extends StatelessWidget {
  const _FlatRow({required this.item, required this.now, required this.last});

  final LifeItem item;
  final DateTime now;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final at = item.primaryInstant?.toLocal();
    return InkWell(
      onTap: () => context.push(Routes.item(item.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.semantic.subtleBorder),
                ),
              ),
        child: Row(
          children: [
            context.kit.glyph(context, type: item.type, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (at != null) ...[
              const SizedBox(width: 10),
              Text(
                AppDateFormat.dayMonth(at, context.localeTag),
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
