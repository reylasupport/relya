import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/branding/brand.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../../../services/cache/item_cache.dart';
import '../../../shared/data/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../subscription/application/subscription_providers.dart';
import '../application/preferences_controller.dart';
import 'appearance_screen.dart';
import 'export_action.dart';
import 'widgets/account_header.dart';
import 'widgets/danger_zone.dart';
import 'widgets/language_sheet.dart';
import 'widgets/settings_group.dart';

/// Everything about the account, in one place, one tap from Home.
///
/// Settings screens usually become a dumping ground. This one is ordered by
/// how often a person actually needs it: who am I and what am I paying,
/// then how the app behaves, then the data, then the things you do once.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final profile = ref.watch(currentProfileProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AccountHeader(
            profile: profile.valueOrNull,
            onUpgrade: () => context.push(Routes.paywall),
          ),
          SettingsGroup(
            title: l10n.accountSectionPreferences,
            tiles: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: l10n.settingsAppearance,
                value: skinTitle(context, prefs.resolvedSkin),
                trailingDot: prefs.resolvedSkin
                    .palette(Theme.of(context).brightness)
                    .accent,
                onTap: () => context.push(Routes.settingsAppearance),
              ),
              SettingsTile(
                icon: Icons.translate_rounded,
                title: l10n.settingsLanguage,
                value: prefs.localeTag ?? l10n.settingsLanguageSystem,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const LanguageSheet(),
                ),
              ),
              SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: l10n.settingsNotifications,
                value: prefs.notificationsEnabled
                    ? l10n.settingsOn
                    : l10n.settingsOff,
                onTap: () => context.push(Routes.settingsNotifications),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.accountSectionData,
            tiles: [
              // A subscriber needs a way out that does not involve hunting
              // through system settings; both stores expect the app to link
              // here, and it only exists for someone who actually subscribed.
              if (isPro)
                SettingsTile(
                  icon: Icons.receipt_long_rounded,
                  title: l10n.accountManageSubscription,
                  onTap: _openStoreSubscriptions,
                ),
              // Hidden until the MX records exist: an address nobody can send
              // to is worse than no setting at all.
              if (Brand.hasEmailInbox)
                SettingsTile(
                  icon: Icons.alternate_email_rounded,
                  title: l10n.settingsEmailInbox,
                  onTap: () => context.push(Routes.settingsEmailInbox),
                ),
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: l10n.settingsPrivacy,
                onTap: () => context.push(Routes.settingsPrivacy),
              ),
              SettingsTile(
                icon: Icons.download_rounded,
                title: l10n.settingsExportData,
                onTap: () => _export(context, ref),
              ),
            ],
          ),
          SettingsGroup(
            title: l10n.accountSectionAbout,
            tiles: [
              SettingsTile(
                icon: Icons.public_rounded,
                title: Brand.appName,
                value: Brand.website.replaceFirst('https://', ''),
                onTap: () => launchUrl(Uri.parse(Brand.website)),
              ),
              SettingsTile(
                icon: Icons.policy_outlined,
                title: l10n.authPrivacy,
                onTap: () => launchUrl(Uri.parse(Brand.privacyUrl)),
              ),
              SettingsTile(
                icon: Icons.gavel_rounded,
                title: l10n.authTerms,
                onTap: () => launchUrl(Uri.parse(Brand.termsUrl)),
              ),
              SettingsTile(
                icon: Icons.mail_outline_rounded,
                title: l10n.accountContactSupport,
                value: Brand.supportEmail,
                onTap: () =>
                    launchUrl(Uri.parse('mailto:${Brand.supportEmail}')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DangerZone(
            // The offline copy goes with the session. A shared phone must not
            // show the previous account's appointments.
            onSignOut: () async {
              await ref.read(itemCacheProvider).clear();
              await ref.read(authServiceProvider).signOut();
            },
            onDelete: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  /// The store's own subscription page. There is no in-app equivalent: a
  /// cancellation has to happen where the payment lives.
  Future<void> _openStoreSubscriptions() async {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) =>
      exportUserData(context, ref);

  /// Deleting takes the items, the files and the account with it, so the
  /// dialog says exactly that and the destructive choice is never the default
  /// (spec section 72).
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccount),
        content: Text(l10n.settingsDeleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.settingsDeleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(itemCacheProvider).clear();
    await ref.read(profileRepositoryProvider).deleteAccount();
  }
}
