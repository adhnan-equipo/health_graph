import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';

class HitTester {
  ProcessedBloodPressureData? hitTestValue(
    Offset position,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
    List<int> yAxisValues,
    double minValue,
    double maxValue,
  ) {
    if (data.isEmpty) return null;
    final xStep = chartArea.width / (data.length - 1);
    const hitArea = 10.0;

    for (var i = 0; i < data.length; i++) {
      final x = chartArea.left + (i * xStep);
      final entry = data[i];
      final positions = _calculateDataPointPositions(
        entry,
        x,
        chartArea,
        yAxisValues,
        minValue,
        maxValue,
      );

      if ((position.dx - x).abs() <= hitArea) {
        // Check points
        if (_isNearPoint(position, positions.maxSystolicPoint) ||
            _isNearPoint(position, positions.minSystolicPoint) ||
            _isNearPoint(position, positions.maxDiastolicPoint) ||
            _isNearPoint(position, positions.minDiastolicPoint)) {
          return entry;
        }

        // Check connector line
        if (_isNearLine(
          position,
          positions.minSystolicPoint,
          positions.maxDiastolicPoint,
        )) {
          return entry;
        }
      }
    }
    return null;
  }

  ({
    Offset maxSystolicPoint,
    Offset minSystolicPoint,
    Offset maxDiastolicPoint,
    Offset minDiastolicPoint,
  }) _calculateDataPointPositions(
    ProcessedBloodPressureData entry,
    double x,
    Rect chartArea,
    List<int> yAxisValues,
    double minValue,
    double maxValue,
  ) {
    final positions = (
      maxSystolicPoint: Offset(
        x,
        getYPosition(
            entry.maxSystolic.toDouble(), chartArea, minValue, maxValue),
      ),
      minSystolicPoint: Offset(
        x,
        getYPosition(
            entry.minSystolic.toDouble(), chartArea, minValue, maxValue),
      ),
      maxDiastolicPoint: Offset(
        x,
        getYPosition(
            entry.maxDiastolic.toDouble(), chartArea, minValue, maxValue),
      ),
      minDiastolicPoint: Offset(
        x,
        getYPosition(
            entry.minDiastolic.toDouble(), chartArea, minValue, maxValue),
      ),
    );
    print('Calculated positions for ${entry.dateLabel}: $positions');
    return positions;
  }

  double getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  bool _isNearLine(Offset point, Offset lineStart, Offset lineEnd) {
    const maxDistance = 10.0;

    // Calculate the distance from point to line
    final a = point - lineStart;
    final b = lineEnd - lineStart;
    final bLen = b.distance;

    if (bLen == 0) return false;

    final t = (a.dx * b.dx + a.dy * b.dy) / (bLen * bLen);

    // If closest point is outside the line segment, return false
    if (t < 0 || t > 1) return false;

    final projection = lineStart + (b * t);
    final distance = (point - projection).distance;

    return distance <= maxDistance;
  }

  bool _isNearPoint(Offset position, Offset point) {
    return (position - point).distance <= 30.0;
  }
}
