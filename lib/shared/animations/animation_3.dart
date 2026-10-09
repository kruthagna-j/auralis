import 'dart:math';
import 'package:flutter/material.dart';

class Animation3 extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final bool isAnimating;

  const Animation3({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    required this.isAnimating,
  }) : super(key: key);

  @override
  _Animation3State createState() => _Animation3State();
}

class _Animation3State extends State<Animation3>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Animation3 oldWidget) {
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
            painter: _LayeredWavePainter(
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

class _LayeredWavePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color accentColor;

  _LayeredWavePainter({
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

    _drawWave(
      canvas,
      w,
      h,
      t,
      baseY: 0.58,
      amplitude: 28.0,
      frequency: 1.2,
      phaseShift: 0.0,
      secondaryAmp: 12.0,
      secondaryFreq: 2.5,
      opacity: 0.20,
    );

    _drawWave(
      canvas,
      w,
      h,
      t,
      baseY: 0.52,
      amplitude: 22.0,
      frequency: 1.5,
      phaseShift: pi * 0.7,
      secondaryAmp: 8.0,
      secondaryFreq: 3.0,
      opacity: 0.30,
    );

    _drawWave(
      canvas,
      w,
      h,
      t,
      baseY: 0.48,
      amplitude: 16.0,
      frequency: 1.8,
      phaseShift: pi * 1.3,
      secondaryAmp: 6.0,
      secondaryFreq: 3.5,
      opacity: 0.40,
    );
  }

  void _drawWave(
    Canvas canvas,
    double w,
    double h,
    double t, {
    required double baseY,
    required double amplitude,
    required double frequency,
    required double phaseShift,
    required double secondaryAmp,
    required double secondaryFreq,
    required double opacity,
  }) {
    final path = Path();
    final yBase = h * baseY;
    const step = 4.0;

    path.moveTo(
      0,
      yBase +
          _waveY(
            0,
            w,
            t,
            amplitude,
            frequency,
            phaseShift,
            secondaryAmp,
            secondaryFreq,
          ),
    );

    for (double x = step; x <= w; x += step) {
      path.lineTo(
        x,
        yBase +
            _waveY(
              x,
              w,
              t,
              amplitude,
              frequency,
              phaseShift,
              secondaryAmp,
              secondaryFreq,
            ),
      );
    }

    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: opacity),
              accentColor.withValues(alpha: opacity * 0.25),
            ],
          ).createShader(
            Rect.fromLTWH(0, yBase - amplitude, w, h - yBase + amplitude),
          );

    canvas.drawPath(path, paint);
  }

  double _waveY(
    double x,
    double w,
    double t,
    double amp,
    double freq,
    double phase,
    double secAmp,
    double secFreq,
  ) {
    return sin((x / w * freq * 2 * pi) + t + phase) * amp +
        sin((x / w * secFreq * 2 * pi) + t * 1.3 + phase * 0.7) * secAmp;
  }

  @override
  bool shouldRepaint(_LayeredWavePainter old) {
    return old.progress != progress ||
        old.backgroundColor != backgroundColor ||
        old.accentColor != accentColor;
  }
}
