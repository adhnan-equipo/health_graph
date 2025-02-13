// lib/bmi/services/bmi_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_bmi_data.dart';

class BMIChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const double _hitTestThreshold = 20.0;

  static List<double> calculateYAxisValues(List<ProcessedBMIData> data) {
    if (data.isEmpty) {
      return [15, 20, 25, 30, 35];
    }

    final values = _collectValues(data)
        .where((value) => !value.isNaN && value.isFinite)
        .toList();

    if (values.isEmpty) {
      return [15, 20, 25, 30, 35];
    }

    // Find actual data range
    var minValue = values.reduce(min);
    var maxValue = values.reduce(max);

    // Validate values
    if (minValue.isNaN ||
        !minValue.isFinite ||
        maxValue.isNaN ||
        !maxValue.isFinite) {
      return [15, 20, 25, 30, 35];
    }

    // Add padding but respect BMI range limits
    final range = maxValue - minValue;
    final padding = _calculateDynamicPadding(range) * range;

    minValue = (minValue - padding).clamp(15.0, 35.0);
    maxValue = (maxValue + padding).clamp(15.0, 40.0);

    // Ensure we always show at least one complete BMI category
    if (maxValue - minValue < 5) {
      maxValue = minValue + 5;
    }

    // Generate nice step values
    final step = _calculateStepSize(minValue, maxValue);
    return _generateAxisValues(minValue, maxValue, step);
  }

  static double _calculateStepSize(double start, double end) {
    final range = end - start;
    if (range <= 5) return 1.0;
    if (range <= 10) return 2.0;
    return 5.0;
  }

  static List<double> _collectValues(List<ProcessedBMIData> data) {
    return data
        .expand((d) => [d.minBMI, d.maxBMI, d.avgBMI])
        .where((value) => value > 0)
        .toList();
  }

  static double _calculateDynamicPadding(double range) {
    if (range <= 0) return _maxPaddingPercent;
    if (range > 20) return _minPaddingPercent;
    if (range < 5) return _maxPaddingPercent;
    return _maxPaddingPercent -
        ((range - 5) / 15) * (_maxPaddingPercent - _minPaddingPercent);
  }

  static List<double> _generateAxisValues(
      double start, double end, double step) {
    final values = <double>[];
    for (var value = start; value <= end; value += step) {
      values.add(value);
    }
    return values;
  }

  static ProcessedBMIData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBMIData> data,
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
}
