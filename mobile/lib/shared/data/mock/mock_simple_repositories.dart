import 'dart:convert';

import '../../domain/assistant_message.dart';
import '../../domain/life_entity.dart';
import '../../domain/life_item.dart';
import '../../domain/life_item_type.dart';
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
/// Answers out of the same fixtures every other screen is showing.
///
/// It used to return one hard-coded sentence to anything it was asked, which
/// in a demo is worse than saying nothing: ask two different questions, get
/// the same three items, and the assistant reads as broken rather than empty.
/// This is still a mock - there is no model here - but the answers are drawn
/// from the real fixture list, so what it says always matches what is on the
/// screen behind it, and a second question moves on to something new.
class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({List<LifeItem>? items})
    : _items = items ?? MockFixtures.items(DateTime.now().toUtc());

  final List<AssistantMessage> _messages = [];
  final List<LifeItem> _items;

  /// What has already been said. "What else do I have?" is a request for the
  /// things that were not mentioned the first time.
  final Set<String> _mentioned = {};

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
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final asked = question.toLowerCase();
    final more = _asksForMore(asked);
    var pool = _matching(asked);

    // Anything already said is old news when the question is "what else".
    if (more) {
      final fresh = pool.where((i) => !_mentioned.contains(i.id)).toList();
      pool = fresh.isEmpty ? const [] : fresh;
    }

    final picked = pool.take(3).toList();
    _mentioned.addAll(picked.map((i) => i.id));

    final answer = AssistantMessage(
      id: 'a-${_messages.length}',
      role: AssistantRole.assistant,
      text: _say(picked, more: more),
      createdAt: DateTime.now(),
      citedItemIds: picked.map((i) => i.id).toList(),
    );
    _messages.add(answer);
    return answer;
  }

  bool _asksForMore(String asked) => const [
    'more',
    'else',
    'other',
    'mais',
    'outra',
    'outro',
    'resto',
    'más',
    'otra',
  ].any(asked.contains);

  /// Keyword matching, in the four languages the app ships in. Crude on
  /// purpose: the job is to make the demo behave like something that listened,
  /// not to pretend there is a model behind it.
  List<LifeItem> _matching(String asked) {
    bool has(List<String> words) => words.any(asked.contains);

    final now = DateTime.now().toUtc();
    final upcoming = [..._items]
      ..sort((a, b) {
        final x = a.primaryInstant;
        final y = b.primaryInstant;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });

    if (has([
      'pay',
      'bill',
      'cost',
      'money',
      'owe',
      'pagar',
      'pago',
      'conta',
      'dinheiro',
      'fatura',
      'pagamento',
      'pagar',
      'cobro',
      'dinero',
    ])) {
      return upcoming.where((i) => i.amount != null).toList();
    }

    if (has(['return', 'refund', 'devolv', 'troca', 'devoluc'])) {
      return upcoming
          .where((i) => i.type == LifeItemType.returnDeadline)
          .toList();
    }

    if (has([
      'subscription',
      'renew',
      'subscri',
      'assinatura',
      'renova',
      'suscrip',
    ])) {
      return upcoming
          .where(
            (i) =>
                i.type == LifeItemType.subscription ||
                i.type == LifeItemType.insurance,
          )
          .toList();
    }

    if (has(['today', 'hoje', 'hoy'])) {
      return upcoming.where((i) {
        final at = i.primaryInstant;
        return at != null && at.difference(now).inHours.abs() < 24;
      }).toList();
    }

    if (has(['week', 'semana'])) {
      return upcoming.where((i) {
        final at = i.primaryInstant;
        return at != null && at.isAfter(now) && at.difference(now).inDays <= 7;
      }).toList();
    }

    return upcoming.where((i) => i.primaryInstant != null).toList();
  }

  String _say(List<LifeItem> items, {required bool more}) {
    if (items.isEmpty) {
      return more
          ? 'That is everything I am keeping track of for you.'
          : 'I could not find anything about that in your items.';
    }

    final parts = items.map(_phrase).toList();
    final list = parts.length == 1
        ? parts.single
        : '${parts.take(parts.length - 1).join(', ')} and ${parts.last}';

    return more ? 'There is also $list.' : 'You have $list.';
  }

  String _phrase(LifeItem item) {
    final at = item.primaryInstant;
    final title = item.title.toLowerCase();
    if (at == null) return title;

    final days = at.difference(DateTime.now().toUtc()).inDays;
    if (days <= 0) return '$title today';
    if (days == 1) return '$title tomorrow';
    return '$title in $days days';
  }

  @override
  Future<void> clear() async {
    _messages.clear();
    _mentioned.clear();
  }
}

/// Keeps the corrections in memory so the confirmation flow can be tested
/// end to end without a backend.
class MockFeedbackRepository implements FeedbackRepository {
  final List<ExtractionCorrection> recorded = [];

  @override
  Future<void> record(List<ExtractionCorrection> corrections) async =>
      recorded.addAll(corrections);
}
