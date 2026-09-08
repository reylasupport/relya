import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/brand.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/data/providers.dart';

/// The address this account can forward email to.
///
/// Most of what this app is for arrives in an inbox. This is the version of
/// that which needs no OAuth, no scanning and nothing to revoke: one address,
/// one message at a time, pushed by the person who owns both.
class EmailInboxScreen extends ConsumerWidget {
  const EmailInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final address = profile?.inboxAddress(Brand.emailInboxDomain);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEmailInbox)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageInset),
        children: [
          Text(l10n.emailInboxIntro, style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          if (address == null)
            AppCard(
              child: Text(
                l10n.emailInboxUnavailable,
                style: context.text.bodyMedium,
              ),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    address,
                    style: context.text.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final copied = l10n.emailInboxCopied;
                      await Clipboard.setData(ClipboardData(text: address));
                      messenger.showSnackBar(SnackBar(content: Text(copied)));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l10n.emailInboxCopy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Point(
              icon: Icons.person_outline_rounded,
              // Naming the address is the point: an account created with Apple
              // sign-in has a private relay address here, and forwarding from
              // the everyday one would be silently dropped.
              text: l10n.emailInboxOnlyYou(profile?.email ?? '-'),
            ),
            _Point(
              icon: Icons.visibility_off_outlined,
              text: l10n.emailInboxNoScanning,
            ),
            _Point(
              icon: Icons.fact_check_outlined,
              text: l10n.emailInboxStillConfirm,
            ),
          ],
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}
