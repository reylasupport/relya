/// The event catalogue (spec section 37).
///
/// Deliberately short. Every event here answers a question we have actually
/// asked; anything else is data we would be collecting because we can, which
/// is exactly what the privacy promise rules out.
abstract final class AnalyticsEvents {
  const AnalyticsEvents._();

  static const String appOpened = 'app_opened';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String signedUp = 'signed_up';

  static const String captureStarted = 'capture_started';

  /// The one that matters most. Fired when an extraction produced at least one
  /// item and the user accepted it. Everything else is secondary to moving
  /// this number.
  static const String firstSuccessfulCapture = 'first_successful_capture';

  static const String captureCompleted = 'capture_completed';
  static const String extractionFailed = 'extraction_failed';
  static const String extractionCorrected = 'extraction_corrected';

  static const String reminderCreated = 'reminder_created';
  static const String reminderOpened = 'reminder_opened';
  static const String calendarEventAdded = 'calendar_event_added';

  static const String assistantAsked = 'assistant_asked';
  static const String searchPerformed = 'search_performed';

  static const String paywallShown = 'paywall_shown';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRestored = 'subscription_restored';
  static const String quotaReached = 'quota_reached';
}

/// Property keys, so a typo cannot silently split a metric in two.
abstract final class AnalyticsProps {
  const AnalyticsProps._();

  static const String source = 'source';
  static const String kind = 'kind';
  static const String category = 'category';
  static const String itemCount = 'item_count';
  static const String confidence = 'confidence';
  static const String plan = 'plan';
  static const String durationMs = 'duration_ms';
}
