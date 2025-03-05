// O2ChartLabelDrawer
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';

class O2ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.right,
  );

  void drawSideLabels(
    Canvas canvas,
    Rect chartArea,
    List<int> yAxisValues,
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
          text: '$value%', // Add % sign for O2 saturation
          style: textStyle.copyWith(
            color: textStyle.color?.withOpacity(animationValue),
          ),
        )
        ..layout();

      // Calculate position with animation
      final xOffset = chartArea.left - _textPainter.width - 8;
      final animatedXOffset = Offset(
        ui.lerpDouble(chartArea.left, xOffset, animationValue)!,
        y - _textPainter.height / 2,
      );

      _textPainter.paint(canvas, animatedXOffset);
    }
  }

  void drawBottomLabels(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    DateRangeType viewType,
    O2SaturationChartStyle style,
    double animationValue,
  ) {
    if (data.isEmpty) return;

    final labelStep = _calculateLabelStep(data.length, viewType);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i < data.length; i++) {
      if (i % labelStep != 0) continue;

      final x = _calculateXPosition(i, data.length, chartArea);
      final label = DateFormatter.format(data[i].startDate, viewType);

      textPainter
        ..text = TextSpan(
          text: label,
          style: style.dateLabelStyle?.copyWith(
                color: style.dateLabelStyle?.color?.withOpacity(animationValue),
              ) ??
              TextStyle(
                color: Colors.grey[600]?.withOpacity(animationValue),
                fontSize: 12,
              ),
        )
        ..layout();

      // Position labels with proper spacing
      textPainter.paint(
        canvas,
        Offset(
          x - (textPainter.width / 2),
          chartArea.bottom + 8, // Increased spacing from chart area
        ),
      );
    }
  }

  double _calculateXPosition(int index, int totalPoints, Rect chartArea) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0; // Increased for better visibility at edges
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
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
