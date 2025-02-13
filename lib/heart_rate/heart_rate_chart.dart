// heart_rate_chart.dart
import 'package:flutter/material.dart';

import '/heart_rate/painters/heart_rate_chart_painter.dart';
import '/heart_rate/styles/heart_rate_chart_style.dart';
import '/heart_rate/utils/heart_rate_calculations.dart';
import '/heart_rate/widgets/heart_rate_tooltip.dart';
import '../models/date_range_type.dart';
import 'controllers/heart_rate_chart_controller.dart';
import 'models/heart_rate_chart_config.dart';
import 'models/heart_rate_data.dart';
import 'models/processed_heart_rate_data.dart';

class HeartRateChart extends StatefulWidget {
  final List<HeartRateData> data;
  final HeartRateChartStyle style;
  final HeartRateChartConfig initialConfig;
  final double height;
  final Function(ProcessedHeartRateData?)? onDataSelected;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedHeartRateData)? onDataPointTap;

  const HeartRateChart({
    Key? key,
    required this.data,
    this.style = const HeartRateChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onDataSelected,
    this.onViewTypeChanged,
    this.onDataPointTap,
  }) : super(key: key);

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart>
    with SingleTickerProviderStateMixin {
  late final HeartRateChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<int>? _yAxisValues;
  double? _minValue;
  double? _maxValue;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChartDimensions();
    });
  }

  void _initializeControllers() {
    _controller = HeartRateChartController(
      data: widget.data,
      config: widget.initialConfig,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _controller.addListener(_handleControllerUpdate);
    _animationController.forward();
  }

  void _initializeChartDimensions() {
    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      setState(() {
        _chartSize = size;
        _chartArea = _calculateChartArea(size);
        _yAxisValues =
            ChartCalculations.calculateYAxisValues(_controller.processedData);
        _minValue = _yAxisValues?.first.toDouble();
        _maxValue = _yAxisValues?.last.toDouble();
      });
    }
  }

  Rect _calculateChartArea(Size size) {
    const leftPadding = 30.0; // Increased for y-axis labels
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0; // Increased for x-axis labels

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  void _handleControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_chartArea == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final selectedData = ChartCalculations.findDataPoint(
      localPosition,
      _chartArea!,
      _controller.processedData,
    );

    if (selectedData != null) {
      _showTooltip(selectedData, localPosition);
      widget.onDataSelected?.call(selectedData);
      widget.onDataPointTap?.call(selectedData);
    } else {
      _hideTooltip();
      widget.onDataSelected?.call(null);
    }
  }

  OverlayEntry? _tooltipOverlay;

  void _showTooltip(ProcessedHeartRateData data, Offset position) {
    _hideTooltip();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final globalPosition = renderBox.localToGlobal(position);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => HeartRateTooltip(
        data: data,
        position: globalPosition,
        screenSize: size,
        style: widget.style,
        // config: widget.initialConfig,
        onClose: _hideTooltip,
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        // Add ClipRect to prevent overflow
        child: SizedBox(
          key: _chartKey,
          height: widget.height,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_chartArea == null ||
                    _yAxisValues == null ||
                    _minValue == null ||
                    _maxValue == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return CustomPaint(
                  size: Size(constraints.maxWidth, widget.height),
                  painter: HeartRateChartPainter(
                    data: _controller.processedData,
                    style: widget.style,
                    config: widget.initialConfig,
                    animation: _animation,
                    selectedData: _controller.selectedData,
                    chartArea: _chartArea!,
                    yAxisValues: _yAxisValues!,
                    minValue: _minValue!,
                    maxValue: _maxValue!,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(HeartRateChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_listEquals(widget.data, oldWidget.data)) {
      _controller.updateData(widget.data);
      _animationController.forward(from: 0.0);
    }

    if (widget.initialConfig != oldWidget.initialConfig) {
      _controller.updateConfig(widget.initialConfig);
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _hideTooltip();
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
