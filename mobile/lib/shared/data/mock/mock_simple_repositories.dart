import 'dart:convert';

import '../../domain/assistant_message.dart';
import '../../domain/life_entity.dart';
import '../../domain/reminder.dart';
import '../../domain/user_preferences.dart';
import '../../domain/user_profile.dart';
import '../repositories/assistant_repository.dart';
import '../repositories/entity_repository.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/reminder_repository.dart';
import 'mock_fixtures.dart';

class MockReminderRepository implements ReminderRepository {
  final List<Reminder> _reminders = [];

  @override
  Future<List<Reminder>> forItem(String itemId) async =>
      _reminders.where((r) => r.itemId == itemId).toList();

  @override
  Future<List<Reminder>> pending() async =>
      _reminders.where((r) => r.isPending).toList();

  @override
  Future<Reminder> create(Reminder reminder) async {
    _reminders.add(reminder);
    return reminder;
  }

  @override
  Future<List<Reminder>> createAll(List<Reminder> reminders) async {
    _reminders.addAll(reminders);
    return reminders;
  }

  @override
  Future<void> cancel(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
  }

  @override
  Future<void> rescheduleForTimezone(String timezone) async {}
}

class MockEntityRepository implements EntityRepository {
  final List<LifeEntity> _entities = MockFixtures.entities().toList();

  @override
  Future<List<LifeEntity>> all() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _entities.toList();
  }

  @override
  Future<LifeEntity?> byId(String id) async {
    for (final entity in _entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  @override
  Future<LifeEntity> create(LifeEntity entity) async {
    _entities.add(entity);
    return entity;
  }

  @override
  Future<LifeEntity> update(LifeEntity entity) async {
    final index = _entities.indexWhere((e) => e.id == entity.id);
    if (index >= 0) _entities[index] = entity;
    return entity;
  }

  @override
  Future<void> delete(String id) async =>
      _entities.removeWhere((e) => e.id == id);
}

class MockProfileRepository implements ProfileRepository {
  UserProfile _profile = UserProfile(
    id: 'mock-user',
    displayName: 'Joao',
    email: 'joao@example.com',
    plan: PlanTier.free,
    locale: null,
    timezone: 'Europe/Lisbon',
    capturesThisPeriod: 6,
    captureQuota: 20,
    periodResetsAt: DateTime.now().toUtc().add(const Duration(days: 18)),
    onboardedAt: DateTime.now().toUtc().subtract(const Duration(days: 30)),
  );

  UserPreferences _preferences = const UserPreferences();

  @override
  Future<UserProfile?> current() async => _profile;

  @override
  Future<UserProfile> update(UserProfile profile) async => _profile = profile;

  @override
  Future<UserPreferences> preferences() async => _preferences;

  @override
  Future<UserPreferences> savePreferences(UserPreferences preferences) async =>
      _preferences = preferences;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<String> exportData() async => const JsonEncoder.withIndent(
    '  ',
  ).convert({'items': [], 'captures': [], 'exported_at': null});
}

/// Canned answers so the Assistant screen can be designed and demoed. The real
/// implementation retrieves the user items and passes them to the model as
/// context; neither version is allowed to answer from general knowledge.
class MockAssistantRepository implements AssistantRepository {
  final List<AssistantMessage> _messages = [];

  @override
  Future<List<AssistantMessage>> history() async => _messages.toList();

  @override
  Future<AssistantMessage> ask(String question) async {
    _messages.add(
      AssistantMessage(
        id: 'q-${_messages.length}',
        role: AssistantRole.user,
        text: question,
        createdAt: DateTime.now(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final answer = AssistantMessage(
      id: 'a-${_messages.length}',
      role: AssistantRole.assistant,
      text:
          'You have a dentist appointment today at 15:30, the Nike return '
          'window closes in 3 days, and your car insurance renews in 12 days.',
      createdAt: DateTime.now(),
      citedItemIds: const ['itm-dentist', 'itm-return', 'itm-insurance'],
    );
    _messages.add(answer);
    return answer;
  }

  @override
  Future<void> clear() async => _messages.clear();
}

/// Keeps the corrections in memory so the confirmation flow can be tested
/// end to end without a backend.
class MockFeedbackRepository implements FeedbackRepository {
  final List<ExtractionCorrection> recorded = [];

  @override
  Future<void> record(List<ExtractionCorrection> corrections) async =>
      recorded.addAll(corrections);
}
