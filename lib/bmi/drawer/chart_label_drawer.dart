// lib/bmi/drawer/chart_label_drawer.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/processed_bmi_data.dart';
import '../services/bmi_chart_calculations.dart';
import '../styles/bmi_chart_style.dart';

class ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

// lib/bmi/drawer/chart_label_drawer.dart - Modified method

  void drawSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<double> yAxisValues,
    TextStyle textStyle,
    double animationValue,
  ) {
    // Calculate min and max for consistent positioning
    final minValue = yAxisValues.isNotEmpty ? yAxisValues.first : 0;
    final maxValue = yAxisValues.isNotEmpty ? yAxisValues.last : 100;

    for (var value in yAxisValues) {
      // Use shared calculation method for consistent positioning with grid lines
      final y = BMIChartCalculations.calculateYPosition(
          value, chartArea, minValue.toDouble(), maxValue.toDouble());

      // Format the value with our optimized formatter
      final formattedValue = BMIChartCalculations.formatAxisLabel(value);

      _textPainter
        ..text = TextSpan(
          text: formattedValue,
          style: textStyle.copyWith(
            color: textStyle.color?.withValues(alpha: animationValue),
          ),
        )
        ..layout();

      // Calculate position with animation
      final xOffset = chartArea.left - _textPainter.width - 8;
      final animatedXOffset = Offset(
        lerpDouble(chartArea.left, xOffset, animationValue)!,
        y - _textPainter.height / 2, // Center text vertically on the line
      );

      // Draw optimized label
      _textPainter.paint(canvas, animatedXOffset);
    }
  }

// Optimized bottom label drawing to avoid overcrowding
  void drawBottomLabels(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBMIData> data,
    DateRangeType viewType,
    BMIChartStyle style,
    double animationValue,
  ) {
    if (data.isEmpty) return;

    final labelStep = _calculateLabelStep(data.length, viewType);

    // Use consistent edge padding for x position calculation
    const edgePadding = 15.0; // Same as in chart_grid_drawer.dart
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      // Skip labels based on step size to avoid overcrowding
      if (i % labelStep != 0) continue;

      // Calculate x position with consistent edge padding
      final x = chartArea.left + edgePadding + (i * xStep);
      final label = DateFormatter.format(data[i].startDate, viewType);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: (style.dateLabelStyle ?? style.defaultDateLabelStyle).copyWith(
            color:
                style.dateLabelStyle?.color?.withValues(alpha: animationValue),
          ),
        )
        ..layout();

      // Position labels with proper spacing and animation
      final labelY =
          chartArea.bottom + 12; // Increased from 8 for better spacing
      final labelX = x - (_textPainter.width / 2);

      // Animate from bottom up
      final animatedY = lerpDouble(
          chartArea.bottom + _textPainter.height, labelY, animationValue)!;

      _textPainter.paint(
        canvas,
        Offset(labelX, animatedY),
      );
    }
  }

  int _calculateLabelStep(int dataLength, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        // Show fewer labels for hourly data
        return (dataLength / 6).round().clamp(1, dataLength);

      case DateRangeType.week:
        // Always show all weekday labels
        return 1;

      case DateRangeType.month:
        // Show approximately 8-10 date labels
        if (dataLength <= 10) return 1;
        return (dataLength / 8).round().clamp(1, 5);

      case DateRangeType.year:
        // Show all month labels
        return 1;
    }
  }

  void drawBMIRangeLabels(
      Canvas canvas, Rect chartArea, double animationValue) {
    // Draw BMI range category labels on the right side
    final rangeLabels = [
      ('Underweight', 18.5),
      ('Normal', 24.9),
      ('Overweight', 29.9),
      ('Obese', 35.0),
    ];

    for (var label in rangeLabels) {
      _textPainter.text = TextSpan(
        text: label.$1,
        style: TextStyle(
          fontSize: 9,
          color: Colors.black54.withValues(alpha: 0.3),
          fontWeight: FontWeight.w500,
        ),
      );
      _textPainter.layout();

      final y =
          chartArea.bottom - ((label.$2 - 15) / (40 - 15)) * chartArea.height;

      // Animate from right side
      final animatedX = lerpDouble(chartArea.right + _textPainter.width,
          chartArea.right + 8, animationValue)!;

      _textPainter.paint(
        canvas,
        Offset(animatedX, y - _textPainter.height / 2),
      );
    }
  }
}
