import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../models/chart_view_config.dart';
import '../models/processed_blood_pressure_data.dart';
import '../styles/blood_pressure_chart_style.dart';

class BloodPressureChartPainter extends CustomPainter {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final ProcessedBloodPressureData? selectedData;
  final Rect chartArea;
  final List<int> yAxisValues;
  final double minValue;
  final double maxValue;

  // Reusable paints for better performance
  final Paint _gridPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final Paint _rangePaint = Paint()..style = PaintingStyle.fill;
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _pointPaint = Paint()..style = PaintingStyle.fill;
  final Paint _highlightPaint = Paint()..style = PaintingStyle.fill;

  // Path caches
  Path? _systolicPath;
  Path? _diastolicPath;
  String _dataHash = '';

  // Text painter for reuse
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  BloodPressureChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.yAxisValues,
    required this.minValue,
    required this.maxValue,
    this.selectedData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Create new hash for caching paths
    final newHash = '${data.length}_${data.first.hashCode}_${animation.value}';

    // Background and clip region
    canvas.save();
    canvas.clipRect(chartArea);

    // Draw background with subtle gradient
    _drawEnhancedBackground(canvas, chartArea);

    // Draw reference ranges with smooth animation
    _drawReferenceRanges(canvas);

    // Draw grid with subtle animation
    if (config.showGrid) {
      _drawAnimatedGrid(canvas);
    }

    canvas.restore();

    // Draw labels with clean animation
    _drawYAxisLabels(canvas);
    _drawTimeLabels(canvas);

    // Draw data visualization
    canvas.save();
    canvas.clipRect(chartArea);

    // Rebuild paths if data changed
    if (_dataHash != newHash) {
      _dataHash = newHash;
      _buildPaths();
    }

    // Draw trend lines first (behind the points)
    if (config.showTrendLine) {
      _drawTrendLines(canvas);
    }

    // Highlight selected data column
    if (selectedData != null) {
      _drawSelectionHighlight(canvas);
    }

    // Draw all data points with smooth animations
    _drawDataPoints(canvas);

