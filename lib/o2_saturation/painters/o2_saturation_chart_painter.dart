// lib/o2_saturation/painters/o2_saturation_chart_painter.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/o2_saturation_range.dart';
import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';
import 'chart_background_drawer.dart';
import 'chart_grid_drawer.dart';
import 'chart_label_drawer.dart';

class O2SaturationChartPainter extends CustomPainter {
  final List<ProcessedO2SaturationData> data;
  final O2SaturationChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedO2SaturationData? selectedData;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  late final ChartBackgroundDrawer _backgroundDrawer = ChartBackgroundDrawer();
  late final ChartGridDrawer _gridDrawer = ChartGridDrawer();
  late final ChartLabelDrawer _labelDrawer = ChartLabelDrawer();
  late final O2ReferenceRangeDrawer _rangeDrawer = O2ReferenceRangeDrawer();
  late final O2DataPointDrawer _dataPointDrawer = O2DataPointDrawer();

  O2SaturationChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
    this.selectedData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw background and grid
    _backgroundDrawer.drawBackground(canvas, chartArea);
    if (config.showGrid) {
      _gridDrawer.drawGrid(canvas, chartArea, yAxisValues, minValue, maxValue);
    }

    // Draw labels
    _labelDrawer.drawSideLabels(
      canvas,
      chartArea,
      yAxisValues,
      TextStyle(color: Colors.black, fontSize: 9),
    );
    _labelDrawer.drawBottomLabels(
      canvas,
      chartArea,
      data,
      config.viewType,
    );

    // Draw reference ranges
    _rangeDrawer.drawReferenceRanges(
      canvas,
      chartArea,
      style,
      minValue,
      maxValue,
    );

    // Draw data points and ranges
    _dataPointDrawer.drawDataPoints(
      canvas,
      chartArea,
      data,
      style,
      animation,
      selectedData,
      minValue,
      maxValue,
    );
  }

  @override
  bool shouldRepaint(covariant O2SaturationChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        style != oldDelegate.style ||
        config != oldDelegate.config ||
        selectedData != oldDelegate.selectedData ||
        animation != oldDelegate.animation ||
        chartArea != oldDelegate.chartArea ||
        yAxisValues != oldDelegate.yAxisValues ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}

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

    // Draw normal range
    final normalRangeRect = Rect.fromLTRB(
      chartArea.left,
      _getYPosition(O2SaturationRange.normalMax.toDouble(), chartArea, minValue,
          maxValue),
      chartArea.right,
      _getYPosition(O2SaturationRange.normalMin.toDouble(), chartArea, minValue,
          maxValue),
    );

    rangePaint.color = style.normalRangeColor.withValues(alpha: 0.1);
    canvas.drawRect(normalRangeRect, rangePaint);

    // Draw labels
    _drawRangeLabel(
      canvas: canvas,
      rect: normalRangeRect,
      text: 'Normal Range',
      style: TextStyle(
        color: style.normalRangeColor.withValues(alpha: 0.7),
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

// lib/o2_saturation/painters/o2_data_point_drawer.dart
class O2DataPointDrawer {
  final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;

  void drawDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    O2SaturationChartStyle style,
    Animation<double> animation,
    ProcessedO2SaturationData? selectedData,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return;

    final xStep = chartArea.width / (data.length - 1);

    // Draw trend lines first
    _drawTrendLines(
      canvas,
      chartArea,
      data,
      xStep,
      style,
      animation,
      minValue,
      maxValue,
    );

    // Draw individual data points
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final y = _getYPosition(entry.avgValue, chartArea, minValue, maxValue);
      final position = Offset(x, y);

      final isSelected = entry == selectedData;

      if (isSelected) {
        _drawSelectionHighlight(canvas, x, chartArea, style);
      }

      // Draw O2 saturation point
      _drawPoint(
        canvas,
        position,
        style.primaryColor,
        style,
        animation,
        isSelected,
      );

      // Draw pulse rate point if available
      if (entry.avgPulseRate != null) {
        final pulseY = _getYPosition(
          entry.avgPulseRate!,
          chartArea,
          minValue,
          maxValue,
        );
        _drawPoint(
          canvas,
          Offset(x, pulseY),
          style.pulseRateColor,
          style,
          animation,
          isSelected,
        );
      }

      // Draw reading count badge if multiple readings
      if (entry.dataPointCount > 1) {
        _drawReadingCount(
          canvas,
          position,
          entry.dataPointCount,
          style,
          animation,
        );
      }
    }
  }

  void _drawTrendLines(
    Canvas canvas,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
    double xStep,
    O2SaturationChartStyle style,
    Animation<double> animation,
    double minValue,
    double maxValue,
  ) {
    if (data.length < 2) return;

    final o2Path = Path();
    final pulsePath = Path();
    var isFirstValidPoint = true;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = chartArea.left + (i * xStep);
      final entry = data[i];

      final o2Y = _getYPosition(
        entry.avgValue,
        chartArea,
        minValue,
        maxValue,
      );

      if (isFirstValidPoint) {
        o2Path.moveTo(x, o2Y);
        if (entry.avgPulseRate != null) {
          final pulseY = _getYPosition(
            entry.avgPulseRate!,
            chartArea,
            minValue,
            maxValue,
          );
          pulsePath.moveTo(x, pulseY);
        }
        isFirstValidPoint = false;
      } else {
        o2Path.lineTo(x, o2Y);
        if (entry.avgPulseRate != null) {
          final pulseY = _getYPosition(
            entry.avgPulseRate!,
            chartArea,
            minValue,
            maxValue,
          );
          pulsePath.lineTo(x, pulseY);
        }
      }
    }

    final trendPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.lineThickness;

    // Draw O2 trend line
    trendPaint.color =
        style.primaryColor.withValues(alpha: 0.3 * animation.value);
    canvas.drawPath(o2Path, trendPaint);

    // Draw pulse rate trend line
    trendPaint.color =
        style.pulseRateColor.withValues(alpha: 0.3 * animation.value);
    canvas.drawPath(pulsePath, trendPaint);
  }

  void _drawPoint(
    Canvas canvas,
    Offset position,
    Color color,
    O2SaturationChartStyle style,
    Animation<double> animation,
    bool isSelected,
  ) {
    if (isSelected) {
      _dataPointPaint
        ..style = PaintingStyle.fill
        ..color = style.selectedHighlightColor;
      canvas.drawCircle(position, style.pointRadius * 2, _dataPointPaint);
    }

    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: animation.value);
    canvas.drawCircle(
      position,
      style.pointRadius,
      _dataPointPaint,
    );

    _dataPointPaint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: animation.value)
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      position,
      style.pointRadius,
      _dataPointPaint,
    );
  }

  void _drawSelectionHighlight(
    Canvas canvas,
    double x,
    Rect chartArea,
    O2SaturationChartStyle style,
  ) {
    final paint = Paint()
      ..color = style.selectedHighlightColor.withValues(alpha: 0.2)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      paint,
    );
  }

  void _drawReadingCount(
    Canvas canvas,
    Offset position,
    int count,
    O2SaturationChartStyle style,
    Animation<double> animation,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRadius = max(textPainter.width, textPainter.height) * 0.7;
    final badgeCenter = Offset(
      position.dx + style.pointRadius * 2,
      position.dy - style.pointRadius * 2,
    );

    _dataPointPaint
      ..style = PaintingStyle.fill
      ..color = style.primaryColor.withValues(alpha: animation.value);
    canvas.drawCircle(badgeCenter, badgeRadius, _dataPointPaint);

    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
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
