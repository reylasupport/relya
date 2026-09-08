import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/concept/concept.dart';
import '../core/design/tokens/app_skin.dart';
import '../core/design/tokens/app_skin_style.dart';
import '../core/extensions/context_extensions.dart';
import '../features/capture/presentation/capture_sheet.dart';
import '../features/inbox/application/inbox_controller.dart';
import 'shell_chrome.dart';

/// The five areas, plus the one button that matters most.
///
/// Capture is a floating button rather than a tab: it is an action, not a
/// place, and it stays reachable with a thumb from every screen in the shell.
const int _assistantTab = 4;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(inboxPendingCountProvider);
    // Two reasons to drop the floating button: the pastel design carries its
    // own inside the bar, and on the Assistant tab it would sit on top of the
    // composer's send button.
    final hideFab =
        context.appSkin.nav == SkinNav.centre ||
        navigationShell.currentIndex == _assistantTab;

    return Scaffold(
      body: navigationShell,
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
