// lib/heart_rate/models/heart_rate_range.dart
import 'package:health_graph/heart_rate/styles/heart_rate_chart_style.dart';

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

  // Get zone description
  static String getZoneDescription(
    double value,
    HeartRateChartStyle style,
  ) {
    if (value < lowMax) {
      return style.lowZoneLabel;
    } else if (value < normalMax) {
      return style.normalZoneLabel;
    } else if (value < elevatedMax) {
      return style.elevatedZoneLabel;
    } else {
      return style.highZoneLabel;
    }
  }
}
