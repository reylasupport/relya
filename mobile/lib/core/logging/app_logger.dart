import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Thin logging seam. In debug it prints; in release it is a no-op apart from
/// warnings and errors, which the crash reporter picks up as breadcrumbs.
///
/// Never log capture content, extracted fields, tokens or file contents. The
/// app handles medical appointments and passport numbers; logs are the easiest
/// place to leak them by accident.
abstract final class AppLogger {
  const AppLogger._();

  static void Function(LogLevel level, String message, Object? error)? sink;

  static void debug(String message) =>
      _log(LogLevel.debug, message, null, null);

  static void info(String message) => _log(LogLevel.info, message, null, null);

  static void warn(String message, [Object? error]) =>
      _log(LogLevel.warning, message, error, null);

  static void error(String message, Object? error, [StackTrace? stack]) =>
      _log(LogLevel.error, message, error, stack);

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    if (kDebugMode) {
      developer.log(
        message,
        name: level.name.toUpperCase(),
        error: error,
        stackTrace: stack,
      );
    }
    if (level == LogLevel.warning || level == LogLevel.error) {
      sink?.call(level, message, error);
    }
  }
}
