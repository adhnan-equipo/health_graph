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

  // ====== COMPREHENSIVE TEXT LABELS ======

  // Basic labels
  final String sleepLabel;
  final String recommendationLabel;
  final String noDataMessage;

  // Sleep quality labels
  final String poorSleepLabel;
  final String insufficientSleepLabel;
  final String adequateSleepLabel;
  final String goodSleepLabel;
  final String excellentSleepLabel;
  final String excessiveSleepLabel;

  // Sleep quality descriptions
  final String poorSleepDescription;
  final String insufficientSleepDescription;
  final String adequateSleepDescription;
  final String goodSleepDescription;
  final String excellentSleepDescription;
  final String excessiveSleepDescription;

  // Sleep quality advice
  final String poorSleepAdvice;
  final String insufficientSleepAdvice;
  final String adequateSleepAdvice;
  final String excessiveSleepAdvice;
  final String defaultSleepAdvice;

  // Sleep stages labels
  final String deepSleepLabel;
  final String remSleepLabel;
  final String lightSleepLabel;
  final String awakeSleepLabel;
  final String awakeInBedLabel;
  final String unknownSleepLabel;

  // Sleep stages short labels
  final String deepSleepShortLabel;
  final String remSleepShortLabel;
  final String lightSleepShortLabel;
  final String awakeSleepShortLabel;
  final String awakeInBedShortLabel;
  final String unknownSleepShortLabel;

  // Tooltip headers and sections
  final String sleepStagesTitle;
  final String sleepPatternTitle;
  final String sleepSummaryTitle;
  final String weekSummaryTitle;
  final String monthSummaryTitle;
  final String yearSummaryTitle;

  // Display labels by view type
  final String totalSleepLabel;
  final String avgPerNightLabel;
  final String recordingsLabel;
  final String qualityLabel;
  final String sleepDaysLabel;

  // Timing labels
  final String bedtimeLabel;
  final String wakeTimeLabel;
  final String efficiencyLabel;

  // Recommendation messages
  final String goalAchievedMessage;
  final String recommendedRangeDaily;
  final String recommendedRangeAverage;

  // Efficiency descriptions
  final String poorEfficiencyDesc;
  final String fairEfficiencyDesc;
  final String goodEfficiencyDesc;
  final String excellentEfficiencyDesc;

  // Annotation texts
  final String bestSleepAnnotation;
  final String leastSleepAnnotation;

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

    // ====== TEXT LABELS WITH DEFAULTS ======

    // Basic labels
    this.sleepLabel = 'sleep_label',
    this.recommendationLabel = 'recommendation_label',
    this.noDataMessage = 'no_sleep_data_message',

    // Sleep quality labels
    this.poorSleepLabel = 'poor_sleep_label',
    this.insufficientSleepLabel = 'insufficient_sleep_label',
    this.adequateSleepLabel = 'adequate_sleep_label',
    this.goodSleepLabel = 'good_sleep_label',
    this.excellentSleepLabel = 'excellent_sleep_label',
    this.excessiveSleepLabel = 'excessive_sleep_label',

    // Sleep quality descriptions
    this.poorSleepDescription = 'poor_sleep_description',
    this.insufficientSleepDescription = 'insufficient_sleep_description',
    this.adequateSleepDescription = 'adequate_sleep_description',
    this.goodSleepDescription = 'good_sleep_description',
    this.excellentSleepDescription = 'excellent_sleep_description',
    this.excessiveSleepDescription = 'excessive_sleep_description',

    // Sleep quality advice
    this.poorSleepAdvice = 'poor_sleep_advice',
    this.insufficientSleepAdvice = 'insufficient_sleep_advice',
    this.adequateSleepAdvice = 'adequate_sleep_advice',
    this.excessiveSleepAdvice = 'excessive_sleep_advice',
    this.defaultSleepAdvice = 'default_sleep_advice',

    // Sleep stages labels
    this.deepSleepLabel = 'deep_sleep_label',
    this.remSleepLabel = 'rem_sleep_label',
    this.lightSleepLabel = 'light_sleep_label',
    this.awakeSleepLabel = 'awake_sleep_label',
    this.awakeInBedLabel = 'awake_in_bed_label',
    this.unknownSleepLabel = 'unknown_sleep_label',

    // Sleep stages short labels
    this.deepSleepShortLabel = 'deep_sleep_short_label',
    this.remSleepShortLabel = 'rem_sleep_short_label',
    this.lightSleepShortLabel = 'light_sleep_short_label',
    this.awakeSleepShortLabel = 'awake_sleep_short_label',
    this.awakeInBedShortLabel = 'awake_in_bed_short_label',
    this.unknownSleepShortLabel = 'unknown_sleep_short_label',

    // Tooltip headers and sections
    this.sleepStagesTitle = 'sleep_stages_title',
    this.sleepPatternTitle = 'sleep_pattern_title',
    this.sleepSummaryTitle = 'sleep_summary_title',
    this.weekSummaryTitle = 'week_summary_title',
    this.monthSummaryTitle = 'month_summary_title',
    this.yearSummaryTitle = 'year_summary_title',

    // Display labels by view type
    this.totalSleepLabel = 'total_sleep_label',
    this.avgPerNightLabel = 'avg_per_night_label',
    this.recordingsLabel = 'recordings_label',
    this.qualityLabel = 'quality_label',
    this.sleepDaysLabel = 'sleep_days_label',

    // Timing labels
    this.bedtimeLabel = 'bedtime_label',
    this.wakeTimeLabel = 'wake_time_label',
    this.efficiencyLabel = 'efficiency_label',

    // Recommendation messages
    this.goalAchievedMessage = 'goal_achieved_message',
    this.recommendedRangeDaily = 'recommended_range_daily',
    this.recommendedRangeAverage = 'recommended_range_average',

    // Efficiency descriptions
    this.poorEfficiencyDesc = 'poor_efficiency_desc',
    this.fairEfficiencyDesc = 'fair_efficiency_desc',
    this.goodEfficiencyDesc = 'good_efficiency_desc',
    this.excellentEfficiencyDesc = 'excellent_efficiency_desc',

    // Annotation texts
    this.bestSleepAnnotation = 'best_sleep_annotation',
    this.leastSleepAnnotation = 'least_sleep_annotation',
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
