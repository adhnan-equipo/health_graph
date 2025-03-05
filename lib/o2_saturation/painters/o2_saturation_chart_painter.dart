// lib/o2_saturation/painters/o2_saturation_chart_painter.dart
import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';
import 'chart_background_drawer.dart';
import 'chart_grid_drawer.dart';
import 'chart_label_drawer.dart';
import 'chart_reference_range_drawer.dart';
import 'o2_data_point_drawer.dart';

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

  late final O2ChartBackgroundDrawer _backgroundDrawer =
      O2ChartBackgroundDrawer();
  late final O2ChartGridDrawer _gridDrawer = O2ChartGridDrawer();
  late final O2ChartLabelDrawer _labelDrawer = O2ChartLabelDrawer();
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
      _gridDrawer.drawGrid(
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
    _labelDrawer.drawSideLabels(
      canvas,
      chartArea,
      yAxisValues,
      style.gridLabelStyle ?? style.defaultGridLabelStyle,
      animation.value,
    );

    _labelDrawer.drawBottomLabels(
      canvas,
      chartArea,
      data,
      config.viewType,
      style,
      animation.value,
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
      selectedData,
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
  bool shouldRepaint(covariant O2SaturationChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        chartArea != oldDelegate.chartArea ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        animation.value != oldDelegate.animation.value ||
        selectedData != oldDelegate.selectedData;
  }
}

// O2DataPointDrawer
