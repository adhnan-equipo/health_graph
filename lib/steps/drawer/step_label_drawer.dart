// lib/steps/drawer/step_label_drawer.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/processed_step_data.dart';
import '../services/step_chart_calculations.dart';
import '../styles/step_chart_style.dart';

class StepLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  void drawSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<int> yAxisValues,
    TextStyle textStyle,
    double animationValue,
  ) {
    final minValue = yAxisValues.isNotEmpty ? yAxisValues.first.toDouble() : 0;
    final maxValue =
        yAxisValues.isNotEmpty ? yAxisValues.last.toDouble() : 15000;

    for (var value in yAxisValues) {
      final y = StepChartCalculations.calculateYPosition(value.toDouble(),
          chartArea, minValue.toDouble(), maxValue.toDouble());

      final formattedValue = StepChartCalculations.formatAxisLabel(value);

      _textPainter
        ..text = TextSpan(
          text: formattedValue,
          style: textStyle.copyWith(
            color: textStyle.color?.withValues(alpha: animationValue),
          ),
        )
        ..layout();

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
    List<ProcessedStepData> data,
    DateRangeType viewType,
    StepChartStyle style,
    double animationValue,
  ) {
    if (data.isEmpty) return;

    final labelStep = _calculateLabelStep(data.length, viewType);

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      if (i % labelStep != 0) continue;

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

      final labelY = chartArea.bottom + 12;
      final labelX = x - (_textPainter.width / 2);

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
        return (dataLength / 6).round().clamp(1, dataLength);
      case DateRangeType.week:
        return 1;
      case DateRangeType.month:
        if (dataLength <= 10) return 1;
        return (dataLength / 8).round().clamp(1, 5);
      case DateRangeType.year:
        return 1;
    }
  }
}
