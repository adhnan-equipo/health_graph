import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../controllers/base_chart_controller.dart';
import '../models/base_chart_style.dart';
import '../services/base_data_processor.dart';
import '../widgets/universal_tooltip.dart';

/// Universal chart factory for creating new chart types with minimal code
/// Future new graphs can be created in ~50 lines instead of 500+!
class ChartFactory {
  /// Create a complete chart widget for any data type
  static Widget
      createChart<TData, TProcessedData, TStyle extends BaseChartStyle>({
    required List<TData> data,
    required ChartViewConfig config,
    required TStyle style,
    required String chartTitle,
    required List<TProcessedData> Function(
            List<TData>, DateRangeType, DateTime, DateTime,
            {double zoomLevel})
        dataProcessor,
    required DateTime Function(TData) getDataDate,
    required DateTime Function(TProcessedData) getProcessedStartDate,
    required DateTime Function(TProcessedData)? getProcessedEndDate,
    required Widget Function(TProcessedData) buildTooltipContent,
    required List<dynamic> Function(List<TProcessedData>) calculateYAxisValues,
    required double Function(List<TProcessedData>) getMinValue,
    required double Function(List<TProcessedData>) getMaxValue,
    required CustomPainter Function(
            List<TProcessedData>,
            TStyle,
            ChartViewConfig,
            Animation<double>,
            Rect,
            List<dynamic>,
            double,
            double,
            TProcessedData?)
        createPainter,
  }) {
    return _UniversalChartWidget<TData, TProcessedData, TStyle>(
      data: data,
      config: config,
      style: style,
      chartTitle: chartTitle,
      dataProcessor: dataProcessor,
      getDataDate: getDataDate,
      getProcessedStartDate: getProcessedStartDate,
      getProcessedEndDate: getProcessedEndDate,
      buildTooltipContent: buildTooltipContent,
      calculateYAxisValues: calculateYAxisValues,
      getMinValue: getMinValue,
      getMaxValue: getMaxValue,
      createPainter: createPainter,
    );
  }

  /// Create a simple chart controller for any data type
  static BaseChartController<TData, TProcessedData>
      createController<TData, TProcessedData>({
    required List<TData> data,
    required ChartViewConfig config,
    required List<TProcessedData> Function(
            List<TData>, DateRangeType, DateTime, DateTime,
            {double zoomLevel})
        dataProcessor,
    required DateTime Function(TData) getDataDate,
  }) {
    return _UniversalController<TData, TProcessedData>(
      data: data,
      config: config,
      dataProcessor: dataProcessor,
      getDataDate: getDataDate,
    );
  }

  /// Create chart-specific data processor wrapper
  static List<TProcessedData> Function(
          List<TData>, DateRangeType, DateTime, DateTime, {double zoomLevel})
      createDataProcessor<TData, TProcessedData>({
    required TProcessedData Function(
            List<TData>, DateTime, DateTime, DateRangeType)
        processGroup,
    required TProcessedData Function(DateTime, DateTime, DateRangeType)
        createEmpty,
    required DateTime Function(TData) getDataDate,
    required List<TProcessedData> Function(List<TProcessedData>, int)
        aggregateData,
  }) {
    return (data, dateRangeType, startDate, endDate, {double zoomLevel = 1.0}) {
      return BaseDataProcessor.processData<TProcessedData, TData>(
        data,
        dateRangeType,
        startDate,
        endDate,
        zoomLevel: zoomLevel,
        processDataGroup: processGroup,
        createEmpty: createEmpty,
        getDataDate: getDataDate,
        aggregateData: aggregateData,
      );
    };
  }
}

/// Universal chart widget - handles all common chart functionality
class _UniversalChartWidget<TData, TProcessedData,
    TStyle extends BaseChartStyle> extends StatefulWidget {
  final List<TData> data;
  final ChartViewConfig config;
  final TStyle style;
  final String chartTitle;
  final List<TProcessedData> Function(
          List<TData>, DateRangeType, DateTime, DateTime, {double zoomLevel})
      dataProcessor;
  final DateTime Function(TData) getDataDate;
  final DateTime Function(TProcessedData) getProcessedStartDate;
  final DateTime Function(TProcessedData)? getProcessedEndDate;
  final Widget Function(TProcessedData) buildTooltipContent;
  final List<dynamic> Function(List<TProcessedData>) calculateYAxisValues;
  final double Function(List<TProcessedData>) getMinValue;
  final double Function(List<TProcessedData>) getMaxValue;
  final CustomPainter Function(
      List<TProcessedData>,
      TStyle,
      ChartViewConfig,
      Animation<double>,
      Rect,
      List<dynamic>,
      double,
      double,
      TProcessedData?) createPainter;

  const _UniversalChartWidget({
    required this.data,
    required this.config,
    required this.style,
    required this.chartTitle,
    required this.dataProcessor,
    required this.getDataDate,
    required this.getProcessedStartDate,
    required this.getProcessedEndDate,
    required this.buildTooltipContent,
    required this.calculateYAxisValues,
    required this.getMinValue,
    required this.getMaxValue,
    required this.createPainter,
  });

  @override
  State<_UniversalChartWidget<TData, TProcessedData, TStyle>> createState() =>
      _UniversalChartWidgetState<TData, TProcessedData, TStyle>();
}

