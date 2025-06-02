// lib/sleep/styles/sleep_chart_style.dart
import 'package:flutter/material.dart';

import '../models/sleep_quality.dart';
import '../models/sleep_stage.dart';

class SleepChartStyle {
  // Core chart elements
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;

  // Sleep stage colors - carefully chosen for sleep context
  final Color deepSleepColor;
  final Color remSleepColor;
  final Color lightSleepColor;
  final Color awakeColor;
  final Color awakeInBedColor;
  final Color unknownColor;

  // Sleep quality colors
  final Color poorSleepColor;
  final Color insufficientSleepColor;
  final Color adequateSleepColor;
  final Color goodSleepColor;
  final Color excellentSleepColor;
  final Color excessiveSleepColor;

  // Chart styling
  final double barBorderRadius;
  final double barBorderWidth;
  final Color barBorderColor;

  // Goal and recommendation styling
  final Color recommendationLineColor;
  final Color recommendationBackgroundColor;
  final double recommendationLineWidth;
  final bool showRecommendationLine;

  // Grid and labels
  final Color gridLineColor;
  final Color axisLineColor;
  final double gridLineWidth;
  final double axisLineWidth;

  // Animation
  final Duration animationDuration;
  final Curve animationCurve;

  // Typography
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? annotationLabelStyle;
  final TextStyle? valueDisplayStyle;

  // Labels
  final String sleepLabel;
  final String recommendationLabel;
  final String noDataMessage;

  const SleepChartStyle({
    // Core colors - calming sleep-focused palette
    this.primaryColor = const Color(0xFF3F51B5), // Deep blue
    this.secondaryColor = const Color(0xFF9C27B0), // Purple
    this.backgroundColor = Colors.transparent,
    this.surfaceColor = const Color(0xFFF8F9FA),

    // Sleep stage colors - intuitive and distinguishable
    this.deepSleepColor =
        const Color(0xFF1A237E), // Dark blue - deep/restorative
    this.remSleepColor = const Color(0xFF4A148C), // Deep purple - REM/dreams
    this.lightSleepColor = const Color(0xFF7986CB), // Light blue - light sleep
    this.awakeColor = const Color(0xFFFF8A65), // Light orange - awake
    this.awakeInBedColor = const Color(0xFFFFCC02), // Yellow - restless
    this.unknownColor = const Color(0xFFBDBDBD), // Gray - unknown

    // Sleep quality colors - intuitive progression
    this.poorSleepColor = const Color(0xFFD32F2F), // Red
    this.insufficientSleepColor = const Color(0xFFFF9800), // Orange
    this.adequateSleepColor = const Color(0xFFFFC107), // Yellow
    this.goodSleepColor = const Color(0xFF388E3C), // Green
    this.excellentSleepColor = const Color(0xFF1976D2), // Blue
    this.excessiveSleepColor = const Color(0xFF7B1FA2), // Purple

    // Bar styling
    this.barBorderRadius = 8.0,
    this.barBorderWidth = 1.0,
    this.barBorderColor = Colors.white,

    // Recommendation styling
    this.recommendationLineColor = const Color(0xFF4CAF50),
    this.recommendationBackgroundColor = const Color(0x1A4CAF50),
    this.recommendationLineWidth = 2.0,
    this.showRecommendationLine = true,

    // Grid styling
    this.gridLineColor = const Color(0xFFE1E8ED),
    this.axisLineColor = const Color(0xFFBDBDBD),
    this.gridLineWidth = 0.8,
    this.axisLineWidth = 1.2,

    // Animation
    this.animationDuration = const Duration(milliseconds: 1000),
    this.animationCurve = Curves.easeInOutCubic,

    // Typography
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.annotationLabelStyle,
    this.valueDisplayStyle,

    // Labels
    this.sleepLabel = 'Sleep',
    this.recommendationLabel = '7-9h Recommended',
    this.noDataMessage = 'No sleep data available',
  });

  /// Get color for a specific sleep stage
  Color getSleepStageColor(SleepStage stage) {
    switch (stage) {
      case SleepStage.deep:
        return deepSleepColor;
      case SleepStage.rem:
        return remSleepColor;
      case SleepStage.light:
        return lightSleepColor;
      case SleepStage.awake:
        return awakeColor;
      case SleepStage.awakeInBed:
        return awakeInBedColor;
      case SleepStage.unknown:
        return unknownColor;
    }
  }

  /// Get color for sleep quality
  Color getSleepQualityColor(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return poorSleepColor;
      case SleepQuality.insufficient:
        return insufficientSleepColor;
      case SleepQuality.adequate:
        return adequateSleepColor;
      case SleepQuality.good:
        return goodSleepColor;
      case SleepQuality.excellent:
        return excellentSleepColor;
      case SleepQuality.excessive:
        return excessiveSleepColor;
    }
  }

  // Default text styles
  TextStyle get defaultGridLabelStyle => TextStyle(
        color: Colors.grey[700],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  TextStyle get defaultDateLabelStyle => TextStyle(
        color: Colors.grey[800],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  TextStyle get defaultAnnotationLabelStyle => TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  TextStyle get defaultValueDisplayStyle => TextStyle(
        color: primaryColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      );

  /// Dark theme adaptation
  SleepChartStyle adaptToTheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return SleepChartStyle(
        primaryColor: const Color(0xFF7986CB),
        secondaryColor: const Color(0xFFBA68C8),
        backgroundColor: Colors.transparent,
        surfaceColor: const Color(0xFF303030),
        gridLineColor: const Color(0xFF424242),
        axisLineColor: const Color(0xFF616161),

        // Adjusted sleep stage colors for dark theme
        deepSleepColor: const Color(0xFF3F51B5),
        remSleepColor: const Color(0xFF9C27B0),
        lightSleepColor: const Color(0xFF90CAF9),
        awakeColor: const Color(0xFFFFAB91),
        awakeInBedColor: const Color(0xFFFFF176),
        unknownColor: const Color(0xFF757575),
      );
    }
    return this;
  }
}
