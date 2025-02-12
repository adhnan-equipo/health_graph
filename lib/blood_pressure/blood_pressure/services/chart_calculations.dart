// lib/blood_pressure/services/chart_calculations.dart
import 'package:flutter/material.dart';

import '../../models/processed_blood_pressure_data.dart';

class ChartCalculations {
  // Constants for chart calculations
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const int _preferredStepCount = 6;
  static const int _minStepSize = 10;
  static const int _maxStepSize = 20;
  static const int _baseGridSize = 10;
  static const double _hitTestThreshold = 20.0;

  /// Calculates Y-axis values based on the provided blood pressure data
  static List<int> calculateYAxisValues(List<ProcessedBloodPressureData> data) {
    if (data.isEmpty) {
      // Return default range if no data
      return [60, 80, 100, 120, 140, 160];
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      // Return default range if no valid values
      return [60, 80, 100, 120, 140, 160];
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = _calculateDynamicPadding(range) * range;

    var start = ((minValue - padding) / _baseGridSize).floor() * _baseGridSize;
    var end = ((maxValue + padding) / _baseGridSize).ceil() * _baseGridSize;

    // Ensure range includes normal blood pressure ranges
    start = start.clamp(40, 80);
    end = end.clamp(120, 200);

    final step = _calculateStepSize(start, end);
    return _generateAxisValues(start, end, step);
  }

  /// Collects all blood pressure values from the data
  static List<double> _collectValues(List<ProcessedBloodPressureData> data) {
    return data
        .expand((d) => [
              d.maxSystolic.toDouble(),
              d.minSystolic.toDouble(),
              d.maxDiastolic.toDouble(),
              d.minDiastolic.toDouble(),
            ])
        .where((value) => value > 0)
        .toList();
  }

  /// Calculates dynamic padding based on the data range
  static double _calculateDynamicPadding(double range) {
    if (range <= 0) return _maxPaddingPercent;
    if (range > 100) return _minPaddingPercent;
    if (range < 40) return _maxPaddingPercent;
    return _maxPaddingPercent -
        ((range - 40) / 60) * (_maxPaddingPercent - _minPaddingPercent);
  }

  /// Calculates appropriate step size for the axis
  static int _calculateStepSize(int start, int end) {
    final range = end - start;
    final rawStep = (range / _preferredStepCount).ceil();
    return _normalizeStepSize(rawStep);
  }

  /// Normalizes step size to maintain readable intervals
  static int _normalizeStepSize(int rawStep) {
    if (rawStep <= _minStepSize) return _minStepSize;
    if (rawStep >= _maxStepSize) return _maxStepSize;
    return ((rawStep + 4) ~/ 5) * 5; // Round to nearest 5
  }

  /// Generates axis values based on calculated parameters
  static List<int> _generateAxisValues(int start, int end, int step) {
    final values = <int>[];
    for (var value = start; value <= end; value += step) {
      values.add(value);
    }
    return values;
  }

  /// Finds the nearest data point to the given position
  static ProcessedBloodPressureData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    final xStep = chartArea.width / (data.length - 1);
    final index =
        _findClosestIndex(position.dx, chartArea.left, xStep, data.length);

    if (index >= 0 && index < data.length) {
      final pointX = chartArea.left + (index * xStep);
      if ((position.dx - pointX).abs() <= _hitTestThreshold) {
        return data[index];
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

  /// Finds the index of the closest data point
  static int _findClosestIndex(
    double x,
    double chartLeft,
    double xStep,
    int dataLength,
  ) {
    if (dataLength <= 1) return 0;

    final relativeX = x - chartLeft;
    final rawIndex = relativeX / xStep;
    final index = rawIndex.round();

    return index.clamp(0, dataLength - 1);
  }

  /// Find data points within date range
  static List<ProcessedBloodPressureData> findDataPointsInRange(
    List<ProcessedBloodPressureData> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    return data.where((point) {
      final pointStart = point.startDate;
      final pointEnd = point.endDate;

      // Check if the point's date range overlaps with the target range
      return (pointStart.isAtSameMomentAs(startDate) ||
              pointStart.isAfter(startDate) ||
              pointEnd.isAfter(startDate)) &&
          (pointEnd.isAtSameMomentAs(endDate) ||
              pointEnd.isBefore(endDate) ||
              pointStart.isBefore(endDate));
    }).toList();
  }

  /// Gets Y position for a value in the chart area
  static double getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (maxValue == minValue) return chartArea.center.dy;

    final valueRange = maxValue - minValue;
    final normalizedValue = (value - minValue) / valueRange;
    return chartArea.bottom - (normalizedValue * chartArea.height);
  }

  /// Calculate chart area based on available size
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

  /// Finds multiple data points near the given position
  static List<ProcessedBloodPressureData> findDataPointsNearPosition(
    Offset position,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    double threshold,
  ) {
    if (data.isEmpty) return [];
    if (!_isWithinChartArea(position, chartArea)) return [];

    final xStep = chartArea.width / (data.length - 1);
    final results = <ProcessedBloodPressureData>[];

    for (var i = 0; i < data.length; i++) {
      final pointX = chartArea.left + (i * xStep);
      if ((position.dx - pointX).abs() <= threshold) {
        results.add(data[i]);
      }
    }

    return results;
  }
}
