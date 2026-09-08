import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_durations.dart';
import '../../../../core/design/tokens/app_skin.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// One theme, shown as a small picture of itself.
///
/// A colour dot cannot tell you that Cosy is warm and dark or that Pastel
/// tints its rows. The thumbnail paints the skin's own surfaces, its own
/// corner radius and a couple of its own rows, so the choice is made by
/// looking rather than by reading an adjective.
class SkinCard extends StatelessWidget {
  const SkinCard({
    super.key,
    required this.skin,
    required this.title,
    required this.body,
    required this.selected,
    required this.previewBrightness,
    required this.onTap,
  });

  final AppSkin skin;
  final String title;
  final String body;
  final bool selected;

  /// Draws the thumbnail in the mode the app is currently in, so the preview
  /// matches what tapping it will actually produce.
  final Brightness previewBrightness;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = skin.palette(previewBrightness);
    final outer = context.colors;

    return Semantics(
      label: title,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(skin.cardRadius + 2),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: outer.surfaceContainer,
            borderRadius: BorderRadius.circular(skin.cardRadius + 2),
            border: Border.all(
              color: selected ? palette.accent : context.colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(skin: skin, palette: palette),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: Text(title, style: context.text.titleMedium)),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: palette.accent,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(body, style: context.text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A miniature of the app in that skin: header, focus card, two rows.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.skin, required this.palette});

  final AppSkin skin;
  final SkinPalette palette;

  @override
  Widget build(BuildContext context) {
    final radius = skin.cardRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: 152,
        width: double.infinity,
        color: palette.surface,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Bar(width: 44, height: 7, color: palette.onSurface),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: palette.gradient,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // The focus card, in this skin's accent and corner radius.
            Container(
              height: 30,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(radius * 0.55),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.30),
                ),
              ),
              child: _Bar(width: 52, height: 6, color: palette.accent),
            ),
            const SizedBox(height: 7),
            _Row(palette: palette, skin: skin, tint: const Color(0xFF0E8A8A)),
            const SizedBox(height: 5),
            _Row(palette: palette, skin: skin, tint: const Color(0xFFB5730A)),
            const Spacer(),
            _MiniBar(skin: skin, palette: palette),
          ],
        ),
      ),
    );
  }
}

/// The navigation bar, in miniature.
///
/// It earns its place because the bar is now part of the theme: one design
/// sinks the capture button into it and drops a destination, and a preview
/// that hid that would be selling the wrong thing.
class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.skin, required this.palette});

  final AppSkin skin;
  final SkinPalette palette;

  @override
  Widget build(BuildContext context) {
    final centre = skin.nav == SkinNav.centre;
    final count = centre ? 4 : 5;

    Widget dot(int i) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: i == 0
            ? palette.accent
            : palette.onSurfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );

    final fab = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        gradient: palette.gradient,
        shape: BoxShape.circle,
      ),
    );

    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.centerRight,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceContainerLowest,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < count; i++) ...[
                    dot(i),
                    if (centre && i == 1) fab,
                  ],
                ],
              ),
            ),
          ),
          if (!centre) Positioned(right: 4, bottom: 12, child: fab),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.palette, required this.skin, required this.tint});

  final SkinPalette palette;
  final AppSkin skin;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        // Pastel puts its rows on a tinted card; the others leave them bare.
        color: skin.tintedRows
            ? tint.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(radiusFor(skin)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          _Bar(width: 46, height: 5, color: palette.onSurface),
          const Spacer(),
          _Bar(width: 16, height: 5, color: palette.onSurfaceVariant),
        ],
      ),
    );
  }

  static double radiusFor(AppSkin skin) => skin.cardRadius * 0.45;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
