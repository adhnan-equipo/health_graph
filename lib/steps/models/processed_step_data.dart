// lib/steps/models/processed_step_data.dart
import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import 'step_category.dart';
import 'step_data.dart';
import 'step_range.dart';

class ProcessedStepData {
  final DateTime startDate;
  final DateTime endDate;
  final int minSteps;
  final int maxSteps;
  final double avgSteps;
  final double stdDev;
  final int dataPointCount;
  final bool isEmpty;
  final List<StepData> originalMeasurements;
  final int totalSteps;
  final DateRangeType viewType;

  // Annotation fields for highest/lowest markers
  final bool isHighest;
  final bool isLowest;
  final bool isGoalAchieved;

  ProcessedStepData({
    required this.startDate,
    required this.endDate,
    required this.minSteps,
    required this.maxSteps,
    required this.avgSteps,
    required this.stdDev,
    required this.dataPointCount,
    this.isEmpty = false,
    this.originalMeasurements = const [],
    int? totalSteps,
    this.viewType = DateRangeType.day,
    this.isHighest = false,
    this.isLowest = false,
    bool? isGoalAchieved,
  })  : totalSteps = totalSteps ?? avgSteps.round(),
        isGoalAchieved = isGoalAchieved ??
            _checkGoalAchievement(totalSteps ?? avgSteps.round(), viewType);

  factory ProcessedStepData.empty(DateTime startDate, DateTime endDate,
      [DateRangeType viewType = DateRangeType.day]) {
    return ProcessedStepData(
      startDate: startDate,
      endDate: endDate,
      minSteps: 0,
      maxSteps: 0,
      avgSteps: 0,
      stdDev: 0,
      dataPointCount: 0,
      isEmpty: true,
      originalMeasurements: const [],
      totalSteps: 0,
      viewType: viewType,
    );
  }

  static bool _checkGoalAchievement(int steps, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        return steps >= StepRange.recommendedDaily;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        // For weekly/monthly/yearly, check daily average
        return steps >= StepRange.recommendedDaily;
    }
  }

  ProcessedStepData copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? minSteps,
    int? maxSteps,
    double? avgSteps,
    double? stdDev,
    int? dataPointCount,
    bool? isEmpty,
    List<StepData>? originalMeasurements,
    int? totalSteps,
    DateRangeType? viewType,
    bool? isHighest,
    bool? isLowest,
    bool? isGoalAchieved,
  }) {
    return ProcessedStepData(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minSteps: minSteps ?? this.minSteps,
      maxSteps: maxSteps ?? this.maxSteps,
      avgSteps: avgSteps ?? this.avgSteps,
      stdDev: stdDev ?? this.stdDev,
      dataPointCount: dataPointCount ?? this.dataPointCount,
      isEmpty: isEmpty ?? this.isEmpty,
      originalMeasurements: originalMeasurements ?? this.originalMeasurements,
      totalSteps: totalSteps ?? this.totalSteps,
      viewType: viewType ?? this.viewType,
      isHighest: isHighest ?? this.isHighest,
      isLowest: isLowest ?? this.isLowest,
      isGoalAchieved: isGoalAchieved ?? this.isGoalAchieved,
    );
  }

  String get dateLabel {
    if (startDate == endDate) {
      return DateFormatter.format(startDate, DateRangeType.month);
    }
    return '${DateFormatter.format(startDate, DateRangeType.month)}-${DateFormatter.format(endDate, DateRangeType.month)}';
  }

  StepCategory get category {
    final stepValue = displayValue;
    if (stepValue <= StepRange.sedentaryMax) return StepCategory.sedentary;
    if (stepValue <= StepRange.lightActiveMax) return StepCategory.lightActive;
    if (stepValue <= StepRange.fairlyActiveMax)
      return StepCategory.fairlyActive;
    if (stepValue <= StepRange.veryActiveMax) return StepCategory.veryActive;
    return StepCategory.highlyActive;
  }

  bool get meetsRecommendation => displayValue >= StepRange.recommendedDaily;

  bool get meetsMinimumHealth => displayValue >= StepRange.minimumHealthBenefit;
  double get completionPercentage =>
      (displayValue / StepRange.recommendedDaily * 100).clamp(0, 100);

  /// This is the key method - returns the value to display on the chart
  /// For daily view: shows total steps for the day/hour
  /// For weekly/monthly/yearly: shows daily average
  int get displayValue {
    switch (viewType) {
      case DateRangeType.day:
        return totalSteps; // Show actual total for daily view
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        return dailyAverage.round(); // Show daily average for longer periods
    }
  }

  /// Always returns total steps for this period
  int get totalStepsInPeriod => totalSteps;

  /// Get the latest individual step count from measurements
  int get latestStepCount {
    if (originalMeasurements.isEmpty) return 0;
    return originalMeasurements.last.step;
  }

  /// Get daily average steps
  double get dailyAverage {
    final daysDifference = endDate.difference(startDate).inDays + 1;
    return totalStepsInPeriod / daysDifference;
  }

  /// Helper for display formatting
  String get displayLabel {
    switch (viewType) {
      case DateRangeType.day:
        return 'Total Steps';
      case DateRangeType.week:
        return 'Avg/Day';
      case DateRangeType.month:
        return 'Avg/Day';
      case DateRangeType.year:
        return 'Avg/Day';
    }
  }

  // New helper methods for annotations
  bool get hasAnnotation => isHighest || isLowest;

  String get annotationText {
    if (isHighest) return 'Highest';
    if (isLowest) return 'Lowest';
    return '';
  }
}
