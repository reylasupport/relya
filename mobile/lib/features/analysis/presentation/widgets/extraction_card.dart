import 'package:flutter/material.dart';

import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/confidence_badge.dart';
import '../../../../core/design/tokens/app_radii.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/design/tokens/type_palette.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/formatting/app_date_format.dart';
import '../../../../core/formatting/app_money_format.dart';
import '../../../../shared/domain/extraction.dart';
import '../../application/analysis_controller.dart';

/// One understood thing, with everything the user might want to change about
/// it before it becomes real.
class ExtractionCard extends StatelessWidget {
  const ExtractionCard({
    super.key,
    required this.draft,
    required this.onToggleAccepted,
    required this.onToggleReminder,
    required this.onToggleAction,
    required this.onPickDate,
    required this.onResolveAmbiguity,
  });

  final AnalysisDraft draft;
  final VoidCallback onToggleAccepted;
  final void Function(int index) onToggleReminder;
  final void Function(int index) onToggleAction;
  final void Function(DateTime when) onPickDate;
  final void Function(DateTime when) onResolveAmbiguity;

  @override
  Widget build(BuildContext context) {
    final result = draft.result;
    final semantic = context.semantic;
    final locale = context.localeTag;
    final level = ConfidenceLevel.of(result.confidence);

    final startDate = result.dateOfKind(ExtractedDateKind.start);
    final otherDates = result.dates
        .where((d) => d.kind != ExtractedDateKind.start)
        .toList();
    final primaryDate =
        startDate ?? (otherDates.isEmpty ? null : otherDates.first);

    return AppCard(
      padding: EdgeInsets.zero,
      accent: draft.accepted ? context.accentFor(result.type) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _facts(context, primaryDate, locale, level),
                if (level == ConfidenceLevel.low ||
                    result.unresolvedNote != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Notice(
                    text:
                        result.unresolvedNote ??
                        context.l10n.analysisLowConfidence,
                    colour: semantic.danger,
                    background: semantic.dangerContainer,
                  ),
                ],
                if (draft.blockedByAmbiguity)
                  _AmbiguityPicker(
                    date: result.dates.firstWhere((d) => d.ambiguous),
                    onResolve: onResolveAmbiguity,
                  ),
                _suggestions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final result = draft.result;
    return InkWell(
      onTap: onToggleAccepted,
      borderRadius: AppRadii.cardRadius,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.type.icon,
              size: 20,
              color: context.accentFor(result.type),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: context.text.titleMedium),
                  if (result.summary != null) ...[
                    const SizedBox(height: 2),
                    Text(result.summary!, style: context.text.bodyMedium),
                  ],
                ],
              ),
            ),
            Semantics(
              label: result.title,
              checked: draft.accepted,
              child: Checkbox(
                value: draft.accepted,
                onChanged: (_) => onToggleAccepted(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _facts(
    BuildContext context,
    ExtractedDate? primaryDate,
    String locale,
    ConfidenceLevel level,
  ) {
    final result = draft.result;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (primaryDate?.resolved != null)
          _Fact(
            icon: Icons.schedule_rounded,
            label: primaryDate!.hasTime
                ? AppDateFormat.dateAndTime(
                    primaryDate.resolved!.toLocal(),
                    locale,
                  )
                : AppDateFormat.fullDate(
                    primaryDate.resolved!.toLocal(),
                    locale,
                  ),
            onTap: () => _pickDate(context, primaryDate.resolved!),
          ),
        if (result.amount != null)
          _Fact(
            icon: Icons.payments_outlined,
            label: AppMoneyFormat.format(
              result.amount!,
              result.currency,
              locale,
            ),
          ),
        if (result.location != null)
          _Fact(icon: Icons.place_outlined, label: result.location!),
        if (level.needsBadge)
          ConfidenceBadge(
            confidence: result.confidence,
            checkLabel: context.l10n.analysisConfirmCheck,
            unsureLabel: context.l10n.analysisConfirmUnsure,
          ),
      ],
    );
  }

  Widget _suggestions(BuildContext context) {
    final result = draft.result;
    if (result.suggestedReminders.isEmpty && result.suggestedActions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < result.suggestedReminders.length; i++)
          _Suggestion(
            icon: Icons.notifications_none_rounded,
            label: result.suggestedReminders[i].label,
            value: draft.reminderChoices[i],
            onChanged: () => onToggleReminder(i),
          ),
        for (var i = 0; i < result.suggestedActions.length; i++)
          _Suggestion(
            icon: _actionIcon(result.suggestedActions[i].type),
            label: result.suggestedActions[i].label,
            value: draft.actionChoices[i],
            onChanged: () => onToggleAction(i),
          ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final local = current.toLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: local,
      firstDate: DateTime(local.year - 5),
      lastDate: DateTime(local.year + 10),
    );
    if (picked == null) return;
    onPickDate(
      DateTime(picked.year, picked.month, picked.day, local.hour, local.minute),
    );
  }

  static IconData _actionIcon(SuggestedActionType type) => switch (type) {
    SuggestedActionType.addToCalendar => Icons.calendar_month_rounded,
    SuggestedActionType.saveDocument => Icons.folder_outlined,
    SuggestedActionType.trackPayment => Icons.payments_outlined,
    SuggestedActionType.trackSubscription => Icons.autorenew_rounded,
    SuggestedActionType.trackWarranty => Icons.verified_user_outlined,
    SuggestedActionType.trackDelivery => Icons.local_shipping_outlined,
    SuggestedActionType.addTrip => Icons.luggage_outlined,
    SuggestedActionType.unknown => Icons.bolt_outlined,
  };
}

/// A single extracted fact. Tappable ones can be corrected on the spot, which
/// is the difference between a user trusting the app and abandoning it.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(label, style: context.text.labelSmall),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.edit_rounded, size: 12, color: context.colors.primary),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pillRadius,
      child: content,
    );
  }
}

/// Uncertainty, stated plainly. Never a silent downgrade of the result.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    required this.colour,
    required this.background,
  });

  final String text;
  final Color colour;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.controlRadius,
      ),
      child: Text(
        text,
        style: context.text.bodyMedium?.copyWith(color: colour),
      ),
    );
  }
}

/// "12/10" means two different days depending on where you are. When the
/// locale does not settle it, we ask instead of guessing (spec section 21).
class _AmbiguityPicker extends StatelessWidget {
  const _AmbiguityPicker({required this.date, required this.onResolve});

  final ExtractedDate date;
  final void Function(DateTime) onResolve;

  @override
  Widget build(BuildContext context) {
    final options = <DateTime>[
      if (date.resolved != null) date.resolved!,
      if (date.alternative != null) date.alternative!,
    ];
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.analysisAmbiguousDate,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final option in options)
                OutlinedButton(
                  onPressed: () => onResolve(option),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                  ),
                  child: Text(
                    AppDateFormat.fullDate(option.toLocal(), context.localeTag),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A pre-ticked proposal. The app suggests; the user decides (spec section 53).
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 17, color: context.colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: context.text.bodyLarge)),
            Switch.adaptive(value: value, onChanged: (_) => onChanged()),
          ],
        ),
      ),
    );
  }
}
