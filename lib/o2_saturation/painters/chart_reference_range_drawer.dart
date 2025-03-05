import 'package:flutter/material.dart';

import '../models/o2_saturation_range.dart';
import '../styles/o2_saturation_chart_style.dart';

// lib/o2_saturation/painters/o2_reference_range_drawer.dart

// O2ReferenceRangeDrawer
class O2ReferenceRangeDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  void drawReferenceRanges(
    Canvas canvas,
    Rect chartArea,
    O2SaturationChartStyle style,
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    final rangePaint = Paint()..style = PaintingStyle.fill;

    // Draw normal range (95-100%)
    final normalRangeRect = _calculateRangeRect(
      chartArea,
      O2SaturationRange.normalMin,
      O2SaturationRange.normalMax,
      minValue,
      maxValue,
    );

    rangePaint.color = style.normalRangeColor.withOpacity(0.1 * animationValue);
    _drawAnimatedRange(canvas, normalRangeRect, rangePaint, animationValue);
    _drawRangeLabel(
      canvas,
      normalRangeRect,
      'Normal (95-100%)',
      TextStyle(
        color: style.normalRangeColor.withOpacity(0.7 * animationValue),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    // Draw mild range (90-94%)
    final mildRangeRect = _calculateRangeRect(
      chartArea,
      O2SaturationRange.mildMin,
      O2SaturationRange.normalMin,
      minValue,
      maxValue,
    );
    rangePaint.color = style.mildRangeColor.withOpacity(0.1 * animationValue);
    _drawAnimatedRange(canvas, mildRangeRect, rangePaint, animationValue);
    _drawRangeLabel(
      canvas,
      mildRangeRect,
      'Mild (90-94%)',
      TextStyle(
        color: style.mildRangeColor.withOpacity(0.7 * animationValue),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    // Draw moderate range (85-89%)
    final moderateRangeRect = _calculateRangeRect(
      chartArea,
      O2SaturationRange.moderateMin,
      O2SaturationRange.mildMin,
      minValue,
      maxValue,
    );
    rangePaint.color =
        style.moderateRangeColor.withOpacity(0.1 * animationValue);
    _drawAnimatedRange(canvas, moderateRangeRect, rangePaint, animationValue);
    _drawRangeLabel(
      canvas,
      moderateRangeRect,
      'Moderate (85-89%)',
      TextStyle(
        color: style.moderateRangeColor.withOpacity(0.7 * animationValue),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    // Draw severe range (<85%)
    if (minValue < O2SaturationRange.moderateMin) {
      final severeRangeRect = _calculateRangeRect(
        chartArea,
        O2SaturationRange.severeMin,
        O2SaturationRange.moderateMin,
        minValue,
        maxValue,
      );
      rangePaint.color =
          style.severeRangeColor.withOpacity(0.1 * animationValue);
      _drawAnimatedRange(canvas, severeRangeRect, rangePaint, animationValue);
      _drawRangeLabel(
        canvas,
        severeRangeRect,
        'Severe (<85%)',
        TextStyle(
          color: style.severeRangeColor.withOpacity(0.7 * animationValue),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }

  Rect _calculateRangeRect(
    Rect chartArea,
    int minValue,
    int maxValue,
    double chartMinValue,
    double chartMaxValue,
  ) {
    final minY = _getYPosition(
        maxValue.toDouble(), chartArea, chartMinValue, chartMaxValue);
    final maxY = _getYPosition(
        minValue.toDouble(), chartArea, chartMinValue, chartMaxValue);

    return Rect.fromLTRB(
      chartArea.left,
      minY,
      chartArea.right,
      maxY,
    );
  }

  void _drawRangeLabel(
    Canvas canvas,
    Rect rangeRect,
    String text,
    TextStyle style,
  ) {
    _textPainter
      ..text = TextSpan(
        text: text,
        style: style,
      )
      ..layout();

    final centerY = rangeRect.center.dy - (_textPainter.height / 2);

    // Draw background for better readability
    final labelBackground = Rect.fromLTWH(
      rangeRect.left + 10,
      centerY,
      _textPainter.width + 20,
      _textPainter.height,
    );

    canvas.drawRect(
      labelBackground,
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    _textPainter.paint(
      canvas,
      Offset(rangeRect.left + 20, centerY),
    );
  }

  void _drawAnimatedRange(
    Canvas canvas,
    Rect rect,
    Paint paint,
    double animationValue,
  ) {
    final center = rect.center;
    final animatedRect = Rect.fromCenter(
      center: center,
      width: rect.width * animationValue,
      height: rect.height,
    );
    canvas.drawRect(animatedRect, paint);
  }

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
