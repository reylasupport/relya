import 'package:flutter/material.dart';

import 'brand.dart';

/// The brand gradient. Cool primary into warm violet, on a diagonal.
///
/// One gradient, used for the mark, the wordmark and nothing else. The moment
/// it starts appearing on buttons and cards it stops being an identity and
/// becomes decoration.
const LinearGradient brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Brand.seedColor, Brand.accentColor],
);

/// The logo mark: a squircle badge holding a single stroke that sweeps in and
/// resolves into a tick, with a spark above it.
///
/// It is drawn rather than shipped as an image so it is crisp at every size,
/// costs nothing in bundle weight, and can be recoloured for a mono context
/// without a second asset.
class RelyaMark extends StatelessWidget {
  const RelyaMark({
    super.key,
    this.size = 44,
    this.gradient = brandGradient,
    this.foreground = Colors.white,
    this.background,
  });

  final double size;
  final Gradient gradient;
  final Color foreground;

  /// Flat colour instead of the gradient, for a mono or inverted lockup.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarkPainter(
          gradient: background == null ? gradient : null,
          flat: background,
          foreground: foreground,
        ),
        isComplex: true,
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.gradient,
    required this.flat,
    required this.foreground,
  });

  final Gradient? gradient;
  final Color? flat;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size(s, s);

    // A superellipse, not a rounded rectangle: it is the shape both platforms
    // use for app icons, and the difference is visible at icon scale.
    final squircle = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.255));

    canvas.drawRRect(
      squircle,
      Paint()
        ..isAntiAlias = true
        ..shader = gradient?.createShader(rect)
        ..color = flat ?? const Color(0xFF000000),
    );

    // A soft diagonal sheen so the badge has some life at large sizes and
    // disappears politely at 24px.
    canvas.save();
    canvas.clipRRect(squircle);
    canvas.drawCircle(
      Offset(s * 0.18, s * 0.10),
      s * 0.62,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(s * 0.18, s * 0.10),
                radius: s * 0.62,
              ),
            ),
    );
    canvas.restore();

    final stroke = Paint()
      ..isAntiAlias = true
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.093
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The mark itself: a tick whose tail keeps rising, so it reads as
    // "settled" rather than as a plain checkbox.
    final path = Path()
      ..moveTo(s * 0.243, s * 0.520)
      ..lineTo(s * 0.415, s * 0.690)
      ..lineTo(s * 0.702, s * 0.372);

    canvas.drawPath(path, stroke);

    // The spark: what the app found that you had not noticed.
    canvas.drawCircle(
      Offset(s * 0.793, s * 0.236),
      s * 0.052,
      Paint()
        ..isAntiAlias = true
        ..color = foreground,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.gradient != gradient ||
      old.flat != flat ||
      old.foreground != foreground;
}

/// The name, in the brand gradient. Used on the splash, the sign-in screen
/// and the first onboarding slide.
class RelyaWordmark extends StatelessWidget {
  const RelyaWordmark({super.key, this.fontSize = 34, this.color});

  final double fontSize;

  /// Overrides the gradient with a flat colour, for places where a gradient
  /// would fight with the background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      Brand.appName,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -fontSize * 0.028,
        height: 1.05,
        color: color ?? Colors.white,
      ),
    );

    if (color != null) return text;

    return ShaderMask(
      shaderCallback: (bounds) => brandGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: text,
    );
  }
}

/// Mark and name side by side, the way the app introduces itself.
class RelyaLockup extends StatelessWidget {
  const RelyaLockup({super.key, this.markSize = 40, this.fontSize = 28});

  final double markSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Brand.appName,
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RelyaMark(size: markSize),
            SizedBox(width: markSize * 0.32),
            RelyaWordmark(fontSize: fontSize),
          ],
        ),
      ),
    );
  }
}
