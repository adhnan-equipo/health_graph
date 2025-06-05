import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/date_range_type.dart';
import '../shared/widgets/empty_state_overlay.dart';
import '../utils/tooltip_position.dart';
import 'controllers/heart_rate_chart_controller.dart';
import 'models/heart_rate_chart_config.dart';
import 'models/heart_rate_data.dart';
import 'models/processed_heart_rate_data.dart';
import 'painters/heart_rate_chart_painter.dart';
import 'services/heart_rate_data_processor.dart';
import 'styles/heart_rate_chart_style.dart';
import 'utils/heart_rate_calculations.dart';
import 'widgets/heart_rate_tooltip.dart';

class HeartRateChart extends StatefulWidget {
  /// The raw data to display in the chart
  final List<HeartRateData> data;

  /// Style configuration for the chart
  final HeartRateChartStyle style;

  /// Configuration options for the chart
  final HeartRateChartConfig config;

  /// Height of the chart
  final double height;

  /// Callback when a data point is tapped
  final Function(ProcessedHeartRateData)? onDataPointTap;

  /// Callback when the tooltip is tapped
  final Function(ProcessedHeartRateData)? onTooltipTap;

  /// Callback when the view type is changed
  final Function(DateRangeType)? onViewTypeChanged;

  /// Callback when configuration is changed
  final Function(HeartRateChartConfig)? onConfigChanged;

  /// Flag to indicate if data is still loading from source
  final bool isLoading;

  const HeartRateChart({
    Key? key,
    required this.data,
    this.style = const HeartRateChartStyle(),
    required this.config,
    this.height = 300,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onViewTypeChanged,
    this.onConfigChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart>
    with SingleTickerProviderStateMixin {
  late HeartRateChartController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey _chartKey = GlobalKey();

  // Chart dimensions and data
  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
  double? _minValue;
  double? _maxValue;
  OverlayEntry? _tooltipOverlay;
  bool _isInitialized = false;
  bool _isProcessingData = false;

  // Local state for selected data point to prevent full rebuilds
  ProcessedHeartRateData? _selectedData;

  @override
  void initState() {
    super.initState();

    // Initialize the controller
    _controller = HeartRateChartController(
      data: widget.data,
      config: widget.config,
    );

    // Initialize animation
    _initializeAnimation();

    // Process data on next frame to avoid blocking the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChart();
    });
  }

  void _initializeChart() {
    setState(() {
      _isProcessingData = true;
    });

    // Process data first
    _processData().then((_) {
      // Then initialize dimensions
      _initializeChartDimensions();
      setState(() {
        _isProcessingData = false;
        _isInitialized = true;
      });
    });
  }

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if data or config has changed
    bool needsDataUpdate = widget.data != oldWidget.data;
    bool needsConfigUpdate = widget.config != oldWidget.config;

    // Check if loading state changed
    bool loadingStateChanged = widget.isLoading != oldWidget.isLoading;

    if (needsDataUpdate) {
      _updateData(widget.data);
    }

    if (needsConfigUpdate) {
      _updateConfig(widget.config, oldWidget.config);
    }

    if (needsDataUpdate || needsConfigUpdate || loadingStateChanged) {
      // Re-render chart with new data or config
      _scheduleUpdateIfNeeded();
    }
  }

  void _updateData(List<HeartRateData> newData) {
    _controller.updateData(newData);
  }

  void _updateConfig(
      HeartRateChartConfig newConfig, HeartRateChartConfig oldConfig) {
    _controller.updateConfig(newConfig);

    // If view type changed, notify parent
    if (newConfig.viewType != oldConfig.viewType &&
        widget.onViewTypeChanged != null) {
      widget.onViewTypeChanged!(newConfig.viewType);
    }

    // If animation settings changed, update controller
    if (newConfig.enableAnimation != oldConfig.enableAnimation) {
      if (newConfig.enableAnimation) {
        _animationController.reset();
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
      }
    }
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

    if (widget.config.enableAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0; // Set to completed state
    }
  }

