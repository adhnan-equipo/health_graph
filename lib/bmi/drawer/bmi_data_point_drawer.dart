// lib/bmi/drawer/bmi_data_point_drawer.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/utils/chart_calculations.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';

class BMIDataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  // Cache for performance optimization
  String _lastDataHash = '';
  Path? _trendPath;

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

    // Hash calculation for path caching (unchanged)
    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildTrendPath(chartArea, data, minValue, maxValue);
    }

    // Draw trend line (unchanged)
    _drawEnhancedTrendLine(canvas, chartArea, style, animation);

    const edgePadding = 15.0; // Same as in chart_grid_drawer.dart
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + edgePadding + (i * xStep);

      // Get the latest measurement value
      double yValue;
      if (entry.originalMeasurements.isNotEmpty) {
        yValue = entry.originalMeasurements.last.bmi;
      } else {
        yValue = entry.avgBMI; // Fallback to average
      }

      // Use shared calculation method for consistent positioning
      final y = SharedChartCalculations.calculateYPosition(
          yValue, chartArea, minValue, maxValue);

      final position = Offset(x, y);

      // Animation and selections (unchanged)
      final pointAnimationValue =
          _calculateAnimationValue(i, data.length, animation);
      final isSelected = entry == selectedData;
      final isLatestPoint = i == data.length - 1;

      // Draw data point
      _drawEnhancedDataPoint(
        canvas,
        position,
        style,
        pointAnimationValue,
        isSelected,
        isLatestPoint,
        yValue,
      );
    }
  }

  // MODIFIED: Update path building to use shared calculation
  void _buildTrendPath(
    Rect chartArea,
    List<ProcessedBMIData> data,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    _trendPath = Path();

    // Store valid points for processing
    final List<Offset> points = [];

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    // First pass: collect all valid points
    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      // Get the appropriate value
      double yValue;
      if (data[i].originalMeasurements.isNotEmpty) {
        yValue = data[i].originalMeasurements.last.bmi;
      } else {
        yValue = data[i].avgBMI;
      }

      final x = chartArea.left + edgePadding + (i * xStep);

      // Use shared calculation method for consistent positioning
      final y = SharedChartCalculations.calculateYPosition(
          yValue, chartArea, minValue, maxValue);

      points.add(Offset(x, y));
    }

    // If we have no valid points, return
    if (points.isEmpty) return;

    // Start the path at the first point
    _trendPath!.moveTo(points[0].dx, points[0].dy);

    // If we only have one point, we're done
    if (points.length == 1) return;

    // If we have exactly two points, just draw a straight line
    if (points.length == 2) {
      _trendPath!.lineTo(points[1].dx, points[1].dy);
      return;
    }

    // For three or more points, use a smoother algorithm
    // Simple approach: draw direct lines between points
    for (int i = 1; i < points.length; i++) {
      _trendPath!.lineTo(points[i].dx, points[i].dy);
    }

    // For a smoother curve (optional), you can use this instead:
    /*
    // Use a simple cardinal spline for smoothing
    for (int i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = points[i-1];

      // Simple direct line - more reliable
      _trendPath!.lineTo(current.dx, current.dy);
    }
    */
  }

  // For enhanced trend line drawing - ensure we're using the trendPath
  void _drawEnhancedTrendLine(
    Canvas canvas,
    Rect chartArea,
    BMIChartStyle style,
    Animation<double> animation,
  ) {
    if (_trendPath == null) return;

    // Draw the main line
    final linePaint = Paint()
      ..color = style.lineColor.withValues(alpha: 0.8 * animation.value)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_trendPath!, linePaint);

    // Add a subtle shadow for depth (optional)
    final shadowPaint = Paint()
      ..color = style.lineColor.withValues(alpha: 0.15 * animation.value)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(_trendPath!, shadowPaint);
  }

  void _drawEnhancedDataPoint(
    Canvas canvas,
    Offset position,
    BMIChartStyle style,
    double animationValue,
    bool isSelected,
    bool isLatestPoint,
    double bmiValue,
  ) {
    // Make latest point stand out more
    final baseRadius =
        isLatestPoint ? style.pointRadius * 2.0 : style.pointRadius;

    // Apply animation to radius
    final radius = baseRadius * animationValue;

    // Selected points are even larger
    final effectiveRadius = isSelected ? radius * 1.4 : radius;

    // Create color based on BMI value
    Color pointColor;
    if (bmiValue < 18.5) {
      pointColor = style.underweightRangeColor;
    } else if (bmiValue < 25.0) {
      pointColor = style.normalRangeColor;
    } else if (bmiValue < 30.0) {
      pointColor = style.overweightRangeColor;
    } else {
      pointColor = style.obeseRangeColor;
    }

    // For latest point, add a pulsing effect
    if (isLatestPoint) {
      final pulseScale = 1.0 + (sin(animationValue * 6) * 0.1).abs();
      final pulseRadius = effectiveRadius * pulseScale;

      // Create a soft outer glow for latest point
      _dataPointPaint
        ..color = pointColor.withValues(alpha: 0.2 * animationValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(position, pulseRadius * 1.8, _dataPointPaint);
      _dataPointPaint.maskFilter = null;
    }

    // Create a soft glow effect
    _dataPointPaint
      ..color = pointColor.withValues(alpha: 0.3 * animationValue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(position, effectiveRadius * 1.5, _dataPointPaint);
    _dataPointPaint.maskFilter = null;

    // Draw outer circle with a gradient
    final outerGradient = ui.Gradient.radial(
      position,
      effectiveRadius,
      [
        pointColor.withValues(alpha: 0.9 * animationValue),
        pointColor.withValues(alpha: 0.7 * animationValue),
      ],
    );

    _dataPointPaint
      ..shader = outerGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, effectiveRadius, _dataPointPaint);

    // Draw a white border
    _dataPointPaint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveRadius * 0.2
      ..color = Colors.white.withValues(alpha: 0.9 * animationValue);
    canvas.drawCircle(position, effectiveRadius * 0.9, _dataPointPaint);

    // Draw a highlight to create a 3D effect
    final highlightOffset = Offset(
      position.dx - effectiveRadius * 0.3,
      position.dy - effectiveRadius * 0.3,
    );

    _dataPointPaint
      ..color = Colors.white.withValues(alpha: 0.6 * animationValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(highlightOffset, effectiveRadius * 0.3, _dataPointPaint);

    // For the latest point, add a label with the BMI value
    if (isLatestPoint && effectiveRadius > 8) {
      _drawBMILabel(
          canvas, position, bmiValue, effectiveRadius, animationValue);
    }
  }

  void _drawBMILabel(Canvas canvas, Offset position, double bmiValue,
      double radius, double animationValue) {
    // Only draw label once animation is mostly complete
    if (animationValue < 0.7) return;

    final opacity = ((animationValue - 0.7) / 0.3).clamp(0.0, 1.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: bmiValue.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.5 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    // Position label below the point
    final labelPosition = Offset(
      position.dx - textPainter.width / 2,
      position.dy + radius * 1.5,
    );

    // Draw background for better readability
    final padding = radius * 0.2;
    final backgroundRect = Rect.fromLTWH(
      labelPosition.dx - padding,
      labelPosition.dy - padding,
      textPainter.width + (padding * 2),
      textPainter.height + (padding * 2),
    );

    final backgroundRRect = RRect.fromRectAndRadius(
      backgroundRect,
      Radius.circular(padding * 2),
    );

    canvas.drawRRect(
      backgroundRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4 * opacity)
        ..style = PaintingStyle.fill,
    );

    textPainter.paint(canvas, labelPosition);
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
    return 1.0 - pow(1.0 - t, 3) as double;
  }
}
