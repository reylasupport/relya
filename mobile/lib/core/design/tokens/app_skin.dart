import 'package:flutter/material.dart';

/// A whole visual character, not just an accent colour.
///
/// The four skins come from four design directions, and each one owns its own
/// surfaces, accent and shape language. Two are warm, two are cool; two read
/// best light, two read best dark - but every skin defines both, because a
/// phone that flips to dark at sunset must not turn the app into something
/// nobody designed.
enum AppSkin {
  /// Warm off-white paper, deep indigo. Calm and neutral: the default.
  soft('soft'),

  /// Lavender whites and tinted rows. Friendlier, more colourful, rounder.
  pastel('pastel'),

  /// Cream and warm near-black with a sage accent. Earthy and quiet.
  cosy('cosy'),

  /// Deep navy-black and electric violet. Tighter corners, more contrast.
  midnight('midnight');

  const AppSkin(this.wire);

  final String wire;

  static AppSkin get fallback => AppSkin.soft;

  static AppSkin fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => fallback);

  SkinPalette palette(Brightness brightness) =>
      brightness == Brightness.light ? _light[this]! : _dark[this]!;

  /// The brightness the skin was drawn in. Used only to preview it honestly
  /// in the picker; the user's mode setting still wins.
  Brightness get nativeBrightness => switch (this) {
    AppSkin.soft || AppSkin.pastel => Brightness.light,
    AppSkin.cosy || AppSkin.midnight => Brightness.dark,
  };

  double get cardRadius => switch (this) {
    AppSkin.pastel => 20,
    AppSkin.cosy => 18,
    AppSkin.soft => 16,
    AppSkin.midnight => 14,
  };

  /// Whether list rows sit on a tinted card of their own colour. True only for
  /// pastel: on the other skins it would fight the accent instead of helping.
  bool get tintedRows => this == AppSkin.pastel;

  /// How strongly a category colour tints a surface behind it.
  double get tintStrength => switch (this) {
    AppSkin.pastel => 1.35,
    AppSkin.cosy => 0.85,
    AppSkin.midnight => 1.1,
    AppSkin.soft => 1.0,
  };
}

/// Every colour a skin needs. Semantic colours are deliberately absent: green
/// means done and red means overdue in all four, or the colour stops carrying
/// meaning the moment somebody switches theme.
@immutable
class SkinPalette {
  const SkinPalette({
    required this.accent,
    required this.accentText,
    required this.accentSecondary,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainer,
    required this.surfaceContainerHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.border,
    required this.borderStrong,
  });

  /// The primary. Also the first stop of the brand gradient in this skin.
  ///
  /// A fill colour: the capture button, the gradient, the tint behind a
  /// selected row. Not a text colour - see [accentText].
  final Color accent;

  /// The accent when it has to be read rather than filled.
  ///
  /// Every skin's accent was chosen against a white card as a block of colour,
  /// and every one of them failed as type: measured as text they came out
  /// between 2.70:1 and 4.40:1, on the surfaces their own skin puts behind
  /// them and on their own 14-24% tint. That covers every link, the selected
  /// segment of a toggle and the assistant's suggestion chips. Each value here
  /// is the same hue moved just far enough to clear 4.5:1 on all of them.
  final Color accentText;

  /// The second gradient stop. Chosen per skin so the logo and the capture
  /// button belong to the theme rather than sitting on top of it.
  final Color accentSecondary;

  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainer;
  final Color surfaceContainerHighest;
  final Color onSurface;
  final Color onSurfaceVariant;

  /// Quiet separation: dividers, and the edge of a card that is already told
  /// apart by its fill. Deliberately faint, and deliberately not used for
  /// anything a person has to find.
  final Color border;

  /// The outline of a control whose boundary is the only thing identifying it
  /// - an outlined button, a text field.
  ///
  /// It exists because [border] cannot do both jobs. At the weight the flat
  /// look wants, a divider is fine and a text field is a rumour: measured
  /// against its own surface, [border] came out between 1.15:1 and 1.50:1,
  /// with `elevation: 0` and a fill only 1.04:1 to 1.11:1 off the page behind
  /// it, so the field had no visible edge at all. Every value here is the
  /// lowest alpha of the same hue that clears the 3:1 WCAG 1.4.11 asks of a
  /// control boundary, on every surface the skin can put behind it. Lowest,
  /// because a border should be findable, not loud.
  final Color borderStrong;

  Gradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSecondary],
  );
}

