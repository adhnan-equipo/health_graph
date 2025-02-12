import 'package:flutter/material.dart';

class HeartRateUtils {
  // Define heart rate zones with their thresholds, colors, and descriptions
  static const List<Map<String, dynamic>> _heartRateZones = [
    {'min': 90, 'color': Color(0xFFE53E3E), 'text': 'High Heart Rate'}, // Red
    {
      'min': 80,
      'color': Color(0xFFED8936),
      'text': 'Elevated Heart Rate'
    }, // Orange
    {
      'min': 60,
      'color': Color(0xFF48BB78),
      'text': 'Normal Heart Rate'
    }, // Green
    {'min': 0, 'color': Color(0xFF3182CE), 'text': 'Low Heart Rate'}, // Blue
  ];

  // Get the zone color based on the heart rate value
  static Color getZoneColor(double value) {
    return _heartRateZones.firstWhere(
      (zone) => value >= zone['min'],
      orElse: () => {'color': Color(0xFF3182CE)}, // Default to Low if no match
    )['color'];
  }

  // Get the zone text based on the heart rate value
  static String getZoneText(double value) {
    return _heartRateZones.firstWhere(
      (zone) => value >= zone['min'],
      orElse: () => {'text': 'Unknown Zone'}, // Default to Unknown if no match
    )['text'];
  }
}
