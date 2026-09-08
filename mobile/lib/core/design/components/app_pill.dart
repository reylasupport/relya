import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';

/// Small status chip. Carries meaning through colour, but never colour alone -
/// the label always says the same thing, for colour-blind users and screen
/// readers.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          // A pill sizes itself to its label, which at 1.6x text can be
          // wider than the phone. Flexible plus an ellipsis keeps the chip
          // inside the row instead of striping the screen; the full text is
          // still on the row it describes.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