    canvas.restore();
  }

  void _drawEnhancedBackground(Canvas canvas, Rect chartArea) {
    // Create subtle gradient background
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        Colors.grey.shade50.withOpacity(animation.value * 0.3),
      ],
    );

    _rangePaint
      ..style = PaintingStyle.fill
      ..shader = bgGradient.createShader(chartArea);

    canvas.drawRect(chartArea, _rangePaint);
    _rangePaint.shader = null;
  }

  void _drawAnimatedGrid(Canvas canvas) {
    _gridPaint
      ..color = style.gridLineColor.withOpacity(0.15 * animation.value)
      ..strokeWidth = 0.5;

    final dashWidth = 3.0 * animation.value;
    final dashSpace = 2.0;

    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());

      // Animated drawing of dashed grid lines
      if (animation.value > 0.5) {
        double distance = 0;
        final maxDistance = chartArea.width;

        while (distance < maxDistance) {
          final animatedWidth = dashWidth * (animation.value * 2 - 1);
          canvas.drawLine(
            Offset(chartArea.left + distance, y),
            Offset(chartArea.left + distance + animatedWidth, y),
            _gridPaint,
          );
          distance += dashWidth + dashSpace;
        }
      }
    }
  }

  void _drawReferenceRanges(Canvas canvas) {
    // Normal systolic range
    final systolicRange = Rect.fromLTRB(
      chartArea.left,
      _getYPosition(120), // Normal systolic max
      chartArea.right,
      _getYPosition(90), // Normal systolic min
    );

    // Normal diastolic range
    final diastolicRange = Rect.fromLTRB(
      chartArea.left,
      _getYPosition(80), // Normal diastolic max
      chartArea.right,
      _getYPosition(60), // Normal diastolic min
    );

    // Draw ranges with animation
    _rangePaint
      ..color = style.normalRangeColor.withOpacity(0.1 * animation.value);

    // Animated appearance from center
    final systolicCenter = systolicRange.center;
    final animatedSystolicRect = Rect.fromCenter(
      center: systolicCenter,
      width: systolicRange.width * animation.value,
      height: systolicRange.height,
    );

    final diastolicCenter = diastolicRange.center;
    final animatedDiastolicRect = Rect.fromCenter(
      center: diastolicCenter,
      width: diastolicRange.width * animation.value,
      height: diastolicRange.height,
    );

    canvas.drawRect(animatedSystolicRect, _rangePaint);
    canvas.drawRect(animatedDiastolicRect, _rangePaint);

    // Draw range labels with fade-in
    if (animation.value > 0.7) {
      final fadeIn = (animation.value - 0.7) / 0.3;
      _drawRangeLabel(canvas, systolicRange, "Normal Systolic Range", fadeIn);
      _drawRangeLabel(canvas, diastolicRange, "Normal Diastolic Range", fadeIn);
    }
  }

  void _drawRangeLabel(
      Canvas canvas, Rect rangeRect, String text, double opacity) {
    _textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: style.gridLineColor.withOpacity(0.7 * opacity),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      )
      ..layout();

    // Add semi-transparent background for better readability
    final labelBg = Rect.fromLTWH(
      rangeRect.left + 5,
      rangeRect.center.dy - (_textPainter.height / 2),
      _textPainter.width + 8,
      _textPainter.height,
    );

    canvas.drawRect(
      labelBg,
      Paint()..color = Colors.white.withOpacity(0.7 * opacity),
    );

    _textPainter.paint(
      canvas,
      Offset(
        rangeRect.left + 8,
        rangeRect.center.dy - (_textPainter.height / 2),
      ),
    );
  }

  void _drawYAxisLabels(Canvas canvas) {
    for (var value in yAxisValues) {
      final y = _getYPosition(value.toDouble());

      _textPainter
        ..text = TextSpan(
          text: value.toString(),
          style: TextStyle(
            color: Colors.grey.shade700.withOpacity(animation.value),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout();

      // Animated entry from left
      final x = ui.lerpDouble(
        chartArea.left,
        chartArea.left - _textPainter.width - 8,
        animation.value,
      )!;

      _textPainter.paint(
        canvas,
        Offset(x, y - _textPainter.height / 2),
      );
    }
  }

  void _drawTimeLabels(Canvas canvas) {
    if (data.isEmpty) return;

    final labelInterval = _calculateLabelInterval();

    for (var i = 0; i < data.length; i += labelInterval) {
      if (i >= data.length) continue;

      final entry = data[i];
      final x = _getXPosition(i);

      // Skip if out of bounds
      if (x < chartArea.left || x > chartArea.right) continue;

      // Format date based on view type
      final label = _formatDateLabel(entry);

      _textPainter
        ..text = TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.grey.shade700.withOpacity(animation.value),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout();

      // Animated entry from bottom
      final y = ui.lerpDouble(
        chartArea.bottom,
        chartArea.bottom + 16,
        animation.value,
      )!;

      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, y),
      );
    }
  }

  String _formatDateLabel(ProcessedBloodPressureData data) {
    switch (config.viewType) {
      case DateRangeType.day:
        return '${data.startDate.hour}:00';
      case DateRangeType.week:
        return '${data.startDate.day}/${data.startDate.month}';
      case DateRangeType.month:
        return '${data.startDate.day}';
      case DateRangeType.year:
        return '${_getMonthAbbreviation(data.startDate.month)}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  int _calculateLabelInterval() {
    final count = data.length;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 4;
    return (count / 6).ceil();
  }

  void _buildPaths() {
    _systolicPath = Path();
    _diastolicPath = Path();

    bool isFirstValid = true;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _getXPosition(i);

      // Only include points within chart area
      if (x < chartArea.left || x > chartArea.right) continue;

      final systolicY = _getYPosition(entry.avgSystolic);
      final diastolicY = _getYPosition(entry.avgDiastolic);

      if (isFirstValid) {
        _systolicPath!.moveTo(x, systolicY);
        _diastolicPath!.moveTo(x, diastolicY);
        isFirstValid = false;
      } else {
        // Use cubic bezier for smoother curves
        _systolicPath!.lineTo(x, systolicY);
        _diastolicPath!.lineTo(x, diastolicY);
      }
    }
  }

  void _drawTrendLines(Canvas canvas) {
    if (_systolicPath == null || _diastolicPath == null) return;

    // Draw systolic trend line with animation and gradient
    _linePaint
      ..color = style.systolicColor.withOpacity(0.6 * animation.value)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(_systolicPath!, _linePaint);

    // Draw diastolic trend line with animation
    _linePaint
      ..color = style.diastolicColor.withOpacity(0.6 * animation.value)
      ..strokeWidth = 2.0;

    canvas.drawPath(_diastolicPath!, _linePaint);
  }

  void _drawSelectionHighlight(Canvas canvas) {
    if (selectedData == null) return;

    // Find index of selected data
    final selectedIndex = data.indexWhere((d) =>
        d.startDate == selectedData!.startDate &&
        d.endDate == selectedData!.endDate);

    if (selectedIndex < 0) return;

    final x = _getXPosition(selectedIndex);

    // Create a pulsing effect
    final pulseValue = 0.85 + 0.15 * sin(animation.value * 6);

    // Draw vertical highlight line
    _linePaint
      ..color = style.selectedHighlightColor.withOpacity(0.7 * pulseValue)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(x, chartArea.top),
      Offset(x, chartArea.bottom),
      _linePaint,
    );

    // Add a subtle gradient background for the column
    final gradientRect = Rect.fromLTRB(
      x - 15,
      chartArea.top,
      x + 15,
      chartArea.bottom,
    );

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        style.selectedHighlightColor.withOpacity(0),
        style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
        style.selectedHighlightColor.withOpacity(0.15 * pulseValue),
        style.selectedHighlightColor.withOpacity(0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    _highlightPaint
      ..shader = gradient.createShader(gradientRect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(gradientRect, _highlightPaint);
    _highlightPaint.shader = null;
  }

  void _drawDataPoints(Canvas canvas) {
    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.isEmpty) continue;

      final x = _getXPosition(i);

      // Skip if outside chart area
      if (x < chartArea.left || x > chartArea.right) continue;

      final isSelected = selectedData != null &&
          entry.startDate == selectedData!.startDate &&
          entry.endDate == selectedData!.endDate;

      // Calculate animation progress for this point
      final pointProgress = _calculatePointAnimation(i);

      if (entry.dataPointCount == 1) {
        _drawSinglePoint(canvas, entry, x, pointProgress, isSelected);
      } else {
        _drawRangePoint(canvas, entry, x, pointProgress, isSelected);
      }
    }
  }

  void _drawSinglePoint(Canvas canvas, ProcessedBloodPressureData entry,
      double x, double progress, bool isSelected) {
    final systolicY = _getYPosition(entry.avgSystolic);
    final diastolicY = _getYPosition(entry.avgDiastolic);

    // Draw connecting line
    _linePaint
      ..color = style.connectorColor.withOpacity(0.5 * progress)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(x, systolicY),
      Offset(x, diastolicY),
      _linePaint,
    );

    // Draw systolic point with animation and enhanced style
    _drawAnimatedPoint(
      canvas,
      Offset(x, systolicY),
      style.systolicColor,
      style.pointRadius * (isSelected ? 1.4 : 1.0),
      progress,
      isSelected,
    );

    // Draw diastolic point
    _drawAnimatedPoint(
      canvas,
      Offset(x, diastolicY),
      style.diastolicColor,
      style.pointRadius * (isSelected ? 1.4 : 1.0),
      progress,
      isSelected,
    );
  }

  void _drawRangePoint(Canvas canvas, ProcessedBloodPressureData entry,
      double x, double progress, bool isSelected) {
    final systolicMaxY = _getYPosition(entry.maxSystolic.toDouble());
    final systolicMinY = _getYPosition(entry.minSystolic.toDouble());
    final diastolicMaxY = _getYPosition(entry.maxDiastolic.toDouble());
    final diastolicMinY = _getYPosition(entry.minDiastolic.toDouble());

    // Enhanced line width for ranges
    final lineWidth = style.lineThickness * (isSelected ? 3.0 : 2.5);

    // Draw systolic range
    _drawAnimatedRangeLine(
      canvas,
      Offset(x, systolicMaxY),
      Offset(x, systolicMinY),
      style.systolicColor,
      lineWidth,
      progress,
      isSelected,
    );

    // Draw diastolic range
    _drawAnimatedRangeLine(
      canvas,
      Offset(x, diastolicMaxY),
      Offset(x, diastolicMinY),
      style.diastolicColor,
      lineWidth,
      progress,
      isSelected,
    );

    // Draw average points for better visual reference
    _drawAnimatedPoint(
      canvas,
      Offset(x, _getYPosition(entry.avgSystolic)),
      style.systolicColor,
      style.pointRadius * 0.8,
      progress,
      isSelected,
    );

    _drawAnimatedPoint(
      canvas,
      Offset(x, _getYPosition(entry.avgDiastolic)),
      style.diastolicColor,
      style.pointRadius * 0.8,
      progress,
      isSelected,
    );
  }

  void _drawAnimatedRangeLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
    double progress,
    bool isSelected,
  ) {
    // Calculate center point for animation
    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Animate line growing from center
    final animatedStart = Offset.lerp(center, start, progress)!;
    final animatedEnd = Offset.lerp(center, end, progress)!;

    // Draw outer line
    _linePaint
      ..color = color.withOpacity(isSelected ? 0.9 : 0.7)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(animatedStart, animatedEnd, _linePaint);

    // Draw terminal points with emphasis
    final capRadius = width / 2;
    _pointPaint..color = color.withOpacity(isSelected ? 1.0 : 0.8);

    canvas.drawCircle(animatedStart, capRadius, _pointPaint);
    canvas.drawCircle(animatedEnd, capRadius, _pointPaint);
  }

  void _drawAnimatedPoint(
    Canvas canvas,
    Offset position,
    Color color,
    double radius,
    double progress,
    bool isSelected,
  ) {
    final animatedRadius = radius * progress;

    // Draw glow effect for selected points
    if (isSelected) {
      _pointPaint
        ..color = color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(position, animatedRadius * 1.8, _pointPaint);
      _pointPaint.maskFilter = null;
    }

    // Draw outer circle
    _pointPaint
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.8;

    canvas.drawCircle(position, animatedRadius, _pointPaint);

    // Draw inner circle
    _pointPaint
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(isSelected ? 0.8 : 0.6);

    canvas.drawCircle(
        position, animatedRadius - (isSelected ? 1.0 : 1.5), _pointPaint);
  }

  double _calculatePointAnimation(int index) {
    // Progressive animation with smoother timing
    final delay = index / (data.length * 1.5);
    final duration = 1.2 / data.length;

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    // Ease-out cubic for smoother finish
    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return 1.0 - ((1.0 - t) * (1.0 - t) * (1.0 - t));
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    // Draw animated grid pattern for empty state
    final paint = Paint()
      ..color = style.gridLineColor.withOpacity(0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

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

    // Draw subtle message
    if (animation.value > 0.7) {
      _textPainter
        ..text = const TextSpan(
          text: "No data available",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout();

      _textPainter.paint(
        canvas,
        Offset(
          (size.width - _textPainter.width) / 2,
          (size.height - _textPainter.height) / 2,
        ),
      );
    }
  }

  double _getYPosition(double value) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  double _getXPosition(int index) {
    if (data.isEmpty) return chartArea.center.dx;

    final availableWidth = chartArea.width;
    const edgePadding = 10.0;

    if (data.length <= 1) return chartArea.center.dx;

    final pointSpacing =
        (availableWidth - (edgePadding * 2)) / (data.length - 1);
    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  @override
  bool shouldRepaint(covariant BloodPressureChartPainter oldDelegate) {
    // Check only things that would actually affect visualization
    final selectionChanged =
        selectedData?.startDate != oldDelegate.selectedData?.startDate ||
            selectedData?.endDate != oldDelegate.selectedData?.endDate;

    // Optimize repaint conditions
    if (selectionChanged &&
        data == oldDelegate.data &&
        chartArea == oldDelegate.chartArea) {
      return true;
    }

    return data != oldDelegate.data ||
        chartArea != oldDelegate.chartArea ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        animation.value != oldDelegate.animation.value;
  }
}
