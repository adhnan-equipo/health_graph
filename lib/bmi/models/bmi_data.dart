import 'bmi_category.dart';
import 'bmi_range.dart';

class BMIData {
  final DateTime date;
  final double height; // in cm
  final double weight; // in kg
  final double bmi;

  BMIData({
    required this.date,
    required this.height,
    required this.weight,
  }) : bmi = weight / ((height / 100) * (height / 100));

  factory BMIData.withBMI({
    required DateTime date,
    required double bmi,
    double? height,
    double? weight,
  }) {
    return BMIData(
      date: date,
      height: height ?? 170, // Default height if not provided
      weight: weight ??
          (bmi *
              (170 / 100) *
              (170 / 100)), // Calculated from BMI if not provided
    );
  }

  BMICategory get category {
    if (bmi < BMIRange.underweightThreshold) return BMICategory.underweight;
    if (bmi <= BMIRange.normalMax) return BMICategory.normal;
    if (bmi <= BMIRange.overweightMax) return BMICategory.overweight;
    return BMICategory.obese;
  }
}
