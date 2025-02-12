// lib/models/processed_heart_rate_data.dart
import 'heart_rate_data.dart';
import 'heart_rate_zone.dart';

class ProcessedHeartRateData {
  final DateTime startDate;
  final DateTime endDate;
  final int minValue;
  final int maxValue;
  final double avgValue;
  final int dataPointCount;
  final double stdDev;
  final bool isRangeData;
  final bool isEmpty;
  final List<HeartRateData> originalMeasurements;
  final double? hrv; // Heart Rate Variability
  final int? restingRate;

  ProcessedHeartRateData({
    required this.startDate,
    required this.endDate,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.dataPointCount,
    required this.stdDev,
    required this.isRangeData,
    this.isEmpty = false,
    this.originalMeasurements = const [],
    this.hrv,
    this.restingRate,
  });

  factory ProcessedHeartRateData.empty(DateTime date) {
    return ProcessedHeartRateData(
      startDate: date,
      endDate: date,
      minValue: 0,
      maxValue: 0,
      avgValue: 0,
      dataPointCount: 0,
      stdDev: 0,
      isRangeData: false,
      isEmpty: true,
    );
  }

  HeartRateZone get zone {
    if (avgValue < 60) return HeartRateZone.low;
    if (avgValue < 100) return HeartRateZone.normal;
    if (avgValue < 140) return HeartRateZone.elevated;
    return HeartRateZone.high;
  }

  String get zoneDescription {
    switch (zone) {
      case HeartRateZone.low:
        return 'Low Heart Rate (Bradycardia)';
      case HeartRateZone.normal:
        return 'Normal Heart Rate';
      case HeartRateZone.elevated:
        return 'Elevated Heart Rate (Mild Tachycardia)';
      case HeartRateZone.high:
        return 'High Heart Rate (Tachycardia)';
    }
  }
}
