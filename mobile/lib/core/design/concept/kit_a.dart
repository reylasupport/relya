import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../extensions/context_extensions.dart';
import 'concept_kit.dart';
import 'kit_common.dart';

/// Concept A: dark AI premium.
///
/// Navy-black, indigo to violet, tight corners, high density. The background
/// is never flat - there is always a glow behind the thing that matters - and
/// the accent is used as light rather than as paint. Everything is a little
/// smaller and a little closer together than in the other three, because a
/// dashboard that breathes stops looking like a dashboard.
class KitA extends ConceptKit {
  const KitA();

  @override
  double get gutter => 18;

  @override
  double get rowGap => 4;

  static const _radius = 14.0;

  @override
  Widget page(BuildContext context, {required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GlowPainter(
              accent: context.colors.primary,
              secondary: context.colors.secondary,
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
      padding: padding ?? const EdgeInsets.all(14),
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
      glyphRadius: 9,
      glyphSize: 36,
      verticalPadding: 9,
      cardRadius: _radius,
    ),
  );

  @override
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  }) => ConceptGlyph(type: type, size: size, radius: 9);

  @override
  Widget badge(
    BuildContext context, {
    required String label,
    required Color tone,
  }) => ConceptBadge(label: label, tone: tone, radius: 7);

  @override
  TextStyle display(BuildContext context) => context.text.displaySmall!;

  @override
  TextStyle heading(BuildContext context) => context.text.headlineMedium!;

  @override
  Widget sectionHeader(
    BuildContext context, {
    required String title,
    int? count,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 22, gutter, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.colors.primary, context.colors.secondary],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
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
    // The only gradient fill in the design, and the reason the screen reads
    // as a product rather than as a form.
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
          ),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
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
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: context.colors.primary),
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
        padding: EdgeInsets.symmetric(horizontal: gutter + 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.28),
                    context.colors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Icon(icon, size: 30, color: context.colors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
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

/// The background of this design: two soft lights and one long curve.
///
/// Painted rather than a gradient because a linear gradient reads as a
/// gradient, and this has to read as a room with lights in it.
class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.accent, required this.secondary});

  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.82, h * 0.06),
      w * 0.55,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.30)
        ..color = accent.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      Offset(w * 0.06, h * 0.42),
      w * 0.40,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.28)
        ..color = secondary.withValues(alpha: 0.11),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.92), radius: w * 0.95),
      3.3416,
      0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.accent != accent;
}
