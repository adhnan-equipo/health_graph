// lib/heart_rate/models/heart_rate_range.dart
class HeartRateRange {
  // Heart rate zones (bpm)
  static const lowMin = 0;
  static const lowMax = 60;

  static const normalMin = 60;
  static const normalMax = 100;

  static const elevatedMin = 100;
  static const elevatedMax = 140;

  static const highMin = 140;
  static const highMax = 220;

  // Age-based maximum heart rate calculation
  static int calculateMaxHeartRate(int age) {
    return 220 - age;
  }

  // Get zone name from value
  static String getZoneName(double value) {
    if (value < lowMax) return 'Low';
    if (value < normalMax) return 'Normal';
    if (value < elevatedMax) return 'Elevated';
    return 'High';
  }

  // Get zone description
  static String getZoneDescription(double value) {
    if (value < lowMax) {
      return 'Low Heart Rate (Bradycardia)';
    } else if (value < normalMax) {
      return 'Normal Heart Rate';
    } else if (value < elevatedMax) {
      return 'Elevated Heart Rate (Mild Tachycardia)';
    } else {
      return 'High Heart Rate (Tachycardia)';
    }
  }
}
