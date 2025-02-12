// lib/services/heart_rate_data_processor.dart
import '../../blood_pressure/models/date_range_type.dart';
import '../models/heart_rate_data.dart';
import '../models/processed_heart_rate_data.dart';

class HeartRateDataProcessor {
  static const int maxDataPoints = 16;
  static const int minDataPointsBeforeAggregation = 8;

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

    // Group data by date based on view type
    final groupedData = _groupDataByDate(data, dateRangeType);
    List<ProcessedHeartRateData> processedData = [];

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

    // Handle zoom level aggregation if needed
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

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

  static ProcessedHeartRateData _processDataGroup(
    List<HeartRateData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedHeartRateData.empty(date);
    }

    final values = measurements.map((m) => m.value).toList();
    final restingRates = measurements
        .map((m) => m.restingRate)
        .where((r) => r != null)
        .cast<int>()
        .toList();

    return ProcessedHeartRateData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minValue: values.reduce((a, b) => a < b ? a : b),
      maxValue: values.reduce((a, b) => a > b ? a : b),
      avgValue: values.reduce((a, b) => a + b) / values.length,
      dataPointCount: measurements.length,
      stdDev: _calculateStdDev(values),
      isRangeData: measurements.length > 1,
      originalMeasurements: measurements,
      hrv: _calculateHRV(measurements),
      restingRate: restingRates.isNotEmpty
          ? restingRates.reduce((a, b) => a < b ? a : b)
          : null,
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

  static List<ProcessedHeartRateData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedHeartRateData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedHeartRateData.empty(currentDate));

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

  static List<ProcessedHeartRateData> _aggregateProcessedData(
    List<ProcessedHeartRateData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedHeartRateData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      // Skip if all data points in chunk are empty
      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedHeartRateData.empty(chunk.first.startDate));
        continue;
      }

      // Filter out empty data points
      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      // Process valid data
      result.add(_aggregateChunk(validData));
    }

    return result;
  }

  static ProcessedHeartRateData _aggregateChunk(
    List<ProcessedHeartRateData> chunk,
  ) {
    // Collect all original measurements
    final allMeasurements = chunk.expand((d) => d.originalMeasurements).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final values = chunk.map((d) => d.avgValue).toList();
    final restingRates = chunk
        .map((d) => d.restingRate)
        .where((r) => r != null)
        .cast<int>()
        .toList();

    return ProcessedHeartRateData(
      startDate: chunk.first.startDate,
      endDate: chunk.last.endDate,
      minValue: chunk.map((d) => d.minValue).reduce((a, b) => a < b ? a : b),
      maxValue: chunk.map((d) => d.maxValue).reduce((a, b) => a > b ? a : b),
      avgValue: values.reduce((a, b) => a + b) / values.length,
      dataPointCount: chunk.fold(0, (sum, d) => sum + d.dataPointCount),
      stdDev: _calculateStdDev(values.map((v) => v.round()).toList()),
      isRangeData: true,
      originalMeasurements: allMeasurements,
      hrv: chunk.map((d) => d.hrv).whereType<double>().isEmpty
          ? null
          : chunk
                  .map((d) => d.hrv)
                  .whereType<double>()
                  .reduce((a, b) => a + b) /
              chunk.map((d) => d.hrv).whereType<double>().length,
      restingRate: restingRates.isEmpty
          ? null
          : restingRates.reduce((a, b) => a < b ? a : b),
    );
  }

  static double _calculateStdDev(List<int> values) {
    if (values.length <= 1) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return (squaredDiffs.reduce((a, b) => a + b) / (values.length - 1)).sqrt();
  }

  static double _calculateHRV(List<HeartRateData> measurements) {
    if (measurements.length <= 1) return 0;
    final rrIntervals = <double>[];

    for (var i = 1; i < measurements.length; i++) {
      final current = measurements[i];
      final previous = measurements[i - 1];

      final timeDiff = current.date.difference(previous.date).inMilliseconds;
      if (timeDiff > 0) {
        rrIntervals.add(60000 / current.value - 60000 / previous.value);
      }
    }

    if (rrIntervals.isEmpty) return 0;
    return _calculateStdDev(rrIntervals.map((r) => r.round()).toList());
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double y = 1;
    double e = 0.000001;
    while ((x - y) > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
