import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../data/services/equalizer_services.dart';

class EqualizerCurveGraph extends StatefulWidget {
  final EqualizerParameters params;
  final Color accentColor;
  final bool isDarkMode;
  final bool isEnabled;
  final ValueChanged<MapEntry<int, double>>? onBandChanged;

  const EqualizerCurveGraph({
    Key? key,
    required this.params,
    required this.accentColor,
    required this.isDarkMode,
    required this.isEnabled,
    this.onBandChanged,
  }) : super(key: key);

  @override
  State<EqualizerCurveGraph> createState() => _EqualizerCurveGraphState();
}

class _EqualizerCurveGraphState extends State<EqualizerCurveGraph> {
  void _handleTouch(Offset localPosition, Size size) {
    if (!widget.isEnabled || widget.onBandChanged == null) return;
    final bands = widget.params.bands;
    if (bands.isEmpty || size.width <= 0 || size.height <= 0) return;

    final bandCount = bands.length;
    final step = bandCount > 1 ? size.width / (bandCount - 1) : size.width;
    final rawIndex = step == 0 ? 0 : (localPosition.dx / step).round();
    final index = rawIndex.clamp(0, bandCount - 1);

    final clampedY = localPosition.dy.clamp(0.0, size.height);
    final normalized = 1.0 - (clampedY / size.height);
    final gain =
        widget.params.minDecibels +
        (widget.params.maxDecibels - widget.params.minDecibels) * normalized;

    widget.onBandChanged!(
      MapEntry(
        index,
        gain.clamp(widget.params.minDecibels, widget.params.maxDecibels),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingMd),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTouch(details.localPosition, size),
              onPanStart: (details) =>
                  _handleTouch(details.localPosition, size),
              onPanUpdate: (details) =>
                  _handleTouch(details.localPosition, size),
              child: CustomPaint(
                painter: _CurvePainter(
                  params: widget.params,
                  accentColor: widget.accentColor,
                  isEnabled: widget.isEnabled,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final EqualizerParameters params;
  final Color accentColor;
  final bool isEnabled;

  _CurvePainter({
    required this.params,
    required this.accentColor,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (params.bands.isEmpty) return;

    final effectiveAccent = isEnabled ? accentColor : Colors.grey;

    final paint = Paint()
      ..color = effectiveAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          effectiveAccent.withValues(alpha: 0.5),
          effectiveAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final bands = params.bands;
    final n = bands.length;

    double getY(double gain) {
      final normalized =
          (gain - params.minDecibels) /
          (params.maxDecibels - params.minDecibels);
      return size.height * (1.0 - normalized);
    }

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = (size.width / (n - 1)) * i;
      final y = getY(bands[i].gain);
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(0, size.height); // Start fill at bottom-left
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];

        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
        fillPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }

      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);

      for (final p in points) {
        final linePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              effectiveAccent.withValues(alpha: 0.85),
              effectiveAccent.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(p.dx, p.dy, 1, size.height - p.dy))
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(p.dx, p.dy),
          Offset(p.dx, size.height),
          linePaint,
        );
      }

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final dotStrokePaint = Paint()
        ..color = effectiveAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final p in points) {
        canvas.drawCircle(p, 5, dotPaint);
        canvas.drawCircle(p, 5, dotStrokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => true;
}
