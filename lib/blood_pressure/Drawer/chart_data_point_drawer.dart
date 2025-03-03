// Updated ChartDataPointDrawer with improved plotting
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';
import '../services/chart_calculations.dart';
import '../styles/blood_pressure_chart_style.dart';

class ChartDataPointDrawer {
  // Reuse paint objects for better performance
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  int? _lastSelectedIndex;
  // Cache for performance optimization
  final Map<int, Offset> _pointPositionCache = {};
  String _lastDataHash = '';
  Path? _systolicPath;
  Path? _diastolicPath;

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

    // Find selected index
    int? selectedIndex;
    if (selectedData != null) {
      selectedIndex = data.indexWhere((d) =>
          d.startDate == selectedData.startDate &&
          d.endDate == selectedData.endDate);
    }

    // Only rebuild paths if data changes or selection changes
    final currentHash =
        '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}_${selectedIndex ?? -1}';
    if (currentHash != _lastDataHash) {
      _lastDataHash = currentHash;
      _buildPaths(chartArea, data, minValue, maxValue);
      _lastSelectedIndex = selectedIndex;
    }

    // Only draw selection highlight if needed
    if (selectedIndex != null && selectedIndex >= 0) {
      final x = ChartCalculations.calculateXPosition(
          selectedIndex, data.length, chartArea);
      _drawYAxisHighlight(canvas, x, chartArea, style, animation.value);
    }

    // Draw trend lines
    _drawTrendLines(
        canvas, chartArea, data, style, animation, minValue, maxValue);

    // Draw data points - we can optimize this by only redrawing points that need updating
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

        final isSelected = selectedIndex == i;
        final animationValue =
            _calculateAnimationValue(i, data.length, animation);

        // Draw the point based on type
        if (entry.dataPointCount == 1) {
          _drawSinglePoint(
              canvas, positions, style, animationValue, isSelected);
        } else {
          _drawRangePoint(canvas, positions, style, animationValue, isSelected);
        }
      }
    }
  }

  // Enhanced method to highlight the entire y-axis
  void _drawYAxisHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    BloodPressureChartStyle style,
    double animationValue,
  ) {
    // Create subtle pulsing effect
    final pulseValue = 0.85 + 0.15 * sin(animationValue * 4);

    // Draw vertical line that spans the entire height
    _linePaint
      ..color = style.selectedHighlightColor.withOpacity(0.7 * pulseValue)
      ..strokeWidth = 2.5;

    // Draw main y-axis line from top to bottom of chart area
    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      _linePaint,
    );

    // Add glow effect to make the y-axis more visible
    _fillPaint
      ..color = style.selectedHighlightColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw a rectangle along the y-axis with blur for glow effect
    final highlightRect =
        Rect.fromLTRB(x - 1, chartArea.top, x + 1, chartArea.bottom);
    canvas.drawRect(highlightRect, _fillPaint);
    _fillPaint.maskFilter = null;

    // Add subtle gradient background to highlight selected column
    final gradientRect = Rect.fromLTRB(
      x - 25,
      chartArea.top,
      x + 25,
      chartArea.bottom,
    );

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        style.selectedHighlightColor.withOpacity(0),
        style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
        style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
        style.selectedHighlightColor.withOpacity(0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    _fillPaint
      ..shader = gradient.createShader(gradientRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(gradientRect, _fillPaint);
    _fillPaint.shader = null;

    // Draw dots along y-axis for visual interest
    _fillPaint
      ..color = style.selectedHighlightColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw dots with varying sizes along the y-axis
    final numDots = 8;
    final dotSpacing = chartArea.height / (numDots + 1);

    for (int i = 1; i <= numDots; i++) {
      // Animate dots along the line
      final y = chartArea.top + (dotSpacing * i);

      // Vary dot size based on position and animation
      final dotSize = 1.5 + 1.0 * sin(animationValue * 3 + i * 0.7);
      canvas.drawCircle(
        Offset(x, y),
        dotSize * pulseValue,
        _fillPaint,
      );
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

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);

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

      if (isFirstValid) {
        _systolicPath!.moveTo(x, systolicY);
        _diastolicPath!.moveTo(x, diastolicY);
        isFirstValid = false;
      } else {
        _systolicPath!.lineTo(x, systolicY);
        _diastolicPath!.lineTo(x, diastolicY);
      }
    }
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
    if (_systolicPath == null || _diastolicPath == null) return;

    // Draw systolic trend line with animation
    _linePaint
      ..color = style.systolicColor.withOpacity(0.3 * animation.value)
      ..strokeWidth = 1.5;
    canvas.drawPath(_systolicPath!, _linePaint);

    // Draw diastolic trend line with animation
    _linePaint
      ..color = style.diastolicColor.withOpacity(0.3 * animation.value)
      ..strokeWidth = 1.5;
    canvas.drawPath(_diastolicPath!, _linePaint);
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
    // Draw connecting line with increased opacity for selected points
    if (isSelected) {
      _linePaint
        ..color = style.connectorColor.withOpacity(0.6 * animationValue)
        ..strokeWidth = style.lineThickness;
      canvas.drawLine(
          positions.maxSystolicPoint, positions.maxDiastolicPoint, _linePaint);
    }

    // Draw points with enhanced visibility for selected state
    _drawAnimatedPoint(
      canvas,
      positions.maxSystolicPoint,
      style.systolicColor,
      style.pointRadius * (isSelected ? 1.3 : 1.0),
      animationValue,
      isSelected,
      style,
    );

    _drawAnimatedPoint(
      canvas,
      positions.maxDiastolicPoint,
      style.diastolicColor,
      style.pointRadius * (isSelected ? 1.3 : 1.0),
      animationValue,
      isSelected,
      style,
    );
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
    final rangeWidth = style.lineThickness * (isSelected ? 3.5 : 3.0);

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
    _linePaint
      ..color = color.withOpacity(isSelected ? 0.8 : 0.4)
      ..strokeWidth = width;
    canvas.drawLine(animatedStart, animatedEnd, _linePaint);

    // Draw inner line for hollow effect
    if (!isSelected) {
      _linePaint
        ..color = color.withOpacity(0.6)
        ..strokeWidth = width * 0.6;
      canvas.drawLine(animatedStart, animatedEnd, _linePaint);
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
    // Enhanced radius for selected points
    final baseRadius = radius * (isSelected ? 1.3 : 1.0);
    final animatedRadius = baseRadius * animationValue;

    // Draw glow effect for selected points
    if (isSelected) {
      _fillPaint
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(position, animatedRadius * 1.8, _fillPaint);
      _fillPaint.maskFilter = null;
    }

    // Draw outer circle with smooth animation
    _dataPointPaint
      ..color = color.withOpacity(0.9 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.8;
    canvas.drawCircle(position, animatedRadius, _dataPointPaint);

    // Fill circle with more opacity for selected points
    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(
          isSelected ? 0.8 * animationValue : 0.5 * animationValue);
    canvas.drawCircle(
        position, animatedRadius - (isSelected ? 1.0 : 1.5), _dataPointPaint);
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
