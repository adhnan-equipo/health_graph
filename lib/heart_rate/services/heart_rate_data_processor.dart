// lib/heart_rate/services/heart_rate_data_processor.dart
import 'dart:math';

import '../../models/date_range_type.dart';
import '../models/heart_rate_data.dart';
import '../models/processed_heart_rate_data.dart';

class HeartRateDataProcessor {
  static const int maxDataPoints = 24;
  static const int minDataPointsBeforeAggregation = 10;

  /// Process heart rate data based on date range type and zoom level
  static List<ProcessedHeartRateData> processData(
    List<HeartRateData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate, {
    double zoomLevel = 1.0,
  }) {
    if (data.isEmpty) {
      return _generateEmptyDataPoints(dateRangeType, startDate, endDate);
    }

    // Sort by date
    data.sort((a, b) => a.date.compareTo(b.date));

    // Group data by appropriate time intervals
    final groupedData = _groupDataByDate(data, dateRangeType);
    List<ProcessedHeartRateData> processedData = [];

    // Generate data points for the entire date range
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      if (measurements.isEmpty) {
        processedData.add(ProcessedHeartRateData.empty(currentDate));
      } else {
        processedData.add(_processDataGroup(measurements, currentDate));
      }

      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    // Check if we have any real data
    bool hasRealData = processedData.any((data) => !data.isEmpty);

    // If no real data exists, return an empty list
    if (!hasRealData) {
      return [];
    }

    // Apply zoom level - aggregate data if too many points
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  /// Group data by appropriate date intervals
  static Map<String, List<HeartRateData>> _groupDataByDate(
    List<HeartRateData> data,
    DateRangeType dateRangeType,
  ) {
    final groupedData = <String, List<HeartRateData>>{};

    for (var item in data) {
      final key = _getDateKey(item.date, dateRangeType);
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return groupedData;
  }

  /// Process a group of measurements into a single data point
  static ProcessedHeartRateData _processDataGroup(
    List<HeartRateData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedHeartRateData.empty(date);
    }

    // Extract heart rate values
    final values = measurements.map((m) => m.value).toList();

    // Extract min/max values if available
    final minValues = measurements
        .where((m) => m.minValue != null)
        .map((m) => m.minValue!)
        .toList();

    final maxValues = measurements
        .where((m) => m.maxValue != null)
        .map((m) => m.maxValue!)
        .toList();

    // Extract resting rates if available
    final restingRates = measurements
        .where((m) => m.restingRate != null)
        .map((m) => m.restingRate!)
        .toList();

    // Calculate min and max values
    int minValue;
    int maxValue;

    if (minValues.isNotEmpty && maxValues.isNotEmpty) {
      // If we have explicit min/max values
      minValue = minValues.reduce(min);
      maxValue = maxValues.reduce(max);
    } else {
      // Otherwise use the recorded values
      minValue = values.reduce(min);
      maxValue = values.reduce(max);
    }

    return ProcessedHeartRateData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: values.reduce((a, b) => a + b) / values.length,
      dataPointCount: measurements.length,
      stdDev: _calculateStdDev(values),
      isRangeData: measurements.length > 1 || minValues.isNotEmpty,
      originalMeasurements: measurements,
      hrv: _calculateHRV(measurements),
      restingRate: restingRates.isEmpty
          ? null
          : restingRates.reduce((a, b) => a < b ? a : b),
    );
  }

  /// Get a consistent key format for the given date and range type
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

  /// Get the next date increment based on range type
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

  /// Calculate standard deviation of a set of values
  static double _calculateStdDev(List<int> values) {
    if (values.length <= 1) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSquaredDiffs = values.fold(0.0, (sum, value) {
      final diff = value - mean;
      return sum + (diff * diff);
    });

    return sqrt(sumSquaredDiffs / (values.length - 1));
  }

