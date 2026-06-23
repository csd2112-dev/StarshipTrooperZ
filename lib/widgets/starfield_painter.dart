import 'dart:math';
import 'package:flutter/material.dart';

class StarData {
  final double x;      // 0.0–1.0 normalized
  final double y;      // 0.0–1.0 normalized
  final double speed;  // parallax multiplier
  final double size;
  final double opacity;
  const StarData({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

List<StarData> generateStars(int count, {int seed = 0}) {
  final rng = Random(seed);
  return List.generate(
    count,
    (_) => StarData(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      speed: 0.015 + rng.nextDouble() * 0.06,
      size: 0.4 + rng.nextDouble() * 1.8,
      opacity: 0.25 + rng.nextDouble() * 0.75,
    ),
  );
}

class StarfieldPainter extends CustomPainter {
  final List<StarData> stars;
  final double offset; // animation progress 0.0–1.0, loops

  const StarfieldPainter({required this.stars, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep-space gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000012), Color(0xFF00091E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle nebula blobs
    _drawNebula(canvas, size, const Offset(0.25, 0.35), const Color(0xFF001A4D), 140);
    _drawNebula(canvas, size, const Offset(0.75, 0.65), const Color(0xFF1A0033), 110);

    // Stars with parallax scroll
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final y = (star.y + offset * star.speed) % 1.0;
      starPaint.color = Color.fromRGBO(220, 235, 255, star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, y * size.height),
        star.size,
        starPaint,
      );
    }
  }

  void _drawNebula(Canvas canvas, Size size, Offset center, Color color, double radius) {
    final paint = Paint()
      ..color = color.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(center.dx * size.width, center.dy * size.height),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.offset != offset;
}
