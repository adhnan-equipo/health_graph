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

    // Draw background
    canvas.save();
    canvas.clipRect(chartArea);
    _backgroundDrawer.drawBackground(canvas, chartArea);

    // Draw grid
    if (config.showGrid) {
      _gridDrawer.drawGrid(
        canvas,
        chartArea,
        yAxisValues,
        minValue,
        maxValue,
        animation.value,
      );
    }

    // Draw goal line if enabled
    if (style.showGoalLine) {
      _drawGoalLine(canvas);
    }

    // Draw activity zones
    _drawActivityZones(canvas);

    canvas.restore();

    // Draw labels
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

    // Draw the hybrid chart
    canvas.save();
    canvas.clipRect(chartArea);

    _drawBars(canvas);
    _drawTrendLine(canvas);
    _drawDataPoints(canvas);
    _drawAnnotations(canvas);

    canvas.restore();
  }

  void _drawBars(Canvas canvas) {
    if (data.isEmpty) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      // Use display value instead of total steps
      final stepValue = entry.displayValue.toDouble();
      final barHeight = _getBarHeight(stepValue);

      final x = chartArea.left + barPadding + (i * (barWidth + barPadding));
      final y = chartArea.bottom - barHeight * _safeAnimationValue;

      final barRect =
          Rect.fromLTWH(x, y, barWidth, barHeight * _safeAnimationValue);

      // Create gradient paint for bars
      final barPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, y),
          Offset(x, y + barHeight * _safeAnimationValue),
          [
            style.barGradientStartColor.withOpacity(_safeAnimationValue),
            style.barGradientEndColor.withOpacity(_safeAnimationValue),
          ],
        );

      // Draw rounded rectangle bar
      final barRRect = RRect.fromRectAndRadius(
        barRect,
        Radius.circular(style.barBorderRadius),
      );

      canvas.drawRRect(barRRect, barPaint);

      // Draw border if specified
      if (style.barBorderWidth > 0) {
        final borderPaint = Paint()
          ..color = style.barBorderColor.withOpacity(_safeAnimationValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.barBorderWidth;

        canvas.drawRRect(barRRect, borderPaint);
      }

      // Goal achievement indicator
      if (entry.isGoalAchieved) {
        _drawGoalAchievementIndicator(canvas, barRect, entry);
      }

      // Selection highlight
      if (entry == selectedData) {
        _drawSelectionHighlight(canvas, barRect);
      }
    }
  }

  void _drawTrendLine(Canvas canvas) {
    if (data.length < 2) return;

    final path = Path();
    final points = <Offset>[];

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth =
        (availableWidth - (barPadding * (data.length - 1))) / data.length;

    // Calculate line points (center of bars)
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

    // Create smooth curve through points
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      if (i == 1) {
        // Simple line to second point
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        // Smooth curve for subsequent points
        final p1 = points[i - 1];
        final p2 = points[i];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.3, p1.dy);
        final controlPoint2 = Offset(p2.dx - (p2.dx - p1.dx) * 0.3, p2.dy);

        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, p2.dx, p2.dy);
      }
    }

    // Create gradient paint for line
    final linePaint = Paint()
      ..color = style.lineColor.withOpacity(_safeAnimationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the trend line with animation
    final animatedPath = _animatePath(path, _safeAnimationValue);
    canvas.drawPath(animatedPath, linePaint);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = style.lineColor.withOpacity(0.3 * _safeAnimationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineThickness + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(animatedPath, glowPaint);
  }

  void _drawDataPoints(Canvas canvas) {
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
    // Ensure animation value is safe
    final safeAnimValue = animationValue.clamp(0.0, 1.0);

    final baseRadius =
        isLatestPoint ? style.pointRadius * 1.5 : style.pointRadius;
    final radius = baseRadius * safeAnimValue;
    final effectiveRadius = isSelected ? radius * 1.3 : radius;

    // Get color based on step category
    Color pointColor = style.getCategoryColor(entry.category);

    // Glow effect for latest point
    if (isLatestPoint && safeAnimValue > 0.5) {
      final pulseScale = 1.0 + (sin(safeAnimValue * 6) * 0.15).abs();
      final pulseRadius = effectiveRadius * pulseScale;

      final glowPaint = Paint()
        ..color = pointColor.withOpacity((0.3 * safeAnimValue).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(position, pulseRadius * 1.5, glowPaint);
    }

    // Main point with solid color (avoid gradient issues)
    final pointPaint = Paint()
      ..color = pointColor.withOpacity((0.9 * safeAnimValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, effectiveRadius, pointPaint);

    // Border
    if (style.pointBorderWidth > 0) {
      final borderPaint = Paint()
        ..color = style.pointBorderColor
            .withOpacity((0.9 * safeAnimValue).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.pointBorderWidth;

      canvas.drawCircle(position, effectiveRadius * 0.9, borderPaint);
    }

    // Highlight for 3D effect
    if (safeAnimValue > 0.3) {
      final highlightOffset = Offset(
        position.dx - effectiveRadius * 0.3,
        position.dy - effectiveRadius * 0.3,
      );

      final highlightPaint = Paint()
        ..color =
            Colors.white.withOpacity((0.6 * safeAnimValue).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          highlightOffset, effectiveRadius * 0.25, highlightPaint);
    }
  }

  void _drawGoalLine(Canvas canvas) {
    final goalY = _getYPosition(StepRange.recommendedDaily.toDouble());

    final goalPaint = Paint()
      ..color = style.goalLineColor
          .withOpacity((0.8 * _safeAnimationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.goalLineWidth
      ..strokeCap = StrokeCap.round;

    // Draw dashed line
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    var startX = chartArea.left;
    while (startX < chartArea.right) {
      final endX = (startX + dashWidth).clamp(chartArea.left, chartArea.right);
      canvas.drawLine(
        Offset(startX, goalY),
        Offset(endX, goalY),
        goalPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Goal label
    if (_safeAnimationValue > 0.5) {
      _drawGoalLabel(canvas, goalY);
    }
  }

  void _drawGoalLabel(Canvas canvas, double goalY) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: style.goalLabel,
        style: style.defaultValueDisplayStyle.copyWith(
          color: style.pointBorderColor.withOpacity(_safeAnimationValue),
          fontSize: 10,
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
      ..color = style.goalBackgroundColor.withOpacity(_safeAnimationValue)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  void _drawActivityZones(Canvas canvas) {
    // Draw subtle background zones for activity levels
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

    for (final (value, color, label) in zones) {
      if (previousValue >= maxValue) break;

      final startY = _getYPosition(min(value, maxValue));
      final endY = _getYPosition(previousValue);

      if ((endY - startY).abs() > 10) {
        final zonePaint = Paint()
          ..color =
              color.withOpacity((0.05 * _safeAnimationValue).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;

        final zoneRect = Rect.fromLTRB(
          chartArea.left,
          startY,
          chartArea.right,
          endY,
        );

        canvas.drawRect(zoneRect, zonePaint);
      }

      previousValue = value;
    }
  }

  void _drawGoalAchievementIndicator(
      Canvas canvas, Rect barRect, ProcessedStepData entry) {
    final indicatorPaint = Paint()
      ..color = style.goalAchievedColor
          .withOpacity((0.8 * _safeAnimationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final indicatorSize = 6.0 * _safeAnimationValue;
    final indicatorCenter = Offset(
      barRect.center.dx,
      barRect.top - indicatorSize - 4,
    );

    // Draw simple circle for goal achievement
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
          color: style.annotationTextColor.withOpacity(_safeAnimationValue),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = Rect.fromCenter(
      center: Offset(position.dx, position.dy - 20),
      width: textPainter.width + 12,
      height: textPainter.height + 8,
    );

    final backgroundPaint = Paint()
      ..color = style.annotationBackgroundColor
          .withOpacity((0.9 * _safeAnimationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          labelRect, Radius.circular(style.annotationBorderRadius)),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        labelRect.left + 6,
        labelRect.top + 4,
      ),
    );
  }

  void _drawSelectionHighlight(Canvas canvas, Rect barRect) {
    final highlightPaint = Paint()
      ..color = style.highlightColor.withOpacity(_safeAnimationValue)
      ..style = PaintingStyle.fill;

    final highlightRect = barRect.inflate(2);
    final highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.circular(style.barBorderRadius + 2),
    );

    canvas.drawRRect(highlightRRect, highlightPaint);
  }

  // Helper methods
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

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor
          .withOpacity((0.1 * _safeAnimationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw animated grid pattern
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * _safeAnimationValue).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * _safeAnimationValue).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
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
