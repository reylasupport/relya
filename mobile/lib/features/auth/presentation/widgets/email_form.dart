import 'package:flutter/material.dart';

import '../../../../core/design/tokens/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../application/auth_controller.dart';
import '../../domain/auth_service.dart';

/// Email and password, plus the passwordless escape hatch.
///
/// The magic link stays on screen in both modes because it is still the
/// better option: no password to forget, to reuse, or for us to store.
class EmailForm extends StatefulWidget {
  const EmailForm({super.key, required this.state, required this.controller});

  final SignInUiState state;
  final SignInController controller;

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _trimmedEmail => _email.text.trim();

  bool get _emailLooksValid {
    final value = _trimmedEmail;
    final at = value.indexOf('@');
    return at > 0 && value.indexOf('.', at) > at + 1;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.signIn(
      AuthProviderKind.password,
      email: _trimmedEmail,
      password: _password.text,
    );
  }

  void _sendLink() {
    if (!_emailLooksValid) {
      _formKey.currentState?.validate();
      return;
    }
    widget.controller.signIn(AuthProviderKind.magicLink, email: _trimmedEmail);
  }

  void _reset() {
    if (!_emailLooksValid) {
      _formKey.currentState?.validate();
      return;
    }
    widget.controller.sendReset(_trimmedEmail);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final busy = state.inFlight == AuthProviderKind.password;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(hintText: l10n.authEmailHint),
            validator: (_) => _emailLooksValid ? null : l10n.authEmailInvalid,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _password,
            obscureText: _obscured,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            autofillHints: [
              state.isSignUp
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            decoration: InputDecoration(
              hintText: l10n.authPasswordHint,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              // Only enforced when registering. On sign-in an old, shorter
              // password must still be accepted.
              if (!state.isSignUp) return null;
              return (value ?? '').length < 8
                  ? l10n.authPasswordTooShort
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    state.isSignUp ? l10n.authModeSignUp : l10n.authModeSignIn,
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: _sendLink, child: Text(l10n.authOrUseLink)),
          if (!state.isSignUp)
            TextButton(onPressed: _reset, child: Text(l10n.authForgotPassword)),
        ],
      ),
    );
  }
}
