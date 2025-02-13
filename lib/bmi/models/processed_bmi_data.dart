import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import 'bmi_category.dart';
import 'bmi_data.dart';
import 'bmi_range.dart';

class ProcessedBMIData {
  final DateTime startDate;
  final DateTime endDate;
  final double minBMI;
  final double maxBMI;
  final double avgBMI;
  final double stdDev;
  final int dataPointCount;
  final bool isEmpty;
  final List<BMIData> originalMeasurements;

  ProcessedBMIData({
    required this.startDate,
    required this.endDate,
    required this.minBMI,
    required this.maxBMI,
    required this.avgBMI,
    required this.stdDev,
    required this.dataPointCount,
    this.isEmpty = false,
    this.originalMeasurements = const [],
  });

  factory ProcessedBMIData.empty(DateTime date) {
    return ProcessedBMIData(
      startDate: date,
      endDate: date,
      minBMI: 0,
      maxBMI: 0,
      avgBMI: 0,
      stdDev: 0,
      dataPointCount: 0,
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

  BMICategory get category {
    if (maxBMI >= BMIRange.obeseThreshold) return BMICategory.obese;
    if (maxBMI >= BMIRange.overweightMin) return BMICategory.overweight;
    if (maxBMI >= BMIRange.normalMin) return BMICategory.normal;
    return BMICategory.underweight;
  }
}
