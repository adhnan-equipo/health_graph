// lib/bmi/drawer/chart_label_drawer.dart
import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/processed_bmi_data.dart';

class ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  void drawSideLabels(Canvas canvas, Rect chartArea, List<double> yAxisValues,
      TextStyle textStyle) {
    for (var value in yAxisValues) {
      final y = chartArea.bottom -
          ((value - yAxisValues.first) /
                  (yAxisValues.last - yAxisValues.first)) *
              chartArea.height;

      _textPainter.text = TextSpan(
          text: value.toStringAsFixed(1), // Format BMI values with 1 decimal
          style: textStyle);
      _textPainter.layout();

      // Draw background
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          y - _textPainter.height / 2,
          chartArea.left - 8,
          _textPainter.height,
        ),
        Paint()..color = Colors.transparent,
      );

      // Draw text
      _textPainter.paint(
        canvas,
        Offset(chartArea.left - _textPainter.width - 8,
            y - _textPainter.height / 2),
      );
    }
  }

  void drawBottomLabels(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedBMIData> data,
    DateRangeType viewType,
  ) {
    if (data.isEmpty) return;

    final xStep = chartArea.width / (data.length - 1);
    final labelStep = _calculateLabelStep(data.length, viewType);

    for (var i = 0; i < data.length; i++) {
      // Skip labels based on step size to avoid overcrowding
      if (i % labelStep != 0) continue;

      final x = chartArea.left + (i * xStep);
      final label = DateFormatter.format(data[i].startDate, viewType);

      _textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
      );
      _textPainter.layout();

      final labelX = x - (_textPainter.width / 2);
      final labelY = chartArea.bottom + 4;

      // Draw background
      canvas.drawRect(
        Rect.fromLTWH(
          labelX - 2,
          labelY - 2,
          _textPainter.width + 4,
          _textPainter.height + 4,
        ),
        Paint()..color = Colors.transparent,
      );

      // Draw text
      _textPainter.paint(
        canvas,
        Offset(labelX, labelY),
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

  void drawBMIRangeLabels(Canvas canvas, Rect chartArea) {
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
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      );
      _textPainter.layout();

      final y =
          chartArea.bottom - ((label.$2 - 15) / (40 - 15)) * chartArea.height;

      _textPainter.paint(
        canvas,
        Offset(chartArea.right + 8, y - _textPainter.height / 2),
      );
    }
  }
}
