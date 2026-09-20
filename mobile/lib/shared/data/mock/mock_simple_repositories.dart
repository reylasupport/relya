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
/// The words the demo answers in.
///
/// Small on purpose. These are not user-facing strings in the ARB sense -
/// nothing in a shipped build reaches them, because a real build asks a model
/// that replies in the language of the question. They exist so the demo does
/// not answer a Portuguese question in English, which is the kind of detail
/// that makes the whole thing look unfinished.
class _Phrases {
  const _Phrases({
    required this.youHave,
    required this.alsoHave,
    required this.thatIsEverything,
    required this.nothingThen,
    required this.today,
    required this.tomorrow,
    required this.inDays,
    required this.and,
  });

  factory _Phrases.of(String languageCode) => switch (languageCode) {
    'pt' => const _Phrases(
      youHave: 'Tens ',
      alsoHave: 'Tens também ',
      thatIsEverything: 'É tudo o que tenho guardado por ti.',
      nothingThen: 'Nessa altura não tens nada marcado.',
      today: 'hoje',
      tomorrow: 'amanhã',
      inDays: 'daqui a ',
      and: ' e ',
    ),
    'es' => const _Phrases(
      youHave: 'Tienes ',
      alsoHave: 'También tienes ',
      thatIsEverything: 'Eso es todo lo que tengo guardado.',
      nothingThen: 'No tienes nada en esas fechas.',
      today: 'hoy',
      tomorrow: 'mañana',
      inDays: 'en ',
      and: ' y ',
    ),
    _ => const _Phrases(
      youHave: 'You have ',
      alsoHave: 'You also have ',
      thatIsEverything: 'That is everything I am keeping track of for you.',
      nothingThen: 'Nothing is booked for you then.',
      today: 'today',
      tomorrow: 'tomorrow',
      inDays: 'in ',
      and: ' and ',
    ),
  };

  final String youHave;
  final String alsoHave;
  final String thatIsEverything;
  final String nothingThen;
  final String today;
  final String tomorrow;
  final String inDays;
  final String and;

  String days(int n) => switch (inDays) {
    'daqui a ' => 'daqui a $n dias',
    'en ' => 'en $n días',
    _ => 'in $n days',
  };
}

