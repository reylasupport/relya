import 'package:flutter/material.dart';

import '../tokens/app_semantic_colors.dart';
import 'app_pill.dart';

/// How sure the extraction was (spec section 20). Uncertainty is never hidden:
/// low confidence is shown to the user, in words, next to the field.
enum ConfidenceLevel {
  high,
  medium,
  low;

  static ConfidenceLevel of(double confidence) {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.55) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// High confidence shows nothing at all - a badge on everything would be
  /// noise, and would make the app feel unsure of itself.
  bool get needsBadge => this != ConfidenceLevel.high;
}

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    required this.checkLabel,
    required this.unsureLabel,
  });

  final double confidence;

  /// Copy for the medium level, e.g. "Please check".
  final String checkLabel;

  /// Copy for the low level, e.g. "Not sure".
  final String unsureLabel;

  @override
  Widget build(BuildContext context) {
    final level = ConfidenceLevel.of(confidence);
    if (!level.needsBadge) return const SizedBox.shrink();

    final semantic = context.semantic;
    return switch (level) {
      ConfidenceLevel.medium => AppPill(
        label: checkLabel,
        icon: Icons.help_outline_rounded,
        foreground: semantic.warning,
        background: semantic.warningContainer,
      ),
      ConfidenceLevel.low => AppPill(
        label: unsureLabel,
        icon: Icons.error_outline_rounded,
        foreground: semantic.danger,
        background: semantic.dangerContainer,
      ),
      ConfidenceLevel.high => const SizedBox.shrink(),
    };
  }
}
