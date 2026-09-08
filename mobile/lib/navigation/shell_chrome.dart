import 'package:flutter/material.dart';

import '../core/design/tokens/app_skin.dart';
import '../core/design/tokens/app_skin_style.dart';
import '../core/design/tokens/app_semantic_colors.dart';
import '../core/extensions/context_extensions.dart';

/// One destination in the bar. Branch index, not slot index: the pastel
/// design leaves Inbox out of the bar, so the two stop matching.
class _Dest {
  const _Dest(this.branch, this.icon, this.activeIcon, this.label);

  final int branch;
  final IconData icon;
  final IconData activeIcon;
  final String Function(BuildContext) label;
}

List<_Dest> _all() => [
  _Dest(0, Icons.home_outlined, Icons.home_rounded, (c) => c.l10n.navHome),
  _Dest(1, Icons.inbox_outlined, Icons.inbox_rounded, (c) => c.l10n.navInbox),
  _Dest(
    2,
    Icons.calendar_today_outlined,
    Icons.calendar_today_rounded,
    (c) => c.l10n.navUpcoming,
  ),
  _Dest(
    3,
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
    (c) => c.l10n.navLife,
  ),
  _Dest(
    4,
    Icons.auto_awesome_outlined,
    Icons.auto_awesome_rounded,
    (c) => c.l10n.navAssistant,
  ),
];

/// The areas of the app, drawn the way the active design draws them.
///
/// Hand-built rather than a NavigationBar because the four concepts disagree
/// about the two things a NavigationBar decides for you: whether the selected
/// destination gets a pill, and whether the capture button belongs inside the
/// bar or above it.
class RelyaNavBar extends StatelessWidget {
  const RelyaNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.pendingCount = 0,
    this.onCapture,
  });

  /// The current branch. May be a branch that has no slot in this design, in
  /// which case nothing is highlighted.
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Captures still waiting for a look. Zero hides the badge entirely: a
  /// number that is always there stops being a signal.
  final int pendingCount;

  /// Only used by the design that sinks the capture button into the bar.
  final VoidCallback? onCapture;

  @override
  Widget build(BuildContext context) {
    final skin = context.appSkin;
    final colors = context.colors;
    final centre = skin.nav == SkinNav.centre;

    final dests = centre ? _all().where((d) => d.branch != 1).toList() : _all();

    final slots = <Widget>[];
    for (var i = 0; i < dests.length; i++) {
      if (centre && i == 2) {
        slots.add(
          SizedBox(
            width: 76,
            child: Center(
              child: CaptureButton(
                tooltip: context.l10n.captureTitle,
                onPressed: onCapture ?? () {},
                size: 50,
              ),
            ),
          ),
        );
      }
      final d = dests[i];
      slots.add(
        Expanded(
          child: _NavSlot(
            dest: d,
            selected: d.branch == selectedIndex,
            badge: d.branch == 1 ? pendingCount : 0,
            onTap: () => onSelected(d.branch),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.semantic.subtleBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(height: 62, child: Row(children: slots)),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.dest,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _Dest dest;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.onSurfaceVariant;
    // Midnight is the only design that marks the selected destination with a
    // shape as well as a colour.
    final pill = selected && context.appSkin.navIndicator;

    Widget icon = Icon(
      selected ? dest.activeIcon : dest.icon,
      size: 23,
      color: tint,
    );
    if (badge > 0) {
      icon = Badge.count(count: badge, child: icon);
    }
    if (pill) {
      icon = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: icon,
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(
              dest.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: tint,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The capture button, in the brand gradient.
///
/// It is the only control in the app that carries the gradient, which is what
/// makes it read as the primary thing to do rather than as one more icon.
class CaptureButton extends StatelessWidget {
  const CaptureButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.size = 58,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    // The sage-and-sand gradient of the cosy theme is pale enough that a white
    // plus disappears into it. The glyph follows the gradient, not a constant.
    final start = (context.skin.gradient as LinearGradient).colors.first;
    final onGradient =
        ThemeData.estimateBrightnessForColor(start) == Brightness.light
        ? const Color(0xFF14120F)
        : Colors.white;

    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // The theme's own gradient, not the brand's: the button has to
            // belong to whichever skin the user picked.
            gradient: context.skin.gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Icon(
                Icons.add_rounded,
                size: size * 0.52,
                color: onGradient,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
