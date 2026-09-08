import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relya/core/branding/relya_logo.dart';

/// Renders the launcher icons from the same painter the app uses.
///
///     flutter test tool/generate_brand_assets.dart
///
/// Keeping the icon as code rather than as a hand-drawn PNG means the badge on
/// the home screen and the badge inside the app can never drift apart, and a
/// rebrand is one colour change rather than a trip through a design tool.
Future<void> render({
  required WidgetTester tester,
  required Widget child,
  required double size,
  required String path,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(width: size, height: size, child: child),
        ),
      ),
    ),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    // Freeing the handle matters: an undisposed image keeps the test binding
    // waiting and the run never finishes.
    image.dispose();

    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote $path (${file.lengthSync()} bytes)');
  });
}

void main() {
  // Two cases rather than one: each gets a fresh binding, and toImage is only
  // called once per test, which is where the pipeline is happiest.
  testWidgets('full-bleed icon', (tester) async {
    tester.view.physicalSize = const Size(1100, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await render(
      tester: tester,
      child: const RelyaMark(size: 1024),
      size: 1024,
      path: 'assets/brand/icon.png',
    );
  });

  testWidgets('android adaptive foreground', (tester) async {
    tester.view.physicalSize = const Size(1100, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The launcher masks and animates this layer, so the badge shape is
    // dropped and the glyph is inset into the safe zone.
    await render(
      tester: tester,
      child: const Center(
        child: RelyaMark(size: 620, background: Color(0x00000000)),
      ),
      size: 1024,
      path: 'assets/brand/icon_foreground.png',
    );
  });
}
