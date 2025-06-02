// lib/sleep/models/sleep_quality.dart
enum SleepQuality {
  poor, // < 4 hours
  insufficient, // 4-6 hours
  adequate, // 6-7 hours
  good, // 7-8 hours
  excellent, // 8-9 hours
  excessive, // > 9 hours
}

extension SleepQualityExtension on SleepQuality {
  String get label {
    switch (this) {
      case SleepQuality.poor:
        return 'Poor Sleep';
      case SleepQuality.insufficient:
        return 'Insufficient';
      case SleepQuality.adequate:
        return 'Adequate';
      case SleepQuality.good:
        return 'Good Sleep';
      case SleepQuality.excellent:
        return 'Excellent';
      case SleepQuality.excessive:
        return 'Excessive';
    }
  }

  String get description {
    switch (this) {
      case SleepQuality.poor:
        return 'Well below recommended hours';
      case SleepQuality.insufficient:
        return 'Below recommended amount';
      case SleepQuality.adequate:
        return 'Approaching recommended range';
      case SleepQuality.good:
        return 'Within recommended range';
      case SleepQuality.excellent:
        return 'Optimal sleep duration';
      case SleepQuality.excessive:
        return 'Above typical recommendation';
    }
  }
}

// Helper class to create SleepQuality from minutes
class SleepQualityHelper {
  static SleepQuality fromMinutes(int minutes) {
    final hours = minutes / 60;
    if (hours < 4) return SleepQuality.poor;
    if (hours < 6) return SleepQuality.insufficient;
    if (hours < 7) return SleepQuality.adequate;
    if (hours < 8) return SleepQuality.good;
    if (hours < 9) return SleepQuality.excellent;
    return SleepQuality.excessive;
  }
}
