import 'dart:math';
import 'package:flutter/material.dart';

class Animation1 extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimating;

  const Animation1({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    required this.isAnimating,
  }) : super(key: key);

  @override
  _Animation1State createState() => _Animation1State();
}

class _Animation1State extends State<Animation1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Animation1 oldWidget) {
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
            painter: _AuroraPainter(
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

class _AuroraPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  _AuroraPainter({
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
    final s = size.shortestSide;

    _drawBlob(
      canvas,
      w,
      h,
      s,
      t,
      cxBase: 0.50,
      cyBase: 0.35,
      cxAmp: 0.30,
      cyAmp: 0.25,
      cxFreq: 1.0,
      cyFreq: 0.7,
      phase: 0.0,
      radiusFactor: 0.55,
      opacity: 0.28,
    );

    _drawBlob(
      canvas,
      w,
      h,
      s,
      t,
      cxBase: 0.45,
      cyBase: 0.60,
      cxAmp: 0.25,
      cyAmp: 0.20,
      cxFreq: 0.8,
      cyFreq: 0.6,
      phase: 1.2,
      radiusFactor: 0.48,
      opacity: 0.22,
    );

    _drawBlob(
      canvas,
      w,
      h,
      s,
      t,
      cxBase: 0.55,
      cyBase: 0.50,
      cxAmp: 0.20,
      cyAmp: 0.30,
      cxFreq: 0.5,
      cyFreq: 0.9,
      phase: 2.5,
      radiusFactor: 0.42,
      opacity: 0.18,
    );

    _drawBlob(
      canvas,
      w,
      h,
      s,
      t,
      cxBase: 0.35,
      cyBase: 0.45,
      cxAmp: 0.15,
      cyAmp: 0.20,
      cxFreq: 0.6,
      cyFreq: 1.1,
      phase: 3.8,
      radiusFactor: 0.38,
      opacity: 0.15,
    );

    _drawBlob(
      canvas,
      w,
      h,
      s,
      t,
      cxBase: 0.65,
      cyBase: 0.40,
      cxAmp: 0.18,
      cyAmp: 0.15,
      cxFreq: 0.9,
      cyFreq: 0.5,
      phase: 5.0,
      radiusFactor: 0.35,
      opacity: 0.12,
    );
  }

  void _drawBlob(
    Canvas canvas,
    double w,
    double h,
    double s,
    double t, {
    required double cxBase,
    required double cyBase,
    required double cxAmp,
    required double cyAmp,
    required double cxFreq,
    required double cyFreq,
    required double phase,
    required double radiusFactor,
    required double opacity,
  }) {
    final cx = w * (cxBase + cxAmp * sin(t * cxFreq + phase));
    final cy = h * (cyBase + cyAmp * cos(t * cyFreq + phase * 1.3));
    final radius = s * radiusFactor;
    final center = Offset(cx, cy);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: opacity),
          accentColor.withValues(alpha: opacity * 0.35),
          backgroundColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) {
    return old.progress != progress ||
        old.backgroundColor != backgroundColor ||
        old.accentColor != accentColor;
  }
}
