// lib/sleep/models/sleep_data.dart
import 'sleep_quality.dart';
import 'sleep_stage.dart';

class SleepData {
  final DateTime createDate;
  final int? sleep; // Total minutes asleep (fallback)
  final DateTime? bedTime;
  final DateTime? wakeTime;
  final int? totalSleep;
  final int? sleepRem;
  final int? sleepLight;
  final int? sleepDeep;
  final int? sleepAwake;
  final int? sleepAwakeInBed;
  final int? sleepAsleep;
  final int? sleepUnknown;
  final int? sleepOutOfBed;

  SleepData({
    required this.createDate,
    this.sleep,
    this.bedTime,
    this.wakeTime,
    this.totalSleep,
    this.sleepRem,
    this.sleepLight,
    this.sleepDeep,
    this.sleepAwake,
    this.sleepAwakeInBed,
    this.sleepAsleep,
    this.sleepUnknown,
    this.sleepOutOfBed,
  });

  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      createDate: DateTime.parse(json['createDate']),
      sleep: json['sleep'],
      bedTime: json['bedTime'] != null ? DateTime.parse(json['bedTime']) : null,
      wakeTime:
          json['wakeTime'] != null ? DateTime.parse(json['wakeTime']) : null,
      totalSleep: json['totalSleep'] != null
          ? int.tryParse(json['totalSleep'].toString())
          : null,
      sleepRem: json['sleepRem'] != null
          ? int.tryParse(json['sleepRem'].toString())
          : null,
      sleepLight: json['sleepLight'] != null
          ? int.tryParse(json['sleepLight'].toString())
          : null,
      sleepDeep: json['sleepDeep'] != null
          ? int.tryParse(json['sleepDeep'].toString())
          : null,
      sleepAwake: json['sleepAwake'] != null
          ? int.tryParse(json['sleepAwake'].toString())
          : null,
      sleepAwakeInBed: json['sleepAwakeInBed'] != null
          ? int.tryParse(json['sleepAwakeInBed'].toString())
          : null,
      sleepAsleep: json['sleepAsleep'] != null
          ? int.tryParse(json['sleepAsleep'].toString())
          : null,
      sleepUnknown: json['sleepUnknown'] != null
          ? int.tryParse(json['sleepUnknown'].toString())
          : null,
      sleepOutOfBed: json['sleepOutOfBed'] != null
          ? int.tryParse(json['sleepOutOfBed'].toString())
          : null,
    );
  }

  /// Get the primary sleep value - total sleep duration in minutes
  int get primarySleepValue => totalSleep ?? sleep ?? 0;

  /// Check if detailed sleep stage data is available
  bool get hasDetailedStages =>
      sleepRem != null || sleepLight != null || sleepDeep != null;

  /// Check if timing data is available
  bool get hasTimingData => bedTime != null && wakeTime != null;

  /// Get all available sleep stages as a map
  Map<SleepStage, int> get availableStages {
    final stages = <SleepStage, int>{};

    if (sleepDeep != null && sleepDeep! > 0) {
      stages[SleepStage.deep] = sleepDeep!;
    }
    if (sleepRem != null && sleepRem! > 0) {
      stages[SleepStage.rem] = sleepRem!;
    }
    if (sleepLight != null && sleepLight! > 0) {
      stages[SleepStage.light] = sleepLight!;
    }
    if (sleepAwake != null && sleepAwake! > 0) {
      stages[SleepStage.awake] = sleepAwake!;
    }
    if (sleepAwakeInBed != null && sleepAwakeInBed! > 0) {
      stages[SleepStage.awakeInBed] = sleepAwakeInBed!;
    }
    if (sleepUnknown != null && sleepUnknown! > 0) {
      stages[SleepStage.unknown] = sleepUnknown!;
    }

    return stages;
  }

  /// Calculate sleep efficiency (time asleep / time in bed)
  double? get sleepEfficiency {
    if (!hasTimingData || primarySleepValue == 0) return null;

    final timeInBed = wakeTime!.difference(bedTime!).inMinutes;
    if (timeInBed <= 0) return null;

    return (primarySleepValue / timeInBed * 100).clamp(0, 100);
  }

  // FIXED: Use SleepQualityHelper.fromMinutes instead of SleepQuality.fromMinutes
  SleepQuality get quality => SleepQualityHelper.fromMinutes(primarySleepValue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepData &&
          runtimeType == other.runtimeType &&
          createDate == other.createDate &&
          sleep == other.sleep;

  @override
  int get hashCode => createDate.hashCode ^ sleep.hashCode;

  @override
  String toString() => 'SleepData(createDate: $createDate, sleep: $sleep)';
}
