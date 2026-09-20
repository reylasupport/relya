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
}
