// lib/blood_pressure/models/chart_view_config.dart
import '../models/date_range_type.dart';

class ChartViewConfig {
  final DateRangeType viewType;
  final DateTime startDate;
  final DateTime endDate;
  final bool showGrid;
  final bool showLabels;
  final bool enableAnimation;
  final bool showTrendLine;
  final bool showConfidenceIntervals;
  final double zoomLevel;

  const ChartViewConfig({
    required this.viewType,
    required this.startDate,
    required this.endDate,
    this.showGrid = true,
    this.showLabels = true,
    this.enableAnimation = true,
    this.showTrendLine = true,
    this.showConfidenceIntervals = true,
    this.zoomLevel = 1.0,
  });

  ChartViewConfig copyWith({
    DateRangeType? viewType,
    DateTime? startDate,
    DateTime? endDate,
    bool? showGrid,
    bool? showLabels,
    bool? enableAnimation,
    bool? showTrendLine,
    bool? showConfidenceIntervals,
    double? zoomLevel,
  }) {
    return ChartViewConfig(
      viewType: viewType ?? this.viewType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showGrid: showGrid ?? this.showGrid,
      showLabels: showLabels ?? this.showLabels,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      showTrendLine: showTrendLine ?? this.showTrendLine,
      showConfidenceIntervals:
          showConfidenceIntervals ?? this.showConfidenceIntervals,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}
