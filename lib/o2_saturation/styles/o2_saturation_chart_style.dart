// lib/o2_saturation/styles/o2_saturation_chart_style.dart
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
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;

  const O2SaturationChartStyle({
    this.primaryColor = const Color(0xFF4CAF50),
    this.pulseRateColor = const Color(0xFFE53E3E),
    this.normalRangeColor = const Color(0xFF4CAF50),
    this.mildRangeColor = const Color(0xFFFFA726),
    this.moderateRangeColor = const Color(0xFFF57C00),
    this.severeRangeColor = const Color(0xFFF44336),
    this.criticalRangeColor = const Color(0xFFD32F2F),
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9D9FE8A1),
    this.pointRadius = 4.0,
    this.lineThickness = 2.0,
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.headerStyle,
    this.subHeaderStyle,
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
