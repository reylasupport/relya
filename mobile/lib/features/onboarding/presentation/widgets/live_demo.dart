import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_durations.dart';
import '../../../../core/design/tokens/app_radii.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/domain/life_item_type.dart';

/// The whole product, played out in eight seconds, before anyone has signed up.
///
/// Telling someone "it understands your screenshots" does not land. Showing a
/// message arrive, get read, and turn into three things they would otherwise
/// have forgotten does. It loops, so a slow reader gets a second pass.
class LiveDemo extends StatefulWidget {
  const LiveDemo({super.key});

  @override
  State<LiveDemo> createState() => _LiveDemoState();
}

class _LiveDemoState extends State<LiveDemo> {
  static const _steps = 5;

  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % (_steps + 2));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final results = [
      (
        LifeItemType.appointment,
        l10n.onboardingDemoItem1,
        l10n.onboardingDemoItem1Meta,
      ),
      (
        LifeItemType.bill,
        l10n.onboardingDemoItem2,
        l10n.onboardingDemoItem2Meta,
      ),
      (
        LifeItemType.task,
        l10n.onboardingDemoItem3,
        l10n.onboardingDemoItem3Meta,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Message(text: l10n.onboardingDemoMessage),
        const SizedBox(height: AppSpacing.md),
        _Reading(active: _step >= 1, label: l10n.analysisStageUnderstanding),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < results.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Result(
              visible: _step >= i + 2,
              type: results[i].$1,
              title: results[i].$2,
              meta: results[i].$3,
            ),
          ),
      ],
    );
  }
}

/// The thing that arrives. Styled as a chat bubble because that is where most
/// of these actually come from.
class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadii.card),
          topRight: Radius.circular(AppRadii.card),
          bottomRight: Radius.circular(AppRadii.card),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.onSurface,
          height: 1.35,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.25,
      duration: AppDurations.normal,
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            '$label...',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One thing the app found, sliding in as it is understood.
class _Result extends StatelessWidget {
  const _Result({
    required this.visible,
    required this.type,
    required this.title,
    required this.meta,
  });

  final bool visible;
  final LifeItemType type;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentFor(type);
    final semantic = context.semantic;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.25),
      duration: AppDurations.normal,
      curve: AppDurations.emphasised,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDurations.normal,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: AppRadii.cardRadius,
            border: Border.all(color: semantic.subtleBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: context.isDark ? 0.22 : 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(type.icon, size: 17, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      meta,
                      style: context.text.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_rounded, size: 18, color: semantic.success),
            ],
          ),
        ),
      ),
    );
  }
}
