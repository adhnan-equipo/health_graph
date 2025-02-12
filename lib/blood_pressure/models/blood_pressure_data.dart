class BloodPressureData {
  final DateTime date;
  final int? minSystolic;
  final int? maxSystolic;
  final int? minDiastolic;
  final int? maxDiastolic;
  final int? systolic; // For single value readings
  final int? diastolic; // For single value readings

  BloodPressureData({
    required this.date,
    this.minSystolic,
    this.maxSystolic,
    this.minDiastolic,
    this.maxDiastolic,
    this.systolic,
    this.diastolic,
  }) {
    assert(
      (minSystolic != null &&
              maxSystolic != null &&
              minDiastolic != null &&
              maxDiastolic != null) ||
          (systolic != null && diastolic != null),
      'Must provide either range values or single values',
    );
  }

  // Factory constructor for single-value readings
  factory BloodPressureData.single({
    required DateTime date,
    required int? systolic,
    required int? diastolic,
  }) {
    return BloodPressureData(
      date: date,
      systolic: systolic,
      diastolic: diastolic,
    );
  }

  // Factory constructor for range readings
  factory BloodPressureData.range({
    required DateTime date,
    required int? minSystolic,
    required int? maxSystolic,
    required int? minDiastolic,
    required int? maxDiastolic,
  }) {
    return BloodPressureData(
      date: date,
      minSystolic: minSystolic,
      maxSystolic: maxSystolic,
      minDiastolic: minDiastolic,
      maxDiastolic: maxDiastolic,
    );
  }

  // Helper getters
  bool get isRangeReading => minSystolic != null;

  // For systolic values
  int get effectiveMinSystolic => minSystolic ?? systolic ?? 0;
  int get effectiveMaxSystolic => maxSystolic ?? systolic ?? 0;

  // For diastolic values
  int get effectiveMinDiastolic => minDiastolic ?? diastolic ?? 0;
  int get effectiveMaxDiastolic => maxDiastolic ?? diastolic ?? 0;
}