const Map<AppSkin, SkinPalette> _light = {
  // Warm paper. The neutral is not grey: a hint of yellow in the surface is
  // what stops a white app looking like a spreadsheet.
  AppSkin.soft: SkinPalette(
    accent: Color(0xFF5B5BD6),
    accentText: Color(0xFF4949AB),
    accentSecondary: Color(0xFF8B5CF6),
    surface: Color(0xFFF6F4F1),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFEDEAE5),
    onSurface: Color(0xFF1B1A18),
    // A shade down from 6E6A64, which measured 4.48:1 on a raised chip - near
    // enough to AA to look fine and still fail it.
    onSurfaceVariant: Color(0xFF6D6963),
    border: Color(0x14000000),
    borderStrong: Color(0x6D000000),
  ),
  AppSkin.pastel: SkinPalette(
    accent: Color(0xFF7C5CFF),
    accentText: Color(0xFF5C44BD),
    accentSecondary: Color(0xFFB07CFF),
    surface: Color(0xFFFBF9FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFF1EDFB),
    onSurface: Color(0xFF2A2340),
    // Was 7A7392, which came out at 4.28:1 on the page and 3.89:1 on a chip.
    // This is the lavender pushed down just far enough to clear AA on every
    // surface pastel can put behind it, because this colour carries the dates
    // and the amounts - the data the app exists to show.
    onSurfaceVariant: Color(0xFF6F6985),
    border: Color(0x14382A6B),
    borderStrong: Color(0x89382A6B),
  ),
  AppSkin.cosy: SkinPalette(
    accent: Color(0xFF4E7A62),
    accentText: Color(0xFF3B5C4A),
    accentSecondary: Color(0xFF7FA98C),
    surface: Color(0xFFF5F1EA),
    surfaceContainerLowest: Color(0xFFFFFDF9),
    surfaceContainer: Color(0xFFFFFDF9),
    surfaceContainerHighest: Color(0xFFEBE5DA),
    onSurface: Color(0xFF211E19),
    onSurfaceVariant: Color(0xFF6B655A),
    border: Color(0x1A3A3226),
    borderStrong: Color(0x8C3A3226),
  ),
  AppSkin.midnight: SkinPalette(
    accent: Color(0xFF4C6FFF),
    accentText: Color(0xFF3750B8),
    accentSecondary: Color(0xFF8A5CF6),
    surface: Color(0xFFF4F6FB),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFE9EDF6),
    onSurface: Color(0xFF101322),
    onSurfaceVariant: Color(0xFF626A85),
    border: Color(0x141A2340),
    borderStrong: Color(0x7F1A2340),
  ),
};

const Map<AppSkin, SkinPalette> _dark = {
  AppSkin.soft: SkinPalette(
    accent: Color(0xFF9B99FF),
    accentText: Color(0xFFADABFF),
    accentSecondary: Color(0xFFC4A0FF),
    surface: Color(0xFF17161A),
    surfaceContainerLowest: Color(0xFF1B1A20),
    surfaceContainer: Color(0xFF201F25),
    surfaceContainerHighest: Color(0xFF2A2830),
    onSurface: Color(0xFFF2F1EF),
    onSurfaceVariant: Color(0xFFA09CA6),
    border: Color(0x1FFFFFFF),
    borderStrong: Color(0x57FFFFFF),
  ),
  AppSkin.pastel: SkinPalette(
    accent: Color(0xFFB49BFF),
    accentText: Color(0xFFBCA6FF),
    accentSecondary: Color(0xFFE0A6F5),
    surface: Color(0xFF14121C),
    surfaceContainerLowest: Color(0xFF1A1725),
    surfaceContainer: Color(0xFF1E1B2A),
    surfaceContainerHighest: Color(0xFF282437),
    onSurface: Color(0xFFF3F0FA),
    onSurfaceVariant: Color(0xFFA9A2C0),
    border: Color(0x24FFFFFF),
    borderStrong: Color(0x56FFFFFF),
  ),
  // The warm near-black is the point of this one: pure grey would make the
  // sage accent look sickly instead of calm.
  AppSkin.cosy: SkinPalette(
    accent: Color(0xFF8FBFA3),
    accentText: Color(0xFF92C1A6),
    accentSecondary: Color(0xFFC8B98F),
    surface: Color(0xFF14120F),
    surfaceContainerLowest: Color(0xFF1A1713),
    surfaceContainer: Color(0xFF1F1C17),
    surfaceContainerHighest: Color(0xFF2A2620),
    onSurface: Color(0xFFF0EBE3),
    onSurfaceVariant: Color(0xFFA39B8E),
    border: Color(0x1FE8DCC8),
    borderStrong: Color(0x66E8DCC8),
  ),
  AppSkin.midnight: SkinPalette(
    accent: Color(0xFF7C8CFF),
    accentText: Color(0xFF94A1FF),
    accentSecondary: Color(0xFFB07CFF),
    surface: Color(0xFF0A0C14),
    surfaceContainerLowest: Color(0xFF11141F),
    surfaceContainer: Color(0xFF141826),
    surfaceContainerHighest: Color(0xFF1C2133),
    onSurface: Color(0xFFEDF0F8),
    onSurfaceVariant: Color(0xFF8E97B4),
    border: Color(0x1F9FB0E0),
    borderStrong: Color(0x839FB0E0),
  ),
};

