// lib/sleep/models/processed_sleep_data.dart
import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import 'sleep_data.dart';
import 'sleep_quality.dart';
import 'sleep_range.dart';
import 'sleep_stage.dart';

class ProcessedSleepData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalSleepMinutes;
  final Map<SleepStage, int> sleepStages;
  final int dataPointCount;
  final bool isEmpty;
  final List<SleepData> originalMeasurements;
  final DateRangeType viewType;

  // Timing data
  final DateTime? averageBedTime;
  final DateTime? averageWakeTime;
  final double? averageEfficiency;

  // Annotations
  final bool isHighest;
  final bool isLowest;
  final bool meetsRecommendation;

  ProcessedSleepData({
    required this.startDate,
    required this.endDate,
    required this.totalSleepMinutes,
    this.sleepStages = const {},
    required this.dataPointCount,
    this.isEmpty = false,
    this.originalMeasurements = const [],
    this.viewType = DateRangeType.day,
    this.averageBedTime,
    this.averageWakeTime,
    this.averageEfficiency,
    this.isHighest = false,
    this.isLowest = false,
    bool? meetsRecommendation,
  }) : meetsRecommendation = meetsRecommendation ??
            _checkRecommendation(totalSleepMinutes, viewType);

  factory ProcessedSleepData.empty(DateTime startDate, DateTime endDate,
      [DateRangeType viewType = DateRangeType.day]) {
    return ProcessedSleepData(
      startDate: startDate,
      endDate: endDate,
      totalSleepMinutes: 0,
      dataPointCount: 0,
      isEmpty: true,
      viewType: viewType,
    );
  }

  static bool _checkRecommendation(int minutes, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        return minutes >= SleepRange.recommendedMin;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        // For longer periods, check daily average
        return minutes >= SleepRange.recommendedMin;
    }
  }

  /// Get the display value based on view type
  int get displayValue {
    switch (viewType) {
      case DateRangeType.day:
        return totalSleepMinutes; // Show actual total for daily view
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        return dailyAverage.round(); // Show daily average for longer periods
    }
  }

  /// Always returns total sleep for this period
  int get totalSleepInPeriod => totalSleepMinutes;

  /// Get daily average sleep
  double get dailyAverage {
    final daysDifference = endDate.difference(startDate).inDays + 1;
    return totalSleepInPeriod / daysDifference;
  }

  /// Format sleep duration as hours and minutes
  String get formattedDuration {
    final hours = totalSleepMinutes ~/ 60;
    final minutes = totalSleepMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Format daily average duration
  String get formattedDailyAverage {
    final avgMinutes = dailyAverage.round();
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;
    if (hours == 0) return '${minutes}m avg';
    if (minutes == 0) return '${hours}h avg';
    return '${hours}h ${minutes}m avg';
  }

  // FIXED: Use SleepQualityHelper.fromMinutes instead of SleepQuality.fromMinutes
  SleepQuality get quality => SleepQualityHelper.fromMinutes(displayValue);

  /// Check if detailed sleep stages are available
  bool get hasDetailedStages => sleepStages.isNotEmpty;

  /// Get sleep stage percentages
  Map<SleepStage, double> get stagePercentages {
    if (totalSleepMinutes == 0 || sleepStages.isEmpty) return {};

    return sleepStages.map((stage, minutes) =>
        MapEntry(stage, (minutes / totalSleepMinutes * 100).clamp(0, 100)));
  }

  /// Get ordered sleep stages for stacking
  List<MapEntry<SleepStage, int>> get orderedStages {
    final entries = sleepStages.entries.toList();
    entries.sort((a, b) => a.key.stackOrder.compareTo(b.key.stackOrder));
    return entries;
  }

  /// Helper for display formatting
  String get displayLabel {
    switch (viewType) {
      case DateRangeType.day:
        return 'Total Sleep';
      case DateRangeType.week:
        return 'Avg/Night';
      case DateRangeType.month:
        return 'Avg/Night';
      case DateRangeType.year:
        return 'Avg/Night';
    }
  }

  String get dateLabel {
    if (startDate == endDate) {
      return DateFormatter.format(startDate, DateRangeType.month);
    }
    return '${DateFormatter.format(startDate, DateRangeType.month)}-${DateFormatter.format(endDate, DateRangeType.month)}';
  }

  // Annotation helpers
  bool get hasAnnotation => isHighest || isLowest;

  String get annotationText {
    if (isHighest) return 'Best';
    if (isLowest) return 'Least';
    return '';
  }

  ProcessedSleepData copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? totalSleepMinutes,
    Map<SleepStage, int>? sleepStages,
    int? dataPointCount,
    bool? isEmpty,
    List<SleepData>? originalMeasurements,
    DateRangeType? viewType,
    DateTime? averageBedTime,
    DateTime? averageWakeTime,
    double? averageEfficiency,
    bool? isHighest,
    bool? isLowest,
    bool? meetsRecommendation,
  }) {
    return ProcessedSleepData(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalSleepMinutes: totalSleepMinutes ?? this.totalSleepMinutes,
      sleepStages: sleepStages ?? this.sleepStages,
      dataPointCount: dataPointCount ?? this.dataPointCount,
      isEmpty: isEmpty ?? this.isEmpty,
      originalMeasurements: originalMeasurements ?? this.originalMeasurements,
      viewType: viewType ?? this.viewType,
      averageBedTime: averageBedTime ?? this.averageBedTime,
      averageWakeTime: averageWakeTime ?? this.averageWakeTime,
      averageEfficiency: averageEfficiency ?? this.averageEfficiency,
      isHighest: isHighest ?? this.isHighest,
      isLowest: isLowest ?? this.isLowest,
      meetsRecommendation: meetsRecommendation ?? this.meetsRecommendation,
    );
  }
}
