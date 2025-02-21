// Updated ChartDataPointDrawer with improved plotting
import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';
import '../services/chart_calculations.dart';
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

    // Draw trend lines first
    if (data.length > 1) {
      _drawTrendLines(
        canvas,
        chartArea,
        data,
        style,
        animation,
        minValue,
        maxValue,
      );
    }

    // Draw each data point
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);

      // Ensure point is within drawable area
      if (x >= chartArea.left && x <= chartArea.right) {
        final positions = _calculateDataPointPositions(
          entry,
          x,
          chartArea,
          minValue,
          maxValue,
        );

        final isSelected = entry == selectedData;
        final animationValue =
            _calculateAnimationValue(i, data.length, animation);

        if (isSelected) {
          _drawSelectionHighlight(canvas, x, chartArea, style, animationValue);
        }

        // Draw the point based on type
        if (entry.dataPointCount == 1) {
          _drawSinglePoint(
            canvas,
            positions,
            style,
            animationValue,
            isSelected,
          );
        } else {
          _drawRangePoint(
            canvas,
            positions,
            style,
            animationValue,
            isSelected,
          );
        }
      }
    }
  }

  double _calculateAnimationValue(
      int index, int totalPoints, Animation<double> animation) {
    // Stagger animation based on point index
    final delay = index / (totalPoints * 2);
    final duration = 1.0 / totalPoints;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    return ((animation.value - delay) / duration).clamp(0.0, 1.0);
  }

  void _drawTrendLines(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    BloodPressureChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    final systolicPath = Path();
    final diastolicPath = Path();
    var isFirstPoint = true;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);
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

      if (isFirstPoint) {
        systolicPath.moveTo(x, systolicY);
        diastolicPath.moveTo(x, diastolicY);
        isFirstPoint = false;
      } else {
        systolicPath.lineTo(x, systolicY);
        diastolicPath.lineTo(x, diastolicY);
      }
    }

    // Draw trend lines with animation
    final trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    trendPaint.color = style.systolicColor.withOpacity(0.3 * animation.value);
    canvas.drawPath(systolicPath, trendPaint);

    trendPaint.color = style.diastolicColor.withOpacity(0.3 * animation.value);
    canvas.drawPath(diastolicPath, trendPaint);
  }

  void _drawRangePoint(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    double animationValue,
    bool isSelected,
  ) {
    final rangeWidth = style.lineThickness * 3;

    // Draw systolic range with animation
    _drawAnimatedRangeLine(
      canvas,
      positions.maxSystolicPoint,
      positions.minSystolicPoint,
      style.systolicColor,
      rangeWidth,
      animationValue,
      isSelected,
      style,
    );

    // Draw diastolic range with animation
    _drawAnimatedRangeLine(
      canvas,
      positions.maxDiastolicPoint,
      positions.minDiastolicPoint,
      style.diastolicColor,
      rangeWidth,
      animationValue,
      isSelected,
      style,
    );
  }

  void _drawAnimatedRangeLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
    double animationValue,
    bool isSelected,
    BloodPressureChartStyle style,
  ) {
    // Animate line drawing from center
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final animatedStart = Offset.lerp(center, start, animationValue)!;
    final animatedEnd = Offset.lerp(center, end, animationValue)!;

    // Draw outer line
    _dataPointPaint
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawLine(animatedStart, animatedEnd, _dataPointPaint);

    // Draw inner line for hollow effect
    if (!isSelected) {
      _dataPointPaint
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = width * 0.6;
      canvas.drawLine(animatedStart, animatedEnd, _dataPointPaint);
    }

    // Draw end caps with animation
    _drawAnimatedPoint(
      canvas,
      animatedStart,
      color,
      width / 2,
      animationValue,
      isSelected,
      style,
    );
    _drawAnimatedPoint(
      canvas,
      animatedEnd,
      color,
      width / 2,
      animationValue,
      isSelected,
      style,
    );
  }

  void _drawAnimatedPoint(
    Canvas canvas,
    Offset position,
    Color color,
    double radius,
    double animationValue,
    bool isSelected,
    BloodPressureChartStyle style,
  ) {
    // Scale animation for points
    final animatedRadius = radius * animationValue;

    if (isSelected) {
      // Draw selection highlight
      _dataPointPaint
        ..color = style.selectedHighlightColor.withOpacity(0.3 * animationValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, animatedRadius * 2, _dataPointPaint);
    }

    // Draw outer circle
    _dataPointPaint
      ..color = color.withOpacity(animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, animatedRadius, _dataPointPaint);

    // Fill circle if selected
    if (isSelected) {
      _dataPointPaint
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(animationValue);
      canvas.drawCircle(position, animatedRadius - 1, _dataPointPaint);
    }
  }

  void _drawSinglePoint(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    double animationValue,
    bool isSelected,
  ) {
    // Draw connecting line with animation
    if (isSelected) {
      final start = positions.maxSystolicPoint;
      final end = positions.maxDiastolicPoint;
      final center = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final animatedStart = Offset.lerp(center, start, animationValue)!;
      final animatedEnd = Offset.lerp(center, end, animationValue)!;

      _dataPointPaint
        ..color = style.connectorColor.withOpacity(0.5 * animationValue)
        ..strokeWidth = style.lineThickness;
      canvas.drawLine(animatedStart, animatedEnd, _dataPointPaint);
    }

    // Draw points with animation
    _drawAnimatedPoint(
      canvas,
      positions.maxSystolicPoint,
      style.systolicColor,
      style.pointRadius * 1.2,
      animationValue,
      isSelected,
      style,
    );

    _drawAnimatedPoint(
      canvas,
      positions.maxDiastolicPoint,
      style.diastolicColor,
      style.pointRadius * 1.2,
      animationValue,
      isSelected,
      style,
    );
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    BloodPressureChartStyle style,
    double animationValue,
  ) {
    // Gradient background
    final gradientRect = Rect.fromLTRB(
      x - 30, // Increased from 20
      chartArea.top,
      x + 30, // Increased from 20
      chartArea.bottom,
    );

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        style.selectedHighlightColor.withOpacity(0),
        style.selectedHighlightColor.withOpacity(0.3), // Increased from 0.2
        style.selectedHighlightColor.withOpacity(0.3), // Increased from 0.2
        style.selectedHighlightColor.withOpacity(0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(gradientRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(gradientRect, paint);

    // Make vertical line more visible
    final dashPaint = Paint()
      ..color =
          style.selectedHighlightColor.withOpacity(0.6) // Increased from 0.4
      ..strokeWidth = 2.0 // Increased from 1.5
      ..style = PaintingStyle.stroke;

    final dashPath = Path();
    double dash = 4;
    double gap = 4;
    double startY = chartArea.top;

    while (startY < chartArea.bottom) {
      dashPath.moveTo(x, startY);
      dashPath.lineTo(x, startY + dash);
      startY += dash + gap;
    }

    // Animate dash offset
    final dashOffset = (animationValue * (dash + gap)) % (dash + gap);
    canvas.save();
    canvas.translate(0, dashOffset);
    canvas.drawPath(dashPath, dashPaint);
    canvas.restore();
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
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
