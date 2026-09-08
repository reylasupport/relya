import 'package:flutter/material.dart';

import '../tokens/app_semantic_colors.dart';
import '../tokens/app_skin_style.dart';
import '../tokens/app_spacing.dart';

/// A flat surface with a hairline border. No shadow: depth in this app comes
/// from whitespace, not from stacking.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.accent,
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Draws a 3px bar on the leading edge. Used sparingly, to mark urgency.
  final Color? accent;

  /// Overrides the surface. Only the designs that fill a card with its own
  /// category colour pass this; everything else stays on the theme surface.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    // A Stack, not a Row with CrossAxisAlignment.stretch. Stretch asks its
    // children for an infinite height, which is fine inside a bounded parent
    // and throws inside a scroll view - and a card is used in both. The Stack
    // sizes to the content and lets the accent bar match whatever that is.
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainer,
        borderRadius: context.skin.card,
        border: Border.all(color: semantic.subtleBorder),
      ),
      child: ClipRRect(
        borderRadius: context.skin.card,
        child: Stack(
          children: [
            Padding(
              padding: accent == null
                  ? padding
                  : padding.add(const EdgeInsetsDirectional.only(start: 3)),
              child: child,
            ),
            if (accent != null)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: accent!),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      container: true,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: context.skin.card,
                child: content,
              ),
            ),
    );
  }
}
