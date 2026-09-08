import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/branding/brand.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/domain/user_preferences.dart';
import '../application/preferences_controller.dart';
import 'export_action.dart';

/// Privacy is a feature here, not a legal page. Everything on this screen is
/// something the user can actually change (spec section 30).
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacy)),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            value: prefs.retention == RetentionPolicy.keepOriginal,
            onChanged: (value) => controller.setRetention(
              value
                  ? RetentionPolicy.keepOriginal
                  : RetentionPolicy.extractedOnly,
            ),
            title: Text(l10n.settingsKeepOriginals),
            subtitle: Text(l10n.settingsKeepOriginalsHint),
          ),
          SwitchListTile.adaptive(
            value: prefs.biometricLock,
            onChanged: controller.setBiometricLock,
            title: Text(l10n.settingsBiometricLock),
          ),
          SwitchListTile.adaptive(
            value: prefs.analyticsOptIn,
            onChanged: controller.setAnalyticsOptIn,
            title: Text(l10n.settingsAnalytics),
          ),
          const Divider(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: Text(l10n.settingsExportData),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(l10n.authPrivacy),
            onTap: () => launchUrl(Uri.parse(Brand.privacyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: Text(l10n.authTerms),
            onTap: () => launchUrl(Uri.parse(Brand.termsUrl)),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) =>
      exportUserData(context, ref);
}
