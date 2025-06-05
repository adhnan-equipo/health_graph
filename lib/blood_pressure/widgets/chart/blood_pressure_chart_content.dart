import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/utils/chart_calculations.dart';
import '../../../shared/widgets/empty_state_overlay.dart';
import '../../../utils/chart_view_config.dart';
import '../../Drawer/blood_pressure_chart_painter.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'chart_tooltip.dart';

class BloodPressureChartContent extends StatefulWidget {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig config;
  final double height;
  final Animation<double> animation;
  final List<(int min, int max)> referenceRanges;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;

  const BloodPressureChartContent({
    Key? key,
    required this.data,
    required this.style,
    required this.config,
    this.height = 300,
    required this.animation,
    required this.referenceRanges,
    this.onDataPointTap,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<BloodPressureChartContent> createState() =>
      _BloodPressureChartContentState();
}

class _BloodPressureChartContentState extends State<BloodPressureChartContent> {
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
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
          // Extract values for axis calculation
          final allValues = <int>[];
          for (var point in widget.data) {
            if (!point.isEmpty) {
              allValues.addAll([
                point.minSystolic,
                point.maxSystolic,
                point.minDiastolic,
                point.maxDiastolic,
              ]);
            }
          }

          // Add reference range values
          for (var range in widget.referenceRanges) {
            allValues.addAll([range.$1, range.$2]);
          }

          final (yAxisValues, minValue, maxValue) =
              SharedChartCalculations.calculateIntegerYAxisRange(allValues);
          _yAxisValues = yAxisValues;
          _minValue = minValue;
          _maxValue = maxValue;
          _lastDataHash = newDataHash;
        });
      }
    }
  }

  String _calculateDataHash() {
    return '${widget.data.length}_${widget.config.zoomLevel}_${widget.referenceRanges.length}';
  }

  void _showTooltip(ProcessedBloodPressureData data, Offset position) {
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
        child: ChartTooltip(
          data: data,
          rangeData: _getRangeData(data),
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

  double _calculateTooltipHeight(ProcessedBloodPressureData data) {
    const baseHeight = 120.0;
    const measurementHeight = 24.0;
    final measurementsCount = data.originalMeasurements.length;

    return baseHeight + (measurementHeight * measurementsCount.clamp(0, 5));
  }

  List<ProcessedBloodPressureData> _getRangeData(
      ProcessedBloodPressureData data) {
    return widget.data.where((measurement) {
      return measurement.startDate
              .isAfter(data.startDate.subtract(const Duration(minutes: 1))) &&
          measurement.startDate
              .isBefore(data.endDate.add(const Duration(minutes: 1)));
    }).toList();
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

    // Find closest data point based on x-axis proximity only
    ProcessedBloodPressureData? closestPoint;
    double minXDistance = double.infinity;
    const hitTestThreshold = 40.0;

    for (int i = 0; i < widget.data.length; i++) {
      final entry = widget.data[i];
      if (entry.isEmpty) continue;

      final x = SharedChartCalculations.calculateXPosition(
          i, widget.data.length, _chartArea!);
      final xDistance = (localPosition.dx - x).abs();

      if (xDistance < minXDistance && xDistance < hitTestThreshold) {
        minXDistance = xDistance;
        closestPoint = entry;
      }
    }

    if (closestPoint != null) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      widget.onDataPointTap?.call(closestPoint);
      _showTooltip(closestPoint, localPosition);
    } else {
      _hideTooltip();
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
        (dataPoint.maxSystolic == 0 || dataPoint.isEmpty) &&
        (dataPoint.maxDiastolic == 0 || dataPoint.isEmpty));

    return allZeros;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTapUp,
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
            painter: BloodPressureChartPainter(
              data: const [], // Use empty list for painter to properly draw grid
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
          const Center(
            child: SharedEmptyStateOverlay(
              message: 'No blood pressure data available',
              icon: Icons.monitor_heart_outlined,
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: BloodPressureChartPainter(
        data: widget.data,
        style: widget.style,
        config: widget.config,
        animation: widget.animation,
        chartArea: _chartArea!,
        yAxisValues: _yAxisValues!,
        minValue: _minValue!,
        maxValue: _maxValue!,
      ),
    );
  }

  @override
  void didUpdateWidget(BloodPressureChartContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force update y-axis when data or view config changes
    if (widget.data != oldWidget.data ||
        widget.config != oldWidget.config ||
        widget.referenceRanges != oldWidget.referenceRanges) {
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
