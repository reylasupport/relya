import 'app_env.dart';

/// Gates for work beyond the MVP. Everything false here is architecture that
/// exists but is deliberately not exposed yet (spec section 55).
abstract final class FeatureFlags {
  const FeatureFlags._();

  /// Life Graph entity inference across captures. Schema and screens exist;
  /// automatic linking does not run in V1.
  static const bool lifeGraphAutoLinking = false;

  /// Natural-language questions over the user's own data.
  static const bool assistantChat = true;

  /// Create reminders without a confirmation tap (spec 53). Off by default and
  /// opt-in forever - the app suggests, the user decides.
  static const bool autoApplySuggestions = false;

  /// Family plan (spec 35). Not in V1.
  static const bool familyPlan = false;

  /// Let the user keep only extracted data and discard the original file.
  static const bool originalFileRetentionChoice = true;

  /// Whether this build has anything to sell.
  ///
  /// A mock build sells the mock offer, so the paywall stays reviewable
  /// without a store account. A real build with no RevenueCat key has nothing
  /// to sell at all, and an upgrade button that ends in an error is worse than
  /// no upgrade button - the same rule Brand.hasEmailInbox already follows.
  static bool get paywallEnabled =>
      AppEnv.useMockData || AppEnv.hasSubscriptions;
}
