import 'package:flutter/material.dart';

class ChartBackgroundDrawer {
  void drawBackground(Canvas canvas, Rect chartArea) {
    canvas.drawRect(
      chartArea,
      Paint()..color = Colors.transparent,
    );
  }
}
