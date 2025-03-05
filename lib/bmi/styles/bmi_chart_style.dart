// lib/bmi/styles/bmi_chart_style.dart
import 'package:flutter/material.dart';

import '../models/bmi_category.dart';

class BMIChartStyle {
  final Color lineColor;
  final Color pointColor;
  final Color gridLineColor;
  final Color selectedHighlightColor;
  final double pointRadius;
  final double lineThickness;
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;
  final Color normalRangeColor;
  final Color underweightRangeColor;
  final Color overweightRangeColor;
  final Color obeseRangeColor;
  final Color trendLineColor;
  final LinearGradient chartGradient;
  final String underweightLabel;
  final String normalLabel;
  final String overweightLabel;
  final String obeseLabel;
  final String measurementsLabel;
  final String summaryLabel;
  final String averageLabel;
  final String rangeLabel;
  final String changeLabel;
  final String readingLabel;
  final String lastReadingLabel;
  final String weight;
  final String height;
  final String noData;
  final bool emphasizeLatestValue;

  const BMIChartStyle({
    this.lineColor = const Color(0xFFC5E3FF),
    this.pointColor = const Color(0xFF3182CE),
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9DFFA1A1),
    this.pointRadius = 4.0,
    this.lineThickness = 2.0,
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.headerStyle,
    this.subHeaderStyle,
    this.normalRangeColor = Colors.green,
    this.underweightRangeColor = Colors.blue,
    this.overweightRangeColor = Colors.orange,
    this.obeseRangeColor = Colors.red,
    this.trendLineColor = const Color(0xFF9E9E9E),
    this.chartGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3182CE), Color(0x333182CE)],
    ),
    this.underweightLabel = 'Underweight',
    this.normalLabel = 'Normal',
    this.overweightLabel = 'Overweight',
    this.obeseLabel = 'Obese',
    this.measurementsLabel = 'Measurements',
    this.summaryLabel = 'Summary',
    this.averageLabel = 'Average BMI',
    this.rangeLabel = 'Range',
    this.changeLabel = 'change',
    this.lastReadingLabel = 'lastReading',
    this.readingLabel = 'reading',
    this.height = 'height',
    this.weight = 'weight',
    this.noData = 'No BMI data available',
    this.emphasizeLatestValue = true,
  });

  Color getCategoryColor(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return underweightRangeColor;
      case BMICategory.normal:
        return normalRangeColor;
      case BMICategory.overweight:
        return overweightRangeColor;
      case BMICategory.obese:
        return obeseRangeColor;
    }
  }

  String getCategoryLabel(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return underweightLabel ?? 'Underweight';
      case BMICategory.normal:
        return normalLabel ?? 'Healthy';
      case BMICategory.overweight:
        return overweightLabel ?? 'Overweight';
      case BMICategory.obese:
        return obeseLabel ?? 'Obese';
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
