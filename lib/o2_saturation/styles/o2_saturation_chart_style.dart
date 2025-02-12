import 'package:flutter/material.dart';

class O2SaturationChartStyle {
  final Color primaryColor;
  final Color pulseRateColor;
  final Color normalRangeColor;
  final Color mildRangeColor;
  final Color moderateRangeColor;
  final Color severeRangeColor;
  final Color criticalRangeColor;
  final Color gridLineColor;
  final Color selectedHighlightColor;
  final double pointRadius;
  final double lineThickness;
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final Color rangePaintColor; // Add this property

  const O2SaturationChartStyle({
    this.primaryColor = const Color(0xFF4CAF50),
    this.pulseRateColor = const Color(0xFFE53E3E),
    this.normalRangeColor = const Color(0xFF4CAF50),
    this.mildRangeColor = const Color(0xFFFFA726),
    this.moderateRangeColor = const Color(0xFFF57C00),
    this.severeRangeColor = const Color(0xFFF44336),
    this.criticalRangeColor = const Color(0xFFD32F2F),
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9DA1C8FF),
    this.pointRadius = 4.0,
    this.lineThickness = 2.0,
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.rangePaintColor = const Color(0xFF4CAF50), // Initialize the property
  });

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
}
