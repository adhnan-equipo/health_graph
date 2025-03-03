// lib/o2_saturation/widgets/o2_saturation_graph.dart
import 'package:flutter/material.dart';

import '/o2_saturation/painters/o2_saturation_chart_painter.dart';
import '../utils/chart_view_config.dart';
import 'controllers/chart_controller.dart';
import 'models/o2_saturation_data.dart';
import 'models/processed_o2_saturation_data.dart';
import 'styles/o2_saturation_chart_style.dart';
import 'widgets/o2_saturation_tooltip.dart';

class O2SaturationGraph extends StatefulWidget {
  final List<O2SaturationData> data;
  final O2SaturationChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Function(ProcessedO2SaturationData?)? onDataSelected;
  final Function(ProcessedO2SaturationData)? onDataPointTap;
  final Function(ProcessedO2SaturationData)? onTooltipTap;
  final Function(ProcessedO2SaturationData)? onLongPress;

  const O2SaturationGraph({
    Key? key,
    required this.data,
    this.style = const O2SaturationChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onDataSelected,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<O2SaturationGraph> createState() => _O2SaturationGraphState();
}

class _O2SaturationGraphState extends State<O2SaturationGraph>
    with SingleTickerProviderStateMixin {
  late final O2ChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controller = O2ChartController(
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

  void _handleControllerUpdate() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(O2SaturationGraph oldWidget) {
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
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) => _buildChart(constraints),
        ),
      ),
    );
  }

  Widget _buildChart(BoxConstraints constraints) {
    return O2SaturationChartContent(
      data: _controller.processedData,
      style: widget.style,
      initialConfig: _controller.config,
      height: widget.height,
      animation: _animation,
      selectedData: _controller.selectedData,
      onDataSelected: _handleDataSelected,
      onDataPointTap: widget.onDataPointTap,
      onTooltipTap: widget.onTooltipTap,
      onLongPress: widget.onLongPress,
    );
  }

  void _handleDataSelected(ProcessedO2SaturationData? data) {
    if (!_isDisposed) {
      _controller.selectData(data);
      widget.onDataSelected?.call(data);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// lib/o2_saturation/widgets/o2_saturation_chart_content.dart
class O2SaturationChartContent extends StatefulWidget {
  final List<ProcessedO2SaturationData> data;
  final O2SaturationChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Animation<double> animation;
  final ProcessedO2SaturationData? selectedData;
  final Function(ProcessedO2SaturationData?)? onDataSelected;
  final Function(ProcessedO2SaturationData)? onDataPointTap;
  final Function(ProcessedO2SaturationData)? onTooltipTap;
  final Function(ProcessedO2SaturationData)? onLongPress;

  const O2SaturationChartContent({
    Key? key,
    required this.data,
    required this.style,
    required this.initialConfig,
    this.height = 300,
    required this.animation,
    this.selectedData,
    this.onDataSelected,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
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
  Offset? _lastTapPosition;
  OverlayEntry? _tooltipOverlay;

  void _showTooltip(ProcessedO2SaturationData data, Offset position) {
    try {
      _hideTooltip();

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final globalPosition = renderBox.localToGlobal(position);
      final screenSize = MediaQuery.of(context).size;

      _tooltipOverlay = OverlayEntry(
        builder: (context) => O2SaturationTooltip(
          data: data,
          viewType: widget.initialConfig.viewType,
          position: globalPosition,
          onClose: _hideTooltip,
          style: widget.style,
          screenSize: screenSize,
          onTooltipTap: widget.onTooltipTap,
        ),
      );

      Overlay.of(context).insert(_tooltipOverlay!);
    } catch (e) {
      debugPrint('Error showing tooltip: $e');
    }
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _handleTap(Offset position) {
    if (_chartArea == null) return;

    try {
      final selectedData = ChartCalculations.findDataPoint(
        position,
        _chartArea!,
        widget.data,
      );

      if (selectedData != null) {
        _lastTapPosition = position;
        widget.onDataSelected?.call(selectedData);
        widget.onDataPointTap?.call(selectedData);
        _showTooltip(selectedData, position);
      } else {
        _hideTooltip();
        widget.onDataSelected?.call(null);
      }
    } catch (e) {
      debugPrint('Error handling tap: $e');
      _hideTooltip();
      widget.onDataSelected?.call(null);
    }
  }

  void _handleLongPress(Offset position) {
    if (_chartArea == null) return;

    try {
      final selectedData = ChartCalculations.findDataPoint(
        position,
        _chartArea!,
        widget.data,
      );

      if (selectedData != null) {
        widget.onLongPress?.call(selectedData);
      }
    } catch (e) {
      debugPrint('Error handling long press: $e');
    }
  }

  @override
  void initState() {
    super.initState();
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
          _chartArea = _calculateChartArea(size);
          _yAxisValues = ChartCalculations.calculateYAxisValues(widget.data);
          _minValue = _yAxisValues?.first.toDouble();
          _maxValue = _yAxisValues?.last.toDouble();
        });
      }
    }
  }

  Rect _calculateChartArea(Size size) {
    const leftPadding = 30.0;
    const rightPadding = 20.0;
    const topPadding = 20.0;
    const bottomPadding = 30.0;
    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          if (_isPointInChartArea(localPosition, renderBox.size)) {
            _handleTap(localPosition);
          }
        }
      },
      onLongPressStart: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          _handleLongPress(localPosition);
        }
      },
      child: RepaintBoundary(
        child: SizedBox(
          key: _chartKey,
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          child: _buildChart(),
        ),
      ),
    );
  }

  bool _isPointInChartArea(Offset position, Size size) {
    return position.dx >= 0 &&
        position.dx <= size.width &&
        position.dy >= 0 &&
        position.dy <= size.height;
  }

  Widget _buildChart() {
    if (_chartArea == null ||
        _yAxisValues == null ||
        _minValue == null ||
        _maxValue == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomPaint(
      painter: O2SaturationChartPainter(
        data: widget.data,
        style: widget.style,
        config: widget.initialConfig,
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
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
