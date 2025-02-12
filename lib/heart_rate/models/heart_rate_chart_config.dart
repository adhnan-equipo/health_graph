// lib/models/heart_rate_chart_config.dart
import '../../blood_pressure/models/date_range_type.dart';

class HeartRateChartConfig {
  final DateRangeType viewType;
  final DateTime startDate;
  final DateTime endDate;
  final bool showGrid;
  final bool showLabels;
  final bool enableAnimation;
  final bool showTrendLine;
  final bool showRanges;
  final double zoomLevel;
  final bool showRestingRate;
  final bool showHRV;

  const HeartRateChartConfig({
    required this.viewType,
    required this.startDate,
    required this.endDate,
    this.showGrid = true,
    this.showLabels = true,
    this.enableAnimation = true,
    this.showTrendLine = true,
    this.showRanges = true,
    this.zoomLevel = 1.0,
    this.showRestingRate = true,
    this.showHRV = true,
  });

  HeartRateChartConfig copyWith({
    DateRangeType? viewType,
    DateTime? startDate,
    DateTime? endDate,
    bool? showGrid,
    bool? showLabels,
    bool? enableAnimation,
    bool? showTrendLine,
    bool? showRanges,
    double? zoomLevel,
    bool? showRestingRate,
    bool? showHRV,
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
      zoomLevel: zoomLevel ?? this.zoomLevel,
      showRestingRate: showRestingRate ?? this.showRestingRate,
      showHRV: showHRV ?? this.showHRV,
    );
  }
}
