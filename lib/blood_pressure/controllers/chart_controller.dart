import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../models/blood_pressure_data.dart';
import '../models/chart_view_config.dart';
import '../models/processed_blood_pressure_data.dart';
import '../utils/data_processor.dart';

class ChartController extends ChangeNotifier {
  List<BloodPressureData> _data;
  ChartViewConfig _config;
  ProcessedBloodPressureData? _selectedData;
  List<ProcessedBloodPressureData> _processedData = [];

  ChartController({
    required List<BloodPressureData> data,
    required ChartViewConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  // Getters
  ChartViewConfig get config => _config;
  List<ProcessedBloodPressureData> get processedData => _processedData;
  ProcessedBloodPressureData? get selectedData => _selectedData;

  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    // Sort data by date
    final sortedData = List<BloodPressureData>.from(_data)
      ..sort((a, b) => a.date.compareTo(b.date));

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

    _processedData = BloodPressureDataProcessor.processData(
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

  void updateData(List<BloodPressureData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedBloodPressureData? data) {
    if (_selectedData?.startDate != data?.startDate) {
      // Compare by date instead of direct comparison
      _selectedData = data;
      notifyListeners();
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
