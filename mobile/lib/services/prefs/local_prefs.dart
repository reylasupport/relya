import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-sensitive device state. Anything private goes in secure storage
/// instead; this holds flags that would be harmless in a backup.
class LocalPrefs {
  LocalPrefs(this._prefs);

  static const String _onboardingSeen = 'onboarding_seen_v1';
  static const String _shareHintShown = 'share_hint_shown_v1';
  static const String _lastTimezone = 'last_timezone';
  static const String _firstCaptureTracked = 'first_capture_tracked_v1';
  static const String _notificationsExplained = 'notifications_explained_v1';
  static const String _inCalendar = 'items_in_calendar_v1';

  final SharedPreferences _prefs;

  static Future<LocalPrefs> load() async =>
      LocalPrefs(await SharedPreferences.getInstance());

  bool get onboardingSeen => _prefs.getBool(_onboardingSeen) ?? false;

  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeen, true);

  bool get shareHintShown => _prefs.getBool(_shareHintShown) ?? false;

  Future<void> setShareHintShown() => _prefs.setBool(_shareHintShown, true);

  /// The single most important activation event fires once per install
  /// (spec section 37), so it has to be remembered across launches.
  bool get firstCaptureTracked => _prefs.getBool(_firstCaptureTracked) ?? false;

  Future<void> setFirstCaptureTracked() =>
      _prefs.setBool(_firstCaptureTracked, true);

  /// Whether the system notification prompt has already been triggered.
  ///
  /// iOS shows that prompt once per install and never again, so it must not be
  /// spent on a dialog the user has no reason to accept. Set only after the
  /// person has said yes to our own explanation - "Not now" leaves this false,
  /// because nothing was spent and the question is worth asking again the next
  /// time a reminder is actually wanted.
  bool get notificationsExplained =>
      _prefs.getBool(_notificationsExplained) ?? false;

  Future<void> setNotificationsExplained() =>
      _prefs.setBool(_notificationsExplained, true);

  /// Items this device has already handed to the calendar.
  ///
  /// add_2_calendar can add an event and nothing else: it cannot look, and it
  /// cannot delete. So the app has no way of knowing what is in somebody's
  /// calendar - only what it put there itself. That is enough to stop
  /// offering the same event a second time, which is what made the button
  /// confusing: tapping it again looked like it had done nothing.
  ///
  /// Per device on purpose. A calendar is a thing on a phone, not on an
  /// account.
  Set<String> get itemsInCalendar =>
      (_prefs.getStringList(_inCalendar) ?? const []).toSet();

  bool isInCalendar(String itemId) => itemsInCalendar.contains(itemId);

  Future<void> setInCalendar(String itemId) =>
      _prefs.setStringList(_inCalendar, {...itemsInCalendar, itemId}.toList());

  /// Used to notice that the user has travelled, so reminders anchored to a
  /// local wall-clock time can be recomputed.
  String? get lastTimezone => _prefs.getString(_lastTimezone);

  Future<void> setLastTimezone(String value) =>
      _prefs.setString(_lastTimezone, value);
}

final localPrefsProvider = Provider<LocalPrefs>(
  (ref) => throw StateError('LocalPrefs was not initialised'),
);

/// Watched by the router so finishing onboarding moves the user on
/// immediately, without a manual navigation call.
class OnboardingController extends StateNotifier<bool> {
  OnboardingController(this._prefs) : super(_prefs.onboardingSeen);

  final LocalPrefs _prefs;

  Future<void> complete() async {
    await _prefs.setOnboardingSeen();
    state = true;
  }
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, bool>(
      (ref) => OnboardingController(ref.watch(localPrefsProvider)),
    );
