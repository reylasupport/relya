import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import '../services/notifications/notification_service.dart';
import '../services/share_intake/share_intake_service.dart';
import 'router.dart';
import 'routes.dart';

/// Sits just inside the router and turns two outside events into navigation:
/// something was shared into the app, and a reminder was tapped.
///
/// Both have to work from a cold start, which is why the listeners are
/// attached here rather than in a screen: by the time any screen exists, a
/// cold-start share has already been delivered.
class ShareIntakeGate extends ConsumerStatefulWidget {
  const ShareIntakeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShareIntakeGate> createState() => _ShareIntakeGateState();
}

class _ShareIntakeGateState extends ConsumerState<ShareIntakeGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    final router = ref.read(routerProvider);

    final share = ref.read(shareIntakeServiceProvider);
    share.createdCaptures.listen((captureId) {
      if (!mounted) return;
      router.push(Routes.analysis(captureId));
    });
    // Not every platform has a share sheet. A build that cannot listen for
    // one is still a working app, so this must not take the launch down.
    share.start().catchError((Object error, StackTrace stack) {
      AppLogger.error('Share intake unavailable', error, stack);
    });

    // Notifications are optional: on a build without them configured the
    // provider is not overridden, and a tapped reminder simply opens the app.
    try {
      final notifications = ref.read(notificationServiceProvider);

      notifications.taps.listen((itemId) {
        if (!mounted) return;
        router.push(Routes.item(itemId));
      });

      // A reminder tapped while the app was not running is delivered here
      // rather than on the stream, so it needs asking for once at startup.
      notifications
          .launchPayload()
          .then((itemId) {
            if (itemId == null || !mounted) return;
            router.push(Routes.item(itemId));
          })
          .catchError((Object error, StackTrace stack) {
            AppLogger.error(
              'Could not read the launch notification',
              error,
              stack,
            );
          });
    } on StateError {
      // No notification service in this build.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
