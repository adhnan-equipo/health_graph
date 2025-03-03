// import 'package:flutter/animation.dart';
//
// import '../models/tooltip_position.dart';
//
// class TooltipPositionCalculator {
//   static TooltipPosition calculatePosition({
//     required Offset tapPosition,
//     required Size screenSize,
//     required Size tooltipSize,
//     double padding = 12.0,
//   }) {
//     const arrowSize = 8.0;
//
//     // Initial position calculation
//     double left = tapPosition.dx - (tooltipSize.width / 2);
//     double top = tapPosition.dy + arrowSize;
//     bool showAbove = false;
//
//     // Check horizontal bounds
//     if (left < padding) {
//       left = padding;
//     } else if (left + tooltipSize.width > screenSize.width - padding) {
//       left = screenSize.width - tooltipSize.width - padding;
//     }
//
//     // Check vertical bounds
//     if (top + tooltipSize.height > screenSize.height - padding) {
//       // Show above the tap point if not enough space below
//       top = tapPosition.dy - tooltipSize.height - arrowSize;
//       showAbove = true;
//     }
//
//     // Ensure tooltip stays within vertical bounds
//     if (top < padding) {
//       top = padding;
//     } else if (top + tooltipSize.height > screenSize.height - padding) {
//       top = screenSize.height - tooltipSize.height - padding;
//     }
//
//     return TooltipPosition(
//       left: left,
//       top: top,
//       showAbove: showAbove,
//     );
//   }
// }
