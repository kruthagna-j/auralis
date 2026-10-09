import 'dart:math';
import 'package:flutter/material.dart';

class Animation2 extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimating;

  const Animation2({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    required this.isAnimating,
  }) : super(key: key);

  @override
  _Animation2State createState() => _Animation2State();
}

class _Animation2State extends State<Animation2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
    final random = Random(42);
    _particles = List.generate(25, (_) => _Particle(random));
  }

  @override
  void didUpdateWidget(covariant Animation2 oldWidget) {
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
            painter: _ConstellationPainter(
              particles: _particles,
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

class _Particle {
  final double centerX;
  final double centerY;
  final double amplitudeX;
  final double amplitudeY;
  final double phaseX;
  final double phaseY;
  final double radius;

  _Particle(Random r)
    : centerX = r.nextDouble() * 0.8 + 0.1,
      centerY = r.nextDouble() * 0.8 + 0.1,
      amplitudeX = r.nextDouble() * 0.12 + 0.03,
      amplitudeY = r.nextDouble() * 0.12 + 0.03,
      phaseX = r.nextDouble() * 2 * pi,
      phaseY = r.nextDouble() * 2 * pi,
      radius = r.nextDouble() * 2.0 + 1.0;

  Offset getPosition(double t) {
    return Offset(
      centerX + sin(t + phaseX) * amplitudeX,
      centerY + cos(t + phaseY) * amplitudeY,
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  static const double _connectionThreshold = 0.18;

  _ConstellationPainter({
    required this.particles,
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

    final positions = <Offset>[];
    for (final p in particles) {
      final rel = p.getPosition(t);
      positions.add(Offset(rel.dx * w, rel.dy * h));
    }

    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final thresholdPx = _connectionThreshold * size.shortestSide;
    final thresholdSq = thresholdPx * thresholdPx;

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dx = positions[i].dx - positions[j].dx;
        final dy = positions[i].dy - positions[j].dy;
        final distSq = dx * dx + dy * dy;
        if (distSq < thresholdSq) {
          final dist = sqrt(distSq);
          final opacity = (1.0 - dist / thresholdPx) * 0.35;
          linePaint.color = accentColor.withValues(alpha: opacity);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < particles.length; i++) {
      final pulse = 0.5 + 0.5 * sin(t * 2 + particles[i].phaseX);
      dotPaint.color = accentColor.withValues(alpha: pulse * 0.8);
      canvas.drawCircle(positions[i], particles[i].radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) {
    return old.progress != progress ||
        old.backgroundColor != backgroundColor ||
        old.accentColor != accentColor;
  }
}
