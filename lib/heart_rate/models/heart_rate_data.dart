// lib/models/heart_rate_data.dart

class HeartRateData {
  final DateTime date;
  final int value;
  final int? minValue;
  final int? maxValue;
  final int? restingRate;

  HeartRateData({
    required this.date,
    required this.value,
    this.minValue,
    this.maxValue,
    this.restingRate,
  });

  factory HeartRateData.single({
    required DateTime date,
    required int value,
    int? restingRate,
  }) {
    return HeartRateData(
      date: date,
      value: value,
      restingRate: restingRate,
    );
  }

  factory HeartRateData.range({
    required DateTime date,
    required int value,
    required int minValue,
    required int maxValue,
    int? restingRate,
  }) {
    return HeartRateData(
      date: date,
      value: value,
      minValue: minValue,
      maxValue: maxValue,
      restingRate: restingRate,
    );
  }

  bool get isRangeReading => minValue != null && maxValue != null;
}
