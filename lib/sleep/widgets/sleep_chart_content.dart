// lib/sleep/widgets/sleep_chart_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/chart_view_config.dart';
import '../../utils/empty_state_overlay.dart';
import '../drawer/sleep_chart_painter.dart';
import '../models/processed_sleep_data.dart';
import '../services/sleep_chart_calculations.dart';
import '../styles/sleep_chart_style.dart';
import 'sleep_tooltip.dart';

class SleepChartContent extends StatefulWidget {
  final List<ProcessedSleepData> data;
  final SleepChartStyle style;
  final ChartViewConfig config;
  final double height;
  final Animation<double> animation;
  final ProcessedSleepData? selectedData;
  final Function(ProcessedSleepData?)? onDataSelected;
  final Function(ProcessedSleepData)? onDataPointTap;
  final Function(ProcessedSleepData)? onTooltipTap;
  final Function(ProcessedSleepData)? onLongPress;

  const SleepChartContent({
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
  State<SleepChartContent> createState() => _SleepChartContentState();
}

class _SleepChartContentState extends State<SleepChartContent> {
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
  double? _minValue;
  double? _maxValue;
  OverlayEntry? _tooltipOverlay;

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
          _chartArea = SleepChartCalculations.calculateChartArea(size);
          final (yAxisValues, minValue, maxValue) =
              SleepChartCalculations.calculateYAxisRange(widget.data, []);
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

  void _showTooltip(ProcessedSleepData data, Offset position) {
    _hideTooltip();

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final screenSize = MediaQuery.of(context).size;
    final tooltipSize = Size(340, _calculateTooltipHeight(data));

    final globalPosition = renderBox.localToGlobal(position);
    final tooltipPosition = SleepChartCalculations.calculateTooltipPosition(
      globalPosition,
      tooltipSize,
      screenSize,
      MediaQuery.of(context).padding,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: tooltipPosition.dx,
        top: tooltipPosition.dy,
        child: SleepTooltip(
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

  double _calculateTooltipHeight(ProcessedSleepData data) {
    double baseHeight = 180.0; // Base height for main sleep info

    // Add height for sleep stages breakdown
    if (data.hasDetailedStages) {
      baseHeight += 100.0 + (data.sleepStages.length * 28.0);
    }

    // Add height for timing data
    if (data.averageBedTime != null || data.averageEfficiency != null) {
      baseHeight += 120.0;
    }

    // Add height for stats section
    baseHeight += 100.0;

    return baseHeight.clamp(200.0, 500.0);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _handleTapUp(TapUpDetails details) {
    if (_chartArea == null || _isDataEffectivelyEmpty()) return;

    final localPosition = details.localPosition;

    if (!_isPointInChartArea(localPosition)) return;

    final closestPoint = SleepChartCalculations.findDataPoint(
      localPosition,
      _chartArea!,
      widget.data,
    );

    if (closestPoint != null) {
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

    final dataPoint = SleepChartCalculations.findDataPoint(
        localPosition, _chartArea!, widget.data);

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

  bool _isDataEffectivelyEmpty() {
    if (widget.data.isEmpty) return true;
    bool allEmpty = widget.data.every((dataPoint) => dataPoint.isEmpty);
    if (allEmpty) return true;
    bool allZeroSleep = widget.data.every(
        (dataPoint) => (dataPoint.totalSleepMinutes == 0 || dataPoint.isEmpty));
    return allZeroSleep;
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

    if (_isDataEffectivelyEmpty()) {
      return Stack(
        children: [
          CustomPaint(
            painter: SleepChartPainter(
              data: const [],
              style: widget.style,
              config: widget.config,
              animation: widget.animation,
              chartArea: _chartArea!,
              yAxisValues: _yAxisValues!,
              minValue: _minValue!,
              maxValue: _maxValue!,
            ),
          ),
          Center(
            child: EmptyStateOverlay(
              message: widget.style.noDataMessage,
              icon: Icons.bedtime,
            ),
          ),
        ],
      );
    }

    return CustomPaint(
      painter: SleepChartPainter(
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
  void didUpdateWidget(SleepChartContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data != oldWidget.data || widget.config != oldWidget.config) {
      _lastDataHash = '';
      _initializeChartDimensions();
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
