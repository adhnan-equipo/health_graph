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

  /// Get a standard config for the given view type using SAME logic as other charts
  static HeartRateChartConfig getDefaultConfig(DateRangeType viewType) {
    final now = DateTime.now();
    late final DateTime startDate;
    late final DateTime endDate;

    // SAME logic as BaseChartController used by other charts
    switch (viewType) {
      case DateRangeType.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case DateRangeType.week:
        // Use the SAME logic as other charts - no custom week calculation
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case DateRangeType.month:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case DateRangeType.year:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 0);
        break;
    }

    return HeartRateChartConfig(
      viewType: viewType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get a config for a specific period using SAME logic as other charts
  static HeartRateChartConfig forPeriod({
    required DateRangeType viewType,
    required DateTime date,
  }) {
    late final DateTime startDate;
    late final DateTime endDate;

    // SAME logic as BaseChartController used by other charts
    switch (viewType) {
      case DateRangeType.day:
        startDate = DateTime(date.year, date.month, date.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case DateRangeType.week:
        // Use the SAME logic as other charts - no custom week calculation
        startDate = DateTime(date.year, date.month, date.day);
        endDate = startDate.add(const Duration(days: 6));
        break;
      case DateRangeType.month:
        startDate = DateTime(date.year, date.month, 1);
        endDate = DateTime(date.year, date.month + 1, 0);
        break;
      case DateRangeType.year:
        startDate = DateTime(date.year, 1, 1);
        endDate = DateTime(date.year + 1, 1, 0);
        break;
    }

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
