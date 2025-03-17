// lib/o2_saturation/painters/o2_data_point_drawer.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';

class O2DataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  // Cache for performance optimization
  String _lastDataHash = '';
  Path? _o2Path;
  Path? _pulsePath;

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

    // Only rebuild paths if data changes
    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildPaths(chartArea, data, minValue, maxValue);
    }

    // Draw trend lines
    _drawTrendLines(
      canvas,
      chartArea,
      style,
      animation,
    );

    // Draw individual data points
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _calculateXPosition(i, data.length, chartArea);

      // Check if point is within drawable area
      if (x >= chartArea.left && x <= chartArea.right) {
        // Calculate O2 saturation positions
        final o2Y =
            _getYPosition(entry.avgValue, chartArea, minValue, maxValue);
        final o2MinY = _getYPosition(
            entry.minValue.toDouble(), chartArea, minValue, maxValue);
        final o2MaxY = _getYPosition(
            entry.maxValue.toDouble(), chartArea, minValue, maxValue);

        // Calculate pulse rate positions if available
        Offset? pulsePoint;
        Offset? pulseMinPoint;
        Offset? pulseMaxPoint;

        if (entry.avgPulseRate != null) {
          final pulseY =
              _getYPosition(entry.avgPulseRate!, chartArea, minValue, maxValue);
          pulsePoint = Offset(x, pulseY);

          if (entry.minPulseRate != null && entry.maxPulseRate != null) {
            final pulseMinY = _getYPosition(
                entry.minPulseRate!.toDouble(), chartArea, minValue, maxValue);
            final pulseMaxY = _getYPosition(
                entry.maxPulseRate!.toDouble(), chartArea, minValue, maxValue);
            pulseMinPoint = Offset(x, pulseMinY);
            pulseMaxPoint = Offset(x, pulseMaxY);
          }
        }

        final animationValue =
            _calculateAnimationValue(i, data.length, animation);

        _drawSinglePoint(
            canvas, Offset(x, o2Y), pulsePoint, style, animationValue);

        // Draw based on single or multiple readings
        // if (entry.dataPointCount == 1) {
        //   // Single reading
        //   _drawSinglePoint(
        //       canvas, Offset(x, o2Y), pulsePoint, style, animationValue);
        // } else {
        //   // Multiple readings (range)
        //   _drawRangePoint(
        //       canvas,
        //       x,
        //       Offset(x, o2Y),
        //       Offset(x, o2MinY),
        //       Offset(x, o2MaxY),
        //       pulsePoint,
        //       pulseMinPoint,
        //       pulseMaxPoint,
        //       style,
        //       animationValue,
        //       entry);
        // }

        // Draw reading count badge if multiple readings
        // if (entry.dataPointCount > 1) {
        //   _drawReadingCount(canvas, Offset(x, o2Y), entry.dataPointCount, style,
        //       animationValue);
        // }
      }
    }
  }

  // Build paths for trend lines
  void _buildPaths(
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    double minValue,
    double maxValue,
  ) {
    _o2Path = Path();
    _pulsePath = Path();

    bool isFirstValidO2 = true;
    bool isFirstValidPulse = true;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _calculateXPosition(i, data.length, chartArea);
      final o2Y = _getYPosition(entry.avgValue, chartArea, minValue, maxValue);

      // Add point to O2 path
      if (isFirstValidO2) {
        _o2Path!.moveTo(x, o2Y);
        isFirstValidO2 = false;
      } else {
        _o2Path!.lineTo(x, o2Y);
      }

      // Add point to pulse path if available
      if (entry.avgPulseRate != null) {
        final pulseY =
            _getYPosition(entry.avgPulseRate!, chartArea, minValue, maxValue);

        if (isFirstValidPulse) {
          _pulsePath!.moveTo(x, pulseY);
          isFirstValidPulse = false;
        } else {
          _pulsePath!.lineTo(x, pulseY);
        }
      }
    }
  }

  void _drawTrendLines(
    Canvas canvas,
    Rect chartArea,
    O2SaturationChartStyle style,
    Animation<double> animation,
  ) {
    // Draw O2 trend line
    if (_o2Path != null) {
      // Draw flat fill first (no diagonal effect)
      final fillRect = Rect.fromLTRB(
          chartArea.left, chartArea.top, chartArea.right, chartArea.bottom);
      canvas.drawRect(
          fillRect,
          Paint()
            ..color = style.primaryColor.withOpacity(0.03 * animation.value));

      // Then draw just the line
      _linePaint
        ..color = style.primaryColor.withOpacity(0.5 * animation.value)
        ..strokeWidth = style.lineThickness;
      canvas.drawPath(_o2Path!, _linePaint);
    }
  }

  void _drawSinglePoint(
    Canvas canvas,
    Offset o2Point,
    Offset? pulsePoint,
    O2SaturationChartStyle style,
    double animationValue,
  ) {
    // Draw O2 point
    _drawDataPoint(
        canvas, o2Point, style.primaryColor, style.pointRadius, animationValue);

    // Draw pulse point if available
    if (pulsePoint != null) {
      _drawDataPoint(canvas, pulsePoint, style.pulseRateColor,
          style.pointRadius, animationValue);

      // Draw connecting line
      _linePaint
        ..color = Colors.grey.withOpacity(0.3 * animationValue)
        ..strokeWidth = 1.0;
      canvas.drawLine(o2Point, pulsePoint, _linePaint);
    }
  }

  void _drawRangePoint(
    Canvas canvas,
    double x,
    Offset o2Point,
    Offset o2MinPoint,
    Offset o2MaxPoint,
    Offset? pulsePoint,
    Offset? pulseMinPoint,
    Offset? pulseMaxPoint,
    O2SaturationChartStyle style,
    double animationValue,
    ProcessedO2SaturationData data,
  ) {
    // Draw O2 range line
    // Commented out to hide range lines
    // _linePaint
    //   ..color = style.primaryColor.withOpacity(0.7 * animationValue)
    //   ..strokeWidth = 2.0;
    // canvas.drawLine(o2MinPoint, o2MaxPoint, _linePaint);

    // Draw O2 point (keep this to show the main data point)
    _drawDataPoint(
        canvas, o2Point, style.primaryColor, style.pointRadius, animationValue);

    // Draw min/max end caps for O2
    // Commented out to hide range indicators
    // _fillPaint
    //   ..color = style.primaryColor.withOpacity(0.7 * animationValue)
    //   ..style = PaintingStyle.fill;
    // canvas.drawCircle(o2MinPoint, style.pointRadius * 0.7, _fillPaint);
    // canvas.drawCircle(o2MaxPoint, style.pointRadius * 0.7, _fillPaint);

    // Draw pulse rate data if available
    if (pulsePoint != null) {
      // Draw pulse point
      _drawDataPoint(canvas, pulsePoint, style.pulseRateColor,
          style.pointRadius, animationValue);

      // Comment out pulse range display
      // if (pulseMinPoint != null && pulseMaxPoint != null) {
      //   // Draw pulse range line
      //   _linePaint
      //     ..color = style.pulseRateColor.withOpacity(0.7 * animationValue)
      //     ..strokeWidth = 2.0;
      //   canvas.drawLine(pulseMinPoint, pulseMaxPoint, _linePaint);
      //
      //   // Draw min/max end caps for pulse
      //   _fillPaint
      //     ..color = style.pulseRateColor.withOpacity(0.7 * animationValue)
      //     ..style = PaintingStyle.fill;
      //   canvas.drawCircle(pulseMinPoint, style.pointRadius * 0.7, _fillPaint);
      //   canvas.drawCircle(pulseMaxPoint, style.pointRadius * 0.7, _fillPaint);
      // }

      // Optional: Keep or comment out the connecting line between O2 and pulse
      // Comment this out if you want to remove the connecting line
      _linePaint
        ..color = Colors.grey.withOpacity(0.3 * animationValue)
        ..strokeWidth = 1.0;
      canvas.drawLine(o2Point, pulsePoint, _linePaint);
    }
  }

  void _drawDataPoint(
    Canvas canvas,
    Offset position,
    Color color,
    double radius,
    double animationValue,
  ) {
    final animatedRadius = radius * animationValue;

    // Outer circle with slight glow
    _fillPaint
      ..color = color.withOpacity(0.3 * animationValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(position, animatedRadius * 1.5, _fillPaint);
    _fillPaint.maskFilter = null;

    // Main circle
    _fillPaint
      ..color = color.withOpacity(0.9 * animationValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, animatedRadius, _fillPaint);

    // Highlight effect (3D look)
    _fillPaint..color = Colors.white.withOpacity(0.7 * animationValue);
    final highlightPos = Offset(
        position.dx - animatedRadius * 0.3, position.dy - animatedRadius * 0.3);
    canvas.drawCircle(highlightPos, animatedRadius * 0.4, _fillPaint);

    // Outline
    _linePaint
      ..color = Colors.white.withOpacity(0.7 * animationValue)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, animatedRadius, _linePaint);
  }

  void _drawReadingCount(
    Canvas canvas,
    Offset position,
    int count,
    O2SaturationChartStyle style,
    double animationValue,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: style.effectiveCountLabelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRadius = max(textPainter.width, textPainter.height) * 0.7;
    final badgeCenter = Offset(
      position.dx + style.pointRadius * 2,
      position.dy - style.pointRadius * 2,
    );

    // Draw badge background
    _fillPaint
      ..color = style.primaryColor.withOpacity(animationValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, _fillPaint);

    // Draw count text
    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  // Calculate animation value for smooth sequential animation
  double _calculateAnimationValue(
      int index, int totalPoints, Animation<double> animation) {
    // Progressive animation with delay proportional to index
    final delay = index / (totalPoints * 1.5);
    final duration = 1.0 / totalPoints;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    // Ease-out cubic for smoother finish
    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return 1.0 - pow(1.0 - t, 3);
  }

  // Helper method for calculating X position
  double _calculateXPosition(int index, int totalPoints, Rect chartArea) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0; // Padding at edges
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  // Helper method to calculate Y position based on value
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
