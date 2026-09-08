import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/concept/concept_kit.dart';
import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../application/auth_controller.dart';

/// The six digits that finish a registration.
///
/// A code rather than a link because the person is already in the app with the
/// keyboard up, and a link would send them to a browser and back. It also
/// works when the email is read on a different device, which a link does not.
class ConfirmCodeForm extends StatefulWidget {
  const ConfirmCodeForm({
    super.key,
    required this.state,
    required this.controller,
  });

  final SignInUiState state;
  final SignInController controller;

  @override
  State<ConfirmCodeForm> createState() => _ConfirmCodeFormState();
}

class _ConfirmCodeFormState extends State<ConfirmCodeForm> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _complete => _code.text.trim().length == 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kit = context.kit;
    final email = widget.state.confirmSentTo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.authConfirmTitle, style: kit.heading(context)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.authConfirmBody(email),
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          // The one field in the app where a wide, spaced, centred face is
          // right: six digits copied from an email are read back a digit at
          // a time to check them.
          style: context.text.headlineMedium?.copyWith(letterSpacing: 10),
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: ''),
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) =>
              _complete ? widget.controller.verifyCode(value) : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        kit.primaryButton(
          context,
          label: l10n.authConfirmAction,
          onTap: widget.state.isBusy || !_complete
              ? null
              : () => widget.controller.verifyCode(_code.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.state.isBusy
              ? null
              : () => widget.controller.resendCode(),
          child: Text(l10n.authConfirmResend),
        ),
        TextButton(
          onPressed: widget.controller.cancelConfirmation,
          child: Text(l10n.actionBack),
        ),
      ],
    );
  }
}
