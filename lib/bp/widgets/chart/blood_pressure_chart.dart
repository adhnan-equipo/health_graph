import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../blood_pressure/models/blood_pressure_data.dart';
import '../../../blood_pressure/models/blood_pressure_range.dart';
import '../../../blood_pressure/models/processed_blood_pressure_data.dart';
import '../../../bmi/services/chart_calculations.dart';
import '../../../utils/chart_view_config.dart';
import '../../Drawer/blood_pressure_chart_painter.dart';
import '../../controllers/chart_controller.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'chart_tooltip.dart';

class BloodPressureChart extends StatefulWidget {
  final List<BloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Function(ProcessedBloodPressureData?)? onDataSelected;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;

  const BloodPressureChart({
    Key? key,
    required this.data,
    this.style = const BloodPressureChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onDataSelected,
    this.onDataPointTap,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<BloodPressureChart> createState() => _BloodPressureChartState();
}

class _BloodPressureChartState extends State<BloodPressureChart>
    with SingleTickerProviderStateMixin {
  late final ChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  // Chart measurements
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
  double? _minValue;
  double? _maxValue;

  // Tooltip management
  OverlayEntry? _tooltipOverlay;
  ProcessedBloodPressureData? _lastSelectedData;

  // Gesture tracking
  bool _isDragging = false;
  int _lastDragIndex = -1;

  // Performance optimizations
  String _lastDataHash = '';
  bool _isDisposed = false;

  // Define reference ranges
  final List<(int min, int max)> _referenceRanges = [
    (
      BloodPressureRange.normalSystolicMin,
      BloodPressureRange.normalSystolicMax
    ),
    (
      BloodPressureRange.normalDiastolicMin,
      BloodPressureRange.normalDiastolicMax
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _scheduleInitialLayout();
  }

  void _initializeControllers() {
    _controller = ChartController(
      data: widget.data,
      config: widget.initialConfig,
    );

    // Smart animation duration based on data size
    _animationController = AnimationController(
      duration: _calculateAnimationDuration(),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _controller.addListener(_handleControllerUpdate);
    _animationController.forward();
  }

  Duration _calculateAnimationDuration() {
    final dataLength = widget.data.length;
    const baseMs = 500;
    const maxMs = 1200;

    // More data = slightly longer animation, but capped
    final duration = baseMs + ((dataLength - 10).clamp(0, 40) * 10);
    return Duration(milliseconds: duration.clamp(baseMs, maxMs));
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
          _chartArea = ChartCalculations.calculateChartArea(size);
          final (yAxisValues, minValue, maxValue) =
              ChartCalculations.calculateYAxisRange(
                  _controller.processedData, _referenceRanges);
          _yAxisValues = yAxisValues;
          _minValue = minValue;
          _maxValue = maxValue;
          _lastDataHash = newDataHash;
        });
      }
    }
  }

  void _handleControllerUpdate() {
    if (!_isDisposed && mounted) {
      final newDataHash = _calculateDataHash();
      if (newDataHash != _lastDataHash) {
        _initializeChartDimensions();
      }
    }
  }

  String _calculateDataHash() {
    return '${widget.data.length}_${widget.initialConfig.hashCode}_${_controller.processedData.length}';
  }

  @override
  void didUpdateWidget(BloodPressureChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldRestartAnimation = false;

    if (!_listEquals(widget.data, oldWidget.data)) {
      _controller.updateData(widget.data);
      _animationController.duration = _calculateAnimationDuration();
      shouldRestartAnimation = true;
    }

    if (widget.initialConfig != oldWidget.initialConfig) {
      _controller.updateConfig(widget.initialConfig);
      shouldRestartAnimation = true;
    }

    if (shouldRestartAnimation) {
      _animationController.forward(from: 0.0);
      _initializeChartDimensions();
    }
  }

  // Optimized equality check
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    // Check just a few items as a simple hash
    if (a.isNotEmpty && b.isNotEmpty) {
      if (a.first != b.first) return false;
      if (a.last != b.last) return false;

      // For longer lists, check middle item too
      if (a.length > 2) {
        final midIndex = a.length ~/ 2;
        if (a[midIndex] != b[midIndex]) return false;
      }
    }

