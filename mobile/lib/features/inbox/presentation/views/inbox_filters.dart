import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../application/inbox_controller.dart';

/// All / To handle / Done.
///
/// Two shapes: a segmented control fused into one block, which is what the
/// poster design uses, and separate pills, which is what the other three use.
/// Same three choices either way.
class InboxFilters extends ConsumerWidget {
  const InboxFilters({super.key, required this.counts, this.fused = false});

  final Map<InboxFilter, int> counts;
  final bool fused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(inboxFilterProvider);
    final kit = context.kit;
    final l10n = context.l10n;

    String label(InboxFilter f) => switch (f) {
      InboxFilter.all => l10n.inboxFilterAll,
      InboxFilter.pending => l10n.inboxFilterPending,
      InboxFilter.done => l10n.inboxFilterDone,
    };

    Widget one(InboxFilter f) {
      final selected = f == active;
      final count = counts[f] ?? 0;
      return _Segment(
        label: label(f),
        count: f == InboxFilter.done ? null : count,
        selected: selected,
        fused: fused,
        onTap: () => ref.read(inboxFilterProvider.notifier).state = f,
      );
    }

    final children = InboxFilter.values.map(one).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(kit.gutter, 4, kit.gutter, 10),
      child: fused
          ? Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Row(
                children: [for (final c in children) Expanded(child: c)],
              ),
            )
          // Scrolls rather than wraps: three filters on two lines reads as
          // a layout accident, and at 1.6x text they do not fit on one line.
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in children)
                    Padding(padding: const EdgeInsets.only(right: 8), child: c),
                ],
              ),
            ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.fused,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final bool fused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(fused ? 9 : 999);
    final fg = selected
        ? (fused ? Colors.white : context.colors.primary)
        : context.colors.onSurfaceVariant;

    return Material(
      color: selected
          ? (fused
                ? context.colors.primary
                : context.colors.primary.withValues(alpha: 0.12))
          : Colors.transparent,
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Container(
          decoration: selected || fused
              ? null
              : BoxDecoration(
                  borderRadius: shape,
                  border: Border.all(color: context.colors.outlineVariant),
                ),
          padding: EdgeInsets.symmetric(
            horizontal: fused ? 8 : 15,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: context.text.labelSmall?.copyWith(
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
