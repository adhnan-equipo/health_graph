import 'dart:math' as math;

import '../../models/date_range_type.dart';
import '../models/heart_rate_data.dart';
import '../models/processed_heart_rate_data.dart';

class HeartRateDataProcessor {
  static const int maxDataPoints = 24;
  static const int minDataPointsBeforeAggregation = 8;

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

    // Create a copy to avoid modifying the original list
    final sortedData = List<HeartRateData>.from(data);
    // Sort by date
    sortedData.sort((a, b) => a.date.compareTo(b.date));

    // Group data by appropriate time intervals
    final groupedData = _groupDataByDate(sortedData, dateRangeType);
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

    // Skip if no valid values
    if (values.isEmpty) {
      return ProcessedHeartRateData.empty(date);
    }

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
      minValue = minValues.reduce(math.min);
      maxValue = maxValues.reduce(math.max);
    } else {
      // Otherwise use the recorded values
      minValue = values.reduce(math.min);
      maxValue = values.reduce(math.max);
    }

    // Calculate average value
    final avgValue = values.reduce((a, b) => a + b) / values.length;

    // Calculate standard deviation
    final stdDev = _calculateStdDev(values, avgValue);

    // Calculate HRV (Heart Rate Variability) from RR intervals if possible
    final hrv = _calculateHRV(measurements);

    // Determine resting heart rate (lowest value or explicit resting rate)
    final restingRate = restingRates.isNotEmpty
        ? restingRates.reduce(math.min)
        : (values.isNotEmpty ? values.reduce(math.min) : null);

    return ProcessedHeartRateData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: avgValue,
      dataPointCount: measurements.length,
      stdDev: stdDev,
      isRangeData: measurements.length > 1 || minValues.isNotEmpty,
      originalMeasurements: measurements,
      hrv: hrv,
      restingRate: restingRate,
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
  static double _calculateStdDev(List<int> values, double mean) {
    if (values.length <= 1) return 0;

    final sumSquaredDiffs = values.fold(0.0, (sum, value) {
      final diff = value - mean;
      return sum + (diff * diff);
    });

    return math.sqrt(sumSquaredDiffs / (values.length - 1));
  }

  /// Approximate HRV using adjacent measurements
  static double? _calculateHRV(List<HeartRateData> measurements) {
    if (measurements.length <= 1) return null;

    // Sort by date to ensure correct sequence
    measurements.sort((a, b) => a.date.compareTo(b.date));

    // Use RMSSD (Root Mean Square of Successive Differences) method
    // which is a time-domain measure of heart rate variability
    final rrIntervals = <double>[];
    double sumSquaredDiffs = 0.0;
    int validPairs = 0;

    for (var i = 1; i < measurements.length; i++) {
      final current = measurements[i];
      final previous = measurements[i - 1];

      // Skip if no valid heart rate
      if (current.value <= 0 || previous.value <= 0) continue;

      // Calculate approximate R-R intervals in ms (60000 ms / bpm)
      final currentRR = 60000 / current.value;
      final previousRR = 60000 / previous.value;

      rrIntervals.add(currentRR);

      // Only calculate differences for consecutive measurements that are close in time
      // (within 10 seconds of each other to avoid large gaps)
      if (current.date.difference(previous.date).inSeconds <= 10) {
        final diff = currentRR - previousRR;
        sumSquaredDiffs += diff * diff;
        validPairs++;
      }
    }

    if (validPairs == 0) return null;

    // Calculate RMSSD (Root Mean Square of Successive Differences)
    final rmssd = math.sqrt(sumSquaredDiffs / validPairs);

    // Calculate SDNN (Standard Deviation of NN intervals) as an alternative measure
    double? sdnn;
    if (rrIntervals.isNotEmpty) {
      final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
      final sumSquaredDeviations =
          rrIntervals.fold(0.0, (sum, rr) => sum + math.pow(rr - mean, 2));
      sdnn = math.sqrt(sumSquaredDeviations / rrIntervals.length);
    }

    // Return RMSSD as the primary HRV measure
    return rmssd;
  }

  /// Generate empty data points for the given date range
  static List<ProcessedHeartRateData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    final emptyPoints = <ProcessedHeartRateData>[];
    var currentDate = startDate;

    // Limit the maximum number of points to prevent excessive memory usage
    int pointCount = 0;
    final maxEmptyPoints = 100; // Reasonable limit for empty points

    while ((currentDate.isBefore(endDate) ||
            currentDate.isAtSameMomentAs(endDate)) &&
        pointCount < maxEmptyPoints) {
      emptyPoints.add(ProcessedHeartRateData.empty(currentDate));
      currentDate = _getNextDate(currentDate, dateRangeType);
      pointCount++;
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
      final end = math.min(i + chunkSize, data.length);
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

      // Limit the number of measurements to prevent memory issues
      final limitedMeasurements = allMeasurements.length > 100
          ? allMeasurements.sublist(0, 100)
          : allMeasurements;

      result.add(_aggregateChunk(validData, limitedMeasurements));
    }

    return result;
  }

  /// Aggregate a chunk of data points into a single data point
  static ProcessedHeartRateData _aggregateChunk(
    List<ProcessedHeartRateData> chunk,
    List<HeartRateData> allMeasurements,
  ) {
    // Calculate min, max, and average values
    final minValue = chunk.map((d) => d.minValue).reduce(math.min);
    final maxValue = chunk.map((d) => d.maxValue).reduce(math.max);

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

    // Calculate combined standard deviation with more numerical stability
    final stdDev = _combinedStdDev(
        chunk.map((d) => (d.stdDev, d.avgValue, d.dataPointCount)).toList());

    // Limit number of original measurements to preserve memory
    // Select key measurements like min, max, and a few representative points
    final limitedMeasurements = _limitMeasurements(allMeasurements, 50);

    return ProcessedHeartRateData(
      startDate: chunk.first.startDate,
      endDate: chunk.last.endDate,
      minValue: minValue,
      maxValue: maxValue,
      avgValue: avgValue,
      dataPointCount: totalWeight,
      stdDev: stdDev,
      isRangeData: true,
      originalMeasurements: limitedMeasurements,
      hrv: hrvValues.isEmpty
          ? null
          : hrvValues.reduce((a, b) => a + b) / hrvValues.length,
      restingRate: restingRates.isEmpty ? null : restingRates.reduce(math.min),
    );
  }

