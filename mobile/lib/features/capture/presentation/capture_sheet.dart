import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../application/capture_controller.dart';

/// One way in, described five ways.
///
/// The Share Sheet is the main route into Relya; this is the fallback for
/// when the user is already inside the app. Three designs show it as a
/// bottom sheet of choices. Concept F shows it as a screen of its own, with
/// the three fast routes given real estate and the manual ones demoted to a
/// list underneath - which is the difference between "pick a source" and
/// "add something".
class CaptureAction {
  const CaptureAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// The second line. Only the designs with room show it.
  final String hint;
  final VoidCallback onTap;
}

List<CaptureAction> captureActions(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final controller = ref.read(captureControllerProvider);

  Future<void> run(Future<CaptureAttempt> Function() action) async {
    final navigator = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final parked = l10n.captureQueuedOffline;
    Navigator.of(context).pop();
    final attempt = await action();
    switch (attempt.outcome) {
      case CaptureOutcome.created:
        navigator.push(Routes.analysis(attempt.capture!.id));
      case CaptureOutcome.parked:
        // Nothing to confirm yet, so reassure instead of opening an empty
        // screen. The drainer will pick it up on the next connection.
        messenger.showSnackBar(SnackBar(content: Text(parked)));
      case CaptureOutcome.cancelled:
        break;
    }
  }

  void go(String route) {
    Navigator.of(context).pop();
    context.push(route);
  }

  return [
    CaptureAction(
      icon: Icons.edit_note_rounded,
      label: l10n.captureManual,
      hint: l10n.captureManualHint,
      onTap: () => go(Routes.captureManual),
    ),
    CaptureAction(
      icon: Icons.document_scanner_rounded,
      label: l10n.captureScanDocument,
      hint: l10n.captureScanHint,
      onTap: () => run(controller.fromCamera),
    ),
    CaptureAction(
      icon: Icons.photo_library_rounded,
      label: l10n.captureFromLibrary,
      hint: l10n.captureLibraryHint,
      onTap: () => run(controller.fromLibrary),
    ),
    CaptureAction(
      icon: Icons.playlist_add_rounded,
      label: l10n.quickAddAction,
      hint: l10n.quickAddActionHint,
      onTap: () => go(Routes.captureQuickAdd),
    ),
    CaptureAction(
      icon: Icons.content_paste_rounded,
      label: l10n.capturePasteText,
      hint: l10n.capturePasteHint,
      onTap: () => go(Routes.captureText),
    ),
    CaptureAction(
      icon: Icons.attach_file_rounded,
      label: l10n.captureUploadFile,
      hint: l10n.captureFileHint,
      onTap: () => run(controller.fromFile),
    ),
  ];
}

class CaptureSheet extends ConsumerWidget {
  const CaptureSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = captureActions(context, ref);
    return switch (context.concept) {
      Concept.f => _CaptureFullScreen(actions: actions),
      Concept.a => _CaptureSheetA(actions: actions),
      _ => _CaptureSheetSoft(actions: actions),
    };
  }
}

/// Concepts D and E: a friendly list of choices on a rounded sheet.
class _CaptureSheetSoft extends StatelessWidget {
  const _CaptureSheetSoft({required this.actions});

  final List<CaptureAction> actions;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(kit.gutter - 6, 10, kit.gutter - 6, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
              child: Text(
                context.l10n.captureTitle,
                style: context.text.headlineSmall,
              ),
            ),
            for (final action in actions)
              _SheetRow(action: action, showHint: false),
          ],
        ),
      ),
    );
  }
}

/// Concept A: a dark sheet that explains itself, with a square icon tile per
/// route and an explicit way out.
class _CaptureSheetA extends StatelessWidget {
  const _CaptureSheetA({required this.actions});

  final List<CaptureAction> actions;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(kit.gutter, 12, kit.gutter, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.captureSheetTitle, style: context.text.headlineSmall),
            const SizedBox(height: 2),
            Text(l10n.captureSheetSubtitle, style: context.text.bodyMedium),
            const SizedBox(height: 14),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: kit.card(
                  context,
                  onTap: action.onTap,
                  semanticLabel: action.label,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          action.icon,
                          size: 17,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(action.label, style: context.text.titleSmall),
                            Text(
                              action.hint,
                              style: context.text.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Concept F: a screen, not a sheet.
///
/// The three fast routes get a large circle each and a line of explanation;
/// the manual ones are demoted to a quiet list underneath. That hierarchy is
/// the design's opinion: most of what goes into Relya is a photo of something
/// that already exists, and typing is the exception.
class _CaptureFullScreen extends StatelessWidget {
  const _CaptureFullScreen({required this.actions});

  final List<CaptureAction> actions;

  static const _circleTones = [
    Color(0xFF9B8CFF),
    Color(0xFF8FBFA3),
    Color(0xFFD9A45B),
  ];

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final l10n = context.l10n;
    final fast = actions.take(3).toList();
    final manual = actions.skip(3).toList();

    return Scaffold(
      body: kit.page(
        context,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(kit.gutter, 4, kit.gutter, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionCancel,
                  ),
                  const SizedBox(width: 4),
                  Text(l10n.captureTitle, style: kit.heading(context)),
                ],
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < fast.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: kit.card(
                    context,
                    onTap: fast[i].onTap,
                    semanticLabel: fast[i].label,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _circleTones[i].withValues(alpha: 0.24),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            fast[i].icon,
                            size: 22,
                            color: _circleTones[i],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fast[i].label,
                                style: context.text.titleMedium,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                fast[i].hint,
                                style: context.text.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              kit.sectionHeader(context, title: l10n.captureManualSection),
              for (final action in manual)
                _SheetRow(action: action, showHint: false),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain choice: icon, label, and the hint where the design wants one.
class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.action, required this.showHint});

  final CaptureAction action;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          child: Row(
            children: [
              Icon(action.icon, size: 21, color: context.colors.primary),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.label, style: context.text.bodyLarge),
                    if (showHint)
                      Text(action.hint, style: context.text.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
