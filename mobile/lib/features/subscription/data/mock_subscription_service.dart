import 'dart:async';

import '../domain/subscription_service.dart';

class MockSubscriptionService implements SubscriptionService {
  final StreamController<Entitlement> _controller =
      StreamController<Entitlement>.broadcast();

  Entitlement _entitlement = Entitlement.none;

  @override
  Stream<Entitlement> get changes => _controller.stream;

  @override
  Future<void> configure({required String userId}) async {}

  @override
  Future<List<SubscriptionOffer>> offers() async => const [
    SubscriptionOffer(
      identifier: 'pro_monthly',
      priceString: '7,99 EUR',
      isAnnual: false,
    ),
    SubscriptionOffer(
      identifier: 'pro_annual',
      priceString: '59,99 EUR',
      isAnnual: true,
      savingsPercent: 37,
    ),
  ];

  @override
  Future<Entitlement> entitlement() async => _entitlement;

  @override
  Future<Entitlement> purchase(SubscriptionOffer offer) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _entitlement = Entitlement(
      isPro: true,
      expiresAt: DateTime.now().add(
        offer.isAnnual ? const Duration(days: 365) : const Duration(days: 30),
      ),
      willRenew: true,
    );
    _controller.add(_entitlement);
    return _entitlement;
  }

  @override
  Future<Entitlement> restore() async => _entitlement;
}
