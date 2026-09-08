import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../../core/config/app_env.dart';
import '../../core/logging/app_logger.dart';

/// Product analytics.
///
/// Two rules: never send anything a user wrote or a document contained, and
/// stop entirely when consent is withdrawn. Event names and counts, never
/// content.
abstract interface class AnalyticsService {
  Future<void> identify(String userId);

  Future<void> track(String event, {Map<String, Object>? properties});

  Future<void> screen(String name);

  Future<void> setEnabled(bool enabled);

  Future<void> reset();
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> track(String event, {Map<String, Object>? properties}) async {
    AppLogger.debug('analytics: $event');
  }

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> reset() async {}
}

class PostHogAnalyticsService implements AnalyticsService {
  PostHogAnalyticsService();

  bool _enabled = true;

  @override
  Future<void> identify(String userId) async {
    if (!_enabled) return;
    // The id only. No email, no name: the backend can join if it ever needs to.
    await Posthog().identify(userId: userId);
  }

  @override
  Future<void> track(String event, {Map<String, Object>? properties}) async {
    if (!_enabled) return;
    await Posthog().capture(eventName: event, properties: properties);
  }

  @override
  Future<void> screen(String name) async {
    if (!_enabled) return;
    await Posthog().screen(screenName: name);
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    enabled ? await Posthog().enable() : await Posthog().disable();
  }

  @override
  Future<void> reset() => Posthog().reset();
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (!AppEnv.hasAnalytics) return const NoopAnalyticsService();
  return PostHogAnalyticsService();
});
