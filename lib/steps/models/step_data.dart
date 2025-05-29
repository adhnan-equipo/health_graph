// lib/steps/models/step_data.dart
import 'step_category.dart';
import 'step_range.dart';

class StepData {
  final DateTime createDate;
  final int step;

  StepData({
    required this.createDate,
    required this.step,
  });

  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      createDate: DateTime.parse(json['createDate']),
      step: json['step'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'createDate': createDate.toIso8601String(),
    };
  }

  StepCategory get category {
    if (step <= StepRange.sedentaryMax) return StepCategory.sedentary;
    if (step <= StepRange.lightActiveMax) return StepCategory.lightActive;
    if (step <= StepRange.fairlyActiveMax) return StepCategory.fairlyActive;
    if (step <= StepRange.veryActiveMax) return StepCategory.veryActive;
    return StepCategory.highlyActive;
  }

  bool get meetsRecommendation => step >= StepRange.recommendedDaily;

  bool get meetsMinimumHealth => step >= StepRange.minimumHealthBenefit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepData &&
          runtimeType == other.runtimeType &&
          createDate == other.createDate &&
          step == other.step;

  @override
  int get hashCode => createDate.hashCode ^ step.hashCode;

  @override
  String toString() => 'StepData(createDate: $createDate, step: $step)';
}
