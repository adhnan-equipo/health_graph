import 'package:flutter/material.dart';

/// Base chart style class containing common styling properties
/// All specific chart styles should extend this to ensure consistency
abstract class BaseChartStyle {
  // Common color properties
  final Color primaryColor;
  final Color gridLineColor;
  final Color backgroundColor;
  final Color surfaceColor;

  // Text style properties
  final TextStyle? gridLabelStyle;
  final TextStyle? dateLabelStyle;

  // Animation and interaction
  final Color selectedHighlightColor;
  final Color highlightColor;

  // Point styling
  final double pointRadius;
  final double pointBorderWidth;
  final Color pointBorderColor;

  // Line styling
  final double lineThickness;
  final Color lineColor;

  const BaseChartStyle({
    required this.primaryColor,
    required this.gridLineColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.gridLabelStyle,
    this.dateLabelStyle,
    required this.selectedHighlightColor,
    required this.highlightColor,
    required this.pointRadius,
    required this.pointBorderWidth,
    required this.pointBorderColor,
    required this.lineThickness,
    required this.lineColor,
  });

  /// Default grid label style - can be overridden by subclasses
  TextStyle get defaultGridLabelStyle => TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  /// Default date label style - can be overridden by subclasses
  TextStyle get defaultDateLabelStyle => TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  /// Effective grid label style (uses default if not specified)
  TextStyle get effectiveGridLabelStyle =>
      gridLabelStyle ?? defaultGridLabelStyle;

  /// Effective date label style (uses default if not specified)
  TextStyle get effectiveDateLabelStyle =>
      dateLabelStyle ?? defaultDateLabelStyle;

  /// Create a copy of this style with modified properties
  BaseChartStyle copyWith({
    Color? primaryColor,
    Color? gridLineColor,
    Color? backgroundColor,
    Color? surfaceColor,
    TextStyle? gridLabelStyle,
    TextStyle? dateLabelStyle,
    Color? selectedHighlightColor,
    Color? highlightColor,
    double? pointRadius,
    double? pointBorderWidth,
    Color? pointBorderColor,
    double? lineThickness,
    Color? lineColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BaseChartStyle &&
        other.primaryColor == primaryColor &&
        other.gridLineColor == gridLineColor &&
        other.backgroundColor == backgroundColor &&
        other.surfaceColor == surfaceColor &&
        other.gridLabelStyle == gridLabelStyle &&
        other.dateLabelStyle == dateLabelStyle &&
        other.selectedHighlightColor == selectedHighlightColor &&
        other.highlightColor == highlightColor &&
        other.pointRadius == pointRadius &&
        other.pointBorderWidth == pointBorderWidth &&
        other.pointBorderColor == pointBorderColor &&
        other.lineThickness == lineThickness &&
        other.lineColor == lineColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      primaryColor,
      gridLineColor,
      backgroundColor,
      surfaceColor,
      gridLabelStyle,
      dateLabelStyle,
      selectedHighlightColor,
      highlightColor,
      pointRadius,
      pointBorderWidth,
      pointBorderColor,
      lineThickness,
      lineColor,
    );
  }
}
