import 'package:flutter/material.dart';

import '../../../shared/domain/life_item.dart';
import '../../../shared/domain/life_item_type.dart';
import 'concept.dart';
import 'kit_a.dart';
import 'kit_d.dart';
import 'kit_e.dart';
import 'kit_f.dart';

/// The vocabulary every screen speaks, implemented once per design.
///
/// This is the layer that stops four themes from being one theme in four
/// colours. A row, a card, a badge and a section label are not the same shape
/// in the four concepts - one tints rows by category, one puts them on a flat
/// dark surface with a hairline, one gives them a serif label above - so the
/// screens ask the kit for a row rather than building one.
///
/// Screens still own their own layout. Where the concepts arrange a screen
/// differently, they get four views; where they arrange it the same way and
/// only the parts differ, one view asking the kit is the honest answer.
abstract class ConceptKit {
  const ConceptKit();

  static ConceptKit of(BuildContext context) => switch (context.concept) {
    Concept.a => const KitA(),
    Concept.d => const KitD(),
    Concept.e => const KitE(),
    Concept.f => const KitF(),
  };

  /// Whatever sits behind every screen in this design: glows, a wash, a
  /// scatter of pastel shapes, or nothing at all.
  Widget page(BuildContext context, {required Widget child});

  /// A surface with this design's shape, border and elevation.
  Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? tint,
    VoidCallback? onTap,
    String? semanticLabel,
  });

  /// One item in a list. The single most repeated shape in the app.
  Widget row(
    BuildContext context, {
    required LifeItem item,
    required DateTime now,
    VoidCallback? onTap,
  });

  /// The label that opens a run of rows.
  Widget sectionHeader(
    BuildContext context, {
    required String title,
    int? count,
    VoidCallback? onSeeAll,
  });

  /// A small status pill: "3 days left", "Done".
  Widget badge(
    BuildContext context, {
    required String label,
    required Color tone,
  });

  /// The icon for a kind of item, in its coloured container.
  Widget glyph(
    BuildContext context, {
    required LifeItemType type,
    double size = 40,
  });

  /// The wide call to action at the bottom of a screen.
  Widget primaryButton(
    BuildContext context, {
    required String label,
    VoidCallback? onTap,
    IconData? icon,
  });

  /// A tappable suggestion in the assistant.
  Widget suggestion(
    BuildContext context, {
    required String label,
    IconData? icon,
    VoidCallback? onTap,
  });

  /// Nothing here yet, and what to do about it.
  Widget empty(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  });

  /// The largest type on a screen. Serif in exactly one design.
  TextStyle display(BuildContext context);

  /// Screen and card headings.
  TextStyle heading(BuildContext context);

  /// How far the content sits from the edge, and how far apart rows sit.
  /// Density is part of a design: the pastel one breathes, the AI one packs.
  double get gutter;

  double get rowGap;
}

extension ConceptKitX on BuildContext {
  ConceptKit get kit => ConceptKit.of(this);
}
