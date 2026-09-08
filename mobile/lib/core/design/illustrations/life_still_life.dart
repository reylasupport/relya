import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';

/// A cup, two books and a plant, beside the Life heading.
///
/// Decoration with a job: the pastel concept promises warmth, and a heading
/// with nothing beside it promises a settings page. It is small, it never
/// overlaps the title, and it takes its colours from the theme like every
/// other drawing in the app.
class LifeStillLife extends StatelessWidget {
  const LifeStillLife({super.key, this.height = 74});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 1.5,
      height: height,
      child: CustomPaint(
        painter: _StillLifePainter(
          accent: context.colors.primary,
          secondary: context.colors.secondary,
          ink: context.colors.onSurface,
          card: context.colors.surfaceContainerLowest,
          dark: context.isDark,
        ),
      ),
    );
  }
}

class _StillLifePainter extends CustomPainter {
  _StillLifePainter({
    required this.accent,
    required this.secondary,
    required this.ink,
    required this.card,
    required this.dark,
  });

  final Color accent;
  final Color secondary;
  final Color ink;
  final Color card;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Two books, lying flat, as the plinth for everything else.
    final shelf = h * 0.86;
    for (var i = 0; i < 2; i++) {
      final y = shelf - i * h * 0.10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * (0.06 + i * 0.05),
            y - h * 0.09,
            w * (0.52 - i * 0.08),
            h * 0.09,
          ),
          Radius.circular(h * 0.03),
        ),
        Paint()
          ..color = (i == 0 ? secondary : accent).withValues(
            alpha: dark ? 0.55 : 0.42,
          ),
      );
    }

    // The plant, standing on the books.
    final pot = Offset(w * 0.26, shelf - h * 0.19);
    for (final a in [-0.7, 0.0, 0.7]) {
      canvas.save();
      canvas.translate(pot.dx, pot.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -h * 0.22),
          width: w * 0.075,
          height: h * 0.34,
        ),
        Paint()..color = accent.withValues(alpha: dark ? 0.70 : 0.58),
      );
      canvas.restore();
    }
    canvas.drawPath(
      Path()
        ..moveTo(pot.dx - w * 0.08, pot.dy)
        ..lineTo(pot.dx + w * 0.08, pot.dy)
        ..lineTo(pot.dx + w * 0.055, pot.dy + h * 0.19)
        ..lineTo(pot.dx - w * 0.055, pot.dy + h * 0.19)
        ..close(),
      Paint()..color = secondary.withValues(alpha: dark ? 0.80 : 0.66),
    );

    // The cup, to the right, with a saucer and a curl of steam.
    final cup = Rect.fromLTWH(w * 0.60, shelf - h * 0.32, w * 0.26, h * 0.24);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cup.right + w * 0.015, cup.center.dy),
        radius: h * 0.07,
      ),
      -1.5708,
      3.1416,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.035
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.30),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cup,
        topLeft: Radius.circular(h * 0.02),
        topRight: Radius.circular(h * 0.02),
        bottomLeft: Radius.circular(h * 0.10),
        bottomRight: Radius.circular(h * 0.10),
      ),
      Paint()..color = card,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cup,
        topLeft: Radius.circular(h * 0.02),
        topRight: Radius.circular(h * 0.02),
        bottomLeft: Radius.circular(h * 0.10),
        bottomRight: Radius.circular(h * 0.10),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.022
        ..color = ink.withValues(alpha: 0.30),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cup.center.dx, cup.bottom + h * 0.035),
          width: w * 0.34,
          height: h * 0.04,
        ),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = ink.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cup.center.dx, cup.top - h * 0.05)
        ..relativeCubicTo(
          -w * 0.04,
          -h * 0.07,
          w * 0.05,
          -h * 0.09,
          w * 0.005,
          -h * 0.17,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.028
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(covariant _StillLifePainter old) => old.accent != accent;
}
