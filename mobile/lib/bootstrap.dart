import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/logging/app_logger.dart';
import 'services/notifications/notification_service.dart';
import 'services/prefs/local_prefs.dart';
import 'services/supabase/supabase_service.dart';
import 'shared/data/providers.dart';

/// Starts the app with everything that must exist before the first frame, and
/// nothing that does not.
///
/// Slow, non-essential work (the share listener, analytics identify) happens
/// after the first frame instead, because time to first paint is the part of
/// performance users actually feel.
Future<void> bootstrap() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  for (final issue in AppEnv.validate()) {
    AppLogger.warn('Configuration: $issue');
  }

  final overrides = <Override>[];

  final prefs = await LocalPrefs.load();
  overrides.add(localPrefsProvider.overrideWithValue(prefs));

  if (!AppEnv.useMockData) {
    final supabase = await SupabaseService.initialise();
    overrides.add(supabaseServiceProvider.overrideWithValue(supabase));
  }

  try {
    final notifications = await NotificationService.initialise();
    overrides.add(notificationServiceProvider.overrideWithValue(notifications));
  } catch (error, stack) {
    // A device that will not give us notifications is still a usable app.
    AppLogger.error('Notifications unavailable', error, stack);
  }

  _installErrorHandlers();

  Widget root() => ProviderScope(overrides: overrides, child: const RelyaApp());

  if (AppEnv.hasCrashReporting) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppEnv.sentryDsn;
        options.environment = AppEnv.flavor.name;
        // Crash reports must never carry a document, a title or an address.
        options.sendDefaultPii = false;
        options.tracesSampleRate = AppEnv.isProd ? 0.1 : 1.0;
        options.beforeSend = (event, hint) => _scrub(event);
      },
      appRunner: () {
        // Warnings and errors become breadcrumbs, so a crash report carries the
        // shape of what went wrong without carrying any of the content.
        AppLogger.sink = (level, message, error) {
          Sentry.addBreadcrumb(
            Breadcrumb(
              message: message,
              level: level == LogLevel.error
                  ? SentryLevel.error
                  : SentryLevel.warning,
            ),
          );
        };
        runApp(root());
      },
    );
    return;
  }

  binding.addPostFrameCallback((_) => AppLogger.info('First frame'));
  runApp(root());
}

void _installErrorHandlers() {
  FlutterError.onError = (details) {
    AppLogger.error(
      details.summary.toString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught', error, stack);
    return true;
  };
}

/// Last line of defence before anything leaves the device: strip the request
/// bodies and breadcrumb data that could contain a user document.
SentryEvent? _scrub(SentryEvent event) {
  return event.copyWith(
    request: null,
    breadcrumbs: event.breadcrumbs
        ?.map((crumb) => crumb.copyWith(data: const {}))
        .toList(),
  );
}
