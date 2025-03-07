// lib/heart_rate/models/heart_rate_chart_config.dart
import '../../models/date_range_type.dart';

class HeartRateChartConfig {
  final DateRangeType viewType;
  final DateTime startDate;
  final DateTime endDate;
  final bool showGrid;
  final bool showLabels;
  final bool enableAnimation;
  final bool showTrendLine;
  final bool showRanges;
  final bool showAverage;
  final double zoomLevel;
  final bool showRestingRate;
  final bool showHRV;
  final bool showTooltips;
  final bool adaptiveScaling;
  final bool showZones;

  const HeartRateChartConfig({
    required this.viewType,
    required this.startDate,
    required this.endDate,
    this.showGrid = true,
    this.showLabels = true,
    this.enableAnimation = true,
    this.showTrendLine = true,
    this.showRanges = true,
    this.showAverage = true,
    this.zoomLevel = 1.0,
    this.showRestingRate = true,
    this.showHRV = true,
    this.showTooltips = true,
    this.adaptiveScaling = true,
    this.showZones = true,
  });

  /// Create a copy with modified properties
  HeartRateChartConfig copyWith({
    DateRangeType? viewType,
    DateTime? startDate,
    DateTime? endDate,
    bool? showGrid,
    bool? showLabels,
    bool? enableAnimation,
    bool? showTrendLine,
    bool? showRanges,
    bool? showAverage,
    double? zoomLevel,
    bool? showRestingRate,
    bool? showHRV,
    bool? showTooltips,
    bool? adaptiveScaling,
    bool? showZones,
  }) {
    return HeartRateChartConfig(
      viewType: viewType ?? this.viewType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showGrid: showGrid ?? this.showGrid,
      showLabels: showLabels ?? this.showLabels,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      showTrendLine: showTrendLine ?? this.showTrendLine,
      showRanges: showRanges ?? this.showRanges,
      showAverage: showAverage ?? this.showAverage,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      showRestingRate: showRestingRate ?? this.showRestingRate,
      showHRV: showHRV ?? this.showHRV,
      showTooltips: showTooltips ?? this.showTooltips,
      adaptiveScaling: adaptiveScaling ?? this.adaptiveScaling,
      showZones: showZones ?? this.showZones,
    );
  }

  /// Calculate end date based on start date and view type
  static DateTime calculateEndDate(DateTime startDate, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        return DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          23,
          59,
          59,
        );
      case DateRangeType.week:
        // End of week (start date + 6 days)
        return startDate.add(const Duration(days: 6));
      case DateRangeType.month:
        // Last day of month
        return DateTime(
          startDate.year,
          startDate.month + 1,
          0,
          23,
          59,
          59,
        );
      case DateRangeType.year:
        // End of year
        return DateTime(
          startDate.year,
          12,
          31,
          23,
          59,
          59,
        );
    }
  }

  /// Get a standard config for the given view type
  static HeartRateChartConfig getDefaultConfig(DateRangeType viewType) {
    final now = DateTime.now();
    late final DateTime startDate;

    switch (viewType) {
      case DateRangeType.day:
        // Start of today
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DateRangeType.week:
        // Start of current week (adjusted to Monday)
        final weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - weekday + 1);
        break;
      case DateRangeType.month:
        // Start of current month
        startDate = DateTime(now.year, now.month, 1);
        break;
      case DateRangeType.year:
        // Start of current year
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    final endDate = calculateEndDate(startDate, viewType);

    return HeartRateChartConfig(
      viewType: viewType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get a config for a specific period
  static HeartRateChartConfig forPeriod({
    required DateRangeType viewType,
    required DateTime date,
  }) {
    late final DateTime startDate;

    switch (viewType) {
      case DateRangeType.day:
        // Start of specified day
        startDate = DateTime(date.year, date.month, date.day);
        break;
      case DateRangeType.week:
        // Start of week that contains the specified date
        final weekday = date.weekday;
        startDate = DateTime(date.year, date.month, date.day - weekday + 1);
        break;
      case DateRangeType.month:
        // Start of month for specified date
        startDate = DateTime(date.year, date.month, 1);
        break;
      case DateRangeType.year:
        // Start of year for specified date
        startDate = DateTime(date.year, 1, 1);
        break;
    }

    final endDate = calculateEndDate(startDate, viewType);

    return HeartRateChartConfig(
      viewType: viewType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateChartConfig &&
          runtimeType == other.runtimeType &&
          viewType == other.viewType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          showGrid == other.showGrid &&
          showLabels == other.showLabels &&
          enableAnimation == other.enableAnimation &&
          showTrendLine == other.showTrendLine &&
          showRanges == other.showRanges &&
          showAverage == other.showAverage &&
          zoomLevel == other.zoomLevel &&
          showRestingRate == other.showRestingRate &&
          showHRV == other.showHRV &&
          showTooltips == other.showTooltips &&
          adaptiveScaling == other.adaptiveScaling &&
          showZones == other.showZones;

  @override
  int get hashCode =>
      viewType.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      showGrid.hashCode ^
      showLabels.hashCode ^
      enableAnimation.hashCode ^
      showTrendLine.hashCode ^
      showRanges.hashCode ^
      showAverage.hashCode ^
      zoomLevel.hashCode ^
      showRestingRate.hashCode ^
      showHRV.hashCode ^
      showTooltips.hashCode ^
      adaptiveScaling.hashCode ^
      showZones.hashCode;
}
