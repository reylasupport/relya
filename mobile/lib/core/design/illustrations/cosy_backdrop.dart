import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The cosy theme opens on a photograph, not on an illustration.
///
/// It is painted rather than shipped, for the same reason as the other scenes:
/// a JPEG would have to exist twice for light and dark, would weigh a
/// megabyte, and would be the one surface in the app that ignores the theme.
/// Blur does most of the work - a soft warm key light, an out-of-focus plant
/// and a vignette are what make a handful of shapes read as a photograph
/// rather than as clip art.
class CosyBackdrop extends StatelessWidget {
  const CosyBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _CosyPainter())),
        // The scrim. Text sits in the top third, so the darkening does too.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF14120F).withValues(alpha: 0.88),
                  const Color(0xFF14120F).withValues(alpha: 0.50),
                  const Color(0xFF14120F).withValues(alpha: 0.10),
                  const Color(0xFF14120F).withValues(alpha: 0.74),
                ],
                stops: const [0, 0.32, 0.60, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CosyPainter extends CustomPainter {
  const _CosyPainter();

  static const _night = Color(0xFF14120F);
  static const _warm = Color(0xFF6B5236);
  static const _cream = Color(0xFFD9C9AE);
  static const _sage = Color(0xFF4E6B52);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0D0B), Color(0xFF241C14), Color(0xFF16120E)],
          stops: [0, 0.62, 1],
        ).createShader(Offset.zero & size),
    );

    // Window light from the upper right. Everything else is lit by this.
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.30),
      w * 0.62,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.22)
        ..color = _warm.withValues(alpha: 0.55),
    );

    _plant(canvas, w, h);
    _blanket(canvas, w, h);
    _mug(canvas, w, h);

    // Vignette, painted last so it darkens everything equally.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, 0.35),
          radius: 0.95,
          colors: [
            _night.withValues(alpha: 0),
            _night.withValues(alpha: 0.30),
            _night.withValues(alpha: 0.80),
          ],
          stops: const [0.45, 0.75, 1],
        ).createShader(Offset.zero & size),
    );
  }

  /// Out of focus, behind the cup. Heavy blur is what puts it there.
  void _plant(Canvas canvas, double w, double h) {
    final base = Offset(w * 0.80, h * 0.60);
    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035)
      ..color = _sage.withValues(alpha: 0.50);
    for (final a in [-1.15, -0.62, -0.05, 0.55, 1.05]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.10),
          width: w * 0.10,
          height: h * 0.20,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: base.translate(0, h * 0.055),
          width: w * 0.20,
          height: h * 0.11,
        ),
        Radius.circular(w * 0.03),
      ),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.03)
        ..color = const Color(0xFF7A6247).withValues(alpha: 0.75),
    );
  }

  /// The knit. Rows of overlapping arcs, softened, so it reads as texture
  /// rather than as a pattern.
  void _blanket(Canvas canvas, double w, double h) {
    final top = h * 0.52;
    final area = Rect.fromLTWH(0, top, w, h - top);
    // Painted into its own layer so the top edge can be dissolved away. A
    // clip alone leaves a horizon line across the middle of the photograph,
    // which is the single thing that stops it reading as one.
    canvas.saveLayer(area, Paint());
    canvas.clipRect(area);
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, h - top),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _cream.withValues(alpha: 0.20),
            _cream.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, top, w, h - top)),
    );

    final stitch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.006)
      ..color = _cream.withValues(alpha: 0.13);
    final step = w * 0.085;
    for (var y = top + step * 0.4; y < h; y += step * 0.62) {
      for (var x = -step; x < w + step; x += step) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(x, y),
            width: step,
            height: step * 0.8,
          ),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          stitch,
        );
      }
    }

    canvas.drawRect(
      area,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
          stops: [0, 0.34],
        ).createShader(area),
    );
    canvas.restore();
  }

  /// The cup. Shadow, saucer, handle, body, the dark disc of coffee, a rim
  /// highlight and two curls of steam. Drawn in that order because that is
  /// the order they occlude each other.
  void _mug(Canvas canvas, double w, double h) {
    final cx = w * 0.46;
    final cy = h * 0.745;
    final r = w * 0.20;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.92),
        width: r * 3.5,
        height: r * 0.9,
      ),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05)
        ..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.78),
        width: r * 3.0,
        height: r * 0.78,
      ),
      Paint()..color = const Color(0xFFCBB99B).withValues(alpha: 0.92),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.72),
        width: r * 2.3,
        height: r * 0.56,
      ),
      Paint()..color = const Color(0xFFA8967A).withValues(alpha: 0.9),
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + r * 1.02, cy), radius: r * 0.44),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.17
        ..color = const Color(0xFFD8C7A9),
    );

    final body = Path()
      ..moveTo(cx - r, cy - r * 0.55)
      ..lineTo(cx - r * 0.86, cy + r * 0.52)
      ..quadraticBezierTo(cx, cy + r * 1.05, cx + r * 0.86, cy + r * 0.52)
      ..lineTo(cx + r, cy - r * 0.55)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFB6A587), Color(0xFFEADCC2), Color(0xFF9C8B70)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromLTWH(cx - r, cy - r, r * 2, r * 2)),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - r * 0.55),
        width: r * 2,
        height: r * 0.62,
      ),
      Paint()..color = const Color(0xFFF0E4CD),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - r * 0.53),
        width: r * 1.72,
        height: r * 0.48,
      ),
      Paint()..color = const Color(0xFF3A2415),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.30, cy - r * 0.60),
        width: r * 0.7,
        height: r * 0.18,
      ),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.10)
        ..color = const Color(0xFF8A6134).withValues(alpha: 0.75),
    );

    // Rim light down the right edge, where the window is, and a soft
    // occlusion on the left. Two strokes, and the cup stops being a sticker.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      Offset(cx + r * 1.10, cy + r * 0.10),
      r * 0.62,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.20)
        ..color = const Color(0xFFFFEAC6).withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(cx - r * 1.05, cy + r * 0.22),
      r * 0.70,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.24)
        ..color = const Color(0xFF2A1D11).withValues(alpha: 0.60),
    );
    canvas.restore();

    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.075
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.09)
      ..color = const Color(0xFFE8DAC0).withValues(alpha: 0.34);
    for (var i = 0; i < 2; i++) {
      final x = cx + (i == 0 ? -r * 0.32 : r * 0.24);
      canvas.drawPath(
        Path()
          ..moveTo(x, cy - r * 0.92)
          ..relativeCubicTo(
            -r * 0.24,
            -r * 0.34,
            r * 0.30,
            -r * 0.44,
            r * 0.04,
            -r * 0.86,
          ),
        steam,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosyPainter oldDelegate) => false;
}
