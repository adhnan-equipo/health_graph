// lib/bmi/controllers/bmi_chart_controller.dart
import 'package:flutter/material.dart';

import '../../blood_pressure/models/chart_view_config.dart';
import '../../models/date_range_type.dart';
import '../models/bmi_data.dart';
import '../models/processed_bmi_data.dart';
import '../services/bmi_data_processor.dart';

class BMIChartController extends ChangeNotifier {
  List<BMIData> _data;
  ChartViewConfig _config;
  ProcessedBMIData? _selectedData;
  List<ProcessedBMIData> _processedData = [];
  double _baseScaleFactor = 1.0;

  BMIChartController({
    required List<BMIData> data,
    required ChartViewConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  // Getters
  ChartViewConfig get config => _config;
  List<ProcessedBMIData> get processedData => _processedData;
  ProcessedBMIData? get selectedData => _selectedData;

  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    // Sort data by date
    final sortedData = List<BMIData>.from(_data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate date range based on view type
    final DateTime now = DateTime.now();
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

    _processedData = BMIDataProcessor.processData(
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

  void updateData(List<BMIData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedBMIData? data) {
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
