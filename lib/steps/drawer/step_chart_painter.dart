// lib/steps/drawer/step_chart_painter.dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/processed_step_data.dart';
import '../models/step_range.dart';
import '../styles/step_chart_style.dart';
import 'step_background_drawer.dart';
import 'step_grid_drawer.dart';
import 'step_label_drawer.dart';

class StepChartPainter extends CustomPainter {
  final List<ProcessedStepData> data;
  final StepChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedStepData? selectedData;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  late final StepBackgroundDrawer _backgroundDrawer = StepBackgroundDrawer();
  late final StepGridDrawer _gridDrawer = StepGridDrawer();
  late final StepLabelDrawer _labelDrawer = StepLabelDrawer();

  StepChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
    this.selectedData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Draw background with subtle gradient for low values
    canvas.save();
    canvas.clipRect(chartArea);
    _drawEnhancedBackground(canvas);

    // Draw enhanced grid for better low-value visibility
    if (config.showGrid) {
      _drawEnhancedGrid(canvas);
    }

    // Draw goal line with smart positioning
    _drawSmartGoalLine(canvas);

    // Draw activity zones with low-value awareness
    _drawEnhancedActivityZones(canvas);

    canvas.restore();

    // Draw enhanced labels
    _drawEnhancedLabels(canvas);

    // Draw the hybrid chart with low-value optimizations
    canvas.save();
    canvas.clipRect(chartArea);

    _drawEnhancedBars(canvas);
    _drawEnhancedTrendLine(canvas);
    _drawEnhancedDataPoints(canvas);
    _drawValueLabels(canvas); // NEW: Always show value labels for low values
    _drawAnnotations(canvas);

