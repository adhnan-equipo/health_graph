import 'package:flutter/material.dart';

import '../models/date_range_type.dart';
import '../models/processed_blood_pressure_data.dart';
import '../utils/date_formatter.dart';

class ChartLabelDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  void drawSideLabels(Canvas canvas, Rect chartArea, List<int> yAxisValues,
      TextStyle textStyle) {
    for (var value in yAxisValues) {
      final y = chartArea.bottom -
          ((value - yAxisValues.first) /
                  (yAxisValues.last - yAxisValues.first)) *
              chartArea.height;

      _textPainter.text = TextSpan(text: value.toString(), style: textStyle);
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
    List<ProcessedBloodPressureData> data,
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

  void drawRightSideValues(Canvas canvas, Rect chartArea,
      List<ProcessedBloodPressureData> data, double minValue, double maxValue) {
    for (final entry in data) {
      final ySystolic = getYPosition(
          entry.maxSystolic.toDouble(), chartArea, minValue, maxValue);
      final yDiastolic = getYPosition(
          entry.minDiastolic.toDouble(), chartArea, minValue, maxValue);

      // Draw systolic value
      drawRightSideLabel(
          canvas, entry.maxSystolic.toString(), ySystolic, chartArea.right + 8);

      // Draw diastolic value
      drawRightSideLabel(canvas, entry.minDiastolic.toString(), yDiastolic,
          chartArea.right + 8);
    }
  }

  void drawRightSideLabel(Canvas canvas, String text, double y, double labelX) {
    _textPainter.text = TextSpan(
        text: text, style: const TextStyle(fontSize: 9, color: Colors.black));
    _textPainter.layout();

    final labelY = y - (_textPainter.height / 2);

    // Draw text
    _textPainter.paint(
      canvas,
      Offset(labelX, labelY),
    );
  }

  double getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
