// blood_pressure_chart_style.dart

import 'package:flutter/material.dart';

import '../models/blood_pressure_category.dart';

class BloodPressureChartStyle {
  final Color systolicColor;
  final Color diastolicColor;
  final Color connectorColor;
  final double pointRadius;
  final double singlePointRadius; // New property for single point readings
  final double lineThickness;
  final double singleLineThickness; // New property for single value connections
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;
  final Color selectedTabColor;
  final Color unselectedTabColor;
  final Color gridLineColor;
  final Color selectedHighlightColor;

  final Color normalRangeColor;
  final Color elevatedRangeColor;
  final Color highRangeColor;
  final Color crisisRangeColor;
  final Color lowRangeColor;
  final Color trendLineColor;
  final Color confidenceIntervalColor;
  final LinearGradient systolicGradient;
  final LinearGradient diastolicGradient;

  const BloodPressureChartStyle({
    this.systolicColor = const Color(0xFFE53E3E),
    this.diastolicColor = const Color(0xFF3182CE),
    this.connectorColor = const Color(0x24006DFF),
    this.pointRadius = 4.0,
    this.singlePointRadius = 5.0, // Slightly larger for better visibility
    this.lineThickness = 2.0,
    this.singleLineThickness = 1.5, // Slightly thinner for single readings
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.headerStyle,
    this.subHeaderStyle,
    this.selectedTabColor = const Color(0xFF3182CE),
    this.unselectedTabColor = const Color(0xFF609FFF),
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9DA1C8FF),
    this.normalRangeColor = const Color(0xFF4CAF50),
    this.elevatedRangeColor = const Color(0xFFFFA726),
    this.highRangeColor = const Color(0xFFF44336),
    this.crisisRangeColor = const Color(0xFFD32F2F),
    this.lowRangeColor = const Color(0xFF90CAF9),
    this.trendLineColor = const Color(0xFF9E9E9E),
    this.confidenceIntervalColor = const Color(0x1F000000),
    this.systolicGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE53E3E), Color(0x33E53E3E)],
    ),
    this.diastolicGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3182CE), Color(0x333182CE)],
    ),
  });

  Color getCategoryColor(BloodPressureCategory category) {
    switch (category) {
      case BloodPressureCategory.normal:
        return normalRangeColor;
      case BloodPressureCategory.elevated:
        return elevatedRangeColor;
      case BloodPressureCategory.high:
        return highRangeColor;
      case BloodPressureCategory.crisis:
        return crisisRangeColor;
      case BloodPressureCategory.low:
        return lowRangeColor;
    }
  }

  TextStyle get defaultGridLabelStyle => TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultDateLabelStyle => TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultHeaderStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFF4A5568),
      );

  TextStyle get defaultSubHeaderStyle => const TextStyle(
        fontSize: 16,
        color: Color(0xFF718096),
      );
}
