import 'package:flutter/material.dart';

import '../models/processed_o2_saturation_data.dart';

class O2HitTester {
  ProcessedO2SaturationData? hitTestValue(
    Offset position,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
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
        // Check main O2 points
        if (_isNearPoint(position, positions.mainPoint)) {
          return entry;
        }

        // Check pulse rate point if available
        if (entry.avgPulseRate != null &&
            _isNearPoint(position, positions.pulsePoint!)) {
          return entry;
        }

        // Check range line if multiple readings
        if (entry.dataPointCount > 1 &&
            _isNearLine(
              position,
              positions.minPoint,
              positions.maxPoint,
            )) {
          return entry;
        }
      }
    }
    return null;
  }

  ({
    Offset mainPoint,
    Offset minPoint,
    Offset maxPoint,
    Offset? pulsePoint,
  }) _calculateDataPointPositions(
    ProcessedO2SaturationData entry,
    double x,
    Rect chartArea,
    List<int> yAxisValues,
    double minValue,
    double maxValue,
  ) {
    return (
      mainPoint: Offset(
        x,
        _getYPosition(entry.avgValue, chartArea, minValue, maxValue),
      ),
      minPoint: Offset(
        x,
        _getYPosition(entry.minValue.toDouble(), chartArea, minValue, maxValue),
      ),
      maxPoint: Offset(
        x,
        _getYPosition(entry.maxValue.toDouble(), chartArea, minValue, maxValue),
      ),
      pulsePoint: entry.avgPulseRate != null
          ? Offset(
              x,
              _getYPosition(entry.avgPulseRate!.toDouble(), chartArea, minValue,
                  maxValue),
            )
          : null,
    );
  }

  double _getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  bool _isNearLine(Offset point, Offset lineStart, Offset lineEnd) {
    const maxDistance = 10.0;

    final a = point - lineStart;
    final b = lineEnd - lineStart;
    final bLen = b.distance;

    if (bLen == 0) return false;

    final t = (a.dx * b.dx + a.dy * b.dy) / (bLen * bLen);

    if (t < 0 || t > 1) return false;

    final projection = lineStart + (b * t);
    final distance = (point - projection).distance;

    return distance <= maxDistance;
  }

  bool _isNearPoint(Offset position, Offset point) {
    return (position - point).distance <= 30.0;
  }
}
