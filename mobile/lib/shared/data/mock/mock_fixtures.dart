import '../../domain/capture.dart';
import '../../domain/life_entity.dart';
import '../../domain/life_item.dart';
import '../../domain/life_item_status.dart';
import '../../domain/life_item_type.dart';

/// Fixtures that mirror the worked examples in the specification, so the app
/// can be demoed, screenshotted and widget-tested without a backend.
///
/// Everything is positioned relative to now, so the Home screen always has a
/// today, a tomorrow and a next-month.
abstract final class MockFixtures {
  const MockFixtures._();

  static DateTime _at(
    DateTime now, {
    int days = 0,
    int hour = 9,
    int minute = 0,
  }) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: days));
    return DateTime(day.year, day.month, day.day, hour, minute).toUtc();
  }

  static List<LifeItem> items(DateTime now) {
    return [
      LifeItem(
        id: 'itm-dentist',
        captureId: 'cap-dentist',
        type: LifeItemType.appointment,
        title: 'Dentist appointment',
        description: 'Clinica Central, Dr. Silva',
        status: LifeItemStatus.active,
        startAt: _at(now, hour: 15, minute: 30),
        startTimezone: 'Europe/Lisbon',
        location: 'Clinica Central',
        organization: 'Clinica Central',
        confidence: 0.96,
        sourceLanguage: 'pt',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      LifeItem(
        id: 'itm-delivery',
        captureId: 'cap-delivery',
        type: LifeItemType.delivery,
        title: 'Package arriving',
        description: 'Amazon order 405-2298',
        status: LifeItemStatus.active,
        startAt: _at(now, hour: 14),
        endAt: _at(now, hour: 18),
        startTimezone: 'Europe/Lisbon',
        confidence: 0.91,
        metadata: const {
          'reference_numbers': ['405-2298'],
        },
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      LifeItem(
        id: 'itm-ikea',
        captureId: 'cap-ikea',
        type: LifeItemType.delivery,
        title: 'IKEA delivery',
        status: LifeItemStatus.active,
        startAt: _at(now, days: 1, hour: 14),
        endAt: _at(now, days: 1, hour: 18),
        startTimezone: 'Europe/Lisbon',
        confidence: 0.88,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      LifeItem(
        id: 'itm-return',
        captureId: 'cap-nike',
        type: LifeItemType.returnDeadline,
        title: 'Return window closes',
        description: 'Nike Air Max, Loja X',
        status: LifeItemStatus.active,
        deadlineAt: _at(now, days: 3, hour: 23, minute: 59),
        amount: 149.99,
        currency: 'EUR',
        organization: 'Loja X',
        confidence: 0.82,
        metadata: const {'product': 'Nike Air Max'},
        createdAt: now.subtract(const Duration(days: 27)),
      ),
      LifeItem(
        id: 'itm-netflix',
        captureId: 'cap-netflix',
        type: LifeItemType.subscription,
        title: 'Netflix renews',
        status: LifeItemStatus.active,
        deadlineAt: _at(now, days: 6, hour: 9),
        amount: 15.99,
        currency: 'EUR',
        organization: 'Netflix',
        confidence: 0.97,
        metadata: const {'recurrence': 'FREQ=MONTHLY'},
        createdAt: now.subtract(const Duration(days: 24)),
      ),
      LifeItem(
        id: 'itm-insurance',
        captureId: 'cap-insurance',
        type: LifeItemType.insurance,
        title: 'Car insurance renews',
        description: 'Automatic renewal',
        status: LifeItemStatus.active,
        deadlineAt: _at(now, days: 12, hour: 9),
        amount: 487.90,
        currency: 'EUR',
        entityId: 'ent-car',
        confidence: 0.94,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      LifeItem(
        id: 'itm-flight',
        captureId: 'cap-flight',
        type: LifeItemType.travel,
        title: 'Lisbon to London',
        description: 'TP1352',
        status: LifeItemStatus.active,
        startAt: _at(now, days: 21, hour: 7, minute: 25),
        startTimezone: 'Europe/Lisbon',
        location: 'Lisbon Airport',
        organization: 'TAP Air Portugal',
        confidence: 0.93,
        metadata: const {'flight_number': 'TP1352', 'terminal': '1'},
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      LifeItem(
        id: 'itm-passport',
        type: LifeItemType.document,
        title: 'Passport expires',
        status: LifeItemStatus.active,
        deadlineAt: _at(now, days: 180, hour: 9),
        confidence: 1.0,
        entityId: 'ent-docs',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }

  static List<Capture> captures(DateTime now) => [
    Capture(
      id: 'cap-pending',
      source: CaptureSource.shareSheet,
      kind: CaptureKind.image,
      status: CaptureStatus.needsConfirmation,
      title: 'Screenshot',
      itemCount: 2,
      createdAt: now.subtract(const Duration(minutes: 4)),
      detectedLanguage: 'pt',
    ),
    Capture(
      id: 'cap-insurance',
      source: CaptureSource.shareSheet,
      kind: CaptureKind.pdf,
      status: CaptureStatus.completed,
      title: 'Apolice seguro automovel.pdf',
      itemCount: 1,
      createdAt: now.subtract(const Duration(days: 5)),
      processedAt: now.subtract(const Duration(days: 5)),
      detectedLanguage: 'pt',
    ),
    Capture(
      id: 'cap-nike',
      source: CaptureSource.camera,
      kind: CaptureKind.image,
      status: CaptureStatus.completed,
      title: 'Receipt',
      itemCount: 2,
      createdAt: now.subtract(const Duration(days: 27)),
      processedAt: now.subtract(const Duration(days: 27)),
    ),
  ];

  static List<LifeEntity> entities() => const [
    LifeEntity(
      id: 'ent-car',
      type: EntityType.vehicle,
      name: 'BMW Serie 1',
      subtitle: 'AA-00-BB',
      identifiers: {'plate': 'AA-00-BB'},
      itemCount: 4,
    ),
    LifeEntity(
      id: 'ent-home',
      type: EntityType.home,
      name: 'Home',
      subtitle: 'Electricity, internet, water',
      itemCount: 6,
    ),
    LifeEntity(
      id: 'ent-docs',
      type: EntityType.document,
      name: 'Documents',
      subtitle: 'Passport, ID card',
      itemCount: 3,
    ),
    LifeEntity(
      id: 'ent-health',
      type: EntityType.health,
      name: 'Health',
      subtitle: 'Appointments and exams',
      itemCount: 2,
    ),
    LifeEntity(
      id: 'ent-purchases',
      type: EntityType.product,
      name: 'Purchases',
      subtitle: 'Receipts, returns, warranties',
      itemCount: 5,
    ),
  ];
}
