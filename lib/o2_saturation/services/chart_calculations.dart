import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';

class ChartCalculations {
  static ProcessedO2SaturationData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    final xStep = chartArea.width / (data.length - 1);
    const hitTestThreshold = 20.0;

    for (var i = 0; i < data.length; i++) {
      final x = chartArea.left + (i * xStep);
      if ((position.dx - x).abs() <= hitTestThreshold) {
        final entry = data[i];
        if (!entry.isEmpty) {
          return entry;
        }
      }
    }

    return null;
  }

  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }

  static List<int> calculateYAxisValues(List<ProcessedO2SaturationData> data) {
    if (data.isEmpty) {
      return _generateDefaultYAxisValues();
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      return _generateDefaultYAxisValues();
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;

    var step = 5;
    if (range > 30) step = 10;
    if (range < 15) step = 2;

    var start = (minValue / step).floor() * step;
    var end = ((maxValue + step - 1) / step).ceil() * step;

    // Ensure we include critical ranges
    start = min(start, 80);
    end = max(end, 100);

    List<int> values2 = [];
    for (var i = start; i <= end; i += step) {
      values2.add(i);
    }

    return values2;
  }

  static List<double> _collectValues(List<ProcessedO2SaturationData> data) {
    return data
        .expand((d) => [d.minValue.toDouble(), d.maxValue.toDouble()])
        .where((value) => value > 0)
        .toList();
  }

  static List<int> _generateDefaultYAxisValues() {
    return [80, 85, 90, 95, 100];
  }
}
