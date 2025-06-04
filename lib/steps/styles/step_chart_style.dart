// lib/steps/styles/step_chart_style.dart
import 'package:flutter/material.dart';

import '../models/step_category.dart';

class StepChartStyle {
  // Enhanced core chart elements for low values
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;

  // Enhanced bar chart colors with better contrast
  final Color barColor;
  final Color barBorderColor;
  final Color barGradientStartColor;
  final Color barGradientEndColor;
  final double barBorderRadius;
  final double barBorderWidth;

  // Enhanced line chart elements for better visibility
  final Color lineColor;
  final Color lineGradientStartColor;
  final Color lineGradientEndColor;
  final double lineThickness;
  final Color pointColor;
  final double pointRadius;
  final Color pointBorderColor;
  final double pointBorderWidth;

  // Enhanced grid and axes for low values
  final Color gridLineColor;
  final Color axisLineColor;
  final double gridLineWidth;
  final double axisLineWidth;

  // Enhanced goal indicators
  final Color goalLineColor;
  final Color goalAchievedColor;
  final Color goalBackgroundColor;
  final double goalLineWidth;
  final bool showGoalLine;

  // Enhanced activity level colors (optimized for low values)
  final Color sedentaryColor;
  final Color lightActiveColor;
  final Color fairlyActiveColor;
  final Color veryActiveColor;
  final Color highlyActiveColor;

  // Enhanced annotations and highlights
  final Color highlightColor;
  final Color annotationBackgroundColor;
  final Color annotationTextColor;
  final double annotationBorderRadius;

  // Enhanced typography for low values
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? annotationLabelStyle;
  final TextStyle? valueDisplayStyle;

  // Animation and interaction
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHapticFeedback;

  // NEW: Low value specific settings
  final bool enhanceLowValues;
  final double lowValueThreshold;
  final Color lowValueHighlightColor;
  final bool showValueLabelsForLowValues;

  // ====== COMPREHENSIVE TEXT LABELS ======

  // Basic labels
  final String stepsLabel;
  final String goalLabel;
  final String noDataMessage;

  // Activity level labels
  final String sedentaryLabel;
  final String lightActiveLabel;
  final String fairlyActiveLabel;
  final String veryActiveLabel;
  final String highlyActiveLabel;

  // Goal and achievement messages
  final String goalAchievedMessage;
  final String goalProgressMessage;
  final String motivationalMessage;
  final String milestoneMessage;
  final String stepsToGoMessage;

  // Tooltip headers and sections
  final String dailySummaryTitle;
  final String weekSummaryTitle;
  final String monthSummaryTitle;
  final String yearSummaryTitle;

  // Display labels by view type
  final String totalStepsLabel;
  final String avgPerDayLabel;
  final String readingsLabel;
  final String activityLabel;
  final String activeDaysLabel;
  final String daysLabel;

  // Goal related labels
  final String dailyGoalLabel;
  final String goalLineLabel;
  final String nextMilestoneLabel;

  // Annotation texts
  final String highestStepsAnnotation;
  final String lowestStepsAnnotation;

  // Activity descriptions
  final String sedentaryDescription;
  final String lightActiveDescription;
  final String fairlyActiveDescription;
  final String veryActiveDescription;
  final String highlyActiveDescription;

  // Low value specific messages
  final String lowValueEncouragement;
  final String everyStepCountsMessage;
  final String keepGoingMessage;

