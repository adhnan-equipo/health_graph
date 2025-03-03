// lib/bmi/widgets/bmi_graph.dart
import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../controllers/bmi_chart_controller.dart';
import '../models/bmi_data.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';
import 'bmi_chart_content.dart';

class BMIGraph extends StatefulWidget {
  final List<BMIData> data;
  final BMIChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Function(ProcessedBMIData?)? onDataSelected;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedBMIData)? onDataPointTap;
  final Function(ProcessedBMIData)? onTooltipTap;
  final Function(ProcessedBMIData)? onLongPress;

  const BMIGraph({
    Key? key,
    required this.data,
    this.style = const BMIChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onDataSelected,
    this.onViewTypeChanged,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<BMIGraph> createState() => _BMIGraphState();
}

class _BMIGraphState extends State<BMIGraph>
    with SingleTickerProviderStateMixin {
  late final BMIChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controller = BMIChartController(
      data: widget.data,
      config: widget.initialConfig,
    );

    _animationController = AnimationController(
      duration: _calculateAnimationDuration(),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _controller.addListener(_handleControllerUpdate);
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

  void _handleControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(BMIGraph oldWidget) {
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

    // For performance, only check first, last and sample middle elements
    if (a.isNotEmpty && b.isNotEmpty) {
      if (a.first != b.first || a.last != b.last) {
        return false;
      }

      // Check a middle element if list is big enough
      if (a.length > 10) {
        final middleIndex = a.length ~/ 2;
        if (a[middleIndex] != b[middleIndex]) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        // Add zoom gesture support
        onScaleStart: _controller.handleScaleStart,
        onScaleUpdate: _controller.handleScaleUpdate,
        child: Container(
          height: widget.height,
          constraints: BoxConstraints(
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
          child: BMIChartContent(
            data: _controller.processedData,
            style: widget.style,
            config: _controller.config,
            height: widget.height,
            animation: _animation,
            selectedData: _controller.selectedData,
            onDataSelected: _handleDataSelected,
            onDataPointTap: widget.onDataPointTap,
            onTooltipTap: widget.onTooltipTap,
            onLongPress: widget.onLongPress,
          ),
        ),
      ),
    );
  }

  void _handleDataSelected(ProcessedBMIData? data) {
    _controller.selectData(data);
    widget.onDataSelected?.call(data);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
