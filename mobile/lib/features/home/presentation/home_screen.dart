import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/app_shell.dart';
import '../../../shared/data/providers.dart';
import '../../inbox/application/inbox_controller.dart';
import '../application/home_controller.dart';
import 'views/home_a.dart';
import 'views/home_d.dart';
import 'views/home_e.dart';
import 'views/home_f.dart';

/// Answers "what is important in my life right now" and nothing else.
///
/// This file owns the data and the states around it - loading, failure,
/// nothing yet - and hands the loaded snapshot to whichever view the active
/// design uses. The four views arrange the same facts very differently: one
/// leads with a dashboard, one with a single card, one with a warm greeting,
/// one with an editorial header.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homeSnapshotProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final pending = ref.watch(inboxPendingCountProvider);
    final kit = context.kit;

    return Scaffold(
      body: kit.page(
        context,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeSnapshotProvider),
          child: snapshot.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            error: (error, _) => kit.empty(
              context,
              icon: Icons.cloud_off_rounded,
              title: context.l10n.errorGeneric,
              message: context.l10n.errorNetwork,
              actionLabel: context.l10n.actionRetry,
              onAction: () => ref.invalidate(homeSnapshotProvider),
            ),
            data: (data) {
              if (data.isEmpty) {
                return kit.empty(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: context.l10n.homeEmptyTitle,
                  message: context.l10n.homeEmptyMessage,
                  actionLabel: context.l10n.captureTitle,
                  onAction: () => openCaptureSheet(context),
                );
              }
              return switch (context.concept) {
                Concept.a => HomeA(
                  data: data,
                  profile: profile,
                  pending: pending,
                ),
                Concept.d => HomeD(
                  data: data,
                  profile: profile,
                  pending: pending,
                ),
                Concept.e => HomeE(
                  data: data,
                  profile: profile,
                  pending: pending,
                ),
                Concept.f => HomeF(
                  data: data,
                  profile: profile,
                  pending: pending,
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}
