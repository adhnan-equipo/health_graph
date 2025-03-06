import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/date_formatter.dart';
import '../models/heart_rate_range.dart';
import '../models/processed_heart_rate_data.dart';
import '../styles/heart_rate_chart_style.dart';

class HeartRateChartPainter extends CustomPainter {
  final List<ProcessedHeartRateData> data;
  final HeartRateChartStyle style;
  final Animation<double> animation;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;
  final bool showGrid;
  final bool showRanges;
  final DateRangeType viewType;
  final ProcessedHeartRateData? selectedData;

  // Reusable objects for better performance
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _pointPaint = Paint();

  // Cache for performance optimization
  String _lastDataHash = '';
  String _lastAnimationHash = '';
  Path? _heartRatePath;
  Path? _restingRatePath;
  Path? _maxRatePath;
  Path? _minRatePath;

  HeartRateChartPainter({
    required this.data,
    required this.style,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
    this.showGrid = true,
    this.showRanges = true,
    required this.viewType,
    this.selectedData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Create a try-catch block to handle any rendering errors
    try {
      canvas.save();
      canvas.clipRect(chartArea);

      // Draw background
      _drawBackground(canvas);

      // Draw ranges if enabled
      if (showRanges) {
        _drawReferenceRanges(canvas);
      }

      // Draw grid if enabled
      if (showGrid) {
        _drawGrid(canvas);
      }

      canvas.restore();

      // Draw axis labels
      _drawAxisLabels(canvas);

      canvas.save();
      canvas.clipRect(chartArea);

      // Draw heart rate lines and points
      _drawHeartRateData(canvas);

      canvas.restore();
    } catch (e) {
      // Log error and draw fallback
      _logRenderingError(e);
      _drawErrorState(canvas, size);
    }
  }

// New method to log errors
  void _logRenderingError(dynamic error) {
    // In production, we'd use a proper logging system
    // For now, print to console in debug mode
    print('Heart rate chart rendering error: $error');
  }

  void _drawHeartRateData(Canvas canvas) {
    if (data.isEmpty) return;

    // Separate data hash from animation hash for better caching
    final currentDataHash = '${data.length}_${data.first.hashCode}';
    final currentAnimationHash = animation.value.toStringAsFixed(2);

    // Only rebuild paths if data changed, not just animation
    if (_lastDataHash != currentDataHash) {
      _buildPaths();
      _lastDataHash = currentDataHash;
      _lastAnimationHash = currentAnimationHash;
    } else if (_heartRatePath == null) {
      // Rebuild if paths are null for some reason
      _buildPaths();
      _lastAnimationHash = currentAnimationHash;
    }

    // Skip if paths couldn't be built properly
    if (_heartRatePath == null) return;

    // Draw range area (shaded area between min and max)
    _drawRangeArea(canvas);

    // Draw resting heart rate line if exists
    if (_restingRatePath != null) {
      _linePaint
        ..color =
            style.restingRateColor.withValues(alpha: 0.6 * animation.value)
        ..strokeWidth = style.lineThickness - 0.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(_restingRatePath!, _linePaint);
    }

    // Draw main heart rate line
    _linePaint
      ..color = style.primaryColor.withValues(alpha: 0.8 * animation.value)
      ..strokeWidth = style.lineThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(_heartRatePath!, _linePaint);

    // Draw data points - limit for performance
    _drawDataPoints(canvas);
  }

  void _drawBackground(Canvas canvas) {
    // Apply a subtle gradient background to the chart area
    final backgroundGradient = ui.Gradient.linear(
      Offset(chartArea.left, chartArea.top),
      Offset(chartArea.left, chartArea.bottom),
      [
        style.backgroundColor.withValues(alpha: 0.1 * animation.value),
        style.backgroundColor.withValues(alpha: 0.02 * animation.value),
      ],
    );

    canvas.drawRect(
      chartArea,
      Paint()..shader = backgroundGradient,
    );
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withValues(alpha: 0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw simple grid pattern
    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawErrorState(Canvas canvas, Size size) {
    // Draw a simple fallback UI when rendering errors occur
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(chartArea, paint);

    _textPainter.text = const TextSpan(
      text: "Error rendering chart",
      style: TextStyle(color: Colors.red, fontSize: 14),
    );
    _textPainter.layout();
    _textPainter.paint(
        canvas,
        Offset(
          chartArea.center.dx - _textPainter.width / 2,
          chartArea.center.dy - _textPainter.height / 2,
        ));
  }

  void _drawReferenceRanges(Canvas canvas) {
    final zones = [
      (
        HeartRateRange.highMax,
        HeartRateRange.highMin,
        style.highZoneColor,
        'High'
      ),
      (
        HeartRateRange.elevatedMax,
        HeartRateRange.elevatedMin,
        style.elevatedZoneColor,
        'Elevated'
      ),
      (
        HeartRateRange.normalMax,
        HeartRateRange.normalMin,
        style.normalZoneColor,
        'Normal'
      ),
      (HeartRateRange.lowMax, HeartRateRange.lowMin, style.lowZoneColor, 'Low'),
    ];

    for (var zone in zones) {
      // Only draw zones visible in the chart
      if (zone.$1 < minValue && zone.$2 < minValue) continue;
      if (zone.$1 > maxValue && zone.$2 > maxValue) continue;

      // Calculate y positions, clamping to chart bounds
      final topValue = min(zone.$1, maxValue);
      final bottomValue = max(zone.$2, minValue);

      final topY = _getYPosition(topValue.toDouble());
      final bottomY = _getYPosition(bottomValue.toDouble());

      // Create animated rect with proper bounds checking
      if (topY.isNaN || bottomY.isNaN) continue;

      final zoneRect = Rect.fromLTRB(
        chartArea.left,
        topY,
        chartArea.right,
        bottomY,
      );

      // Draw zone background with a simple color instead of gradient for better performance
      _fillPaint
        ..color = zone.$3.withValues(alpha: 0.1 * animation.value)
        ..style = PaintingStyle.fill;
      canvas.drawRect(zoneRect, _fillPaint);

      // Draw zone label for zones that occupy enough vertical space
      if ((bottomY - topY) >= 30) {
        _drawZoneLabel(canvas, zone.$4, zone.$3, zoneRect);
      }
    }
  }

  void _drawZoneLabel(Canvas canvas, String text, Color color, Rect zoneRect) {
    _textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.7 * animation.value),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      )
      ..layout(maxWidth: chartArea.width * 0.3);

    // Position at the beginning of the zone
    final labelX = chartArea.left + 8;
    final labelY = zoneRect.center.dy - (_textPainter.height / 2);

    // Only draw text if within valid bounds
    if (labelX >= 0 &&
        labelY >= 0 &&
        labelX + _textPainter.width <= chartArea.right &&
        labelY + _textPainter.height <= chartArea.bottom) {
      _textPainter.paint(canvas, Offset(labelX, labelY));
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = style.gridLineColor.withValues(alpha: 0.15 * animation.value)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines with animation
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());

      // Skip if position is outside bounds or NaN
      if (y.isNaN || y < chartArea.top || y > chartArea.bottom) continue;

      final start = Offset(chartArea.left, y);
      final end = Offset(
        chartArea.right,
        y,
      );

      canvas.drawLine(start, end, paint);
    }

    // Draw vertical grid lines (time divisions) - limit number for performance
    final verticalCount =
        min(_getVerticalGridCount(), 12); // Cap at 12 vertical lines
    final step = chartArea.width / verticalCount;

    for (var i = 0; i <= verticalCount; i++) {
      final x = chartArea.left + (i * step);

      // Skip if outside bounds
      if (x < chartArea.left || x > chartArea.right) continue;

      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, chartArea.bottom),
        paint,
      );
    }
  }

  int _getVerticalGridCount() {
    switch (viewType) {
      case DateRangeType.day:
        return 6; // Hours
      case DateRangeType.week:
        return 7; // Days
      case DateRangeType.month:
        return 4; // Weeks
      case DateRangeType.year:
        return 12; // Months
    }
  }

  void _drawAxisLabels(Canvas canvas) {
    // Draw y-axis labels with animation
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());

      // Skip if position is outside bounds or NaN
      if (y.isNaN || y < chartArea.top || y > chartArea.bottom) continue;

      final opacity = animation.value.clamp(0.0, 1.0);

      _textPainter
        ..text = TextSpan(
          text: value.toString(),
          style: style.labelStyle.copyWith(
            color: style.labelColor.withValues(alpha: opacity),
          ),
        )
        ..layout();

      // Calculate x position with bounds checking
      final xOffset = chartArea.left - _textPainter.width - 8;
      if (xOffset < 0) continue; // Skip if outside bounds

      _textPainter.paint(
        canvas,
        Offset(xOffset, y - _textPainter.height / 2),
      );
    }

    // Draw x-axis (time) labels with animation - only draw a reasonable number
    final labelStep = _calculateLabelStep();
    final maxLabels = 8; // Maximum number of labels to draw
    final step = max(labelStep, (data.length / maxLabels).ceil());

    for (var i = 0; i < data.length; i += step) {
      if (i >= data.length) continue;

      final x = _getXPosition(i);

      // Skip if position is outside bounds
      if (x < chartArea.left || x > chartArea.right) continue;

      final label = DateFormatter.format(data[i].startDate, viewType);
      final opacity = animation.value.clamp(0.0, 1.0);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: style.labelStyle.copyWith(
            color: style.labelColor.withValues(alpha: opacity),
          ),
        )
        ..layout();

      // Calculate y position with bounds checking
      final yOffset = chartArea.bottom + 8;
      if (yOffset + _textPainter.height > chartArea.bottom + 30)
        continue; // Skip if too low

      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, yOffset),
      );
    }
  }

  int _calculateLabelStep() {
    if (data.length <= 7) return 1;

    switch (viewType) {
      case DateRangeType.day:
        return (data.length / 6).round().clamp(1, data.length);
      case DateRangeType.week:
        return 1;
      case DateRangeType.month:
        return (data.length / 8).round().clamp(1, 4);
      case DateRangeType.year:
        return (data.length / 12).round().clamp(1, 3);
    }
  }

  void _buildPaths() {
    try {
      // Initialize paths
      _heartRatePath = Path();
      _restingRatePath = Path();
      _maxRatePath = Path();
      _minRatePath = Path();

      bool hasValidHeartRate = false;
      bool hasValidRestingRate = false;
      bool hasValidRangeData = false;

      // Collect points for smoother curves
      final List<Offset> heartRatePoints = [];
      final List<Offset> restingRatePoints = [];
      final List<Offset> maxRatePoints = [];
      final List<Offset> minRatePoints = [];

      // Process each data point
      for (var i = 0; i < data.length; i++) {
        final entry = data[i];
        if (entry.isEmpty) continue;

        final x = _getXPosition(i);

        // Skip if x position is outside bounds
        if (x < chartArea.left || x > chartArea.right) continue;

        // Heart rate (average)
        final heartRateY = _getYPosition(entry.avgValue);

        // Skip if y position is outside bounds or NaN
        if (heartRateY.isNaN ||
            heartRateY < chartArea.top ||
            heartRateY > chartArea.bottom) continue;

        heartRatePoints.add(Offset(x, heartRateY));

        // Start heart rate path if first valid point
        if (!hasValidHeartRate) {
          _heartRatePath!.moveTo(x, heartRateY);
          hasValidHeartRate = true;
        }

        // Resting rate if available
        if (entry.restingRate != null && entry.restingRate! > 0) {
          final restingRateY = _getYPosition(entry.restingRate!.toDouble());

          // Skip if y position is outside bounds or NaN
          if (!restingRateY.isNaN &&
              restingRateY >= chartArea.top &&
              restingRateY <= chartArea.bottom) {
            restingRatePoints.add(Offset(x, restingRateY));

            if (!hasValidRestingRate) {
              _restingRatePath!.moveTo(x, restingRateY);
              hasValidRestingRate = true;
            }
          }
        }

        // Range data (min/max)
        if (entry.isRangeData) {
          final maxRateY = _getYPosition(entry.maxValue.toDouble());
          final minRateY = _getYPosition(entry.minValue.toDouble());

          // Skip if positions are outside bounds or NaN
          if (!maxRateY.isNaN &&
              !minRateY.isNaN &&
              maxRateY >= chartArea.top &&
              maxRateY <= chartArea.bottom &&
              minRateY >= chartArea.top &&
              minRateY <= chartArea.bottom) {
            maxRatePoints.add(Offset(x, maxRateY));
            minRatePoints.add(Offset(x, minRateY));

            if (!hasValidRangeData) {
              _maxRatePath!.moveTo(x, maxRateY);
              _minRatePath!.moveTo(x, minRateY);
              hasValidRangeData = true;
            }
          }
        }
      }

      // Create lines for the paths - use simpler approach for better performance
      // Only use smoothing when we have few data points
      final useSmoothing = heartRatePoints.length < 20;

      if (useSmoothing) {
        _createSmoothPath(_heartRatePath!, heartRatePoints);
        if (hasValidRestingRate && restingRatePoints.length > 1) {
          _createSmoothPath(_restingRatePath!, restingRatePoints);
        }
        if (hasValidRangeData &&
            maxRatePoints.length > 1 &&
            minRatePoints.length > 1) {
          _createSmoothPath(_maxRatePath!, maxRatePoints);
          _createSmoothPath(_minRatePath!, minRatePoints);
        }
      } else {
        // Simple lines for better performance with many points
        _createSimplePath(_heartRatePath!, heartRatePoints);
        if (hasValidRestingRate && restingRatePoints.length > 1) {
          _createSimplePath(_restingRatePath!, restingRatePoints);
        }
        if (hasValidRangeData &&
            maxRatePoints.length > 1 &&
            minRatePoints.length > 1) {
          _createSimplePath(_maxRatePath!, maxRatePoints);
          _createSimplePath(_minRatePath!, minRatePoints);
        }
      }
    } catch (e) {
      // Reset paths if an error occurs
      _heartRatePath = null;
      _restingRatePath = null;
      _maxRatePath = null;
      _minRatePath = null;
    }
  }

  void _createSmoothPath(Path path, List<Offset> points) {
    if (points.length < 2) return;

    // Start from the first point
    path.reset();
    path.moveTo(points.first.dx, points.first.dy);

    // If only two points, just draw a line
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return;
    }

    // Use a simpler curve for smoother rendering
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (i < points.length - 2) {
        final p3 = points[i + 2];
        final midPoint1 = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final midPoint2 = Offset((p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2);

        path.quadraticBezierTo(p2.dx, p2.dy, midPoint2.dx, midPoint2.dy);
      } else {
        path.lineTo(p2.dx, p2.dy);
      }
    }
  }

  void _createSimplePath(Path path, List<Offset> points) {
    if (points.isEmpty) return;

    path.reset();
    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
  }

  void _drawRangeArea(Canvas canvas) {
    if (_maxRatePath == null || _minRatePath == null) return;

    try {
      // Create a simplified area path
      final areaPath = Path();

      // Get a list of points from max and min paths
      final List<Offset> maxPoints = [];
      final List<Offset> minPoints = [];

      // Sample points at regular intervals for better performance
      final step = max(1, (data.length / 30).round());

      for (var i = 0; i < data.length; i += step) {
        if (i >= data.length || data[i].isEmpty) continue;

        final x = _getXPosition(i);
        final maxY = _getYPosition(data[i].maxValue.toDouble());
        final minY = _getYPosition(data[i].minValue.toDouble());

        // Skip invalid points
        if (maxY.isNaN || minY.isNaN) continue;

        maxPoints.add(Offset(x, maxY));
        minPoints.add(Offset(x, minY));
      }

      // Create area path
      if (maxPoints.isNotEmpty && minPoints.isNotEmpty) {
        areaPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);

        // Add max points
        for (var point in maxPoints) {
          areaPath.lineTo(point.dx, point.dy);
        }

        // Add min points in reverse
        for (var i = minPoints.length - 1; i >= 0; i--) {
          areaPath.lineTo(minPoints[i].dx, minPoints[i].dy);
        }

        areaPath.close();

        // Draw the area with a solid color for better performance
        _fillPaint
          ..color = style.primaryColor.withValues(alpha: 0.1 * animation.value)
          ..style = PaintingStyle.fill;

        canvas.drawPath(areaPath, _fillPaint);
      }
    } catch (e) {
      // Skip drawing range area if an error occurs
    }
  }

  void _drawDataPoints(Canvas canvas) {
    // Determine optimal rendering strategy based on data density
    final isHighDensity = data.length > 100;
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    // Scale hit test threshold by device pixel ratio for consistent touch behavior
    // final adjustedHitThreshold = _hitTestThreshold * devicePixelRatio;

    // Adaptive step calculation
    final step = _calculateAdaptiveStep(data.length);

    // Create a more efficient paint for high density rendering
    if (isHighDensity) {
      _pointPaint.isAntiAlias = false; // Disable anti-aliasing for performance
    } else {
      _pointPaint.isAntiAlias = true; // Enable for quality with fewer points
    }

    // Draw regularly spaced points
    for (var i = 0; i < data.length; i += step) {
      if (i >= data.length) continue;

      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _getXPosition(i);
      final y = _getYPosition(entry.avgValue);

      // Skip if position is outside bounds or NaN
      if (x < chartArea.left ||
          x > chartArea.right ||
          y < chartArea.top ||
          y > chartArea.bottom ||
          y.isNaN) continue;

      // Determine if this is the selected point
      final isSelected = selectedData == entry;

      // Base point radius - use smaller radius for better performance
      var pointRadius = isHighDensity
          ? style.pointRadius * 0.5 // Even smaller for high density
          : style.pointRadius * 0.8; // Regular small radius

      // Larger radius for selected point
      if (isSelected) {
        pointRadius = style.selectedPointRadius;
      }

      // Apply animation to radius
      final animatedRadius = pointRadius * animation.value;

      // Only draw outline for selected or steps with larger interval
      if (isSelected || i % (step * 3) == 0 || !isHighDensity) {
        // Draw white outline
        _pointPaint
          ..color = Colors.white.withValues(alpha: animation.value)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), animatedRadius + 1, _pointPaint);
      }

      // Draw colored center
      _pointPaint
        ..color = (isSelected ? style.selectedColor : style.primaryColor)
            .withValues(alpha: animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), animatedRadius, _pointPaint);

      // Only draw range endpoints for selected point or with larger step and not high density
      if ((isSelected || i % (step * 5) == 0) &&
          entry.isRangeData &&
          entry.dataPointCount > 1 &&
          !isHighDensity) {
        _drawRangeEndpoints(canvas, x, entry, animatedRadius * 0.7);
      }
    }

    // Always draw the selected point (if any)
    if (selectedData != null && !selectedData!.isEmpty) {
      _drawSelectedPoint(canvas);
    }
  }

