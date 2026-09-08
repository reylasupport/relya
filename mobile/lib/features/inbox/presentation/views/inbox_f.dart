import 'package:flutter/material.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/domain/capture.dart';
import '../../application/inbox_controller.dart';
import 'capture_rows.dart';
import 'inbox_filters.dart';

/// Concept F: the same list, set like a page.
///
/// A serif title, a count under it instead of beside it, and cards on a warm
/// dark surface. The difference from the pastel version is almost entirely
/// temperature and typography - which is the point of having both.
class InboxF extends StatelessWidget {
  const InboxF({
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
          padding: EdgeInsets.fromLTRB(kit.gutter, 14, kit.gutter, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.inboxTitle, style: kit.heading(context)),
              const SizedBox(height: 2),
              Text(
                context.l10n.foundNThings(counts[InboxFilter.all] ?? 0),
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
