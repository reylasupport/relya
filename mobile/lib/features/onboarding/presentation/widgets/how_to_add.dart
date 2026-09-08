import 'package:flutter/material.dart';

import '../../../../core/branding/brand.dart';
import '../../../../core/design/tokens/app_radii.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// The lesson: how things get into the app.
///
/// Share is listed first and marked as the important one, because it is the
/// only path that works without opening the app, and it is the difference
/// between a tool someone uses once and one they keep.
class HowToAdd extends StatelessWidget {
  const HowToAdd({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.onboardingHowTitle,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          _Way(
            icon: Icons.ios_share_rounded,
            title: l10n.onboardingHowShare,
            body: l10n.onboardingHowShareBody(Brand.appName),
            highlighted: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _Way(
            icon: Icons.photo_camera_rounded,
            title: l10n.onboardingHowPhoto,
            body: l10n.onboardingHowPhotoBody,
          ),
          const SizedBox(height: AppSpacing.md),
          _Way(
            icon: Icons.content_paste_rounded,
            title: l10n.onboardingHowPaste,
            body: l10n.onboardingHowPasteBody,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _Way extends StatelessWidget {
  const _Way({
    required this.icon,
    required this.title,
    required this.body,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final dark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primary.withValues(alpha: dark ? 0.14 : 0.07)
            : colors.surfaceContainer,
        borderRadius: AppRadii.cardRadius,
        border: Border.all(
          color: highlighted
              ? colors.primary.withValues(alpha: 0.35)
              : semantic.subtleBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: dark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
