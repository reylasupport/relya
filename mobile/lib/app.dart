import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/branding/brand.dart';
import 'core/design/theme/app_theme.dart';
import 'core/design/tokens/app_typography.dart';
import 'features/settings/application/preferences_controller.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/supported_locales.dart';
import 'navigation/router.dart';
import 'navigation/share_intake_gate.dart';
import 'services/outbox/outbox_providers.dart';

class RelyaApp extends ConsumerStatefulWidget {
  const RelyaApp({super.key});

  @override
  ConsumerState<RelyaApp> createState() => _RelyaAppState();
}

class _RelyaAppState extends ConsumerState<RelyaApp> {
  @override
  void initState() {
    super.initState();
    // Empties the capture outbox now and on every reconnect. Started here
    // rather than from a screen because a capture parked yesterday has to go
    // out whether or not anybody opens the Inbox.
    ref.read(outboxDrainerProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(preferences.resolvedSkin),
      darkTheme: AppTheme.dark(preferences.resolvedSkin),
      themeMode: preferences.themeMode,
      locale: SupportedLocales.fromTag(preferences.localeTag),
      supportedLocales: SupportedLocales.locales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Dynamic Type is respected, but clamped: past this point the dense
        // screens stop fitting even with wrapping, and a broken layout helps
        // nobody who needs large text.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: AppTypography.maxTextScale,
            ),
          ),
          child: ShareIntakeGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
