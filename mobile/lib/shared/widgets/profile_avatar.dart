import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../domain/user_profile.dart';

/// Initials in a circle. No photo upload in V1: one more thing to store, one
/// more piece of personal data to protect, for no functional gain.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 36,
    this.onTap,
    this.semanticLabel,
  });

  final UserProfile? profile;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  String get _initials {
    final name = profile?.displayName?.trim();
    if (name == null || name.isEmpty) {
      final email = profile?.email;
      return (email == null || email.isEmpty) ? '?' : email[0].toUpperCase();
    }
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: colors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (onTap == null) return circle;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: circle,
      ),
    );
  }
}