  Duration _calculateAnimationDuration() {
    final dataLength = widget.data.length;

    // Much faster animation for large datasets
    if (dataLength > 100) return const Duration(milliseconds: 300);

    // Medium speed for medium datasets
    if (dataLength > 50) return const Duration(milliseconds: 400);

    // Adaptive calculation for smaller datasets
    const baseMs = 300;
    const maxMs = 600;

    if (dataLength <= 20) return const Duration(milliseconds: baseMs);

    final duration = baseMs + ((dataLength - 20) * 1);
    return Duration(milliseconds: duration.clamp(baseMs, maxMs));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        key: _chartKey,
        height: widget.height,
        child: _buildChartContent(),
      ),
    );
  }

  Widget _buildChartContent() {
    // Show loading indicator only if data is being fetched
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.style.primaryColor),
        ),
      );
    }

    // Show temporary loading during internal processing
    if (!_isInitialized || _isProcessingData) {
      return const SizedBox
          .shrink(); // Use empty container instead of loading indicator for smoother transition
    }

    // Check for valid chart dimensions
    if (_chartArea == null ||
        _yAxisValues == null ||
        _minValue == null ||
        _maxValue == null) {
      return const SizedBox
          .shrink(); // Use empty container for smoother transition
    }

    // Check for empty data - only show empty state if we're sure there's no data
    if (_isDataEffectivelyEmpty() && !widget.isLoading && widget.data.isEmpty) {
      return _buildEmptyState();
    }

    // Build the interactive chart
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: CustomPaint(
        // Use key to optimize rebuilds
        key: ValueKey(
            'heart_rate_chart_${widget.data.hashCode}_${widget.config.hashCode}'),
        // Use RepaintBoundary to prevent unnecessary repainting
        isComplex: true,
        willChange: false,
        painter: HeartRateChartPainter(
          data: _controller.processedData,
          style: widget.style,
          animation: _animation,
          chartArea: _chartArea!,
          yAxisValues: _yAxisValues!,
          minValue: _minValue!,
          maxValue: _maxValue!,
          config: widget.config,
          selectedData: _selectedData,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        // Draw empty chart background
        CustomPaint(
          isComplex: true,
          willChange: false,
          painter: HeartRateChartPainter(
            data: const [],
            // Empty list for painter
            style: widget.style,
            animation: _animation,
            chartArea: _chartArea!,
            yAxisValues: _yAxisValues!,
            minValue: _minValue!,
            maxValue: _maxValue!,
            config: widget.config,
            selectedData: null,
          ),
        ),
        // Show empty state overlay
        SharedEmptyStateOverlay(
          message: widget.style.noDataLabel,
          icon: Icons.favorite_outline,
        ),
      ],
    );
  }

  Future<void> _scheduleUpdateIfNeeded() async {
    // Wait until the layout is ready
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    _initializeChartDimensions();

    // Only reset animation if animation is enabled
    if (widget.config.enableAnimation) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _initializeChartDimensions() {
    if (!mounted) return;

    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final size = renderBox.size;

      // Only update if size has changed or chart isn't initialized
      if (_chartSize != size || _chartArea == null) {
        setState(() {
          _chartSize = size;
          _chartArea = HeartRateChartCalculations.calculateChartArea(size);
        });
      }

      // Recalculate Y-axis values if needed
      _updateYAxisValues();
    }
  }

  void _updateYAxisValues() {
    final processedData = _controller.processedData;

    if (processedData.isNotEmpty) {
      final yAxisData = HeartRateChartCalculations.calculateYAxisRange(
        processedData,
      );

      setState(() {
        _yAxisValues = yAxisData.$1;
        _minValue = yAxisData.$2;
        _maxValue = yAxisData.$3;
      });
    } else {
      // Default values if no data
      setState(() {
        _yAxisValues = [40, 60, 80, 100, 120, 140, 160];
        _minValue = 40.0;
        _maxValue = 160.0;
      });
    }
  }

  bool _isDataEffectivelyEmpty() {
    final data = _controller.processedData;
    if (data.isEmpty) return true;

    // Check if all data points are marked as empty
    bool allEmpty = data.every((dataPoint) => dataPoint.isEmpty);
    if (allEmpty) return true;

    // Check if all data points have zero values
    bool allZeros = data.every((dataPoint) =>
        (dataPoint.maxValue == 0 || dataPoint.isEmpty) &&
        (dataPoint.avgValue == 0 || dataPoint.isEmpty));

    return allZeros;
  }

  void _handleTapDown(TapDownDetails details) {
    if (_chartArea == null || _isDataEffectivelyEmpty()) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Check if tap is within the chart area
    if (!_isPointInChartArea(localPosition)) return;

    // Find the nearest data point
    final nearestPoint = HeartRateChartCalculations.findNearestDataPoint(
      localPosition,
      _chartArea!,
      _controller.processedData,
      _minValue!,
      _maxValue!,
      hitTestThreshold: 30.0 * devicePixelRatio, // Scale by pixel ratio
    );

    if (nearestPoint != null && !nearestPoint.isEmpty) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();

      // Set selected data point locally instead of in controller
      setState(() {
        _selectedData = nearestPoint;
      });

      // Call callback
      if (widget.onDataPointTap != null) {
        widget.onDataPointTap!(nearestPoint);
      }

      // Show tooltip if enabled
      if (widget.config.showTooltips) {
        _showTooltip(nearestPoint, localPosition);
      }
    } else {
      // Clear selection if tapped on empty area
      setState(() {
        _selectedData = null;
      });
      _hideTooltip();
    }
  }

// In lib/heart_rate/heart_rate_chart.dart
  void _showTooltip(ProcessedHeartRateData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // More accurate tooltip size estimation based on content
    final baseWidth = 280.0;
    final baseHeight = 180.0;

    // Calculate additional height based on content complexity
    double additionalHeight = 0;

    // Add height for statistics section if present
    if (data.isRangeData || data.hrv != null) {
      additionalHeight += 60.0;
    }

    // Add height for resting rate if present
    if (data.restingRate != null) {
      additionalHeight += 20.0;
    }

    // Add height for measurements section if present
    if (data.originalMeasurements.length > 1) {
      additionalHeight +=
          min(24.0 + (data.originalMeasurements.length * 4.0), 60.0);
    }

    final tooltipSize = Size(baseWidth, baseHeight + additionalHeight);

    final screenSize = MediaQuery.of(context).size;
    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = TooltipPosition.calculate(
      tapPosition: globalPosition,
      tooltipSize: tooltipSize,
      screenSize: screenSize,
      safeArea: MediaQuery.of(context).padding,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => HeartRateTooltip(
        data: data,
        position: tooltipPosition,
        style: widget.style,
        onClose: _hideTooltip,
        onTooltipTap: (data) {
          if (widget.onTooltipTap != null) {
            widget.onTooltipTap!(data);
          }
          _hideTooltip();
        },
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

  Future<void> _processData() async {
    // Process data in a separate task to avoid blocking UI
    try {
      final processedData = HeartRateDataProcessor.processData(
        widget.data,
        widget.config.viewType,
        widget.config.startDate,
        widget.config.endDate,
        zoomLevel: widget.config.zoomLevel,
      );

      _controller.updateProcessedData(processedData);
    } catch (e) {
      debugPrint('Error processing heart rate data: $e');
    }

    return;
  }

  @override
  void dispose() {
    _hideTooltip();
    _animationController.dispose();
    super.dispose();
  }
}
