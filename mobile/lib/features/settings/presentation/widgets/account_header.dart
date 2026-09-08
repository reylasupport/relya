import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/design/components/app_pill.dart';
import '../../../../core/design/tokens/app_radii.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/widgets/profile_avatar.dart';

/// Who you are and what you are paying, answered before anything else.
///
/// On the free plan the remaining quota is shown as a bar rather than a
/// number alone: a person should be able to tell at a glance whether they are
/// about to run out, without doing arithmetic.
class AccountHeader extends StatelessWidget {
  const AccountHeader({
    super.key,
    required this.profile,
    required this.onUpgrade,
  });

  final UserProfile? profile;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semantic;
    final isPro = profile?.plan.isPaid ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.md,
        AppSpacing.pageInset,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: semantic.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(profile: profile, size: 52),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? l10n.accountTitle,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile!.email!,
                          style: context.text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                AppPill(
                  label: isPro ? l10n.accountPlanPro : l10n.accountPlanFree,
                  icon: isPro ? Icons.workspace_premium_rounded : null,
                  foreground: isPro
                      ? semantic.success
                      : context.colors.onSurfaceVariant,
                  background: isPro
                      ? semantic.successContainer
                      : context.colors.surfaceContainerHighest,
                ),
              ],
            ),
            if (!isPro) _quota(context),
          ],
        ),
      ),
    );
  }

  Widget _quota(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semantic;

    final quota = profile?.captureQuota ?? 20;
    final used = profile?.capturesThisPeriod ?? 0;
    final left = profile?.capturesRemaining ?? quota;
    final fraction = quota == 0 ? 0.0 : (used / quota).clamp(0.0, 1.0);

    // Amber only when it is nearly gone. A bar that is always coloured is a
    // bar nobody reads.
    final barColour = left == 0
        ? semantic.danger
        : fraction > 0.8
        ? semantic.warning
        : context.colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: context.colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColour),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.accountCapturesLeft(left), style: context.text.labelSmall),
        // The quota bar is worth showing either way; the button is not. A
        // build with no store keys cannot complete a purchase, so offering one
        // only produces a dead end.
        if (FeatureFlags.paywallEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(l10n.accountUpgrade),
            ),
          ),
        ],
      ],
    );
  }
}
