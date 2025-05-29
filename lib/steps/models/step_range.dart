// lib/steps/models/step_range.dart
class StepRange {
  // Updated step categories based on your requirements
  static const int sedentaryMax = 4999;
  static const int lightActiveMin = 5000;
  static const int lightActiveMax = 7499;
  static const int fairlyActiveMin = 7500;
  static const int fairlyActiveMax = 9999;
  static const int veryActiveMin = 10000;
  static const int veryActiveMax = 12499;
  static const int highlyActiveMin = 12500;
  static const int highlyActiveMax = 999999; // Very high upper limit

  // WHO/CDC recommended daily target
  static const int recommendedDaily = 10000;
  static const int minimumHealthBenefit = 5000;
  static const int optimalHealthBenefit = 8000;

  // Helper method to get category description
  static String getCategoryDescription(int steps) {
    if (steps <= sedentaryMax) return 'Like a desk job with no exercise';
    if (steps <= lightActiveMax) return 'Some walking, light activities';
    if (steps <= fairlyActiveMax) return 'Regular walking, some sports';
    if (steps <= veryActiveMax) return 'Regular exercise, active lifestyle';
    return 'High activity, athlete-like';
  }
}
