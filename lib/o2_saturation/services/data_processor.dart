import 'dart:math';

import '../../blood_pressure/models/date_range_type.dart';
import '../models/o2_saturation_data.dart';
import '../models/processed_o2_saturation_data.dart';

class O2SaturationDataProcessor {
  static const int maxDataPoints = 16;
  static const int minDataPointsBeforeAggregation = 8;

  static List<ProcessedO2SaturationData> processData(
    List<O2SaturationData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate, {
    double zoomLevel = 1.0,
  }) {
    if (data.isEmpty) {
      return _generateEmptyDataPoints(dateRangeType, startDate, endDate);
    }

    final groupedData = _groupDataByDate(data, dateRangeType);
    List<ProcessedO2SaturationData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      if (measurements.isEmpty) {
        processedData.add(ProcessedO2SaturationData.empty(currentDate));
      } else {
        processedData.add(_processDataGroup(measurements, currentDate));
      }

      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  static Map<String, List<O2SaturationData>> _groupDataByDate(
    List<O2SaturationData> data,
    DateRangeType dateRangeType,
  ) {
    final groupedData = <String, List<O2SaturationData>>{};

    for (var item in data) {
      final key = _getDateKey(item.date, dateRangeType);
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

  static ProcessedO2SaturationData _processDataGroup(
    List<O2SaturationData> measurements,
    DateTime date,
  ) {
    if (measurements.isEmpty) {
      return ProcessedO2SaturationData.empty(date);
    }

    final values =
        measurements.map((m) => m.o2Value ?? 0).where((v) => v > 0).toList();

    final pulseRates = measurements
        .map((m) => m.pulseRate)
        .where((v) => v != null)
        .cast<int>()
        .toList();

    return ProcessedO2SaturationData(
      startDate: measurements.first.date,
      endDate: measurements.last.date,
      minValue: values.reduce(min),
      maxValue: values.reduce(max),
      dataPointCount: measurements.length,
      avgValue: values.reduce((a, b) => a + b) / values.length,
      stdDev: _calculateStdDev(values),
      // isRangeData: measurements.length > 1,
      originalMeasurements: measurements,
      avgPulseRate: pulseRates.isNotEmpty
          ? pulseRates.reduce((a, b) => a + b) / pulseRates.length
          : null,
      minPulseRate: pulseRates.isNotEmpty ? pulseRates.reduce(min) : null,
      maxPulseRate: pulseRates.isNotEmpty ? pulseRates.reduce(max) : null,
    );
  }

  static double _calculateStdDev(List<int> values) {
    if (values.length <= 1) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  static List<ProcessedO2SaturationData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedO2SaturationData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      emptyPoints.add(ProcessedO2SaturationData.empty(currentDate));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }

  static List<ProcessedO2SaturationData> _aggregateProcessedData(
    List<ProcessedO2SaturationData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedO2SaturationData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedO2SaturationData.empty(chunk.first.startDate));
        continue;
      }

      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      result.add(_aggregateChunk(validData));
    }

    return result;
  }

  static ProcessedO2SaturationData _aggregateChunk(
    List<ProcessedO2SaturationData> chunk,
  ) {
    final allMeasurements = chunk.expand((d) => d.originalMeasurements).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final values = chunk.expand((d) => [d.minValue, d.maxValue]).toList();
    final pulseRates = chunk
        .where((d) => d.avgPulseRate != null)
        .map((d) => (d.avgPulseRate!, d.dataPointCount))
        .toList();

    return ProcessedO2SaturationData(
      startDate: chunk.first.startDate,
      endDate: chunk.last.endDate,
      minValue: values.reduce(min),
      maxValue: values.reduce(max),
      dataPointCount: chunk.fold(0, (sum, d) => sum + d.dataPointCount),
      avgValue: _weightedAverage(
          chunk.map((d) => (d.avgValue, d.dataPointCount)).toList()),
      stdDev: _combinedStdDev(
          chunk.map((d) => (d.stdDev, d.avgValue, d.dataPointCount)).toList()),
      // isRangeData: true,
      originalMeasurements: allMeasurements,
      avgPulseRate: pulseRates.isNotEmpty ? _weightedAverage(pulseRates) : null,
      minPulseRate: chunk
          .where((d) => d.minPulseRate != null)
          .map((d) => d.minPulseRate!)
          .reduce(min),
      maxPulseRate: chunk
          .where((d) => d.maxPulseRate != null)
          .map((d) => d.maxPulseRate!)
          .reduce(max),
    );
  }

  static double _weightedAverage(List<(double value, int weight)> values) {
    if (values.isEmpty) return 0;
    final totalWeight = values.fold(0, (sum, item) => sum + item.$2);
    if (totalWeight == 0) return 0;
    return values.fold(0.0, (sum, item) => sum + item.$1 * item.$2) /
        totalWeight;
  }

  static double _combinedStdDev(
    List<(double stdDev, double mean, int count)> values,
  ) {
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
