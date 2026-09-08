import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/relya_logo.dart';
import '../../../core/design/illustrations/cosy_backdrop.dart';
import '../../../core/design/illustrations/midnight_aurora.dart';
import '../../../core/design/illustrations/pastel_scene.dart';
import '../../../core/design/illustrations/relya_scenes.dart';
import '../../../core/design/tokens/app_skin.dart';
import '../../../core/design/tokens/app_skin_style.dart';
import '../../../core/design/tokens/app_durations.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../services/prefs/local_prefs.dart';
import 'widgets/how_to_add.dart';
import 'widgets/live_demo.dart';
import 'widgets/onboarding_chrome.dart';

/// Three screens: the problem, the product working, and how to feed it.
///
/// The third one is the one that matters. An app whose main input is the
/// system Share Sheet has to teach that, or it gets opened once and forgotten;
/// nobody discovers a share extension on their own.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  static const _lastPage = 2;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).complete();

  void _next() {
    if (_index < _lastPage) {
      _pages.nextPage(duration: AppDurations.normal, curve: AppDurations.curve);
      return;
    }
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Two of the designs open on a full-bleed picture; all of them fall back
    // to the wash on the pages after the first, where a photograph behind a
    // live demo would be unreadable.
    final hero = _index == 0;

    return Scaffold(
      body: _Backdrop(
        hero: hero,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.actionSkip),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (index) => setState(() => _index = index),
                  children: [const _Welcome(), _Magic(), const HowToAdd()],
                ),
              ),
              OnboardingDots(count: _lastPage + 1, index: _index),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.pageInset),
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index == _lastPage
                        ? l10n.onboardingGetStarted
                        : l10n.actionNext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first thing anyone sees, and the one screen that differs most between
/// the four designs.
///
/// They do not disagree about decoration - they disagree about what the app
/// is. Soft and midnight lead with a list of promises; pastel leads with a
/// feeling; cosy leads with a photograph and three words. Rendering one
/// layout in four palettes would lose all of that, so each gets its own.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => switch (context.appSkin.welcome) {
    SkinWelcome.scene => const _WelcomeSoft(),
    SkinWelcome.bubbles => const _WelcomePastel(),
    SkinWelcome.photo => const _WelcomeCosy(),
    SkinWelcome.aurora => const _WelcomeMidnight(),
  };
}

class _WelcomeSoft extends StatelessWidget {
  const _WelcomeSoft();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const MorningScene(height: 190),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.welcomeTitleSoft,
            textAlign: TextAlign.center,
            style: context.text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.welcomeBodySoft,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _Features(),
        ],
      ),
    );
  }
}

class _WelcomePastel extends StatelessWidget {
  const _WelcomePastel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The last word carries the accent, as in the concept: on this design the
    // sentence is doing the work the illustration does elsewhere.
    final words = l10n.welcomeTitleLight.split(' ');
    final lead = words.take(words.length - 1).join(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const PastelScene(),
          const SizedBox(height: AppSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$lead '),
                TextSpan(
                  text: words.last,
                  style: TextStyle(color: context.colors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: context.text.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.welcomeBodyLight,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCosy extends StatelessWidget {
  const _WelcomeCosy();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Type in the top third, over the darkest part of the scrim. The picture
    // owns the rest of the screen; nothing is centred on top of the cup.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              RelyaMark(size: 30),
              SizedBox(width: AppSpacing.sm),
              RelyaWordmark(fontSize: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.welcomeTitleCalm,
            style: context.text.displaySmall?.copyWith(
              color: Colors.white,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.welcomeBodyLight,
            style: context.text.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeMidnight extends StatelessWidget {
  const _WelcomeMidnight();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          const RelyaMark(size: 84),
          const SizedBox(height: AppSpacing.lg),
          const RelyaWordmark(fontSize: 40),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.welcomeTaglineAi,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _Features(compact: true),
        ],
      ),
    );
  }
}

/// The three promises. Two designs show them; the icon tile carries the
/// accent so the row still reads when the body line is dropped.
class _Features extends StatelessWidget {
  const _Features({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _FeatureRow(
          icon: Icons.notifications_active_rounded,
          title: l10n.welcomeFeature1Title,
          body: compact ? null : l10n.welcomeFeature1Body,
        ),
        _FeatureRow(
          icon: Icons.check_circle_outline_rounded,
          title: l10n.welcomeFeature2Title,
          body: compact ? null : l10n.welcomeFeature2Body,
        ),
        _FeatureRow(
          icon: Icons.auto_awesome_rounded,
          title: l10n.welcomeFeature3Title,
          body: compact ? null : l10n.welcomeFeature3Body,
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(
                alpha: context.isDark ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(context.skin.cardRadius - 6),
            ),
            child: Icon(icon, size: 19, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The backdrop, chosen by the design and by which page is showing.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.hero, required this.child});

  final bool hero;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!hero) return OnboardingBackdrop(child: child);
    return switch (context.appSkin.welcome) {
      SkinWelcome.photo => CosyBackdrop(child: child),
      SkinWelcome.aurora => MidnightAurora(child: child),
      _ => OnboardingBackdrop(child: child),
    };
  }
}

class _Magic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingTitle3,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.onboardingBody3,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          const LiveDemo(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
