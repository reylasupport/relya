import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../data/mock_subscription_service.dart';
import '../data/revenuecat_subscription_service.dart';
import '../domain/subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  if (AppEnv.useMockData) return MockSubscriptionService();
  return RevenueCatSubscriptionService();
});

final offersProvider = FutureProvider.autoDispose<List<SubscriptionOffer>>(
  (ref) => ref.watch(subscriptionServiceProvider).offers(),
);

/// The single source of truth for whether paid features are unlocked.
final entitlementProvider = StreamProvider<Entitlement>((ref) async* {
  final service = ref.watch(subscriptionServiceProvider);
  yield await service.entitlement();
  yield* service.changes;
});

final isProProvider = Provider<bool>(
  (ref) => ref.watch(entitlementProvider).valueOrNull?.isPro ?? false,
);
