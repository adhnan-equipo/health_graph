// services/chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_bmi_data.dart';

class ChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const double _hitTestThreshold = 20.0;

  /// Calculates Y-axis values based on the provided BMI data
  static List<double> calculateYAxisValues(List<ProcessedBMIData> data) {
    if (data.isEmpty) {
      // Return default range for BMI
      return [15, 20, 25, 30, 35, 40];
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      return [15, 20, 25, 30, 35, 40];
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;
    final padding = _calculateDynamicPadding(range) * range;

    var start = ((minValue - padding) * 2).floor() / 2;
    var end = ((maxValue + padding) * 2).ceil() / 2;

    // Ensure range includes important BMI thresholds
    start = start.clamp(15.0, 25.0);
    end = end.clamp(30.0, 45.0);

    return _generateAxisValues(start, end);
  }

  /// Collects all BMI values from the data
  static List<double> _collectValues(List<ProcessedBMIData> data) {
    return data
        .where((d) => !d.isEmpty)
        .expand((d) => [d.minBMI, d.maxBMI])
        .toList();
  }

  /// Calculates dynamic padding based on the data range
  static double _calculateDynamicPadding(double range) {
    if (range <= 0) return _maxPaddingPercent;
    if (range > 20) return _minPaddingPercent;
    if (range < 5) return _maxPaddingPercent;
    return _maxPaddingPercent -
        ((range - 5) / 15) * (_maxPaddingPercent - _minPaddingPercent);
  }

  /// Generates axis values based on calculated parameters
  static List<double> _generateAxisValues(double start, double end) {
    const preferredStepCount = 5;
    final range = end - start;
    final rawStep = range / preferredStepCount;
    final step = _normalizeStep(rawStep);

    final values = <double>[];
    for (var value = start; value <= end; value += step) {
      values.add((value * 10).round() / 10); // Round to 1 decimal place
    }
    return values;
  }

  /// Normalizes step size to maintain readable intervals
  static double _normalizeStep(double rawStep) {
    final magnitude = pow(10, (log(rawStep) / ln10).floor());
    final normalized = rawStep / magnitude;

    if (normalized < 1.5) return magnitude.toDouble();
    if (normalized < 3) return (2 * magnitude).toDouble();
    if (normalized < 7) return (5 * magnitude).toDouble();
    return (10 * magnitude).toDouble();
  }

  /// Gets Y position for a value in the chart area
  static double getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  /// Calculate chart area based on available size
  static Rect calculateChartArea(Size size) {
    const leftPadding = 50.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 30.0;

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  /// Finds the nearest data point to the given position
  static ProcessedBMIData? findNearestDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBMIData> data,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    final xStep = chartArea.width / (data.length - 1);
    const hitArea = _hitTestThreshold;

    for (var i = 0; i < data.length; i++) {
      final x = chartArea.left + (i * xStep);
      final entry = data[i];
      if (entry.isEmpty) continue;

      final y = getYPosition(entry.avgBMI, chartArea, minValue, maxValue);
      final distance = (position - Offset(x, y)).distance;

      if (distance <= hitArea) {
        return entry;
      }
    }
    return null;
  }

  /// Checks if the position is within the chart area
  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }
}
