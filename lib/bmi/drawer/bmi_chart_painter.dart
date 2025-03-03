// lib/bmi/drawer/bmi_chart_painter.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../blood_pressure/models/chart_view_config.dart';
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
    if (data.isEmpty) return;

    // Draw background and grid
    _backgroundDrawer.drawBackground(canvas, chartArea);
    if (config.showGrid) {
      _gridDrawer.drawGrid(canvas, chartArea,
          yAxisValues.map((e) => e.toInt()).toList(), minValue, maxValue, 2);
    }

    // Draw BMI range indicators
    _drawBMIRanges(canvas);

    // Draw labels
    _labelDrawer.drawSideLabels(
      canvas,
      chartArea,
      yAxisValues.map((e) => e.toDouble()).toList(),
      TextStyle(color: Colors.black, fontSize: 9),
    );
    _labelDrawer.drawBottomLabels(
      canvas,
      chartArea,
      data,
      config.viewType,
    );

    // Draw data points and line
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
  }

  void _drawRangeWithLabel(
    Canvas canvas,
    Rect rect,
    String text,
    TextStyle style,
    Paint paint,
  ) {
    // Draw the range background
    canvas.drawRect(rect, paint);

    // Draw the label
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    textPainter.layout(maxWidth: rect.width - 20);

    // Draw semi-transparent white background for better readability
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final textBgRect = Rect.fromLTWH(
      rect.left + 10,
      rect.center.dy - textPainter.height / 2,
      textPainter.width + 10,
      textPainter.height,
    );

    canvas.drawRect(textBgRect, backgroundPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        rect.left + 15,
        rect.center.dy - textPainter.height / 2,
      ),
    );
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

      // Draw range background
      rangePaint.color = color.withValues(alpha: 0.1);
      final rangeRect = Rect.fromLTRB(
        chartArea.left,
        startY,
        chartArea.right,
        endY,
      );
      canvas.drawRect(rangeRect, rangePaint);

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

    // Draw ranges from bottom to top
    drawRangeIfVisible(30.0, 40.0, 'Obese', style.obeseRangeColor);
    drawRangeIfVisible(25.0, 30.0, 'Overweight', style.overweightRangeColor);
    drawRangeIfVisible(18.5, 25.0, 'Normal', style.normalRangeColor);
    drawRangeIfVisible(15.0, 18.5, 'Underweight', style.underweightRangeColor);
  }

  void _drawCenteredLabel(
    Canvas canvas,
    Rect rect,
    String text,
    TextStyle style,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
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
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Draw text centered in the range
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
        animation != oldDelegate.animation ||
        chartArea != oldDelegate.chartArea ||
        yAxisValues != oldDelegate.yAxisValues ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
