// lib/steps/styles/step_chart_style.dart
import 'package:flutter/material.dart';

import '../models/step_category.dart';

class StepChartStyle {
  // Core chart elements
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;

  // Bar chart colors
  final Color barColor;
  final Color barBorderColor;
  final Color barGradientStartColor;
  final Color barGradientEndColor;
  final double barBorderRadius;
  final double barBorderWidth;

  // Line chart elements
  final Color lineColor;
  final Color lineGradientStartColor;
  final Color lineGradientEndColor;
  final double lineThickness;
  final Color pointColor;
  final double pointRadius;
  final Color pointBorderColor;
  final double pointBorderWidth;

  // Grid and axes
  final Color gridLineColor;
  final Color axisLineColor;
  final double gridLineWidth;
  final double axisLineWidth;

  // Goal indicators
  final Color goalLineColor;
  final Color goalAchievedColor;
  final Color goalBackgroundColor;
  final double goalLineWidth;
  final bool showGoalLine;

  // Activity level colors (modern fitness app palette)
  final Color sedentaryColor;
  final Color lightActiveColor;
  final Color fairlyActiveColor;
  final Color veryActiveColor;
  final Color highlyActiveColor;

  // Annotations and highlights
  final Color highlightColor;
  final Color annotationBackgroundColor;
  final Color annotationTextColor;
  final double annotationBorderRadius;

  // Typography
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? annotationLabelStyle;
  final TextStyle? valueDisplayStyle;

  // Animation and interaction
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHapticFeedback;

  // Labels and messages
  final String sedentaryLabel;
  final String lightActiveLabel;
  final String fairlyActiveLabel;
  final String veryActiveLabel;
  final String highlyActiveLabel;
  final String stepsLabel;
  final String goalLabel;
  final String noDataMessage;

  const StepChartStyle({
    // Modern fitness app color scheme
    this.primaryColor = const Color(0xFF2196F3),
    this.secondaryColor = const Color(0xFF4CAF50),
    this.backgroundColor = Colors.transparent,
    this.surfaceColor = const Color(0xFFF8F9FA),

    // Bar styling with gradient support
    this.barColor = const Color(0xFF2196F3),
    this.barBorderColor = const Color(0xFF1976D2),
    this.barGradientStartColor = const Color(0xFF42A5F5),
    this.barGradientEndColor = const Color(0xFF1976D2),
    this.barBorderRadius = 8.0,
    this.barBorderWidth = 1.0,

    // Line styling with modern gradients
    this.lineColor = const Color(0xFF4CAF50),
    this.lineGradientStartColor = const Color(0xFF66BB6A),
    this.lineGradientEndColor = const Color(0xFF2E7D32),
    this.lineThickness = 3.0,
    this.pointColor = const Color(0xFF2196F3),
    this.pointRadius = 6.0,
    this.pointBorderColor = Colors.white,
    this.pointBorderWidth = 2.0,

    // Grid and axes with subtle styling
    this.gridLineColor = const Color(0xFFE0E0E0),
    this.axisLineColor = const Color(0xFFBDBDBD),
    this.gridLineWidth = 0.5,
    this.axisLineWidth = 1.0,

    // Goal indicators with fitness app styling
    this.goalLineColor = const Color(0xFFFF9800),
    this.goalAchievedColor = const Color(0xFF4CAF50),
    this.goalBackgroundColor = const Color(0x1AFF9800),
    this.goalLineWidth = 2.0,
    this.showGoalLine = true,

    // Activity level colors (vibrant fitness palette)
    this.sedentaryColor = const Color(0xFFEF5350), // Red
    this.lightActiveColor = const Color(0xFFFF7043), // Deep Orange
    this.fairlyActiveColor = const Color(0xFFFFCA28), // Amber
    this.veryActiveColor = const Color(0xFF66BB6A), // Green
    this.highlyActiveColor = const Color(0xFF26A69A), // Teal

    // Annotations and highlights
    this.highlightColor = const Color(0x4D2196F3),
    this.annotationBackgroundColor = const Color(0xFF37474F),
    this.annotationTextColor = Colors.white,
    this.annotationBorderRadius = 6.0,

    // Typography with accessibility
    this.gridLabelStyle,
    this.dateLabelStyle,
    this.annotationLabelStyle,
    this.valueDisplayStyle,

    // Animation settings
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOutCubic,
    this.enableHapticFeedback = true,

    // Labels
    this.sedentaryLabel = 'Sedentary',
    this.lightActiveLabel = 'Light',
    this.fairlyActiveLabel = 'Moderate',
    this.veryActiveLabel = 'Active',
    this.highlyActiveLabel = 'Very Active',
    this.stepsLabel = 'Steps',
    this.goalLabel = '10K Goal',
    this.noDataMessage = 'No step data available',
  });

  // Adaptive color getters for light/dark mode
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

  String getCategoryLabel(StepCategory category) {
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

  // Default text styles with adaptive theming
  TextStyle get defaultGridLabelStyle => TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  TextStyle get defaultDateLabelStyle => TextStyle(
        color: Colors.grey[700],
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  TextStyle get defaultAnnotationLabelStyle => TextStyle(
        color: annotationTextColor,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  TextStyle get defaultValueDisplayStyle => TextStyle(
        color: primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.2,
      );

  // Theme-aware style factory
  StepChartStyle adaptToTheme(Brightness brightness) {
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
        // ... other dark theme colors
      );
    }
    return this;
  }
}
