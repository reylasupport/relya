/// Who is signed in, as far as the app is concerned.
sealed class AuthState {
  const AuthState();
}

/// Before the stored session has been read. The router holds on the splash
/// rather than flashing the sign-in screen at a user who is already signed in.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.reason});

  final String? reason;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn({required this.userId, this.email, this.displayName});

  final String userId;
  final String? email;
  final String? displayName;
}