// New method to intelligently limit measurements
  static List<HeartRateData> _limitMeasurements(
      List<HeartRateData> measurements, int maxCount) {
    if (measurements.length <= maxCount) return measurements;

    // Sort by date
    measurements.sort((a, b) => a.date.compareTo(b.date));

    if (measurements.length <= 3) return measurements;

    // Always include first, last, min, and max points
    final result = <HeartRateData>[];
    result.add(measurements.first);

    // Find min and max values
    HeartRateData minHR = measurements[0];
    HeartRateData maxHR = measurements[0];

    for (var i = 1; i < measurements.length - 1; i++) {
      if (measurements[i].value < minHR.value) minHR = measurements[i];
      if (measurements[i].value > maxHR.value) maxHR = measurements[i];
    }

    // Add min and max if they're not already the first or last point
    if (minHR != measurements.first && minHR != measurements.last) {
      result.add(minHR);
    }

    if (maxHR != measurements.first &&
        maxHR != measurements.last &&
        maxHR != minHR) {
      result.add(maxHR);
    }

    // Add last point
    if (measurements.last != minHR && measurements.last != maxHR) {
      result.add(measurements.last);
    }

    // If we still have room, add evenly spaced points
    final remainingSlots = maxCount - result.length;
    if (remainingSlots > 0 && measurements.length > result.length) {
      final step = (measurements.length - 1) / (remainingSlots + 1);
      for (var i = 1; i <= remainingSlots; i++) {
        final index = (i * step).round();
        if (index > 0 && index < measurements.length) {
          final point = measurements[index];
          if (!result.contains(point)) {
            result.add(point);
          }
        }
      }
    }

    // Sort by date again to ensure correct order
    result.sort((a, b) => a.date.compareTo(b.date));

    return result;
  }

  /// Calculate combined standard deviation for aggregated data
  /// Calculate combined standard deviation for aggregated data with improved numerical stability
  static double _combinedStdDev(
    List<(double stdDev, double mean, int count)> values,
  ) {
    if (values.isEmpty) return 0;
    final totalCount = values.fold(0, (sum, item) => sum + item.$3);
    if (totalCount <= 1) return values.first.$1;

    // Calculate combined mean with Welford's online algorithm for numerical stability
    double combinedMean = 0.0;
    double m2 = 0.0;
    int count = 0;

    for (final item in values) {
      final itemMean = item.$2;
      final itemVariance = item.$1 * item.$1;
      final itemCount = item.$3;

      for (int i = 0; i < itemCount; i++) {
        count++;
        final delta = itemMean - combinedMean;
        combinedMean += delta / count;
        final delta2 = itemMean - combinedMean;
        m2 += delta * delta2;
      }

      // Add the internal variance of this group
      m2 += itemVariance * (itemCount - 1);
    }

    if (count <= 1) return 0.0;

    // Calculate final variance and return standard deviation
    final variance = m2 / (count - 1);
    return math.sqrt(math.max(0, variance)); // Ensure non-negative value
  }
}
