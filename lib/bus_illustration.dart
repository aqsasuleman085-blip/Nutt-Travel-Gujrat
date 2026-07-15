import 'package:flutter/material.dart';

/// A hand-drawn style bus illustration (no image assets needed - works
/// fully offline). Draws a simple but recognizable coach-bus silhouette
/// with windows, wheels, headlights, and "NUTT" painted on the side,
/// matching the app's emerald theme.
///
/// Used on the splash screen (a row of these) and can be reused anywhere
/// else a bus graphic is wanted.
class BusIllustration extends StatelessWidget {
  final double width;
  final double height;
  final Color busColor;
  final Color accentColor;

  const BusIllustration({
    super.key,
    this.width = 140,
    this.height = 80,
    this.busColor = Colors.white,
    this.accentColor = const Color(0xff10B981),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BusPainter(busColor: busColor, accentColor: accentColor),
      ),
    );
  }
}

class _BusPainter extends CustomPainter {
  final Color busColor;
  final Color accentColor;

  _BusPainter({required this.busColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = busColor;
    final accentPaint = Paint()..color = accentColor;
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.15);
    final windowPaint = Paint()..color = accentColor.withOpacity(0.55);

    // Bus body (rounded rectangle, slightly taller at the back)
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.02, h * 0.12, w * 0.90, h * 0.62),
      topLeft: Radius.circular(h * 0.12),
      topRight: Radius.circular(h * 0.22),
      bottomLeft: Radius.circular(h * 0.06),
      bottomRight: Radius.circular(h * 0.06),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Roof accent stripe
    final stripeRect = Rect.fromLTWH(w * 0.02, h * 0.12, w * 0.90, h * 0.09);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        stripeRect,
        topLeft: Radius.circular(h * 0.12),
        topRight: Radius.circular(h * 0.22),
      ),
      accentPaint,
    );

    // Windshield (front, right side - slanted)
    final windshield = Path()
      ..moveTo(w * 0.78, h * 0.24)
      ..lineTo(w * 0.90, h * 0.30)
      ..lineTo(w * 0.90, h * 0.50)
      ..lineTo(w * 0.78, h * 0.50)
      ..close();
    canvas.drawPath(windshield, windowPaint);

    // Passenger windows (three evenly spaced along the body)
    final windowWidth = w * 0.16;
    final windowHeight = h * 0.22;
    final windowY = h * 0.26;
    for (var i = 0; i < 3; i++) {
      final windowX = w * 0.08 + i * (windowWidth + w * 0.04);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(windowX, windowY, windowWidth, windowHeight),
          Radius.circular(h * 0.04),
        ),
        windowPaint,
      );
    }

    // "NUTT" text on the lower body/side panel
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'NUTT',
        style: TextStyle(
          color: accentColor,
          fontSize: h * 0.16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(w * 0.08, h * 0.58 - textPainter.height / 2),
    );

    // Headlight
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.62),
      h * 0.045,
      Paint()..color = Colors.amber.shade300,
    );

    // Bumper / undercarriage shadow line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.72, w, h * 0.06),
        Radius.circular(h * 0.02),
      ),
      darkPaint,
    );

    // Wheels
    final wheelRadius = h * 0.14;
    final wheelY = h * 0.80;
    _drawWheel(canvas, Offset(w * 0.22, wheelY), wheelRadius);
    _drawWheel(canvas, Offset(w * 0.74, wheelY), wheelRadius);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = Colors.black87);
    canvas.drawCircle(center, radius * 0.5, Paint()..color = Colors.grey.shade300);
  }

  @override
  bool shouldRepaint(covariant _BusPainter oldDelegate) {
    return oldDelegate.busColor != busColor ||
        oldDelegate.accentColor != accentColor;
  }
}
