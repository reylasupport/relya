/// Every path in the app, in one place. Nothing types a route string inline.
abstract final class Routes {
  const Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/auth';
  static const String checkEmail = '/auth/check-email';

  static const String home = '/home';
  static const String inbox = '/inbox';
  static const String upcoming = '/upcoming';
  static const String life = '/life';
  static const String assistant = '/assistant';

  // There is deliberately no /capture route. Capture is a modal sheet on
  // three designs and a full page on the fourth, and both are opened by
  // openCaptureSheet() rather than by navigation.
  static const String captureText = '/capture/text';
  static const String captureManual = '/capture/manual';
  static const String captureQuickAdd = '/capture/quick-add';

  static String analysis(String captureId) => '/analysis/$captureId';
  static const String analysisPattern = '/analysis/:captureId';

  static String item(String id) => '/item/$id';
  static const String itemPattern = '/item/:itemId';

  static String itemEdit(String id) => '/item/$id/edit';
  static const String itemEditPattern = '/item/:itemId/edit';

  static String entity(String id) => '/life/$id';
  static const String entityPattern = ':entityId';

  static const String search = '/search';
  static const String paywall = '/paywall';

  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsLanguage = '/settings/language';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsEmailInbox = '/settings/email';
  static const String settingsAbout = '/settings/about';
}
