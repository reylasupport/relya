import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/known_service.dart';

/// The name of a service that has no brand behind it.
///
/// Kept apart from the catalogue because a const list cannot hold a string
/// that depends on the interface language.
String genericLabel(BuildContext context, GenericService service) {
  final l10n = context.l10n;
  return switch (service) {
    GenericService.rent => l10n.quickAddRent,
    GenericService.condominium => l10n.quickAddCondominium,
    GenericService.councilTax => l10n.quickAddCouncilTax,
    GenericService.electricity => l10n.quickAddElectricity,
    GenericService.water => l10n.quickAddWater,
    GenericService.gas => l10n.quickAddGas,
    GenericService.internet => l10n.quickAddInternet,
    GenericService.mobile => l10n.quickAddMobile,
    GenericService.gym => l10n.quickAddGym,
    GenericService.carInsurance => l10n.quickAddCarInsurance,
    GenericService.homeInsurance => l10n.quickAddHomeInsurance,
    GenericService.healthInsurance => l10n.quickAddHealthInsurance,
    GenericService.lifeInsurance => l10n.quickAddLifeInsurance,
    GenericService.carInspection => l10n.quickAddCarInspection,
    GenericService.roadTax => l10n.quickAddRoadTax,
    GenericService.passport => l10n.quickAddPassport,
    GenericService.idCard => l10n.quickAddIdCard,
    GenericService.driversLicence => l10n.quickAddDriversLicence,
    GenericService.dentist => l10n.quickAddDentist,
    GenericService.medicalCheckup => l10n.quickAddMedicalCheckup,
  };
}
