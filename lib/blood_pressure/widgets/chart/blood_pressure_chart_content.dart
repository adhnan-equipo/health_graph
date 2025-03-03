// lib/blood_pressure/widgets/chart/blood_pressure_chart_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Drawer/blood_pressure_chart_painter.dart';
import '../../models/chart_view_config.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../services/chart_calculations.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'chart_tooltip.dart';

class BloodPressureChartContent extends StatefulWidget {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig config;
  final double height;
  final Animation<double> animation;
  final ProcessedBloodPressureData? selectedData;
  final List<(int min, int max)> referenceRanges;
  final Function(ProcessedBloodPressureData?)? onDataSelected;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;
  final Function(ProcessedBloodPressureData)? onLongPress;

  const BloodPressureChartContent({
    Key? key,
    required this.data,
    required this.style,
    required this.config,
    this.height = 300,
    required this.animation,
    this.selectedData,
    required this.referenceRanges,
    this.onDataSelected,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
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
  ProcessedBloodPressureData? _lastSelectedData;

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
          _chartArea = ChartCalculations.calculateChartArea(size);
          final (yAxisValues, minValue, maxValue) =
              ChartCalculations.calculateYAxisRange(
                  widget.data, widget.referenceRanges);
          _yAxisValues = yAxisValues;
          _minValue = minValue;
          _maxValue = maxValue;
          _lastDataHash = newDataHash;

          // Mark cache as needing rebuild since chart dimensions changed
          _hitTestCacheNeedsRebuild = true;
        });
      }
    }
  }

  // More efficient hash calculation
  String _calculateDataHash() {
    final buffer = StringBuffer();
    buffer.write(widget.data.length);
    buffer.write('_');
    buffer.write(widget.config.zoomLevel);
    buffer.write('_');
    buffer.write(widget.referenceRanges.length);

    // Only include critical data for hashing
    if (widget.data.isNotEmpty) {
      buffer.write('_');
      buffer.write(widget.data.first.hashCode);
      buffer.write('_');
      buffer.write(widget.data.last.hashCode);
    }

    return buffer.toString();
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
          // rangeData: _getRangeData(data),
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

  // Cached nearby data points to avoid expensive filtering on every tooltip display
  final Map<ProcessedBloodPressureData, List<ProcessedBloodPressureData>>
      _rangeDataCache = {};

  List<ProcessedBloodPressureData> _getRangeData(
      ProcessedBloodPressureData data) {
    // Check cache first
    if (_rangeDataCache.containsKey(data)) {
      return _rangeDataCache[data]!;
    }

    // Filter data points within time range
    final results = widget.data.where((measurement) {
      return measurement.startDate
              .isAfter(data.startDate.subtract(const Duration(minutes: 1))) &&
          measurement.startDate
              .isBefore(data.endDate.add(const Duration(minutes: 1)));
    }).toList();

    // Cache results
    _rangeDataCache[data] = results;

    return results;
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  // Cached map from x-positions to data points for fast hit testing
  final Map<int, (double x, ProcessedBloodPressureData data)> _hitTestCache =
      {};
  bool _hitTestCacheNeedsRebuild = true;

  void _rebuildHitTestCache() {
    if (_chartArea == null) return;

    _hitTestCache.clear();

    // Build a spatial index for faster hit testing
    for (int i = 0; i < widget.data.length; i++) {
      final entry = widget.data[i];
      if (entry.isEmpty) continue;

      final x = ChartCalculations.calculateXPosition(
          i, widget.data.length, _chartArea!);

      // Round to integer for faster lookups later
      final xKey = x.round();
      _hitTestCache[xKey] = (x, entry);
    }

    _hitTestCacheNeedsRebuild = false;
  }

  void _handleTapUp(TapUpDetails details) {
    if (_chartArea == null) return;

    final localPosition = details.localPosition;

    // Check if tap is in chart area
    if (!_isPointInChartArea(localPosition)) return;

    // Rebuild cache if needed
    if (_hitTestCacheNeedsRebuild) {
      _rebuildHitTestCache();
    }

    // Fast hit test using spatial index
    ProcessedBloodPressureData? closestPoint;
    double minXDistance = double.infinity;
    // Reduced hit test threshold for better precision
    const hitTestThreshold = 30.0;

    // Search within a reasonable pixel range around the tap point
    final searchRange = 30;
    final targetX = localPosition.dx.round();

    for (int offset = 0; offset <= searchRange; offset++) {
      // Check points on both sides of tap point
      for (final xKey in [targetX + offset, targetX - offset]) {
        final entry = _hitTestCache[xKey];
        if (entry != null) {
          final (x, data) = entry;
          final xDistance = (localPosition.dx - x).abs();

          if (xDistance < minXDistance && xDistance < hitTestThreshold) {
            minXDistance = xDistance;
            closestPoint = data;
          }
        }
      }

      // Early exit if found a close point
      if (minXDistance < 15.0) break;
    }

    // Only update if selection actually changed
    if (closestPoint != _lastSelectedData) {
      // Provide haptic feedback only when selection changes
      HapticFeedback.selectionClick();

      _lastSelectedData = closestPoint;

      // Call callback to update parent's state
      widget.onDataSelected?.call(closestPoint);

      if (closestPoint != null) {
        widget.onDataPointTap?.call(closestPoint);
        _showTooltip(closestPoint, localPosition);
      } else {
        _hideTooltip();
      }
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (_chartArea == null) return;

    final localPosition = details.localPosition;
    if (!_isPointInChartArea(localPosition)) return;

    final selectedData = ChartCalculations.findDataPoint(
      localPosition,
      _chartArea!,
      widget.data,
    );

    if (selectedData != null) {
      widget.onLongPress?.call(selectedData);
    }
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
    return GestureDetector(
      onTapUp: _handleTapUp,
      onLongPressStart: _handleLongPressStart,
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

    if (widget.data.isEmpty) {
      return Stack(
        children: [
          CustomPaint(
            painter: BloodPressureChartPainter(
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
          ),
          const EmptyStateOverlay(),
        ],
      );
    }

    return CustomPaint(
      painter: BloodPressureChartPainter(
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
  void didUpdateWidget(BloodPressureChartContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if data-affecting properties changed
    final dataChanged = widget.data != oldWidget.data;
    final configChanged = widget.config != oldWidget.config;
    final rangesChanged = widget.referenceRanges != oldWidget.referenceRanges;

    // Only recalculate dimensions if data-affecting properties changed
    if (dataChanged || configChanged || rangesChanged) {
      _initializeChartDimensions();

      // Clear caches when data changes
      if (dataChanged) {
        _rangeDataCache.clear();
        _hitTestCacheNeedsRebuild = true;
      }
    }

    // Handle selection change separately without full recalculation
    if (widget.selectedData != oldWidget.selectedData) {
      // No need to rebuild everything on selection change
      _lastSelectedData = widget.selectedData;
    }

    // Handle animation changes separately
    if (widget.animation != oldWidget.animation) {
      // Animation changed but we don't need to rebuild dimensions
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}

class EmptyStateOverlay extends StatelessWidget {
  const EmptyStateOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
