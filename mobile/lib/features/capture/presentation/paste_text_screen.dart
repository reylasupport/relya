import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../navigation/routes.dart';
import '../application/capture_controller.dart';

class PasteTextScreen extends ConsumerStatefulWidget {
  const PasteTextScreen({super.key});

  @override
  ConsumerState<PasteTextScreen> createState() => _PasteTextScreenState();
}

class _PasteTextScreenState extends ConsumerState<PasteTextScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final parked = context.l10n.captureQueuedOffline;
    final failed = context.l10n.errorGeneric;
    try {
      final attempt = await ref.read(captureControllerProvider).fromText(text);
      // Parked means it went to the outbox: there is nothing to confirm yet,
      // so say so and step back rather than opening an empty analysis screen.
      if (attempt.outcome != CaptureOutcome.created) {
        messenger.showSnackBar(SnackBar(content: Text(parked)));
        router.pop();
        return;
      }
      router.pushReplacement(Routes.analysis(attempt.capture!.id));
    } catch (error, stack) {
      AppLogger.error('Could not queue pasted text', error, stack);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.capturePasteText)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: context.l10n.capturePasteHint,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(context.l10n.actionContinue),
            ),
          ],
        ),
      ),
    );
  }
}
