// lib/styles/heart_rate_chart_style.dart
import 'package:flutter/material.dart';

import '../models/heart_rate_zone.dart';

class HeartRateChartStyle {
  final Color primaryColor;
  final Color backgroundColor;
  final Color gridColor;
  final Color labelColor;
  final Color rangeColor;
  final Color selectedColor;
  final Color lowZoneColor;
  final Color normalZoneColor;
  final Color elevatedZoneColor;
  final Color highZoneColor;
  final LinearGradient areaGradient;
  final LinearGradient selectedAreaGradient;
  final double lineThickness;
  final double pointRadius;
  final double selectedPointRadius;
  final TextStyle labelStyle;
  final TextStyle selectedLabelStyle;
  final double zoneOpacity;
  final List<BoxShadow> tooltipShadow;
  final BorderRadius tooltipBorderRadius;

  const HeartRateChartStyle({
    this.primaryColor = const Color(0xFFFF4B6B),
    this.backgroundColor = Colors.white,
    this.gridColor = const Color(0xFFE2E8F0),
    this.labelColor = const Color(0xFF718096),
    this.rangeColor = const Color(0x1AFF4B6B),
    this.selectedColor = const Color(0xFFFF4B6B),
    this.lowZoneColor = const Color(0xFF3182CE),
    this.normalZoneColor = const Color(0xFF48BB78),
    this.elevatedZoneColor = const Color(0xFFED8936),
    this.highZoneColor = const Color(0xFFE53E3E),
    this.lineThickness = 2.0,
    this.pointRadius = 4.0,
    this.selectedPointRadius = 6.0,
    this.zoneOpacity = 0.1,
    this.areaGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x33FF4B6B),
        Color(0x00FF4B6B),
      ],
      stops: [0.0, 1.0],
    ),
    this.selectedAreaGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x66FF4B6B),
        Color(0x00FF4B6B),
      ],
      stops: [0.0, 1.0],
    ),
    this.labelStyle = const TextStyle(
      color: Color(0xFF718096),
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    this.selectedLabelStyle = const TextStyle(
      color: Color(0xFF2D3748),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
    this.tooltipShadow = const [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
    this.tooltipBorderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  HeartRateChartStyle copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? gridColor,
    Color? labelColor,
    Color? rangeColor,
    Color? selectedColor,
    Color? lowZoneColor,
    Color? normalZoneColor,
    Color? elevatedZoneColor,
    Color? highZoneColor,
    LinearGradient? areaGradient,
    LinearGradient? selectedAreaGradient,
    double? lineThickness,
    double? pointRadius,
    double? selectedPointRadius,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    double? zoneOpacity,
    List<BoxShadow>? tooltipShadow,
    BorderRadius? tooltipBorderRadius,
  }) {
    return HeartRateChartStyle(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      labelColor: labelColor ?? this.labelColor,
      rangeColor: rangeColor ?? this.rangeColor,
      selectedColor: selectedColor ?? this.selectedColor,
      lowZoneColor: lowZoneColor ?? this.lowZoneColor,
      normalZoneColor: normalZoneColor ?? this.normalZoneColor,
      elevatedZoneColor: elevatedZoneColor ?? this.elevatedZoneColor,
      highZoneColor: highZoneColor ?? this.highZoneColor,
      areaGradient: areaGradient ?? this.areaGradient,
      selectedAreaGradient: selectedAreaGradient ?? this.selectedAreaGradient,
      lineThickness: lineThickness ?? this.lineThickness,
      pointRadius: pointRadius ?? this.pointRadius,
      selectedPointRadius: selectedPointRadius ?? this.selectedPointRadius,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      zoneOpacity: zoneOpacity ?? this.zoneOpacity,
      tooltipShadow: tooltipShadow ?? this.tooltipShadow,
      tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
    );
  }

  Color getZoneColor(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.low:
        return lowZoneColor;
      case HeartRateZone.normal:
        return normalZoneColor;
      case HeartRateZone.elevated:
        return elevatedZoneColor;
      case HeartRateZone.high:
        return highZoneColor;
    }
  }
}
