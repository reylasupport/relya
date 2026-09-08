import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';
import '../tokens/app_skin_style.dart';

/// The artwork in this app is drawn, not shipped.
///
/// Two reasons. A raster illustration has to exist four times over - light and
/// dark, warm and cool - or it sits on the surface like a sticker; these take
/// their colours from whichever theme is active, so they belong to it. And a
/// few hundred lines of paint weigh nothing next to four sets of PNGs.
///
/// Both scenes are drawn on a 320x220 grid and scale from there, so the
/// proportions hold at any size.
class MorningScene extends StatelessWidget {
  const MorningScene({super.key, this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MorningPainter(
          accent: context.colors.primary,
          secondary: context.colors.secondary,
          ink: context.colors.onSurface,
          muted: context.colors.onSurfaceVariant,
          card: context.colors.surfaceContainerLowest,
          radius: context.skin.cardRadius,
        ),
        isComplex: true,
      ),
    );
  }
}

class _MorningPainter extends CustomPainter {
  _MorningPainter({
    required this.accent,
    required this.secondary,
    required this.ink,
    required this.muted,
    required this.card,
    required this.radius,
  });

  final Color accent;
  final Color secondary;
  final Color ink;
  final Color muted;
  final Color card;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 220;
    final cx = size.width / 2;
    Offset p(double x, double y) => Offset(cx + (x - 160) * s, y * s);

    canvas.drawOval(
      Rect.fromCenter(center: p(160, 118), width: 250 * s, height: 175 * s),
      Paint()..color = accent.withValues(alpha: 0.10),
    );
    canvas.drawOval(
      Rect.fromCenter(center: p(160, 126), width: 176 * s, height: 124 * s),
      Paint()..color = secondary.withValues(alpha: 0.10),
    );

    _card(canvas, p(72, 44), 62 * s, 44 * s, s, tilt: -0.13);
    _card(canvas, p(250, 62), 56 * s, 40 * s, s, tilt: 0.15);

    final potTop = p(232, 150);
    final pot = Path()
      ..moveTo(potTop.dx - 21 * s, potTop.dy)
      ..lineTo(potTop.dx + 21 * s, potTop.dy)
      ..lineTo(potTop.dx + 15 * s, potTop.dy + 34 * s)
      ..lineTo(potTop.dx - 15 * s, potTop.dy + 34 * s)
      ..close();
    canvas.drawPath(pot, Paint()..color = secondary.withValues(alpha: 0.55));
    canvas.drawRect(
      Rect.fromLTWH(potTop.dx - 23 * s, potTop.dy - 6 * s, 46 * s, 8 * s),
      Paint()..color = secondary.withValues(alpha: 0.75),
    );
    final leaf = Paint()..color = accent.withValues(alpha: 0.62);
    for (final a in [-0.85, -0.1, 0.7]) {
      canvas.save();
      canvas.translate(potTop.dx, potTop.dy - 6 * s);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -22 * s),
          width: 17 * s,
          height: 42 * s,
        ),
        leaf,
      );
      canvas.restore();
    }

    final mug = Rect.fromLTWH(p(96, 132).dx, p(96, 132).dy, 74 * s, 52 * s);
    final mugShape = RRect.fromRectAndCorners(
      mug,
      bottomLeft: Radius.circular(20 * s),
      bottomRight: Radius.circular(20 * s),
      topLeft: Radius.circular(5 * s),
      topRight: Radius.circular(5 * s),
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(mug.right + 4 * s, mug.top + 22 * s),
        radius: 13 * s,
      ),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.30),
    );
    canvas.drawRRect(mugShape, Paint()..color = card);
    canvas.drawRRect(
      mugShape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..color = ink.withValues(alpha: 0.30),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          mug.left - 9 * s,
          mug.bottom + 2 * s,
          mug.width + 18 * s,
          6 * s,
        ),
        Radius.circular(3 * s),
      ),
      Paint()..color = ink.withValues(alpha: 0.14),
    );
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round
      ..color = muted.withValues(alpha: 0.55);
    for (var i = 0; i < 2; i++) {
      final x = mug.left + (24 + i * 26) * s;
      canvas.drawPath(
        Path()
          ..moveTo(x, mug.top - 8 * s)
          ..relativeCubicTo(-8 * s, -10 * s, 10 * s, -14 * s, 1 * s, -26 * s),
        steam,
      );
    }

    final tick = p(186, 84);
    canvas.drawCircle(tick, 15 * s, Paint()..color = accent);
    canvas.drawPath(
      Path()
        ..moveTo(tick.dx - 7 * s, tick.dy)
        ..lineTo(tick.dx - 2 * s, tick.dy + 6 * s)
        ..lineTo(tick.dx + 8 * s, tick.dy - 6 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  void _card(
    Canvas canvas,
    Offset centre,
    double w,
    double h,
    double s, {
    required double tilt,
  }) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(tilt);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(radius * 0.6 * s + 2),
    );
    canvas.drawRRect(r, Paint()..color = card);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * s
        ..color = ink.withValues(alpha: 0.12),
    );
    for (var i = 0; i < 3; i++) {
      final y = -h / 2 + (12 + i * 9) * s;
      final lineWidth = w - (16 + (i == 2 ? 18 : 0)) * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2 + 8 * s, y, lineWidth, 4 * s),
          Radius.circular(2 * s),
        ),
        Paint()
          ..color = (i == 0 ? accent : muted).withValues(
            alpha: i == 0 ? 0.75 : 0.35,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MorningPainter old) =>
      old.accent != accent || old.card != card || old.ink != ink;
}

