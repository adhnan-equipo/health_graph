import 'package:flutter/material.dart';

import '../../shared/drawers/chart_background_drawer.dart';
import '../../shared/drawers/chart_grid_drawer.dart';
import '../../shared/drawers/chart_label_drawer.dart';
import '../../utils/chart_view_config.dart';
import '../models/processed_blood_pressure_data.dart';
import '../styles/blood_pressure_chart_style.dart';
import 'chart_data_point_drawer.dart';
import 'chart_reference_range_drawer.dart';

class BloodPressureChartPainter extends CustomPainter {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  late final ChartBackgroundDrawer _backgroundDrawer = ChartBackgroundDrawer();
  late final ChartGridDrawer _gridDrawer = ChartGridDrawer();
  late final ChartLabelDrawer _labelDrawer = ChartLabelDrawer();
  late final ChartReferenceRangeDrawer _rangeDrawer =
      ChartReferenceRangeDrawer();
  late final ChartDataPointDrawer _dataPointDrawer = ChartDataPointDrawer();

  BloodPressureChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Draw background with animation
    canvas.save();
    canvas.clipRect(chartArea);

    _backgroundDrawer.drawBackground(canvas, chartArea);

    // Animate grid lines
    if (config.showGrid) {
      _gridDrawer.drawIntegerGrid(
        canvas,
        chartArea,
        yAxisValues,
        minValue,
        maxValue,
        animation.value,
      );
    }

    // Draw reference ranges with animation
    _rangeDrawer.drawReferenceRanges(
      canvas,
      chartArea,
      style,
      minValue,
      maxValue,
      animation.value,
    );

    canvas.restore();

    // Draw labels with animation
    _labelDrawer.drawIntegerSideLabels(
      canvas,
      chartArea,
      yAxisValues,
      style.gridLabelStyle ?? const TextStyle(fontSize: 12, color: Colors.grey),
      animation.value,
    );

    _labelDrawer.drawBottomLabels<ProcessedBloodPressureData>(
      canvas,
      chartArea,
      data,
      config.viewType,
      style.dateLabelStyle ?? const TextStyle(fontSize: 12, color: Colors.grey),
      animation.value,
      (data) => data.startDate,
    );

    // Draw data points with animation
    canvas.save();
    canvas.clipRect(chartArea);

    _dataPointDrawer.drawDataPoints(
      canvas,
      chartArea,
      data,
      style,
      animation,
      minValue,
      maxValue,
    );

    canvas.restore();
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withValues(alpha: 0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw animated grid pattern
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BloodPressureChartPainter oldDelegate) {
    // Full repaint needed only when these key properties change
    return data != oldDelegate.data ||
        chartArea != oldDelegate.chartArea ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        animation.value != oldDelegate.animation.value;
  }
}
