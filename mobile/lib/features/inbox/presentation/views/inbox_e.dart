import 'package:flutter/material.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/domain/capture.dart';
import '../../application/inbox_controller.dart';
import 'capture_rows.dart';
import 'inbox_filters.dart';

/// Concept E: every capture on its own rounded card.
///
/// No dividers anywhere in this design - separation comes from the gap
/// between cards. The status colour fills the leading circle rather than
/// sitting in a pill beside it, so the list can be read by colour alone.
class InboxE extends StatelessWidget {
  const InboxE({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(kit.gutter, 12, kit.gutter, 4),
          child: Text(context.l10n.inboxTitle, style: kit.heading(context)),
        ),
        InboxFilters(counts: counts),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120, top: 2),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                CaptureListRow(capture: items[i], carded: true),
          ),
        ),
      ],
    );
  }
}
