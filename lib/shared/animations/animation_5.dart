import 'dart:math';
import 'package:flutter/material.dart';

class Animation5 extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimating;

  const Animation5({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    required this.isAnimating,
  }) : super(key: key);

  @override
  _Animation5State createState() => _Animation5State();
}

class _Animation5State extends State<Animation5>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
    final random = Random(42);
    _stars = List.generate(50, (_) => _Star(random));
  }

  @override
  void didUpdateWidget(covariant Animation5 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _StarfieldPainter(
              stars: _stars,
              progress: _controller.value,
              backgroundColor: widget.backgroundColor,
              accentColor: widget.accentColor,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Star {
  final double x;
  final double startY;
  final double size;
  final double phase;
  final double twinkleSpeed;
  final int driftSpeed;

  _Star(Random r)
    : x = r.nextDouble(),
      startY = r.nextDouble(),
      size = r.nextDouble() * 2.0 + 0.5,
      phase = r.nextDouble() * 2 * pi,
      twinkleSpeed = r.nextDouble() * 2.0 + 1.0,
      driftSpeed = r.nextInt(3) + 1;

  double getY(double animValue) {
    return (startY + animValue * driftSpeed) % 1.0;
  }

  double getOpacity(double tRad) {
    return 0.15 + 0.70 * (0.5 + 0.5 * sin(tRad * twinkleSpeed + phase));
  }
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  _StarfieldPainter({
    required this.stars,
    required this.progress,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final t = progress * 2 * pi;
    final w = size.width;
    final h = size.height;

    _drawNebula(canvas, w, h, t);

    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final y = star.getY(progress);
      final opacity = star.getOpacity(t);
      final px = star.x * w;
      final py = y * h;

      starPaint.color = accentColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(px, py), star.size, starPaint);

      if (star.size > 1.8) {
        final glowOpacity = opacity * 0.25;
        final glowLen = star.size * 2.5;
        final glowPaint = Paint()
          ..color = accentColor.withValues(alpha: glowOpacity)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(px - glowLen, py),
          Offset(px + glowLen, py),
          glowPaint,
        );
        canvas.drawLine(
          Offset(px, py - glowLen),
          Offset(px, py + glowLen),
          glowPaint,
        );
      }
    }
  }

  void _drawNebula(Canvas canvas, double w, double h, double t) {
    final c1 = Offset(
      w * (0.3 + 0.1 * sin(t * 0.3)),
      h * (0.4 + 0.08 * cos(t * 0.25)),
    );
    final c2 = Offset(
      w * (0.7 + 0.08 * cos(t * 0.35)),
      h * (0.6 + 0.1 * sin(t * 0.2)),
    );

    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.06),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c1, radius: w * 0.35));
    canvas.drawCircle(c1, w * 0.35, nebulaPaint);

    nebulaPaint.shader = RadialGradient(
      colors: [
        accentColor.withValues(alpha: 0.04),
        accentColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: c2, radius: w * 0.3));
    canvas.drawCircle(c2, w * 0.3, nebulaPaint);
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) {
    return old.progress != progress ||
        old.backgroundColor != backgroundColor ||
        old.accentColor != accentColor;
  }
}
