// lib/sleep/models/sleep_stage.dart
enum SleepStage {
  deep,
  rem,
  light,
  awake,
  awakeInBed,
  unknown,
}

extension SleepStageExtension on SleepStage {
  String get label {
    switch (this) {
      case SleepStage.deep:
        return 'Deep Sleep';
      case SleepStage.rem:
        return 'REM Sleep';
      case SleepStage.light:
        return 'Light Sleep';
      case SleepStage.awake:
        return 'Awake';
      case SleepStage.awakeInBed:
        return 'Awake in Bed';
      case SleepStage.unknown:
        return 'Unknown';
    }
  }

  String get shortLabel {
    switch (this) {
      case SleepStage.deep:
        return 'Deep';
      case SleepStage.rem:
        return 'REM';
      case SleepStage.light:
        return 'Light';
      case SleepStage.awake:
        return 'Awake';
      case SleepStage.awakeInBed:
        return 'In Bed';
      case SleepStage.unknown:
        return 'Unknown';
    }
  }

  /// Order for stacking in charts (bottom to top)
  int get stackOrder {
    switch (this) {
      case SleepStage.deep:
        return 0; // Bottom - most restorative
      case SleepStage.rem:
        return 1;
      case SleepStage.light:
        return 2;
      case SleepStage.awakeInBed:
        return 3;
      case SleepStage.awake:
        return 4;
      case SleepStage.unknown:
        return 5; // Top
    }
  }
}
