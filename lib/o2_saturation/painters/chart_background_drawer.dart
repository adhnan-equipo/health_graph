import 'package:flutter/material.dart';

// O2ChartBackgroundDrawer
class O2ChartBackgroundDrawer {
  void drawBackground(Canvas canvas, Rect chartArea) {
    canvas.drawRect(chartArea, Paint()..color = Colors.transparent);
  }
}
