// lib/steps/styles/step_chart_style.dart
import 'package:flutter/material.dart';

import '../models/step_category.dart';

class StepChartStyle {
  final Color lineColor;
  final Color pointColor;
  final Color gridLineColor;
  final Color selectedHighlightColor;
  final double pointRadius;
  final double lineThickness;
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;

  // Step category colors
  final Color sedentaryColor;
  final Color lightActiveColor;
  final Color fairlyActiveColor;
  final Color veryActiveColor;
  final Color highlyActiveColor;

  // Goal indicators
  final Color goalLineColor;
  final Color goalAchievedColor;

  // Labels
  final String sedentaryLabel;
  final String lightActiveLabel;
  final String fairlyActiveLabel;
  final String veryActiveLabel;
  final String highlyActiveLabel;
  final String stepsLabel;
  final String goalLabel;
  final String noDataMessage;

  const StepChartStyle({
    this.lineColor = const Color(0xFF4CAF50),
    this.pointColor = const Color(0xFF2196F3),
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9D4CAF50),
    this.pointRadius = 4.0,
    this.lineThickness = 2.0,
    this.gridLabelStyle,
    this.dateLabelStyle,

    // Activity level colors inspired by health apps
    this.sedentaryColor = const Color(0xFFE57373), // Light red
    this.lightActiveColor = const Color(0xFFFFB74D), // Orange
    this.fairlyActiveColor = const Color(0xFFFFF176), // Yellow
    this.veryActiveColor = const Color(0xFF81C784), // Light green
    this.highlyActiveColor = const Color(0xFF4CAF50), // Green

    this.goalLineColor = const Color(0xFF2196F3),
    this.goalAchievedColor = const Color(0xFF4CAF50),
    this.sedentaryLabel = 'Sedentary',
    this.lightActiveLabel = 'Light Active',
    this.fairlyActiveLabel = 'Fairly Active',
    this.veryActiveLabel = 'Very Active',
    this.highlyActiveLabel = 'Highly Active',
    this.stepsLabel = 'Steps',
    this.goalLabel = '10K Goal',
    this.noDataMessage = 'No step data available',
  });

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
