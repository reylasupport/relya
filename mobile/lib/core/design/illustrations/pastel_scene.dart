import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';
import '../tokens/app_skin_style.dart';

/// The pastel welcome: a mug, a plant, and the things Relya swallows -
/// a calendar, a parcel, a message, a tick - orbiting it in soft bubbles.
///
/// Where the soft theme draws a quiet morning, this one draws the input. Same
/// promise, said in the register of that concept: friendlier, rounder, and
/// with everything in its own pastel circle.
class PastelScene extends StatelessWidget {
  const PastelScene({super.key, this.height = 230});

  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = context.skin.cardRadius;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _PastelPainter(
              accent: context.colors.primary,
              secondary: context.colors.secondary,
              ink: context.colors.onSurface,
              card: context.colors.surfaceContainerLowest,
              radius: radius,
            ),
          ),
          // The bubbles are real icons rather than paint: they have to be
          // recognisable at a glance, and a hand-drawn parcel is not.
          const _Bubble(
            icon: Icons.event_available_rounded,
            align: Alignment(-0.72, -0.62),
            size: 46,
            tone: 0,
          ),
          const _Bubble(
            icon: Icons.check_circle_rounded,
            align: Alignment(0.34, -0.86),
            size: 40,
            tone: 1,
          ),
          const _Bubble(
            icon: Icons.inventory_2_rounded,
            align: Alignment(0.86, -0.28),
            size: 50,
            tone: 2,
          ),
          const _Bubble(
            icon: Icons.chat_bubble_rounded,
            align: Alignment(-0.94, 0.18),
            size: 42,
            tone: 3,
          ),
          const _Bubble(
            icon: Icons.favorite_rounded,
            align: Alignment(0.72, 0.52),
            size: 36,
            tone: 4,
          ),
        ],
      ),
    );
  }
}

/// One floating icon. The tones are fixed rather than derived so the five
/// circles keep their spread on every theme instead of collapsing into one
/// hue when the accent changes.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.icon,
    required this.align,
    required this.size,
    required this.tone,
  });

  final IconData icon;
  final Alignment align;
  final double size;
  final int tone;

  static const _light = [
    (Color(0xFFEDE7FF), Color(0xFF6D4BD6)),
    (Color(0xFFDFF3E6), Color(0xFF2E7D5B)),
    (Color(0xFFFFE9D6), Color(0xFFC2610A)),
    (Color(0xFFDDEBFF), Color(0xFF2563C9)),
    (Color(0xFFFFE0E8), Color(0xFFD6456B)),
  ];

  @override
  Widget build(BuildContext context) {
    final pair = _light[tone % _light.length];
    final dark = context.isDark;
    final fill = dark ? Color.lerp(pair.$2, Colors.black, 0.62)! : pair.$1;
    final glyph = dark ? Color.lerp(pair.$2, Colors.white, 0.45)! : pair.$2;

    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: pair.$2.withValues(alpha: dark ? 0.28 : 0.16),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.44, color: glyph),
      ),
    );
  }
}

class _PastelPainter extends CustomPainter {
  _PastelPainter({
    required this.accent,
    required this.secondary,
    required this.ink,
    required this.card,
    required this.radius,
  });

  final Color accent;
  final Color secondary;
  final Color ink;
  final Color card;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.60),
        width: w * 0.62,
        height: h * 0.72,
      ),
      Paint()..color = accent.withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.04, h * 0.66),
        width: w * 0.40,
        height: h * 0.48,
      ),
      Paint()..color = secondary.withValues(alpha: 0.12),
    );

    // Plant, right of centre.
    final pot = Offset(cx + w * 0.13, h * 0.74);
    for (final a in [-0.8, -0.05, 0.72]) {
      canvas.save();
      canvas.translate(pot.dx, pot.dy - h * 0.02);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.11),
          width: w * 0.05,
          height: h * 0.21,
        ),
        Paint()..color = accent.withValues(alpha: 0.55),
      );
      canvas.restore();
    }
    canvas.drawPath(
      Path()
        ..moveTo(pot.dx - w * 0.055, pot.dy)
        ..lineTo(pot.dx + w * 0.055, pot.dy)
        ..lineTo(pot.dx + w * 0.040, pot.dy + h * 0.16)
        ..lineTo(pot.dx - w * 0.040, pot.dy + h * 0.16)
        ..close(),
      Paint()..color = secondary.withValues(alpha: 0.62),
    );

    // Mug, left of centre, with a saucer and two curls of steam.
    final mug = Rect.fromCenter(
      center: Offset(cx - w * 0.10, h * 0.76),
      width: w * 0.19,
      height: h * 0.20,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(mug.right + w * 0.012, mug.center.dy),
        radius: h * 0.055,
      ),
      -1.5708,
      3.1416,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.26),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        mug,
        topLeft: Radius.circular(w * 0.012),
        topRight: Radius.circular(w * 0.012),
        bottomLeft: Radius.circular(w * 0.055),
        bottomRight: Radius.circular(w * 0.055),
      ),
      Paint()..color = card,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        mug,
        topLeft: Radius.circular(w * 0.012),
        topRight: Radius.circular(w * 0.012),
        bottomLeft: Radius.circular(w * 0.055),
        bottomRight: Radius.circular(w * 0.055),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008
        ..color = ink.withValues(alpha: 0.26),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(mug.center.dx, mug.bottom + h * 0.022),
          width: w * 0.26,
          height: h * 0.024,
        ),
        Radius.circular(h * 0.012),
      ),
      Paint()..color = ink.withValues(alpha: 0.12),
    );
    final steam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.010
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: 0.22);
    for (var i = 0; i < 2; i++) {
      final x = mug.left + w * (0.055 + i * 0.075);
      canvas.drawPath(
        Path()
          ..moveTo(x, mug.top - h * 0.030)
          ..relativeCubicTo(
            -w * 0.030,
            -h * 0.042,
            w * 0.038,
            -h * 0.058,
            w * 0.004,
            -h * 0.108,
          ),
        steam,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PastelPainter old) => old.accent != accent;
}