class _UniversalChartWidgetState<TData, TProcessedData,
        TStyle extends BaseChartStyle>
    extends State<_UniversalChartWidget<TData, TProcessedData, TStyle>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  TProcessedData? _selectedData;
  List<TProcessedData> _processedData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _processData();
    _animationController.forward();
  }

  void _processData() {
    _processedData = widget.dataProcessor(
      widget.data,
      widget.config.viewType,
      widget.config.startDate,
      widget.config.endDate,
      zoomLevel: widget.config.zoomLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartArea =
        Rect.fromLTRB(40, 10, MediaQuery.of(context).size.width - 10, 200);
    final yAxisValues = widget.calculateYAxisValues(_processedData);
    final minValue = widget.getMinValue(_processedData);
    final maxValue = widget.getMaxValue(_processedData);

    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: widget.createPainter(
            _processedData,
            widget.style,
            widget.config,
            _animation,
            chartArea,
            yAxisValues,
            minValue,
            maxValue,
            _selectedData,
          ),
        ),
        if (_selectedData != null)
          Positioned.fill(
            child: UniversalTooltip<TProcessedData, TStyle>(
              data: _selectedData!,
              viewType: widget.config.viewType,
              onClose: () => setState(() => _selectedData = null),
              style: widget.style,
              screenSize: MediaQuery.of(context).size,
              title: widget.chartTitle,
              buildContent: widget.buildTooltipContent,
              getStartDate: widget.getProcessedStartDate,
              getEndDate: widget.getProcessedEndDate,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Universal controller implementation
class _UniversalController<TData, TProcessedData>
    extends BaseChartController<TData, TProcessedData> {
  final List<TProcessedData> Function(
          List<TData>, DateRangeType, DateTime, DateTime, {double zoomLevel})
      _dataProcessor;
  final DateTime Function(TData) _getDataDate;

  _UniversalController({
    required List<TData> data,
    required ChartViewConfig config,
    required List<TProcessedData> Function(
            List<TData>, DateRangeType, DateTime, DateTime,
            {double zoomLevel})
        dataProcessor,
    required DateTime Function(TData) getDataDate,
  })  : _dataProcessor = dataProcessor,
        _getDataDate = getDataDate,
        super(data: data, config: config);

  @override
  List<TProcessedData> processDataImpl(
    List<TData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dataProcessor(sortedData, viewType, startDate, endDate);
  }

  @override
  DateTime getDataDate(TData data) {
    return _getDataDate(data);
  }
}

/*
USAGE EXAMPLE: Creating a new chart type in ~50 lines!
===============================================

// Define your data model
class TemperatureData {
  final DateTime date;
  final double temperature;
  // ... other fields
}

class ProcessedTemperatureData {
  final DateTime startDate;
  final double avgTemp;
  // ... other fields
}

// Create the complete chart in ~20 lines:
Widget temperatureChart = ChartFactory.createChart<TemperatureData, ProcessedTemperatureData, MyChartStyle>(
  data: temperatureData,
  config: chartConfig,
  style: temperatureStyle,
  chartTitle: 'Temperature',
  dataProcessor: myDataProcessor,
  getDataDate: (data) => data.date,
  getProcessedStartDate: (data) => data.startDate,
  buildTooltipContent: (data) => Text('Temp: ${data.avgTemp}°C'),
  calculateYAxisValues: (data) => [0, 10, 20, 30, 40],
  getMinValue: (data) => 0,
  getMaxValue: (data) => 40,
  createPainter: (data, style, config, animation, chartArea, yAxis, min, max, selected) =>
    MyTemperaturePainter(...), // Only ~30 lines needed!
);

TOTAL: New chart type in ~50 lines instead of 500+!
*/
