import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/utils/chart_calculations.dart';
import '../models/processed_blood_pressure_data.dart';
import '../styles/blood_pressure_chart_style.dart';

class ChartDataPointDrawer {
  // Reuse paint objects for better performance
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  // Cache for performance optimization
  String _lastDataHash = '';
  Path? _systolicPath;
  Path? _diastolicPath;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    BloodPressureChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    // Only rebuild paths if data changes
    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildPaths(chartArea, data, minValue, maxValue);
    }

    // Draw trend lines with gradient
    _drawEnhancedTrendLines(
        canvas, chartArea, data, style, animation, minValue, maxValue);

    // Draw data points
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x =
          SharedChartCalculations.calculateXPosition(i, data.length, chartArea);

      // Ensure point is within drawable area
      if (x >= chartArea.left && x <= chartArea.right) {
        final positions = _calculateDataPointPositions(
          entry,
          x,
          chartArea,
          minValue,
          maxValue,
        );

        final animationValue =
            _calculateAnimationValue(i, data.length, animation);

        // Draw the point based on type
        if (entry.dataPointCount == 1) {
          _drawEnhancedSinglePoint(
              canvas, positions, style, animationValue, entry);
        } else {
          _drawEnhancedRangePoint(
              canvas, positions, style, animationValue, entry);
        }
      }
    }
  }

  // Optimize path building for trend lines
  void _buildPaths(
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    double minValue,
    double maxValue,
  ) {
    _systolicPath = Path();
    _diastolicPath = Path();

    bool isFirstValid = true;
    List<Offset> systolicPoints = [];
    List<Offset> diastolicPoints = [];

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x =
          SharedChartCalculations.calculateXPosition(i, data.length, chartArea);

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

      systolicPoints.add(Offset(x, systolicY));
      diastolicPoints.add(Offset(x, diastolicY));

      if (isFirstValid) {
        _systolicPath!.moveTo(x, systolicY);
        _diastolicPath!.moveTo(x, diastolicY);
        isFirstValid = false;
      } else {
        // Use a smooth curve instead of straight lines for better appearance
        if (systolicPoints.length >= 3) {
          final p1 = systolicPoints[systolicPoints.length - 3];
          final p2 = systolicPoints[systolicPoints.length - 2];
          final p3 = systolicPoints[systolicPoints.length - 1];

          if (systolicPoints.length == 3) {
            _systolicPath!.lineTo(p2.dx, p2.dy);
          }

          // Calculate control points for a smooth curve
          final controlPoint1 =
              Offset(p2.dx + (p3.dx - p1.dx) / 6, p2.dy + (p3.dy - p1.dy) / 6);

          _systolicPath!.quadraticBezierTo(
              controlPoint1.dx, controlPoint1.dy, p3.dx, p3.dy);
        } else {
          _systolicPath!.lineTo(x, systolicY);
        }

        if (diastolicPoints.length >= 3) {
          final p1 = diastolicPoints[diastolicPoints.length - 3];
          final p2 = diastolicPoints[diastolicPoints.length - 2];
          final p3 = diastolicPoints[diastolicPoints.length - 1];

          if (diastolicPoints.length == 3) {
            _diastolicPath!.lineTo(p2.dx, p2.dy);
          }

          // Calculate control points for a smooth curve
          final controlPoint1 =
              Offset(p2.dx + (p3.dx - p1.dx) / 6, p2.dy + (p3.dy - p1.dy) / 6);

          _diastolicPath!.quadraticBezierTo(
              controlPoint1.dx, controlPoint1.dy, p3.dx, p3.dy);
        } else {
          _diastolicPath!.lineTo(x, diastolicY);
        }
      }
    }
  }

  void _drawEnhancedTrendLines(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    BloodPressureChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    if (_systolicPath == null || _diastolicPath == null) return;

    // Create a gradient for systolic line
    final systolicGradient = ui.Gradient.linear(
      Offset(0, chartArea.top),
      Offset(0, chartArea.bottom),
      [
        style.systolicColor.withValues(alpha: 0.7 * animation.value),
        style.systolicColor.withValues(alpha: 0.3 * animation.value),
      ],
    );

    // Draw systolic trend line with animation and gradient
    _linePaint
      ..shader = systolicGradient
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_systolicPath!, _linePaint);

    // Create a gradient for diastolic line
    final diastolicGradient = ui.Gradient.linear(
      Offset(0, chartArea.top),
      Offset(0, chartArea.bottom),
      [
        style.diastolicColor.withValues(alpha: 0.7 * animation.value),
        style.diastolicColor.withValues(alpha: 0.3 * animation.value),
      ],
    );

    // Draw diastolic trend line with animation and gradient
    _linePaint
      ..shader = diastolicGradient
      ..strokeWidth = 2.5;
    canvas.drawPath(_diastolicPath!, _linePaint);

    // Reset shader
    _linePaint.shader = null;

    // Add a subtle fill under the lines for better visual effect
    if (animation.value > 0.5) {
      final fillOpacity = (animation.value - 0.5) * 2 * 0.15; // Max 15% opacity

      // Create path for systolic area fill
      final systolicFillPath = Path.from(_systolicPath!);
      systolicFillPath.lineTo(chartArea.right, chartArea.bottom);
      systolicFillPath.lineTo(chartArea.left, chartArea.bottom);
      systolicFillPath.close();

      // Create path for diastolic area fill
      final diastolicFillPath = Path.from(_diastolicPath!);
      diastolicFillPath.lineTo(chartArea.right, chartArea.bottom);
      diastolicFillPath.lineTo(chartArea.left, chartArea.bottom);
      diastolicFillPath.close();

      // Draw fills
      _fillPaint.shader = ui.Gradient.linear(
        Offset(0, chartArea.top),
        Offset(0, chartArea.bottom),
        [
          style.systolicColor.withValues(alpha: fillOpacity),
          style.systolicColor.withValues(alpha: 0),
        ],
      );
      canvas.drawPath(systolicFillPath, _fillPaint);

      _fillPaint.shader = ui.Gradient.linear(
        Offset(0, chartArea.top),
        Offset(0, chartArea.bottom),
        [
          style.diastolicColor.withValues(alpha: fillOpacity),
          style.diastolicColor.withValues(alpha: 0),
        ],
      );
      canvas.drawPath(diastolicFillPath, _fillPaint);

      // Reset shader
      _fillPaint.shader = null;
    }
  }

  void _drawEnhancedSinglePoint(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    double animationValue,
    ProcessedBloodPressureData data,
  ) {
    // Draw connecting line with gradient
    final lineGradient = ui.Gradient.linear(
      positions.maxSystolicPoint,
      positions.maxDiastolicPoint,
      [
        style.systolicColor.withValues(alpha: 0.7 * animationValue),
        style.diastolicColor.withValues(alpha: 0.7 * animationValue),
      ],
    );

    _linePaint
      ..shader = lineGradient
      ..strokeWidth = style.lineThickness + 0.5; // Slightly thicker
    canvas.drawLine(
        positions.maxSystolicPoint, positions.maxDiastolicPoint, _linePaint);
    _linePaint.shader = null;

    // Draw points with enhanced appearance
    _drawEnhancedDataPoint(
      canvas,
      positions.maxSystolicPoint,
      style.systolicColor,
      style.pointRadius * 1.2, // Slightly larger
      animationValue,
      style,
      true, // Is systolic
      data.maxSystolic,
    );

    _drawEnhancedDataPoint(
      canvas,
      positions.maxDiastolicPoint,
      style.diastolicColor,
      style.pointRadius * 1.2, // Slightly larger
      animationValue,
      style,
      false, // Is diastolic
      data.maxDiastolic,
    );
  }

  void _drawEnhancedRangePoint(
    Canvas canvas,
    ({
      Offset maxSystolicPoint,
      Offset minSystolicPoint,
      Offset maxDiastolicPoint,
      Offset minDiastolicPoint
    }) positions,
    BloodPressureChartStyle style,
    double animationValue,
    ProcessedBloodPressureData data,
  ) {
    final rangeWidth = style.lineThickness * 3.5;

    // Create gradient for systolic range
    final systolicGradient = ui.Gradient.linear(
      positions.maxSystolicPoint,
      positions.minSystolicPoint,
      [
        style.systolicColor.withValues(alpha: 0.9 * animationValue),
        style.systolicColor.withValues(alpha: 0.5 * animationValue),
      ],
    );

    // Create gradient for diastolic range
    final diastolicGradient = ui.Gradient.linear(
      positions.maxDiastolicPoint,
      positions.minDiastolicPoint,
      [
        style.diastolicColor.withValues(alpha: 0.9 * animationValue),
        style.diastolicColor.withValues(alpha: 0.5 * animationValue),
      ],
    );

    // Draw systolic range with gradient
    _drawEnhancedRangeLine(
      canvas,
      positions.maxSystolicPoint,
      positions.minSystolicPoint,
      style.systolicColor,
      systolicGradient,
      rangeWidth,
      animationValue,
      style,
      true,
      data.minSystolic,
      data.maxSystolic,
    );

    // Draw diastolic range with gradient
    _drawEnhancedRangeLine(
      canvas,
      positions.maxDiastolicPoint,
      positions.minDiastolicPoint,
      style.diastolicColor,
      diastolicGradient,
      rangeWidth,
      animationValue,
      style,
      false,
      data.minDiastolic,
      data.maxDiastolic,
    );
  }

  void _drawEnhancedRangeLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    ui.Gradient gradient,
    double width,
    double animationValue,
    BloodPressureChartStyle style,
    bool isSystolic,
    int minValue,
    int maxValue,
  ) {
    // Animate line drawing from center
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final animatedStart = Offset.lerp(center, start, animationValue)!;
    final animatedEnd = Offset.lerp(center, end, animationValue)!;

    // Draw main line with gradient
    _linePaint
      ..shader = gradient
      ..strokeWidth = width;
    canvas.drawLine(animatedStart, animatedEnd, _linePaint);
    _linePaint.shader = null;

    // Draw decorative capsules at ends
    _drawEnhancedDataPoint(
      canvas,
      animatedStart,
      color,
      width / 2 + 1,
      animationValue,
      style,
      isSystolic,
      maxValue,
    );

    _drawEnhancedDataPoint(
      canvas,
      animatedEnd,
      color,
      width / 2 + 1,
      animationValue,
      style,
      isSystolic,
      minValue,
    );
  }

  void _drawEnhancedDataPoint(
    Canvas canvas,
    Offset position,
    Color color,
    double radius,
    double animationValue,
    BloodPressureChartStyle style,
    bool isSystolic,
    int value,
  ) {
    // Apply animation to radius
    final animatedRadius = radius * animationValue;

    // Create a soft glow effect
    _fillPaint
      ..color = color.withValues(alpha: 0.3 * animationValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(position, animatedRadius * 1.5, _fillPaint);
    _fillPaint.maskFilter = null;

    // Draw outer circle with a gradient
    final outerGradient = ui.Gradient.radial(
      position,
      animatedRadius,
      [
        color.withValues(alpha: 0.9 * animationValue),
        color.withValues(alpha: 0.7 * animationValue),
      ],
    );

    _dataPointPaint
      ..shader = outerGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, animatedRadius, _dataPointPaint);

    // Draw a highlight to create a 3D effect
    final highlightOffset = Offset(
      position.dx - animatedRadius * 0.3,
      position.dy - animatedRadius * 0.3,
    );

    _fillPaint
      ..color = Colors.white.withValues(alpha: 0.5 * animationValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(highlightOffset, animatedRadius * 0.4, _fillPaint);

    // Reset shader
    _dataPointPaint.shader = null;
  }

  // Improved animation calculation for smoother transitions
  double _calculateAnimationValue(
      int index, int totalPoints, Animation<double> animation) {
    // Progressive animation with smoother timing function
    final delay = index / (totalPoints * 1.5);
    final duration = 1.2 / totalPoints;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    // Ease-out cubic for smoother finish
    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3);
  }

  // Helper method for position calculation
  ({
    Offset maxSystolicPoint,
    Offset minSystolicPoint,
    Offset maxDiastolicPoint,
    Offset minDiastolicPoint
  }) _calculateDataPointPositions(
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
