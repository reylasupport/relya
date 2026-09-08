import 'package:flutter/material.dart';

import '../../../../core/design/concept/concept.dart';
import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'robot_mascot.dart';

/// What the assistant shows before anyone has asked it anything.
///
/// This is where the four designs diverge most on this screen. The poster
/// design behaves like a copilot: a greeting, three commands, and two cards
/// of unsolicited insight. The pastel one waves. The cosy one offers three
/// warm pills. The clean one asks a plain question and gets out of the way.
class AssistantIntro extends StatelessWidget {
  const AssistantIntro({super.key, required this.onPick, this.name});

  final void Function(String) onPick;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kit = context.kit;
    final concept = context.concept;
    final suggestions = [
      (l10n.assistantSuggestion1, Icons.calendar_today_outlined),
      (l10n.assistantSuggestion2, Icons.add_alert_outlined),
      (l10n.assistantSuggestion3, Icons.lightbulb_outline_rounded),
    ];

    final greeting = name == null
        ? l10n.assistantEmptyTitle
        : '${l10n.greetingHi(name!)} 👋';

    return ListView(
      padding: EdgeInsets.fromLTRB(kit.gutter, 8, kit.gutter, 20),
      children: [
        if (concept == Concept.e) ...[
          const Center(child: RobotMascot(size: 92)),
          const SizedBox(height: 14),
        ],
        if (concept == Concept.a || concept == Concept.e)
          Align(
            alignment: concept == Concept.e
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: Column(
              crossAxisAlignment: concept == Concept.e
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(greeting, style: context.text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  l10n.assistantEmptyMessage,
                  textAlign: concept == Concept.e
                      ? TextAlign.center
                      : TextAlign.start,
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 30, bottom: 6),
            child: Column(
              children: [
                Text(
                  l10n.assistantEmptyTitle,
                  textAlign: TextAlign.center,
                  style: concept == Concept.f
                      ? kit.heading(context)
                      : context.text.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.assistantEmptyMessage,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        // Vertical for the two designs that treat them as commands, wrapped
        // for the two that treat them as friendly offers.
        if (concept == Concept.a)
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: kit.suggestion(
                  context,
                  label: s.$1,
                  icon: s.$2,
                  onTap: () => onPick(s.$1),
                ),
              ),
            )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final s in suggestions)
                kit.suggestion(
                  context,
                  label: s.$1,
                  icon: concept == Concept.d ? null : s.$2,
                  onTap: () => onPick(s.$1),
                ),
            ],
          ),
        if (concept == Concept.a) ...[
          const SizedBox(height: 22),
          kit.sectionHeader(context, title: l10n.assistantForYou),
          Row(
            children: [
              Expanded(child: _Insight(text: l10n.assistantInsight1)),
              const SizedBox(width: 10),
              Expanded(child: _Insight(text: l10n.assistantInsight2)),
            ],
          ),
        ],
      ],
    );
  }
}

/// An unsolicited observation, offered as a card. Only the poster design
/// does this: on the others it would read as the app talking over you.
class _Insight extends StatelessWidget {
  const _Insight({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    return kit.card(
      context,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: context.colors.primary,
          ),
          const SizedBox(height: 9),
          Text(text, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Text(
            context.l10n.actionSeeDetails,
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
