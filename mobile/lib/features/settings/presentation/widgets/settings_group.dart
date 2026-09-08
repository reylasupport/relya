import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_radii.dart';
import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class SettingsTile {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.value,
    this.trailingDot,
    this.onTap,
  });

  final IconData icon;
  final String title;

  /// The current setting, shown inline. Saves a tap just to find out what a
  /// setting is currently on.
  final String? value;

  /// A colour chip, used by the palette row so the choice is visible here too.
  final Color? trailingDot;

  final VoidCallback? onTap;
}

/// A titled block of rows on one surface, the way both platforms group
/// settings. Cheaper to scan than a flat list of thirty tiles.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.tiles});

  final String title;
  final List<SettingsTile> tiles;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageInset,
        AppSpacing.xl,
        AppSpacing.pageInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title.toUpperCase(),
              style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: AppRadii.cardRadius,
              border: Border.all(color: semantic.subtleBorder),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  _Row(tile: tiles[i]),
                  if (i < tiles.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: semantic.subtleBorder,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.tile});

  final SettingsTile tile;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: AppRadii.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg - 2,
          ),
          child: Row(
            children: [
              Icon(tile.icon, size: 20, color: context.colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(tile.title, style: context.text.bodyLarge)),
              if (tile.trailingDot != null) ...[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: tile.trailingDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (tile.value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    tile.value!,
                    style: context.text.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              if (tile.onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
