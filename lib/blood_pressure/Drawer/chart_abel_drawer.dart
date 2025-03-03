// import 'dart:ui';
//
// import 'package:flutter/material.dart';
//
// import '/blood_pressure/styles/blood_pressure_chart_style.dart';
// import '../../models/date_range_type.dart';
// import '../../utils/date_formatter.dart';
// import '../models/processed_blood_pressure_data.dart';
// import '../services/chart_calculations.dart';
//
// class ChartLabelDrawer {
//   final TextPainter _textPainter = TextPainter(
//     textDirection: TextDirection.ltr,
//     textAlign: TextAlign.right,
//   );
//
//   void drawSideLabels(
//     Canvas canvas,
//     Rect chartArea,
//     List<int> yAxisValues,
//     TextStyle textStyle,
//     double animationValue,
//   ) {
//     for (var value in yAxisValues) {
//       final y = chartArea.bottom -
//           ((value - yAxisValues.first) /
//                   (yAxisValues.last - yAxisValues.first)) *
//               chartArea.height;
//
//       _textPainter
//         ..text = TextSpan(
//           text: value.toString(),
//           style: textStyle.copyWith(
//             color: textStyle.color?.withOpacity(animationValue),
//           ),
//         )
//         ..layout();
//
//       // Calculate position with animation
//       final xOffset = chartArea.left - _textPainter.width - 8;
//       final animatedXOffset = Offset(
//         lerpDouble(chartArea.left, xOffset, animationValue)!,
//         y - _textPainter.height / 2,
//       );
//
//       _textPainter.paint(canvas, animatedXOffset);
//     }
//   }
//
//   void drawBottomLabels(
//     Canvas canvas,
//     Rect chartArea,
//     List<ProcessedBloodPressureData> data,
//     DateRangeType viewType,
//     BloodPressureChartStyle style,
//     double animationValue,
//   ) {
//     if (data.isEmpty) return;
//
//     final labelStep = _calculateLabelStep(data.length, viewType);
//     final textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.center,
//     );
//
//     for (var i = 0; i < data.length; i++) {
//       if (i % labelStep != 0) continue;
//
//       final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);
//       final label = DateFormatter.format(data[i].startDate, viewType);
//
//       textPainter
//         ..text = TextSpan(
//           text: label,
//           style: style.dateLabelStyle?.copyWith(
//             color: style.dateLabelStyle?.color?.withOpacity(animationValue),
//           ),
//         )
//         ..layout();
//
//       // Position labels with proper spacing
//       textPainter.paint(
//         canvas,
//         Offset(
//           x - (textPainter.width / 2),
//           chartArea.bottom + 8, // Increased spacing from chart area
//         ),
//       );
//     }
//   }
//
//   int _calculateLabelStep(int dataLength, DateRangeType viewType) {
//     switch (viewType) {
//       case DateRangeType.day:
//         return (dataLength / 6).round().clamp(1, dataLength);
//       case DateRangeType.week:
//         return 1;
//       case DateRangeType.month:
//         if (dataLength <= 10) return 1;
//         return (dataLength / 8).round().clamp(1, 5);
//       case DateRangeType.year:
//         return 1;
//     }
//   }
// }
