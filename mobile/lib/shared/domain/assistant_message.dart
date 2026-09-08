enum AssistantRole { user, assistant }

/// One turn in the Assistant conversation.
///
/// [citedItemIds] is what keeps the assistant honest: every factual claim it
/// makes has to point at items the user already owns. An answer with no
/// citations and no data is rendered as "I could not find anything", never as
/// an invented fact (spec section 9).
class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.citedItemIds = const [],
    this.isPending = false,
    this.failed = false,
  });

  final String id;
  final AssistantRole role;
  final String text;
  final DateTime createdAt;
  final List<String> citedItemIds;
  final bool isPending;
  final bool failed;

  bool get isUser => role == AssistantRole.user;

  AssistantMessage copyWith({
    String? text,
    List<String>? citedItemIds,
    bool? isPending,
    bool? failed,
  }) {
    return AssistantMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      createdAt: createdAt,
      citedItemIds: citedItemIds ?? this.citedItemIds,
      isPending: isPending ?? this.isPending,
      failed: failed ?? this.failed,
    );
  }
}
