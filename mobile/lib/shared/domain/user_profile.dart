/// Which plan the user is on. Sourced from RevenueCat entitlements, never
/// asserted by the client on its own.
enum PlanTier {
  free('free'),
  pro('pro'),
  family('family');

  const PlanTier(this.wire);

  final String wire;

  static PlanTier fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => PlanTier.free);

  bool get isPaid => this != PlanTier.free;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.plan,
    this.displayName,
    this.email,
    this.locale,
    this.timezone,
    this.capturesThisPeriod = 0,
    this.captureQuota,
    this.periodResetsAt,
    this.onboardedAt,
    this.inboxToken,
  });

  final String id;
  final String? displayName;
  final String? email;

  /// BCP-47 tag chosen by the user, or the device default on first run.
  final String? locale;

  /// IANA zone. Refreshed whenever the device reports a different one, so
  /// reminders keep firing at the right local moment.
  final String? timezone;

  final PlanTier plan;

  /// Free-plan usage, for the soft quota in spec section 35.
  final int capturesThisPeriod;
  final int? captureQuota;
  final DateTime? periodResetsAt;

  final DateTime? onboardedAt;

  /// The unguessable part of this account's forwarding address. Null on a
  /// backend where the email inbox migration has not been applied.
  final String? inboxToken;

  /// The address to forward to, or null when the feature is not configured.
  String? inboxAddress(String domain) {
    final token = inboxToken;
    if (token == null || token.isEmpty || domain.isEmpty) return null;
    return 'u-$token@$domain';
  }

  /// First name only, for the greeting. Falls back to nothing rather than to
  /// something impersonal.
  String? get firstName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  int? get capturesRemaining {
    final quota = captureQuota;
    if (quota == null) return null;
    final left = quota - capturesThisPeriod;
    return left < 0 ? 0 : left;
  }

  bool get hasCapturesLeft => plan.isPaid || (capturesRemaining ?? 1) > 0;

  UserProfile copyWith({
    String? displayName,
    String? locale,
    String? timezone,
    PlanTier? plan,
    int? capturesThisPeriod,
    DateTime? onboardedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      plan: plan ?? this.plan,
      capturesThisPeriod: capturesThisPeriod ?? this.capturesThisPeriod,
      captureQuota: captureQuota,
      periodResetsAt: periodResetsAt,
      onboardedAt: onboardedAt ?? this.onboardedAt,
      inboxToken: inboxToken,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    email: json['email'] as String?,
    locale: json['locale'] as String?,
    timezone: json['timezone'] as String?,
    plan: PlanTier.fromWire(json['plan'] as String?),
    capturesThisPeriod: json['captures_this_period'] as int? ?? 0,
    captureQuota: json['capture_quota'] as int?,
    periodResetsAt: json['period_resets_at'] == null
        ? null
        : DateTime.parse(json['period_resets_at'] as String).toUtc(),
    onboardedAt: json['onboarded_at'] == null
        ? null
        : DateTime.parse(json['onboarded_at'] as String).toUtc(),
    inboxToken: json['inbox_token'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'locale': locale,
    'timezone': timezone,
  };
}
