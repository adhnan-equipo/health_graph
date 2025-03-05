// lib/o2_saturation/services/o2_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';

class O2ChartCalculations {
  static ProcessedO2SaturationData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    const hitTestThreshold = 20.0;
    ProcessedO2SaturationData? closestPoint;
    double minDistance = double.infinity;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = calculateXPosition(i, data.length, chartArea);
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance < hitTestThreshold) {
        minDistance = distance;
        closestPoint = entry;
      }
    }

    return closestPoint;
  }

  // Helper method to check if a point is within the chart area
  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }

  // Modified method to return the tuple format expected by the chart
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedO2SaturationData> data,
  ) {
    if (data.isEmpty) {
      return _getDefaultRange();
    }

    // Collect all values including pulse rate if available
    final allValues = <double>[];

    // Gather O2 values
    for (var point in data) {
      if (!point.isEmpty) {
        allValues.addAll([
          point.minValue.toDouble(),
          point.maxValue.toDouble(),
          point.avgValue,
        ]);

        // Add pulse rate values if available
        if (point.avgPulseRate != null) {
          allValues.add(point.avgPulseRate!);
        }
        if (point.minPulseRate != null) {
          allValues.add(point.minPulseRate!.toDouble());
        }
        if (point.maxPulseRate != null) {
          allValues.add(point.maxPulseRate!.toDouble());
        }
      }
    }

    if (allValues.isEmpty) {
      return _getDefaultRange();
    }

    // Find actual min/max from data
    double minValue = allValues.reduce(min);
    double maxValue = allValues.reduce(max);

    // Calculate range with padding (10% on each side)
    final range = maxValue - minValue;
    final padding = range * 0.1;

    // Round min value down to nearest step (5 or 10 depending on range)
    // Ensure minValue is never higher than the minimum saturation value in the data
    minValue = max(0, minValue - padding);
    minValue = (minValue / 5).floor() * 5;

    // Ensure maxValue is never lower than the maximum saturation value in the data
    maxValue = min(100, maxValue + padding);
    maxValue = (maxValue / 5).ceil() * 5;

    // If data has a narrow range (e.g., 95-98%), extend range to make it more readable
    if (range < 10) {
      // Extend range to show at least 20 units if the range is small
      final minExtended = (minValue - 10).clamp(40.0, minValue);
      final maxExtended = (maxValue + 10).clamp(maxValue, 100.0);

      minValue = minExtended;
      maxValue = maxExtended;
    }

    // Never show values below 40% (typically not relevant for O2 saturation)
    minValue = max(40, minValue);

    // Calculate optimal step size
    var stepSize = _calculateOptimalStepSize(minValue, maxValue);

    // Generate axis values with better distribution
    final yAxisValues =
        _generateAxisValues(minValue.toInt(), maxValue.toInt(), stepSize);

    return (yAxisValues, minValue, maxValue);
  }

  static int _calculateOptimalStepSize(double min, double max) {
    final range = max - min;

    if (range <= 20) return 2;
    if (range <= 40) return 5;
    return 10;
  }

  static List<int> _generateAxisValues(int start, int end, int step) {
    final values = <int>[];
    for (var i = start; i <= end; i += step) {
      values.add(i);
    }

    // Ensure we have enough values for proper spacing
    if (values.length < 5) {
      final additionalStep = step ~/ 2;
      if (additionalStep > 0) {
        var additionalValue = start + additionalStep;

        while (additionalValue < end) {
          if (!values.contains(additionalValue)) {
            values.add(additionalValue);
          }
          additionalValue += step;
        }
        values.sort();
      }
    }

    return values;
  }

  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 85.0;
    const defaultMax = 100.0;
    const step = 5;
    final values =
        _generateAxisValues(defaultMin.toInt(), defaultMax.toInt(), step);
    return (values, defaultMin, defaultMax);
  }

  // Calculate X position based on index in data array
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0; // Increased for better visibility at edges
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 40.0; // Increased for better y-axis label visibility
    const rightPadding = 10.0;
    const topPadding = 10.0;
    const bottomPadding = 30.0; // Increased for better x-axis label visibility

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }
}
