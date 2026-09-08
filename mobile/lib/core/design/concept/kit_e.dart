import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../extensions/context_extensions.dart';
import '../illustrations/pastel_scene.dart';
import 'concept_kit.dart';
import 'kit_common.dart';

/// Concept E: friendly pastel.
///
/// The cheerful one. Everything is rounder, softer and further apart than in
/// the other three, colour is used generously rather than sparingly, and the
/// icons are filled because outline icons look administrative. Rows sit on a
/// tinted card of their own category, which is what makes a list of six read
/// as six different kinds of thing instead of six lines.
class KitE extends ConceptKit {
  const KitE();

  @override
  double get gutter => 22;

  @override
  double get rowGap => 8;

  static const _radius = 24.0;

  @override
  Widget page(BuildContext context, {required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PetalPainter(
              accent: context.colors.primary,
              secondary: context.colors.secondary,
              dark: context.isDark,
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
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tint ?? context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
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
      tinted: true,
      glyphRadius: 999,
      glyphSize: 42,
      verticalPadding: 13,
      cardRadius: 20,
      filledIcons: true,
    ),
  );

  @override
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  }) => ConceptGlyph(type: type, size: size, radius: 999, filled: true);

  @override
  Widget badge(
    BuildContext context, {
    required String label,
    required Color tone,
  }) => ConceptBadge(label: label, tone: tone);

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
      padding: EdgeInsets.fromLTRB(gutter, 26, gutter, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
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
      color: context.colors.primary.withValues(alpha: 0.10),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
        padding: EdgeInsets.symmetric(horizontal: gutter + 10, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PastelScene(height: 200),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
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

/// Petals and blobs in the corners. Decoration is part of this design, not
/// an afterthought: without it the screen is just a white page.
class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.accent,
    required this.secondary,
    required this.dark,
  });

  final Color accent;
  final Color secondary;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final a = dark ? 0.10 : 0.13;

    canvas.drawCircle(
      Offset(-w * 0.16, h * 0.06),
      w * 0.34,
      Paint()..color = secondary.withValues(alpha: a * 0.8),
    );
    canvas.drawCircle(
      Offset(w * 1.12, h * 0.30),
      w * 0.30,
      Paint()..color = accent.withValues(alpha: a * 0.7),
    );

    // Three leaves in the bottom-left corner.
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(w * 0.04, h * 0.97);
      canvas.rotate(-1.25 + i * 0.42);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -w * 0.13),
          width: w * 0.09,
          height: w * 0.27,
        ),
        Paint()..color = accent.withValues(alpha: a * 0.75),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) => old.accent != accent;
}
