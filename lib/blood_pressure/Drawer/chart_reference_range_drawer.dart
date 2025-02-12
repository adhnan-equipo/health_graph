import 'package:flutter/material.dart';

import '../models/blood_pressure_range.dart';
import '../styles/blood_pressure_chart_style.dart';

class ChartReferenceRangeDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );

  void drawReferenceRanges(Canvas canvas, Rect chartArea,
      BloodPressureChartStyle style, double minValue, double maxValue) {
    final rangePaint = Paint()..style = PaintingStyle.fill;

    // Draw systolic normal range
    final systolicRangeRect = Rect.fromLTRB(
      chartArea.left,
      getYPosition(BloodPressureRange.normalSystolicMax.toDouble(), chartArea,
          minValue, maxValue),
      chartArea.right,
      getYPosition(BloodPressureRange.normalSystolicMin.toDouble(), chartArea,
          minValue, maxValue),
    );

    rangePaint.color = style.normalRangeColor.withOpacity(0.1);
    canvas.drawRect(systolicRangeRect, rangePaint);

    // Draw diastolic normal range
    final diastolicRangeRect = Rect.fromLTRB(
      chartArea.left,
      getYPosition(BloodPressureRange.normalDiastolicMax.toDouble(), chartArea,
          minValue, maxValue),
      chartArea.right,
      getYPosition(BloodPressureRange.normalDiastolicMin.toDouble(), chartArea,
          minValue, maxValue),
    );

    canvas.drawRect(diastolicRangeRect, rangePaint);

    // Draw range labels
    _drawRangeLabel(
      canvas: canvas,
      rect: systolicRangeRect,
      text: 'Normal Systolic Range',
      style: TextStyle(
        color: style.confidenceIntervalColor.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    _drawRangeLabel(
      canvas: canvas,
      rect: diastolicRangeRect,
      text: 'Normal Diastolic Range',
      style: TextStyle(
        color: style.confidenceIntervalColor.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _drawRangeLabel({
    required Canvas canvas,
    required Rect rect,
    required String text,
    required TextStyle style,
  }) {
    _textPainter
      ..text = TextSpan(text: text, style: style)
      ..layout(maxWidth: rect.width - 20); // Account for padding

    // Draw semi-transparent white background for better readability
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final textBgRect = Rect.fromLTWH(
      rect.left + 10, // Left padding
      rect.center.dy - _textPainter.height / 2,
      _textPainter.width + 10, // Add some padding
      _textPainter.height,
    );

    canvas.drawRect(textBgRect, backgroundPaint);

    // Draw text horizontally in the center of the range
    _textPainter.paint(
      canvas,
      Offset(
        rect.left + 15, // Left padding
        rect.center.dy - _textPainter.height / 2, // Vertically centered
      ),
    );
  }

  double getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
