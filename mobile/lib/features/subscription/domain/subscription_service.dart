/// A purchasable plan, as returned by the store through RevenueCat.
class SubscriptionOffer {
  const SubscriptionOffer({
    required this.identifier,
    required this.priceString,
    required this.isAnnual,
    this.savingsPercent,
  });

  final String identifier;

  /// Already localised and currency-correct by the store. Never format prices
  /// ourselves: the store knows the user region and tax rules, we do not.
  final String priceString;

  final bool isAnnual;
  final int? savingsPercent;
}

class Entitlement {
  const Entitlement({required this.isPro, this.expiresAt, this.willRenew});

  final bool isPro;
  final DateTime? expiresAt;
  final bool? willRenew;

  static const Entitlement none = Entitlement(isPro: false);
}

/// Wraps RevenueCat. The app never talks to StoreKit or Play Billing directly,
/// and never implements its own payment flow for digital goods, which both
/// stores forbid (spec section 36).
abstract interface class SubscriptionService {
  Future<void> configure({required String userId});

  Future<List<SubscriptionOffer>> offers();

  Future<Entitlement> entitlement();

  Future<Entitlement> purchase(SubscriptionOffer offer);

  Future<Entitlement> restore();

  Stream<Entitlement> get changes;
}