// Helper method to calculate adaptive step based on data density
  int _calculateAdaptiveStep(int dataLength) {
    if (dataLength <= 20) return 1;
    if (dataLength <= 50) return 2;
    if (dataLength <= 100) return 3;
    if (dataLength <= 200) return 5;
    if (dataLength <= 500) return 10;
    return (dataLength / 50).round(); // For very large datasets
  }

// Extracted method to draw the selected point
  void _drawSelectedPoint(Canvas canvas) {
    final index = data.indexOf(selectedData!);
    if (index < 0) return;

    final x = _getXPosition(index);
    final y = _getYPosition(selectedData!.avgValue);

    // Skip if position is outside bounds or NaN
    if (x < chartArea.left ||
        x > chartArea.right ||
        y < chartArea.top ||
        y > chartArea.bottom ||
        y.isNaN) return;

    // Draw white outline with glow
    _pointPaint
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..isAntiAlias = true; // Always use anti-aliasing for selected point

    canvas.drawCircle(Offset(x, y), style.selectedPointRadius + 2, _pointPaint);
    _pointPaint.maskFilter = null;

    // Draw colored center
    _pointPaint
      ..color = style.selectedColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), style.selectedPointRadius, _pointPaint);

    // Draw range endpoints
    if (selectedData!.isRangeData && selectedData!.dataPointCount > 1) {
      _drawRangeEndpoints(
          canvas, x, selectedData!, style.selectedPointRadius * 0.7);
    }
  }

  void _drawRangeEndpoints(
      Canvas canvas, double x, ProcessedHeartRateData entry, double radius) {
    final maxY = _getYPosition(entry.maxValue.toDouble());
    final minY = _getYPosition(entry.minValue.toDouble());

    // Skip if positions are outside bounds or NaN
    if (maxY.isNaN ||
        minY.isNaN ||
        maxY < chartArea.top ||
        maxY > chartArea.bottom ||
        minY < chartArea.top ||
        minY > chartArea.bottom) return;

    // Skip if too close to average value
    if ((maxY - _getYPosition(entry.avgValue)).abs() > 5) {
      // Max value point (smaller)
      _pointPaint
        ..color = Colors.white.withValues(alpha: 0.8 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, maxY), radius, _pointPaint);

      _pointPaint
        ..color = style.primaryColor.withValues(alpha: 0.7 * animation.value);

      canvas.drawCircle(Offset(x, maxY), radius * 0.7, _pointPaint);
    }

    // Skip if too close to average value
    if ((minY - _getYPosition(entry.avgValue)).abs() > 5) {
      // Min value point (smaller)
      _pointPaint
        ..color = Colors.white.withValues(alpha: 0.8 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, minY), radius, _pointPaint);

      _pointPaint
        ..color = style.primaryColor.withValues(alpha: 0.7 * animation.value);

      canvas.drawCircle(Offset(x, minY), radius * 0.7, _pointPaint);
    }
  }

  double _getYPosition(double value) {
    // Handle potential division by zero or very small range
    if (maxValue <= minValue) return chartArea.center.dy;

    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  double _getXPosition(int index) {
    if (data.isEmpty) return chartArea.center.dx;
    if (data.length <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0;
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (data.length - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  @override
  bool shouldRepaint(covariant HeartRateChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        animation.value != oldDelegate.animation.value ||
        chartArea != oldDelegate.chartArea ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        showGrid != oldDelegate.showGrid ||
        showRanges != oldDelegate.showRanges ||
        viewType != oldDelegate.viewType ||
        selectedData != oldDelegate.selectedData;
  }
}
