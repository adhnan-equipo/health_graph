// // lib/bmi/drawer/chart_reference_range_drawer.dart
// import 'package:flutter/material.dart';
//
// class ChartReferenceRangeDrawer {
//   final TextPainter _textPainter = TextPainter(
//     textDirection: TextDirection.ltr,
//     textAlign: TextAlign.center,
//   );
//
//   void drawReferenceRanges(
//     Canvas canvas,
//     Rect chartArea,
//     Color rangeColor,
//     double minValue,
//     double maxValue,
//     double animationValue,
//     Map<String, List<double>> ranges,
//     TextStyle labelStyle,
//   ) {
//     final rangePaint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = rangeColor.withValues(alpha: 0.1 * animationValue);
//
//     ranges.forEach((label, range) {
//       if (range.length != 2) return;
//
//       final rangeRect = _calculateRangeRect(
//         chartArea,
//         range[0],
//         range[1],
//         minValue,
//         maxValue,
//       );
//
//       _drawAnimatedRange(canvas, rangeRect, rangePaint, animationValue);
//       _drawRangeLabel(
//         canvas,
//         rangeRect,
//         label,
//         labelStyle,
//         animationValue,
//       );
//     });
//   }
//
//   Rect _calculateRangeRect(
//     Rect chartArea,
//     double minValue,
//     double maxValue,
//     double chartMinValue,
//     double chartMaxValue,
//   ) {
//     final minY =
//         _getYPosition(maxValue, chartArea, chartMinValue, chartMaxValue);
//     final maxY =
//         _getYPosition(minValue, chartArea, chartMinValue, chartMaxValue);
//
//     return Rect.fromLTRB(
//       chartArea.left,
//       minY,
//       chartArea.right,
//       maxY,
//     );
//   }
//
//   void _drawRangeLabel(
//     Canvas canvas,
//     Rect rangeRect,
//     String text,
//     TextStyle style,
//     double animationValue,
//   ) {
//     _textPainter
//       ..text = TextSpan(
//         text: text,
//         style: style.copyWith(
//           color: style.color?.withValues(alpha: animationValue),
//         ),
//       )
//       ..layout();
//
//     final centerY = rangeRect.center.dy - (_textPainter.height / 2);
//
//     // Draw background for better readability
//     final labelBackground = Rect.fromLTWH(
//       rangeRect.left + 10,
//       centerY,
//       _textPainter.width + 20,
//       _textPainter.height,
//     );
//
//     canvas.drawRect(
//       labelBackground,
//       Paint()..color = Colors.white.withValues(alpha: 0.8 * animationValue),
//     );
//
//     _textPainter.paint(
//       canvas,
//       Offset(rangeRect.left + 20, centerY),
//     );
//   }
//
//   void _drawAnimatedRange(
//     Canvas canvas,
//     Rect rect,
//     Paint paint,
//     double animationValue,
//   ) {
//     final center = rect.center;
//     final animatedRect = Rect.fromCenter(
//       center: center,
//       width: rect.width * animationValue,
//       height: rect.height,
//     );
//     canvas.drawRect(animatedRect, paint);
//   }
//
//   double _getYPosition(
//       double value, Rect chartArea, double minValue, double maxValue) {
//     return chartArea.bottom -
//         ((value - minValue) / (maxValue - minValue)) * chartArea.height;
//   }
// }
