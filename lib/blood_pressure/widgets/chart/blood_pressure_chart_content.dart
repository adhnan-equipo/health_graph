// lib/blood_pressure/widgets/chart/blood_pressure_chart_content.dart
import 'package:flutter/material.dart';

import '../../Drawer/blood_pressure_chart_painter.dart';
import '../../blood_pressure/services/chart_calculations.dart';
import '../../models/chart_view_config.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'chart_tooltip.dart';

class BloodPressureChartContent extends StatefulWidget {
  final List<ProcessedBloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Animation<double> animation;
  final ProcessedBloodPressureData? selectedData;
  final Function(ProcessedBloodPressureData?)? onDataSelected;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;
  final Function(ProcessedBloodPressureData)? onLongPress;

  const BloodPressureChartContent({
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
  Offset? _lastTapPosition;
  OverlayEntry? _tooltipOverlay;

// In BloodPressureChartContent class, update the _showTooltip method:
  void _showTooltip(ProcessedBloodPressureData data, Offset position) {
    try {
      _hideTooltip();

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final globalPosition = renderBox.localToGlobal(position);
      final screenSize = MediaQuery.of(context).size;

      // Get all measurements in the range
      final rangeData = widget.data.where((measurement) {
        return measurement.startDate
                .isAfter(data.startDate.subtract(const Duration(minutes: 1))) &&
            measurement.startDate
                .isBefore(data.endDate.add(const Duration(minutes: 1)));
      }).toList();

      _tooltipOverlay = OverlayEntry(
        builder: (context) => ChartTooltip(
          data: data,
          rangeData: rangeData,
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
    const leftPadding = 25.0;
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
      painter: BloodPressureChartPainter(
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
