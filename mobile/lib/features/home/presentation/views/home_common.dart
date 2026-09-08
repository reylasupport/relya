import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../navigation/routes.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../application/home_controller.dart';

/// What every Home view is handed. The data is identical; only the
/// arrangement differs, which is the whole point of having four of them.
abstract class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.data,
    required this.profile,
    required this.pending,
  });

  final HomeSnapshot data;
  final UserProfile? profile;
  final int pending;

  /// "Good evening, Joao". Time of day is the only variable; the designs
  /// disagree about how loudly to say it, not about what it says.
  String greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final name = profile?.firstName;
    final suffix = name == null ? '' : ', $name';
    if (hour < 12) return context.l10n.greetingMorning(suffix);
    if (hour < 19) return context.l10n.greetingAfternoon(suffix);
    return context.l10n.greetingEvening(suffix);
  }

  Widget avatar(BuildContext context) => ProfileAvatar(
    profile: profile,
    onTap: () => context.push(Routes.settings),
    semanticLabel: context.l10n.accountTitle,
  );

  /// The inbox, reachable from the header. Carries the pending badge, so a
  /// design that drops the Inbox destination from the bar still shows it.
  Widget inboxBell(BuildContext context, {IconData? icon}) => IconButton(
    onPressed: () => context.go(Routes.inbox),
    tooltip: context.l10n.navInbox,
    icon: Badge.count(
      count: pending,
      isLabelVisible: pending > 0,
      child: Icon(icon ?? Icons.notifications_none_rounded),
    ),
  );
}

/// The way into the assistant, as a field rather than a button: the question
/// is the point, and a button would make it feel like a feature.
class AskBar extends StatelessWidget {
  const AskBar({
    super.key,
    required this.gutter,
    this.radius = 999,
    this.filled = true,
  });

  final double gutter;
  final double radius;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Material(
        color: filled ? context.colors.surfaceContainer : Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: () => context.push(Routes.assistant),
          borderRadius: shape,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: context.colors.outlineVariant),
            ),
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.homeAskPlaceholder,
                    style: context.text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
