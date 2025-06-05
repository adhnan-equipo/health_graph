import 'package:flutter/material.dart';

/// Shared chart background drawer for all health metric charts
/// Provides consistent background drawing across all chart types
class ChartBackgroundDrawer {
  /// Draws a transparent background for the chart area
  void drawBackground(Canvas canvas, Rect chartArea) {
    canvas.drawRect(chartArea, Paint()..color = Colors.transparent);
  }
}
