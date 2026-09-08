import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/relya_logo.dart';
import '../../../core/design/concept/concept.dart';
import '../../../core/design/concept/concept_kit.dart';
import '../../../core/design/tokens/app_semantic_colors.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../application/auth_controller.dart';
import '../domain/auth_service.dart';
import 'widgets/confirm_code_form.dart';
import 'widgets/email_form.dart';
import 'widgets/provider_button.dart';

/// One screen, two modes.
///
/// Apple and Google create an account and sign in with the same tap, so the
/// mode only changes what the email half does. Apple is listed first and is
/// never hidden on its own platforms: offering another social provider
/// without it fails App Review, and it is the more private option.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);

    ref.listen(signInControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.error != null) {
        final error = next.error;
        // A dead mailer is not the user's fault and cannot be retried away,
        // so it gets its own sentence and longer on screen. Everything else
        // keeps the message the failure came with.
        final message = switch (error) {
          EmailDeliveryFailure() => l10n.authEmailNotSent,
          AppException() => error.message,
          _ => l10n.errorGeneric,
        };
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: error is EmailDeliveryFailure
                ? const Duration(seconds: 7)
                : const Duration(seconds: 4),
          ),
        );
        controller.clearFeedback();
      } else if (next.linkSentTo != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.authCheckEmailMessage(next.linkSentTo!))),
        );
      } else if (next.resetSentTo != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.authResetSent(next.resetSentTo!))),
        );
      }
    });

    final kit = context.kit;
    // The pastel design centres the wordmark, waves, and leads with the email
    // form - the social buttons come after the divider, and the mode switch
    // is a line of text at the bottom rather than a control at the top. The
    // other three keep the segmented control, which is plainer to scan.
    final centred = context.concept == Concept.e;

    if (state.awaitingCode) {
      return Scaffold(
        body: kit.page(
          context,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(kit.gutter),
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                ConfirmCodeForm(state: state, controller: controller),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: kit.page(
        context,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(kit.gutter),
            children: [
              SizedBox(height: centred ? AppSpacing.xxxl : AppSpacing.xl),
              if (centred) ...[
                const Center(child: RelyaWordmark(fontSize: 44)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.isSignUp
                      ? '${l10n.authTitle} 👋'
                      : '${l10n.authTitleSignIn} 👋',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  state.isSignUp ? l10n.authSubtitle : l10n.authSubtitleSignIn,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
              ] else ...[
                const RelyaLockup(markSize: 46, fontSize: 34),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.isSignUp ? l10n.authSubtitle : l10n.authSubtitleSignIn,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SegmentedButton<AuthMode>(
                  segments: [
                    ButtonSegment(
                      value: AuthMode.signUp,
                      label: Text(l10n.authModeSignUp),
                    ),
                    ButtonSegment(
                      value: AuthMode.signIn,
                      label: Text(l10n.authModeSignIn),
                    ),
                  ],
                  selected: {state.mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      controller.setMode(selection.first),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (centred) ...[
                EmailForm(state: state, controller: controller),
                const SizedBox(height: AppSpacing.xl),
                const _Separator(),
                const SizedBox(height: AppSpacing.xl),
                _providers(context, state, controller),
                const SizedBox(height: AppSpacing.xl),
                _ModeSwitch(state: state, controller: controller),
              ] else ...[
                _providers(context, state, controller),
                const SizedBox(height: AppSpacing.xl),
                const _Separator(),
                const SizedBox(height: AppSpacing.xl),
                EmailForm(state: state, controller: controller),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.authLegal,
                textAlign: TextAlign.center,
                style: context.text.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providers(
    BuildContext context,
    SignInUiState state,
    SignInController controller,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isApplePlatform)
          ProviderButton(
            icon: Icons.apple_rounded,
            label: l10n.authContinueWithApple,
            busy: state.inFlight == AuthProviderKind.apple,
            filled: true,
            onPressed: () => controller.signIn(AuthProviderKind.apple),
          ),
        if (_isApplePlatform) const SizedBox(height: AppSpacing.md),
        ProviderButton(
          icon: Icons.g_mobiledata_rounded,
          label: l10n.authContinueWithGoogle,
          busy: state.inFlight == AuthProviderKind.google,
          // Outlined in the pastel design: the filled violet button on that
          // screen is Entrar, and two solid violet blocks would compete.
          filled: !_isApplePlatform && context.concept != Concept.e,
          onPressed: () => controller.signIn(AuthProviderKind.google),
        ),
      ],
    );
  }
}

/// "Already have an account? Sign in." The pastel design's way of changing
/// mode: a sentence at the bottom rather than a control at the top.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.state, required this.controller});

  final SignInUiState state;
  final SignInController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.isSignUp ? l10n.authHaveAccount : l10n.authNoAccount,
          style: context.text.bodyMedium,
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => controller.setMode(
            state.isSignUp ? AuthMode.signIn : AuthMode.signUp,
          ),
          child: Text(
            state.isSignUp ? l10n.authModeSignIn : l10n.authModeSignUp,
            style: context.text.labelLarge?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: context.semantic.subtleBorder, thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(context.l10n.authOrEmail, style: context.text.labelSmall),
        ),
        line,
      ],
    );
  }
}

/// Apple requires Sign in with Apple wherever another social provider is
/// offered, on its own platforms. defaultTargetPlatform rather than dart:io,
/// so the same check works in tests and in a browser preview.
bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
