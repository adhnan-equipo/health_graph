// // Updated ChartDataPointDrawer with improved plotting
// import 'dart:math';
//
// import 'package:flutter/material.dart';
//
// import '../models/processed_blood_pressure_data.dart';
// import '../services/chart_calculations.dart';
// import '../styles/blood_pressure_chart_style.dart';
//
// class ChartDataPointDrawer {
//   // Reuse paint objects for better performance
//   final Paint _dataPointPaint = Paint()..strokeCap = StrokeCap.round;
//   final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
//   final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
//   int? _lastSelectedIndex;
//   // Cache for performance optimization
//   final Map<int, Offset> _pointPositionCache = {};
//   String _lastDataHash = '';
//   Path? _systolicPath;
//   Path? _diastolicPath;
//
//   // Optimization: Remember last drawn parameters to avoid unnecessary work
//   int? _previousSelectedIndex;
//   double? _previousAnimationValue;
//
//   // Offscreen testing for clipping optimization
//   bool _isPointVisible(double x, Rect chartArea, double buffer) {
//     return x >= chartArea.left - buffer && x <= chartArea.right + buffer;
//   }
//
//   void drawDataPoints(
//     Canvas canvas,
//     Rect chartArea,
//     List<ProcessedBloodPressureData> data,
//     BloodPressureChartStyle style,
//     Animation<double> animation,
//     ProcessedBloodPressureData? selectedData,
//     double minValue,
//     double maxValue,
//   ) {
//     if (data.isEmpty) return;
//
//     // Find selected index more efficiently
//     int? selectedIndex;
//     if (selectedData != null) {
//       for (int i = 0; i < data.length; i++) {
//         final entry = data[i];
//         if (entry.startDate == selectedData.startDate &&
//             entry.endDate == selectedData.endDate) {
//           selectedIndex = i;
//           break;
//         }
//       }
//     }
//
//     // Check if we only need to update the selection highlight
//     final selectionOnly =
//         _previousSelectedIndex != selectedIndex &&
//         animation.value > 0.9 && // Animation is mostly done
//         _previousAnimationValue != null &&
//         (animation.value - _previousAnimationValue!).abs() < 0.1; // Animation hasn't changed much
//
//     // Determine if paths need rebuilding (only when data changes significantly)
//     final currentHash = '${data.length}_${data.isNotEmpty ? data.first.hashCode : 0}';
//     final needsPathRebuild = currentHash != _lastDataHash;
//
//     if (needsPathRebuild) {
//       _lastDataHash = currentHash;
//       _buildPaths(chartArea, data, minValue, maxValue);
//     }
//
//     // Track state for next frame
//     _previousSelectedIndex = selectedIndex;
//     _previousAnimationValue = animation.value;
//
//     // Draw trend lines first (they're in the background)
//     _drawTrendLines(canvas, chartArea, data, style, animation, minValue, maxValue);
//
//     // Only draw selection highlight if needed
//     if (selectedIndex != null && selectedIndex >= 0) {
//       final x = ChartCalculations.calculateXPosition(
//           selectedIndex, data.length, chartArea);
//       _drawYAxisHighlight(canvas, x, chartArea, style, animation.value);
//     }
//
//     // Skip point drawing if we're just updating selection and animation is complete
//     if (selectionOnly && animation.value >= 1.0) {
//       // Just draw the selected point(s) for efficiency
//       if (selectedIndex != null && selectedIndex >= 0) {
//         final entry = data[selectedIndex];
//         if (!entry.isEmpty) {
//           final x = ChartCalculations.calculateXPosition(selectedIndex, data.length, chartArea);
//           final positions = _calculateDataPointPositions(
//             entry, x, chartArea, minValue, maxValue);
//
//           if (entry.dataPointCount == 1) {
//             _drawSinglePoint(canvas, positions, style, 1.0, true);
//           } else {
//             _drawRangePoint(canvas, positions, style, 1.0, true);
//           }
//         }
//       }
//       return;
//     }
//
//     // Determine visible range to avoid drawing offscreen points
//     final pointWidth = chartArea.width / max(1, data.length - 1);
//     final buffer = pointWidth * 2; // Extra buffer for large points
//
//     // Draw visible data points with potential clipping optimization
//     for (var i = 0; i < data.length; i++) {
//       final entry = data[i];
//       if (entry.isEmpty) continue;
//
//       final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);
//
//       // Skip points that are definitely not visible
//       if (!_isPointVisible(x, chartArea, buffer)) continue;
//
//       final positions = _calculateDataPointPositions(
//         entry, x, chartArea, minValue, maxValue,
//       );
//
//       final isSelected = selectedIndex == i;
//       final animationValue = _calculateAnimationValue(i, data.length, animation);
//
//       // Draw the point based on type
//       if (entry.dataPointCount == 1) {
//         _drawSinglePoint(canvas, positions, style, animationValue, isSelected);
//       } else {
//         _drawRangePoint(canvas, positions, style, animationValue, isSelected);
//       }
//     }
//   }
//
//   // Enhanced method to highlight the entire y-axis
//   // Pre-calculated values for highlight effects
//   Color? _cachedHighlightColor;
//   Shader? _cachedGradientShader;
//   double _lastAnimationValue = -1;
//   late Rect _lastGradientRect;
//
//   void _drawYAxisHighlight(
//     Canvas canvas,
//     double x,
//     Rect chartArea,
//     BloodPressureChartStyle style,
//     double animationValue,
//   ) {
//     // Simplified pulsing effect with less computation
//     final pulseValue = 0.85 + 0.15 * sin(animationValue * 4);
//
//     // Draw main vertical line first (most important visual)
//     _linePaint
//       ..color = style.selectedHighlightColor.withOpacity(0.7 * pulseValue)
//       ..strokeWidth = 2.5;
//
//     canvas.drawLine(
//       Offset(x, chartArea.top),
//       Offset(x, chartArea.bottom),
//       _linePaint,
//     );
//
//     // Only add glow effect if not in low-quality mode (helps performance)
//     if (true) { // Can be replaced with a quality flag if needed
//       // Add glow effect more efficiently
//       _fillPaint
//         ..color = style.selectedHighlightColor.withOpacity(0.3)
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
//
//       final highlightRect = Rect.fromLTRB(x - 1, chartArea.top, x + 1, chartArea.bottom);
//       canvas.drawRect(highlightRect, _fillPaint);
//       _fillPaint.maskFilter = null;
//
//       // Optimize gradient creation - only recreate if necessary
//       final gradientRect = Rect.fromLTRB(
//         x - 25, chartArea.top, x + 25, chartArea.bottom,
//       );
//
//       // Check if we need to regenerate the gradient
//       final needsNewGradient =
//           _cachedGradientShader == null ||
//           _lastGradientRect != gradientRect ||
//           (_lastAnimationValue - animationValue).abs() > 0.1;
//
//       if (needsNewGradient) {
//         _lastGradientRect = gradientRect;
//         _lastAnimationValue = animationValue;
//
//         final gradient = LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [
//             style.selectedHighlightColor.withOpacity(0),
//             style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
//             style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
//             style.selectedHighlightColor.withOpacity(0),
//           ],
//           stops: const [0.0, 0.3, 0.7, 1.0],
//         );
//
//         _cachedGradientShader = gradient.createShader(gradientRect);
//       }
//
//       _fillPaint
//         ..shader = _cachedGradientShader
//         ..style = PaintingStyle.fill;
//
//       canvas.drawRect(gradientRect, _fillPaint);
//       _fillPaint.shader = null;
//
//       // Optimize dot drawing - reduce number of dots for better performance
//       _fillPaint
//         ..color = style.selectedHighlightColor.withOpacity(0.7 * pulseValue)
//         ..style = PaintingStyle.fill;
//
//       // Use fewer dots on the axis for better performance
//       final numDots = 4; // Reduced from 8
//       final dotSpacing = chartArea.height / (numDots + 1);
//
//       for (int i = 1; i <= numDots; i++) {
//         final y = chartArea.top + (dotSpacing * i);
//         final dotSize = 2.0; // Fixed size for better performance
//         canvas.drawCircle(Offset(x, y), dotSize, _fillPaint);
//       }
//     }
//   }
//
//   // Optimize path building for trend lines
//   void _buildPaths(
//     Rect chartArea,
//     List<ProcessedBloodPressureData> data,
//     double minValue,
//     double maxValue,
//   ) {
//     _systolicPath = Path();
//     _diastolicPath = Path();
//
//     bool isFirstValid = true;
//
//     for (var i = 0; i < data.length; i++) {
//       final entry = data[i];
//       if (entry.isEmpty) continue;
//
//       final x = ChartCalculations.calculateXPosition(i, data.length, chartArea);
//
//       final systolicY = _getYPosition(
//         entry.avgSystolic,
//         chartArea,
//         minValue,
//         maxValue,
//       );
//
//       final diastolicY = _getYPosition(
//         entry.avgDiastolic,
//         chartArea,
//         minValue,
//         maxValue,
//       );
//
//       if (isFirstValid) {
//         _systolicPath!.moveTo(x, systolicY);
//         _diastolicPath!.moveTo(x, diastolicY);
//         isFirstValid = false;
//       } else {
//         _systolicPath!.lineTo(x, systolicY);
//         _diastolicPath!.lineTo(x, diastolicY);
//       }
//     }
//   }
//
//   void _drawTrendLines(
//     Canvas canvas,
//     Rect chartArea,
//     List<ProcessedBloodPressureData> data,
//     BloodPressureChartStyle style,
//     Animation<double> animation,
//     double minValue,
//     double maxValue,
//   ) {
//     if (_systolicPath == null || _diastolicPath == null) return;
//
//     // Draw systolic trend line with animation
//     _linePaint
//       ..color = style.systolicColor.withOpacity(0.3 * animation.value)
//       ..strokeWidth = 1.5;
//     canvas.drawPath(_systolicPath!, _linePaint);
//
//     // Draw diastolic trend line with animation
//     _linePaint
//       ..color = style.diastolicColor.withOpacity(0.3 * animation.value)
//       ..strokeWidth = 1.5;
//     canvas.drawPath(_diastolicPath!, _linePaint);
//   }
//
//   void _drawSinglePoint(
//     Canvas canvas,
//     ({
//       Offset maxSystolicPoint,
//       Offset minSystolicPoint,
//       Offset maxDiastolicPoint,
//       Offset minDiastolicPoint
//     }) positions,
//     BloodPressureChartStyle style,
//     double animationValue,
//     bool isSelected,
//   ) {
//     // Draw connecting line with increased opacity for selected points
//     if (isSelected) {
//       _linePaint
//         ..color = style.connectorColor.withOpacity(0.6 * animationValue)
//         ..strokeWidth = style.lineThickness;
//       canvas.drawLine(
//           positions.maxSystolicPoint, positions.maxDiastolicPoint, _linePaint);
//     }
//
//     // Draw points with enhanced visibility for selected state
//     _drawAnimatedPoint(
//       canvas,
//       positions.maxSystolicPoint,
//       style.systolicColor,
//       style.pointRadius * (isSelected ? 1.3 : 1.0),
//       animationValue,
//       isSelected,
//       style,
//     );
//
//     _drawAnimatedPoint(
//       canvas,
//       positions.maxDiastolicPoint,
//       style.diastolicColor,
//       style.pointRadius * (isSelected ? 1.3 : 1.0),
//       animationValue,
//       isSelected,
//       style,
//     );
//   }
//
//   void _drawRangePoint(
//     Canvas canvas,
//     ({
//       Offset maxSystolicPoint,
//       Offset minSystolicPoint,
//       Offset maxDiastolicPoint,
//       Offset minDiastolicPoint
//     }) positions,
//     BloodPressureChartStyle style,
//     double animationValue,
//     bool isSelected,
//   ) {
//     final rangeWidth = style.lineThickness * (isSelected ? 3.5 : 3.0);
//
//     // Draw systolic range with animation
//     _drawAnimatedRangeLine(
//       canvas,
//       positions.maxSystolicPoint,
//       positions.minSystolicPoint,
//       style.systolicColor,
//       rangeWidth,
//       animationValue,
//       isSelected,
//       style,
//     );
//
//     // Draw diastolic range with animation
//     _drawAnimatedRangeLine(
//       canvas,
//       positions.maxDiastolicPoint,
//       positions.minDiastolicPoint,
//       style.diastolicColor,
//       rangeWidth,
//       animationValue,
//       isSelected,
//       style,
//     );
//   }
//
//   void _drawAnimatedRangeLine(
//     Canvas canvas,
//     Offset start,
//     Offset end,
//     Color color,
//     double width,
//     double animationValue,
//     bool isSelected,
//     BloodPressureChartStyle style,
//   ) {
//     // Animate line drawing from center
//     final center = Offset(
//       (start.dx + end.dx) / 2,
//       (start.dy + end.dy) / 2,
//     );
//
//     final animatedStart = Offset.lerp(center, start, animationValue)!;
//     final animatedEnd = Offset.lerp(center, end, animationValue)!;
//
//     // Draw outer line
//     _linePaint
//       ..color = color.withOpacity(isSelected ? 0.8 : 0.4)
//       ..strokeWidth = width;
//     canvas.drawLine(animatedStart, animatedEnd, _linePaint);
//
//     // Draw inner line for hollow effect
//     if (!isSelected) {
//       _linePaint
//         ..color = color.withOpacity(0.6)
//         ..strokeWidth = width * 0.6;
//       canvas.drawLine(animatedStart, animatedEnd, _linePaint);
//     }
//
//     // Draw end caps with animation
//     _drawAnimatedPoint(
//       canvas,
//       animatedStart,
//       color,
//       width / 2,
//       animationValue,
//       isSelected,
//       style,
//     );
//     _drawAnimatedPoint(
//       canvas,
//       animatedEnd,
//       color,
//       width / 2,
//       animationValue,
//       isSelected,
//       style,
//     );
//   }
//
//   // Cache for colors to reduce object creation
//   final Map<Color, Map<double, Color>> _colorOpacityCache = {};
//
//   // Get color with opacity, using cache when possible
//   Color _getColorWithOpacity(Color baseColor, double opacity) {
//     final colorCache = _colorOpacityCache.putIfAbsent(baseColor, () => {});
//     return colorCache.putIfAbsent(
//       opacity.roundToDouble() / 10, // Round to reduce cache size
//       () => baseColor.withOpacity(opacity)
//     );
//   }
//
//   void _drawAnimatedPoint(
//     Canvas canvas,
//     Offset position,
//     Color color,
//     double radius,
//     double animationValue,
//     bool isSelected,
//     BloodPressureChartStyle style,
//   ) {
//     // Skip invisible points
//     if (animationValue <= 0.01) return;
//
//     // Optimize for fully animated points
//     final isFullyAnimated = animationValue >= 0.99;
//
//     // Enhanced radius for selected points with reduced calculation
//     final baseRadius = isSelected ? radius * 1.3 : radius;
//     final animatedRadius = isFullyAnimated ? baseRadius : baseRadius * animationValue;
//
//     // Only draw glow for selected points and only when needed
//     if (isSelected) {
//       // Skip the blur effect when animating for better performance
//       final skipGlow = !isFullyAnimated && animationValue < 0.7;
//
//       if (!skipGlow) {
//         _fillPaint
//           ..color = _getColorWithOpacity(color, 0.3)
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
//
//         canvas.drawCircle(position, animatedRadius * 1.8, _fillPaint);
//         _fillPaint.maskFilter = null;
//       }
//     }
//
//     // Draw outer circle - reuse paint objects
//     _dataPointPaint
//       ..color = _getColorWithOpacity(color, isFullyAnimated ? 0.9 : 0.9 * animationValue)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = isSelected ? 2.5 : 1.8;
//     canvas.drawCircle(position, animatedRadius, _dataPointPaint);
//
//     // Fill circle with appropriate opacity
//     _dataPointPaint
//       ..style = PaintingStyle.fill
//       ..color = _getColorWithOpacity(
//           color,
//           isSelected ?
//             (isFullyAnimated ? 0.8 : 0.8 * animationValue) :
//             (isFullyAnimated ? 0.5 : 0.5 * animationValue)
//       );
//
//     canvas.drawCircle(
//         position,
//         animatedRadius - (isSelected ? 1.0 : 1.5),
//         _dataPointPaint
//     );
//   }
//
//   // Improved animation calculation for smoother transitions
//   double _calculateAnimationValue(
//       int index, int totalPoints, Animation<double> animation) {
//     // Progressive animation with smoother timing function
//     final delay = index / (totalPoints * 1.5);
//     final duration = 1.2 / totalPoints;
//
//     if (animation.value < delay) return 0.0;
//     if (animation.value > delay + duration) return 1.0;
//
//     // Ease-out cubic for smoother finish
//     final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
//     return 1.0 - pow(1.0 - t, 3) as double;
//   }
//
//   // Helper method for position calculation
//   ({
//     Offset maxSystolicPoint,
//     Offset minSystolicPoint,
//     Offset maxDiastolicPoint,
//     Offset minDiastolicPoint
//   }) _calculateDataPointPositions(
//     ProcessedBloodPressureData entry,
//     double x,
//     Rect chartArea,
//     double minValue,
//     double maxValue,
//   ) {
//     return (
//       maxSystolicPoint: Offset(
//         x,
//         _getYPosition(
//             entry.maxSystolic.toDouble(), chartArea, minValue, maxValue),
//       ),
//       minSystolicPoint: Offset(
//         x,
//         _getYPosition(
//             entry.minSystolic.toDouble(), chartArea, minValue, maxValue),
//       ),
//       maxDiastolicPoint: Offset(
//         x,
//         _getYPosition(
//             entry.maxDiastolic.toDouble(), chartArea, minValue, maxValue),
//       ),
//       minDiastolicPoint: Offset(
//         x,
//         _getYPosition(
//             entry.minDiastolic.toDouble(), chartArea, minValue, maxValue),
//       ),
//     );
//   }
//
//   double _getYPosition(
//     double value,
//     Rect chartArea,
//     double minValue,
//     double maxValue,
//   ) {
//     return chartArea.bottom -
//         ((value - minValue) / (maxValue - minValue)) * chartArea.height;
//   }
// }
