import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept_kit.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';

final _entityItemsProvider = FutureProvider.autoDispose
    .family<List<LifeItem>, String>(
      (ref, entityId) =>
          ref.watch(lifeItemRepositoryProvider).byEntity(entityId),
    );

final _entityProvider = FutureProvider.autoDispose.family(
  (ref, String entityId) => ref.watch(entityRepositoryProvider).byId(entityId),
);

class EntityDetailScreen extends ConsumerWidget {
  const EntityDetailScreen({super.key, required this.entityId});

  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(_entityProvider(entityId));
    final items = ref.watch(_entityItemsProvider(entityId));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(entity.valueOrNull?.name ?? context.l10n.lifeTitle),
      ),
      body: items.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: context.l10n.errorGeneric,
          message: context.l10n.errorNetwork,
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_rounded,
              title: context.l10n.lifeEmptyTitle,
              message: context.l10n.lifeEmptyMessage,
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => context.kit.row(
              context,
              item: list[index],
              now: now,
              onTap: () => context.push(Routes.item(list[index].id)),
            ),
          );
        },
      ),
    );
  }
}
