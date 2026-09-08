import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';

/// The little assistant of Concept E.
///
/// Friendly rather than futuristic: a rounded head, two soft eyes, an antenna
/// and a cheek blush. It exists because that concept promises warmth, and a
/// spark icon promises competence instead. The other three designs do not
/// draw it at all.
class RobotMascot extends StatelessWidget {
  const RobotMascot({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RobotPainter(
          body: context.colors.primary.withValues(
            alpha: context.isDark ? 0.34 : 0.20,
          ),
          ink: context.colors.primary,
          blush: context.colors.secondary,
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({required this.body, required this.ink, required this.blush});

  final Color body;
  final Color ink;
  final Color blush;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.12, s * 0.26, s * 0.76, s * 0.60),
      Radius.circular(s * 0.26),
    );

    // Antenna.
    canvas.drawLine(
      Offset(s * 0.5, s * 0.26),
      Offset(s * 0.5, s * 0.12),
      Paint()
        ..strokeWidth = s * 0.055
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.10),
      s * 0.085,
      Paint()..color = ink,
    );

    canvas.drawRRect(head, Paint()..color = body);
    canvas.drawRRect(
      head,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = ink.withValues(alpha: 0.55),
    );

    // Eyes, then a small smile between them.
    for (final dx in [0.34, 0.66]) {
      canvas.drawCircle(
        Offset(s * dx, s * 0.50),
        s * 0.075,
        Paint()..color = ink,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.56), radius: s * 0.14),
      0.5,
      2.15,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..strokeCap = StrokeCap.round
        ..color = ink.withValues(alpha: 0.8),
    );

    // Cheeks.
    for (final dx in [0.22, 0.78]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(s * dx, s * 0.63),
          width: s * 0.13,
          height: s * 0.08,
        ),
        Paint()..color = blush.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RobotPainter old) => old.ink != ink;
}
