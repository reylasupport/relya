import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../../shared/widgets/item_time_label.dart';
import '../../extensions/context_extensions.dart';
import '../../formatting/app_money_format.dart';
import '../tokens/type_palette.dart';

/// The knobs that make one design's list row different from another's.
///
/// The row is the most repeated shape in the app, so the four designs are
/// parameterised rather than copy-pasted. What varies is real: whether the
/// row sits on a tinted card of its own colour, how round the icon tile is,
/// how tightly it is packed, and whether the time is a chip or plain text.
@immutable
class RowStyle {
  const RowStyle({
    required this.tinted,
    required this.glyphRadius,
    required this.glyphSize,
    required this.verticalPadding,
    required this.cardRadius,
    this.filledIcons = false,
    this.borderedCard = false,
    this.chevron = false,
  });

  final bool tinted;
  final double glyphRadius;
  final double glyphSize;
  final double verticalPadding;
  final double cardRadius;
  final bool filledIcons;
  final bool borderedCard;

  /// A disclosure arrow at the end of the row. Only the clean design uses it:
  /// it is the most conventional affordance there is, which is the point.
  final bool chevron;
}

class ConceptRow extends StatelessWidget {
  const ConceptRow({
    super.key,
    required this.item,
    required this.now,
    required this.style,
    required this.gutter,
    this.onTap,
  });

  final LifeItem item;
  final DateTime now;
  final RowStyle style;
  final double gutter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = ItemTimeLabel.of(context, item, now);
    final accent = context.accentFor(item.type);
    final subtitle = item.description ?? item.organization ?? item.location;
    final radius = BorderRadius.circular(style.cardRadius);

    final surface = style.tinted
        ? accent.withValues(alpha: context.isDark ? 0.13 : 0.08)
        : style.borderedCard
        ? context.colors.surfaceContainer
        : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter - 6, vertical: 3),
      child: Material(
        color: surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.05),
          child: Container(
            decoration: style.borderedCard
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: context.colors.outlineVariant),
                  )
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: style.verticalPadding,
            ),
            child: Row(
              children: [
                ConceptGlyph(
                  type: item.type,
                  size: style.glyphSize,
                  radius: style.glyphRadius,
                  filled: style.filledIcons,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: context.text.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: context.text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (time.text.isNotEmpty)
                      ConceptBadge(
                        label: time.text,
                        tone: time.colour,
                        radius: style.cardRadius,
                      ),
                    if (item.hasMoney) ...[
                      SizedBox(height: time.colour != null ? 5 : 3),
                      Text(
                        AppMoneyFormat.format(
                          item.amount!,
                          item.currency,
                          context.localeTag,
                        ),
                        style: context.text.labelSmall?.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                if (style.chevron) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The type icon on its coloured tile. Roundness and fill vary by design:
/// the pastel one uses filled glyphs on soft circles, the AI one thin outline
/// glyphs on tight squares.
class ConceptGlyph extends StatelessWidget {
  const ConceptGlyph({
    super.key,
    required this.type,
    this.size = 40,
    this.radius = 13,
    this.filled = false,
  });

  final LifeItemType type;
  final double size;
  final double radius;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentFor(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: context.isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        filled ? type.icon : outlineOf(type.icon),
        size: size * 0.5,
        color: accent,
      ),
    );
  }
}

/// A small status pill. Neutral tone renders as plain text: a chip around
/// every time would make the urgent ones stop reading as urgent.
class ConceptBadge extends StatelessWidget {
  const ConceptBadge({
    super.key,
    required this.label,
    this.tone,
    this.radius = 999,
  });

  final String label;
  final Color? tone;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (tone == null) {
      return Text(
        label,
        textAlign: TextAlign.end,
        style: context.text.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone!.withValues(alpha: context.isDark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The outline twin of a filled icon, where Material has one.
///
/// Three of the four designs want line icons and one wants them filled, and
/// [LifeItemType] only carries the filled name. Mapping here keeps that
/// decision in the design layer instead of duplicating the enum.
IconData outlineOf(IconData filled) => _outline[filled.codePoint] ?? filled;

final Map<int, IconData> _outline = {
  Icons.event_available_rounded.codePoint: Icons.event_available_outlined,
  Icons.receipt_long_rounded.codePoint: Icons.receipt_long_outlined,
  Icons.autorenew_rounded.codePoint: Icons.autorenew_outlined,
  Icons.shopping_bag_rounded.codePoint: Icons.shopping_bag_outlined,
  Icons.assignment_return_rounded.codePoint: Icons.assignment_return_outlined,
  Icons.verified_user_rounded.codePoint: Icons.verified_user_outlined,
  Icons.flight_takeoff_rounded.codePoint: Icons.flight_takeoff_outlined,
  Icons.description_rounded.codePoint: Icons.description_outlined,
  Icons.shield_rounded.codePoint: Icons.shield_outlined,
  Icons.directions_car_rounded.codePoint: Icons.directions_car_outlined,
  Icons.home_rounded.codePoint: Icons.home_outlined,
  Icons.celebration_rounded.codePoint: Icons.celebration_outlined,
  Icons.local_shipping_rounded.codePoint: Icons.local_shipping_outlined,
  Icons.restaurant_rounded.codePoint: Icons.restaurant_outlined,
  Icons.school_rounded.codePoint: Icons.school_outlined,
};
