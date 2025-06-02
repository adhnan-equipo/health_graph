// lib/sleep/models/sleep_range.dart
class SleepRange {
  // Sleep duration recommendations (in minutes)
  static const int minimumSleep = 240; // 4 hours
  static const int insufficientMax = 360; // 6 hours
  static const int adequateMin = 360; // 6 hours
  static const int adequateMax = 420; // 7 hours
  static const int recommendedMin = 420; // 7 hours
  static const int recommendedMax = 540; // 9 hours
  static const int excessiveMin = 540; // 9 hours

  // Sleep efficiency thresholds
  static const double poorEfficiency = 70.0;
  static const double goodEfficiency = 85.0;
  static const double excellentEfficiency = 95.0;

  // Ideal sleep stage percentages (of total sleep)
  static const double idealDeepPercent = 20.0; // 15-25% is normal
  static const double idealRemPercent = 25.0; // 20-30% is normal
  static const double idealLightPercent = 55.0; // 45-65% is normal

  static String getDurationDescription(int minutes) {
    final hours = minutes / 60;
    if (minutes < minimumSleep) return 'Severely insufficient sleep';
    if (minutes < adequateMin) return 'Below recommended duration';
    if (minutes < recommendedMin) return 'Adequate sleep duration';
    if (minutes <= recommendedMax) return 'Recommended sleep duration';
    return 'Extended sleep duration';
  }

  static String getEfficiencyDescription(double efficiency) {
    if (efficiency < poorEfficiency) return 'Poor sleep efficiency';
    if (efficiency < goodEfficiency) return 'Fair sleep efficiency';
    if (efficiency < excellentEfficiency) return 'Good sleep efficiency';
    return 'Excellent sleep efficiency';
  }
}
