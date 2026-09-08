import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';

class ProviderButton extends StatelessWidget {
  const ProviderButton({
    super.key,
    required this.icon,
    required this.label,
    required this.busy,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );

    return filled
        ? FilledButton(onPressed: busy ? null : onPressed, child: child)
        : OutlinedButton(onPressed: busy ? null : onPressed, child: child);
  }
}
