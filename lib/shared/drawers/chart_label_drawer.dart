import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../utils/chart_calculations.dart';

/// Shared chart label drawer for all health metric charts
/// Provides consistent label drawing with animation support
class ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  /// Draws Y-axis labels for numeric values (double)
  void drawNumericSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<double> yAxisValues,
    TextStyle textStyle,
    double animationValue,
  ) {
    final minValue = yAxisValues.isNotEmpty ? yAxisValues.first : 0.0;
    final maxValue = yAxisValues.isNotEmpty ? yAxisValues.last : 100.0;

    for (var value in yAxisValues) {
      final y = SharedChartCalculations.calculateYPosition(
          value, chartArea, minValue, maxValue);

      final formattedValue = SharedChartCalculations.formatAxisLabel(value);

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

  /// Draws Y-axis labels for integer values
  void drawIntegerSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<int> yAxisValues,
    TextStyle textStyle,
    double animationValue,
  ) {
    final minValue =
        yAxisValues.isNotEmpty ? yAxisValues.first.toDouble() : 0.0;
    final maxValue =
        yAxisValues.isNotEmpty ? yAxisValues.last.toDouble() : 100.0;

    for (var value in yAxisValues) {
      final y = SharedChartCalculations.calculateYPosition(
          value.toDouble(), chartArea, minValue, maxValue);

      final formattedValue =
          SharedChartCalculations.formatAxisLabel(value.toDouble());

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

  /// Draws bottom date labels for any data type with date information
  void drawBottomLabels<T>(
    Canvas canvas,
    Rect chartArea,
    List<T> data,
    DateRangeType viewType,
    TextStyle textStyle,
    double animationValue,
    DateTime Function(T) getStartDate,
  ) {
    if (data.isEmpty) return;

    final labelStep = _calculateLabelStep(data.length, viewType);

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    for (var i = 0; i < data.length; i++) {
      if (i % labelStep != 0) continue;

      final x = chartArea.left + edgePadding + (i * xStep);
      final label = DateFormatter.format(getStartDate(data[i]), viewType);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: textStyle.copyWith(
            color: textStyle.color?.withValues(alpha: animationValue),
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

  /// Calculates optimal label step based on data length and view type
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
