import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';

/// Base interface for processed chart data
/// Provides common structure for all health metric processed data types
abstract class BaseProcessedData {
  DateTime get startDate;

  DateTime get endDate;

  int get dataPointCount;

  bool get isEmpty;

  /// Format date label based on date range
  String get dateLabel {
    if (startDate == endDate) {
      return DateFormatter.format(startDate, DateRangeType.month);
    }
    return '${DateFormatter.format(startDate, DateRangeType.month)}-${DateFormatter.format(endDate, DateRangeType.month)}';
  }

  /// Common equality comparison based on dates and data count
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseProcessedData &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.dataPointCount == dataPointCount &&
        other.isEmpty == isEmpty;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, dataPointCount, isEmpty);
}

/// Base class with common statistical properties
abstract class BaseStatisticalData extends BaseProcessedData {
  double get minValue;

  double get maxValue;

  double get avgValue;

  double get stdDev;

  /// Common statistical calculations
  String get formattedRange =>
      '${minValue.toStringAsFixed(1)} - ${maxValue.toStringAsFixed(1)}';

  String get formattedAverage => avgValue.toStringAsFixed(1);

  String get formattedStdDev => stdDev.toStringAsFixed(1);

  @override
  bool operator ==(Object other) {
    if (!(super == other)) return false;
    return other is BaseStatisticalData &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.avgValue == avgValue &&
        other.stdDev == stdDev;
  }

  @override
  int get hashCode =>
      Object.hash(super.hashCode, minValue, maxValue, avgValue, stdDev);
}
