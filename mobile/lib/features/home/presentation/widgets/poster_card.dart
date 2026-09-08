import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_skin_style.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// The week, said out loud.
///
/// Where the other designs open Home with the single next item, this one opens
/// with a sentence about the week as a whole. It is the only card in the app
/// that carries the gradient as a fill rather than as an edge, which is what
/// makes the screen below it read as quiet by comparison.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.weekCount,
    required this.soonCount,
    this.onTap,
  });

  final int weekCount;
  final int soonCount;
  final VoidCallback? onTap;

  static LinearGradient _poster(BuildContext context) {
    final g = context.skin.gradient as LinearGradient;
    final amount = context.isDark ? 0.42 : 0.18;
    return LinearGradient(
      begin: g.begin,
      end: g.end,
      colors: [for (final c in g.colors) Color.lerp(c, Colors.black, amount)!],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = BorderRadius.circular(context.skin.cardRadius + 4);
    final calm = weekCount == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageInset),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: radius,
              // Darkened towards black: white type has to sit on this, and
              // the raw accent gradient is too light to carry it.
              gradient: _poster(context),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.30),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _Swirl(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homePosterLabel,
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      calm
                          ? l10n.homePosterTitleCalm
                          : l10n.homePosterTitle(weekCount),
                      style: context.text.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      calm
                          ? l10n.homePosterSubtitleCalm
                          : l10n.homePosterSubtitle(soonCount),
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GhostButton(label: l10n.actionSeeDetails, onTap: onTap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two soft arcs in the top-right corner. Enough to stop the gradient reading
/// as a flat rectangle, quiet enough not to compete with the sentence.
class _Swirl extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.86, size.height * 0.12);
    for (var i = 0; i < 3; i++) {
      final r = size.height * (0.34 + i * 0.24);
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.13 - i * 0.035),
      );
    }
    canvas.drawCircle(
      origin,
      size.height * 0.30,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: origin, radius: size.height * 0.30),
            ),
    );
    // A single diagonal sheen across the lower half.
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.55, size.height)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height);
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.045),
    );
  }

  @override
  bool shouldRepaint(covariant _Swirl oldDelegate) => false;
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 12, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.labelLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
