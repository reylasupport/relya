import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_semantic_colors.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

/// The two actions you take once. Kept at the bottom, unstyled as buttons, so
/// they are findable but never in the way.
class DangerZone extends StatelessWidget {
  const DangerZone({
    super.key,
    required this.onSignOut,
    required this.onDelete,
  });

  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l10n.settingsSignOut),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: context.semantic.danger,
            ),
            child: Text(l10n.settingsDeleteAccount),
          ),
        ],
      ),
    );
  }
}