/// Where the capture button lives, and how many destinations flank it.
///
/// This is the single most recognisable difference between the four designs,
/// which is why it belongs to the skin and not to the shell.
enum SkinNav {
  /// A circle floating above a five-destination bar.
  docked,

  /// A circle sunk into the middle of the bar, two destinations either side.
  /// Inbox moves to the header bell, where its badge is still visible.
  centre,
}

/// What sits at the top of Home.
enum SkinHero {
  /// The single next thing, on a card tinted with its own category colour.
  focus,

  /// The same card, warmer and larger, with the item's own artwork block.
  highlight,

  /// A gradient poster that counts the week, over a four-number grid.
  poster,
}

/// How a list announces a new section.
enum SkinSectionStyle {
  /// `Hoje` and a `Ver todos` link.
  linkAll,

  /// `Hoje` and the number of rows beneath it.
  count,

  /// `HOJE` and the number of rows beneath it.
  upperCount,

  /// `A seguir`, and nothing else.
  plain,
}

/// What fills the first screen anyone sees.
enum SkinWelcome {
  /// A drawn morning - cup, plant, two captured cards - over the wash.
  scene,

  /// The same idea with the inputs orbiting it in pastel bubbles.
  bubbles,

  /// A full-bleed painted photograph, with the type over the scrim.
  photo,

  /// A full-bleed dome of light and stars behind the mark.
  aurora,
}

/// The parts of the layout that change with the theme.
///
/// A skin here is a design, not a palette: the four concepts differ in where
/// the capture button sits and what the top of Home is, and swapping only the
/// colours would produce four screens that all look like the same one.
extension AppSkinLayout on AppSkin {
  SkinNav get nav => switch (this) {
    AppSkin.pastel => SkinNav.centre,
    _ => SkinNav.docked,
  };

  SkinHero get hero => switch (this) {
    AppSkin.pastel => SkinHero.highlight,
    AppSkin.midnight => SkinHero.poster,
    _ => SkinHero.focus,
  };

  SkinSectionStyle get sectionStyle => switch (this) {
    AppSkin.soft => SkinSectionStyle.linkAll,
    AppSkin.pastel => SkinSectionStyle.count,
    AppSkin.cosy => SkinSectionStyle.upperCount,
    AppSkin.midnight => SkinSectionStyle.plain,
  };

  /// The assistant field under the greeting. Absent where the concept gives
  /// the space to something else: the counts in pastel, the poster in
  /// midnight.
  bool get showAskBar => this == AppSkin.soft || this == AppSkin.cosy;

  /// Today / upcoming / this week / done, as four tappable numbers.
  bool get showStatsGrid => this == AppSkin.midnight;

  /// A second line under the greeting, and what it says.
  SkinGreetingSubtitle get greetingSubtitle => switch (this) {
    AppSkin.soft => SkinGreetingSubtitle.date,
    AppSkin.pastel => SkinGreetingSubtitle.tagline,
    _ => SkinGreetingSubtitle.none,
  };

  /// The inbox, reachable from the header. Always true for the centre-button
  /// skin, which has no inbox destination in the bar.
  bool get headerBell => nav == SkinNav.centre || this == AppSkin.cosy;

  /// A shape behind the selected destination, not just a colour.
  bool get navIndicator => this == AppSkin.midnight;

  /// The welcome screen. All four differ, and a test keeps them differing:
  /// this is the screen where the concepts disagree most about what the
  /// product is, and flattening it would flatten the whole theme.
  SkinWelcome get welcome => switch (this) {
    AppSkin.soft => SkinWelcome.scene,
    AppSkin.pastel => SkinWelcome.bubbles,
    AppSkin.cosy => SkinWelcome.photo,
    AppSkin.midnight => SkinWelcome.aurora,
  };

  /// Whether the welcome art fills the screen behind the type.
  bool get welcomeIsFullBleed =>
      welcome == SkinWelcome.photo || welcome == SkinWelcome.aurora;

  /// Upcoming opens on the agenda rather than the plain list.
  bool get upcomingStartsOnAgenda => this == AppSkin.midnight;
}

enum SkinGreetingSubtitle { none, date, tagline }
