import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// Turns whatever the network threw into the small set of failures the UI
/// knows how to talk about.
///
/// Kept apart from the repositories on purpose. The repositories are Postgres
/// query builders and storage calls, which are awkward to fake and dull to
/// assert on; this is the part that decides what the user is told, which is
/// the part worth pinning down. Every Supabase implementation in the app was
/// at zero coverage, so the one piece of policy inside them now lives where a
/// test can reach it.
abstract final class SupabaseErrors {
  const SupabaseErrors._();

  /// HTTP 429 from an edge function. Both `analyze-capture` and
  /// `ask-assistant` answer with it when an allowance is spent, and it is the
  /// one failure that is not a fault: the request succeeds later, unchanged.
  static const int tooManyRequests = 429;

  /// Maps a failure from an edge function call.
  ///
  /// [quotaMessage] is what a 429 means for this particular call - a monthly
  /// capture allowance and a daily assistant ceiling are different limits and
  /// read differently to whoever hits them.
  static AppException fromFunction(
    Object error, {
    required String quotaMessage,
  }) {
    if (error is FunctionException && error.status == tooManyRequests) {
      return QuotaExceeded(quotaMessage, cause: error);
    }
    return fromAny(error);
  }

  /// Maps anything else: a query, an upload, a plain call.
  static AppException fromAny(Object error) {
    if (error is AppException) return error;

    if (error is SocketException || error is TimeoutException) {
      return const NetworkException();
    }

    if (error is AuthException) {
      return AuthFailure(error.message, cause: error);
    }

    if (error is StorageException) {
      return StorageFailure(error.message, cause: error);
    }

    // A Postgres error is never shown raw: the message names columns and
    // constraints, which tells the user nothing and tells an attacker
    // something.
    if (error is PostgrestException) {
      return UnexpectedFailure('Request failed', cause: error);
    }

    return UnexpectedFailure('Request failed', cause: error);
  }
}