  const StepChartStyle({
    // Enhanced color scheme for better low-value visibility
    this.primaryColor = const Color(0xFF1976D2),
    this.secondaryColor = const Color(0xFF388E3C),
    this.backgroundColor = Colors.transparent,
    this.surfaceColor = const Color(0xFFF8F9FA),

    // Enhanced bar styling for low values
    this.barColor = const Color(0xFF2196F3),
    this.barBorderColor = const Color(0xFF1565C0),
    this.barGradientStartColor = const Color(0xFF64B5F6),
    this.barGradientEndColor = const Color(0xFF1976D2),
    this.barBorderRadius = 8.0,
    this.barBorderWidth = 1.5, // Increased for better definition

    // Enhanced line styling
    this.lineColor = const Color(0xFF4CAF50),
    this.lineGradientStartColor = const Color(0xFF66BB6A),
    this.lineGradientEndColor = const Color(0xFF2E7D32),
    this.lineThickness = 3.5, // Increased for better visibility
    this.pointColor = const Color(0xFF2196F3),
    this.pointRadius = 7.0, // Increased for low values
    this.pointBorderColor = Colors.white,
    this.pointBorderWidth = 2.5, // Increased

    // Enhanced grid for better low value reading
    this.gridLineColor = const Color(0xFFE1E8ED),
    this.axisLineColor = const Color(0xFFBDBDBD),
    this.gridLineWidth = 0.8, // Slightly increased
    this.axisLineWidth = 1.2,

    // Enhanced goal indicators
    this.goalLineColor = const Color(0xFFFF6F00),
    this.goalAchievedColor = const Color(0xFF4CAF50),
    this.goalBackgroundColor = const Color(0x1AFF6F00),
    this.goalLineWidth = 2.5, // Increased for visibility
    this.showGoalLine = true,

    // Enhanced activity level colors (high contrast for low values)
    this.sedentaryColor = const Color(0xFFE57373), // Lighter red
    this.lightActiveColor = const Color(0xFFFFB74D), // Warmer orange
    this.fairlyActiveColor = const Color(0xFFFFF176), // Brighter yellow
    this.veryActiveColor = const Color(0xFF81C784), // Softer green
    this.highlyActiveColor = const Color(0xFF4DB6AC), // Vibrant teal

    // Enhanced highlights
    this.highlightColor = const Color(0x4D2196F3),
    this.annotationBackgroundColor = const Color(0xFF37474F),
    this.annotationTextColor = Colors.white,
    this.annotationBorderRadius = 6.0,

    // Enhanced typography
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.annotationLabelStyle,
    this.valueDisplayStyle,

    // Animation settings
    this.animationDuration =
        const Duration(milliseconds: 1000), // Increased for better effect
    this.animationCurve = Curves.easeInOutCubic,
    this.enableHapticFeedback = true,

    // NEW: Low value enhancements
    this.enhanceLowValues = true,
    this.lowValueThreshold = 2000.0,
    this.lowValueHighlightColor = const Color(0x20FF6F00),
    this.showValueLabelsForLowValues = true,

    // ====== TEXT LABELS WITH DEFAULTS ======

    // Basic labels
    this.stepsLabel = 'steps_label',
    this.goalLabel = 'goal_label',
    this.noDataMessage = 'no_step_data_message',

    // Activity level labels
    this.sedentaryLabel = 'sedentary_label',
    this.lightActiveLabel = 'light_active_label',
    this.fairlyActiveLabel = 'fairly_active_label',
    this.veryActiveLabel = 'very_active_label',
    this.highlyActiveLabel = 'highly_active_label',

    // Goal and achievement messages
    this.goalAchievedMessage = 'goal_achieved_message',
    this.goalProgressMessage = 'goal_progress_message',
    this.motivationalMessage = 'motivational_message',
    this.milestoneMessage = 'milestone_message',
    this.stepsToGoMessage = 'steps_to_go_message',

    // Tooltip headers and sections
    this.dailySummaryTitle = 'daily_summary_title',
    this.weekSummaryTitle = 'week_summary_title',
    this.monthSummaryTitle = 'month_summary_title',
    this.yearSummaryTitle = 'year_summary_title',

    // Display labels by view type
    this.totalStepsLabel = 'total_steps_label',
    this.avgPerDayLabel = 'avg_per_day_label',
    this.readingsLabel = 'readings_label',
    this.activityLabel = 'activity_label',
    this.activeDaysLabel = 'active_days_label',
    this.daysLabel = 'days_label',

    // Goal related labels
    this.dailyGoalLabel = 'daily_goal_label',
    this.goalLineLabel = 'goal_line_label',
    this.nextMilestoneLabel = 'next_milestone_label',

    // Annotation texts
    this.highestStepsAnnotation = 'highest_steps_annotation',
    this.lowestStepsAnnotation = 'lowest_steps_annotation',

    // Activity descriptions
    this.sedentaryDescription = 'sedentary_description',
    this.lightActiveDescription = 'light_active_description',
    this.fairlyActiveDescription = 'fairly_active_description',
    this.veryActiveDescription = 'very_active_description',
    this.highlyActiveDescription = 'highly_active_description',

    // Low value specific messages
    this.lowValueEncouragement = 'low_value_encouragement',
    this.everyStepCountsMessage = 'every_step_counts_message',
    this.keepGoingMessage = 'keep_going_message',
  });

