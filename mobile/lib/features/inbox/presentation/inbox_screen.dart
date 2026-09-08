import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/data/repositories/capture_repository.dart';
import '../../../shared/domain/capture.dart';
import '../application/inbox_controller.dart';
import 'views/inbox_a.dart';
import 'views/outbox_banner.dart';
import 'views/inbox_d.dart';
import 'views/inbox_e.dart';
import 'views/inbox_f.dart';

/// Everything that has been sent in, and what state it is in.
///
/// The designs disagree about what this screen is. The poster design treats
/// it as a processing queue - a file manifest with states; the other three
/// treat it as a list of things you sent, and say so more gently.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captures = ref.watch(inboxProvider);
    final filter = ref.watch(inboxFilterProvider);
    final kit = context.kit;

    return Scaffold(
      body: kit.page(
        context,
        child: SafeArea(
          bottom: false,
          child: captures.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            error: (error, _) => kit.empty(
              context,
              icon: Icons.cloud_off_rounded,
              title: context.l10n.errorGeneric,
              message: context.l10n.errorNetwork,
              actionLabel: context.l10n.actionRetry,
              onAction: () => ref.invalidate(inboxProvider),
            ),
            data: (all) {
              final counts = {
                for (final f in InboxFilter.values) f: all.matching(f).length,
              };
              final items = all.matching(filter);
              final empty = all.isEmpty
                  ? kit.empty(
                      context,
                      icon: Icons.inbox_rounded,
                      title: context.l10n.inboxEmptyTitle,
                      message: context.l10n.inboxEmptyMessage,
                      actionLabel: context.l10n.inboxTryExample,
                      onAction: () => runInboxDemo(context, ref),
                    )
                  : null;

              final view = switch (context.concept) {
                Concept.a => InboxA(items: items, counts: counts, empty: empty),
                Concept.d => InboxD(items: items, counts: counts, empty: empty),
                Concept.e => InboxE(items: items, counts: counts, empty: empty),
                Concept.f => InboxF(items: items, counts: counts, empty: empty),
              };
              // "Nothing here" and "two things are waiting for a network" are
              // both true at once offline, so the banner sits above the view
              // rather than inside it.
              return Column(
                children: [
                  const OutboxBanner(),
                  Expanded(child: view),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Runs the built-in example so a new user reaches the moment that sells the
/// product without having to find a real document first (spec section 64).
Future<void> runInboxDemo(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(captureRepositoryProvider);
  final capture = await repository.enqueue(
    const CaptureDraft(
      source: CaptureSource.demo,
      kind: CaptureKind.text,
      title: 'Example message',
      text: 'Consulta de dentista dia 17 de setembro as 15:30.',
    ),
  );
  if (!context.mounted) return;
  context.push(Routes.analysis(capture.id));
}
