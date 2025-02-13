import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';
import '../styles/blood_pressure_chart_style.dart';

class ChartDataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    BloodPressureChartStyle style,
    Animation<double> animation,
    ProcessedBloodPressureData? selectedData,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    final xStep = chartArea.width / (data.length - 1);

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

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final positions = _calculateDataPointPositions(
        entry,
        x,
        chartArea,
        minValue,
        maxValue,
      );

      final isSelected = entry == selectedData;

      if (isSelected) {
        _drawSelectionHighlight(canvas, x, chartArea, style);
      }

      if (entry.dataPointCount > 1) {
        _drawRangeLines(
          canvas,
          positions,
          style,
          animation,
          isSelected,
        );
      } else {
        _drawSinglePointConnector(
          canvas,
          positions,
          style,
          animation,
          isSelected,
        );
      }

      _drawPoints(
        canvas,
        positions,
        style,
        animation,
        isSelected,
        entry.dataPointCount > 1,
      );

      if (entry.dataPointCount > 1) {
        _drawReadingCount(
          canvas,
          positions.maxSystolicPoint,
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
    List<ProcessedBloodPressureData> data,
    double xStep,
    BloodPressureChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    if (data.length < 2) return;

    final systolicPath = Path();
    final diastolicPath = Path();
    var isFirstValidPoint = true;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final entry = data[i];

      final systolicY = _getYPosition(
        entry.avgSystolic,
        chartArea,
        minValue,
        maxValue,
      );
      final diastolicY = _getYPosition(
        entry.avgDiastolic,
        chartArea,
        minValue,
        maxValue,
      );

      if (isFirstValidPoint) {
        systolicPath.moveTo(x, systolicY);
        diastolicPath.moveTo(x, diastolicY);
        isFirstValidPoint = false;
      } else {
        systolicPath.lineTo(x, systolicY);
        diastolicPath.lineTo(x, diastolicY);
      }
    }

    // Draw trend lines
    final trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw systolic trend line
    trendPaint.color = style.systolicColor.withOpacity(0.3 * animation.value);
    canvas.drawPath(systolicPath, trendPaint);

    // Draw diastolic trend line
    trendPaint.color = style.diastolicColor.withOpacity(0.3 * animation.value);
    canvas.drawPath(diastolicPath, trendPaint);
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    BloodPressureChartStyle style,
  ) {
    final paint = Paint()
      ..color = style.selectedHighlightColor.withOpacity(0.2)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      paint,
    );
  }

  void _drawSinglePointConnector(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    Animation<double> animation,
    bool isSelected,
  ) {
    _dataPointPaint
      ..color = (isSelected
          ? style.connectorColor.withOpacity(animation.value * 0.8)
          : style.connectorColor.withOpacity(animation.value * 0.3))
      ..strokeWidth = style.lineThickness;

    canvas.drawLine(
      positions.maxSystolicPoint,
      positions.maxDiastolicPoint,
      _dataPointPaint,
    );
  }

  void _drawRangeLines(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    Animation<double> animation,
    bool isSelected,
  ) {
    _dataPointPaint
      ..color = style.systolicColor.withOpacity(animation.value * 0.5)
      ..strokeWidth = style.lineThickness;
    canvas.drawLine(
      positions.maxSystolicPoint,
      positions.minSystolicPoint,
      _dataPointPaint,
    );

    _dataPointPaint.color =
        style.diastolicColor.withOpacity(animation.value * 0.5);
    canvas.drawLine(
      positions.maxDiastolicPoint,
      positions.minDiastolicPoint,
      _dataPointPaint,
    );

    _dataPointPaint
      ..color = (isSelected
          ? style.connectorColor.withOpacity(animation.value * 0.8)
          : style.connectorColor.withOpacity(animation.value * 0.3))
      ..strokeWidth = style.lineThickness / 2;
    canvas.drawLine(
      positions.minSystolicPoint,
      positions.maxDiastolicPoint,
      _dataPointPaint,
    );
  }

  void _drawPoints(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    Animation<double> animation,
    bool isSelected,
    bool isRangeData,
  ) {
    void drawPoint(Offset position, Color color) {
      if (isSelected) {
        _dataPointPaint
          ..style = PaintingStyle.fill
          ..color = style.selectedHighlightColor;
        canvas.drawCircle(position, style.pointRadius * 2, _dataPointPaint);
      }

      _dataPointPaint
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(animation.value);
      canvas.drawCircle(
        position,
        isRangeData ? style.pointRadius : style.pointRadius * 1.5,
        _dataPointPaint,
      );

      _dataPointPaint
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(animation.value)
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        position,
        isRangeData ? style.pointRadius : style.pointRadius * 1.5,
        _dataPointPaint,
      );
    }

    // Draw systolic points
    drawPoint(positions.maxSystolicPoint, style.systolicColor);
    if (isRangeData) {
      drawPoint(positions.minSystolicPoint, style.systolicColor);
    }

    // Draw diastolic points
    drawPoint(positions.maxDiastolicPoint, style.diastolicColor);
    if (isRangeData) {
      drawPoint(positions.minDiastolicPoint, style.diastolicColor);
    }
  }

  void _drawReadingCount(
    Canvas canvas,
    Offset position,
    int count,
    BloodPressureChartStyle style,
    Animation<double> animation,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: style.dateLabelStyle,
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
      ..color = style.systolicColor.withOpacity(animation.value);
    canvas.drawCircle(badgeCenter, badgeRadius, _dataPointPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  _calculateDataPointPositions(
    ProcessedBloodPressureData entry,
    double x,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return (
      maxSystolicPoint: Offset(
        x,
        _getYPosition(
            entry.maxSystolic.toDouble(), chartArea, minValue, maxValue),
      ),
      minSystolicPoint: Offset(
        x,
        _getYPosition(
            entry.minSystolic.toDouble(), chartArea, minValue, maxValue),
      ),
      maxDiastolicPoint: Offset(
        x,
        _getYPosition(
            entry.maxDiastolic.toDouble(), chartArea, minValue, maxValue),
      ),
      minDiastolicPoint: Offset(
        x,
        _getYPosition(
            entry.minDiastolic.toDouble(), chartArea, minValue, maxValue),
      ),
    );
  }

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
