import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_skin.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../application/preferences_controller.dart';
import 'widgets/skin_card.dart';

/// Choosing how the app looks.
///
/// Themes are picked from thumbnails of themselves rather than from a list of
/// names, because nobody can tell what "Cosy" means until they see it. Mode
/// sits above them and applies to whichever one is chosen: every skin is
/// drawn in both light and dark.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearance)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageInset,
          AppSpacing.sm,
          AppSpacing.pageInset,
          AppSpacing.xxl,
        ),
        children: [
          _Label(l10n.appearanceMode),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_rounded, size: 18),
              ),
            ],
            selected: {prefs.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                controller.setThemeMode(selection.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Label(l10n.appearanceSkin),
          const SizedBox(height: AppSpacing.md),
          for (final skin in AppSkin.values) ...[
            SkinCard(
              skin: skin,
              title: skinTitle(context, skin),
              body: skinBody(context, skin),
              selected: skin == prefs.resolvedSkin,
              previewBrightness: brightness,
              onTap: () => controller.setThemeSkin(skin),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
  );
}

/// Theme names are translated: a Portuguese speaker looks for "Aconchego",
/// not for "Cosy".
String skinTitle(BuildContext context, AppSkin skin) {
  final l10n = context.l10n;
  return switch (skin) {
    AppSkin.soft => l10n.skinSoft,
    AppSkin.pastel => l10n.skinPastel,
    AppSkin.cosy => l10n.skinCosy,
    AppSkin.midnight => l10n.skinMidnight,
  };
}

String skinBody(BuildContext context, AppSkin skin) {
  final l10n = context.l10n;
  return switch (skin) {
    AppSkin.soft => l10n.skinSoftBody,
    AppSkin.pastel => l10n.skinPastelBody,
    AppSkin.cosy => l10n.skinCosyBody,
    AppSkin.midnight => l10n.skinMidnightBody,
  };
}
