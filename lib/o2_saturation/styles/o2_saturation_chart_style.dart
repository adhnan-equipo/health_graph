import 'package:flutter/material.dart';

class O2SaturationChartStyle {
  // Main colors
  final Color primaryColor;
  final Color pulseRateColor;
  final Color backgroundColor;
  final Color gridLineColor;
  final Color selectedHighlightColor;

  // Range colors
  final Color normalRangeColor;
  final Color mildRangeColor;
  final Color moderateRangeColor;
  final Color severeRangeColor;
  final Color criticalRangeColor;

  // Line and point dimensions
  final double pointRadius;
  final double lineThickness;

  // Text styles
  final TextStyle? labelStyle;
  final TextStyle? headerStyle;
  final TextStyle? subHeaderStyle;
  final TextStyle? tooltipTextStyle;
  final TextStyle? gridLabelStyle;
  final TextStyle? emptyStateStyle;
  final TextStyle? valueLabelStyle;
  final TextStyle? dateLabelStyle;
  final TextStyle? countLabelStyle;
  final TextStyle? statisticsLabelStyle;
  final TextStyle? measurementsLabelStyle;
  final TextStyle? rangeTextStyle;

  // Tooltip design
  final BorderRadius tooltipBorderRadius;
  final List<BoxShadow> tooltipShadow;

  // Labels
  final String o2SaturationLabel;
  final String pulseRateLabel;
  final String measurementsLabel;
  final String summaryLabel;
  final String averageLabel;
  final String rangeLabel;
  final String statisticsLabel;
  final String readingsLabel;
  final String standardDeviationLabel;
  final String todayLabel;
  final String yesterdayLabel;
  final String thisWeekLabel;
  final String lastWeekLabel;
  final String thisMonthLabel;
  final String lastMonthLabel;
  final String noDataLabel;
  final String normalRangeLabel;
  final String mildRangeLabel;
  final String moderateRangeLabel;
  final String severeRangeLabel;
  final String criticalRangeLabel;
  final String percentLabel;
  final String bpmLabel;

  const O2SaturationChartStyle({
    this.primaryColor = const Color(0xFF4CAF50),
    this.pulseRateColor = const Color(0xFFE53E3E),
    this.backgroundColor = Colors.white,
    this.gridLineColor = const Color(0xFFE2E8F0),
    this.selectedHighlightColor = const Color(0x9D9FE8A1),
    this.normalRangeColor = const Color(0xFF4CAF50),
    this.mildRangeColor = const Color(0xFFFFA726),
    this.moderateRangeColor = const Color(0xFFF57C00),
    this.severeRangeColor = const Color(0xFFF44336),
    this.criticalRangeColor = const Color(0xFFD32F2F),
    this.pointRadius = 4.0,
    this.lineThickness = 2.0,
    this.labelStyle,
    this.headerStyle,
    this.subHeaderStyle,
    this.tooltipTextStyle,
    this.gridLabelStyle,
    this.emptyStateStyle,
    this.valueLabelStyle,
    this.dateLabelStyle,
    this.countLabelStyle,
    this.statisticsLabelStyle,
    this.measurementsLabelStyle,
    this.rangeTextStyle,
    this.tooltipBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.tooltipShadow = const [
      BoxShadow(
        color: Color(0x20000000),
        blurRadius: 8,
        spreadRadius: 1,
        offset: Offset(0, 4),
      ),
    ],
    this.o2SaturationLabel = 'O₂ Saturation',
    this.pulseRateLabel = 'Pulse Rate',
    this.measurementsLabel = 'Measurements',
    this.summaryLabel = 'Summary',
    this.averageLabel = 'Average',
    this.rangeLabel = 'Range',
    this.statisticsLabel = 'Statistics',
    this.readingsLabel = 'Readings',
    this.standardDeviationLabel = 'Standard Deviation',
    this.todayLabel = 'Today',
    this.yesterdayLabel = 'Yesterday',
    this.thisWeekLabel = 'This Week',
    this.lastWeekLabel = 'Last Week',
    this.thisMonthLabel = 'This Month',
    this.lastMonthLabel = 'Last Month',
    this.noDataLabel = 'No O₂ saturation data available',
    this.normalRangeLabel = 'Normal (95-100%)',
    this.mildRangeLabel = 'Mild (90-94%)',
    this.moderateRangeLabel = 'Moderate (85-89%)',
    this.severeRangeLabel = 'Severe (80-84%)',
    this.criticalRangeLabel = 'Critical (<80%)',
    this.percentLabel = '%',
    this.bpmLabel = 'bpm',
  });

