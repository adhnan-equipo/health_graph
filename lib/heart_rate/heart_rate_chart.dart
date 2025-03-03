// lib/heart_rate/widgets/heart_rate_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/date_range_type.dart';
import '../../utils/empty_state_overlay.dart';
import 'models/heart_rate_chart_config.dart';
import 'models/heart_rate_data.dart';
import 'models/processed_heart_rate_data.dart';
import 'painters/heart_rate_chart_painter.dart';
import 'services/heart_rate_data_processor.dart';
import 'styles/heart_rate_chart_style.dart';
import 'utils/heart_rate_calculations.dart';
import 'widgets/heart_rate_tooltip.dart';

class HeartRateChart extends StatefulWidget {
  final List<HeartRateData> data;
  final HeartRateChartStyle style;
  final HeartRateChartConfig config;
  final double height;
  final Function(ProcessedHeartRateData)? onDataPointTap;
  final Function(ProcessedHeartRateData)? onTooltipTap;
  final Function(DateRangeType)? onViewTypeChanged;

  const HeartRateChart({
    Key? key,
    required this.data,
    this.style = const HeartRateChartStyle(),
    required this.config,
    this.height = 300,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onViewTypeChanged,
  }) : super(key: key);

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late List<ProcessedHeartRateData> _processedData;
  final GlobalKey _chartKey = GlobalKey();

  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
  double? _minValue;
  double? _maxValue;
  OverlayEntry? _tooltipOverlay;
  ProcessedHeartRateData? _selectedData;

