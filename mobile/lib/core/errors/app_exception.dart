/// Every failure the user can see is one of these. Keeping the set small lets
/// the UI map failures to calm, specific copy instead of dumping a stack trace.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No connection']);
}

class AuthFailure extends AppException {
  const AuthFailure(super.message, {super.cause});
}

/// The account could not be created because the confirmation email could not
/// be sent. Always a server-side configuration problem - missing or wrong
/// SMTP settings, or a sender the provider will not accept - never something
/// the person at the keyboard can fix by trying again.
class EmailDeliveryFailure extends AppException {
  const EmailDeliveryFailure(super.message, {super.cause});
}

class PermissionDenied extends AppException {
  const PermissionDenied(super.message, {this.permission, super.cause});

  final String? permission;
}

/// The model returned something that did not survive schema validation, or the
/// pipeline gave up. Never silently swallowed: the capture is marked failed and
/// the user is told, because hiding uncertainty is the one thing we must not do.
class ExtractionFailure extends AppException {
  const ExtractionFailure(super.message, {super.cause});
}

/// Free-plan capture quota, or a server-side rate limit.
class QuotaExceeded extends AppException {
  const QuotaExceeded(super.message, {this.resetsAt, super.cause});

  final DateTime? resetsAt;
}

class StorageFailure extends AppException {
  const StorageFailure(super.message, {super.cause});
}

class UnexpectedFailure extends AppException {
  const UnexpectedFailure(super.message, {super.cause});
}
