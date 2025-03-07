import 'package:flutter/material.dart';

import '../models/heart_rate_range.dart';
import '../models/heart_rate_zone.dart';

class HeartRateChartStyle {
  // Main colors
  final Color primaryColor;
  final Color backgroundColor;
  final Color gridLineColor;
  final Color labelColor;
  final Color selectedColor;
  final Color restingRateColor;

  // Zone colors
  final Color lowZoneColor;
  final Color normalZoneColor;
  final Color elevatedZoneColor;
  final Color highZoneColor;

  // Gradient for area beneath the line
  final LinearGradient areaGradient;

  // Line and point dimensions
  final double lineThickness;
  final double pointRadius;
  final double selectedPointRadius;

  // Text styles
  final TextStyle? labelStyle;
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;
  final TextStyle? tooltipTextStyle;
  final TextStyle? gridLabelStyle;
  final TextStyle? emptyStateStyle;
  final TextStyle? zoneTextStyle;
  final TextStyle? valueLabelStyle;
  final TextStyle? averageLabelStyle;
  final TextStyle? dateLabelStyle;

  // Tooltip design
  final BorderRadius tooltipBorderRadius;
  final List<BoxShadow> tooltipShadow;

  // Labels
  final String heartRateLabel;
  final String restingRateLabel;
  final String measurementsLabel;
  final String summaryLabel;
  final String averageLabel;
  final String rangeLabel;
  final String hrvLabel;
  final String statisticsLabel;
  final String todayLabel;
  final String yesterdayLabel;
  final String thisWeekLabel;
  final String lastWeekLabel;
  final String thisMonthLabel;
  final String lastMonthLabel;
  final String noDataLabel;
  final String lowZoneLabel;
  final String normalZoneLabel;
  final String elevatedZoneLabel;
  final String highZoneLabel;
  final String bpmLabel;
  final String msLabel; // For HRV (milliseconds)

