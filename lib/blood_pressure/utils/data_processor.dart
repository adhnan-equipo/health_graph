import 'dart:math';

import '../../models/date_range_type.dart';
import '../models/blood_pressure_data.dart';
import '../models/processed_blood_pressure_data.dart';

class BloodPressureDataProcessor {
  // Configurable parameters for data processing
  static const int maxDataPoints = 32; // Max data points to display
  static const int minDataPointsBeforeAggregation =
      8; // Threshold before aggregation

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

    // First pass: group data by appropriate time periods
    final groupedData = _groupDataByDate(data, dateRangeType);

    // Second pass: create processed data objects with proper time intervals
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

    // Third pass: adjust data density based on zoom level
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  // Initial grouping of data by appropriate time periods
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

  // Process a group of measurements into a single data point
  static ProcessedBloodPressureData _processDataGroup(
    List<BloodPressureData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedBloodPressureData.empty(date);
    }

    // Sort measurements by date for consistent processing
    measurements.sort((a, b) => a.date.compareTo(b.date));

    // Extract systolic and diastolic values, handling both single and range readings
    List<int> systolicValues = [];
    List<int> diastolicValues = [];

    for (var m in measurements) {
      if (m.isRangeReading) {
        // Range reading - add both min and max
        if (m.minSystolic != null) systolicValues.add(m.minSystolic!);
        if (m.maxSystolic != null) systolicValues.add(m.maxSystolic!);
        if (m.minDiastolic != null) diastolicValues.add(m.minDiastolic!);
        if (m.maxDiastolic != null) diastolicValues.add(m.maxDiastolic!);
      } else {
        // Single reading
        if (m.systolic != null) systolicValues.add(m.systolic!);
        if (m.diastolic != null) diastolicValues.add(m.diastolic!);
      }
    }

    // Handle empty or incomplete data
    if (systolicValues.isEmpty || diastolicValues.isEmpty) {
      return ProcessedBloodPressureData.empty(date);
    }

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
      isRangeData: measurements.length > 1 || measurements.first.isRangeReading,
      originalMeasurements: measurements,
    );
  }

  // Create a key string that represents a time interval for grouping
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

  // Move to the next time interval
  static DateTime _getNextDate(DateTime date, DateRangeType dateRangeType) {
    switch (dateRangeType) {
      case DateRangeType.day:
        return date.add(const Duration(hours: 1));
      case DateRangeType.week:
      case DateRangeType.month:
        return date.add(const Duration(days: 1));
      case DateRangeType.year:
        // Handle leap years and variable month lengths correctly
        if (date.month == 12) {
          return DateTime(date.year + 1, 1, 1);
        } else {
          return DateTime(date.year, date.month + 1, 1);
        }
    }
  }

  // Calculate standard deviation for a list of values
  static double _calculateStdDev(List<int> values) {
    if (values.length <= 1) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    return sqrt(
            squaredDiffs.reduce((a, b) => a + b as num) / (values.length - 1))
        as double;
  }

  // Generate empty data points for a date range
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
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }

  // Aggregate data to reduce density when there are too many points
  static List<ProcessedBloodPressureData> _aggregateProcessedData(
    List<ProcessedBloodPressureData> data,
    int targetCount,
  ) {
    // Calculate how many points to group into each aggregate
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
      if (validData.isEmpty) {
        result.add(ProcessedBloodPressureData.empty(chunk.first.startDate));
        continue;
      }

      // Collect all original measurements from the chunk
      final allOriginalMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Create an aggregated data point
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

  // Calculate weighted average across multiple data points
  static double _weightedAverage(List<(double value, int weight)> values) {
    if (values.isEmpty) return 0;

    final totalWeight = values.fold(0, (sum, item) => sum + item.$2);
    if (totalWeight == 0) return 0;

    return values.fold(0.0, (sum, item) => sum + item.$1 * item.$2) /
        totalWeight;
  }

  // Combine standard deviations across multiple data points
  static double _combinedStdDev(
      List<(double stdDev, double mean, int count)> values) {
    if (values.isEmpty) return 0;

    final totalCount = values.fold(0, (sum, item) => sum + item.$3);
    if (totalCount <= 1) return values.first.$1;

    // Calculate combined mean
    final combinedMean =
        values.fold(0.0, (sum, item) => sum + item.$2 * item.$3) / totalCount;

    // Calculate combined variance using the parallel axis theorem
    final combinedVariance = values.fold(0.0, (sum, item) {
          final variance = item.$1 * item.$1;
          final meanDiffSquared = pow(item.$2 - combinedMean, 2);
          return sum + (variance + meanDiffSquared) * item.$3;
        }) /
        totalCount;

    return sqrt(combinedVariance);
  }
}
