// lib/sleep/services/sleep_data_processor.dart
import '../../models/date_range_type.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_data.dart';
import '../models/sleep_stage.dart';

class SleepDataProcessor {
  static const int maxDataPoints = 16;

  static List<ProcessedSleepData> processData(
    List<SleepData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate, {
    double zoomLevel = 1.0,
  }) {
    if (data.isEmpty) {
      return _generateEmptyDataPoints(dateRangeType, startDate, endDate);
    }

    // Group raw data by time periods
    final groupedData =
        _groupRawDataByPeriod(data, dateRangeType, startDate, endDate);
    List<ProcessedSleepData> processedData = [];

    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final key = _getDateKey(currentDate, dateRangeType);
      final measurements = groupedData[key] ?? [];

      final periodStart = _getPeriodStart(currentDate, dateRangeType);
      final periodEnd = _getPeriodEnd(currentDate, dateRangeType);

      if (measurements.isEmpty) {
        processedData.add(
            ProcessedSleepData.empty(periodStart, periodEnd, dateRangeType));
      } else {
        processedData.add(_processRawDataGroup(
            measurements, periodStart, periodEnd, dateRangeType));
      }

      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    // Add annotations for best/worst sleep periods
    _addAnnotations(processedData);

    // Handle zoom level aggregation
    final effectiveMaxPoints = (maxDataPoints * zoomLevel).round();
    if (processedData.length > effectiveMaxPoints) {
      return _aggregateProcessedData(processedData, effectiveMaxPoints);
    }

    return processedData;
  }

  static ProcessedSleepData _processRawDataGroup(
    List<SleepData> measurements,
    DateTime periodStart,
    DateTime periodEnd,
    DateRangeType dateRangeType,
  ) {
    if (measurements.isEmpty) {
      return ProcessedSleepData.empty(periodStart, periodEnd, dateRangeType);
    }

    // Calculate total sleep for this period
    int totalSleep = 0;
    final Map<SleepStage, int> aggregatedStages = {};
    List<DateTime> bedTimes = [];
    List<DateTime> wakeTimes = [];
    List<double> efficiencies = [];

    for (var measurement in measurements) {
      totalSleep += measurement.primarySleepValue;

      // Aggregate sleep stages
      final stages = measurement.availableStages;
      for (var entry in stages.entries) {
        aggregatedStages[entry.key] =
            (aggregatedStages[entry.key] ?? 0) + entry.value;
      }

      // Collect timing data
      if (measurement.bedTime != null) bedTimes.add(measurement.bedTime!);
      if (measurement.wakeTime != null) wakeTimes.add(measurement.wakeTime!);
      if (measurement.sleepEfficiency != null)
        efficiencies.add(measurement.sleepEfficiency!);
    }

    // Calculate average timings
    DateTime? avgBedTime;
    DateTime? avgWakeTime;
    if (bedTimes.isNotEmpty) {
      final avgBedMinutes =
          bedTimes.map((t) => t.hour * 60 + t.minute).reduce((a, b) => a + b) /
              bedTimes.length;
      final bedHour = (avgBedMinutes ~/ 60) % 24;
      final bedMinute = (avgBedMinutes % 60).round();
      avgBedTime = DateTime(periodStart.year, periodStart.month,
          periodStart.day, bedHour, bedMinute);
    }

    if (wakeTimes.isNotEmpty) {
      final avgWakeMinutes =
          wakeTimes.map((t) => t.hour * 60 + t.minute).reduce((a, b) => a + b) /
              wakeTimes.length;
      final wakeHour = (avgWakeMinutes ~/ 60) % 24;
      final wakeMinute = (avgWakeMinutes % 60).round();
      avgWakeTime = DateTime(periodStart.year, periodStart.month,
          periodStart.day, wakeHour, wakeMinute);
    }

    final avgEfficiency = efficiencies.isNotEmpty
        ? efficiencies.reduce((a, b) => a + b) / efficiencies.length
        : null;

    return ProcessedSleepData(
      startDate: periodStart,
      endDate: periodEnd,
      totalSleepMinutes: totalSleep,
      sleepStages: aggregatedStages,
      dataPointCount: measurements.length,
      originalMeasurements: measurements,
      viewType: dateRangeType,
      averageBedTime: avgBedTime,
      averageWakeTime: avgWakeTime,
      averageEfficiency: avgEfficiency,
    );
  }

  static void _addAnnotations(List<ProcessedSleepData> data) {
    if (data.isEmpty) return;

    final nonEmptyData = data.where((d) => !d.isEmpty).toList();
    if (nonEmptyData.isEmpty) return;

    // Find best and worst sleep based on display values
    var bestSleep = nonEmptyData.first;
    var worstSleep = nonEmptyData.first;

    for (var item in nonEmptyData) {
      if (item.displayValue > bestSleep.displayValue) {
        bestSleep = item;
      }
      if (item.displayValue < worstSleep.displayValue) {
        worstSleep = item;
      }
    }

    // Mark best and worst (if different)
    if (bestSleep != worstSleep && nonEmptyData.length > 2) {
      final bestIndex = data.indexOf(bestSleep);
      final worstIndex = data.indexOf(worstSleep);

      if (bestIndex >= 0) {
        data[bestIndex] = data[bestIndex].copyWith(isHighest: true);
      }
      if (worstIndex >= 0) {
        data[worstIndex] = data[worstIndex].copyWith(isLowest: true);
      }
    }
  }

  // Helper methods similar to step processor
  static Map<String, List<SleepData>> _groupRawDataByPeriod(
    List<SleepData> data,
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    final groupedData = <String, List<SleepData>>{};

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

  static List<ProcessedSleepData> _aggregateProcessedData(
    List<ProcessedSleepData> data,
    int targetCount,
  ) {
    final chunkSize = (data.length / targetCount).ceil();
    final result = <ProcessedSleepData>[];

    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      final chunk = data.sublist(i, end);

      if (chunk.every((d) => d.isEmpty)) {
        result.add(ProcessedSleepData.empty(
            chunk.first.startDate, chunk.last.endDate));
        continue;
      }

      final validData = chunk.where((d) => !d.isEmpty).toList();
      if (validData.isEmpty) continue;

      // Aggregate sleep stages across chunks
      final Map<SleepStage, int> combinedStages = {};
      for (var item in validData) {
        for (var entry in item.sleepStages.entries) {
          combinedStages[entry.key] =
              (combinedStages[entry.key] ?? 0) + entry.value;
        }
      }

      final totalSleepInPeriod =
          validData.fold(0, (sum, d) => sum + d.totalSleepInPeriod);

      result.add(ProcessedSleepData(
        startDate: chunk.first.startDate,
        endDate: chunk.last.endDate,
        totalSleepMinutes: totalSleepInPeriod,
        sleepStages: combinedStages,
        dataPointCount: validData.fold(0, (sum, d) => sum + d.dataPointCount),
        originalMeasurements:
            validData.expand((d) => d.originalMeasurements).toList(),
        viewType: validData.first.viewType,
      ));
    }

    return result;
  }

  static List<ProcessedSleepData> _generateEmptyDataPoints(
    DateRangeType dateRangeType,
    DateTime startDate,
    DateTime endDate,
  ) {
    List<ProcessedSleepData> emptyPoints = [];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final periodStart = _getPeriodStart(currentDate, dateRangeType);
      final periodEnd = _getPeriodEnd(currentDate, dateRangeType);
      emptyPoints
          .add(ProcessedSleepData.empty(periodStart, periodEnd, dateRangeType));
      currentDate = _getNextDate(currentDate, dateRangeType);
    }

    return emptyPoints;
  }
}