  const HeartRateChartStyle({
    this.primaryColor = const Color(0xFFE53E3E),
    this.backgroundColor = Colors.white,
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.labelColor = const Color(0xFF718096),
    this.selectedColor = const Color(0xFFE53E3E),
    this.restingRateColor = const Color(0xFF6B46C1),
    this.lowZoneColor = const Color(0xFF3182CE),
    this.normalZoneColor = const Color(0xFF48BB78),
    this.elevatedZoneColor = const Color(0xFFED8936),
    this.highZoneColor = const Color(0xFFE53E3E),
    this.lineThickness = 2.5,
    this.pointRadius = 4.0,
    this.selectedPointRadius = 6.0,
    this.labelStyle,
    this.headerStyle,
    this.subHeaderStyle,
    this.tooltipTextStyle,
    this.gridLabelStyle,
    this.emptyStateStyle,
    this.zoneTextStyle,
    this.valueLabelStyle,
    this.averageLabelStyle,
    this.dateLabelStyle,
    this.tooltipBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.tooltipShadow = const [
      BoxShadow(
        color: Color(0x20000000),
        blurRadius: 8,
        spreadRadius: 1,
        offset: Offset(0, 4),
      ),
    ],
    this.areaGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x40E53E3E),
        Color(0x05E53E3E),
      ],
    ),
    this.heartRateLabel = 'Heart Rate',
    this.restingRateLabel = 'Resting Rate',
    this.measurementsLabel = 'Measurements',
    this.summaryLabel = 'Summary',
    this.averageLabel = 'Average',
    this.rangeLabel = 'Range',
    this.hrvLabel = 'HRV',
    this.statisticsLabel = 'Statistics',
    this.todayLabel = 'Today',
    this.yesterdayLabel = 'Yesterday',
    this.thisWeekLabel = 'This Week',
    this.lastWeekLabel = 'Last Week',
    this.thisMonthLabel = 'This Month',
    this.lastMonthLabel = 'Last Month',
    this.noDataLabel = 'No heart rate data available',
    this.lowZoneLabel = 'Low',
    this.normalZoneLabel = 'Normal',
    this.elevatedZoneLabel = 'Elevated',
    this.highZoneLabel = 'High',
    this.bpmLabel = 'bpm',
    this.msLabel = 'ms',
  });

  // Get default text styles with fallbacks
  TextStyle get defaultLabelStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultHeaderStyle => const TextStyle(
        fontSize: 18,
        color: Color(0xFF4A5568),
        fontWeight: FontWeight.w600,
      );

  TextStyle get defaultSubHeaderStyle => const TextStyle(
        fontSize: 14,
        color: Color(0xFF718096),
        fontWeight: FontWeight.w500,
      );

  TextStyle get defaultTooltipTextStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF4A5568),
      );

  TextStyle get defaultGridLabelStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 10,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultEmptyStateStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultZoneTextStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  TextStyle get defaultValueLabelStyle => const TextStyle(
        fontSize: 13,
        color: Color(0xFF4A5568),
        fontWeight: FontWeight.bold,
      );

  TextStyle get defaultAverageLabelStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF718096),
      );

  TextStyle get defaultDateLabelStyle => const TextStyle(
        fontSize: 11,
        color: Color(0xFF718096),
      );

  // Getter methods for text styles with fallbacks
  TextStyle get effectiveLabelStyle => labelStyle ?? defaultLabelStyle;

  TextStyle get effectiveHeaderStyle => headerStyle ?? defaultHeaderStyle;

  TextStyle get effectiveSubHeaderStyle =>
      subHeaderStyle ?? defaultSubHeaderStyle;

  TextStyle get effectiveTooltipTextStyle =>
      tooltipTextStyle ?? defaultTooltipTextStyle;

  TextStyle get effectiveGridLabelStyle =>
      gridLabelStyle ?? defaultGridLabelStyle;

  TextStyle get effectiveEmptyStateStyle =>
      emptyStateStyle ?? defaultEmptyStateStyle;

  TextStyle get effectiveZoneTextStyle => zoneTextStyle ?? defaultZoneTextStyle;

  TextStyle get effectiveValueLabelStyle =>
      valueLabelStyle ?? defaultValueLabelStyle;

  TextStyle get effectiveAverageLabelStyle =>
      averageLabelStyle ?? defaultAverageLabelStyle;

  TextStyle get effectiveDateLabelStyle =>
      dateLabelStyle ?? defaultDateLabelStyle;

  // Get color for a specific heart rate zone
  Color getZoneColor(double value) {
    if (value < HeartRateRange.lowMax) return lowZoneColor;
    if (value < HeartRateRange.normalMax) return normalZoneColor;
    if (value < HeartRateRange.elevatedMax) return elevatedZoneColor;
    return highZoneColor;
  }

  // Get zone label for a specific heart rate zone
  String getZoneLabel(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.low:
        return lowZoneLabel;
      case HeartRateZone.normal:
        return normalZoneLabel;
      case HeartRateZone.elevated:
        return elevatedZoneLabel;
      case HeartRateZone.high:
        return highZoneLabel;
    }
  }

  // Get zone label based on value
  String getZoneLabelFromValue(double value) {
    if (value < HeartRateRange.lowMax) return lowZoneLabel;
    if (value < HeartRateRange.normalMax) return normalZoneLabel;
    if (value < HeartRateRange.elevatedMax) return elevatedZoneLabel;
    return highZoneLabel;
  }

  // Create a dark theme style
  factory HeartRateChartStyle.dark() {
    return const HeartRateChartStyle(
      primaryColor: Color(0xFFF56565),
      backgroundColor: Color(0xFF2D3748),
      gridLineColor: Color(0xFF4A5568),
      labelColor: Color(0xFFE2E8F0),
      selectedColor: Color(0xFFF56565),
      restingRateColor: Color(0xFFB794F4),
      lowZoneColor: Color(0xFF63B3ED),
      normalZoneColor: Color(0xFF68D391),
      elevatedZoneColor: Color(0xFFF6AD55),
      highZoneColor: Color(0xFFF56565),
      // Dark theme specific text styles can be added here
    );
  }

  // Copy with constructor for easy customization
  HeartRateChartStyle copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? gridLineColor,
    Color? labelColor,
    Color? selectedColor,
    Color? restingRateColor,
    Color? lowZoneColor,
    Color? normalZoneColor,
    Color? elevatedZoneColor,
    Color? highZoneColor,
    LinearGradient? areaGradient,
    double? lineThickness,
    double? pointRadius,
    double? selectedPointRadius,
    TextStyle? labelStyle,
    TextStyle? headerStyle,
    TextStyle? subHeaderStyle,
    TextStyle? tooltipTextStyle,
    TextStyle? gridLabelStyle,
    TextStyle? emptyStateStyle,
    TextStyle? zoneTextStyle,
    TextStyle? valueLabelStyle,
    TextStyle? averageLabelStyle,
    TextStyle? dateLabelStyle,
    BorderRadius? tooltipBorderRadius,
    List<BoxShadow>? tooltipShadow,
    String? heartRateLabel,
    String? restingRateLabel,
    String? measurementsLabel,
    String? summaryLabel,
    String? averageLabel,
    String? rangeLabel,
    String? hrvLabel,
    String? statisticsLabel,
    String? todayLabel,
    String? yesterdayLabel,
    String? thisWeekLabel,
    String? lastWeekLabel,
    String? thisMonthLabel,
    String? lastMonthLabel,
    String? noDataLabel,
    String? lowZoneLabel,
    String? normalZoneLabel,
    String? elevatedZoneLabel,
    String? highZoneLabel,
    String? bpmLabel,
    String? msLabel,
  }) {
    return HeartRateChartStyle(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      labelColor: labelColor ?? this.labelColor,
      selectedColor: selectedColor ?? this.selectedColor,
      restingRateColor: restingRateColor ?? this.restingRateColor,
      lowZoneColor: lowZoneColor ?? this.lowZoneColor,
      normalZoneColor: normalZoneColor ?? this.normalZoneColor,
      elevatedZoneColor: elevatedZoneColor ?? this.elevatedZoneColor,
      highZoneColor: highZoneColor ?? this.highZoneColor,
      areaGradient: areaGradient ?? this.areaGradient,
      lineThickness: lineThickness ?? this.lineThickness,
      pointRadius: pointRadius ?? this.pointRadius,
      selectedPointRadius: selectedPointRadius ?? this.selectedPointRadius,
      labelStyle: labelStyle ?? this.labelStyle,
      headerStyle: headerStyle ?? this.headerStyle,
      subHeaderStyle: subHeaderStyle ?? this.subHeaderStyle,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      gridLabelStyle: gridLabelStyle ?? this.gridLabelStyle,
      emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
      zoneTextStyle: zoneTextStyle ?? this.zoneTextStyle,
      valueLabelStyle: valueLabelStyle ?? this.valueLabelStyle,
      averageLabelStyle: averageLabelStyle ?? this.averageLabelStyle,
      dateLabelStyle: dateLabelStyle ?? this.dateLabelStyle,
      tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
      tooltipShadow: tooltipShadow ?? this.tooltipShadow,
      heartRateLabel: heartRateLabel ?? this.heartRateLabel,
      restingRateLabel: restingRateLabel ?? this.restingRateLabel,
      measurementsLabel: measurementsLabel ?? this.measurementsLabel,
      summaryLabel: summaryLabel ?? this.summaryLabel,
      averageLabel: averageLabel ?? this.averageLabel,
      rangeLabel: rangeLabel ?? this.rangeLabel,
      hrvLabel: hrvLabel ?? this.hrvLabel,
      statisticsLabel: statisticsLabel ?? this.statisticsLabel,
      todayLabel: todayLabel ?? this.todayLabel,
      yesterdayLabel: yesterdayLabel ?? this.yesterdayLabel,
      thisWeekLabel: thisWeekLabel ?? this.thisWeekLabel,
      lastWeekLabel: lastWeekLabel ?? this.lastWeekLabel,
      thisMonthLabel: thisMonthLabel ?? this.thisMonthLabel,
      lastMonthLabel: lastMonthLabel ?? this.lastMonthLabel,
      noDataLabel: noDataLabel ?? this.noDataLabel,
      lowZoneLabel: lowZoneLabel ?? this.lowZoneLabel,
      normalZoneLabel: normalZoneLabel ?? this.normalZoneLabel,
      elevatedZoneLabel: elevatedZoneLabel ?? this.elevatedZoneLabel,
      highZoneLabel: highZoneLabel ?? this.highZoneLabel,
      bpmLabel: bpmLabel ?? this.bpmLabel,
      msLabel: msLabel ?? this.msLabel,
    );
  }
}
