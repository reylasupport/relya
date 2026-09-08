import 'package:flutter/material.dart';

import '../../../../core/design/concept/concept.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'robot_mascot.dart';

/// The title bar of the assistant, in four voices.
///
/// The poster design calls it a copilot and puts a spark on it; the pastel
/// one introduces a mascot and a heart; the cosy one sets it in serif; the
/// clean one just says what it is. Same screen, four first impressions.
class AssistantHeader extends StatelessWidget implements PreferredSizeWidget {
  const AssistantHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final l10n = context.l10n;
    final concept = context.concept;

    final spark = concept == Concept.a || concept == Concept.f;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(kit.gutter, 12, kit.gutter, 8),
        child: Row(
          children: [
            if (spark) ...[
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.assistantTitle, style: kit.heading(context)),
                  if (concept == Concept.e)
                    Text(
                      l10n.assistantSubtitle,
                      style: context.text.bodyMedium,
                    ),
                ],
              ),
            ),
            if (concept == Concept.e) const RobotMascot(size: 46),
          ],
        ),
      ),
    );
  }
}

/// One turn of the conversation.
///
/// The user side is always the accent; what changes is the shape - a tight
/// radius in the poster design, a big soft one in the pastel design - and how
/// much the answer bubble is allowed to stand out from the page.
class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = switch (context.concept) {
      Concept.a => 12.0,
      Concept.d => 18.0,
      Concept.e => 22.0,
      Concept.f => 16.0,
    };

    final userFill = context.concept == Concept.e
        ? colors.primary.withValues(alpha: context.isDark ? 0.34 : 0.18)
        : colors.primary;
    final userInk = context.concept == Concept.e
        ? colors.onSurface
        : colors.onPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? userFill : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(radius),
          border: isUser
              ? null
              : Border.all(color: context.colors.outlineVariant),
        ),
        child: Text(
          text,
          style: context.text.bodyLarge?.copyWith(
            color: isUser ? userInk : colors.onSurface,
          ),
        ),
      ),
    );
  }
}