/// Answers out of the same fixtures every other screen is showing.
///
/// It used to return one hard-coded English sentence to anything it was asked,
/// which in a demo is worse than answering nothing: ask three questions about
/// three different weeks, get the same three items back in the wrong language,
/// and the assistant reads as broken rather than empty.
///
/// There is still no model here. What this does is answer from the real
/// fixture list, in the language the interface is in, and keep enough context
/// to know that "and the week after that" is a different question from the one
/// before it.
class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({List<LifeItem>? items})
    : _items = items ?? MockFixtures.items(DateTime.now().toUtc());

  final List<AssistantMessage> _messages = [];
  final List<LifeItem> _items;

  /// What has already been said, so "what else?" moves on.
  final Set<String> _mentioned = {};

  /// Which week was last asked about. "Next week" means nothing on its own -
  /// it means the week after whichever one we were just talking about.
  int? _week;

  @override
  Future<List<AssistantMessage>> history() async => _messages.toList();

  @override
  Future<AssistantMessage> ask(
    String question, {
    String languageCode = 'en',
  }) async {
    _messages.add(
      AssistantMessage(
        id: 'q-${_messages.length}',
        role: AssistantRole.user,
        text: question,
        createdAt: DateTime.now(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final phrases = _Phrases.of(languageCode);
    final asked = _fold(question);
    final week = _weekAskedAbout(asked);
    final more = week == null && _asksForMore(asked);

    var pool = week != null ? _inWeek(week) : _matching(asked);
    if (more) {
      pool = pool.where((i) => !_mentioned.contains(i.id)).toList();
    }

    final picked = pool.take(3).toList();
    _mentioned.addAll(picked.map((i) => i.id));

    final answer = AssistantMessage(
      id: 'a-${_messages.length}',
      role: AssistantRole.assistant,
      text: _say(picked, phrases, more: more, aboutAWeek: week != null),
      createdAt: DateTime.now(),
      citedItemIds: picked.map((i) => i.id).toList(),
    );
    _messages.add(answer);
    return answer;
  }

  /// Lower case and without accents, so "próxima" and "proxima" are the same
  /// word to everything below.
  String _fold(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final at = from.indexOf(char);
      buffer.write(at == -1 ? char : to[at]);
    }
    return buffer.toString();
  }

  bool _has(String asked, List<String> words) => words.any(asked.contains);

  bool _asksForMore(String asked) => _has(asked, [
    'more',
    'else',
    'other',
    'mais',
    'outra',
    'outro',
    'resto',
    'otra',
  ]);

  /// Which week the question is about, counting from the one we are in.
  ///
  /// Null when the question is not about a week at all. The state matters:
  /// asked three times in a row, "this week", "and next week" and "and the
  /// week after that" have to be three different answers, and they only are
  /// if each one is read relative to the last.
  int? _weekAskedAbout(String asked) {
    if (!_has(asked, ['week', 'semana'])) {
      // "And the one after that?" can arrive without the word at all.
      if (_week != null && _has(asked, ['seguir', 'seguinte', 'after'])) {
        return _week = _week! + 1;
      }
      return null;
    }

    if (_has(asked, ['this ', 'esta ', 'essa '])) return _week = 0;
    if (_has(asked, ['seguir', 'seguinte', 'after'])) {
      return _week = (_week ?? 0) + 1;
    }
    if (_has(asked, ['next', 'proxima', 'proximo', 'siguiente', 'que vem'])) {
      return _week = (_week ?? 0) + 1;
    }
    return _week = 0;
  }

  List<LifeItem> _inWeek(int offset) {
    final now = DateTime.now().toUtc();
    return _upcoming().where((item) {
      final at = item.primaryInstant;
      if (at == null) return false;
      final days = at.difference(now).inDays;
      return days >= offset * 7 && days < (offset + 1) * 7;
    }).toList();
  }

  List<LifeItem> _upcoming() {
    final sorted = [..._items]
      ..sort((a, b) {
        final x = a.primaryInstant;
        final y = b.primaryInstant;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });
    return sorted.where((i) => i.primaryInstant != null).toList();
  }

  /// Keyword matching, in the languages the app ships in. Crude on purpose:
  /// the job is to behave like something that listened, not to pretend there
  /// is a model behind it.
  List<LifeItem> _matching(String asked) {
    if (_has(asked, [
      'pay',
      'bill',
      'cost',
      'money',
      'owe',
      'pagar',
      'conta',
      'dinheiro',
      'fatura',
      'pagamento',
      'dinero',
    ])) {
      return _upcoming().where((i) => i.amount != null).toList();
    }

    if (_has(asked, ['return', 'refund', 'devolv', 'troca'])) {
      return _upcoming()
          .where((i) => i.type == LifeItemType.returnDeadline)
          .toList();
    }

    if (_has(asked, [
      'subscription',
      'renew',
      'subscri',
      'assinatura',
      'renova',
      'suscrip',
    ])) {
      return _upcoming()
          .where(
            (i) =>
                i.type == LifeItemType.subscription ||
                i.type == LifeItemType.insurance,
          )
          .toList();
    }

    if (_has(asked, ['today', 'hoje', 'hoy'])) {
      final now = DateTime.now().toUtc();
      return _upcoming().where((i) {
        final at = i.primaryInstant!;
        return at.difference(now).inHours.abs() < 24;
      }).toList();
    }

    return _upcoming();
  }

  String _say(
    List<LifeItem> items,
    _Phrases phrases, {
    required bool more,
    required bool aboutAWeek,
  }) {
    if (items.isEmpty) {
      if (aboutAWeek) return phrases.nothingThen;
      return more ? phrases.thatIsEverything : phrases.thatIsEverything;
    }

    final parts = items.map((i) => _phrase(i, phrases)).toList();
    final list = parts.length == 1
        ? parts.single
        : '${parts.take(parts.length - 1).join(', ')}${phrases.and}${parts.last}';

    return '${more ? phrases.alsoHave : phrases.youHave}$list.';
  }

  String _phrase(LifeItem item, _Phrases phrases) {
    final at = item.primaryInstant;
    final title = item.title.toLowerCase();
    if (at == null) return title;

    final days = at.difference(DateTime.now().toUtc()).inDays;
    if (days <= 0) return '$title ${phrases.today}';
    if (days == 1) return '$title ${phrases.tomorrow}';
    return '$title ${phrases.days(days)}';
  }

  @override
  Future<void> clear() async {
    _messages.clear();
    _mentioned.clear();
    _week = null;
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
