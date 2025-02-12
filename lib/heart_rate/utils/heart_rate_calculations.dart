// lib/utils/heart_rate_calculations.dart
import 'package:flutter/material.dart';

import '../models/processed_heart_rate_data.dart';

class ChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const int _preferredStepCount = 6;
  static const int _minStepSize = 10;
  static const int _maxStepSize = 20;
  static const int _baseGridSize = 10;
  static const double _hitTestThreshold = 20.0;

  /// Calculates Y-axis values based on the provided heart rate data
  static List<int> calculateYAxisValues(List<ProcessedHeartRateData> data) {
    if (data.isEmpty) {
      // Return default range if no data
      return [40, 60, 80, 100, 120, 140];
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      return [40, 60, 80, 100, 120, 140];
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = _calculateDynamicPadding(range) * range;

    var start = ((minValue - padding) / _baseGridSize).floor() * _baseGridSize;
    var end = ((maxValue + padding) / _baseGridSize).ceil() * _baseGridSize;

    // Ensure range includes common heart rate zones
    start = start.clamp(30, 60);
    end = end.clamp(120, 200);

    final step = _calculateStepSize(start, end);
    return _generateAxisValues(start, end, step);
  }

  static List<double> _collectValues(List<ProcessedHeartRateData> data) {
    return data
        .expand((d) => [
              d.minValue.toDouble(),
              d.maxValue.toDouble(),
              d.avgValue,
              if (d.restingRate != null) d.restingRate!.toDouble(),
            ])
        .where((value) => value > 0)
        .toList();
  }

  static double _calculateDynamicPadding(double range) {
    if (range <= 0) return _maxPaddingPercent;
    if (range > 100) return _minPaddingPercent;
    if (range < 40) return _maxPaddingPercent;
    return _maxPaddingPercent -
        ((range - 40) / 60) * (_maxPaddingPercent - _minPaddingPercent);
  }

  static int _calculateStepSize(int start, int end) {
    final range = end - start;
    final rawStep = (range / _preferredStepCount).ceil();
    return _normalizeStepSize(rawStep);
  }

  static int _normalizeStepSize(int rawStep) {
    if (rawStep <= _minStepSize) return _minStepSize;
    if (rawStep >= _maxStepSize) return _maxStepSize;
    return ((rawStep + 4) ~/ 5) * 5; // Round to nearest 5
  }

  static List<int> _generateAxisValues(int start, int end, int step) {
    final values = <int>[];
    for (var value = start; value <= end; value += step) {
      values.add(value);
    }
    return values;
  }

  static ProcessedHeartRateData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedHeartRateData> data,
  ) {
    if (data.isEmpty) return null;

    final xStep = chartArea.width / (data.length - 1);
    final index = ((position.dx - chartArea.left) / xStep).round();

    if (index >= 0 && index < data.length) {
      final x = chartArea.left + (index * xStep);
      if ((x - position.dx).abs() <= _hitTestThreshold) {
        return data[index];
      }
    }

    return null;
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 40.0; // Space for y-axis labels
    const rightPadding = 20.0; // Right margin
    const topPadding = 20.0; // Top margin
    const bottomPadding = 30.0; // Space for x-axis labels

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
    if (maxValue == minValue) return chartArea.center.dy;
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
