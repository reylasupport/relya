import 'app_env.dart';

/// The account the fixtures belong to, typed in for you.
///
/// It exists so the product can be opened and walked through in one tap, with
/// no Supabase project, no network and no sign-up. MockAuthService accepts
/// whatever it is given, so these values are here to be recognisable rather
/// than to be checked.
///
/// Gated on [AppEnv.useMockData] and on nothing else. A build that talks to a
/// real backend must never put a password into a field on its own, however
/// harmless that password is: the habit is the risk, not this string.
abstract final class DemoAccount {
  const DemoAccount._();

  static const String email = 'demo@relya.app';

  /// Eight characters is the app's own minimum, so the form accepts it
  /// without the demo having to be a special case in the validator.
  static const String password = 'relya-demo';

  static bool get isAvailable => AppEnv.useMockData;

  /// What the sign-in form starts with. Empty everywhere that matters.
  static String get prefilledEmail => isAvailable ? email : '';

  static String get prefilledPassword => isAvailable ? password : '';
}
