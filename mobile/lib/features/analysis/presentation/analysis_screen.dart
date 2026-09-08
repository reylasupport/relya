import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/progressive_loader.dart';
import '../../../core/design/tokens/app_semantic_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/formatting/app_date_format.dart';
import '../../../core/logging/app_logger.dart';
import '../../../navigation/routes.dart';
import '../../../shared/data/providers.dart';
import '../application/analysis_controller.dart';
import 'widgets/extraction_card.dart';

/// The screen the whole product turns on.
///
/// It has one job: show what was understood, make anything uncertain obvious,
/// and let the user commit all of it with a single tap.
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key, required this.captureId});

  final String captureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = analysisControllerProvider(captureId);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next is AnalysisSaved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.analysisSavedConfirmation)),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
          tooltip: context.l10n.actionClose,
        ),
      ),
      body: switch (state) {
        AnalysisRunning() => _RunningView(),
        AnalysisFailed(:final error) => _FailureView(
          error: error,
          onRetry: () => ref.read(provider.notifier).retry(),
        ),
        AnalysisSaved() => const SizedBox.shrink(),
        AnalysisReady(:final drafts) =>
          drafts.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: context.l10n.analysisNothingFound,
                  message: context.l10n.analysisNothingFoundMessage,
                  actionLabel: context.l10n.actionClose,
                  onAction: () => context.pop(),
                )
              : _ReadyView(captureId: captureId, state: state),
      },
      bottomNavigationBar: state is AnalysisReady && state.drafts.isNotEmpty
          ? _SubmitBar(captureId: captureId, state: state)
          : null,
    );
  }
}

class _RunningView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ProgressiveLoader(
        stages: [
          l10n.analysisStageReading,
          l10n.analysisStageUnderstanding,
          l10n.analysisStageDates,
        ],
      ),
    );
  }
}

class _ReadyView extends ConsumerWidget {
  const _ReadyView({required this.captureId, required this.state});

  final String captureId;
  final AnalysisReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(analysisControllerProvider(captureId).notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageInset,
            AppSpacing.sm,
            AppSpacing.pageInset,
            AppSpacing.xl,
          ),
          child: Text(
            context.l10n.foundNThings(state.drafts.length),
            style: context.text.headlineMedium,
          ),
        ),
        for (var i = 0; i < state.drafts.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageInset,
              0,
              AppSpacing.pageInset,
              AppSpacing.md,
            ),
            child: ExtractionCard(
              draft: state.drafts[i],
              onToggleAccepted: () => controller.toggleAccepted(i),
              onToggleReminder: (r) => controller.toggleReminder(i, r),
              onToggleAction: (a) => controller.toggleAction(i, a),
              onPickDate: (when) => controller.editDate(i, when),
              onResolveAmbiguity: (when) =>
                  controller.resolveAmbiguousDate(i, when),
            ),
          ),
      ],
    );
  }
}

/// One button, always reachable, always saying exactly what it will do.
class _SubmitBar extends ConsumerStatefulWidget {
  const _SubmitBar({required this.captureId, required this.state});

  final String captureId;
  final AnalysisReady state;

  @override
  ConsumerState<_SubmitBar> createState() => _SubmitBarState();
}

class _SubmitBarState extends ConsumerState<_SubmitBar> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final count = state.acceptedCount;
    final all = count == state.drafts.length && count > 1;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.sm,
        AppSpacing.pageInset,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.drafts.any((d) => d.accepted && d.blockedByAmbiguity))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                context.l10n.analysisAmbiguousDate,
                style: context.text.labelSmall?.copyWith(
                  color: context.semantic.warning,
                ),
              ),
            ),
          FilledButton(
            onPressed: state.canSubmit && !_saving ? _submit : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    all
                        ? context.l10n.actionAddAll
                        : context.l10n.analysisAddSelected(count),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.errorGeneric;
    try {
      await ref
          .read(analysisControllerProvider(widget.captureId).notifier)
          .submit();
    } catch (error, stack) {
      // A save that fails silently reads as a dead button. Say it out loud
      // and leave the drafts on screen so the user can try again.
      AppLogger.error('Could not save the accepted items', error, stack);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// What the user sees when the pipeline did not produce anything.
///
/// The distinction that matters is quota versus failure. Running out of the
/// monthly allowance is not a fault and must not be dressed as one: it is the
/// one moment where an upgrade is genuinely the answer to the user's problem,
/// so it gets its own copy and its own button. Everything else keeps the
/// retry, and never shows a raw exception - an English class name is not an
/// error message in an app that ships in four languages.
class _FailureView extends ConsumerWidget {
  const _FailureView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (error is QuotaExceeded) {
      final resetsAt =
          (error as QuotaExceeded).resetsAt ??
          ref.watch(currentProfileProvider).valueOrNull?.periodResetsAt;

      return EmptyState(
        icon: Icons.hourglass_bottom_rounded,
        title: l10n.captureQuotaReachedTitle,
        message: resetsAt == null
            ? l10n.errorQuota
            : l10n.captureQuotaReachedMessage(
                AppDateFormat.fullDate(resetsAt.toLocal(), context.localeTag),
              ),
        actionLabel: FeatureFlags.paywallEnabled ? l10n.paywallSubscribe : null,
        onAction: FeatureFlags.paywallEnabled
            ? () => context.push(Routes.paywall)
            : null,
        secondaryActionLabel: l10n.actionClose,
        onSecondaryAction: () => context.pop(),
      );
    }

    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: error is NetworkException
          ? l10n.errorNetwork
          : l10n.errorExtraction,
      message: error is NetworkException
          ? l10n.errorOffline
          : l10n.errorGeneric,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
