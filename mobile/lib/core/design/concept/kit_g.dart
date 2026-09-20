import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../extensions/context_extensions.dart';
import '../illustrations/relya_scenes.dart';
import '../tokens/app_semantic_colors.dart';
import 'concept_kit.dart';
import 'kit_common.dart';

/// Concept G: soft depth.
///
/// The one rule the whole design follows: hierarchy comes from elevation, not
/// from lines or weight. Nothing here has a border. What matters most sits on
/// the biggest shadow, what matters least sits nearly flat on the ground, and
/// the eye sorts them without being told.
///
/// That rule is also why this skin needed a dark palette drawn from scratch
/// rather than an inversion. Translucent white over a dark ground is dead
/// grey, so after dark the planes go solid and the depth is carried by light:
/// each surface a step brighter than the one behind it.
class KitG extends ConceptKit {
  const KitG();

  @override
  double get gutter => 18;

  @override
  double get rowGap => 8;

  static const double _radius = 22;

  /// Two shadows, not one. A tight dark one holds the edge and a wide soft one
  /// gives the lift; a single blur does one of those jobs badly.
  static List<BoxShadow> _lift(BuildContext context, {required double level}) {
    final dark = context.isDark;
    final base = dark ? Colors.black : const Color(0xFF111520);
    return [
      BoxShadow(
        color: base.withValues(alpha: dark ? 0.34 : 0.05),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: (dark ? 0.40 : 0.09) * level),
        blurRadius: 14 * level + 6,
        offset: Offset(0, 5 * level + 1),
      ),
    ];
  }

  @override
  Widget page(BuildContext context, {required Widget child}) => child;

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
        color: tint ?? context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: _lift(context, level: 1.4),
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

  /// A surface that carries other surfaces: the list a row sits in, the panel
  /// under a set of details. Lower than [card] on purpose.
  static Widget panel(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) => Container(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(_radius),
      boxShadow: _lift(context, level: 0.7),
    ),
    child: child,
  );

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
      glyphRadius: 11,
      glyphSize: 38,
      verticalPadding: 13,
      cardRadius: _radius,
      chevron: true,
    ),
  );

  @override
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  }) => ConceptGlyph(type: type, size: size, radius: 11);

  @override
  Widget badge(
    BuildContext context, {
    required String label,
    required Color tone,
  }) => ConceptBadge(label: label, tone: tone);

  @override
  TextStyle display(BuildContext context) => context.text.displaySmall!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5);

  @override
  TextStyle heading(BuildContext context) => context.text.headlineMedium!
      .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4);

  @override
  Widget sectionHeader(
    BuildContext context, {
    required String title,
    int? count,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter + 6, 22, gutter + 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
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
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius - 6),
          ),
          elevation: 6,
          shadowColor: context.colors.primary.withValues(alpha: 0.5),
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
    // A raised pill rather than an outlined one: an outline would be the only
    // line in the design.
    return Material(
      color: context.colors.surfaceContainer,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: _lift(context, level: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            // A pill sized to its text will happily grow past the screen once
            // the text scale does. It stays a pill and wraps instead.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - gutter * 2 - 30,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: context.semantic.accentText),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
            const EmptyInboxScene(height: 150),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
            if (secondaryLabel != null)
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          ],
        ),
      ),
    );
  }
}
