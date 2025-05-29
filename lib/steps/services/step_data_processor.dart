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

    // Group raw data by time periods based on view type
    final groupedData =
        _groupRawDataByPeriod(data, dateRangeType, startDate, endDate);
    List<ProcessedStepData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      final periodStart = _getPeriodStart(currentDate, dateRangeType);
      final periodEnd = _getPeriodEnd(currentDate, dateRangeType);

      if (measurements.isEmpty) {
        processedData.add(
            ProcessedStepData.empty(periodStart, periodEnd, dateRangeType));
      } else {
        processedData.add(_processRawDataGroup(
            measurements, periodStart, periodEnd, dateRangeType));
      }

      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    // Add annotations for highest/lowest periods based on display values
    _addAnnotations(processedData);

    // Handle zoom level aggregation if needed
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  static ProcessedStepData _processRawDataGroup(
    List<StepData> measurements,
    DateTime periodStart,
    DateTime periodEnd,
    DateRangeType dateRangeType,
  ) {
    if (measurements.isEmpty) {
      return ProcessedStepData.empty(periodStart, periodEnd, dateRangeType);
    }

    // Calculate total steps for this period
    final totalSteps =
        measurements.fold(0, (sum, measurement) => sum + measurement.step);

    // For individual measurements stats
    final stepValues = measurements.map((m) => m.step).toList();
    final minSteps = stepValues.reduce(min);
    final maxSteps = stepValues.reduce(max);
    final avgSteps = totalSteps / measurements.length;

    return ProcessedStepData(
      startDate: periodStart,
      endDate: periodEnd,
      minSteps: minSteps,
      maxSteps: maxSteps,
      avgSteps: avgSteps,
      stdDev: _calculateStdDev(stepValues.map((v) => v.toDouble()).toList()),
      dataPointCount: measurements.length,
      originalMeasurements: measurements,
      totalSteps: totalSteps,
      viewType: dateRangeType,
    );
  }

  static void _addAnnotations(List<ProcessedStepData> data) {
    if (data.isEmpty) return;

    final nonEmptyData = data.where((d) => !d.isEmpty).toList();
    if (nonEmptyData.isEmpty) return;

    // Find highest and lowest display values (not total steps)
    var highestData = nonEmptyData.first;
    var lowestData = nonEmptyData.first;

    for (var item in nonEmptyData) {
      if (item.displayValue > highestData.displayValue) {
        highestData = item;
      }
      if (item.displayValue < lowestData.displayValue) {
        lowestData = item;
      }
    }

    // Mark highest and lowest (if they're different)
    if (highestData != lowestData && nonEmptyData.length > 2) {
      final highestIndex = data.indexOf(highestData);
      final lowestIndex = data.indexOf(lowestData);

      if (highestIndex >= 0) {
        data[highestIndex] = data[highestIndex].copyWith(isHighest: true);
      }
      if (lowestIndex >= 0) {
        data[lowestIndex] = data[lowestIndex].copyWith(isLowest: true);
      }
    }
  }

  // Rest of the helper methods remain similar but updated for new period handling
  static Map<String, List<StepData>> _groupRawDataByPeriod(
    List<StepData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    final groupedData = <String, List<StepData>>{};

    for (var item in data) {
      if (item.createDate.isBefore(startDate) ||
          item.createDate.isAfter(endDate)) {
        continue;
      }

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

  static DateTime _getPeriodStart(DateTime date, DateRangeType dateRangeType) {
    switch (dateRangeType) {
      case DateRangeType.day:
        return DateTime(date.year, date.month, date.day, date.hour);
      case DateRangeType.week:
      case DateRangeType.month:
        return DateTime(date.year, date.month, date.day);
      case DateRangeType.year:
        return DateTime(date.year, date.month, 1);
    }
  }

  static DateTime _getPeriodEnd(DateTime date, DateRangeType dateRangeType) {
    switch (dateRangeType) {
      case DateRangeType.day:
        return DateTime(date.year, date.month, date.day, date.hour, 59, 59);
      case DateRangeType.week:
      case DateRangeType.month:
        return DateTime(date.year, date.month, date.day, 23, 59, 59);
      case DateRangeType.year:
        return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
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
        result.add(
            ProcessedStepData.empty(chunk.first.startDate, chunk.last.endDate));
        continue;
      }

      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      final allOriginalMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.createDate.compareTo(b.createDate));

      final totalStepsInPeriod =
          validData.fold(0, (sum, d) => sum + d.totalStepsInPeriod);

      result.add(ProcessedStepData(
        startDate: chunk.first.startDate,
        endDate: chunk.last.endDate,
        minSteps: validData.map((d) => d.minSteps).reduce(min),
        maxSteps: validData.map((d) => d.maxSteps).reduce(max),
        avgSteps: totalStepsInPeriod / validData.length,
        stdDev: _combinedStdDev(validData
            .map((d) => (d.stdDev, d.avgSteps, d.dataPointCount))
            .toList()),
        dataPointCount: validData.fold(0, (sum, d) => sum + d.dataPointCount),
        originalMeasurements: allOriginalMeasurements,
        totalSteps: totalStepsInPeriod,
        viewType: validData.first.viewType,
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
      final periodStart = _getPeriodStart(currentDate, dateRangeType);
      final periodEnd = _getPeriodEnd(currentDate, dateRangeType);
      emptyPoints
          .add(ProcessedStepData.empty(periodStart, periodEnd, dateRangeType));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }
}