  @override
  void initState() {
    super.initState();
    _processData();
    _initializeAnimation();
    _scheduleInitialLayout();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        key: _chartKey,
        height: widget.height,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          child: _buildChartContent(),
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    // If chart not initialized yet, show loading indicator
    if (_chartArea == null ||
        _yAxisValues == null ||
        _minValue == null ||
        _maxValue == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // If data is empty or all zeros, show empty state
    if (_isDataEffectivelyEmpty()) {
      return Stack(
        children: [
          // Draw empty chart background
          CustomPaint(
            painter: HeartRateChartPainter(
              data: const [],
              // Empty list for background only
              style: widget.style,
              animation: _animation,
              chartArea: _chartArea!,
              yAxisValues: _yAxisValues!,
              minValue: _minValue!,
              maxValue: _maxValue!,
              showGrid: widget.config.showGrid,
              showRanges: widget.config.showRanges,
              viewType: widget.config.viewType,
            ),
          ),
          // Show empty state overlay
          const Center(
            child: EmptyStateOverlay(
              message: 'No heart rate data available',
              icon: Icons.favorite_outline,
            ),
          ),
        ],
      );
    }

    // Draw chart with data
    return CustomPaint(
      painter: HeartRateChartPainter(
        data: _processedData,
        style: widget.style,
        animation: _animation,
        chartArea: _chartArea!,
        yAxisValues: _yAxisValues!,
        minValue: _minValue!,
        maxValue: _maxValue!,
        showGrid: widget.config.showGrid,
        showRanges: widget.config.showRanges,
        viewType: widget.config.viewType,
        selectedData: _selectedData,
      ),
    );
  }

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsUpdate = false;

    // Check if data has changed
    if (!_listEquals(widget.data, oldWidget.data)) {
      needsUpdate = true;
    }

    // Check if config has changed
    if (widget.config.viewType != oldWidget.config.viewType ||
        widget.config.startDate != oldWidget.config.startDate ||
        widget.config.endDate != oldWidget.config.endDate ||
        widget.config.zoomLevel != oldWidget.config.zoomLevel) {
      needsUpdate = true;

      // Notify parent if view type changed
      if (widget.config.viewType != oldWidget.config.viewType) {
        widget.onViewTypeChanged?.call(widget.config.viewType);
      }
    }

    if (needsUpdate) {
      _processData();
      _initializeChartDimensions();
      _animationController.forward(from: 0.0);
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    // For performance, only check a sample of elements
    if (a.length > 10) {
      // Check first, middle, and last elements
      if (a.first != b.first || a.last != b.last) {
        return false;
      }

      final middleIndex = a.length ~/ 2;
      if (a[middleIndex] != b[middleIndex]) {
        return false;
      }

      return true;
    }

    // For smaller lists, check all elements
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _hideTooltip();
    _animationController.dispose();
    super.dispose();
  }

  void _scheduleInitialLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChartDimensions();
    });
  }

  void _initializeChartDimensions() {
    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;

      if (size != _chartSize) {
        setState(() {
          _chartSize = size;
          _chartArea = HeartRateChartCalculations.calculateChartArea(size);
          final yAxisData = HeartRateChartCalculations.calculateYAxisRange(
            _processedData,
          );
          _yAxisValues = yAxisData.$1;
          _minValue = yAxisData.$2;
          _maxValue = yAxisData.$3;
        });
      }
    }
  }

  void _processData() {
    _processedData = HeartRateDataProcessor.processData(
      widget.data,
      widget.config.viewType,
      widget.config.startDate,
      widget.config.endDate,
      zoomLevel: widget.config.zoomLevel,
    );
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: _calculateAnimationDuration(),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  Duration _calculateAnimationDuration() {
    final dataLength = widget.data.length;
    const baseMs = 300;
    const maxMs = 800;

    if (dataLength <= 20) return const Duration(milliseconds: baseMs);

    final duration = baseMs + ((dataLength - 20) * 2);
    return Duration(milliseconds: duration.clamp(baseMs, maxMs));
  }

  void _handleTapDown(TapDownDetails details) {
    if (_chartArea == null || _isDataEffectivelyEmpty()) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Check if tap is within the chart area
    if (!_isPointInChartArea(localPosition)) return;

    // Find the nearest data point
    final nearestPoint = HeartRateChartCalculations.findNearestDataPoint(
      localPosition,
      _chartArea!,
      _processedData,
    );

    if (nearestPoint != null && !nearestPoint.isEmpty) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      // Set selected data point
      setState(() {
        _selectedData = nearestPoint;
      });

      // Call callback
      widget.onDataPointTap?.call(nearestPoint);

      // Show tooltip
      _showTooltip(nearestPoint, localPosition);
    } else {
      // Clear selection if tapped on empty area
      setState(() {
        _selectedData = null;
      });

      _hideTooltip();
    }
  }

  void _showTooltip(ProcessedHeartRateData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final screenSize = MediaQuery.of(context).size;
    final tooltipSize = const Size(240, 300); // Approximate size

    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = HeartRateChartCalculations.calculateTooltipPosition(
      globalPosition,
      tooltipSize,
      screenSize,
      MediaQuery.of(context).padding,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => HeartRateTooltip(
        data: data,
        position: tooltipPosition,
        style: widget.style,
        onClose: _hideTooltip,
        onTooltipTap: widget.onTooltipTap,
        viewType: widget.config.viewType,
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  bool _isPointInChartArea(Offset position) {
    if (_chartArea == null) return false;

    return position.dx >= _chartArea!.left &&
        position.dx <= _chartArea!.right &&
        position.dy >= _chartArea!.top &&
        position.dy <= _chartArea!.bottom;
  }

  bool _isDataEffectivelyEmpty() {
    if (_processedData.isEmpty) return true;

    // Check if all data points are marked as empty
    bool allEmpty = _processedData.every((dataPoint) => dataPoint.isEmpty);
    if (allEmpty) return true;

    // Check if all data points have zero values
    bool allZeros = _processedData.every((dataPoint) =>
        (dataPoint.maxValue == 0 || dataPoint.isEmpty) &&
        (dataPoint.avgValue == 0 || dataPoint.isEmpty));

    return allZeros;
  }
}
