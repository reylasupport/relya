import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/outbox/outbox_providers.dart';

/// "2 waiting for a connection."
///
/// The outbox is invisible when it is empty, which is almost always. It shows
/// up only to answer the question a user has the moment they share something
/// on a train: did that work? Tapping it tries again immediately rather than
/// waiting for the network to announce itself.
class OutboxBanner extends ConsumerWidget {
  const OutboxBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(outboxCountProvider);
    if (waiting == 0) return const SizedBox.shrink();

    final kit = context.kit;
    return Padding(
      padding: EdgeInsets.fromLTRB(kit.gutter, 4, kit.gutter, 8),
      child: kit.card(
        context,
        onTap: () => ref.read(outboxDrainerProvider).drain(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.outboxWaiting(waiting),
                style: context.text.bodyMedium,
              ),
            ),
            Text(
              context.l10n.actionRetry,
              style: context.text.labelMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
