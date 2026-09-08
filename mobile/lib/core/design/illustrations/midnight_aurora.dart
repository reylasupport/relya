import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';

/// The backdrop of the poster theme: a dome of light behind the mark, a few
/// concentric arcs, and a scatter of small stars.
///
/// It is the technological answer to the cosy theme's photograph - the same
/// job, opposite promise. Both fill the screen, so the welcome page is a
/// picture with type on it rather than type with a picture in it.
class MidnightAurora extends StatelessWidget {
  const MidnightAurora({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _AuroraPainter(
              accent: context.colors.primary,
              secondary: context.colors.secondary,
              ground: context.colors.surface,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.accent,
    required this.secondary,
    required this.ground,
  });

  final Color accent;
  final Color secondary;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w / 2, h * 0.34);

    canvas.drawRect(Offset.zero & size, Paint()..color = ground);

    // The dome. Two blurred discs rather than a gradient, so the light has a
    // soft edge instead of a mathematical one.
    canvas.drawCircle(
      centre,
      w * 0.60,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.30)
        ..color = accent.withValues(alpha: 0.30),
    );
    canvas.drawCircle(
      centre.translate(w * 0.18, -h * 0.06),
      w * 0.30,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.22)
        ..color = secondary.withValues(alpha: 0.26),
    );

    // Concentric arcs, fading outwards.
    for (var i = 0; i < 4; i++) {
      final r = w * (0.34 + i * 0.16);
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        math.pi * 0.06,
        math.pi * 0.88,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = accent.withValues(alpha: 0.26 - i * 0.055),
      );
    }

    // Stars. Deterministic, so the screen looks the same every time it opens.
    final random = math.Random(7);
    for (var i = 0; i < 34; i++) {
      final x = random.nextDouble() * w;
      final y = random.nextDouble() * h;
      final d = (Offset(x, y) - centre).distance / (w * 0.9);
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.3 + 0.5,
        Paint()
          ..color = Colors.white.withValues(
            alpha: (0.30 - d * 0.18).clamp(0.05, 0.30),
          ),
      );
    }

    // Ground fade, so the list of features below sits on something calm.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ground.withValues(alpha: 0),
            ground.withValues(alpha: 0.55),
            ground.withValues(alpha: 0.95),
          ],
          stops: const [0.42, 0.68, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.accent != accent;
}
