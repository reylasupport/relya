import 'package:flutter/material.dart';

import '../tokens/app_skin.dart';
import '../tokens/app_skin_style.dart';

/// The four designs, by the letter they were drawn under.
///
/// A skin used to be a palette. It is now a whole design: its own background,
/// its own card shape, its own typography, its own icons, and in most places
/// its own screen layout. The palette lives in [AppSkin]; everything above the
/// palette hangs off this.
///
/// The wire values in [AppSkin] are what is persisted, so they keep their
/// original names. This enum is the one people should read.
enum Concept {
  /// Dark AI premium. Navy-black, indigo to violet, glows, dashboards.
  a,

  /// Clean mainstream. Near-white, one soft indigo, very conventional.
  d,

  /// Friendly pastel. Illustrated, colourful, rounded, cheerful.
  e,

  /// Cozy lifestyle dark. Warm black, serif headings, photography.
  f;

  bool get isDarkByNature => this == Concept.a || this == Concept.f;

  /// The letter, for logs and documentation.
  String get letter => switch (this) {
    Concept.a => 'A',
    Concept.d => 'D',
    Concept.e => 'E',
    Concept.f => 'F',
  };
}

/// The editorial serif of Concept F.
///
/// Bundled rather than resolved through the platform 'serif' family: that
/// family is not guaranteed to exist on every device, and a heading font that
/// fails to resolve renders as a row of empty boxes rather than degrading.
/// Merriweather is SIL Open Font License 1.1; the licence ships beside the
/// files in assets/fonts/merriweather/.
const String kSerifFamily = 'Merriweather';

/// A floor, for the rare glyph Merriweather lacks.
const List<String> kSerifFallback = <String>['serif', 'Noto Serif', 'Georgia'];

/// The heading voice of a concept, applied to any base style.
///
/// Only F changes family. The others keep the system face, because a second
/// typeface that is not doing editorial work is just noise.
TextStyle conceptHeading(Concept concept, TextStyle base) {
  if (concept != Concept.f) return base;
  return base.copyWith(
    fontFamily: kSerifFamily,
    fontFamilyFallback: kSerifFallback,
    // Merriweather ships Light and Regular. Asking for a heavier weight makes
    // the engine synthesise a fake bold, which on a serif looks like a fault.
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
}

extension ConceptOfSkin on AppSkin {
  Concept get concept => switch (this) {
    AppSkin.midnight => Concept.a,
    AppSkin.soft => Concept.d,
    AppSkin.pastel => Concept.e,
    AppSkin.cosy => Concept.f,
  };
}

extension ConceptOfContext on BuildContext {
  Concept get concept => appSkin.concept;
}
