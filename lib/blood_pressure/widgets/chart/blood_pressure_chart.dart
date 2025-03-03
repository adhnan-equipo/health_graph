import 'package:flutter/material.dart';

import '../../../models/date_range_type.dart';
import '../../../utils/chart_view_config.dart';
import '../../models/blood_pressure_data.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';
import '../../utils/data_processor.dart';
import 'blood_pressure_chart_content.dart';

class BloodPressureGraph extends StatefulWidget {
  final List<BloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig initialConfig;
  final double height;
  final List<(int min, int max)> referenceRanges;
  final Function(DateRangeType)? onViewTypeChanged;
  final Function(ProcessedBloodPressureData)? onDataPointTap;
  final Function(ProcessedBloodPressureData)? onTooltipTap;

  const BloodPressureGraph({
    Key? key,
    required this.data,
    this.style = const BloodPressureChartStyle(),
    required this.initialConfig,
    this.height = 300,
    required this.referenceRanges,
    this.onViewTypeChanged,
    this.onDataPointTap,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<BloodPressureGraph> createState() => _BloodPressureGraphState();
}

class _BloodPressureGraphState extends State<BloodPressureGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late ChartViewConfig _currentConfig;
  late List<ProcessedBloodPressureData> _processedData;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.initialConfig;
    _processData();
    _initializeAnimation();
  }

  void _processData() {
    _processedData = BloodPressureDataProcessor.processData(
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
  void didUpdateWidget(BloodPressureGraph oldWidget) {
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
      _animationController.duration = _calculateAnimationDuration();
      _animationController.forward(from: 0.0);
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
        child: BloodPressureChartContent(
          data: _processedData,
          style: widget.style,
          config: _currentConfig,
          height: widget.height,
          animation: _animation,
          referenceRanges: widget.referenceRanges,
          onDataPointTap: widget.onDataPointTap,
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
