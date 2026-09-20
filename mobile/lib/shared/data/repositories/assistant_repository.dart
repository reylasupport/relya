import '../../domain/assistant_message.dart';

/// Answers questions using only the items the user already owns. The backend
/// retrieves candidate items and hands them to the model as context; the model
/// is never allowed to answer from general knowledge (spec section 9).
abstract interface class AssistantRepository {
  Future<List<AssistantMessage>> history();

  /// [languageCode] is what the answer should be written in.
  ///
  /// The real implementation ignores it: the model is told to reply in the
  /// language of the question, which handles the case where somebody asks in
  /// Portuguese on an interface set to English. The demo cannot read a
  /// question, so it is told instead - and answering an app set to Portuguese
  /// in English is exactly the kind of detail that makes a demo look unfinished.
  Future<AssistantMessage> ask(String question, {String languageCode});

  Future<void> clear();
}