  /// Enhanced category color method with better contrast for low values
  Color getCategoryColor(StepCategory category) {
    switch (category) {
      case StepCategory.sedentary:
        return sedentaryColor;
      case StepCategory.lightActive:
        return lightActiveColor;
      case StepCategory.fairlyActive:
        return fairlyActiveColor;
      case StepCategory.veryActive:
        return veryActiveColor;
      case StepCategory.highlyActive:
        return highlyActiveColor;
    }
  }

  String getCategoryLabel(
    StepCategory category,
  ) {
    switch (category) {
      case StepCategory.sedentary:
        return sedentaryLabel;
      case StepCategory.lightActive:
        return lightActiveLabel;
      case StepCategory.fairlyActive:
        return fairlyActiveLabel;
      case StepCategory.veryActive:
        return veryActiveLabel;
      case StepCategory.highlyActive:
        return highlyActiveLabel;
    }
  }

  // Enhanced default text styles for better low value visibility
  TextStyle get defaultGridLabelStyle => TextStyle(
        color: Colors.grey[700], // Darker for better contrast
        fontSize: 12, // Slightly larger
        fontWeight: FontWeight.w600, // Bolder
        letterSpacing: 0.3,
      );

  TextStyle get defaultDateLabelStyle => TextStyle(
        color: Colors.grey[800], // Darker
        fontSize: 12, // Larger
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  TextStyle get defaultAnnotationLabelStyle => TextStyle(
        color: annotationTextColor,
        fontSize: 11, // Larger
        fontWeight: FontWeight.w700, // Bolder
        letterSpacing: 0.5,
      );

  TextStyle get defaultValueDisplayStyle => TextStyle(
        color: primaryColor,
        fontSize: 13, // Larger for low values
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      );

  // NEW: Style for low value labels
  TextStyle get lowValueLabelStyle => TextStyle(
        color: primaryColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(
            offset: const Offset(0, 1),
            blurRadius: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      );

  // Enhanced method for low value detection
  bool isLowValue(double value) {
    return enhanceLowValues && value < lowValueThreshold;
  }

  // Factory method for low-value optimized style
  static StepChartStyle lowValueOptimized({
    Color? primaryColor,
    bool? showValueLabels,
  }) {
    return StepChartStyle(
      primaryColor: primaryColor ?? const Color(0xFF1976D2),
      pointRadius: 8.0,
      // Larger points
      lineThickness: 4.0,
      // Thicker lines
      barBorderWidth: 2.0,
      // Thicker borders
      gridLineWidth: 1.0,
      // More visible grid
      goalLineWidth: 3.0,
      // More prominent goal line
      enhanceLowValues: true,
      lowValueThreshold: 1000.0,
      // Lower threshold
      showValueLabelsForLowValues: showValueLabels ?? true,
      animationDuration:
          const Duration(milliseconds: 1200), // Slower for effect
    );
  }

  // Theme-aware style factory with low value enhancements
  StepChartStyle adaptToTheme(Brightness brightness,
      {bool optimizeForLowValues = false}) {
    if (brightness == Brightness.dark) {
      return StepChartStyle(
        primaryColor: const Color(0xFF90CAF9),
        secondaryColor: const Color(0xFF81C784),
        backgroundColor: Colors.transparent,
        surfaceColor: const Color(0xFF303030),
        gridLineColor: const Color(0xFF424242),
        axisLineColor: const Color(0xFF616161),
        barColor: const Color(0xFF64B5F6),
        lineColor: const Color(0xFF81C784),

        // Enhanced for low values if requested
        enhanceLowValues: optimizeForLowValues,
        pointRadius: optimizeForLowValues ? 8.0 : pointRadius,
        lineThickness: optimizeForLowValues ? 4.0 : lineThickness,
        showValueLabelsForLowValues: optimizeForLowValues,
      );
    }

    if (optimizeForLowValues) {
      return lowValueOptimized();
    }

    return this;
  }
}
