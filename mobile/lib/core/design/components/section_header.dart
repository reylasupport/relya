import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';
import '../tokens/app_skin.dart';
import '../tokens/app_skin_style.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_semantic_colors.dart';

/// "Today", "Next 30 days". The label that opens a run of rows.
///
/// Each design says this differently - a link on one, a bare count on
/// another, small caps on a third - so the shape comes from the skin rather
/// than from the caller. Callers supply the facts: the title, how many rows
/// follow, and where "see all" goes if there is somewhere to go.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.count,
    this.onSeeAll,
  });

  final String title;
  final Widget? trailing;
  final int? count;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final style = context.appSkin.sectionStyle;
    final text = context.text;

    final upper = style == SkinSectionStyle.upperCount;
    final label = Semantics(
      header: true,
      child: Text(
        upper ? title.toUpperCase() : title,
        style: upper
            ? text.labelSmall?.copyWith(letterSpacing: 1.1)
            : text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    final showCount =
        count != null &&
        (style == SkinSectionStyle.count ||
            style == SkinSectionStyle.upperCount ||
            style == SkinSectionStyle.pill);
    final showLink = style == SkinSectionStyle.linkAll && onSeeAll != null;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pageInset,
        right: AppSpacing.pageInset,
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(child: label),
          if (showCount)
            if (style == SkinSectionStyle.pill)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Text(
                '$count',
                style: text.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          if (showLink)
            _SeeAll(label: context.l10n.actionSeeAll, onTap: onSeeAll!),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      // The label is small on purpose; the thing you hit should not be. Eight
      // points of vertical padding is what takes a 20dp line to 48.
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 16,
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.accentText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
