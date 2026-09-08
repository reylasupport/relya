import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/assistant_message.dart';
import 'views/assistant_intro.dart';
import 'views/assistant_parts.dart';

/// Questions about the user own life, answered only from the user own data.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<AssistantMessage> _messages = const [];
  bool _thinking = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _thinking) return;
    _input.clear();

    setState(() {
      _thinking = true;
      _messages = [
        ..._messages,
        AssistantMessage(
          id: 'local-${_messages.length}',
          role: AssistantRole.user,
          text: question,
          createdAt: DateTime.now(),
        ),
      ];
    });
    _scrollToEnd();

    try {
      final answer = await ref.read(assistantRepositoryProvider).ask(question);
      if (!mounted) return;
      // The server answers with nothing at all when the user has no items yet.
      // An empty bubble reads as a broken assistant, so say why it is empty.
      final text = answer.text.trim().isEmpty
          ? context.l10n.assistantNoData
          : answer.text;
      setState(() => _messages = [..._messages, answer.copyWith(text: text)]);
    } catch (error, stack) {
      AppLogger.error('The assistant could not answer', error, stack);
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          AssistantMessage(
            id: 'err-${_messages.length}',
            role: AssistantRole.assistant,
            // Running out of the daily allowance is not a failure to answer,
            // and saying "something went wrong" for it sends the user looking
            // for a bug that is not there.
            text: error is QuotaExceeded
                ? context.l10n.assistantLimitReached
                : context.l10n.errorGeneric,
            createdAt: DateTime.now(),
            failed: true,
          ),
        ];
      });
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kit = context.kit;
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      body: kit.page(
        context,
        child: Column(
          children: [
            const AssistantHeader(),
            Expanded(
              child: _messages.isEmpty
                  ? AssistantIntro(onPick: _send, name: profile?.firstName)
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.all(kit.gutter),
                      itemCount: _messages.length + (_thinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _messages.length) {
                          return const AssistantBubble(
                            text: '...',
                            isUser: false,
                          );
                        }
                        final message = _messages[index];
                        return AssistantBubble(
                          text: message.text,
                          isUser: message.isUser,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(kit.gutter, 8, kit.gutter, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: l10n.assistantPlaceholder,
                          // The composer follows the design: a tight field in
                          // the poster one, a pill everywhere else.
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              context.concept == Concept.a ? 12 : 999,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _thinking ? null : () => _send(),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
