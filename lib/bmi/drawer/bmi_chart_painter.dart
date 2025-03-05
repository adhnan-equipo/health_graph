// lib/bmi/drawer/bmi_chart_painter.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';
import 'bmi_data_point_drawer.dart';
import 'chart_background_drawer.dart';
import 'chart_grid_drawer.dart';
import 'chart_label_drawer.dart';

class BMIChartPainter extends CustomPainter {
  final List<ProcessedBMIData> data;
  final BMIChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedBMIData? selectedData;
  final Rect chartArea;
  final List<double> yAxisValues;
  final double minValue;
  final double maxValue;

  late final ChartBackgroundDrawer _backgroundDrawer = ChartBackgroundDrawer();
  late final ChartGridDrawer _gridDrawer = ChartGridDrawer();
  late final ChartLabelDrawer _labelDrawer = ChartLabelDrawer();
  late final BMIDataPointDrawer _dataPointDrawer = BMIDataPointDrawer();

  BMIChartPainter({
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
          yAxisValues.map((e) => e.toInt()).toList(),
          minValue,
          maxValue,
          animation.value);
    }

    // Draw BMI range indicators
    _drawBMIRanges(canvas);

    canvas.restore();

    // Draw labels
    _labelDrawer.drawSideLabels(
      canvas,
      chartArea,
      yAxisValues.map((e) => e.toDouble()).toList(),
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

  void _drawBMIRanges(Canvas canvas) {
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
        double startBMI, double endBMI, String label, Color color) {
      // Check if range is visible in current view
      if (startBMI > visibleMax || endBMI < visibleMin) return;

      // Adjust range boundaries to visible area
      final adjustedStart = max(startBMI, visibleMin);
      final adjustedEnd = min(endBMI, visibleMax);

      final startY = _getYPosition(adjustedEnd); // Flip because Y is inverted
      final endY = _getYPosition(adjustedStart);

      // Don't draw if range is too small to be visible
      if ((endY - startY).abs() < 10) return;

      // Draw range background with animation
      rangePaint.color = color.withValues(alpha: 0.1 * animation.value);
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
      if ((endY - startY).abs() >= 20) {
        _drawCenteredLabel(
          canvas,
          rangeRect,
          label,
          labelStyle,
        );
      }
    }

    // Draw ranges from bottom to top with animation
    drawRangeIfVisible(
        30.0, 100.0, style.obeseLabel ?? 'Obese', style.obeseRangeColor);
    drawRangeIfVisible(25.0, 30.0, style.overweightLabel ?? 'Overweight',
        style.overweightRangeColor);
    drawRangeIfVisible(
        18.5, 25.0, style.normalLabel ?? 'Healthy', style.normalRangeColor);
    drawRangeIfVisible(0.0, 18.5, style.underweightLabel ?? 'Underweight',
        style.underweightRangeColor);
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
          color: style.color?.withValues(alpha: animation.value),
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
      Paint()..color = Colors.white.withValues(alpha: 0.4),
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
  bool shouldRepaint(covariant BMIChartPainter oldDelegate) {
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
