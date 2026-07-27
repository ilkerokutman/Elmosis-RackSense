import 'package:flutter/material.dart';
import 'package:rack_sense/app/data/models/temperature_sample.dart';

class TemperatureHistoryChart extends StatelessWidget {
  const TemperatureHistoryChart({
    super.key,
    required this.samples,
    required this.from,
    required this.until,
  });

  final List<TemperatureSample> samples;
  final DateTime from;
  final DateTime until;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return const Center(child: Text('Bu aralıkta kayıtlı veri yok'));
    }
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _TemperatureChartPainter(
        samples: samples,
        from: from,
        until: until,
        gridColor: scheme.outlineVariant,
        temperatureColor: scheme.primary,
        targetColor: scheme.tertiary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  const _TemperatureChartPainter({
    required this.samples,
    required this.from,
    required this.until,
    required this.gridColor,
    required this.temperatureColor,
    required this.targetColor,
  });

  final List<TemperatureSample> samples;
  final DateTime from;
  final DateTime until;
  final Color gridColor;
  final Color temperatureColor;
  final Color targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const top = 12.0;
    const right = 12.0;
    const bottom = 26.0;
    final bounds = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    if (bounds.width <= 0 || bounds.height <= 0) return;

    final values = [
      ...samples.map((sample) => sample.temperature.toDouble()),
      ...samples.map((sample) => sample.targetTemperature.toDouble()),
    ];
    final minimum = values.reduce((a, b) => a < b ? a : b).floor() - 1;
    final maximum = values.reduce((a, b) => a > b ? a : b).ceil() + 1;
    final span = (maximum - minimum)
        .toDouble()
        .clamp(2, double.infinity)
        .toDouble();
    _drawGrid(canvas, bounds, minimum, maximum);
    _drawLine(
      canvas,
      bounds,
      (sample) => sample.temperature,
      minimum,
      span,
      temperatureColor,
    );
    _drawLine(
      canvas,
      bounds,
      (sample) => sample.targetTemperature,
      minimum,
      span,
      targetColor,
    );
  }

  void _drawGrid(Canvas canvas, Rect bounds, int minimum, int maximum) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = bounds.top + bounds.height * index / 4;
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        gridPaint,
      );
      final value = maximum - (maximum - minimum) * index / 4;
      _drawLabel(canvas, '${value.toStringAsFixed(0)}°', Offset(2, y - 7));
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect bounds,
    int Function(TemperatureSample) valueOf,
    int minimum,
    double span,
    Color color,
  ) {
    final path = Path();
    final totalMilliseconds = until.difference(from).inMilliseconds;
    final gapThreshold = const Duration(minutes: 2).inMilliseconds;
    DateTime? previousAt;
    for (final sample in samples) {
      final elapsed = sample.recordedAt.difference(from).inMilliseconds;
      final x = bounds.left + bounds.width * elapsed / totalMilliseconds;
      final y =
          bounds.bottom - bounds.height * (valueOf(sample) - minimum) / span;
      if (previousAt == null ||
          sample.recordedAt.difference(previousAt).inMilliseconds >
              gapThreshold) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      previousAt = sample.recordedAt;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawLabel(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: gridColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TemperatureChartPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.from != from ||
      oldDelegate.until != until ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.temperatureColor != temperatureColor ||
      oldDelegate.targetColor != targetColor;
}
