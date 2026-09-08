/// Build-time configuration, supplied with --dart-define-from-file.
///
/// Nothing here is confidential. Anything inside a mobile binary is readable by
/// anyone holding that binary, so only publishable values live here: the
/// Supabase project URL and anon token (both gated by Row Level Security) and
/// the RevenueCat public SDK identifiers. AI provider credentials, the Supabase
/// service role token and webhook signing values exist only as Edge Function
/// environment variables on the server.
enum AppFlavor { dev, staging, prod }

abstract final class AppEnv {
  const AppEnv._();

  static const String _flavorRaw = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  static AppFlavor get flavor => switch (_flavorRaw) {
    'prod' => AppFlavor.prod,
    'staging' => AppFlavor.staging,
    _ => AppFlavor.dev,
  };

  static bool get isProd => flavor == AppFlavor.prod;

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase renamed the anon key to the publishable key; both names are
  /// accepted so existing .env files keep working.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const String revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
  );
  static const String revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
  );

  static const String posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Runs the whole app against in-memory fixtures. Lets the UI be built and
  /// demoed before any backend exists, and keeps widget tests hermetic.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get hasAnalytics => posthogApiKey.isNotEmpty;

  /// RevenueCat is per-platform, and a build cut for one store legitimately
  /// carries only that store's key.
  static bool get hasSubscriptions =>
      revenueCatIosKey.isNotEmpty || revenueCatAndroidKey.isNotEmpty;

  static bool get hasCrashReporting => sentryDsn.isNotEmpty;

  /// Misconfigurations worth failing loudly on at boot, rather than showing a
  /// blank screen an hour later.
  static List<String> validate() {
    final issues = <String>[];
    if (!useMockData && !hasSupabase) {
      issues.add('Supabase configuration missing while USE_MOCK_DATA is false');
    }
    if (isProd && useMockData) {
      issues.add('USE_MOCK_DATA must be false in a production build');
    }
    // Everything below was silent until now, which is how a production build
    // shipped with the paywall on, nothing to sell behind it, and no crash
    // reporting to tell anybody.
    if (!useMockData && !hasSubscriptions) {
      issues.add('RevenueCat keys missing: the paywall has nothing to sell');
    }
    if (isProd && !hasCrashReporting) {
      issues.add('SENTRY_DSN missing in a production build');
    }
    if (isProd && !hasAnalytics) {
      issues.add('POSTHOG_API_KEY missing in a production build');
    }
    return issues;
  }
}
