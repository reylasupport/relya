import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../extensions/context_extensions.dart';
import '../illustrations/cosy_backdrop.dart';
import 'concept.dart';
import 'concept_kit.dart';
import 'kit_common.dart';

/// Concept F: cozy lifestyle dark.
///
/// Dark, but never technological. Warm near-black instead of navy, cream
/// instead of white, and a serif on every heading - that last one is the
/// single decision that separates this from Concept A more than any colour
/// does. It should feel like an app opened on a sofa at night, not a console.
class KitF extends ConceptKit {
  const KitF();

  @override
  double get gutter => 20;

  @override
  double get rowGap => 6;

  static const _radius = 18.0;

  /// The editorial voice. Sizes come from the text theme so Dynamic Type
  /// still works; only the family and the weight change.
  static TextStyle serif(TextStyle base) => conceptHeading(Concept.f, base);

  @override
  Widget page(BuildContext context, {required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WarmPainter(
              glow: context.colors.secondary,
              accent: context.colors.primary,
            ),
          ),
        ),
        child,
      ],
    );
  }

  @override
  Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? tint,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: tint ?? context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: child,
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
                borderRadius: BorderRadius.circular(_radius),
                child: content,
              ),
            ),
    );
  }

  @override
  Widget row(
    BuildContext context, {
    required LifeItem item,
    required DateTime now,
    VoidCallback? onTap,
  }) => ConceptRow(
    item: item,
    now: now,
    gutter: gutter,
    onTap: onTap,
    style: const RowStyle(
      tinted: false,
      glyphRadius: 12,
      glyphSize: 40,
      verticalPadding: 12,
      cardRadius: _radius,
    ),
  );

  @override
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  }) => ConceptGlyph(type: type, size: size, radius: 12);

  @override
  Widget badge(
    BuildContext context, {
    required String label,
    required Color tone,
  }) => ConceptBadge(label: label, tone: tone, radius: 8);

  @override
  TextStyle display(BuildContext context) => serif(context.text.displaySmall!);

  @override
  TextStyle heading(BuildContext context) =>
      serif(context.text.headlineMedium!);

  @override
  Widget sectionHeader(
    BuildContext context, {
    required String title,
    int? count,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget primaryButton(
    BuildContext context, {
    required String label,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    // Flat lavender, no gradient. The gradient belongs to Concept A; this one
    // gets its richness from the warmth of the surfaces around it.
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius - 4),
          ),
        ),
      ),
    );
  }

  @override
  Widget suggestion(
    BuildContext context, {
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: context.colors.primary),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: context.text.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget empty(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter + 14, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: const CosyBackdrop(child: SizedBox.expand()),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: heading(context)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              primaryButton(context, label: actionLabel, onTap: onAction),
            ],
            if (secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

/// A warm pool of light at the top and a leaf in the corner. Nothing sharp,
/// nothing blue.
class _WarmPainter extends CustomPainter {
  _WarmPainter({required this.glow, required this.accent});

  final Color glow;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.78, -h * 0.02),
      w * 0.50,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.32)
        ..color = glow.withValues(alpha: 0.13),
    );

    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(w * 0.97, h * 0.055);
      canvas.rotate(0.5 + i * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -w * 0.11),
          width: w * 0.055,
          height: w * 0.23,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = accent.withValues(alpha: 0.20),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WarmPainter old) => old.glow != glow;
}
