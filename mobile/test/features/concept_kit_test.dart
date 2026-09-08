import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/design/concept/concept.dart';
import 'package:relya/core/design/concept/concept_kit.dart';
import 'package:relya/core/design/concept/kit_a.dart';
import 'package:relya/core/design/concept/kit_d.dart';
import 'package:relya/core/design/concept/kit_e.dart';
import 'package:relya/core/design/concept/kit_f.dart';
import 'package:relya/core/design/theme/app_theme.dart';
import 'package:relya/core/design/tokens/app_skin.dart';

/// The whole point of the concept layer is that the four designs are four
/// designs. These tests fail the moment someone collapses them back into one.
void main() {
  test('every skin maps to its own concept', () {
    final concepts = AppSkin.values.map((s) => s.concept).toList();
    expect(concepts.toSet().length, 4);
    expect(AppSkin.midnight.concept, Concept.a);
    expect(AppSkin.soft.concept, Concept.d);
    expect(AppSkin.pastel.concept, Concept.e);
    expect(AppSkin.cosy.concept, Concept.f);
  });

  testWidgets('each concept resolves to its own kit', (tester) async {
    final kits = <Type>{};
    for (final skin in AppSkin.values) {
      late ConceptKit kit;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(skin),
          home: Builder(
            builder: (context) {
              kit = context.kit;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      kits.add(kit.runtimeType);
    }
    expect(kits, {KitA, KitD, KitE, KitF});
  });

  test('density is part of the design, not a constant', () {
    const kits = [KitA(), KitD(), KitE(), KitF()];
    final gutters = kits.map((k) => k.gutter).toSet();
    // Not all four have to differ, but they must not all agree: the AI
    // dashboard packs tighter than the pastel one on purpose.
    expect(gutters.length, greaterThan(1));
    expect(const KitA().gutter, lessThan(const KitE().gutter));
  });

  testWidgets('only the cosy design sets its headings in a serif', (
    tester,
  ) async {
    final families = <AppSkin, String?>{};
    for (final skin in AppSkin.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(skin),
          home: Builder(
            builder: (context) {
              families[skin] = context.kit.heading(context).fontFamily;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(families[AppSkin.cosy], 'Merriweather');
    for (final skin in AppSkin.values.where((s) => s != AppSkin.cosy)) {
      expect(families[skin], isNot('Merriweather'), reason: skin.wire);
    }
  });
}