    canvas.restore();
  }

  void _drawEnhancedBackground(Canvas canvas) {
    // Create subtle gradient background for better contrast with low values
    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chartArea.left, chartArea.top),
        Offset(chartArea.left, chartArea.bottom),
        [
          style.backgroundColor.withOpacity(0.02),
          style.surfaceColor.withOpacity(0.05),
        ],
      );

    canvas.drawRect(chartArea, backgroundPaint);
  }

  void _drawEnhancedGrid(Canvas canvas) {
    _gridDrawer.drawGrid(
      canvas,
      chartArea,
      yAxisValues,
      minValue,
      maxValue,
      animation.value,
    );

    // Add extra grid lines for very low values to improve readability
    if (_isLowValueRange()) {
      _drawAdditionalGridLines(canvas);
    }
  }

  void _drawAdditionalGridLines(Canvas canvas) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.3 * animation.value)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Add intermediate grid lines for better granularity
    for (int i = 0; i < yAxisValues.length - 1; i++) {
      final currentValue = yAxisValues[i];
      final nextValue = yAxisValues[i + 1];
      final midValue = (currentValue + nextValue) / 2;

      final y = _getYPosition(midValue);
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );
    }
  }

  void _drawSmartGoalLine(Canvas canvas) {
    if (!style.showGoalLine) return;

    final goalValue = StepRange.recommendedDaily.toDouble();
    final maxDisplayValue =
        data.isEmpty ? 0 : data.map((d) => d.displayValue).reduce(max);

    // Smart goal line positioning
    if (goalValue > maxValue * 1.1) {
      // Goal is way above current range - show it at the top with special styling
      _drawOffScaleGoalLine(canvas, maxDisplayValue);
    } else {
      // Goal is within or near range - show normally
      _drawNormalGoalLine(canvas, goalValue);
    }
  }

  void _drawOffScaleGoalLine(Canvas canvas, int maxDisplayValue) {
    final topPosition = chartArea.top + 15;

    // Draw line
    final goalPaint = Paint()
      ..color = style.pointBorderColor.withValues(alpha: 0.9 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.goalLineWidth
      ..strokeCap = StrokeCap.round;

    // Dashed line pattern
    _drawDashedLine(
      canvas,
      Offset(chartArea.left, topPosition),
      Offset(chartArea.right, topPosition),
      goalPaint,
    );

    // Enhanced goal label showing distance to goal
    if (animation.value > 0.5) {
      _drawOffScaleGoalLabel(canvas, topPosition, maxDisplayValue);
    }
  }

  void _drawNormalGoalLine(Canvas canvas, double goalValue) {
    final goalY = _getYPosition(goalValue);

    final goalPaint = Paint()
      ..color = style.pointBorderColor.withOpacity(0.8 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.goalLineWidth
      ..strokeCap = StrokeCap.round;

    // Draw dashed line
    _drawDashedLine(
      canvas,
      Offset(chartArea.left, goalY),
      Offset(chartArea.right, goalY),
      goalPaint,
    );

    // Goal label
    if (animation.value > 0.5) {
      _drawNormalGoalLabel(canvas, goalY);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    var currentX = start.dx;
    while (currentX < end.dx) {
      final dashEnd = (currentX + dashWidth).clamp(start.dx, end.dx);
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(dashEnd, start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawOffScaleGoalLabel(Canvas canvas, double yPosition, int maxValue) {
    final remaining = StepRange.recommendedDaily - maxValue;
    final text =
        '🎯 Goal: ${_formatStepValue(StepRange.recommendedDaily)} (${_formatStepValue(remaining)} to go)';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.defaultValueDisplayStyle.copyWith(
          color: style.pointBorderColor.withOpacity(animation.value),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Background with rounded corners
    final backgroundRect = Rect.fromLTWH(
      chartArea.right - textPainter.width - 12,
      yPosition - textPainter.height - 4,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = style.goalBackgroundColor.withOpacity(0.9 * animation.value)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(6)),
      backgroundPaint,
    );

    textPainter.paint(
        canvas,
        Offset(
          backgroundRect.left + 4,
          backgroundRect.top + 2,
        ));
  }

  void _drawNormalGoalLabel(Canvas canvas, double goalY) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🎯 ${style.goalLabel}',
        style: style.defaultValueDisplayStyle.copyWith(
          color: style.pointBorderColor.withOpacity(animation.value),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelX = chartArea.right - textPainter.width - 8;
    final labelY = goalY - textPainter.height - 4;

    // Background
    final backgroundRect = Rect.fromLTWH(
      labelX - 4,
      labelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = style.goalBackgroundColor.withOpacity(0.9 * animation.value)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  void _drawEnhancedBars(Canvas canvas) {
    if (data.isEmpty) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final stepValue = entry.displayValue.toDouble();
      final barHeight = _getBarHeight(stepValue);

      final x = chartArea.left + barPadding + (i * (barWidth + barPadding));
      final y = chartArea.bottom - barHeight * animation.value;

      final barRect =
          Rect.fromLTWH(x, y, barWidth, barHeight * animation.value);

      // Enhanced bar rendering for low values
      _drawEnhancedBar(canvas, barRect, entry, stepValue);

      // Selection highlight
      if (entry == selectedData) {
        _drawSelectionHighlight(canvas, barRect);
      }
    }
  }

  void _drawEnhancedBar(
      Canvas canvas, Rect barRect, ProcessedStepData entry, double stepValue) {
    // Enhanced gradient based on value magnitude
    final intensity = _calculateBarIntensity(stepValue);
    final categoryColor = style.getCategoryColor(entry.category);

    final barPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(barRect.left, barRect.top),
        Offset(barRect.left, barRect.bottom),
        [
          categoryColor.withOpacity(0.3 + (intensity * 0.4)),
          categoryColor.withOpacity(0.7 + (intensity * 0.3)),
        ],
      );

    // Draw rounded rectangle bar with enhanced styling
    final barRRect = RRect.fromRectAndRadius(
      barRect,
      Radius.circular(style.barBorderRadius),
    );

    canvas.drawRRect(barRRect, barPaint);

    // Enhanced border for better definition
    if (style.barBorderWidth > 0) {
      final borderPaint = Paint()
        ..color = categoryColor.withOpacity(0.8 * animation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.barBorderWidth + (_isLowValueRange() ? 0.5 : 0);

      canvas.drawRRect(barRRect, borderPaint);
    }

    // Goal achievement indicator
    if (entry.isGoalAchieved) {
      _drawGoalAchievementIndicator(canvas, barRect, entry);
    }

    // Low value highlight (make small bars more visible)
    if (stepValue < 1000) {
      _drawLowValueHighlight(canvas, barRect, categoryColor);
    }
  }

  void _drawLowValueHighlight(Canvas canvas, Rect barRect, Color baseColor) {
    final highlightPaint = Paint()
      ..color = baseColor.withOpacity(0.3 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final highlightRect = barRect.inflate(1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        highlightRect,
        Radius.circular(style.barBorderRadius + 1),
      ),
      highlightPaint,
    );
  }

  double _calculateBarIntensity(double stepValue) {
    // Calculate intensity based on step value for better visual contrast
    if (stepValue < 500) return 0.3;
    if (stepValue < 2000) return 0.5;
    if (stepValue < 5000) return 0.7;
    return 1.0;
  }

  void _drawValueLabels(Canvas canvas) {
    // Always show value labels for low values to ensure visibility
    if (!_shouldShowValueLabels()) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final stepValue = entry.displayValue.toDouble();
      final barHeight = _getBarHeight(stepValue);
      final y = chartArea.bottom - barHeight * animation.value;

      _drawValueLabel(canvas, Offset(x, y - 8), entry.displayValue);
    }
  }

  void _drawValueLabel(Canvas canvas, Offset position, int value) {
    final text = _formatStepValue(value);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: style.primaryColor.withOpacity(animation.value),
          fontSize: _isLowValueRange() ? 11 : 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 2,
              color: Colors.white.withOpacity(0.8),
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
      position.dy - textPainter.height,
    );

    textPainter.paint(canvas, labelPosition);
  }

  bool _shouldShowValueLabels() {
    // Show value labels for low values or when explicitly enabled
    return _isLowValueRange() || data.length <= 8;
  }

  String _formatStepValue(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  bool _isLowValueRange() {
    return maxValue <= 2000;
  }

  // Rest of the enhanced methods...
  void _drawEnhancedTrendLine(Canvas canvas) {
    if (data.length < 2) return;

    final path = Path();
    final points = <Offset>[];

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth =
        (availableWidth - (barPadding * (data.length - 1))) / data.length;

    // Calculate line points with enhanced precision for low values
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final stepValue = entry.displayValue.toDouble();
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final y = _getYPosition(stepValue);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Create smooth curve with enhanced visibility for low values
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      if (i == 1) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final p1 = points[i - 1];
        final p2 = points[i];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.3, p1.dy);
        final controlPoint2 = Offset(p2.dx - (p2.dx - p1.dx) * 0.3, p2.dy);

        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, p2.dx, p2.dy);
      }
    }

    // Enhanced line paint for low values
    final lineThickness =
        _isLowValueRange() ? style.lineThickness + 1 : style.lineThickness;
    final linePaint = Paint()
      ..color = style.lineColor.withOpacity(animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final animatedPath = _animatePath(path, animation.value);
    canvas.drawPath(animatedPath, linePaint);

    // Enhanced glow effect for better visibility
    final glowPaint = Paint()
      ..color = style.lineColor.withOpacity(0.4 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineThickness + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(animatedPath, glowPaint);
  }

  void _drawEnhancedDataPoints(Canvas canvas) {
    if (data.isEmpty) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth =
        (availableWidth - (barPadding * (data.length - 1))) / data.length;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final stepValue = entry.displayValue.toDouble();
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final y = _getYPosition(stepValue);

      final position = Offset(x, y);
      final pointAnimationValue =
          _calculatePointAnimation(i, data.length, animation);

      _drawEnhancedDataPoint(
        canvas,
        position,
        entry,
        pointAnimationValue,
        entry == selectedData,
        i == data.length - 1,
      );
    }
  }

  void _drawEnhancedDataPoint(
    Canvas canvas,
    Offset position,
    ProcessedStepData entry,
    double animationValue,
    bool isSelected,
    bool isLatestPoint,
  ) {
    final safeAnimValue = animationValue.clamp(0.0, 1.0);

    // Enhanced radius for low values
    final baseRadius = _isLowValueRange()
        ? (isLatestPoint ? style.pointRadius * 2.2 : style.pointRadius * 1.3)
        : (isLatestPoint ? style.pointRadius * 1.5 : style.pointRadius);

    final radius = baseRadius * safeAnimValue;
    final effectiveRadius = isSelected ? radius * 1.3 : radius;

    final pointColor = style.getCategoryColor(entry.category);

    // Enhanced glow for latest point with low values
    if (isLatestPoint && safeAnimValue > 0.5) {
      final pulseScale = 1.0 + (sin(safeAnimValue * 6) * 0.2).abs();
      final pulseRadius = effectiveRadius * pulseScale;

      final glowPaint = Paint()
        ..color = pointColor.withOpacity(0.4 * safeAnimValue)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(position, pulseRadius * 1.8, glowPaint);
    }

    // Main point with enhanced visibility
    final pointPaint = Paint()
      ..color = pointColor.withOpacity(0.9 * safeAnimValue)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, effectiveRadius, pointPaint);

    // Enhanced border for low values
    if (style.pointBorderWidth > 0) {
      final borderWidth = _isLowValueRange()
          ? style.pointBorderWidth + 0.5
          : style.pointBorderWidth;
      final borderPaint = Paint()
        ..color = style.pointBorderColor.withOpacity(0.9 * safeAnimValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;

      canvas.drawCircle(position, effectiveRadius * 0.9, borderPaint);
    }

    // Enhanced highlight for 3D effect
    if (safeAnimValue > 0.3) {
      final highlightOffset = Offset(
        position.dx - effectiveRadius * 0.3,
        position.dy - effectiveRadius * 0.3,
      );

      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * safeAnimValue)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(highlightOffset, effectiveRadius * 0.3, highlightPaint);
    }
  }

  void _drawEnhancedActivityZones(Canvas canvas) {
    // Enhanced activity zones with better visibility for low values
    final zones = [
      (StepRange.sedentaryMax.toDouble(), style.sedentaryColor, 'Sedentary'),
      (StepRange.lightActiveMax.toDouble(), style.lightActiveColor, 'Light'),
      (
        StepRange.fairlyActiveMax.toDouble(),
        style.fairlyActiveColor,
        'Moderate'
      ),
      (StepRange.veryActiveMax.toDouble(), style.veryActiveColor, 'Active'),
      (maxValue, style.highlyActiveColor, 'Very Active'),
    ];

    var previousValue = minValue;
    final zoneOpacity = _isLowValueRange() ? 0.08 : 0.05;

    for (final (value, color, label) in zones) {
      if (previousValue >= maxValue) break;

      final startY = _getYPosition(min(value, maxValue));
      final endY = _getYPosition(previousValue);

      if ((endY - startY).abs() > 5) {
        // Lowered threshold for better low-value visibility
        final zonePaint = Paint()
          ..color = color.withOpacity(zoneOpacity * animation.value)
          ..style = PaintingStyle.fill;

        final zoneRect =
            Rect.fromLTRB(chartArea.left, startY, chartArea.right, endY);
        canvas.drawRect(zoneRect, zonePaint);

        // Add zone labels for low value ranges
        if (_isLowValueRange() && previousValue < maxValue * 0.8) {
          _drawZoneLabel(canvas, zoneRect, label, color);
        }
      }

      previousValue = value;
    }
  }

  void _drawZoneLabel(Canvas canvas, Rect zoneRect, String label, Color color) {
    if (zoneRect.height < 20) return; // Skip if too small

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withOpacity(0.4 * animation.value),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelPosition = Offset(
      chartArea.right - textPainter.width - 8,
      zoneRect.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, labelPosition);
  }

  void _drawEnhancedLabels(Canvas canvas) {
    _labelDrawer.drawSideLabels(
      canvas,
      chartArea,
      yAxisValues,
      style.gridLabelStyle ?? style.defaultGridLabelStyle,
      animation.value,
    );

    _labelDrawer.drawBottomLabels(
      canvas,
      chartArea,
      data,
      config.viewType,
      style,
      animation.value,
    );
  }

  // Helper methods remain largely the same but with enhanced calculations
  double get _safeAnimationValue => animation.value.clamp(0.0, 1.0);

  double _getBarHeight(double stepValue) {
    if (maxValue <= minValue) return 0;
    final normalizedValue = (stepValue - minValue) / (maxValue - minValue);
    return normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  double _getYPosition(double value) {
    if (maxValue <= minValue) return chartArea.bottom;
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    return chartArea.bottom -
        normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  double _calculatePointAnimation(
      int index, int totalPoints, Animation<double> animation) {
    final delay = index / (totalPoints * 2.0);
    final duration = 0.6;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t);
  }

  Path _animatePath(Path originalPath, double animationValue) {
    final pathMetrics = originalPath.computeMetrics();
    final animatedPath = Path();

    for (final pathMetric in pathMetrics) {
      final extractedPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * animationValue.clamp(0.0, 1.0),
      );
      animatedPath.addPath(extractedPath, Offset.zero);
    }

    return animatedPath;
  }

  // Rest of existing methods...
  void _drawGoalAchievementIndicator(
      Canvas canvas, Rect barRect, ProcessedStepData entry) {
    final indicatorPaint = Paint()
      ..color = style.goalAchievedColor.withOpacity(0.8 * animation.value)
      ..style = PaintingStyle.fill;

    final indicatorSize = 6.0 * animation.value;
    final indicatorCenter = Offset(
      barRect.center.dx,
      barRect.top - indicatorSize - 4,
    );

    canvas.drawCircle(indicatorCenter, indicatorSize, indicatorPaint);
  }

  void _drawAnnotations(Canvas canvas) {
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (!entry.hasAnnotation) continue;

      const barPadding = 8.0;
      final availableWidth = chartArea.width - (barPadding * 2);
      final barWidth =
          (availableWidth - (barPadding * (data.length - 1))) / data.length;

      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final stepValue = entry.displayValue.toDouble();
      final y = _getYPosition(stepValue);

      _drawAnnotationLabel(canvas, Offset(x, y), entry.annotationText);
    }
  }

  void _drawAnnotationLabel(Canvas canvas, Offset position, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: (style.annotationLabelStyle ?? style.defaultAnnotationLabelStyle)
            .copyWith(
          color: style.annotationTextColor.withOpacity(animation.value),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromCenter(
      center: Offset(position.dx, position.dy - 25),
      width: textPainter.width + 12,
      height: textPainter.height + 8,
    );

    final backgroundPaint = Paint()
      ..color =
          style.annotationBackgroundColor.withOpacity(0.9 * animation.value)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          labelRect, Radius.circular(style.annotationBorderRadius)),
      backgroundPaint,
    );

    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 4));
  }

  void _drawSelectionHighlight(Canvas canvas, Rect barRect) {
    final highlightPaint = Paint()
      ..color = style.highlightColor.withOpacity(animation.value)
      ..style = PaintingStyle.fill;

    final highlightRect = barRect.inflate(2);
    final highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.circular(style.barBorderRadius + 2),
    );

    canvas.drawRRect(highlightRRect, highlightPaint);
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * progress), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant StepChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        style != oldDelegate.style ||
        config != oldDelegate.config ||
        selectedData != oldDelegate.selectedData ||
        animation.value != oldDelegate.animation.value ||
        chartArea != oldDelegate.chartArea ||
        yAxisValues != oldDelegate.yAxisValues ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
