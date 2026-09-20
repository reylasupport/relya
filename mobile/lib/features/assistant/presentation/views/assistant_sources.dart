import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/data/providers.dart';
import '../../../../shared/domain/life_item.dart';

/// The items an answer was built from.
///
/// A family keyed on the ids joined with a comma, because a List is not a
/// usable family key - two equal lists are two different keys, and the screen
/// would refetch on every rebuild.
final citedItemsProvider = FutureProvider.autoDispose
    .family<List<LifeItem>, String>((ref, key) async {
      final repository = ref.watch(lifeItemRepositoryProvider);
      final ids = key.split(',').where((id) => id.isNotEmpty);
      final items = <LifeItem>[];
      for (final id in ids) {
        final item = await repository.byId(id);
        // An answer can cite something the user deleted in the meantime.
        // Dropping it silently is right: the sentence it supports is still
        // true of the moment it was asked, and a dead chip is worse than one
        // chip fewer.
        if (item != null) items.add(item);
      }
      return items;
    });

/// The strip of sources under an assistant answer.
///
/// The assistant is only allowed to say things it can point at, and until now
/// it pointed at them privately: the ids came down with every answer and the
/// screen threw them away. Showing them is what turns "you have two payments
/// this week" from a claim into something the user can check in one tap.
class AssistantSources extends ConsumerWidget {
  const AssistantSources({super.key, required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(citedItemsProvider(itemIds.join(','))).valueOrNull;
    // While they load, and if every one of them is gone, there is nothing to
    // say - the answer above already stands on its own.
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.assistantSources.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            hint: context.l10n.assistantSourcesHint,
            explicitChildNodes: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final item in items) _SourceChip(item: item)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.item});

  final LifeItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.item(item.id)),
        child: ConstrainedBox(
          // Long enough to read, short enough that three of them do not become
          // three paragraphs stacked under one sentence.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.62,
            // The chip is the tap target, so it carries the whole of it.
            minHeight: 48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                context.kit.glyph(context, type: item.type, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.north_east_rounded,
                  size: 14,
                  color: context.semantic.accentText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
