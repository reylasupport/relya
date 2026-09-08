import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/components/app_pill.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/capture.dart';

/// What a capture is called, and what colour that state is.
///
/// Shared because it is meaning, not decoration: green is done and amber
/// needs a look in all four designs, or the colour stops carrying anything.
({String label, Color foreground, Color background}) captureStatus(
  BuildContext context,
  Capture capture,
) {
  final l10n = context.l10n;
  final semantic = context.semantic;
  return switch (capture.status) {
    CaptureStatus.queued => (
      label: l10n.inboxStatusQueued,
      foreground: context.colors.onSurfaceVariant,
      background: context.colors.surfaceContainerHighest,
    ),
    CaptureStatus.processing => (
      label: l10n.inboxStatusProcessing,
      foreground: semantic.info,
      background: semantic.infoContainer,
    ),
    CaptureStatus.needsConfirmation => (
      label: l10n.foundNThings(capture.itemCount),
      foreground: semantic.warning,
      background: semantic.warningContainer,
    ),
    CaptureStatus.completed => (
      label: l10n.inboxStatusCompleted,
      foreground: semantic.success,
      background: semantic.successContainer,
    ),
    CaptureStatus.failed => (
      label: l10n.inboxStatusFailed,
      foreground: semantic.danger,
      background: semantic.dangerContainer,
    ),
    CaptureStatus.archived => (
      label: l10n.inboxStatusCompleted,
      foreground: context.colors.onSurfaceVariant,
      background: context.colors.surfaceContainerHighest,
    ),
  };
}

IconData captureIcon(Capture capture) => switch (capture.kind) {
  CaptureKind.image => Icons.image_outlined,
  CaptureKind.pdf => Icons.picture_as_pdf_outlined,
  CaptureKind.text => Icons.notes_rounded,
  CaptureKind.url => Icons.link_rounded,
};

/// Opens the confirmation screen for any capture that still has work left.
///
/// Restricting this to needsConfirmation left two dead ends in the Inbox. A
/// capture created on the server - a forwarded email - arrives queued and
/// nothing had ever analysed it, so the row sat there forever and could not be
/// tapped. A failed one had no way back either, even though the analysis
/// screen has always had a retry. Both open here now: the controller reuses a
/// cached analysis when there is one and runs the pipeline when there is not.
void openCapture(BuildContext context, Capture capture) {
  const openable = {
    CaptureStatus.needsConfirmation,
    CaptureStatus.queued,
    CaptureStatus.failed,
  };
  if (!openable.contains(capture.status)) return;
  context.push(Routes.analysis(capture.id));
}

/// The file-manifest row of Concept A: name on the left, clock on the right,
/// and what the AI did with it underneath in its own colour.
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.capture});

  final Capture capture;

  @override
  Widget build(BuildContext context) {
    final status = captureStatus(context, capture);
    final kit = context.kit;

    return Padding(
      padding: EdgeInsets.fromLTRB(kit.gutter, 3, kit.gutter, 3),
      child: kit.card(
        context,
        onTap: () => openCapture(context, capture),
        semanticLabel: capture.title,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: status.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                captureIcon(capture),
                size: 17,
                color: status.foreground,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title ?? context.l10n.captureTitle,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.label,
                    style: context.text.labelSmall?.copyWith(
                      color: status.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppDateFormat.time(
                capture.createdAt.toLocal(),
                context.localeTag,
              ),
              style: context.text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// The list row of the other three designs: a leading tile, the title, a
/// status pill and a date. Shape comes from the kit, so it is round and
/// tinted in the pastel design and square and flat in the cosy one.
class CaptureListRow extends StatelessWidget {
  const CaptureListRow({super.key, required this.capture, this.carded = false});

  final Capture capture;

  /// Whether the row is a card of its own. The pastel and cosy designs put
  /// every row on a surface; the clean one leaves them on the page.
  final bool carded;

  @override
  Widget build(BuildContext context) {
    final status = captureStatus(context, capture);
    final kit = context.kit;

    final content = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: status.background,
            borderRadius: BorderRadius.circular(carded ? 999 : 12),
          ),
          child: Icon(captureIcon(capture), size: 19, color: status.foreground),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capture.title ?? context.l10n.captureTitle,
                style: context.text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppPill(
                    label: status.label,
                    foreground: status.foreground,
                    background: status.background,
                  ),
                  Text(
                    AppDateFormat.dayMonth(
                      capture.createdAt.toLocal(),
                      context.localeTag,
                    ),
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (capture.status.isWorking)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );

    if (!carded) {
      return InkWell(
        onTap: () => openCapture(context, capture),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: kit.gutter, vertical: 12),
          child: content,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(kit.gutter, 4, kit.gutter, 4),
      child: kit.card(
        context,
        onTap: () => openCapture(context, capture),
        semanticLabel: capture.title,
        padding: const EdgeInsets.all(14),
        child: content,
      ),
    );
  }
}
