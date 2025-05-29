// lib/steps/drawer/step_background_drawer.dart
import 'package:flutter/material.dart';

class StepBackgroundDrawer {
  void drawBackground(Canvas canvas, Rect chartArea) {
    canvas.drawRect(chartArea, Paint()..color = Colors.transparent);
  }
}
