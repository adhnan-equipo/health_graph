// lib/blood_pressure/widgets/chart/chart_legend.dart
import 'package:flutter/material.dart';

import '../../styles/blood_pressure_chart_style.dart';

class ChartLegend extends StatelessWidget {
  final BloodPressureChartStyle style;

  const ChartLegend({
    Key? key,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: style.systolicColor,
          label: 'Systolic',
          style: style,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: style.diastolicColor,
          label: 'Diastolic',
          style: style,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final BloodPressureChartStyle style;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.label,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: style.gridLabelStyle ?? style.subHeaderStyle,
        ),
      ],
    );
  }
}