  /// Approximate HRV using adjacent measurements
  static double _calculateHRV(List<HeartRateData> measurements) {
    if (measurements.length <= 1) return 0;

    final rmssd = <double>[];

    for (var i = 1; i < measurements.length; i++) {
      final current = measurements[i];
      final previous = measurements[i - 1];

      // Calculate approximate R-R intervals in ms
      final currentRR = 60000 / current.value;
      final previousRR = 60000 / previous.value;

      // Square the difference
      final diff = currentRR - previousRR;
      rmssd.add(diff * diff);
    }

    if (rmssd.isEmpty) return 0;

    // Root mean square of successive differences
    final meanSquare = rmssd.reduce((a, b) => a + b) / rmssd.length;
    return sqrt(meanSquare);
  }

  /// Generate empty data points for the given date range
  static List<ProcessedHeartRateData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    final emptyPoints = <ProcessedHeartRateData>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedHeartRateData.empty(currentDate));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }

  /// Aggregate processed data to reduce number of points
  static List<ProcessedHeartRateData> _aggregateProcessedData(
    List<ProcessedHeartRateData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedHeartRateData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = min(i + chunkSize, data.length);
      final chunk = data.sublist(i, end);

      // Skip if all data points in chunk are empty
      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedHeartRateData.empty(chunk.first.startDate));
        continue;
      }

      // Filter out empty data points
      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      // Collect all original measurements
      final allMeasurements = validData
          .expand((d) => d.originalMeasurements)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      result.add(_aggregateChunk(validData, allMeasurements));
    }

    return result;
  }

  /// Aggregate a chunk of data points into a single data point
  static ProcessedHeartRateData _aggregateChunk(
    List<ProcessedHeartRateData> chunk,
    List<HeartRateData> allMeasurements,
  ) {
    // Calculate min, max, and average values
    final minValue = chunk.map((d) => d.minValue).reduce(min);
    final maxValue = chunk.map((d) => d.maxValue).reduce(max);

    // Weighted average for more accurate representation
    final totalWeight = chunk.fold(0, (sum, d) => sum + d.dataPointCount);
    final avgValue = chunk.fold(
          0.0,
          (sum, d) => sum + (d.avgValue * d.dataPointCount),
        ) /
        totalWeight;

    // Process resting rates (if available)
    final restingRates = chunk
        .where((d) => d.restingRate != null)
        .map((d) => d.restingRate!)
        .toList();

    // Process HRV values (if available)
    final hrvValues =
        chunk.where((d) => d.hrv != null).map((d) => d.hrv!).toList();

    return ProcessedHeartRateData(
      startDate: chunk.first.startDate,
      endDate: chunk.last.endDate,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: avgValue,
      dataPointCount: totalWeight,
      stdDev: _combinedStdDev(
          chunk.map((d) => (d.stdDev, d.avgValue, d.dataPointCount)).toList()),
      isRangeData: true,
      originalMeasurements: allMeasurements,
      hrv: hrvValues.isEmpty
          ? null
          : hrvValues.reduce((a, b) => a + b) / hrvValues.length,
      restingRate: restingRates.isEmpty ? null : restingRates.reduce(min),
    );
  }

  /// Calculate combined standard deviation for aggregated data
  static double _combinedStdDev(
    List<(double stdDev, double mean, int count)> values,
  ) {
    if (values.isEmpty) return 0;
    final totalCount = values.fold(0, (sum, item) => sum + item.$3);
    if (totalCount <= 1) return values.first.$1;

    // Calculate combined mean
    final combinedMean =
        values.fold(0.0, (sum, item) => sum + item.$2 * item.$3) / totalCount;

    // Calculate combined variance
    final combinedVariance = values.fold(0.0, (sum, item) {
          final variance = item.$1 * item.$1;
          final meanDiffSquared = pow(item.$2 - combinedMean, 2);
          return sum + (variance + meanDiffSquared) * item.$3;
        }) /
        totalCount;

    return sqrt(combinedVariance);
  }

  /// Calculate square root manually for devices without math lib
  static double sqrt(double value) {
    if (value <= 0) return 0;
    double x = value;
    double y = 1;
    double e = 0.000001;
    while ((x - y) > e) {
      x = (x + y) / 2;
      y = value / x;
    }
    return x;
  }
}