/// An open box with two sheets and a leaf. The inbox, when there is nothing
/// in it - a state worth drawing rather than apologising for.
class EmptyInboxScene extends StatelessWidget {
  const EmptyInboxScene({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _InboxPainter(
          accent: context.colors.primary,
          secondary: context.colors.secondary,
          ink: context.colors.onSurface,
          muted: context.colors.onSurfaceVariant,
          card: context.colors.surfaceContainerLowest,
        ),
      ),
    );
  }
}

class _InboxPainter extends CustomPainter {
  _InboxPainter({
    required this.accent,
    required this.secondary,
    required this.ink,
    required this.muted,
    required this.card,
  });

  final Color accent;
  final Color secondary;
  final Color ink;
  final Color muted;
  final Color card;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 150;
    final cx = size.width / 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, 84 * s),
        width: 190 * s,
        height: 116 * s,
      ),
      Paint()..color = accent.withValues(alpha: 0.09),
    );

    canvas.save();
    canvas.translate(cx + 52 * s, 56 * s);
    canvas.rotate(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 15 * s, height: 34 * s),
      Paint()..color = accent.withValues(alpha: 0.55),
    );
    canvas.restore();

    for (final o in [(-26.0, -8.0, -0.12), (10.0, -14.0, 0.09)]) {
      canvas.save();
      canvas.translate(cx + o.$1 * s, (58 + o.$2) * s);
      canvas.rotate(o.$3);
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 46 * s, height: 58 * s),
        Radius.circular(5 * s),
      );
      canvas.drawRRect(r, Paint()..color = card);
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * s
          ..color = ink.withValues(alpha: 0.14),
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-15 * s, (-18 + i * 10) * s, 30 * s, 3.4 * s),
            Radius.circular(2 * s),
          ),
          Paint()..color = muted.withValues(alpha: 0.34),
        );
      }
      canvas.restore();
    }

    final body = Path()
      ..moveTo(cx - 62 * s, 84 * s)
      ..lineTo(cx + 62 * s, 84 * s)
      ..lineTo(cx + 50 * s, 124 * s)
      ..lineTo(cx - 50 * s, 124 * s)
      ..close();
    canvas.drawPath(body, Paint()..color = secondary.withValues(alpha: 0.55));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 68 * s, 76 * s, 136 * s, 14 * s),
        Radius.circular(4 * s),
      ),
      Paint()..color = secondary.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _InboxPainter old) =>
      old.accent != accent || old.card != card;
}
