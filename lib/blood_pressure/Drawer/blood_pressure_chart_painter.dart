import 'package:flutter/material.dart';

import '../models/chart_view_config.dart';
import '../models/processed_blood_pressure_data.dart';
import '../styles/blood_pressure_chart_style.dart';
import 'chart_abel_drawer.dart';
import 'chart_background_drawer.dart';
import 'chart_data_point_drawer.dart';
import 'chart_grid_drawer.dart';
import 'chart_reference_range_drawer.dart';

class BloodPressureChartPainter extends CustomPainter {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedBloodPressureData? selectedData;
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
  bool shouldRepaint(covariant BloodPressureChartPainter oldDelegate) {
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
