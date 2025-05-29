// lib/steps/drawer/step_data_point_drawer.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/processed_step_data.dart';
import '../services/step_chart_calculations.dart';
import '../styles/step_chart_style.dart';

class StepDataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;

  String _lastDataHash = '';
  Path? _trendPath;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedStepData> data,
    StepChartStyle style,
    Animation<double> animation,
    ProcessedStepData? selectedData,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildTrendPath(chartArea, data, minValue, maxValue);
    }

    // Draw trend line
    _drawTrendLine(canvas, chartArea, style, animation);

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + edgePadding + (i * xStep);

      // KEY FIX: Use TOTAL steps for the period, not latest individual reading
      final stepValue = entry.totalStepsInPeriod.toDouble();

      final y = StepChartCalculations.calculateYPosition(
          stepValue, chartArea, minValue, maxValue);

      final position = Offset(x, y);

      final pointAnimationValue =
          _calculateAnimationValue(i, data.length, animation);
      final isSelected = entry == selectedData;
      final isLatestPoint = i == data.length - 1;

      // Draw data point with TOTAL steps
      _drawEnhancedDataPoint(
        canvas,
        position,
        style,
        pointAnimationValue,
        isSelected,
        isLatestPoint,
        entry.totalStepsInPeriod,
        // Show total steps for the period
        entry.category,
      );
    }
  }

  void _buildTrendPath(
    Rect chartArea,
    List<ProcessedStepData> data,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    _trendPath = Path();
    final List<Offset> points = [];

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      // KEY FIX: Use TOTAL steps for trend line as well
      final stepValue = data[i].totalStepsInPeriod.toDouble();
      final x = chartArea.left + edgePadding + (i * xStep);
      final y = StepChartCalculations.calculateYPosition(
          stepValue, chartArea, minValue, maxValue);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    _trendPath!.moveTo(points[0].dx, points[0].dy);

    if (points.length == 1) return;

    if (points.length == 2) {
      _trendPath!.lineTo(points[1].dx, points[1].dy);
      return;
    }

    for (int i = 1; i < points.length; i++) {
      _trendPath!.lineTo(points[i].dx, points[i].dy);
    }
  }

  void _drawTrendLine(
    Canvas canvas,
    Rect chartArea,
    StepChartStyle style,
    Animation<double> animation,
  ) {
    if (_trendPath == null) return;

    final linePaint = Paint()
      ..color = style.lineColor.withOpacity(0.8 * animation.value)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_trendPath!, linePaint);

    // Add subtle shadow
    final shadowPaint = Paint()
      ..color = style.lineColor.withOpacity(0.15 * animation.value)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(_trendPath!, shadowPaint);
  }

  void _drawEnhancedDataPoint(
    Canvas canvas,
    Offset position,
    StepChartStyle style,
    double animationValue,
    bool isSelected,
    bool isLatestPoint,
    int totalSteps, // This is now total steps for the period
    dynamic stepCategory,
  ) {
    final baseRadius =
        isLatestPoint ? style.pointRadius * 2.0 : style.pointRadius;
    final radius = baseRadius * animationValue;
    final effectiveRadius = isSelected ? radius * 1.4 : radius;

    // Get color based on step category
    Color pointColor = style.getCategoryColor(stepCategory);

    // Latest point pulsing effect
    if (isLatestPoint) {
      final pulseScale = 1.0 + (sin(animationValue * 6) * 0.1).abs();
      final pulseRadius = effectiveRadius * pulseScale;

      _dataPointPaint
        ..color = pointColor.withValues(alpha: 0.2 * animationValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(position, pulseRadius * 1.8, _dataPointPaint);
      _dataPointPaint.maskFilter = null;
    }

    // Soft glow effect
    _dataPointPaint
      ..color = pointColor.withValues(alpha: 0.3 * animationValue)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(position, effectiveRadius * 1.5, _dataPointPaint);
    _dataPointPaint.maskFilter = null;

    // Main circle with gradient
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

    // White border
    _dataPointPaint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveRadius * 0.2
      ..color = Colors.white.withValues(alpha: 0.9 * animationValue);
    canvas.drawCircle(position, effectiveRadius * 0.9, _dataPointPaint);

    // Highlight for 3D effect
    final highlightOffset = Offset(
      position.dx - effectiveRadius * 0.3,
      position.dy - effectiveRadius * 0.3,
    );

    _dataPointPaint
      ..color = Colors.white.withValues(alpha: 0.6 * animationValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(highlightOffset, effectiveRadius * 0.3, _dataPointPaint);

    // Label for latest point - show TOTAL steps
    if (isLatestPoint && effectiveRadius > 8) {
      _drawStepLabel(
          canvas, position, totalSteps, effectiveRadius, animationValue);
    }
  }

  void _drawStepLabel(Canvas canvas, Offset position, int totalSteps,
      double radius, double animationValue) {
    if (animationValue < 0.7) return;

    final opacity = ((animationValue - 0.7) / 0.3).clamp(0.0, 1.0);

    // Format the total steps nicely
    String stepText;
    if (totalSteps >= 1000) {
      stepText = '${(totalSteps / 1000).toStringAsFixed(1)}K';
    } else {
      stepText = totalSteps.toString();
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: stepText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: radius * 0.6,
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

    final labelPosition = Offset(
      position.dx - textPainter.width / 2,
      position.dy + radius * 1.5,
    );

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

  double _calculateAnimationValue(
      int index, int totalPoints, Animation<double> animation) {
    final delay = index / (totalPoints * 1.5);
    final duration = 1.2 / totalPoints;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3) as double;
  }
}
