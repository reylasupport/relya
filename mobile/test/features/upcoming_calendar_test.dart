import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/features/upcoming/application/upcoming_controller.dart';
import 'package:relya/shared/data/mock/mock_life_item_repository.dart';
import 'package:relya/core/formatting/time_bucket.dart';
import 'package:relya/shared/data/providers.dart';
import 'package:relya/shared/domain/life_item.dart';
import 'package:relya/shared/domain/life_item_status.dart';
import 'package:relya/shared/domain/life_item_type.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        lifeItemRepositoryProvider.overrideWithValue(MockLifeItemRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('items are bucketed by their local calendar day', () async {
    final data = await container.read(calendarDataProvider.future);

    final today = DateTime.now();
    // The fixtures put a dentist appointment and a delivery on today.
    expect(data.countOn(today), greaterThanOrEqualTo(2));

    final titles = data.on(today).map((i) => i.title);
    expect(titles, contains('Dentist appointment'));
  });

  test('a day with nothing on it returns an empty list, never null', () async {
    final data = await container.read(calendarDataProvider.future);
    final quiet = DateTime.now().add(const Duration(days: 900));
    expect(data.on(quiet), isEmpty);
    expect(data.countOn(quiet), 0);
  });

  test('items on a day come back in time order', () async {
    final data = await container.read(calendarDataProvider.future);
    for (final items in data.byDay.values) {
      for (var i = 1; i < items.length; i++) {
        final previous = items[i - 1].primaryInstant!;
        final current = items[i].primaryInstant!;
        expect(previous.isAfter(current), isFalse);
      }
    }
  });

  test('a future day is never reported as overdue', () async {
    final data = await container.read(calendarDataProvider.future);
    expect(
      data.hasOverdue(DateTime.now().add(const Duration(days: 3))),
      isFalse,
    );
  });

  test('an item with no date still reaches the timeline', () async {
    // A manual task, or an extraction the model found no date in, used to be
    // written and then dropped by every list that reads primaryInstant.
    final repository = container.read(lifeItemRepositoryProvider);
    await repository.create(
      LifeItem(
        id: 'undated-1',
        type: LifeItemType.task,
        title: 'Call the landlord',
        status: LifeItemStatus.active,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    final sections = await container.read(upcomingProvider.future);
    final undated = sections.singleWhere((s) => s.bucket == TimeBucket.undated);

    expect(undated.items.map((i) => i.title), contains('Call the landlord'));
    expect(sections.last.bucket, TimeBucket.undated);
  });

  test('the calendar opens on today, in this month', () {
    final now = DateTime.now();
    final selected = container.read(selectedDayProvider);
    final month = container.read(visibleMonthProvider);

    expect(selected.day, now.day);
    expect(month.month, now.month);
    expect(container.read(upcomingViewModeProvider), UpcomingViewMode.calendar);
  });
}