    return true; // Likely the same list if we got here
  }

  void _showTooltip(ProcessedBloodPressureData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final screenSize = MediaQuery.of(context).size;
    final tooltipSize = Size(280, _calculateTooltipHeight(data));

    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = ChartCalculations.calculateTooltipPosition(
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
          viewType: widget.initialConfig.viewType,
          onClose: _hideTooltip,
          style: widget.style,
          screenSize: screenSize,
          onTooltipTap: widget.onTooltipTap,
          // Pass additional data for richer tooltips
          dataContext: _getRangeData(data),
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
    return _controller.processedData.where((measurement) {
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
    if (_chartArea == null || _controller.processedData.isEmpty) return;

    final localPosition = details.localPosition;
    if (!_isPointInChartArea(localPosition)) return;

    final dataPoint = _findNearestDataPoint(localPosition);

    if (dataPoint != null && dataPoint != _lastSelectedData) {
      HapticFeedback.selectionClick();
      _lastSelectedData = dataPoint;

      _controller.selectData(dataPoint);
      widget.onDataSelected?.call(dataPoint);
      widget.onDataPointTap?.call(dataPoint);

      _showTooltip(dataPoint, localPosition);
    } else if (dataPoint == null) {
      _hideTooltip();
      _controller.selectData(null);
      widget.onDataSelected?.call(null);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (_chartArea == null || _controller.processedData.isEmpty) return;

    _isDragging = true;
    _lastDragIndex = -1;

    // Hide tooltip during drag for better performance
    _hideTooltip();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _chartArea == null || _controller.processedData.isEmpty)
      return;

    final localPosition = details.localPosition;
    if (!_isPointInChartArea(localPosition)) return;

    // Find nearest point based on X axis only
    final index = _getNearestDataPointIndex(localPosition);

    // Only update if we've moved to a new point
    if (index >= 0 &&
        index < _controller.processedData.length &&
        index != _lastDragIndex) {
      _lastDragIndex = index;
      final dataPoint = _controller.processedData[index];

      if (!dataPoint.isEmpty) {
        HapticFeedback.selectionClick();
        _lastSelectedData = dataPoint;

        _controller.selectData(dataPoint);
        widget.onDataSelected?.call(dataPoint);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    // Show tooltip for final selection
    if (_lastDragIndex >= 0 &&
        _lastDragIndex < _controller.processedData.length) {
      final dataPoint = _controller.processedData[_lastDragIndex];
      if (!dataPoint.isEmpty && _chartArea != null) {
        final pointX = _getXPositionForIndex(_lastDragIndex);
        final pointY = _chartArea!.center.dy;
        _showTooltip(dataPoint, Offset(pointX, pointY));
      }
    }
  }

  ProcessedBloodPressureData? _findNearestDataPoint(Offset position) {
    if (_controller.processedData.isEmpty) return null;

    final index = _getNearestDataPointIndex(position);
    if (index < 0 || index >= _controller.processedData.length) return null;

    final dataPoint = _controller.processedData[index];
    return dataPoint.isEmpty ? null : dataPoint;
  }

  int _getNearestDataPointIndex(Offset position) {
    if (_chartArea == null || _controller.processedData.isEmpty) return -1;

    // Use X position to find the nearest data point
    final relativeX = position.dx - _chartArea!.left;
    final pointSpacing = _chartArea!.width /
        (_controller.processedData.length - 1).clamp(1, double.infinity);
    final estimatedIndex = (relativeX / pointSpacing).round();

    return estimatedIndex.clamp(0, _controller.processedData.length - 1);
  }

  double _getXPositionForIndex(int index) {
    if (_chartArea == null || _controller.processedData.isEmpty) {
      return 0;
    }

    if (_controller.processedData.length <= 1) {
      return _chartArea!.center.dx;
    }

    final pointSpacing =
        _chartArea!.width / (_controller.processedData.length - 1);
    return _chartArea!.left + (index * pointSpacing);
  }

  bool _isPointInChartArea(Offset position) {
    if (_chartArea == null) return false;

    return position.dx >= _chartArea!.left &&
        position.dx <= _chartArea!.right &&
        position.dy >= _chartArea!.top &&
        position.dy <= _chartArea!.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) => _buildChartWithGestures(),
        ),
      ),
    );
  }

  Widget _buildChartWithGestures() {
    return GestureDetector(
      onTapUp: _handleTapUp,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: SizedBox(
        key: _chartKey,
        width: MediaQuery.of(context).size.width,
        height: widget.height,
        child: _buildChartContent(),
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

    return CustomPaint(
      painter: BloodPressureChartPainter(
        data: _controller.processedData,
        style: widget.style,
        config: _controller.config,
        animation: _animation,
        selectedData: _controller.selectedData,
        chartArea: _chartArea!,
        yAxisValues: _yAxisValues!,
        minValue: _minValue!,
        maxValue: _maxValue!,
      ),
      child: _controller.processedData.isEmpty
          ? const Center(
              child: Text(
                "No data available",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideTooltip();
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
