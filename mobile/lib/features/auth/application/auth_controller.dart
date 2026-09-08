import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/data/providers.dart';
import '../data/mock_auth_service.dart';
import '../data/supabase_auth_service.dart';
import '../domain/auth_service.dart';
import '../domain/auth_state.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  if (AppEnv.useMockData) return MockAuthService();
  return SupabaseAuthService(ref.watch(supabaseServiceProvider));
});

/// Current session, as a stream the router listens to.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.changes;
});

/// Creating an account and signing in are the same screen in two modes.
/// Apple and Google do not distinguish between them at all; only the email
/// path does, and only in what it calls the button.
enum AuthMode { signUp, signIn }

class SignInUiState {
  const SignInUiState({
    this.mode = AuthMode.signUp,
    this.inFlight,
    this.error,
    this.linkSentTo,
    this.resetSentTo,
    this.confirmSentTo,
  });

  final AuthMode mode;
  final AuthProviderKind? inFlight;
  final Object? error;
  final String? linkSentTo;
  final String? resetSentTo;

  /// The account was created and is waiting for the six-digit code that was
  /// emailed to this address. While it is set, the gate shows the code field
  /// instead of the sign-up form: there is exactly one thing to do next.
  final String? confirmSentTo;

  bool get awaitingCode => confirmSentTo != null;

  bool get isBusy => inFlight != null;

  bool get isSignUp => mode == AuthMode.signUp;

  SignInUiState copyWith({AuthMode? mode}) =>
      SignInUiState(mode: mode ?? this.mode);
}

/// Drives the sign-in screen: which mode it is in, which provider is in
/// flight, and what failed.
class SignInController extends StateNotifier<SignInUiState> {
  SignInController(this._service) : super(const SignInUiState());

  final AuthService _service;

  void setMode(AuthMode mode) => state = SignInUiState(mode: mode);

  /// Back out of the code screen without losing the chosen mode.
  void cancelConfirmation() => state = SignInUiState(mode: state.mode);

  /// Exchanges the emailed code for a session.
  Future<void> verifyCode(String code) async {
    final email = state.confirmSentTo;
    if (email == null) return;
    state = SignInUiState(
      mode: state.mode,
      confirmSentTo: email,
      inFlight: AuthProviderKind.password,
    );
    try {
      await _service.verifySignUpCode(email, code);
      // The router leaves the gate on the auth stream; clearing the state
      // here only stops the code field flashing back on the way out.
      state = SignInUiState(mode: state.mode);
    } catch (error) {
      AppLogger.warn('Code verification failed', error);
      state = SignInUiState(
        mode: state.mode,
        confirmSentTo: email,
        error: error,
      );
    }
  }

  Future<void> resendCode() async {
    final email = state.confirmSentTo;
    if (email == null) return;
    state = SignInUiState(
      mode: state.mode,
      confirmSentTo: email,
      inFlight: AuthProviderKind.password,
    );
    try {
      await _service.resendSignUpCode(email);
      state = SignInUiState(
        mode: state.mode,
        confirmSentTo: email,
        linkSentTo: email,
      );
    } catch (error) {
      state = SignInUiState(
        mode: state.mode,
        confirmSentTo: email,
        error: error,
      );
    }
  }

  Future<void> signIn(
    AuthProviderKind kind, {
    String? email,
    String? password,
  }) async {
    state = SignInUiState(mode: state.mode, inFlight: kind);
    try {
      switch (kind) {
        case AuthProviderKind.apple:
          await _service.signInWithApple();
        case AuthProviderKind.google:
          await _service.signInWithGoogle();
        case AuthProviderKind.magicLink:
          await _service.sendMagicLink(email!);
          state = SignInUiState(mode: state.mode, linkSentTo: email);
          return;
        case AuthProviderKind.password:
          if (state.isSignUp) {
            final result = await _service.signUpWithPassword(email!, password!);
            // Signing up with "Confirm email" on creates the account and
            // returns no session on purpose. That is a success, not a
            // failure, and it needs saying out loud.
            if (result is! AuthSignedIn) {
              state = SignInUiState(mode: state.mode, confirmSentTo: email);
              return;
            }
          } else {
            await _service.signInWithPassword(email!, password!);
          }
      }
      state = SignInUiState(mode: state.mode);
    } catch (error) {
      AppLogger.warn('Auth failed via ${kind.name}', error);
      state = SignInUiState(mode: state.mode, error: error);
    }
  }

  Future<void> sendReset(String email) async {
    state = SignInUiState(
      mode: state.mode,
      inFlight: AuthProviderKind.password,
    );
    try {
      await _service.sendPasswordReset(email);
      state = SignInUiState(mode: state.mode, resetSentTo: email);
    } catch (error) {
      state = SignInUiState(mode: state.mode, error: error);
    }
  }

  void clearFeedback() => state = SignInUiState(mode: state.mode);
}

final signInControllerProvider =
    StateNotifierProvider<SignInController, SignInUiState>(
      (ref) => SignInController(ref.watch(authServiceProvider)),
    );
