import 'package:flutter/material.dart';

import '../models/o2_saturation_range.dart';
import '../styles/o2_saturation_chart_style.dart';

// lib/o2_saturation/painters/o2_reference_range_drawer.dart
class O2ReferenceRangeDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );

  void drawReferenceRanges(
    Canvas canvas,
    Rect chartArea,
    O2SaturationChartStyle style,
    double minValue,
    double maxValue,
  ) {
    final rangePaint = Paint()..style = PaintingStyle.fill;

    // Draw normal range (95-100%)
    final normalRangeRect = _getRangeRect(
      chartArea,
      O2SaturationRange.normalMax.toDouble(),
      O2SaturationRange.normalMin.toDouble(),
      minValue,
      maxValue,
    );

    // Fixed: Remove the incorrect assignment
    rangePaint.color = style.normalRangeColor.withValues(alpha: 0.1);
    canvas.drawRect(normalRangeRect, rangePaint);

    // Draw mild range (90-94%)
    final mildRangeRect = _getRangeRect(
      chartArea,
      O2SaturationRange.normalMin.toDouble(),
      O2SaturationRange.mildMin.toDouble(),
      minValue,
      maxValue,
    );
    rangePaint.color = style.mildRangeColor.withValues(alpha: 0.1);
    canvas.drawRect(mildRangeRect, rangePaint);

    // Draw moderate range (85-89%)
    final moderateRangeRect = _getRangeRect(
      chartArea,
      O2SaturationRange.mildMin.toDouble(),
      O2SaturationRange.moderateMin.toDouble(),
      minValue,
      maxValue,
    );
    rangePaint.color = style.moderateRangeColor.withValues(alpha: 0.1);
    canvas.drawRect(moderateRangeRect, rangePaint);

    // Draw severe range (<85%)
    final severeRangeRect = _getRangeRect(
      chartArea,
      O2SaturationRange.moderateMin.toDouble(),
      O2SaturationRange.severeMin.toDouble(),
      minValue,
      maxValue,
    );
    rangePaint.color = style.severeRangeColor.withValues(alpha: 0.1);
    canvas.drawRect(severeRangeRect, rangePaint);

    // Draw labels
    _drawRangeLabel(
      canvas: canvas,
      rect: normalRangeRect,
      text: 'Normal (95-100%)',
      style: TextStyle(
        color: style.normalRangeColor.withValues(alpha: 0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    _drawRangeLabel(
      canvas: canvas,
      rect: mildRangeRect,
      text: 'Mild (90-94%)',
      style: TextStyle(
        color: style.mildRangeColor.withValues(alpha: 0.7),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Rect _getRangeRect(
    Rect chartArea,
    double topValue,
    double bottomValue,
    double minValue,
    double maxValue,
  ) {
    return Rect.fromLTRB(
      chartArea.left,
      _getYPosition(topValue, chartArea, minValue, maxValue),
      chartArea.right,
      _getYPosition(bottomValue, chartArea, minValue, maxValue),
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
      ..layout(maxWidth: rect.width - 20);

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final textBgRect = Rect.fromLTWH(
      rect.left + 10,
      rect.center.dy - _textPainter.height / 2,
      _textPainter.width + 10,
      _textPainter.height,
    );

    canvas.drawRect(textBgRect, backgroundPaint);

    _textPainter.paint(
      canvas,
      Offset(
        rect.left + 15,
        rect.center.dy - _textPainter.height / 2,
      ),
    );
  }

  double _getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
