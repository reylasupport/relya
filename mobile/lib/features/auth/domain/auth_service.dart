import 'auth_state.dart';

/// Sign-in methods offered. Apple is mandatory on iOS whenever another social
/// provider is offered, so it is always first in the UI (spec section 32).
enum AuthProviderKind { apple, google, magicLink, password }

abstract interface class AuthService {
  Stream<AuthState> get changes;

  AuthState get current;

  Future<AuthState> signInWithApple();

  Future<AuthState> signInWithGoogle();

  /// Sends a one-time link. No password is created, so there is no password
  /// for us to store or for anyone to steal. Still the recommended path.
  Future<void> sendMagicLink(String email);

  /// Registers with an email and a password, for people who want an account
  /// that does not depend on Apple or Google.
  Future<AuthState> signUpWithPassword(String email, String password);

  Future<AuthState> signInWithPassword(String email, String password);

  /// Confirms a new account with the six-digit code emailed to it.
  ///
  /// A code rather than a link because a link opens a browser, and the person
  /// is already holding the app with the keyboard up. It also survives the
  /// email being read on a different device from the one signing up.
  Future<AuthState> verifySignUpCode(String email, String code);

  /// Sends the confirmation code again. Rate limited on the server; the UI
  /// still has to stop somebody hammering it.
  Future<void> resendSignUpCode(String email);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
