// services/bmi_data_processor.dart
import 'dart:math';

import '../../models/date_range_type.dart';
import '../models/bmi_data.dart';
import '../models/processed_bmi_data.dart';

class BMIDataProcessor {
  static const int maxDataPoints = 16;
  static const int minDataPointsBeforeAggregation = 8;

  static List<ProcessedBMIData> processData(
    List<BMIData> data,
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
    List<ProcessedBMIData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      if (measurements.isEmpty) {
        processedData.add(ProcessedBMIData.empty(currentDate));
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

  static Map<String, List<BMIData>> _groupDataByDate(
    List<BMIData> data,
    DateRangeType dateRangeType,
  ) {
    final groupedData = <String, List<BMIData>>{};

    for (var item in data) {
      final key = _getDateKey(item.date, dateRangeType);
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return groupedData;
  }

  static ProcessedBMIData _processDataGroup(
    List<BMIData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedBMIData.empty(date);
    }

    final bmiValues = measurements.map((m) => m.bmi).toList();

    return ProcessedBMIData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minBMI: bmiValues.reduce(min),
      maxBMI: bmiValues.reduce(max),
      avgBMI: bmiValues.reduce((a, b) => a + b) / bmiValues.length,
      stdDev: _calculateStdDev(bmiValues),
      dataPointCount: measurements.length,
      originalMeasurements: measurements,
    );
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

  static List<ProcessedBMIData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedBMIData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedBMIData.empty(currentDate));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }

  static List<ProcessedBMIData> _aggregateProcessedData(
    List<ProcessedBMIData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedBMIData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedBMIData.empty(chunk.first.startDate));
        continue;
      }

      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      final allOriginalMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      result.add(ProcessedBMIData(
        startDate: chunk.first.startDate,
        endDate: chunk.last.endDate,
        minBMI: validData.map((d) => d.minBMI).reduce(min),
        maxBMI: validData.map((d) => d.maxBMI).reduce(max),
        avgBMI: _weightedAverage(
            validData.map((d) => (d.avgBMI, d.dataPointCount)).toList()),
        stdDev: _combinedStdDev(validData
            .map((d) => (d.stdDev, d.avgBMI, d.dataPointCount))
            .toList()),
        dataPointCount: validData.fold(0, (sum, d) => sum + d.dataPointCount),
        originalMeasurements: allOriginalMeasurements,
      ));
    }

    return result;
  }

  static double _weightedAverage(List<(double value, int weight)> values) {
    if (values.isEmpty) return 0;
    final totalWeight = values.fold(0, (sum, item) => sum + item.$2);
    if (totalWeight == 0) return 0;
    return values.fold(0.0, (sum, item) => sum + item.$1 * item.$2) /
        totalWeight;
  }
