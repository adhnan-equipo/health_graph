import 'dart:math';

import 'package:flutter/material.dart';

import '../../blood_pressure/models/chart_view_config.dart';
import '../../blood_pressure/models/date_range_type.dart';
import '../models/o2_saturation_data.dart';
import '../models/processed_o2_saturation_data.dart';
import '../services/data_processor.dart';

class O2ChartController extends ChangeNotifier {
  List<O2SaturationData> _data;
  ChartViewConfig _config;
  ProcessedO2SaturationData? _selectedData;
  List<ProcessedO2SaturationData> _processedData = [];
  double _baseScaleFactor = 1.0;

  O2ChartController({
    required List<O2SaturationData> data,
    required ChartViewConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  ChartViewConfig get config => _config;
  List<ProcessedO2SaturationData> get processedData => _processedData;
  ProcessedO2SaturationData? get selectedData => _selectedData;

  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    final sortedData = List<O2SaturationData>.from(_data)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime startDate;
    DateTime endDate;

    switch (_config.viewType) {
      case DateRangeType.day:
        startDate = DateTime(_config.startDate.year, _config.startDate.month,
            _config.startDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;

      case DateRangeType.week:
        startDate = _config.startDate;
        endDate = startDate.add(const Duration(days: 6));
        break;

      case DateRangeType.month:
        startDate =
            DateTime(_config.startDate.year, _config.startDate.month, 1);
        endDate =
            DateTime(_config.startDate.year, _config.startDate.month + 1, 0);
        break;

      case DateRangeType.year:
        startDate = DateTime(_config.startDate.year, 1, 1);
        endDate = DateTime(_config.startDate.year + 1, 1, 0);
        break;
    }

    _processedData = O2SaturationDataProcessor.processData(
      sortedData,
      _config.viewType,
      startDate,
      endDate,
      zoomLevel: _config.zoomLevel,
    );

    notifyListeners();
  }

  void updateConfig(ChartViewConfig newConfig) {
    if (_config == newConfig) return;
    _config = newConfig;
    _processData();
  }

  void updateData(List<O2SaturationData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedO2SaturationData? data) {
    if (_selectedData == data) return;
    _selectedData = data;
    notifyListeners();
  }

  void handleScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _config.zoomLevel;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) return;

    final newZoomLevel = (_baseScaleFactor * details.scale).clamp(1.0, 4.0);
    if (newZoomLevel != _config.zoomLevel) {
      updateConfig(_config.copyWith(zoomLevel: newZoomLevel));
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
    _selectedData = null;
    super.dispose();
  }
}

// lib/o2_saturation/services/chart_calculations.dart
class ChartCalculations {
  static ProcessedO2SaturationData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedO2SaturationData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    final xStep = chartArea.width / (data.length - 1);
    const hitTestThreshold = 20.0;

    for (var i = 0; i < data.length; i++) {
      final x = chartArea.left + (i * xStep);
      if ((position.dx - x).abs() <= hitTestThreshold) {
        final entry = data[i];
        if (!entry.isEmpty) {
          return entry;
        }
      }
    }

    return null;
  }

  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }

  static List<int> calculateYAxisValues(List<ProcessedO2SaturationData> data) {
    if (data.isEmpty) {
      return _generateDefaultYAxisValues();
    }

    final values = _collectValues(data);
    if (values.isEmpty) {
      return _generateDefaultYAxisValues();
    }

    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;

    var step = 5;
    if (range > 30) step = 10;
    if (range < 15) step = 2;

    var start = (minValue / step).floor() * step;
    var end = ((maxValue + step - 1) / step).ceil() * step;

    // Ensure we include critical ranges
    start = min(start, 80);
    end = max(end, 100);

    List<int> values2 = [];
    for (var i = start; i <= end; i += step) {
      values2.add(i);
    }

    return values2;
  }

  static List<double> _collectValues(List<ProcessedO2SaturationData> data) {
    return data
        .expand((d) => [d.minValue.toDouble(), d.maxValue.toDouble()])
        .where((value) => value > 0)
        .toList();
  }

  static List<int> _generateDefaultYAxisValues() {
    return [80, 85, 90, 95, 100];
  }
}
