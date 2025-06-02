// lib/sleep/controllers/sleep_chart_controller.dart
import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_data.dart';
import '../services/sleep_data_processor.dart';

class SleepChartController extends ChangeNotifier {
  List<SleepData> _data;
  ChartViewConfig _config;
  ProcessedSleepData? _selectedData;
  List<ProcessedSleepData> _processedData = [];
  double _baseScaleFactor = 1.0;

  SleepChartController({
    required List<SleepData> data,
    required ChartViewConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  // Getters
  ChartViewConfig get config => _config;

  List<ProcessedSleepData> get processedData => _processedData;

  ProcessedSleepData? get selectedData => _selectedData;

  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    // Sort data by date
    final sortedData = List<SleepData>.from(_data)
      ..sort((a, b) => a.createDate.compareTo(b.createDate));

    // Calculate date range based on view type
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

    _processedData = SleepDataProcessor.processData(
      sortedData,
      _config.viewType,
      startDate,
      endDate,
    );

    notifyListeners();
  }

  void updateConfig(ChartViewConfig newConfig) {
    if (_config == newConfig) return;
    _config = newConfig;
    _processData();
  }

  void updateData(List<SleepData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedSleepData? data) {
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
}