// Continuing from where we left off in BMIDataProcessor...

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

  static List<ProcessedBMIData> filterDataByDateRange(
    List<ProcessedBMIData> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    return data.where((point) {
      return (point.startDate.isAtSameMomentAs(startDate) ||
              point.startDate.isAfter(startDate)) &&
          (point.endDate.isAtSameMomentAs(endDate) ||
              point.endDate.isBefore(endDate));
    }).toList();
  }

  static double calculateTrendSlope(List<ProcessedBMIData> data) {
    if (data.length < 2) return 0;

    final validData = data.where((d) => !d.isEmpty).toList();
    if (validData.length < 2) return 0;

    // Simple linear regression
    final n = validData.length;
    final sumX = validData.fold(
        0.0, (sum, d) => sum + d.startDate.millisecondsSinceEpoch.toDouble());
    final sumY = validData.fold(0.0, (sum, d) => sum + d.avgBMI);
    final sumXY = validData.fold(
        0.0,
        (sum, d) =>
            sum + d.startDate.millisecondsSinceEpoch.toDouble() * d.avgBMI);
    final sumXX = validData.fold(
        0.0,
        (sum, d) =>
            sum +
            d.startDate.millisecondsSinceEpoch.toDouble() *
                d.startDate.millisecondsSinceEpoch.toDouble());

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  static Map<String, List<ProcessedBMIData>> groupDataByCategory(
      List<ProcessedBMIData> data) {
    return {
      'underweight': data.where((d) => d.maxBMI < 18.5).toList(),
      'normal': data.where((d) => d.maxBMI >= 18.5 && d.maxBMI < 25.0).toList(),
      'overweight':
          data.where((d) => d.maxBMI >= 25.0 && d.maxBMI < 30.0).toList(),
      'obese': data.where((d) => d.maxBMI >= 30.0).toList(),
    };
  }

  static Map<String, dynamic> calculateStatistics(List<ProcessedBMIData> data) {
    if (data.isEmpty) {
      return {
        'minBMI': 0.0,
        'maxBMI': 0.0,
        'avgBMI': 0.0,
        'stdDev': 0.0,
        'trend': 0.0,
        'totalMeasurements': 0,
      };
    }

    final validData = data.where((d) => !d.isEmpty).toList();
    if (validData.isEmpty) {
      return {
        'minBMI': 0.0,
        'maxBMI': 0.0,
        'avgBMI': 0.0,
        'stdDev': 0.0,
        'trend': 0.0,
        'totalMeasurements': 0,
      };
    }

    final allBMIs = validData
        .expand((d) => d.originalMeasurements)
        .map((m) => m.bmi)
        .toList();

    return {
      'minBMI': allBMIs.reduce(min),
      'maxBMI': allBMIs.reduce(max),
      'avgBMI': allBMIs.reduce((a, b) => a + b) / allBMIs.length,
      'stdDev': _calculateStdDev(allBMIs),
      'trend': calculateTrendSlope(validData),
      'totalMeasurements': allBMIs.length,
    };
  }

  static List<ProcessedBMIData> smoothData(
    List<ProcessedBMIData> data,
    int windowSize,
  ) {
    if (data.length < windowSize) return data;

    final smoothedData = <ProcessedBMIData>[];
    for (var i = 0; i < data.length; i++) {
      final start = (i - windowSize ~/ 2).clamp(0, data.length - 1);
      final end = (i + windowSize ~/ 2).clamp(0, data.length - 1);
      final window = data.sublist(start, end + 1);

      if (window.every((d) => d.isEmpty)) {
        smoothedData.add(ProcessedBMIData.empty(data[i].startDate));
        continue;
      }

      final validWindow = window.where((d) => !d.isEmpty).toList();
      if (validWindow.isEmpty) continue;

      final allMeasurements = validWindow
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      smoothedData.add(ProcessedBMIData(
        startDate: data[i].startDate,
        endDate: data[i].endDate,
        minBMI: validWindow.map((d) => d.minBMI).reduce(min),
        maxBMI: validWindow.map((d) => d.maxBMI).reduce(max),
        avgBMI: validWindow.fold(0.0, (sum, d) => sum + d.avgBMI) /
            validWindow.length,
        stdDev: _calculateStdDev(validWindow.map((d) => d.avgBMI).toList()),
        dataPointCount: validWindow.fold(0, (sum, d) => sum + d.dataPointCount),
        originalMeasurements: allMeasurements,
      ));
    }

    return smoothedData;
  }

  static List<double> calculatePercentiles(
    List<ProcessedBMIData> data,
    List<int> percentiles,
  ) {
    if (data.isEmpty) {
      return List.filled(percentiles.length, 0);
    }

    final validBMIs = data
        .where((d) => !d.isEmpty)
        .expand((d) => d.originalMeasurements)
        .map((m) => m.bmi)
        .toList()
      ..sort();

    if (validBMIs.isEmpty) {
      return List.filled(percentiles.length, 0);
    }

    return percentiles.map((percentile) {
      final index = ((percentile / 100) * (validBMIs.length - 1)).round();
      return validBMIs[index];
    }).toList();
  }
}
