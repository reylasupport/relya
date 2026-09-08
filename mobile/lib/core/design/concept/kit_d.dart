import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../extensions/context_extensions.dart';
import '../illustrations/relya_scenes.dart';
import 'concept_kit.dart';
import 'kit_common.dart';

/// Concept D: clean mainstream.
///
/// The one that has to work for everybody. Near-white, one soft indigo, wide
/// corner radius, generous padding, and nothing that could be described as an
/// effect. Its job is legibility and calm; every decision here is the boring
/// one on purpose.
class KitD extends ConceptKit {
  const KitD();

  @override
  double get gutter => 20;

  @override
  double get rowGap => 6;

  static const _radius = 18.0;

  @override
  Widget page(BuildContext context, {required Widget child}) {
    // A breath of colour in the top corner and nothing else. Anything more
    // would stop this reading as a plain, trustworthy surface.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withValues(alpha: 0.045),
            context.colors.surface.withValues(alpha: 0),
          ],
          stops: const [0, 0.45],
        ),
      ),
      child: child,
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
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tint ?? context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
      tinted: false,
      glyphRadius: 13,
      glyphSize: 40,
      verticalPadding: 12,
      cardRadius: _radius,
      chevron: true,
    ),
  );

  @override
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  }) => ConceptGlyph(type: type, size: size, radius: 13);

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
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  context.l10n.actionSeeAll,
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: context.colors.outlineVariant),
        foregroundColor: context.colors.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        padding: EdgeInsets.symmetric(horizontal: gutter + 12, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyInboxScene(height: 158),
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
