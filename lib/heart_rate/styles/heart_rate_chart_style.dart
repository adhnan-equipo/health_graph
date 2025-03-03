// lib/heart_rate/styles/heart_rate_chart_style.dart
import 'package:flutter/material.dart';

import '../models/heart_rate_range.dart';

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
  final TextStyle labelStyle;
  final TextStyle headerStyle;
  final TextStyle subHeaderStyle;
  final TextStyle tooltipTextStyle;

  // Tooltip design
  final BorderRadius tooltipBorderRadius;
  final List<BoxShadow> tooltipShadow;

  // Labels
  final String systolicLabel;
  final String diastolicLabel;
  final String measurementsLabel;
  final String summaryLabel;
  final String averageLabel;
  final String rangeLabel;
  final String hrvLabel;
  final String restingLabel;

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
    this.labelStyle = const TextStyle(
      color: Color(0xFF718096),
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    this.headerStyle = const TextStyle(
      fontSize: 18,
      color: Color(0xFF4A5568),
      fontWeight: FontWeight.w600,
    ),
    this.subHeaderStyle = const TextStyle(
      fontSize: 14,
      color: Color(0xFF718096),
      fontWeight: FontWeight.w500,
    ),
    this.tooltipTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF4A5568),
    ),
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
    this.systolicLabel = 'Heart Rate',
    this.diastolicLabel = 'Resting Rate',
    this.measurementsLabel = 'Measurements',
    this.summaryLabel = 'Summary',
    this.averageLabel = 'Average',
    this.rangeLabel = 'Range',
    this.hrvLabel = 'HRV',
    this.restingLabel = 'Resting Rate',
  });

  // Copy with constructor
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
    BorderRadius? tooltipBorderRadius,
    List<BoxShadow>? tooltipShadow,
    String? systolicLabel,
    String? diastolicLabel,
    String? measurementsLabel,
    String? summaryLabel,
    String? averageLabel,
    String? rangeLabel,
    String? hrvLabel,
    String? restingLabel,
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
      tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
      tooltipShadow: tooltipShadow ?? this.tooltipShadow,
      systolicLabel: systolicLabel ?? this.systolicLabel,
      diastolicLabel: diastolicLabel ?? this.diastolicLabel,
      measurementsLabel: measurementsLabel ?? this.measurementsLabel,
      summaryLabel: summaryLabel ?? this.summaryLabel,
      averageLabel: averageLabel ?? this.averageLabel,
      rangeLabel: rangeLabel ?? this.rangeLabel,
      hrvLabel: hrvLabel ?? this.hrvLabel,
      restingLabel: restingLabel ?? this.restingLabel,
    );
  }

  // Get color for a specific heart rate zone
  Color getZoneColor(double value) {
    if (value < HeartRateRange.lowMax) return lowZoneColor;
    if (value < HeartRateRange.normalMax) return normalZoneColor;
    if (value < HeartRateRange.elevatedMax) return elevatedZoneColor;
    return highZoneColor;
  }
}

// Import the range class for zone calculations
