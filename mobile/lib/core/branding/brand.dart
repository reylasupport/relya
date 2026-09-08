import 'package:flutter/material.dart';

/// Single source of truth for everything name- and identity-related.
///
/// Rebranding means editing this file (plus env/*.json, the launcher icons and
/// the store listings) - never grepping the codebase. Nothing else may
/// hardcode the product name.
abstract final class Brand {
  const Brand._();

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Relya',
  );

  /// Short promise. Used on the splash and the first onboarding slide.
  static const String tagline = String.fromEnvironment(
    'APP_TAGLINE',
    defaultValue: 'Send anything. I remember.',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@relya.app',
  );

  static const String website = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://relya.app',
  );

  static const String privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://relya.app/privacy',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://relya.app/terms',
  );

  /// Domain that receives forwarded email, e.g. "in.relya.app". Empty until
  /// the MX records and the inbound provider are configured; every surface
  /// that shows a forwarding address checks [hasEmailInbox] first, so an
  /// unconfigured build simply does not offer the feature.
  static const String emailInboxDomain = String.fromEnvironment(
    'EMAIL_INBOX_DOMAIN',
  );

  static bool get hasEmailInbox => emailInboxDomain.isNotEmpty;

  /// Custom URL scheme for notification deep links and OAuth callbacks.
  static const String urlScheme = String.fromEnvironment(
    'URL_SCHEME',
    defaultValue: 'relya',
  );

  /// Seed for the Material colour scheme, and the base of the logo gradient.
  static const Color seedColor = Color(0xFF3D5AFE);

  /// The second stop of the brand gradient. Warm violet against the cool
  /// primary: it is what stops the identity reading as generic tech blue.
  static const Color accentColor = Color(0xFF9B5CFF);
}
