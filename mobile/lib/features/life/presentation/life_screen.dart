import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/design/tokens/type_palette.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../../../shared/data/providers.dart';
import '../../../core/design/illustrations/life_still_life.dart';
import '../../../shared/domain/life_entity.dart';

final entitiesProvider = FutureProvider.autoDispose<List<LifeEntity>>(
  (ref) => ref.watch(entityRepositoryProvider).all(),
);

/// The Life Graph, shown as plain groups. The user never sees the word entity,
/// or the relationships underneath (spec section 43).
///
/// All four designs draw a grid here, and all four draw it differently: the
/// clean one keeps the cards white and colours only the icon, the pastel one
/// fills each card with its category, the cosy one darkens that fill into
/// olive and bronze, and the poster one keeps them tight and translucent.
class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(entitiesProvider);
    final kit = context.kit;

    return Scaffold(
      body: kit.page(
        context,
        child: SafeArea(
          bottom: false,
          child: entities.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            error: (error, _) => kit.empty(
              context,
              icon: Icons.cloud_off_rounded,
              title: context.l10n.errorGeneric,
              message: context.l10n.errorNetwork,
              actionLabel: context.l10n.actionRetry,
              onAction: () => ref.invalidate(entitiesProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return kit.empty(
                  context,
                  icon: Icons.category_rounded,
                  title: context.l10n.lifeEmptyTitle,
                  message: context.l10n.lifeEmptyMessage,
                );
              }
              return _Grid(items: items);
            },
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items});

  final List<LifeEntity> items;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final concept = context.concept;
    final odd = items.length.isOdd;
    final gridCount = concept == Concept.e && odd
        ? items.length - 1
        : items.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(kit.gutter, 12, kit.gutter, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.lifeTitle, style: kit.heading(context)),
                      if (concept == Concept.e) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.lifeSubtitle,
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                // A small still life beside the title: a cup, two books and a
                // plant. Only the pastel design decorates a header like this.
                // The cosy one puts a settings gear here instead, and the
                // other two leave it bare.
                if (concept == Concept.e) const LifeStillLife(height: 74),
                if (concept == Concept.f)
                  IconButton(
                    onPressed: () => context.push(Routes.settings),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: context.l10n.settingsTitle,
                  ),
              ],
            ),
          ),
        ),
        // An odd number of groups leaves a hole in a two-column grid. The
        // pastel design fills it by letting the last card run the full width;
        // the others leave the gap, which reads as deliberate on a denser
        // layout and as an accident on a soft one.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(kit.gutter, 8, kit.gutter, 12),
          sliver: SliverGrid.builder(
            // A fixed aspect ratio cannot hold a name and a count once the
            // user turns text up, and the card is what overflows. Height is
            // derived from the text scale instead, so the grid grows with the
            // type rather than clipping it.
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: concept == Concept.a ? 10 : 14,
              crossAxisSpacing: concept == Concept.a ? 10 : 14,
              mainAxisExtent: _cardHeight(context, concept),
            ),
            itemCount: gridCount,
            itemBuilder: (context, i) => _EntityCard(entity: items[i]),
          ),
        ),
        if (gridCount < items.length)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kit.gutter),
              child: SizedBox(
                height: 60 + 40 * MediaQuery.textScalerOf(context).scale(1),
                child: _EntityCard(entity: items.last, wide: true),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

/// How tall a group card needs to be at the current text size.
///
/// The dense design packs them shorter, and both grow with Dynamic Type.
double _cardHeight(BuildContext context, Concept concept) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final base = concept == Concept.a ? 104.0 : 126.0;
  return base + (scale - 1) * 78;
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.entity, this.wide = false});

  final LifeEntity entity;

  /// The full-width variant lays the same parts out in a row instead of a
  /// column, because a wide card with a tall stack in it looks empty.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final concept = context.concept;
    final accent = context.accentForEntity(entity.type);

    // Who fills the card and who only tints the icon is the difference
    // between a colourful grid and a quiet one.
    final filled = concept == Concept.e || concept == Concept.f;
    final fill = switch (concept) {
      Concept.e => accent.withValues(alpha: context.isDark ? 0.22 : 0.14),
      Concept.f => accent.withValues(alpha: 0.14),
      _ => null,
    };

    return kit.card(
      context,
      tint: fill,
      onTap: () => context.push(Routes.entity(entity.id)),
      semanticLabel: entity.name,
      padding: EdgeInsets.all(concept == Concept.a ? 13 : 16),
      child: Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: wide
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisAlignment: wide
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: concept == Concept.a ? 32 : 40,
            height: concept == Concept.a ? 32 : 40,
            decoration: BoxDecoration(
              color: filled
                  ? context.colors.surfaceContainerLowest.withValues(
                      alpha: context.isDark ? 0.30 : 0.85,
                    )
                  : accent.withValues(alpha: context.isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(
                concept == Concept.e ? 999 : 12,
              ),
            ),
            child: Icon(
              entity.type.icon,
              size: concept == Concept.a ? 16 : 20,
              color: accent,
            ),
          ),
          if (wide) const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entity.name,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.lifeItemsCount(entity.itemCount),
                  style: context.text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
