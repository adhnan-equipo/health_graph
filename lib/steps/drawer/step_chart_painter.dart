// lib/steps/drawer/step_chart_painter.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/processed_step_data.dart';
import '../styles/step_chart_style.dart';
import 'step_background_drawer.dart';
import 'step_data_point_drawer.dart';
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
  late final StepDataPointDrawer _dataPointDrawer = StepDataPointDrawer();

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

    // Draw background and grid
    canvas.save();
    canvas.clipRect(chartArea);

    _backgroundDrawer.drawBackground(canvas, chartArea);

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

    // Draw step range indicators
    _drawStepRanges(canvas);

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

    // Draw data points and trend line
    canvas.save();
    canvas.clipRect(chartArea);

    _dataPointDrawer.drawDataPoints(
      canvas,
      chartArea,
      data,
      style,
      animation,
      selectedData,
      minValue,
      maxValue,
    );

    canvas.restore();
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withValues(alpha: 0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw animated grid pattern
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
    }
  }

  void _drawStepRanges(Canvas canvas) {
    final rangePaint = Paint()..style = PaintingStyle.fill;
    final labelStyle = TextStyle(
      color: Colors.black54,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Calculate visible range
    final visibleMin = minValue;
    final visibleMax = maxValue;

    // Only draw ranges that are within the visible area
    void drawRangeIfVisible(
        double startSteps, double endSteps, String label, Color color) {
      // Check if range is visible in current view
      if (startSteps > visibleMax || endSteps < visibleMin) return;

      // Adjust range boundaries to visible area
      final adjustedStart = max(startSteps, visibleMin);
      final adjustedEnd = min(endSteps, visibleMax);

      final startY = _getYPosition(adjustedEnd); // Flip because Y is inverted
      final endY = _getYPosition(adjustedStart);

      // Don't draw if range is too small to be visible
      if ((endY - startY).abs() < 10) return;

      // Draw range background with animation
      rangePaint.color = color.withValues(alpha: 0.08 * animation.value);
      final rangeRect = Rect.fromLTRB(
        chartArea.left,
        startY,
        chartArea.right,
        endY,
      );

      // Animate range drawing from center
      final centerY = (startY + endY) / 2;
      final animatedHeight = (endY - startY) * animation.value;
      final animatedRect = Rect.fromLTRB(
        chartArea.left,
        centerY - animatedHeight / 2,
        chartArea.right,
        centerY + animatedHeight / 2,
      );

      canvas.drawRect(animatedRect, rangePaint);

      // Only draw label if there's enough space
      if ((endY - startY).abs() >= 25) {
        _drawCenteredLabel(
          canvas,
          rangeRect,
          label,
          labelStyle,
        );
      }
    }

    // Draw step ranges from bottom to top
    drawRangeIfVisible(
        12500, 25000, style.highlyActiveLabel, style.highlyActiveColor);
    drawRangeIfVisible(
        10000, 12500, style.veryActiveLabel, style.veryActiveColor);
    drawRangeIfVisible(
        7500, 10000, style.fairlyActiveLabel, style.fairlyActiveColor);
    drawRangeIfVisible(
        5000, 7500, style.lightActiveLabel, style.lightActiveColor);
    drawRangeIfVisible(0, 5000, style.sedentaryLabel, style.sedentaryColor);
  }

  void _drawCenteredLabel(
    Canvas canvas,
    Rect rect,
    String text,
    TextStyle style,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: style.color?.withValues(alpha: animation.value * 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: rect.width - 20);

    // Calculate vertical center position with proper clipping
    final yCenter = rect.center.dy - (textPainter.height / 2);

    // Ensure label doesn't overflow the chart area
    if (yCenter < chartArea.top ||
        (yCenter + textPainter.height) > chartArea.bottom) {
      return;
    }

    // Draw background for better readability
    final padding = 4.0;
    final backgroundRect = Rect.fromLTWH(
      rect.left + ((rect.width - textPainter.width) / 2) - padding,
      yCenter - padding,
      textPainter.width + (padding * 2),
      textPainter.height + (padding * 2),
    );

    canvas.drawRect(
      backgroundRect,
      Paint()..color = Colors.white.withValues(alpha: 0.3 * animation.value),
    );

    // Draw text centered in the range with animation
    textPainter.paint(
      canvas,
      Offset(
        rect.left + ((rect.width - textPainter.width) / 2),
        yCenter,
      ),
    );
  }

  double _getYPosition(double value) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
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
