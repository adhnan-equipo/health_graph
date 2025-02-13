// lib/bmi/widgets/bmi_chart_content.dart
import 'package:flutter/material.dart';

import '../../blood_pressure/models/chart_view_config.dart';
import '../drawer/bmi_chart_painter.dart';
import '../models/processed_bmi_data.dart';
import '../services/bmi_chart_calculations.dart';
import '../styles/bmi_chart_style.dart';
import 'bmi_tooltip.dart';

class BMIChartContent extends StatefulWidget {
  final List<ProcessedBMIData> data;
  final BMIChartStyle style;
  final ChartViewConfig initialConfig;
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
  State<BMIChartContent> createState() => _BMIChartContentState();
}

class _BMIChartContentState extends State<BMIChartContent> {
  final GlobalKey _chartKey = GlobalKey();
  Size? _chartSize;
  Rect? _chartArea;
  List<double>? _yAxisValues;
  double? _minValue;
  double? _maxValue;
  Offset? _lastTapPosition;
  OverlayEntry? _tooltipOverlay;

  void _showTooltip(ProcessedBMIData data, Offset position) {
    try {
      _hideTooltip();

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final globalPosition = renderBox.localToGlobal(position);
      final screenSize = MediaQuery.of(context).size;

      _tooltipOverlay = OverlayEntry(
        builder: (context) => BMITooltip(
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
      final selectedData = BMIChartCalculations.findDataPoint(
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
      final selectedData = BMIChartCalculations.findDataPoint(
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
          _yAxisValues = BMIChartCalculations.calculateYAxisValues(widget.data);
          _minValue = _yAxisValues?.first;
          _maxValue = _yAxisValues?.last;
        });
      }
    }
  }

  Rect _calculateChartArea(Size size) {
    const leftPadding = 30.0;
    const rightPadding = 10.0;
    const topPadding = 0.0;
    const bottomPadding = 0.0;
    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

// In BMIChartContent widget
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
        child: Container(
          key: _chartKey,
          width: MediaQuery.of(context).size.width,
          height: widget.height,
          constraints: BoxConstraints(
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
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
      painter: BMIChartPainter(
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
