// lib/o2_saturation/widgets/o2_saturation_graph.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../../utils/empty_state_overlay.dart';
import 'models/o2_saturation_data.dart';
import 'models/processed_o2_saturation_data.dart';
import 'painters/o2_saturation_chart_painter.dart';
import 'services/chart_calculations.dart';
import 'services/data_processor.dart';
import 'styles/o2_saturation_chart_style.dart';
import 'widgets/o2_saturation_tooltip.dart';

class O2SaturationGraph extends StatefulWidget {
  final List<O2SaturationData> data;
  final O2SaturationChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedO2SaturationData)? onDataPointTap;
  final Function(ProcessedO2SaturationData)? onTooltipTap;

  const O2SaturationGraph({
    Key? key,
    required this.data,
    this.style = const O2SaturationChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onViewTypeChanged,
    this.onDataPointTap,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<O2SaturationGraph> createState() => _O2SaturationGraphState();
}

class _O2SaturationGraphState extends State<O2SaturationGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late ChartViewConfig _currentConfig;
  late List<ProcessedO2SaturationData> _processedData;
  ProcessedO2SaturationData? _selectedData;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.initialConfig;
    _processData();
    _initializeAnimation();
  }

  void _processData() {
    _processedData = O2SaturationDataProcessor.processData(
      widget.data,
      _currentConfig.viewType,
      _currentConfig.startDate,
      _calculateEndDate(_currentConfig.startDate, _currentConfig.viewType),
      zoomLevel: _currentConfig.zoomLevel,
    );
  }

  DateTime _calculateEndDate(DateTime startDate, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        return startDate.add(const Duration(days: 1));
      case DateRangeType.week:
        return startDate.add(const Duration(days: 6));
      case DateRangeType.month:
        return DateTime(startDate.year, startDate.month + 1, 0);
      case DateRangeType.year:
        return DateTime(startDate.year + 1, 1, 0);
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

  void updateConfig(ChartViewConfig newConfig) {
    if (_currentConfig == newConfig) return;

    setState(() {
      _currentConfig = newConfig;
      _processData();
      // Restart animation for better visual feedback
      _animationController.reset();
      _animationController.forward();
    });

    widget.onViewTypeChanged?.call(newConfig.viewType);
  }

  @override
  void didUpdateWidget(O2SaturationGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool needsUpdate = false;

    if (!_listEquals(widget.data, oldWidget.data)) {
      needsUpdate = true;
    }

    if (widget.initialConfig != oldWidget.initialConfig) {
      _currentConfig = widget.initialConfig;
      needsUpdate = true;
    }

    if (needsUpdate) {
      _processData();
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    // For performance, only check first and last elements
    if (a.isNotEmpty && b.isNotEmpty) {
      if (a.first != b.first || a.last != b.last) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: O2SaturationChartContent(
          data: _processedData,
          style: widget.style,
          config: _currentConfig,
          height: widget.height,
          animation: _animation,
          selectedData: _selectedData,
          onDataPointTap: (data) {
            setState(() {
              _selectedData = data;
            });
            widget.onDataPointTap?.call(data);
          },
          onTooltipTap: widget.onTooltipTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class O2SaturationChartContent extends StatefulWidget {
  final List<ProcessedO2SaturationData> data;
  final O2SaturationChartStyle style;
  final ChartViewConfig config;
  final double height;
  final Animation<double> animation;
  final ProcessedO2SaturationData? selectedData;
  final Function(ProcessedO2SaturationData)? onDataPointTap;
  final Function(ProcessedO2SaturationData)? onTooltipTap;

  const O2SaturationChartContent({
    Key? key,
    required this.data,
    required this.style,
    required this.config,
    this.height = 300,
    required this.animation,
    this.selectedData,
    this.onDataPointTap,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<O2SaturationChartContent> createState() =>
      _O2SaturationChartContentState();
}

class _O2SaturationChartContentState extends State<O2SaturationChartContent> {
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
          _chartArea = O2ChartCalculations.calculateChartArea(size);
          final (yAxisValues, minValue, maxValue) =
              O2ChartCalculations.calculateYAxisRange(widget.data);
          _yAxisValues = yAxisValues;
          _minValue = minValue;
          _maxValue = maxValue;
          _lastDataHash = newDataHash;
        });
      }
    }
  }

  String _calculateDataHash() {
    return '${widget.data.length}_${widget.config.zoomLevel}';
  }

  void _showTooltip(ProcessedO2SaturationData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final screenSize = MediaQuery.of(context).size;
    final tooltipSize = Size(280, _calculateTooltipHeight(data));

    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = _calculateTooltipPosition(
      globalPosition,
      tooltipSize,
      screenSize,
      MediaQuery.of(context).padding,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: tooltipPosition.dx,
        top: tooltipPosition.dy,
        child: O2SaturationTooltip(
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

  double _calculateTooltipHeight(ProcessedO2SaturationData data) {
    const baseHeight = 120.0;
    const measurementHeight = 24.0;
    final measurementsCount = data.originalMeasurements.length;

    return baseHeight + (measurementHeight * measurementsCount.clamp(0, 5));
  }

  Offset _calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets padding,
  ) {
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 10;

    // Ensure tooltip stays within horizontal bounds
    x = x.clamp(
      padding.left,
      screenSize.width - tooltipSize.width - padding.right,
    );

    // If tooltip would go above screen, show it below the tap point
    if (y < padding.top) {
      y = tapPosition.dy + 10;
    }

    // Ensure tooltip stays within vertical bounds
    y = y.clamp(
      padding.top,
      screenSize.height - tooltipSize.height - padding.bottom,
    );

    return Offset(x, y);
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
    final closestPoint = O2ChartCalculations.findDataPoint(
        localPosition, _chartArea!, widget.data);

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
    bool allZeros = widget.data
        .every((dataPoint) => (dataPoint.maxValue == 0 || dataPoint.isEmpty));

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
            painter: O2SaturationChartPainter(
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
            child: EmptyStateOverlay(
              message: 'No O2 saturation data available',
              icon: Icons.monitor_heart_outlined,
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: O2SaturationChartPainter(
        data: widget.data,
        style: widget.style,
        config: widget.config,
        animation: widget.animation,
        chartArea: _chartArea!,
        yAxisValues: _yAxisValues!,
        minValue: _minValue!,
        maxValue: _maxValue!,
        selectedData: widget.selectedData,
      ),
    );
  }

  @override
  void didUpdateWidget(O2SaturationChartContent oldWidget) {
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
