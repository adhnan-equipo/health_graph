import 'dart:math';

import '../models/blood_pressure_data.dart';
import '../models/date_range_type.dart';
import '../models/processed_blood_pressure_data.dart';

class BloodPressureDataProcessor {
  static const int maxDataPoints = 16;
  static const int minDataPointsBeforeAggregation = 8;

  static List<ProcessedBloodPressureData> processData(
    List<BloodPressureData> data,
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
    List<ProcessedBloodPressureData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      if (measurements.isEmpty) {
        processedData.add(ProcessedBloodPressureData.empty(currentDate));
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

  static Map<String, List<BloodPressureData>> _groupDataByDate(
    List<BloodPressureData> data,
    DateRangeType dateRangeType,
  ) {
    final groupedData = <String, List<BloodPressureData>>{};

    for (var item in data) {
      final key = _getDateKey(item.date, dateRangeType);
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return groupedData;
  }

  static ProcessedBloodPressureData _processDataGroup(
    List<BloodPressureData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedBloodPressureData.empty(date);
    }

    final systolicValues =
        measurements.map((m) => m.systolic ?? 0).where((v) => v > 0).toList();
    final diastolicValues =
        measurements.map((m) => m.diastolic ?? 0).where((v) => v > 0).toList();

    return ProcessedBloodPressureData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minSystolic: systolicValues.reduce(min),
      maxSystolic: systolicValues.reduce(max),
      minDiastolic: diastolicValues.reduce(min),
      maxDiastolic: diastolicValues.reduce(max),
      dataPointCount: measurements.length,
      avgSystolic:
          systolicValues.reduce((a, b) => a + b) / systolicValues.length,
      avgDiastolic:
          diastolicValues.reduce((a, b) => a + b) / diastolicValues.length,
      systolicStdDev: _calculateStdDev(systolicValues),
      diastolicStdDev: _calculateStdDev(diastolicValues),
      isRangeData: measurements.length > 1,
      originalMeasurements: measurements, // Store original measurements
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

  static double _calculateStdDev(List<int> values) {
    if (values.length <= 1) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  static List<ProcessedBloodPressureData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedBloodPressureData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedBloodPressureData.empty(currentDate));

      switch (dateRangeType) {
        case DateRangeType.day:
          currentDate = currentDate.add(const Duration(hours: 1));
          break;
        case DateRangeType.week:
        case DateRangeType.month:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case DateRangeType.year:
          currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
          break;
      }
    }

    return emptyPoints;
  }

  static List<ProcessedBloodPressureData> _aggregateProcessedData(
    List<ProcessedBloodPressureData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedBloodPressureData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      // Skip if all data points in chunk are empty
      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedBloodPressureData.empty(chunk.first.startDate));
        continue;
      }

      // Filter out empty data points
      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      // Collect all original measurements from the chunk
      final allOriginalMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      result.add(ProcessedBloodPressureData(
        startDate: chunk.first.startDate,
        endDate: chunk.last.endDate,
        minSystolic: validData.map((d) => d.minSystolic).reduce(min),
        maxSystolic: validData.map((d) => d.maxSystolic).reduce(max),
        minDiastolic: validData.map((d) => d.minDiastolic).reduce(min),
        maxDiastolic: validData.map((d) => d.maxDiastolic).reduce(max),
        dataPointCount: validData.fold(0, (sum, d) => sum + d.dataPointCount),
        avgSystolic: _weightedAverage(
            validData.map((d) => (d.avgSystolic, d.dataPointCount)).toList()),
        avgDiastolic: _weightedAverage(
            validData.map((d) => (d.avgDiastolic, d.dataPointCount)).toList()),
        systolicStdDev: _combinedStdDev(validData
            .map((d) => (d.systolicStdDev, d.avgSystolic, d.dataPointCount))
            .toList()),
        diastolicStdDev: _combinedStdDev(validData
            .map((d) => (d.diastolicStdDev, d.avgDiastolic, d.dataPointCount))
            .toList()),
        isRangeData: true,
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
}
