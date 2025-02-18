// lib/o2_saturation/painters/o2_data_point_drawer.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';

class O2DataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    O2SaturationChartStyle style,
    Animation<double> animation,
    ProcessedO2SaturationData? selectedData,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    final xStep = chartArea.width / (data.length - 1);

    // Draw trend lines first
    _drawTrendLines(
      canvas,
      chartArea,
      data,
      xStep,
      style,
      animation,
      minValue,
      maxValue,
    );

    // Draw individual data points
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final o2Y = _getYPosition(entry.avgValue, chartArea, minValue, maxValue);
      final o2Position = Offset(x, o2Y);

      final isSelected = entry == selectedData;

      if (isSelected) {
        _drawSelectionHighlight(canvas, x, chartArea, style);
      }

      // Draw O2 saturation point
      _drawPoint(
        canvas,
        o2Position,
        style.primaryColor,
        style,
        animation,
        isSelected,
      );

      // Draw min-max range if multiple readings
      if (entry.dataPointCount > 1) {
        _drawRange(
          canvas,
          x,
          entry,
          chartArea,
          style,
          animation,
          minValue,
          maxValue,
        );
      }

      // Draw pulse rate point if available
      if (entry.avgPulseRate != null) {
        final pulseY = _getYPosition(
          entry.avgPulseRate!,
          chartArea,
          minValue,
          maxValue,
        );
        final pulsePosition = Offset(x, pulseY);

        _drawPoint(
          canvas,
          pulsePosition,
          style.pulseRateColor,
          style,
          animation,
          isSelected,
        );
      }

      // Draw reading count badge if multiple readings
      if (entry.dataPointCount > 1) {
        _drawReadingCount(
          canvas,
          o2Position,
          entry.dataPointCount,
          style,
          animation,
        );
      }
    }
  }

  void _drawTrendLines(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    double xStep,
    O2SaturationChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    if (data.length < 2) return;

    final o2Path = Path();
    final pulsePath = Path();
    var isFirstValidPoint = true;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final entry = data[i];

      final o2Y = _getYPosition(
        entry.avgValue,
        chartArea,
        minValue,
        maxValue,
      );

      if (isFirstValidPoint) {
        o2Path.moveTo(x, o2Y);
        if (entry.avgPulseRate != null) {
          final pulseY = _getYPosition(
            entry.avgPulseRate!,
            chartArea,
            minValue,
            maxValue,
          );
          pulsePath.moveTo(x, pulseY);
        }
        isFirstValidPoint = false;
      } else {
        o2Path.lineTo(x, o2Y);
        if (entry.avgPulseRate != null) {
          final pulseY = _getYPosition(
            entry.avgPulseRate!,
            chartArea,
            minValue,
            maxValue,
          );
          pulsePath.lineTo(x, pulseY);
        }
      }
    }

    final trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineThickness;

    // Draw O2 trend line
    trendPaint.color =
        style.primaryColor.withValues(alpha: 0.3 * animation.value);
    canvas.drawPath(o2Path, trendPaint);

    // Draw pulse rate trend line
    trendPaint.color =
        style.pulseRateColor.withValues(alpha: 0.3 * animation.value);
    canvas.drawPath(pulsePath, trendPaint);
  }

  void _drawRange(
    Canvas canvas,
    double x,
    ProcessedO2SaturationData data,
    Rect chartArea,
    O2SaturationChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    final maxY =
        _getYPosition(data.maxValue.toDouble(), chartArea, minValue, maxValue);
    final minY =
        _getYPosition(data.minValue.toDouble(), chartArea, minValue, maxValue);

    final rangePaint = Paint()
      ..color = style.primaryColor.withValues(alpha: 0.2 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, maxY),
      Offset(x, minY),
      rangePaint,
    );
  }

  void _drawPoint(
    Canvas canvas,
    Offset position,
    Color color,
    O2SaturationChartStyle style,
    Animation<double> animation,
    bool isSelected,
  ) {
    if (isSelected) {
      _dataPointPaint
        ..style = PaintingStyle.fill
        ..color = style.selectedHighlightColor;
      canvas.drawCircle(position, style.pointRadius * 2, _dataPointPaint);
    }

    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: animation.value);
    canvas.drawCircle(
      position,
      style.pointRadius,
      _dataPointPaint,
    );

    _dataPointPaint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: animation.value)
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      position,
      style.pointRadius,
      _dataPointPaint,
    );
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    O2SaturationChartStyle style,
  ) {
    final paint = Paint()
      ..color = style.selectedHighlightColor.withValues(alpha: 0.2)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      paint,
    );
  }

  void _drawReadingCount(
    Canvas canvas,
    Offset position,
    int count,
    O2SaturationChartStyle style,
    Animation<double> animation,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRadius = max(textPainter.width, textPainter.height) * 0.7;
    final badgeCenter = Offset(
      position.dx + style.pointRadius * 2,
      position.dy - style.pointRadius * 2,
    );

    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = style.primaryColor.withValues(alpha: animation.value);
    canvas.drawCircle(badgeCenter, badgeRadius, _dataPointPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  double _getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
