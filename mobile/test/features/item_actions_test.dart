import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/home/application/home_controller.dart';
import 'package:relya/features/item/application/item_actions.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/shared/data/mock/mock_simple_repositories.dart';
import 'package:relya/shared/data/providers.dart';
import 'package:relya/shared/domain/life_item.dart';
import 'package:relya/shared/domain/life_item_status.dart';
import 'package:relya/shared/domain/life_item_type.dart';
import 'package:relya/shared/domain/recurrence.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockLifeItemRepository items;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    items = MockLifeItemRepository(items: <LifeItem>[]);
    container = ProviderContainer(
      overrides: [
        lifeItemRepositoryProvider.overrideWithValue(items),
        reminderRepositoryProvider.overrideWithValue(MockReminderRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  ItemActions actions() => container.read(itemActionsProvider);

  LifeItem monthlyRent(DateTime due) => LifeItem(
    id: 'rent',
    type: LifeItemType.bill,
    title: 'Rent',
    status: LifeItemStatus.active,
    deadlineAt: due,
    amount: 850,
    currency: 'EUR',
    recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.monthly),
    createdAt: DateTime.now().toUtc(),
  );

  test('completing a repeating item is what writes the next one', () async {
    final rent = monthlyRent(DateTime.utc(2026, 9, 8));
    await items.create(rent);

    final next = await actions().complete(rent);

    expect(next, isNotNull);
    expect(next!.deadlineAt, DateTime.utc(2026, 10, 8));
    expect(next.status, LifeItemStatus.active);
    expect(next.amount, 850);
    // Every occurrence points back at the first one, so the series can be
    // found and stopped as a whole later.
    expect(next.seriesId, rent.id);
    expect(next.id, isNot(rent.id));

    expect((await items.byId(rent.id))!.status, LifeItemStatus.done);
  });

  test('a one-off just closes', () async {
    final task = LifeItem(
      id: 'once',
      type: LifeItemType.task,
      title: 'Call the landlord',
      status: LifeItemStatus.active,
      deadlineAt: DateTime.utc(2026, 9, 8),
      createdAt: DateTime.now().toUtc(),
    );
    await items.create(task);

    expect(await actions().complete(task), isNull);
    expect((await items.byId(task.id))!.status, LifeItemStatus.done);
  });

  test('a series stops at its end date instead of running forever', () async {
    final rent = monthlyRent(
      DateTime.utc(2026, 9, 8),
    ).copyWith(recurrenceUntil: DateTime.utc(2026, 9, 30));
    await items.create(rent);

    expect(await actions().complete(rent), isNull);
  });

  test('snoozing hides the item without moving its date', () async {
    final now = DateTime.now();
    final bill = LifeItem(
      id: 'bill',
      type: LifeItemType.bill,
      title: 'Water',
      status: LifeItemStatus.active,
      deadlineAt: now.toUtc().add(const Duration(days: 2)),
      createdAt: now.toUtc(),
    );
    await items.create(bill);

    final until = now.add(const Duration(days: 1));
    await actions().snooze(bill, until);

    final stored = (await items.byId(bill.id))!;
    expect(stored.status, LifeItemStatus.snoozed);
    // The bill is still due when it was due. What moved is when it is heard
    // about again.
    expect(stored.deadlineAt, bill.deadlineAt);
    expect(stored.isHiddenAt(now), isTrue);

    final home = await container.read(homeSnapshotProvider.future);
    expect(
      [...home.overdue, ...home.today, ...home.next].map((i) => i.id),
      isNot(contains(bill.id)),
    );
  });

  test('a snooze whose moment has passed stops hiding on its own', () async {
    final now = DateTime.now();
    final bill = LifeItem(
      id: 'bill',
      type: LifeItemType.bill,
      title: 'Water',
      status: LifeItemStatus.snoozed,
      snoozedUntil: now.toUtc().subtract(const Duration(minutes: 5)),
      deadlineAt: now.toUtc().add(const Duration(hours: 6)),
      createdAt: now.toUtc(),
    );

    // No background job brings it back: the lists simply stop hiding it.
    expect(bill.isHiddenAt(now), isFalse);
  });

  test('resuming puts the item back on the list', () async {
    final now = DateTime.now();
    final bill = LifeItem(
      id: 'bill',
      type: LifeItemType.bill,
      title: 'Water',
      status: LifeItemStatus.snoozed,
      snoozedUntil: now.toUtc().add(const Duration(days: 3)),
      deadlineAt: now.toUtc().add(const Duration(days: 5)),
      createdAt: now.toUtc(),
    );
    await items.create(bill);

    await actions().resume(bill);

    final stored = (await items.byId(bill.id))!;
    expect(stored.status, LifeItemStatus.active);
    expect(stored.snoozedUntil, isNull);
    expect(stored.isHiddenAt(now), isFalse);
  });
}
