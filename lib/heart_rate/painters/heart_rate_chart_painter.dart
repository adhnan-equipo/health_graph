// lib/painters/heart_rate_chart_painter.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/date_formatter.dart';
import '../models/heart_rate_chart_config.dart';
import '../models/processed_heart_rate_data.dart';
import '../styles/heart_rate_chart_style.dart';

class HeartRateChartPainter extends CustomPainter {
  final List<ProcessedHeartRateData> data;
  final HeartRateChartStyle style;
  final HeartRateChartConfig config;
  final Animation<double> animation;
  final ProcessedHeartRateData? selectedData;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  static const rangeDefinitions = [
    (180.0, 300.0, 'Hypertensive Crisis', Color(0xFFE53E3E)), // Red
    (140.0, 180.0, 'Stage 2 Hypertension', Color(0xFFF6AD55)), // Orange
    (130.0, 140.0, 'Stage 1 Hypertension', Color(0xFFFBD38D)), // Light Orange
    (120.0, 130.0, 'Elevated', Color(0xFFFAF089)), // Yellow
    (90.0, 120.0, 'Normal', Color(0xFF48BB78)), // Green
    (0.0, 90.0, 'Low', Color(0xFF3182CE)), // Blue
  ];

  HeartRateChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
    this.selectedData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    _drawBackground(canvas);
    _drawZones(canvas);
    if (config.showGrid) {
      _drawGrid(canvas);
    }
    _drawHeartRateLine(canvas);
    if (config.showLabels) {
      _drawAxisLabels(canvas);
    }
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(
      chartArea,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _drawZones(Canvas canvas) {
    // Draw range backgrounds within chart bounds
    for (var range in rangeDefinitions) {
      final rangeTop = _getYPosition(range.$2.clamp(minValue, maxValue));
      final rangeBottom = _getYPosition(range.$1.clamp(minValue, maxValue));

      // Draw range background
      canvas.drawRect(
        Rect.fromLTRB(chartArea.left, rangeTop, chartArea.right, rangeBottom),
        Paint()..color = range.$4.withValues(alpha: 0.1),
      );

      // Check if any data points fall within this range
      final hasDataInRange = data.any((d) =>
          !d.isEmpty && d.avgValue >= range.$1 && d.avgValue <= range.$2);

      if (hasDataInRange) {
        // Create centered label
        final labelRect = Rect.fromLTRB(
          chartArea.left,
          rangeTop,
          chartArea.right,
          rangeBottom,
        );

        _drawRangeLabel(
          canvas,
          labelRect,
          range.$3,
          range.$4,
        );
      }
    }
  }

  void _drawHeartRateLine(Canvas canvas) {
    if (data.isEmpty) return;

    final validPoints = _getValidPoints();
    if (validPoints.isEmpty) return;

    // Draw area under the line
    final areaPath = Path();
    areaPath.moveTo(validPoints.first.dx, chartArea.bottom);

    // Create smooth line path
    final linePath = Path();
    linePath.moveTo(validPoints.first.dx, validPoints.first.dy);

    for (var i = 0; i < validPoints.length; i++) {
      if (i == 0) {
        areaPath.lineTo(validPoints[i].dx, validPoints[i].dy);
      } else {
        final previous = validPoints[i - 1];
        final current = validPoints[i];

        if (_isPointConnected(previous, current)) {
          // Calculate control points for smooth curve
          final controlPoint1 = Offset(
            previous.dx + (current.dx - previous.dx) / 3,
            previous.dy,
          );
          final controlPoint2 = Offset(
            previous.dx + (current.dx - previous.dx) * 2 / 3,
            current.dy,
          );

          linePath.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            current.dx,
            current.dy,
          );

          areaPath.cubicTo(
            controlPoint1.dx,
            controlPoint1.dy,
            controlPoint2.dx,
            controlPoint2.dy,
            current.dx,
            current.dy,
          );
        } else {
          areaPath.lineTo(previous.dx, chartArea.bottom);
          areaPath.moveTo(current.dx, chartArea.bottom);
          areaPath.lineTo(current.dx, current.dy);

          linePath.moveTo(current.dx, current.dy);
        }
      }
    }

    areaPath.lineTo(validPoints.last.dx, chartArea.bottom);
    areaPath.close();

    // Draw area with gradient
    final gradient = ui.Gradient.linear(
      Offset(0, chartArea.top),
      Offset(0, chartArea.bottom),
      [
        style.primaryColor.withValues(alpha: 0.15),
        style.primaryColor.withValues(alpha: 0.02),
      ],
    );

    canvas.drawPath(
      areaPath,
      Paint()..shader = gradient,
    );

    // Draw the line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = style.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Draw points
    for (var point in validPoints) {
      // White outline
      canvas.drawCircle(
        point,
        4.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Colored center
      canvas.drawCircle(
        point,
        3.5,
        Paint()
          ..color = style.primaryColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines with values
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines
    final xStep = chartArea.width / 6; // 6 vertical divisions
    for (var i = 0; i <= 6; i++) {
      final x = chartArea.left + (i * xStep);
      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        gridPaint,
      );
    }
  }

  List<Offset> _getValidPoints() {
    final points = <Offset>[];
    if (data.length <= 1) return points;

    final xStep = chartArea.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      if (!data[i].isEmpty) {
        final x = chartArea.left + (i * xStep);
        final y = _getYPosition(data[i].avgValue);
        points.add(Offset(x, y));
      }
    }

    return points;
  }

  bool _isPointConnected(Offset point1, Offset point2) {
    // Consider points connected if they're not too far apart
    final maxGap = chartArea.width / (data.length - 1) * 1.5;
    return (point2.dx - point1.dx).abs() <= maxGap;
  }

  Path _createAnimatedPath(Path path, double progress) {
    final metrics = path.computeMetrics();
    final animatedPath = Path();

    for (final metric in metrics) {
      final length = metric.length;
      animatedPath.addPath(
        metric.extractPath(0, length * progress),
        Offset.zero,
      );
    }

    return animatedPath;
  }

  void _drawRangeLabel(Canvas canvas, Rect rect, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Calculate centered position
    final bgWidth = textPainter.width + 16;
    final bgHeight = textPainter.height + 8;
    final bgLeft = chartArea.left + (chartArea.width - bgWidth) / 2;
    final bgTop = rect.center.dy - bgHeight / 2;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(bgLeft, bgTop, bgWidth, bgHeight),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Draw text centered
    textPainter.paint(
      canvas,
      Offset(
        bgLeft + 8,
        bgTop + 4,
      ),
    );
  }

  void _drawAxisLabels(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Y-axis labels
    for (var value in yAxisValues) {
      textPainter
        ..text = TextSpan(
          text: value.toString(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        )
        ..layout();

      textPainter.paint(
        canvas,
        Offset(
          chartArea.left - textPainter.width - 8,
          _getYPosition(value.toDouble()) - textPainter.height / 2,
        ),
      );
    }

    // X-axis labels using HeartRateDateFormatter
    final labelIndices = _calculateLabelIndices();
    for (var i in labelIndices) {
      if (i >= data.length) continue;

      final x = chartArea.left + (i * chartArea.width / (data.length - 1));
      final label = DateFormatter.format(
        data[i].startDate,
        config.viewType,
      );

      textPainter
        ..text = TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        )
        ..layout();

      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          chartArea.bottom + 8,
        ),
      );
    }
  }

  List<int> _calculateLabelIndices() {
    if (data.length <= 1) return [0];
    if (data.length <= 7) return List.generate(data.length, (i) => i);

    final step = (data.length / 6).ceil();
    final indices = <int>[];

    for (var i = 0; i < data.length; i += step) {
      indices.add(i);
    }

    if (!indices.contains(data.length - 1)) {
      indices.add(data.length - 1);
    }

    return indices;
  }

  double _getYPosition(double value) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  @override
  bool shouldRepaint(covariant HeartRateChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        style != oldDelegate.style ||
        config != oldDelegate.config ||
        animation != oldDelegate.animation ||
        selectedData != oldDelegate.selectedData ||
        chartArea != oldDelegate.chartArea ||
        yAxisValues != oldDelegate.yAxisValues ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
