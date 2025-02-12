import 'o2_saturation_category.dart';
import 'o2_saturation_data.dart';
import 'o2_saturation_range.dart';

class ProcessedO2SaturationData {
  final DateTime startDate;
  final DateTime endDate;
  final int minValue;
  final int maxValue;
  final double avgValue;
  final double stdDev;
  final int dataPointCount;
  final bool isEmpty;
  final List<O2SaturationData> originalMeasurements;

  // Pulse rate data
  final double? avgPulseRate;
  final int? minPulseRate;
  final int? maxPulseRate;

  ProcessedO2SaturationData({
    required this.startDate,
    required this.endDate,
    required this.minValue,
    required this.maxValue,
    required this.avgValue,
    required this.stdDev,
    required this.dataPointCount,
    this.isEmpty = false,
    this.originalMeasurements = const [],
    this.avgPulseRate,
    this.minPulseRate,
    this.maxPulseRate,
  });

  factory ProcessedO2SaturationData.empty(DateTime date) {
    return ProcessedO2SaturationData(
      startDate: date,
      endDate: date,
      minValue: 0,
      maxValue: 0,
      avgValue: 0,
      stdDev: 0,
      dataPointCount: 0,
      isEmpty: true,
    );
  }

  O2SaturationCategory get category {
    if (minValue < O2SaturationRange.severeMin) {
      return O2SaturationCategory.critical;
    }
    if (minValue < O2SaturationRange.moderateMin) {
      return O2SaturationCategory.severe;
    }
    if (minValue < O2SaturationRange.mildMin) {
      return O2SaturationCategory.moderate;
    }
    if (minValue < O2SaturationRange.normalMin) {
      return O2SaturationCategory.mild;
    }
    return O2SaturationCategory.normal;
  }
}
