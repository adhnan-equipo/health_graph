// lib/sleep/widgets/sleep_graph.dart
import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../controllers/sleep_chart_controller.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_data.dart';
import '../styles/sleep_chart_style.dart';
import 'sleep_chart_content.dart';

class SleepGraph extends StatefulWidget {
  final List<SleepData> data;
  final SleepChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final Function(ProcessedSleepData?)? onDataSelected;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedSleepData)? onDataPointTap;
  final Function(ProcessedSleepData)? onTooltipTap;
  final Function(ProcessedSleepData)? onLongPress;

  const SleepGraph({
    Key? key,
    required this.data,
    this.style = const SleepChartStyle(),
    required this.initialConfig,
    this.height = 300,
    this.onDataSelected,
    this.onViewTypeChanged,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<SleepGraph> createState() => _SleepGraphState();
}

class _SleepGraphState extends State<SleepGraph>
    with SingleTickerProviderStateMixin {
  late final SleepChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controller = SleepChartController(
      data: widget.data,
      config: widget.initialConfig,
    );

    _animationController = AnimationController(
      duration: widget.style.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.style.animationCurve,
    );

    _controller.addListener(_handleControllerUpdate);
    _animationController.forward();
  }

  void _handleControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(SleepGraph oldWidget) {
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
    if (a.isNotEmpty && b.isNotEmpty) {
      if (a.first != b.first || a.last != b.last) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onScaleStart: _controller.handleScaleStart,
        onScaleUpdate: _controller.handleScaleUpdate,
        child: Container(
          height: widget.height,
          constraints: BoxConstraints(
            minHeight: widget.height,
            maxHeight: widget.height,
          ),
          child: SleepChartContent(
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

  void _handleDataSelected(ProcessedSleepData? data) {
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
