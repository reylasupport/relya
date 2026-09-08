import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_durations.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A slow wash of brand colour behind onboarding. Static, not animated: this
/// screen already has a moving demo on it, and two things moving at once is
/// one thing too many.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.9),
          radius: 1.5,
          colors: [
            context.colors.primary.withValues(alpha: dark ? 0.20 : 0.11),
            context.colors.secondary.withValues(alpha: dark ? 0.10 : 0.05),
            context.colors.surface.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: child,
    );
  }
}

class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? context.colors.primary
                  : context.colors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
