import 'package:flutter/material.dart';

import '../../../shared/domain/life_entity.dart';
import '../../../shared/domain/life_item_type.dart';

/// A colour per kind of thing.
///
/// This is what stops a list of twenty rows reading as grey noise: a dentist
/// appointment, an electricity bill and a flight are different kinds of
/// worry, and the eye should be able to sort them before the brain reads a
/// word. The hues are deliberately desaturated in light mode and lifted in
/// dark mode so neither theme turns into a fruit salad.
///
/// Colour is never the only signal. Every row still carries an icon and a
/// label, so this works for a colour-blind user and for a screen reader.
class TypeAccent {
  const TypeAccent(this._light, this._dark);

  final Color _light;
  final Color _dark;

  Color of(Brightness brightness) =>
      brightness == Brightness.light ? _light : _dark;

  /// The tinted background behind an icon. Low alpha rather than a second
  /// hardcoded colour, so it stays correct on any surface.
  Color containerOf(Brightness brightness) => of(
    brightness,
  ).withValues(alpha: brightness == Brightness.light ? 0.12 : 0.20);
}

abstract final class TypePalette {
  const TypePalette._();

  static const Map<LifeItemType, TypeAccent> _accents = {
    LifeItemType.appointment: TypeAccent(Color(0xFF0E8A8A), Color(0xFF4FD1C5)),
    LifeItemType.bill: TypeAccent(Color(0xFFB5730A), Color(0xFFF3B564)),
    LifeItemType.subscription: TypeAccent(Color(0xFF7B3FE4), Color(0xFFB794F6)),
    LifeItemType.purchase: TypeAccent(Color(0xFFC2185B), Color(0xFFF48FB1)),
    LifeItemType.returnDeadline: TypeAccent(
      Color(0xFFD1600A),
      Color(0xFFFFB077),
    ),
    LifeItemType.warranty: TypeAccent(Color(0xFF1B8A5A), Color(0xFF5FD3A0)),
    LifeItemType.travel: TypeAccent(Color(0xFF0277BD), Color(0xFF63B3ED)),
    LifeItemType.document: TypeAccent(Color(0xFF5A6472), Color(0xFFA0AEC0)),
    LifeItemType.insurance: TypeAccent(Color(0xFF3D5AFE), Color(0xFF93A5FF)),
    LifeItemType.vehicle: TypeAccent(Color(0xFF37618E), Color(0xFF8AB4F8)),
    LifeItemType.home: TypeAccent(Color(0xFF2E7D32), Color(0xFF81C784)),
    LifeItemType.event: TypeAccent(Color(0xFFA623B8), Color(0xFFE39FF6)),
    LifeItemType.delivery: TypeAccent(Color(0xFF00838F), Color(0xFF4DD0E1)),
    LifeItemType.reservation: TypeAccent(Color(0xFFC1440E), Color(0xFFFF9E80)),
    LifeItemType.education: TypeAccent(Color(0xFF5E35B1), Color(0xFFB39DDB)),
    LifeItemType.task: TypeAccent(Color(0xFF455A64), Color(0xFF90A4AE)),
    LifeItemType.other: TypeAccent(Color(0xFF6A7180), Color(0xFF9AA1AE)),
  };

  /// The same idea for the groups on the Life screen. Home is green, health
  /// is rose, documents are blue: the concepts all colour these cards, and a
  /// grid of nine identical tiles is exactly the grey noise this file exists
  /// to prevent.
  static const Map<EntityType, TypeAccent> _entityAccents = {
    EntityType.home: TypeAccent(Color(0xFF2E7D5B), Color(0xFF79C79B)),
    EntityType.health: TypeAccent(Color(0xFFD6456B), Color(0xFFF7899F)),
    EntityType.document: TypeAccent(Color(0xFF2563C9), Color(0xFF7FA9F5)),
    EntityType.product: TypeAccent(Color(0xFF7B3FE4), Color(0xFFB794F6)),
    EntityType.subscription: TypeAccent(Color(0xFF7B3FE4), Color(0xFFB794F6)),
    EntityType.organization: TypeAccent(Color(0xFF00838F), Color(0xFF4DD0E1)),
    EntityType.person: TypeAccent(Color(0xFFB5730A), Color(0xFFF3B564)),
    EntityType.trip: TypeAccent(Color(0xFF1565C0), Color(0xFF64B5F6)),
    EntityType.vehicle: TypeAccent(Color(0xFF455A64), Color(0xFF90A4AE)),
  };

  static TypeAccent entityAccent(EntityType type) =>
      _entityAccents[type] ?? _accents[LifeItemType.other]!;

  static TypeAccent accent(LifeItemType type) =>
      _accents[type] ?? _accents[LifeItemType.other]!;

  static Color colorOf(LifeItemType type, Brightness brightness) =>
      accent(type).of(brightness);

  static Color containerOf(LifeItemType type, Brightness brightness) =>
      accent(type).containerOf(brightness);
}

extension TypePaletteX on BuildContext {
  Color accentFor(LifeItemType type) =>
      TypePalette.colorOf(type, Theme.of(this).brightness);

  Color accentContainerFor(LifeItemType type) =>
      TypePalette.containerOf(type, Theme.of(this).brightness);

  Color accentForEntity(EntityType type) =>
      TypePalette.entityAccent(type).of(Theme.of(this).brightness);

  Color accentContainerForEntity(EntityType type) =>
      TypePalette.entityAccent(type).containerOf(Theme.of(this).brightness);
}
