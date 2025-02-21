import 'package:flutter/material.dart';

class ChartAnimationConfig {
  static const defaultConfig = ChartAnimationConfig(
    dataPointDuration: Duration(milliseconds: 800),
    gridDuration: Duration(milliseconds: 500),
    labelDuration: Duration(milliseconds: 600),
    dataPointCurve: Curves.elasticOut,
    gridCurve: Curves.easeInOutCubic,
    labelCurve: Curves.easeOutCubic,
  );

  final Duration dataPointDuration;
  final Duration gridDuration;
  final Duration labelDuration;
  final Curve dataPointCurve;
  final Curve gridCurve;
  final Curve labelCurve;

  const ChartAnimationConfig({
    required this.dataPointDuration,
    required this.gridDuration,
    required this.labelDuration,
    required this.dataPointCurve,
    required this.gridCurve,
    required this.labelCurve,
  });
}
