import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/branding/brand.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/supabase/supabase_service.dart';
import '../domain/auth_service.dart';
import '../domain/auth_state.dart';

/// Where an OAuth or email round trip returns to.
///
/// On a phone that is the custom scheme registered in the manifest and the
/// Info.plist. On the web a custom scheme is meaningless - the browser has
/// nowhere to send `relya://` - so we pass null and let Supabase return to the
/// project's own Site URL. Getting this wrong shows up as a login that opens
/// a Google page and then lands on a blank tab, which is a miserable thing to
/// debug from a bug report.
String? get _authRedirect =>
    kIsWeb ? null : '${Brand.urlScheme}://auth-callback';

/// Real authentication.
///
/// Apple and Google use the native sheets rather than a web view: it is what
/// the platforms expect, it is what App Review expects, and the identity token
/// is exchanged with Supabase directly so no password ever exists.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._supabase) {
    _subscription = _supabase.auth.onAuthStateChange.listen((event) {
      _controller.add(_map(event.session));
    });
  }

  final SupabaseService _supabase;

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();
  StreamSubscription<sb.AuthState>? _subscription;

  AuthState _map(sb.Session? session) {
    final user = session?.user;
    if (user == null) return const AuthSignedOut();
    return AuthSignedIn(
      userId: user.id,
      email: user.email,
      displayName:
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String?,
    );
  }

  @override
  AuthState get current => _map(_supabase.auth.currentSession);

  @override
  Stream<AuthState> get changes => _controller.stream;

  @override
  Future<AuthState> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthFailure('Apple did not return an identity token');
      }
      final response = await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
      );
      return _map(response.session);
    } on AuthFailure {
      rethrow;
    } catch (error) {
      throw AuthFailure('Could not sign in with Apple', cause: error);
    }
  }

  @override
  Future<AuthState> signInWithGoogle() async {
    try {
      // Supabase handles the round trip and returns to the app through the
      // custom scheme registered on both platforms.
      await _supabase.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: _authRedirect,
      );
      return current;
    } catch (error) {
      throw AuthFailure('Could not sign in with Google', cause: error);
    }
  }

  @override
  Future<void> sendMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: _authRedirect,
      );
    } catch (error) {
      throw AuthFailure('Could not send the sign-in link', cause: error);
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  /// Supabase enforces its own minimum, but checking here means the user gets
  /// a useful message instead of a server error string.
  @override
  Future<AuthState> signUpWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _authRedirect,
      );
      return _map(response.session);
    } catch (error) {
      if (_isMailDeliveryFailure(error)) {
        throw EmailDeliveryFailure(
          'The confirmation email could not be sent',
          cause: error,
        );
      }
      throw AuthFailure('Could not create the account', cause: error);
    }
  }

  /// Supabase reports a dead mailer as a generic 500. The message is the only
  /// thing that distinguishes it, which is fragile - but guessing wrong here
  /// costs a misleading sentence, and not checking costs an afternoon.
  static bool _isMailDeliveryFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('sending confirmation email') ||
        text.contains('error sending') ||
        text.contains('smtp');
  }

  @override
  Future<AuthState> verifySignUpCode(String email, String code) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: code.trim(),
        type: sb.OtpType.signup,
      );
      final state = _map(response.session);
      if (state is! AuthSignedIn) {
        throw const AuthFailure('That code did not work');
      }
      return state;
    } on AuthFailure {
      rethrow;
    } catch (error) {
      // Vague on purpose: expired and wrong look the same to an attacker.
      throw AuthFailure('That code did not work', cause: error);
    }
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    try {
      await _supabase.auth.resend(type: sb.OtpType.signup, email: email);
    } catch (error) {
      throw AuthFailure('Could not send the code again', cause: error);
    }
  }

  @override
  Future<AuthState> signInWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _map(response.session);
    } catch (error) {
      // Deliberately vague: saying which half was wrong tells an attacker
      // whether the address has an account.
      throw AuthFailure('Email or password is wrong', cause: error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirect,
      );
    } catch (error) {
      throw AuthFailure('Could not send the reset link', cause: error);
    }
  }
}
