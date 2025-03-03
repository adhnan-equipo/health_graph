import 'package:flutter/material.dart';

import '../models/blood_pressure_range.dart';
import '../styles/blood_pressure_chart_style.dart';

class ChartReferenceRangeDrawer {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  void drawReferenceRanges(
    Canvas canvas,
    Rect chartArea,
    BloodPressureChartStyle style,
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    final rangePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = style.normalRangeColor.withOpacity(0.1 * animationValue);

    // Draw systolic normal range
    final systolicRangeRect = _calculateRangeRect(
      chartArea,
      BloodPressureRange.normalSystolicMin,
      BloodPressureRange.normalSystolicMax,
      minValue,
      maxValue,
    );

    _drawAnimatedRange(canvas, systolicRangeRect, rangePaint, animationValue);
    _drawRangeLabel(
      canvas,
      systolicRangeRect,
      style.systolicLabels,
      style.subHeaderStyle,
      animationValue,
    );

    // Draw diastolic normal range
    final diastolicRangeRect = _calculateRangeRect(
      chartArea,
      BloodPressureRange.normalDiastolicMin,
      BloodPressureRange.normalDiastolicMax,
      minValue,
      maxValue,
    );

    _drawAnimatedRange(canvas, diastolicRangeRect, rangePaint, animationValue);
    _drawRangeLabel(
      canvas,
      diastolicRangeRect,
      style.diastolicLabels,
      style.subHeaderStyle,
      animationValue,
    );
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
    double animationValue,
  ) {
    _textPainter
      ..text = TextSpan(
        text: text,
        style: style.copyWith(
          color: style.color?.withOpacity(animationValue),
        ),
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
      Paint()..color = Colors.transparent,
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
