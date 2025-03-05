// lib/bmi/drawer/bmi_data_point_drawer.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

    // Only rebuild path if data changes
    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildTrendPath(chartArea, data, minValue, maxValue);
    }

    // Draw trend line with enhanced effects
    _drawEnhancedTrendLine(canvas, chartArea, style, animation);
    const edgePadding = 15.0; // Same as in chart_grid_drawer.dart
    final availableWidth = chartArea.width - (edgePadding * 2);
    // Draw data points with emphasizing latest values
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + edgePadding + (i * xStep);
      final y = _getYPosition(entry.avgBMI, chartArea, minValue, maxValue);
      final position = Offset(x, y);

      // Calculate animation value based on position for staggered effect
      final pointAnimationValue =
          _calculateAnimationValue(i, data.length, animation);
      final isSelected = entry == selectedData;

      // Draw selection highlight first if needed
      // if (isSelected) {
      //   _drawSelectionHighlight(canvas, x, chartArea, style, animation.value);
      // }

      // Determine if this is the latest data point
      final isLatestPoint = i == data.length - 1;

      // Draw enhanced data point with emphasizing latest value
      _drawEnhancedDataPoint(
        canvas,
        position,
        style,
        pointAnimationValue,
        isSelected,
        isLatestPoint,
        entry.avgBMI,
      );
    }
  }

  void _buildTrendPath(
    Rect chartArea,
    List<ProcessedBMIData> data,
    double minValue,
    double maxValue,
  ) {
    _trendPath = Path();

    List<Offset> points = [];
    bool isFirstValid = true;

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = chartArea.left + edgePadding + (i * xStep);
      final y = _getYPosition(data[i].avgBMI, chartArea, minValue, maxValue);

      points.add(Offset(x, y));

      if (isFirstValid) {
        _trendPath!.moveTo(x, y);
        isFirstValid = false;
      } else {
        // Use smooth curve for better appearance
        if (points.length >= 3) {
          final p1 = points[points.length - 3];
          final p2 = points[points.length - 2];
          final p3 = points[points.length - 1];

          if (points.length == 3) {
            _trendPath!.lineTo(p2.dx, p2.dy);
          }

          // Calculate control point for a smooth curve
          final controlPoint =
              Offset(p2.dx + (p3.dx - p1.dx) / 6, p2.dy + (p3.dy - p1.dy) / 6);

          _trendPath!.quadraticBezierTo(
              controlPoint.dx, controlPoint.dy, p3.dx, p3.dy);
        } else {
          _trendPath!.lineTo(x, y);
        }
      }
    }
  }

  void _drawEnhancedTrendLine(
    Canvas canvas,
    Rect chartArea,
    BMIChartStyle style,
    Animation<double> animation,
  ) {
    if (_trendPath == null) return;

    // Create a gradient for the trend line
    final gradient = ui.Gradient.linear(
      Offset(0, chartArea.top),
      Offset(0, chartArea.bottom),
      [
        style.lineColor.withValues(alpha: 0.8 * animation.value),
        style.lineColor.withValues(alpha: 0.4 * animation.value),
      ],
    );

    // Draw trend line with animation and gradient
    _linePaint
      ..shader = gradient
      ..strokeWidth = style.lineThickness
      ..style = PaintingStyle.stroke;

    // Use path metrics to animate the path drawing
    final pathMetrics = _trendPath!.computeMetrics();

    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(
        0.0,
        metric.length * animation.value,
      );
      canvas.drawPath(extractPath, _linePaint);
    }

    // Reset shader
    _linePaint.shader = null;

    // Add a subtle fill under the line for better visual effect
    if (animation.value > 0.3) {
      final fillOpacity =
          (animation.value - 0.3) / 0.7 * 0.15; // Max 15% opacity

      // Create path for area fill
      final fillPath = Path.from(_trendPath!);
      fillPath.lineTo(chartArea.right, chartArea.bottom);
      fillPath.lineTo(chartArea.left, chartArea.bottom);
      fillPath.close();

      // Draw fill with gradient
      _fillPaint
        ..shader = ui.Gradient.linear(
          Offset(0, chartArea.top),
          Offset(0, chartArea.bottom),
          [
            style.lineColor.withValues(alpha: fillOpacity),
            style.lineColor.withValues(alpha: 0),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, _fillPaint);

      // Reset shader
      _fillPaint.shader = null;
    }
  }

  // void _drawSelectionHighlight(
  //   Canvas canvas,
  //   double x,
  //   Rect chartArea,
  //   BMIChartStyle style,
  //   double animationValue,
  // )
  // {
  //   // Draw vertical line highlight with animation
  //   final paint = Paint()
  //     ..color = style.selectedHighlightColor.withValues(alpha: animationValue)
  //     ..strokeWidth = 2;
  //
  //   // Animate from center
  //   final centerY = chartArea.center.dy;
  //   final topY = ui.lerpDouble(centerY, chartArea.top, animationValue)!;
  //   final bottomY = ui.lerpDouble(centerY, chartArea.bottom, animationValue)!;
  //
  //   canvas.drawLine(
  //     Offset(x, topY),
  //     Offset(x, bottomY),
  //     paint,
  //   );
  //
  //   // Add subtle glow effect
  //   paint
  //     ..color =
  //         style.selectedHighlightColor.withValues(alpha: 0.3 * animationValue)
  //     ..strokeWidth = 8
  //     ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  //
  //   canvas.drawLine(
  //     Offset(x, topY),
  //     Offset(x, bottomY),
  //     paint,
  //   );
  //
  //   // Reset mask filter
  //   paint.maskFilter = null;
  // }

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

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    if (value.isNaN ||
        !value.isFinite ||
        minValue.isNaN ||
        !minValue.isFinite ||
        maxValue.isNaN ||
        !maxValue.isFinite ||
        maxValue == minValue) {
      return chartArea.center.dy;
    }

    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
