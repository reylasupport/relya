import 'package:flutter_test/flutter_test.dart';
import 'package:relya/shared/data/mock/mock_simple_repositories.dart';

/// The demo assistant has to sound like it listened.
///
/// It answered every question with the same three items, which in a demo is
/// worse than answering nothing: ask twice, get the same sentence, and the
/// thing reads as broken rather than empty. There is still no model behind
/// it - the point of these tests is that the answers come from the fixture
/// list on the screen behind it, and that a second question moves on.
void main() {
  test('a question about money gets the things that cost money', () async {
    final assistant = MockAssistantRepository();

    final answer = await assistant.ask('What do I have to pay this month?');

    expect(answer.citedItemIds, isNotEmpty);
    // The dentist appointment costs nothing and has no business here.
    expect(answer.citedItemIds, isNot(contains('itm-dentist')));
  });

  test('a question about returns gets the return', () async {
    final assistant = MockAssistantRepository();

    final answer = await assistant.ask('Can I still return anything?');

    expect(answer.citedItemIds, contains('itm-return'));
  });

  test('asking what else moves on instead of repeating itself', () async {
    final assistant = MockAssistantRepository();

    final first = await assistant.ask('How is my life?');
    final second = await assistant.ask('What more do I have?');

    expect(first.citedItemIds, isNotEmpty);
    expect(second.text, isNot(first.text));
    // Nothing said twice.
    for (final id in second.citedItemIds) {
      expect(
        first.citedItemIds,
        isNot(contains(id)),
        reason: '$id was already mentioned',
      );
    }
  });

  test('it admits when there is nothing left rather than inventing', () async {
    final assistant = MockAssistantRepository();

    // Drain everything it knows.
    for (var i = 0; i < 8; i++) {
      await assistant.ask('what else?');
    }
    final last = await assistant.ask('what else?');

    expect(last.citedItemIds, isEmpty);
    expect(last.text, contains('everything'));
  });

  test('both sides of the exchange are kept, in order', () async {
    final assistant = MockAssistantRepository();

    await assistant.ask('How is my life?');
    final history = await assistant.history();

    expect(history, hasLength(2));
    expect(history.first.text, 'How is my life?');
  });

  test('it answers in Portuguese keywords too', () async {
    final assistant = MockAssistantRepository();

    final answer = await assistant.ask('O que tenho para pagar este mes?');

    expect(answer.citedItemIds, isNot(contains('itm-dentist')));
    expect(answer.citedItemIds, isNotEmpty);
  });

  group('one week is not the next one', () {
    test("three questions about three weeks give three answers", () async {
      final assistant = MockAssistantRepository();

      final now = await assistant.ask(
        "Tenho alguma coisa importante esta semana?",
        languageCode: "pt",
      );
      final next = await assistant.ask(
        "e na proxima semana?",
        languageCode: "pt",
      );
      final after = await assistant.ask(
        "e na semana a seguir a essa?",
        languageCode: "pt",
      );

      // The screenshot that started this: the same sentence three times.
      expect(next.text, isNot(now.text));
      expect(after.text, isNot(next.text));
    });

    test("a later week never repeats an earlier one", () async {
      final assistant = MockAssistantRepository();

      final now = await assistant.ask("this week?");
      final next = await assistant.ask("and next week?");

      for (final id in next.citedItemIds) {
        expect(now.citedItemIds, isNot(contains(id)));
      }
    });

    test("an empty week says so instead of showing another one", () async {
      final assistant = MockAssistantRepository();

      // Far enough out that the fixtures have nothing there.
      await assistant.ask("this week?");
      var answer = await assistant.ask("and next week?");
      for (var i = 0; i < 6; i++) {
        answer = await assistant.ask("and the week after that?");
      }

      expect(answer.citedItemIds, isEmpty);
    });
  });

  group("it answers in the language the app is in", () {
    test("Portuguese", () async {
      final answer = await MockAssistantRepository().ask(
        "O que tenho esta semana?",
        languageCode: "pt",
      );

      // The bug in the screenshot: an English sentence in a Portuguese app.
      expect(answer.text, isNot(startsWith("You have")));
    });

    test("Spanish", () async {
      final answer = await MockAssistantRepository().ask(
        "Que tengo esta semana?",
        languageCode: "es",
      );

      expect(answer.text, isNot(startsWith("You have")));
    });

    test("and English when that is what it is set to", () async {
      final answer = await MockAssistantRepository().ask(
        "What do I have this week?",
        languageCode: "en",
      );

      expect(answer.text, startsWith("You have"));
    });
  });
}
