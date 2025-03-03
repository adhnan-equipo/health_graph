// lib/bmi/drawer/chart_label_drawer.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';

class ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  void drawSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<double> yAxisValues,
    TextStyle textStyle,
    double animationValue,
  ) {
    for (var value in yAxisValues) {
      final y = chartArea.bottom -
          ((value - yAxisValues.first) /
                  (yAxisValues.last - yAxisValues.first)) *
              chartArea.height;

      _textPainter
        ..text = TextSpan(
          text: value.toStringAsFixed(1), // Format BMI values with 1 decimal
          style: textStyle.copyWith(
            color: textStyle.color?.withOpacity(animationValue),
          ),
        )
        ..layout();

      // Calculate position with animation
      final xOffset = chartArea.left - _textPainter.width - 8;
      final animatedXOffset = Offset(
        lerpDouble(chartArea.left, xOffset, animationValue)!,
        y - _textPainter.height / 2,
      );

      _textPainter.paint(canvas, animatedXOffset);
    }
  }

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
    final xStep = chartArea.width / (data.length - 1).clamp(1, double.infinity);

    for (var i = 0; i < data.length; i++) {
      // Skip labels based on step size to avoid overcrowding
      if (i % labelStep != 0) continue;

      final x = chartArea.left + (i * xStep);
      final label = DateFormatter.format(data[i].startDate, viewType);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: (style.dateLabelStyle ?? style.defaultDateLabelStyle).copyWith(
            color: style.dateLabelStyle?.color?.withOpacity(animationValue),
          ),
        )
        ..layout();

      // Position labels with proper spacing and animation
      final labelY = chartArea.bottom + 8;
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
