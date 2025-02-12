import '../utils/date_formatter.dart';
import 'blood_pressure_category.dart';
import 'blood_pressure_data.dart';
import 'date_range_type.dart';

// Updated ProcessedBloodPressureData model
class ProcessedBloodPressureData {
  final DateTime startDate;
  final DateTime endDate;
  final int minSystolic;
  final int maxSystolic;
  final int minDiastolic;
  final int maxDiastolic;
  final int dataPointCount;
  final double avgSystolic;
  final double avgDiastolic;
  final double systolicStdDev;
  final double diastolicStdDev;
  final bool isRangeData;
  final bool isEmpty;
  final List<BloodPressureData> originalMeasurements;

  ProcessedBloodPressureData({
    required this.startDate,
    required this.endDate,
    required this.minSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.maxDiastolic,
    required this.dataPointCount,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.systolicStdDev,
    required this.diastolicStdDev,
    required this.isRangeData,
    this.isEmpty = false,
    this.originalMeasurements = const [], // Add this parameter
  });
  factory ProcessedBloodPressureData.empty(DateTime date) {
    return ProcessedBloodPressureData(
      startDate: date,
      endDate: date,
      minSystolic: 0,
      maxSystolic: 0,
      minDiastolic: 0,
      maxDiastolic: 0,
      dataPointCount: 0,
      avgSystolic: 0,
      avgDiastolic: 0,
      systolicStdDev: 0,
      diastolicStdDev: 0,
      isRangeData: false,
      isEmpty: true,
      originalMeasurements: const [],
    );
  }
  String get dateLabel {
    if (startDate == endDate) {
      return DateFormatter.format(startDate, DateRangeType.month);
    }
    return '${DateFormatter.format(startDate, DateRangeType.month)}-${DateFormatter.format(endDate, DateRangeType.month)}';
  }

  BloodPressureCategory get category {
    if (maxSystolic >= 180 || maxDiastolic >= 120) {
      return BloodPressureCategory.crisis;
    }
    if (maxSystolic >= 140 || maxDiastolic >= 90) {
      return BloodPressureCategory.high;
    }
    if (maxSystolic >= 130 || maxDiastolic >= 80) {
      return BloodPressureCategory.elevated;
    }
    if (minSystolic < 90 || minDiastolic < 60) {
      return BloodPressureCategory.low;
    }
    return BloodPressureCategory.normal;
  }
}
