import 'package:flutter/material.dart';

/// Nodes of the Life Graph (spec section 8). The schema and the Life tab exist
/// in V1; automatic inference of these from captures is V2 work, gated behind
/// FeatureFlags.lifeGraphAutoLinking.
enum EntityType {
  person('person', Icons.person_rounded),
  vehicle('vehicle', Icons.directions_car_rounded),
  home('home', Icons.home_rounded),
  product('product', Icons.inventory_2_rounded),
  organization('organization', Icons.business_rounded),
  subscription('subscription', Icons.autorenew_rounded),
  document('document', Icons.badge_rounded),
  trip('trip', Icons.luggage_rounded),
  health('health', Icons.favorite_rounded);

  const EntityType(this.wire, this.icon);

  final String wire;
  final IconData icon;

  static EntityType fromWire(String? value) => values.firstWhere(
    (e) => e.wire == value,
    orElse: () => EntityType.product,
  );
}

class LifeEntity {
  const LifeEntity({
    required this.id,
    required this.type,
    required this.name,
    this.subtitle,
    this.identifiers = const {},
    this.metadata = const {},
    this.itemCount = 0,
  });

  final String id;
  final EntityType type;
  final String name;
  final String? subtitle;

  /// Stable keys that let two captures be recognised as the same thing later:
  /// a licence plate, an IBAN suffix, a serial number.
  final Map<String, String> identifiers;

  final Map<String, dynamic> metadata;
  final int itemCount;

  factory LifeEntity.fromJson(Map<String, dynamic> json) => LifeEntity(
    id: json['id'] as String,
    type: EntityType.fromWire(json['type'] as String?),
    name: json['name'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    identifiers:
        (json['identifiers'] as Map?)?.cast<String, String>() ?? const {},
    metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    itemCount: json['item_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.wire,
    'name': name,
    'subtitle': subtitle,
    'identifiers': identifiers,
    'metadata': metadata,
  };

  @override
  bool operator ==(Object other) => other is LifeEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
