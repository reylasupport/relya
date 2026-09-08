import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/capture.dart';
import '../../application/inbox_controller.dart';
import 'capture_rows.dart';
import 'inbox_filters.dart';

/// Concept D: a plain list with dividers.
///
/// The most ordinary rendering of the same data, on purpose. Rows sit on the
/// page rather than on cards, separated by hairlines, which is the pattern
/// every mail and messaging app on the phone already uses.
class InboxD extends StatelessWidget {
  const InboxD({
    super.key,
    required this.items,
    required this.counts,
    required this.empty,
  });

  final List<Capture> items;
  final Map<InboxFilter, int> counts;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    if (empty != null) return empty!;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(kit.gutter, 10, kit.gutter - 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.inboxTitle,
                  style: kit.heading(context),
                ),
              ),
              IconButton(
                onPressed: () => context.push(Routes.search),
                icon: const Icon(Icons.search_rounded),
                tooltip: context.l10n.searchTitle,
              ),
            ],
          ),
        ),
        InboxFilters(counts: counts),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: kit.gutter + 53,
              endIndent: kit.gutter,
              color: context.colors.outlineVariant,
            ),
            itemBuilder: (context, i) => CaptureListRow(capture: items[i]),
          ),
        ),
      ],
    );
  }
}
