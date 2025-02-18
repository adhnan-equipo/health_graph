// lib/bmi/drawer/bmi_data_point_drawer.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';

class BMIDataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBMIData> data,
    BMIChartStyle style,
    Animation<double> animation,
    ProcessedBMIData? selectedData,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    final xStep = chartArea.width / (data.length - 1);

    // Draw trend line first
    _drawTrendLine(
      canvas,
      chartArea,
      data,
      xStep,
      style,
      animation,
      minValue,
      maxValue,
    );

    // Draw data points
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final y = _getYPosition(entry.avgBMI, chartArea, minValue, maxValue);

      // Skip if position is invalid
      if (x.isNaN || y.isNaN || !x.isFinite || !y.isFinite) continue;

      final position = Offset(x, y);
      final isSelected = entry == selectedData;

      if (isSelected) {
        _drawSelectionHighlight(canvas, x, chartArea, style);
      }

      // Draw data point
      _drawPoint(
        canvas,
        position,
        style,
        animation,
        isSelected,
        entry.dataPointCount > 1,
      );

      // Draw reading count badge if multiple readings
      if (entry.dataPointCount > 1) {
        _drawReadingCount(
          canvas,
          position,
          entry.dataPointCount,
          style,
          animation,
        );
      }
    }
  }

  void _drawTrendLine(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBMIData> data,
    double xStep,
    BMIChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    final path = Path();
    var isFirstValidPoint = true;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final y = _getYPosition(data[i].avgBMI, chartArea, minValue, maxValue);

      if (isFirstValidPoint) {
        path.moveTo(x, y);
        isFirstValidPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineThickness
      ..color = style.lineColor.withValues(alpha: animation.value);

    canvas.drawPath(path, paint);
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    BMIChartStyle style,
  ) {
    final paint = Paint()
      ..color = style.selectedHighlightColor
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      paint,
    );
  }

  void _drawPoint(
    Canvas canvas,
    Offset position,
    BMIChartStyle style,
    Animation<double> animation,
    bool isSelected,
    bool isMultipleReadings,
  ) {
    // Validate position before drawing
    if (position.dx.isNaN ||
        position.dy.isNaN ||
        !position.dx.isFinite ||
        !position.dy.isFinite) {
      return;
    }

    if (isSelected) {
      _dataPointPaint
        ..style = PaintingStyle.fill
        ..color = style.selectedHighlightColor;
      canvas.drawCircle(position, style.pointRadius * 2, _dataPointPaint);
    }

    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = style.pointColor.withValues(alpha: animation.value);
    canvas.drawCircle(
      position,
      isMultipleReadings ? style.pointRadius : style.pointRadius * 1.5,
      _dataPointPaint,
    );

    _dataPointPaint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: animation.value)
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      position,
      isMultipleReadings ? style.pointRadius : style.pointRadius * 1.5,
      _dataPointPaint,
    );
  }

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    if (value.isNaN ||
        !value.isFinite ||
        minValue.isNaN ||
        !minValue.isFinite ||
        maxValue.isNaN ||
        !maxValue.isFinite ||
        maxValue == minValue) {
      return 0;
    }

    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  void _drawReadingCount(
    Canvas canvas,
    Offset position,
    int count,
    BMIChartStyle style,
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
      ..color = style.pointColor.withValues(alpha: animation.value);
    canvas.drawCircle(badgeCenter, badgeRadius, _dataPointPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }
}
