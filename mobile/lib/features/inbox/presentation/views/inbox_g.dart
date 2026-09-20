import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/concept/kit_g.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/capture.dart';
import '../../application/inbox_controller.dart';
import 'capture_rows.dart';
import 'inbox_filters.dart';

/// Concept G: one raised panel holding the whole list.
///
/// The rows do not each get a card - twelve cards is twelve planes and no
/// hierarchy at all. They share one, and what separates them is a hairline
/// that exists only inside it. The panel is the object; the rows are its
/// contents.
class InboxG extends StatelessWidget {
  const InboxG({
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
          padding: EdgeInsets.fromLTRB(kit.gutter + 6, 10, kit.gutter - 4, 4),
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(kit.gutter, 8, kit.gutter, 130),
            children: [
              KitG.panel(
                context,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == items.length - 1
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: context.colors.outlineVariant,
                                  ),
                                ),
                        ),
                        child: CaptureListRow(capture: items[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
