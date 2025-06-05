// This file is deprecated - use shared/drawers/chart_grid_drawer.dart instead
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../shared/drawers/chart_grid_drawer.dart' as shared;
import '../../shared/utils/chart_calculations.dart';

class StepGridDrawer {
  final shared.ChartGridDrawer _sharedDrawer = shared.ChartGridDrawer();

  void drawGrid(
    Canvas canvas,
    Rect chartArea,
    List<int> yAxisValues,
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    _sharedDrawer.drawIntegerGrid(
        canvas, chartArea, yAxisValues, minValue, maxValue, animationValue);
  }

  // Delegated to shared calculations
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    return SharedChartCalculations.calculateXPosition(
        index, totalPoints, chartArea);
  }
}
