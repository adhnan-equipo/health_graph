// lib/steps/services/step_data_processor.dart
import 'dart:math';

import '../../models/date_range_type.dart';
import '../models/processed_step_data.dart';
import '../models/step_data.dart';

class StepDataProcessor {
  static const int maxDataPoints = 16;

  static List<ProcessedStepData> processData(
    List<StepData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate, {
    double zoomLevel = 1.0,
  }) {
    if (data.isEmpty) {
      return _generateEmptyDataPoints(dateRangeType, startDate, endDate);
    }

    // Group data by date based on view type
    final groupedData = _groupDataByDate(data, dateRangeType);
    List<ProcessedStepData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      if (measurements.isEmpty) {
        processedData.add(ProcessedStepData.empty(currentDate));
      } else {
        processedData.add(_processDataGroup(measurements, currentDate));
      }

      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    // Handle zoom level aggregation if needed
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  static ProcessedStepData _processDataGroup(
    List<StepData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedStepData.empty(date);
    }

    // For steps, we need to SUM all values in the period, not average
    final stepValues = measurements.map((m) => m.step).toList();

    // Calculate total steps for this period
    final totalSteps = stepValues.reduce((a, b) => a + b);

    // For step tracking, we typically want the total as our main value
    // Min/Max still make sense for individual readings
    final minSteps = stepValues.reduce(min);
    final maxSteps = stepValues.reduce(max);

    return ProcessedStepData(
      startDate: measurements.first.createDate,
      endDate: measurements.last.createDate,
      minSteps: minSteps,
      maxSteps: maxSteps,
      avgSteps: totalSteps.toDouble(),
      // This is actually total steps now
      stdDev: _calculateStdDev(stepValues.map((v) => v.toDouble()).toList()),
      dataPointCount: measurements.length,
      originalMeasurements: measurements,
      totalSteps: totalSteps, // Add explicit total field
    );
  }

  // Rest of the methods remain the same...
  static Map<String, List<StepData>> _groupDataByDate(
    List<StepData> data,
    DateRangeType dateRangeType,
  ) {
    final groupedData = <String, List<StepData>>{};

    for (var item in data) {
      final key = _getDateKey(item.createDate, dateRangeType);
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return groupedData;
  }

  static String _getDateKey(DateTime date, DateRangeType dateRangeType) {
    switch (dateRangeType) {
      case DateRangeType.day:
        return '${date.year}-${date.month}-${date.day}-${date.hour}';
      case DateRangeType.week:
      case DateRangeType.month:
        return '${date.year}-${date.month}-${date.day}';
      case DateRangeType.year:
        return '${date.year}-${date.month}';
    }
  }

  static DateTime _getNextDate(DateTime date, DateRangeType dateRangeType) {
    switch (dateRangeType) {
      case DateRangeType.day:
        return date.add(const Duration(hours: 1));
      case DateRangeType.week:
      case DateRangeType.month:
        return date.add(const Duration(days: 1));
      case DateRangeType.year:
        return DateTime(date.year, date.month + 1, 1);
    }
  }

  static double _calculateStdDev(List<double> values) {
    if (values.length <= 1) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  // Updated aggregation to sum steps instead of averaging
  static List<ProcessedStepData> _aggregateProcessedData(
    List<ProcessedStepData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedStepData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedStepData.empty(chunk.first.startDate));
        continue;
      }

      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      final allOriginalMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.createDate.compareTo(b.createDate));

      // Sum all steps in this aggregated period
      final totalStepsInPeriod =
          validData.fold(0.0, (sum, d) => sum + d.avgSteps);

      result.add(ProcessedStepData(
        startDate: chunk.first.startDate,
        endDate: chunk.last.endDate,
        minSteps: validData.map((d) => d.minSteps).reduce(min),
        maxSteps: validData.map((d) => d.maxSteps).reduce(max),
        avgSteps: totalStepsInPeriod,
        // Total steps for this aggregated period
        stdDev: _combinedStdDev(validData
            .map((d) => (d.stdDev, d.avgSteps, d.dataPointCount))
            .toList()),
        dataPointCount: validData.fold(0, (sum, d) => sum + d.dataPointCount),
        originalMeasurements: allOriginalMeasurements,
        totalSteps: totalStepsInPeriod.round(),
      ));
    }

    return result;
  }

  static double _combinedStdDev(
      List<(double stdDev, double mean, int count)> values) {
    if (values.isEmpty) return 0;
    final totalCount = values.fold(0, (sum, item) => sum + item.$3);
    if (totalCount <= 1) return values.first.$1;

    final combinedMean =
        values.fold(0.0, (sum, item) => sum + item.$2 * item.$3) / totalCount;

    final combinedVariance = values.fold(0.0, (sum, item) {
          final variance = item.$1 * item.$1;
          final meanDiffSquared = pow(item.$2 - combinedMean, 2);
          return sum + (variance + meanDiffSquared) * item.$3;
        }) /
        totalCount;

    return sqrt(combinedVariance);
  }

  static List<ProcessedStepData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedStepData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedStepData.empty(currentDate));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }
}
