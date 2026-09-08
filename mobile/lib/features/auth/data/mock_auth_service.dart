import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../domain/auth_service.dart';
import '../domain/auth_state.dart';

/// Signs in instantly. Lets the whole product be walked through, demoed and
/// widget-tested without a Supabase project.
class MockAuthService implements AuthService {
  MockAuthService({bool startSignedIn = false})
    : _state = startSignedIn
          ? const AuthSignedIn(
              userId: 'mock-user',
              email: 'joao@example.com',
              displayName: 'Joao',
            )
          : const AuthSignedOut();

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  AuthState _state;

  @override
  AuthState get current => _state;

  @override
  Stream<AuthState> get changes => _controller.stream;

  void _emit(AuthState state) {
    _state = state;
    _controller.add(state);
  }

  Future<AuthState> _fakeSignIn(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    const signedIn = AuthSignedIn(
      userId: 'mock-user',
      email: 'joao@example.com',
      displayName: 'Joao',
    );
    _emit(signedIn);
    return signedIn;
  }

  @override
  Future<AuthState> signInWithApple() => _fakeSignIn('Apple');

  @override
  Future<AuthState> signInWithGoogle() => _fakeSignIn('Google');

  @override
  Future<void> sendMagicLink(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> signOut() async {
    _emit(const AuthSignedOut());
  }

  @override
  Future<AuthState> signUpWithPassword(String email, String password) =>
      _fakeSignIn(email);

  @override
  Future<AuthState> signInWithPassword(String email, String password) =>
      _fakeSignIn(email);

  /// Any six digits pass. The mock exists so the flow can be walked without a
  /// backend; refusing a code here would only test the mock.
  @override
  Future<AuthState> verifySignUpCode(String email, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code.trim().length != 6) {
      throw const AuthFailure('That code did not work');
    }
    return _fakeSignIn(email);
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
