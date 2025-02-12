import 'package:flutter/material.dart';

class ChartGridDrawer {
  final Paint _gridPaint = Paint()
    ..color = Colors.grey.withOpacity(0.2)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  void drawGrid(Canvas canvas, Rect chartArea, List<int> yAxisValues,
      double minValue, double maxValue) {
    for (var value in yAxisValues) {
      final y = chartArea.bottom -
          ((value - minValue) / (maxValue - minValue)) * chartArea.height;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        _gridPaint,
      );
    }
  }
}
