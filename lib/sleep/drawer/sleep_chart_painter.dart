// lib/sleep/drawer/sleep_chart_painter.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_range.dart';
import '../styles/sleep_chart_style.dart';

class SleepChartPainter extends CustomPainter {
  final List<ProcessedSleepData> data;
  final SleepChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedSleepData? selectedData;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  SleepChartPainter({
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
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    canvas.save();
    canvas.clipRect(chartArea);

    // Draw background
    _drawBackground(canvas);

    // Draw grid
    if (config.showGrid) {
      _drawGrid(canvas);
    }

    // Draw recommendation zones
    _drawRecommendationZones(canvas);

    // Draw sleep bars (stacked if detailed stages available)
    _drawSleepBars(canvas);

    // Draw trend line if enabled
    if (config.showTrendLine) {
      _drawTrendLine(canvas);
    }

    canvas.restore();

    // Draw labels
    _drawLabels(canvas);
  }

  void _drawBackground(Canvas canvas) {
    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(chartArea.left, chartArea.top),
        Offset(chartArea.left, chartArea.bottom),
        [
          style.backgroundColor.withOpacity(0.02),
          style.surfaceColor.withOpacity(0.05),
        ],
      );

    canvas.drawRect(chartArea, backgroundPaint);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(animation.value)
      ..strokeWidth = style.gridLineWidth
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        paint,
      );
    }
  }

  void _drawRecommendationZones(Canvas canvas) {
    if (!style.showRecommendationLine) return;

    // Draw recommended sleep zone (7-9 hours)
    final recommendedMinY = _getYPosition(SleepRange.recommendedMin.toDouble());
    final recommendedMaxY = _getYPosition(SleepRange.recommendedMax.toDouble());

    final zonePaint = Paint()
      ..color =
          style.recommendationBackgroundColor.withOpacity(0.3 * animation.value)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
          chartArea.left, recommendedMaxY, chartArea.right, recommendedMinY),
      zonePaint,
    );

    // Draw recommendation line at minimum
    final linePaint = Paint()
      ..color = style.recommendationLineColor.withOpacity(animation.value)
      ..strokeWidth = style.recommendationLineWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(chartArea.left, recommendedMinY),
      Offset(chartArea.right, recommendedMinY),
      linePaint,
    );
  }

  void _drawSleepBars(Canvas canvas) {
    if (data.isEmpty) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = chartArea.left + barPadding + (i * (barWidth + barPadding));

      if (entry.hasDetailedStages) {
        _drawStackedSleepBar(canvas, entry, x, barWidth);
      } else {
        _drawSimpleSleepBar(canvas, entry, x, barWidth);
      }

      // Selection highlight
      if (entry == selectedData) {
        _drawSelectionHighlight(
            canvas, x, barWidth, entry.displayValue.toDouble());
      }
    }
  }

  void _drawStackedSleepBar(
      Canvas canvas, ProcessedSleepData entry, double x, double barWidth) {
    final orderedStages = entry.orderedStages;
    double currentY = chartArea.bottom;

    for (var stageEntry in orderedStages) {
      final stage = stageEntry.key;
      final minutes = stageEntry.value;

      final segmentHeight = _getBarHeight(minutes.toDouble()) * animation.value;
      final segmentY = currentY - segmentHeight;

      final segmentRect = Rect.fromLTWH(x, segmentY, barWidth, segmentHeight);

      final segmentPaint = Paint()
        ..color =
            style.getSleepStageColor(stage).withOpacity(0.8 * animation.value)
        ..style = PaintingStyle.fill;

      // Draw segment with rounded corners (only top corners for top segment)
      final isTopSegment = stage == orderedStages.last.key;
      final borderRadius = isTopSegment
          ? BorderRadius.only(
              topLeft: Radius.circular(style.barBorderRadius),
              topRight: Radius.circular(style.barBorderRadius),
            )
          : BorderRadius.zero;

      final rRect = RRect.fromRectAndCorners(
        segmentRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
      );

      canvas.drawRRect(rRect, segmentPaint);

      // Draw border between segments
      if (orderedStages.indexOf(stageEntry) > 0) {
        final borderPaint = Paint()
          ..color = style.barBorderColor.withOpacity(0.5 * animation.value)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(x, currentY),
          Offset(x + barWidth, currentY),
          borderPaint,
        );
      }

      currentY = segmentY;
    }
  }

  void _drawSimpleSleepBar(
      Canvas canvas, ProcessedSleepData entry, double x, double barWidth) {
    final sleepValue = entry.displayValue.toDouble();
    final barHeight = _getBarHeight(sleepValue) * animation.value;
    final y = chartArea.bottom - barHeight;

    final barRect = Rect.fromLTWH(x, y, barWidth, barHeight);
    final qualityColor = style.getSleepQualityColor(entry.quality);

    final barPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(x, y),
        Offset(x, y + barHeight),
        [
          qualityColor.withOpacity(0.3),
          qualityColor.withOpacity(0.8),
        ],
      );

    final barRRect = RRect.fromRectAndRadius(
      barRect,
      Radius.circular(style.barBorderRadius),
    );

    canvas.drawRRect(barRRect, barPaint);

    // Border
    if (style.barBorderWidth > 0) {
      final borderPaint = Paint()
        ..color = qualityColor.withOpacity(animation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.barBorderWidth;

      canvas.drawRRect(barRRect, borderPaint);
    }
  }

  void _drawTrendLine(Canvas canvas) {
    if (data.length < 2) return;

    final path = Path();
    final points = <Offset>[];

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth =
        (availableWidth - (barPadding * (data.length - 1))) / data.length;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final sleepValue = entry.displayValue.toDouble();
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final y = _getYPosition(sleepValue);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = style.primaryColor.withOpacity(0.8 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw data points
    for (var point in points) {
      final pointPaint = Paint()
        ..color = style.primaryColor.withOpacity(animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 4.0 * animation.value, pointPaint);
    }
  }

  void _drawSelectionHighlight(
      Canvas canvas, double x, double barWidth, double sleepValue) {
    final barHeight = _getBarHeight(sleepValue);
    final y = chartArea.bottom - barHeight;

    final highlightPaint = Paint()
      ..color = style.primaryColor.withOpacity(0.3 * animation.value)
      ..style = PaintingStyle.fill;

    final highlightRect =
        Rect.fromLTWH(x - 2, y - 2, barWidth + 4, barHeight + 4);
    final highlightRRect = RRect.fromRectAndRadius(
      highlightRect,
      Radius.circular(style.barBorderRadius + 2),
    );

    canvas.drawRRect(highlightRRect, highlightPaint);
  }

  void _drawLabels(Canvas canvas) {
    // Draw Y-axis labels (sleep duration)
    _drawYAxisLabels(canvas);

    // Draw X-axis labels (dates)
    _drawXAxisLabels(canvas);
  }

  void _drawYAxisLabels(Canvas canvas) {
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());
      final label = _formatSleepDuration(value);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: (style.gridLabelStyle ?? style.defaultGridLabelStyle).copyWith(
            color: (style.gridLabelStyle?.color ??
                    style.defaultGridLabelStyle.color)
                ?.withOpacity(animation.value),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final xOffset = chartArea.left - textPainter.width - 8;
      textPainter.paint(canvas, Offset(xOffset, y - textPainter.height / 2));
    }
  }

  void _drawXAxisLabels(Canvas canvas) {
    if (data.isEmpty) return;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth =
        (availableWidth - (barPadding * (data.length - 1))) / data.length;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);

      // FIXED: Improved date formatting with 4-hour intervals for day view
      String label;
      bool shouldShowLabel = true;

      switch (config.viewType) {
        case DateRangeType.day:
          // FIXED: Show labels only for 4-hour intervals (0, 4, 8, 12, 16, 20)
          final hour = entry.startDate.hour;
          if (hour % 4 == 0) {
            label = '${hour.toString().padLeft(2, '0')}:00';
          } else {
            shouldShowLabel = false;
            label = '';
          }
          break;
        case DateRangeType.week:
          label =
              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][entry.startDate.weekday % 7];
          break;
        case DateRangeType.month:
          label = '${entry.startDate.day}';
          break;
        case DateRangeType.year:
          label = [
            'J',
            'F',
            'M',
            'A',
            'M',
            'J',
            'J',
            'A',
            'S',
            'O',
            'N',
            'D'
          ][entry.startDate.month - 1];
          break;
      }

      // Only draw label if it should be shown
      if (shouldShowLabel && label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style:
                (style.dateLabelStyle ?? style.defaultDateLabelStyle).copyWith(
              color: (style.dateLabelStyle?.color ??
                      style.defaultDateLabelStyle.color)
                  ?.withOpacity(animation.value),
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartArea.bottom + 12),
        );
      }
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * progress), paint);
    }
  }

  // Helper methods
  double _getYPosition(double value) {
    if (maxValue <= minValue) return chartArea.bottom;
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    return chartArea.bottom -
        normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  double _getBarHeight(double sleepValue) {
    if (maxValue <= minValue) return 0;
    final normalizedValue = (sleepValue - minValue) / (maxValue - minValue);
    return normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  // FIXED: Improved duration formatting - prefer whole hours
  String _formatSleepDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    // Always show whole hours when possible
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';

    // For mixed hours and minutes, still show both but prioritize readability
    return '${hours}h ${mins}m';
  }

  @override
  bool shouldRepaint(covariant SleepChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        style != oldDelegate.style ||
        config != oldDelegate.config ||
        selectedData != oldDelegate.selectedData ||
        animation.value != oldDelegate.animation.value ||
        chartArea != oldDelegate.chartArea ||
        yAxisValues != oldDelegate.yAxisValues ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
