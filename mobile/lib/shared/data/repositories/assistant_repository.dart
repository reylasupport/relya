import '../../domain/assistant_message.dart';

/// Answers questions using only the items the user already owns. The backend
/// retrieves candidate items and hands them to the model as context; the model
/// is never allowed to answer from general knowledge (spec section 9).
abstract interface class AssistantRepository {
  Future<List<AssistantMessage>> history();

  Future<AssistantMessage> ask(String question);

  Future<void> clear();
}
