import 'dart:math';
import 'package:flutter/material.dart';

class Animation4 extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimating;

  const Animation4({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    required this.isAnimating,
  }) : super(key: key);

  @override
  _Animation4State createState() => _Animation4State();
}

class _Animation4State extends State<Animation4>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Animation4 oldWidget) {
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
            painter: _RipplePainter(
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

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  static const int _ringCount = 4;

  _RipplePainter({
    required this.progress,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.6;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _ringCount; i++) {
      final ringProgress = (progress + i / _ringCount) % 1.0;
      final radius = ringProgress * maxRadius;

      double opacity;
      if (ringProgress < 0.15) {
        opacity = ringProgress / 0.15;
      } else if (ringProgress < 0.5) {
        opacity = 1.0;
      } else {
        opacity = (1.0 - ringProgress) / 0.5;
      }
      opacity = (opacity * 0.45).clamp(0.0, 1.0);
      if (opacity < 0.02) continue;

      ringPaint
        ..color = accentColor.withValues(alpha: opacity)
        ..strokeWidth = 2.5 * (1.0 - ringProgress * 0.6);
      canvas.drawCircle(center, radius, ringPaint);
    }

    final pulseT = progress * 2 * pi;
    final pulseSize = 5.0 + 3.0 * sin(pulseT);
    final pulseOpacity = (0.5 + 0.3 * sin(pulseT)).clamp(0.0, 1.0);
    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseSize, dotPaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.22),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 30));
    canvas.drawCircle(center, 30, glowPaint);

    _drawOrbitDots(canvas, center, maxRadius * 0.5, progress, pulseT);
  }

  void _drawOrbitDots(
    Canvas canvas,
    Offset center,
    double orbitRadius,
    double t,
    double tRad,
  ) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const dotCount = 8;
    final baseAngle = t * 2 * pi;

    for (int i = 0; i < dotCount; i++) {
      final a = baseAngle + (i / dotCount) * 2 * pi;
      final dist = orbitRadius * (0.8 + 0.2 * sin(tRad * 2 + i));
      final x = center.dx + cos(a) * dist;
      final y = center.dy + sin(a) * dist;

      final dotOpacity = (0.3 + 0.3 * sin(tRad * 3 + i * 1.5)).clamp(0.0, 1.0);
      final dotSize = 1.5 + 0.8 * sin(tRad * 2 + i * 0.8);

      dotPaint.color = accentColor.withValues(alpha: dotOpacity);
      canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) {
    return old.progress != progress ||
        old.backgroundColor != backgroundColor ||
        old.accentColor != accentColor;
  }
}
