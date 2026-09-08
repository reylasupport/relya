import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_skin.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/user_preferences.dart';

/// Holds preferences in memory and writes through on every change, so a
/// toggle never appears to work and then silently revert.
class PreferencesController extends StateNotifier<UserPreferences> {
  PreferencesController(this._ref) : super(const UserPreferences()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final loaded = await _ref.read(profileRepositoryProvider).preferences();
    if (mounted) state = loaded;
  }

  Future<void> _save(UserPreferences next) async {
    state = next;
    await _ref.read(profileRepositoryProvider).savePreferences(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save(state.copyWith(themeMode: mode));

  Future<void> setThemeSkin(AppSkin skin) =>
      _save(state.copyWith(themeSkin: skin));

  /// Null follows the device language.
  Future<void> setLocale(String? tag) => _save(state.copyWith(localeTag: tag));

  Future<void> setNotificationsEnabled(bool enabled) =>
      _save(state.copyWith(notificationsEnabled: enabled));

  Future<void> toggleCategory(String wire) {
    final muted = {...state.mutedCategories};
    muted.contains(wire) ? muted.remove(wire) : muted.add(wire);
    return _save(state.copyWith(mutedCategories: muted));
  }

  Future<void> setQuietHours(TimeOfDay? start, TimeOfDay? end) =>
      _save(state.copyWith(quietHoursStart: start, quietHoursEnd: end));

  Future<void> setRetention(RetentionPolicy policy) =>
      _save(state.copyWith(retention: policy));

  Future<void> setBiometricLock(bool enabled) =>
      _save(state.copyWith(biometricLock: enabled));

  Future<void> setAnalyticsOptIn(bool enabled) =>
      _save(state.copyWith(analyticsOptIn: enabled));
}

final preferencesProvider =
    StateNotifierProvider<PreferencesController, UserPreferences>(
      PreferencesController.new,
    );
