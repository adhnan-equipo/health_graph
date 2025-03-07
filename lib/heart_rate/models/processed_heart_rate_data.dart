// lib/heart_rate/models/processed_heart_rate_data.dart
import 'dart:math';

import '../models/heart_rate_data.dart';

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

  const ProcessedHeartRateData({
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

  /// Get range width (max - min), ensuring it's never negative
  int get rangeWidth => max(0, maxValue - minValue);

  /// Check if this point has a significant range
  bool get hasSignificantRange => rangeWidth > 5;

  /// Check if this point has HRV data
  bool get hasHrv => hrv != null && hrv! > 0;

  /// Check if this point has resting rate data
  bool get hasRestingRate => restingRate != null && restingRate! > 0;

  /// Check if this has any data (not empty)
  bool get hasData => !isEmpty && dataPointCount > 0;

  /// Get the formatted date string
  String getFormattedDate(String format) {
    // Format the date using the provided format
    final year = startDate.year.toString();
    final month = startDate.month.toString().padLeft(2, '0');
    final day = startDate.day.toString().padLeft(2, '0');
    final hour = startDate.hour.toString().padLeft(2, '0');
    final minute = startDate.minute.toString().padLeft(2, '0');

    return format
        .replaceAll('yyyy', year)
        .replaceAll('MM', month)
        .replaceAll('dd', day)
        .replaceAll('HH', hour)
        .replaceAll('mm', minute);
  }

  /// Check if this data point is equal to another
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessedHeartRateData &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          minValue == other.minValue &&
          maxValue == other.maxValue;

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      minValue.hashCode ^
      maxValue.hashCode;
}
