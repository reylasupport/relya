import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/concept/concept.dart';
import '../core/design/tokens/app_skin.dart';
import '../core/design/tokens/app_skin_style.dart';
import '../core/extensions/context_extensions.dart';
import '../features/capture/presentation/capture_sheet.dart';
import '../features/inbox/application/inbox_controller.dart';
import '../shared/data/providers.dart';
import 'routes.dart';
import 'shell_chrome.dart';

/// The five areas, plus the one button that matters most.
///
/// Capture is a floating button rather than a tab: it is an action, not a
/// place, and it stays reachable with a thumb from every screen in the shell.
const int _assistantTab = 4;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Roughly the height of the Home header. Past this the account avatar has
  /// left the screen, and the bar picks it up.
  static const double _headerHeight = 72;

  /// Home is the only tab that carries the avatar itself.
  static const int _homeTab = 0;

  bool _pastHeader = false;

  bool _onScroll(ScrollNotification notification) {
    // Horizontal lists - the category chips, the week strip - say nothing
    // about whether the header is still on screen.
    if (notification.metrics.axis != Axis.vertical) return false;
    // Only the page itself. A sheet or a dropdown scrolling over the top of
    // it must not move the bar underneath.
    if (notification.depth > 0) return false;

    final past = notification.metrics.pixels > _headerHeight;
    if (past != _pastHeader) setState(() => _pastHeader = past);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final pending = ref.watch(inboxPendingCountProvider);

    // Shown wherever the avatar has nowhere else to be: every tab but Home,
    // and Home itself once its header has scrolled away.
    final showProfile = navigationShell.currentIndex != _homeTab || _pastHeader;
    // Two reasons to drop the floating button: the pastel design carries its
    // own inside the bar, and on the Assistant tab it would sit on top of the
    // composer's send button.
    final hideFab =
        context.appSkin.nav != SkinNav.docked ||
        navigationShell.currentIndex == _assistantTab;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: navigationShell,
      ),
      // Hidden on the Assistant tab: it would sit on top of the composer's
      // send button, and nobody captures a receipt mid-conversation. There,
      // the primary action is the question being typed.
      floatingActionButton: hideFab
          ? null
          : CaptureButton(
              tooltip: context.l10n.captureTitle,
              onPressed: () => openCaptureSheet(context),
            ),
      bottomNavigationBar: RelyaNavBar(
        selectedIndex: navigationShell.currentIndex,
        pendingCount: pending,
        onCapture: () => openCaptureSheet(context),
        // Tapping the tab you are already on pops that branch back to its
        // root, which is what every native app does.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        showProfile: showProfile,
        profile: ref.watch(currentProfileProvider).valueOrNull,
        onProfile: () => context.push(Routes.settings),
      ),
    );
  }
}

/// Opens the capture flow the way the active design wants it opened.
///
/// Three designs present it as a bottom sheet. Concept F presents it as a
/// full page, so it gets a route rather than a sheet - pushing a Scaffold
/// inside a sheet would give it two backgrounds and no way back.
void openCaptureSheet(BuildContext context) {
  if (context.concept == Concept.f) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const CaptureSheet(),
      ),
    );
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const CaptureSheet(),
  );
}
