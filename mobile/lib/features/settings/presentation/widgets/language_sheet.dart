import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/supported_locales.dart';
import '../../application/preferences_controller.dart';

/// Interface language. Independent of the language of the documents the user
/// sends in, which is detected per capture (spec section 46).
class LanguageSheet extends ConsumerWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(preferencesProvider).localeTag;
    final controller = ref.read(preferencesProvider.notifier);

    return SafeArea(
      child: RadioGroup<String?>(
        groupValue: selected,
        onChanged: (value) {
          controller.setLocale(value);
          Navigator.of(context).pop();
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            RadioListTile<String?>(
              value: null,
              title: Text(context.l10n.settingsLanguageSystem),
            ),
            for (final locale in SupportedLocales.all)
              RadioListTile<String?>(
                value: locale.tag,
                title: Text(locale.nativeName),
              ),
          ],
        ),
      ),
    );
  }
}