  // Default text styles with fallbacks
  TextStyle get defaultLabelStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultHeaderStyle => const TextStyle(
        fontSize: 18,
        color: Color(0xFF4A5568),
        fontWeight: FontWeight.w600,
      );

  TextStyle get defaultSubHeaderStyle => const TextStyle(
        fontSize: 14,
        color: Color(0xFF718096),
        fontWeight: FontWeight.w500,
      );

  TextStyle get defaultTooltipTextStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF4A5568),
      );

  TextStyle get defaultGridLabelStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 10,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultEmptyStateStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultValueLabelStyle => const TextStyle(
        fontSize: 13,
        color: Color(0xFF4A5568),
        fontWeight: FontWeight.bold,
      );

  TextStyle get defaultDateLabelStyle => const TextStyle(
        color: Color(0xFF718096),
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  TextStyle get defaultCountLabelStyle => const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      );

  TextStyle get defaultStatisticsLabelStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF718096),
        fontWeight: FontWeight.w500,
      );

  TextStyle get defaultMeasurementsLabelStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF718096),
        fontWeight: FontWeight.w500,
      );

  TextStyle get defaultRangeTextStyle => const TextStyle(
        fontSize: 12,
        color: Color(0xFF4A5568),
        fontWeight: FontWeight.w500,
      );

  // Getter methods for text styles with fallbacks
  TextStyle get effectiveLabelStyle => labelStyle ?? defaultLabelStyle;

  TextStyle get effectiveHeaderStyle => headerStyle ?? defaultHeaderStyle;

  TextStyle get effectiveSubHeaderStyle =>
      subHeaderStyle ?? defaultSubHeaderStyle;

  TextStyle get effectiveTooltipTextStyle =>
      tooltipTextStyle ?? defaultTooltipTextStyle;

  TextStyle get effectiveGridLabelStyle =>
      gridLabelStyle ?? defaultGridLabelStyle;

  TextStyle get effectiveEmptyStateStyle =>
      emptyStateStyle ?? defaultEmptyStateStyle;

  TextStyle get effectiveValueLabelStyle =>
      valueLabelStyle ?? defaultValueLabelStyle;

  TextStyle get effectiveDateLabelStyle =>
      dateLabelStyle ?? defaultDateLabelStyle;

  TextStyle get effectiveCountLabelStyle =>
      countLabelStyle ?? defaultCountLabelStyle;

  TextStyle get effectiveStatisticsLabelStyle =>
      statisticsLabelStyle ?? defaultStatisticsLabelStyle;

  TextStyle get effectiveMeasurementsLabelStyle =>
      measurementsLabelStyle ?? defaultMeasurementsLabelStyle;

  TextStyle get effectiveRangeTextStyle =>
      rangeTextStyle ?? defaultRangeTextStyle;

  // Copy with constructor for easy customization
  O2SaturationChartStyle copyWith({
    Color? primaryColor,
    Color? pulseRateColor,
    Color? backgroundColor,
    Color? gridLineColor,
    Color? selectedHighlightColor,
    Color? normalRangeColor,
    Color? mildRangeColor,
    Color? moderateRangeColor,
    Color? severeRangeColor,
    Color? criticalRangeColor,
    double? pointRadius,
    double? lineThickness,
    TextStyle? labelStyle,
    TextStyle? headerStyle,
    TextStyle? subHeaderStyle,
    TextStyle? tooltipTextStyle,
    TextStyle? gridLabelStyle,
    TextStyle? emptyStateStyle,
    TextStyle? valueLabelStyle,
    TextStyle? dateLabelStyle,
    TextStyle? countLabelStyle,
    TextStyle? statisticsLabelStyle,
    TextStyle? measurementsLabelStyle,
    TextStyle? rangeTextStyle,
    BorderRadius? tooltipBorderRadius,
    List<BoxShadow>? tooltipShadow,
    String? o2SaturationLabel,
    String? pulseRateLabel,
    String? measurementsLabel,
    String? summaryLabel,
    String? averageLabel,
    String? rangeLabel,
    String? statisticsLabel,
    String? readingsLabel,
    String? standardDeviationLabel,
    String? todayLabel,
    String? yesterdayLabel,
    String? thisWeekLabel,
    String? lastWeekLabel,
    String? thisMonthLabel,
    String? lastMonthLabel,
    String? noDataLabel,
    String? normalRangeLabel,
    String? mildRangeLabel,
    String? moderateRangeLabel,
    String? severeRangeLabel,
    String? criticalRangeLabel,
    String? percentLabel,
    String? bpmLabel,
  }) {
    return O2SaturationChartStyle(
      primaryColor: primaryColor ?? this.primaryColor,
      pulseRateColor: pulseRateColor ?? this.pulseRateColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      selectedHighlightColor:
          selectedHighlightColor ?? this.selectedHighlightColor,
      normalRangeColor: normalRangeColor ?? this.normalRangeColor,
      mildRangeColor: mildRangeColor ?? this.mildRangeColor,
      moderateRangeColor: moderateRangeColor ?? this.moderateRangeColor,
      severeRangeColor: severeRangeColor ?? this.severeRangeColor,
      criticalRangeColor: criticalRangeColor ?? this.criticalRangeColor,
      pointRadius: pointRadius ?? this.pointRadius,
      lineThickness: lineThickness ?? this.lineThickness,
      labelStyle: labelStyle ?? this.labelStyle,
      headerStyle: headerStyle ?? this.headerStyle,
      subHeaderStyle: subHeaderStyle ?? this.subHeaderStyle,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      gridLabelStyle: gridLabelStyle ?? this.gridLabelStyle,
      emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
      valueLabelStyle: valueLabelStyle ?? this.valueLabelStyle,
      dateLabelStyle: dateLabelStyle ?? this.dateLabelStyle,
      countLabelStyle: countLabelStyle ?? this.countLabelStyle,
      statisticsLabelStyle: statisticsLabelStyle ?? this.statisticsLabelStyle,
      measurementsLabelStyle:
          measurementsLabelStyle ?? this.measurementsLabelStyle,
      rangeTextStyle: rangeTextStyle ?? this.rangeTextStyle,
      tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
      tooltipShadow: tooltipShadow ?? this.tooltipShadow,
      o2SaturationLabel: o2SaturationLabel ?? this.o2SaturationLabel,
      pulseRateLabel: pulseRateLabel ?? this.pulseRateLabel,
      measurementsLabel: measurementsLabel ?? this.measurementsLabel,
      summaryLabel: summaryLabel ?? this.summaryLabel,
      averageLabel: averageLabel ?? this.averageLabel,
      rangeLabel: rangeLabel ?? this.rangeLabel,
      statisticsLabel: statisticsLabel ?? this.statisticsLabel,
      readingsLabel: readingsLabel ?? this.readingsLabel,
      standardDeviationLabel:
          standardDeviationLabel ?? this.standardDeviationLabel,
      todayLabel: todayLabel ?? this.todayLabel,
      yesterdayLabel: yesterdayLabel ?? this.yesterdayLabel,
      thisWeekLabel: thisWeekLabel ?? this.thisWeekLabel,
      lastWeekLabel: lastWeekLabel ?? this.lastWeekLabel,
      thisMonthLabel: thisMonthLabel ?? this.thisMonthLabel,
      lastMonthLabel: lastMonthLabel ?? this.lastMonthLabel,
      noDataLabel: noDataLabel ?? this.noDataLabel,
      normalRangeLabel: normalRangeLabel ?? this.normalRangeLabel,
      mildRangeLabel: mildRangeLabel ?? this.mildRangeLabel,
      moderateRangeLabel: moderateRangeLabel ?? this.moderateRangeLabel,
      severeRangeLabel: severeRangeLabel ?? this.severeRangeLabel,
      criticalRangeLabel: criticalRangeLabel ?? this.criticalRangeLabel,
      percentLabel: percentLabel ?? this.percentLabel,
      bpmLabel: bpmLabel ?? this.bpmLabel,
    );
  }
}
