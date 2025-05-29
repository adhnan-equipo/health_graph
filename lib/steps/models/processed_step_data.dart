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
  final double avgSteps; // This now represents TOTAL steps for the period
  final double stdDev;
  final int dataPointCount;
  final bool isEmpty;
  final List<StepData> originalMeasurements;
  final int? totalSteps; // Explicit total steps field

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
    this.totalSteps,
  });

  factory ProcessedStepData.empty(DateTime date) {
    return ProcessedStepData(
      startDate: date,
      endDate: date,
      minSteps: 0,
      maxSteps: 0,
      avgSteps: 0,
      stdDev: 0,
      dataPointCount: 0,
      isEmpty: true,
      originalMeasurements: const [],
      totalSteps: 0,
    );
  }

  String get dateLabel {
    if (startDate == endDate) {
      return DateFormatter.format(startDate, DateRangeType.month);
    }
    return '${DateFormatter.format(startDate, DateRangeType.month)}-${DateFormatter.format(endDate, DateRangeType.month)}';
  }

  StepCategory get category {
    final totalStepsValue = totalSteps ?? avgSteps.round();
    if (totalStepsValue <= StepRange.sedentaryMax)
      return StepCategory.sedentary;
    if (totalStepsValue <= StepRange.lightActiveMax)
      return StepCategory.lightActive;
    if (totalStepsValue <= StepRange.fairlyActiveMax)
      return StepCategory.fairlyActive;
    if (totalStepsValue <= StepRange.veryActiveMax)
      return StepCategory.veryActive;
    return StepCategory.highlyActive;
  }

  bool get meetsRecommendation =>
      totalStepsInPeriod >= StepRange.recommendedDaily;

  bool get meetsMinimumHealth =>
      totalStepsInPeriod >= StepRange.minimumHealthBenefit;

  double get completionPercentage =>
      (totalStepsInPeriod / StepRange.recommendedDaily * 100).clamp(0, 100);

  /// Get the total step count for this period
  int get totalStepsInPeriod {
    return totalSteps ?? avgSteps.round();
  }

  /// Get the latest individual step count from measurements
  int get latestStepCount {
    if (originalMeasurements.isEmpty) return 0;
    return originalMeasurements.last.step;
  }

  /// Get daily average if this represents multiple days
  double get dailyAverage {
    final daysDifference = endDate.difference(startDate).inDays + 1;
    return totalStepsInPeriod / daysDifference;
  }
}
