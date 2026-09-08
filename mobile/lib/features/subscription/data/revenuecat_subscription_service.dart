import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/errors/app_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart' hide LogLevel;
import '../domain/subscription_service.dart';

/// RevenueCat implementation.
///
/// Entitlement is always read from RevenueCat, never asserted locally: the
/// client saying "this user is Pro" is a claim, the store receipt is a fact.
class RevenueCatSubscriptionService implements SubscriptionService {
  static const String _proEntitlement = 'pro';

  final StreamController<Entitlement> _controller =
      StreamController<Entitlement>.broadcast();

  @override
  Stream<Entitlement> get changes => _controller.stream;

  @override
  Future<void> configure({required String userId}) async {
    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? AppEnv.revenueCatIosKey
        : AppEnv.revenueCatAndroidKey;
    if (apiKey.isEmpty) {
      AppLogger.warn('RevenueCat is not configured for this build');
      return;
    }
    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = userId,
    );
    Purchases.addCustomerInfoUpdateListener(
      (info) => _controller.add(_map(info)),
    );
  }

  Entitlement _map(CustomerInfo info) {
    final entitlement = info.entitlements.all[_proEntitlement];
    if (entitlement == null || !entitlement.isActive) return Entitlement.none;
    return Entitlement(
      isPro: true,
      expiresAt: entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!),
      willRenew: entitlement.willRenew,
    );
  }

  @override
  Future<List<SubscriptionOffer>> offers() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return const [];

    return current.availablePackages.map((package) {
      final isAnnual = package.packageType == PackageType.annual;
      return SubscriptionOffer(
        identifier: package.identifier,
        priceString: package.storeProduct.priceString,
        isAnnual: isAnnual,
        savingsPercent: isAnnual ? 37 : null,
      );
    }).toList();
  }

  @override
  Future<Entitlement> entitlement() async =>
      _map(await Purchases.getCustomerInfo());

  @override
  Future<Entitlement> purchase(SubscriptionOffer offer) async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages
          .where((p) => p.identifier == offer.identifier)
          .firstOrNull;
      if (package == null) {
        throw const UnexpectedFailure('That plan is no longer available');
      }
      final info = await Purchases.purchasePackage(package);
      return _map(info);
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return entitlement();
      }
      throw UnexpectedFailure('Purchase failed', cause: error);
    }
  }

  @override
  Future<Entitlement> restore() async =>
      _map(await Purchases.restorePurchases());
}
