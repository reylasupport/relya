import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../domain/life_item_type.dart';

/// The user-facing name of a category.
///
/// The enum's wire value is an English identifier meant for the database and
/// the model. Showing "appointment" to a Portuguese user is the kind of leak
/// that makes an app feel unfinished, so nothing renders `type.wire` directly.
String categoryLabel(BuildContext context, LifeItemType type) {
  final l10n = context.l10n;
  return switch (type) {
    LifeItemType.appointment => l10n.categoryAppointment,
    LifeItemType.bill => l10n.categoryBill,
    LifeItemType.subscription => l10n.categorySubscription,
    LifeItemType.purchase => l10n.categoryPurchase,
    LifeItemType.returnDeadline => l10n.categoryReturn,
    LifeItemType.warranty => l10n.categoryWarranty,
    LifeItemType.travel => l10n.categoryTravel,
    LifeItemType.document => l10n.categoryDocument,
    LifeItemType.insurance => l10n.categoryInsurance,
    LifeItemType.vehicle => l10n.categoryVehicle,
    LifeItemType.home => l10n.categoryHome,
    LifeItemType.event => l10n.categoryEvent,
    LifeItemType.delivery => l10n.categoryDelivery,
    LifeItemType.reservation => l10n.categoryReservation,
    LifeItemType.education => l10n.categoryEducation,
    LifeItemType.task => l10n.categoryTask,
    LifeItemType.other => l10n.categoryOther,
  };
}
