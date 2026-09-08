import 'package:flutter/material.dart';

import '../../core/design/tokens/app_skin.dart';

/// What happens to the original file once we have understood it (spec 31).
enum RetentionPolicy {
  /// Keep the screenshot or PDF in encrypted storage.
  keepOriginal('keep_original'),

  /// Keep only the extracted fields. The most private option, and the default
  /// we intend to move to once users trust the extraction.
  extractedOnly('extracted_only');

  const RetentionPolicy(this.wire);

  final String wire;

  static RetentionPolicy fromWire(String? value) => values.firstWhere(
    (p) => p.wire == value,
    orElse: () => RetentionPolicy.keepOriginal,
  );
}

/// User-controlled behaviour. Notifications are opt-out per category, never a
/// single all-or-nothing switch, because a useless notification costs more
/// trust than a missing one (spec section 22).
class UserPreferences {
  const UserPreferences({
    this.themeMode = ThemeMode.system,
    this.themeSkin,
    this.localeTag,
    this.notificationsEnabled = true,
    this.mutedCategories = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.defaultLeadTimes = const [Duration(days: 1), Duration(hours: 2)],
    this.retention = RetentionPolicy.keepOriginal,
    this.biometricLock = false,
    this.analyticsOptIn = true,
  });

  final ThemeMode themeMode;

  /// Null follows the default skin, so a change of default moves every user
  /// who never picked one of their own.
  final AppSkin? themeSkin;

  AppSkin get resolvedSkin => themeSkin ?? AppSkin.fallback;

  /// Null means follow the device language.
  final String? localeTag;

  final bool notificationsEnabled;

  /// Wire values of LifeItemType the user does not want to hear about.
  final Set<String> mutedCategories;

  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;

  /// Applied when the user accepts a suggestion without editing it.
  final List<Duration> defaultLeadTimes;

  final RetentionPolicy retention;

  /// Documents area behind Face ID / fingerprint.
  final bool biometricLock;

  /// Product analytics. Off means no events leave the device at all.
  final bool analyticsOptIn;

  bool isMuted(String categoryWire) => mutedCategories.contains(categoryWire);

  UserPreferences copyWith({
    ThemeMode? themeMode,
    AppSkin? themeSkin,
    Object? localeTag = _unset,
    bool? notificationsEnabled,
    Set<String>? mutedCategories,
    Object? quietHoursStart = _unset,
    Object? quietHoursEnd = _unset,
    List<Duration>? defaultLeadTimes,
    RetentionPolicy? retention,
    bool? biometricLock,
    bool? analyticsOptIn,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      themeSkin: themeSkin ?? this.themeSkin,
      localeTag: localeTag == _unset ? this.localeTag : localeTag as String?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      mutedCategories: mutedCategories ?? this.mutedCategories,
      quietHoursStart: quietHoursStart == _unset
          ? this.quietHoursStart
          : quietHoursStart as TimeOfDay?,
      quietHoursEnd: quietHoursEnd == _unset
          ? this.quietHoursEnd
          : quietHoursEnd as TimeOfDay?,
      defaultLeadTimes: defaultLeadTimes ?? this.defaultLeadTimes,
      retention: retention ?? this.retention,
      biometricLock: biometricLock ?? this.biometricLock,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time(String key) {
      final raw = json[key] as String?;
      if (raw == null) return null;
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    return UserPreferences(
      themeMode: switch (json['theme_mode'] as String?) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      themeSkin: json['theme_skin'] == null
          ? null
          : AppSkin.fromWire(json['theme_skin'] as String?),
      localeTag: json['locale'] as String?,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      mutedCategories: ((json['muted_categories'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      quietHoursStart: time('quiet_hours_start'),
      quietHoursEnd: time('quiet_hours_end'),
      defaultLeadTimes: ((json['default_lead_seconds'] as List?) ?? const [])
          .cast<int>()
          .map((s) => Duration(seconds: s))
          .toList(),
      retention: RetentionPolicy.fromWire(json['retention'] as String?),
      biometricLock: json['biometric_lock'] as bool? ?? false,
      analyticsOptIn: json['analytics_opt_in'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme_mode': themeMode.name,
    'theme_skin': themeSkin?.wire,
    'locale': localeTag,
    'notifications_enabled': notificationsEnabled,
    'muted_categories': mutedCategories.toList(),
    'quiet_hours_start': quietHoursStart == null
        ? null
        : '${quietHoursStart!.hour}:${quietHoursStart!.minute}',
    'quiet_hours_end': quietHoursEnd == null
        ? null
        : '${quietHoursEnd!.hour}:${quietHoursEnd!.minute}',
    'default_lead_seconds': defaultLeadTimes.map((d) => d.inSeconds).toList(),
    'retention': retention.wire,
    'biometric_lock': biometricLock,
    'analytics_opt_in': analyticsOptIn,
  };
}

const Object _unset = Object();
