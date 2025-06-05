// lib/bmi/widgets/bmi_chart_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/utils/chart_calculations.dart';
import '../../shared/widgets/empty_state_overlay.dart';
import '../../utils/chart_view_config.dart';
import '../drawer/bmi_chart_painter.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';
import 'bmi_tooltip.dart';

class BMIChartContent extends StatefulWidget {
  final List<ProcessedBMIData> data;
  final BMIChartStyle style;
  final ChartViewConfig config;
  final double height;
  final Animation<double> animation;
  final ProcessedBMIData? selectedData;
  final Function(ProcessedBMIData?)? onDataSelected;
  final Function(ProcessedBMIData)? onDataPointTap;
  final Function(ProcessedBMIData)? onTooltipTap;
  final Function(ProcessedBMIData)? onLongPress;

  const BMIChartContent({
    Key? key,
    required this.data,
    required this.style,
    required this.config,
    this.height = 300,
    required this.animation,
    this.selectedData,
    this.onDataSelected,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<BMIChartContent> createState() => _BMIChartContentState();
}

class _BMIChartContentState extends State<BMIChartContent> {
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<double>? _yAxisValues;
  double? _minValue;
  double? _maxValue;
  OverlayEntry? _tooltipOverlay;

  // Cache the last calculation to prevent unnecessary updates
  String _lastDataHash = '';

  @override
  void initState() {
    super.initState();
    _scheduleInitialLayout();
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
      final newDataHash = _calculateDataHash();

      if (size != _chartSize || newDataHash != _lastDataHash) {
        setState(() {
          _chartSize = size;
          _chartArea = SharedChartCalculations.calculateChartArea(size);
          // Extract BMI values for axis calculation
          final allValues = <double>[];
          for (var point in widget.data) {
            if (!point.isEmpty) {
              allValues.addAll([point.minBMI, point.maxBMI, point.avgBMI]);
            }
          }

          final (yAxisValues, minValue, maxValue) =
              SharedChartCalculations.calculateNumericYAxisRange(allValues);
          _yAxisValues = yAxisValues;
          _minValue = minValue;
          _maxValue = maxValue;
          _lastDataHash = newDataHash;
        });
      }
    }
  }

  String _calculateDataHash() {
    return '${widget.data.length}_${widget.config.zoomLevel}_${widget.config.viewType}';
  }

  void _showTooltip(ProcessedBMIData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final screenSize = MediaQuery.of(context).size;
    final tooltipSize = Size(280, _calculateTooltipHeight(data));

    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = SharedChartCalculations.calculateTooltipPosition(
      globalPosition,
      tooltipSize,
      screenSize,
      MediaQuery.of(context).padding,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: tooltipPosition.dx,
        top: tooltipPosition.dy,
        child: BMITooltip(
          data: data,
          viewType: widget.config.viewType,
          onClose: _hideTooltip,
          style: widget.style,
          screenSize: screenSize,
          onTooltipTap: widget.onTooltipTap,
        ),
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  double _calculateTooltipHeight(ProcessedBMIData data) {
    const baseHeight = 120.0;
    const measurementHeight = 24.0;
    final measurementsCount = data.originalMeasurements.length;

    return baseHeight + (measurementHeight * measurementsCount.clamp(0, 5));
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _handleTapUp(TapUpDetails details) {
    if (_chartArea == null || _isDataEffectivelyEmpty()) return;

    final localPosition = details.localPosition;

    // Check if tap is in chart area
    if (!_isPointInChartArea(localPosition)) return;

    // Find closest data point
    final closestIndex = SharedChartCalculations.findClosestDataPointIndex(
      localPosition,
      _chartArea!,
      widget.data.length,
    );
    final closestPoint =
        closestIndex != null ? widget.data[closestIndex] : null;

    if (closestPoint != null) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      widget.onDataPointTap?.call(closestPoint);
      widget.onDataSelected?.call(closestPoint);
      _showTooltip(closestPoint, localPosition);
    } else {
      _hideTooltip();
      widget.onDataSelected?.call(null);
    }
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (_chartArea == null || _isDataEffectivelyEmpty()) return;

    final localPosition = details.localPosition;

    if (!_isPointInChartArea(localPosition)) return;

    final dataIndex = SharedChartCalculations.findClosestDataPointIndex(
        localPosition, _chartArea!, widget.data.length);
    final dataPoint = dataIndex != null ? widget.data[dataIndex] : null;

    if (dataPoint != null) {
      HapticFeedback.heavyImpact();
      widget.onLongPress?.call(dataPoint);
    }
  }

  bool _isPointInChartArea(Offset position) {
    if (_chartArea == null) return false;

    return position.dx >= _chartArea!.left &&
        position.dx <= _chartArea!.right &&
        position.dy >= _chartArea!.top &&
        position.dy <= _chartArea!.bottom;
  }

  // Check if all data points are effectively empty
  bool _isDataEffectivelyEmpty() {
    if (widget.data.isEmpty) return true;

    // Check if all data points are marked as empty
    bool allEmpty = widget.data.every((dataPoint) => dataPoint.isEmpty);
    if (allEmpty) return true;

    // Check if all data points have zero values
    bool allZeros = widget.data.every((dataPoint) =>
        (dataPoint.maxBMI == 0 || dataPoint.isEmpty) &&
        (dataPoint.minBMI == 0 || dataPoint.isEmpty));

    return allZeros;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTapUp,
      onLongPressStart: _handleLongPress,
      child: RepaintBoundary(
        child: SizedBox(
          key: _chartKey,
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          child: _buildChartContent(),
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    if (_chartArea == null ||
        _yAxisValues == null ||
        _minValue == null ||
        _maxValue == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use the improved empty data detection
    if (_isDataEffectivelyEmpty()) {
      return Stack(
        children: [
          // Draw empty chart background with grid
          CustomPaint(
            painter: BMIChartPainter(
              data: const [], // Use empty list for painter
              style: widget.style,
              config: widget.config,
              animation: widget.animation,
              chartArea: _chartArea!,
              yAxisValues: _yAxisValues!,
              minValue: _minValue!,
              maxValue: _maxValue!,
            ),
          ),
          // Draw empty state overlay with message
          Center(
            child: SharedEmptyStateOverlay(
              message: widget.style.noData,
              icon: Icons.monitor_weight_outlined,
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: BMIChartPainter(
        data: widget.data,
        style: widget.style,
        config: widget.config,
        animation: widget.animation,
        selectedData: widget.selectedData,
        chartArea: _chartArea!,
        yAxisValues: _yAxisValues!,
        minValue: _minValue!,
        maxValue: _maxValue!,
      ),
    );
  }

  @override
  void didUpdateWidget(BMIChartContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force update y-axis when data or view config changes
    if (widget.data != oldWidget.data || widget.config != oldWidget.config) {
      _lastDataHash = ''; // Reset the hash to force update
      _initializeChartDimensions();
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
