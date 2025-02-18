// lib/blood_pressure/services/chart_calculations.dart
import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';

class ChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const int _preferredStepCount = 6;
  static const int _minStepSize = 10;
  static const int _maxStepSize = 20;
  static const int _baseGridSize = 10;
  static const double _hitTestThreshold = 20.0;

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

  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }

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
}
