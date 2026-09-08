import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/app_pill.dart';
import '../../../core/design/tokens/app_radii.dart';
import '../../../core/design/tokens/app_semantic_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../application/subscription_providers.dart';
import '../domain/subscription_service.dart';

/// Shown only after the user has felt the product work at least once
/// (spec section 35). Never on first launch.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offers = ref.watch(offersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            child: Text(l10n.paywallRestore),
          ),
        ],
      ),
      body: offers.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        error: (error, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) => _content(list),
      ),
    );
  }

  Widget _content(List<SubscriptionOffer> offers) {
    final l10n = context.l10n;
    final annual = offers.where((o) => o.isAnnual).firstOrNull;
    final selected =
        _selected ?? annual?.identifier ?? offers.firstOrNull?.identifier;

    final features = [
      l10n.paywallFeatureUnlimited,
      l10n.paywallFeatureAssistant,
      l10n.paywallFeatureDocuments,
      l10n.paywallFeatureReminders,
      l10n.paywallFeatureSearch,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageInset,
            ),
            children: [
              Text(l10n.paywallTitle, style: context.text.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.paywallSubtitle,
                style: context.text.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: context.semantic.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(feature, style: context.text.bodyLarge),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              for (final offer in offers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OfferTile(
                    offer: offer,
                    selected: offer.identifier == selected,
                    onTap: () => setState(() => _selected = offer.identifier),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.pageInset),
          child: FilledButton(
            onPressed: _busy || selected == null
                ? null
                : () => _purchase(
                    offers.firstWhere((o) => o.identifier == selected),
                  ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.paywallSubscribe),
          ),
        ),
      ],
    );
  }

  Future<void> _purchase(SubscriptionOffer offer) async {
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    try {
      final entitlement = await ref
          .read(subscriptionServiceProvider)
          .purchase(offer);
      if (entitlement.isPro && mounted) router.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final entitlement = await ref.read(subscriptionServiceProvider).restore();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            entitlement.isPro ? l10n.actionDone : l10n.errorGeneric,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadii.cardRadius,
          color: selected
              ? colors.primary.withValues(alpha: 0.06)
              : colors.surfaceContainer,
          border: Border.all(
            color: selected ? colors.primary : context.semantic.subtleBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.isAnnual ? l10n.paywallAnnual : l10n.paywallMonthly,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    offer.isAnnual
                        ? l10n.paywallPerYear(offer.priceString)
                        : l10n.paywallPerMonth(offer.priceString),
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            ),
            if (offer.isAnnual)
              AppPill(
                label: l10n.paywallBestValue,
                foreground: context.semantic.success,
                background: context.semantic.successContainer,
              ),
          ],
        ),
      ),
    );
  }
}
