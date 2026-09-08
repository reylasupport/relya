import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/design/tokens/type_palette.dart';
import '../../../shared/domain/life_item_type.dart';
import '../../../shared/widgets/category_label.dart';
import '../application/preferences_controller.dart';

/// Per-category control, not one master switch.
///
/// A single toggle forces the user to choose between useful reminders and
/// noise; letting them mute delivery updates while keeping payment deadlines
/// is what keeps notifications trusted (spec section 22).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            value: prefs.notificationsEnabled,
            onChanged: controller.setNotificationsEnabled,
            title: Text(l10n.settingsNotificationsEnabled),
          ),
          ListTile(
            enabled: prefs.notificationsEnabled,
            title: Text(l10n.settingsQuietHours),
            subtitle: Text(
              prefs.quietHoursStart == null
                  ? l10n.actionNotNow
                  : '${prefs.quietHoursStart!.format(context)} - '
                        '${prefs.quietHoursEnd?.format(context) ?? ''}',
            ),
            onTap: prefs.notificationsEnabled
                ? () => _pickQuietHours(context, ref)
                : null,
          ),
          const Divider(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageInset,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              l10n.settingsMutedCategories.toUpperCase(),
              style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
            ),
          ),
          for (final type in LifeItemType.values)
            SwitchListTile.adaptive(
              value: !prefs.isMuted(type.wire),
              onChanged: prefs.notificationsEnabled
                  ? (_) => controller.toggleCategory(type.wire)
                  : null,
              secondary: Icon(
                type.icon,
                size: 20,
                color: context.accentFor(type),
              ),
              title: Text(categoryLabel(context, type)),
            ),
        ],
      ),
    );
  }

  Future<void> _pickQuietHours(BuildContext context, WidgetRef ref) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
      helpText: context.l10n.settingsQuietHours,
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: context.l10n.settingsQuietHours,
    );
    if (end == null) return;
    await ref.read(preferencesProvider.notifier).setQuietHours(start, end);
  }
}
