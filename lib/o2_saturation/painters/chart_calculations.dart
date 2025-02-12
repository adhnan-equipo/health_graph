import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';

class O2ChartCalculations {
  static List<int> calculateYAxisValues(List<ProcessedO2SaturationData> data) {
    if (data.isEmpty) {
      // Default range focused on normal O2 values
      return [85, 88, 91, 94, 97, 100];
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      return [85, 88, 91, 94, 97, 100];
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);

    // Add padding to min and max
    var start = ((minValue - 2) / 3).floor() * 3; // Round down to nearest 3
    var end = ((maxValue + 2) / 3).ceil() * 3; // Round up to nearest 3

    // Enforce minimum range to prevent cramped display
    if (end - start < 9) {
      final mid = (start + end) / 2;
      start = (mid - 6).floor();
      end = (mid + 6).ceil();
    }

    // Clamp ranges
    start = start.clamp(80, 94); // Don't go below 80%
    end = end.clamp(96, 100); // Don't exceed 100%

    // Generate values with appropriate step size
    var step = 3;
    if (end - start <= 12) step = 2;
    if (end - start <= 6) step = 1;

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

  static Rect calculateChartArea(Size size) {
    // Adjust padding to give more vertical space
    const leftPadding = 40.0;
    const rightPadding = 20.0;
    const topPadding = 30.0; // Increased top padding
    const bottomPadding = 30.0;

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  static double getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    // Add small padding to prevent points touching edges
    final paddingPercent = 0.05;
    final range = maxValue - minValue;
    final paddedMin = minValue - (range * paddingPercent);
    final paddedMax = maxValue + (range * paddingPercent);

    return chartArea.bottom -
        ((value - paddedMin) / (paddedMax - paddedMin)) * chartArea.height;
  }
}
