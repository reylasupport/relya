import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/accent_choice.dart';
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
          if (prefs.resolvedSkin.accentIsChosen) ...[
            const SizedBox(height: AppSpacing.xl),
            _Label(l10n.appearanceAccent),
            const SizedBox(height: AppSpacing.sm),
            _AccentRow(
              selected: prefs.themeAccent,
              brightness: brightness,
              onPick: controller.setThemeAccent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.appearanceAccentHint,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
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
    AppSkin.suave => l10n.skinSuave,
  };
}

String skinBody(BuildContext context, AppSkin skin) {
  final l10n = context.l10n;
  return switch (skin) {
    AppSkin.soft => l10n.skinSoftBody,
    AppSkin.pastel => l10n.skinPastelBody,
    AppSkin.cosy => l10n.skinCosyBody,
    AppSkin.midnight => l10n.skinMidnightBody,
    AppSkin.suave => l10n.skinSuaveBody,
  };
}

/// The six accents, as swatches.
///
/// The swatches carry radio semantics rather than being six bare circles: this
/// is one choice out of a fixed set, so a screen reader should announce the
/// colour's name and whether it is the selected one, instead of reading six
/// unlabelled shapes.
class _AccentRow extends StatelessWidget {
  const _AccentRow({
    required this.selected,
    required this.brightness,
    required this.onPick,
  });

  final AccentChoice selected;
  final Brightness brightness;
  final ValueChanged<AccentChoice> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final accent in AccentChoice.values)
          Expanded(
            child: Semantics(
              label: accentName(context, accent),
              inMutuallyExclusiveGroup: true,
              selected: accent == selected,
              child: InkWell(
                onTap: () => onPick(accent),
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.fill(brightness),
                        shape: BoxShape.circle,
                        border: accent == selected
                            ? Border.all(
                                color: context.colors.onSurface,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: accent == selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 19,
                              color: accent.onFill,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Accent names are translated for the same reason theme names are.
String accentName(BuildContext context, AccentChoice accent) {
  final l10n = context.l10n;
  return switch (accent) {
    AccentChoice.azul => l10n.accentAzul,
    AccentChoice.verde => l10n.accentVerde,
    AccentChoice.terracota => l10n.accentTerracota,
    AccentChoice.ameixa => l10n.accentAmeixa,
    AccentChoice.ardosia => l10n.accentArdosia,
    AccentChoice.carmim => l10n.accentCarmim,
  };
}
