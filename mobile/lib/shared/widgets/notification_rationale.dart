import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/logging/app_logger.dart';
import '../../features/settings/application/preferences_controller.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/prefs/local_prefs.dart';

/// Says why notifications are needed, in our own words, before the operating
/// system asks in its own.
///
/// iOS shows the system prompt once per install. Triggering it from inside the
/// scheduler, with nothing on screen explaining it, spent that single chance on
/// a question with no context - and a refusal there is permanent, so every
/// reminder the user accepts afterwards is stored and never delivered. The
/// specification asked for the reason to be on screen (section 50); the code
/// said so in a comment and did not do it.
///
/// Called at the two moments the user has just chosen to be reminded of
/// something, which is the only point where the answer is obvious.
Future<void> explainNotificationsIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  final LocalPrefs prefs;
  try {
    prefs = ref.read(localPrefsProvider);
  } on StateError {
    // No prefs in this build; nothing to remember, so nothing to ask.
    return;
  }

  if (prefs.notificationsExplained) return;
  // Reminders are switched off for this account: the system prompt would be
  // asking permission for something the app is not going to do.
  if (!ref.read(preferencesProvider).notificationsEnabled) return;

  final l10n = context.l10n;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.reminderPermissionTitle),
      content: Text(l10n.reminderPermissionMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.actionNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.actionContinue),
        ),
      ],
    ),
  );

  if (proceed != true) return;

  try {
    await ref.read(notificationServiceProvider).requestPermission();
    // Recorded after the prompt has actually been triggered, so a build with
    // no notification service does not burn the explanation for nothing.
    await prefs.setNotificationsExplained();
  } on StateError {
    // No notification service in this build.
  } catch (error, stack) {
    AppLogger.error('Could not ask for notification permission', error, stack);
  }
}
