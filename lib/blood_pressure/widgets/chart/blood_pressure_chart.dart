// lib/blood_pressure/widgets/chart/blood_pressure_graph.dart
import 'package:flutter/material.dart';

import '../../../models/date_range_type.dart';
import '../../controllers/chart_controller.dart';
import '../../models/blood_pressure_data.dart';
import '../../models/chart_view_config.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'blood_pressure_chart_content.dart';

class BloodPressureGraph extends StatefulWidget {
  final List<BloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final List<(int min, int max)> referenceRanges;
  final Function(ProcessedBloodPressureData?)? onDataSelected;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;
  final Function(ProcessedBloodPressureData)? onLongPress;

  const BloodPressureGraph({
    Key? key,
    required this.data,
    this.style = const BloodPressureChartStyle(),
    required this.initialConfig,
    this.height = 300,
    required this.referenceRanges,
    this.onDataSelected,
    this.onViewTypeChanged,
    this.onDataPointTap,
    this.onTooltipTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<BloodPressureGraph> createState() => _BloodPressureGraphState();
}

class _BloodPressureGraphState extends State<BloodPressureGraph>
    with SingleTickerProviderStateMixin {
  late final ChartController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  bool _isDisposed = false;
  String _lastDataHash = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controller = ChartController(
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
    const maxMs = 1000;

    if (dataLength <= 50) return const Duration(milliseconds: baseMs);

    final duration = baseMs + ((dataLength - 50) * 2);
    return Duration(milliseconds: duration.clamp(baseMs, maxMs));
  }

  void _handleControllerUpdate() {
    if (!_isDisposed && mounted) {
      final newDataHash = _calculateDataHash();
      if (newDataHash != _lastDataHash) {
        setState(() {
          _lastDataHash = newDataHash;
        });
      }
    }
  }

  String _calculateDataHash() {
    return widget.data.length.toString() +
        widget.initialConfig.zoomLevel.toString() +
        _controller.processedData.length.toString();
  }

  @override
  void didUpdateWidget(BloodPressureGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_listEquals(widget.data, oldWidget.data)) {
      _controller.updateData(widget.data);
      _animationController.duration = _calculateAnimationDuration();
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
    return BloodPressureChartContent(
      data: _controller.processedData,
      style: widget.style,
      config: _controller.config,
      height: widget.height,
      animation: _animation,
      selectedData: _controller.selectedData,
      referenceRanges: widget.referenceRanges,
      onDataSelected: _handleDataSelected,
      onDataPointTap: widget.onDataPointTap,
      onTooltipTap: widget.onTooltipTap,
      onLongPress: widget.onLongPress,
    );
  }

  void _handleDataSelected(ProcessedBloodPressureData? data) {
    if (!_isDisposed) {
      _controller.selectData(data);

      // Restart animation to force redraw
      if (data != null) {
        _animationController.reset();
        _animationController.forward();
      }

      widget.onDataSelected?.call(data);

      // Force rebuild
      if (mounted) {
        setState(() {});
      }
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
