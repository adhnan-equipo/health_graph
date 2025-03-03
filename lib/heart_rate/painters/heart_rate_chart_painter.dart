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
  }

  void _drawBackground(Canvas canvas) {
    canvas.drawRect(
      chartArea,
      Paint()..color = style.backgroundColor.withOpacity(0.1 * animation.value),
    );
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw animated grid pattern
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
    }
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

      // Create animated rect
      final center = Offset(
        chartArea.center.dx,
        (topY + bottomY) / 2,
      );

      final animatedRect = Rect.fromCenter(
        center: center,
        width: chartArea.width * animation.value,
        height: (bottomY - topY),
      );

      // Draw zone background
      canvas.drawRect(
        animatedRect,
        Paint()..color = zone.$3.withOpacity(0.1 * animation.value),
      );

      // Draw zone label for zones that occupy enough vertical space
      if ((bottomY - topY) >= 30) {
        _drawZoneLabel(canvas, zone.$4, zone.$3, animatedRect);
      }
    }
  }

  void _drawZoneLabel(Canvas canvas, String text, Color color, Rect zoneRect) {
    _textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(0.7 * animation.value),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      )
      ..layout();

    // Position at the beginning of the zone
    final labelX = chartArea.left + 8;
    final labelY = zoneRect.center.dy - (_textPainter.height / 2);

    _textPainter.paint(canvas, Offset(labelX, labelY));
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.15 * animation.value)
      ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());

      final start = Offset(chartArea.left, y);
      final end = Offset(
        ui.lerpDouble(chartArea.left, chartArea.right, animation.value)!,
        y,
      );

      canvas.drawLine(start, end, paint);
    }

    // Draw vertical grid lines (time divisions)
    final verticalCount = _getVerticalGridCount();
    final step = chartArea.width / verticalCount;

    for (var i = 0; i <= verticalCount; i++) {
      final x = chartArea.left + (i * step);
      final progress = (i / verticalCount * animation.value).clamp(0.0, 1.0);

      canvas.drawLine(
        Offset(x, chartArea.top),
        Offset(x, ui.lerpDouble(chartArea.top, chartArea.bottom, progress)!),
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
    // Draw y-axis labels
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());
      final opacity = animation.value.clamp(0.0, 1.0);

      _textPainter
        ..text = TextSpan(
          text: value.toString(),
          style: style.labelStyle.copyWith(
            color: style.labelColor.withOpacity(opacity),
          ),
        )
        ..layout();

      // Animate label position
      final xOffset = chartArea.left - _textPainter.width - 8;
      final animatedXOffset =
          ui.lerpDouble(chartArea.left, xOffset, animation.value)!;

      _textPainter.paint(
        canvas,
        Offset(animatedXOffset, y - _textPainter.height / 2),
      );
    }

    // Draw x-axis (time) labels
    final labelStep = _calculateLabelStep();

    for (var i = 0; i < data.length; i += labelStep) {
      if (i >= data.length) continue;

      final x = _getXPosition(i);
      final label = DateFormatter.format(data[i].startDate, viewType);
      final opacity = animation.value.clamp(0.0, 1.0);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: style.labelStyle.copyWith(
            color: style.labelColor.withOpacity(opacity),
          ),
        )
        ..layout();

      // Animate label position
      final yOffset = chartArea.bottom + 8;
      final animatedYOffset =
          ui.lerpDouble(chartArea.bottom, yOffset, animation.value)!;

      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, animatedYOffset),
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

  void _drawHeartRateData(Canvas canvas) {
    if (data.isEmpty) return;

    // Build paths if data has changed
    final currentHash =
        '${data.length}_${data.first.hashCode}_${animation.value}';
    if (_lastDataHash != currentHash) {
      _buildPaths();
      _lastDataHash = currentHash;
    }

    // Draw range area (shaded area between min and max)
    _drawRangeArea(canvas);

    // Draw main heart rate line
    if (_heartRatePath != null) {
      _linePaint
        ..color = style.primaryColor.withOpacity(0.8 * animation.value)
        ..strokeWidth = style.lineThickness
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(_heartRatePath!, _linePaint);
    }

    // Draw resting heart rate line if exists
    if (_restingRatePath != null) {
      _linePaint
        ..color = style.restingRateColor.withOpacity(0.6 * animation.value)
        ..strokeWidth = style.lineThickness - 0.5
        ..strokeCap = StrokeCap.round;
      // ..strokeDashArray = [3, 3];

      canvas.drawPath(_restingRatePath!, _linePaint);
      // _linePaint.strokeDashArray = null;
    }

    // Draw data points
    _drawDataPoints(canvas);
  }

  void _buildPaths() {
    // Initialize paths
    _heartRatePath = Path();
    _restingRatePath = Path();
    _maxRatePath = Path();
    _minRatePath = Path();

    var hasValidHeartRate = false;
    var hasValidRestingRate = false;
    var hasValidRangeData = false;

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

      // Heart rate (average)
      final heartRateY = _getYPosition(entry.avgValue);
      heartRatePoints.add(Offset(x, heartRateY));

      // Start heart rate path if first valid point
      if (!hasValidHeartRate) {
        _heartRatePath!.moveTo(x, heartRateY);
        hasValidHeartRate = true;
      }

      // Resting rate if available
      if (entry.restingRate != null) {
        final restingRateY = _getYPosition(entry.restingRate!.toDouble());
        restingRatePoints.add(Offset(x, restingRateY));

        if (!hasValidRestingRate) {
          _restingRatePath!.moveTo(x, restingRateY);
          hasValidRestingRate = true;
        }
      }

      // Range data (min/max)
      if (entry.isRangeData) {
        final maxRateY = _getYPosition(entry.maxValue.toDouble());
        final minRateY = _getYPosition(entry.minValue.toDouble());

        maxRatePoints.add(Offset(x, maxRateY));
        minRatePoints.add(Offset(x, minRateY));

        if (!hasValidRangeData) {
          _maxRatePath!.moveTo(x, maxRateY);
          _minRatePath!.moveTo(x, minRateY);
          hasValidRangeData = true;
        }
      }
    }

    // Create smooth curves for the paths using the collected points
    _createSmoothPath(_heartRatePath!, heartRatePoints);
    if (hasValidRestingRate) {
      _createSmoothPath(_restingRatePath!, restingRatePoints);
    }
    if (hasValidRangeData) {
      _createSmoothPath(_maxRatePath!, maxRatePoints);
      _createSmoothPath(_minRatePath!, minRatePoints);
    }
  }

  void _createSmoothPath(Path path, List<Offset> points) {
    if (points.length < 2) return;

    // Start from the first point
    path.moveTo(points.first.dx, points.first.dy);

    // If only two points, just draw a line
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return;
    }

    // Use cubic bezier curves for smoother path
    for (var i = 0; i < points.length - 1; i++) {
      if (i == 0) {
        // First segment
        final p0 = points[i];
        final p1 = points[i + 1];

        // Simple control points for first segment
        final c1 = Offset(p0.dx + (p1.dx - p0.dx) / 3, p0.dy);
        final c2 = Offset(p0.dx + 2 * (p1.dx - p0.dx) / 3, p1.dy);

        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      } else if (i < points.length - 2) {
        // Middle segments - use points before and after for better smoothing
        final p0 = points[i - 1];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = points[i + 2];

        // Calculate control points based on surrounding points
        final xDiff = (p2.dx - p0.dx) / 4;
        final c1 = Offset(p1.dx + xDiff, p1.dy);
        final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 4, p2.dy);

        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      } else {
        // Last segment
        final p0 = points[i];
        final p1 = points[i + 1];

        // Simple control points for last segment
        final c1 = Offset(p0.dx + (p1.dx - p0.dx) / 3, p0.dy);
        final c2 = Offset(p0.dx + 2 * (p1.dx - p0.dx) / 3, p1.dy);

        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      }
    }
  }

  void _drawRangeArea(Canvas canvas) {
    if (_maxRatePath == null || _minRatePath == null) return;

    // Create a combined path for the area
    final areaPath = Path();

    // Add max path
    areaPath.addPath(_maxRatePath!, Offset.zero);

    // Create the bottom part by adding min path in reverse
    final reversedMinPath = Path();
    final minMetrics = _minRatePath!.computeMetrics();

    for (final metric in minMetrics) {
      final length = metric.length;
      final pathSegment = metric.extractPath(0, length);
      // Add the path in reverse order
      for (double dist = length; dist >= 0; dist -= 1) {
        try {
          final pos = metric.getTangentForOffset(dist)?.position;
          if (pos != null) {
            if (dist == length) {
              reversedMinPath.moveTo(pos.dx, pos.dy);
            } else {
              reversedMinPath.lineTo(pos.dx, pos.dy);
            }
          }
        } catch (e) {
          // Handle potential errors from getTangentForOffset
        }
      }
    }

    // Add the reversed min path to the area path
    areaPath.addPath(reversedMinPath, Offset.zero);

    // Close the path
    areaPath.close();

    // Create gradient for the range area
    final rangeGradient = ui.Gradient.linear(
      Offset(0, chartArea.top),
      Offset(0, chartArea.bottom),
      [
        style.primaryColor.withOpacity(0.2 * animation.value),
        style.primaryColor.withOpacity(0.05 * animation.value),
      ],
    );

    // Draw the range area
    _fillPaint
      ..shader = rangeGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, _fillPaint);

    // Reset shader
    _fillPaint.shader = null;
  }

  void _drawDataPoints(Canvas canvas) {
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _getXPosition(i);
      final y = _getYPosition(entry.avgValue);

      // Determine if this is the selected point
      final isSelected = selectedData == entry;

      // Base point radius
      var pointRadius = style.pointRadius;

      // Larger radius for selected point
      if (isSelected) {
        pointRadius = style.selectedPointRadius;
      }

      // Apply animation to radius
      final animatedRadius = pointRadius * animation.value;

      // Draw outer glow for selected point
      if (isSelected) {
        _pointPaint
          ..color = style.selectedColor.withOpacity(0.3 * animation.value)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(Offset(x, y), animatedRadius * 1.5, _pointPaint);
        _pointPaint.maskFilter = null;
      }

      // Draw white outline
      _pointPaint
        ..color = Colors.white.withOpacity(animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), animatedRadius + 1, _pointPaint);

      // Draw colored center
      _pointPaint
        ..color = (isSelected ? style.selectedColor : style.primaryColor)
            .withOpacity(animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), animatedRadius, _pointPaint);

      // Add highlight for 3D effect
      _pointPaint
        ..color = Colors.white.withOpacity(0.6 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x - animatedRadius * 0.3, y - animatedRadius * 0.3),
        animatedRadius * 0.3,
        _pointPaint,
      );

      // For range data, optionally draw min and max points
      if (entry.isRangeData && entry.dataPointCount > 1) {
        _drawRangeEndpoints(canvas, x, entry, animatedRadius * 0.7);
      }
    }
  }

  void _drawRangeEndpoints(
      Canvas canvas, double x, ProcessedHeartRateData entry, double radius) {
    final maxY = _getYPosition(entry.maxValue.toDouble());
    final minY = _getYPosition(entry.minValue.toDouble());

    // Skip if too close to average value
    if ((maxY - _getYPosition(entry.avgValue)).abs() > 5) {
      // Max value point (smaller)
      _pointPaint
        ..color = Colors.white.withOpacity(0.8 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, maxY), radius, _pointPaint);

      _pointPaint
        ..color = style.primaryColor.withOpacity(0.7 * animation.value);

      canvas.drawCircle(Offset(x, maxY), radius * 0.7, _pointPaint);
    }

    // Skip if too close to average value
    if ((minY - _getYPosition(entry.avgValue)).abs() > 5) {
      // Min value point (smaller)
      _pointPaint
        ..color = Colors.white.withOpacity(0.8 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, minY), radius, _pointPaint);

      _pointPaint
        ..color = style.primaryColor.withOpacity(0.7 * animation.value);

      canvas.drawCircle(Offset(x, minY), radius * 0.7, _pointPaint);
    }
  }

  double _getYPosition(double value) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  double _getXPosition(int index) {
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
        style != oldDelegate.style ||
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
