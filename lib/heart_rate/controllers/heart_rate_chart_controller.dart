// lib/controllers/heart_rate_chart_controller.dart
import 'package:flutter/material.dart';

import '../models/heart_rate_chart_config.dart';
import '../models/heart_rate_data.dart';
import '../models/processed_heart_rate_data.dart';
import '../services/heart_rate_data_processor.dart';

class HeartRateChartController extends ChangeNotifier {
  List<HeartRateData> _data;
  HeartRateChartConfig _config;
  ProcessedHeartRateData? _selectedData;
  List<ProcessedHeartRateData> _processedData = [];

  HeartRateChartController({
    required List<HeartRateData> data,
    required HeartRateChartConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  // Getters
  HeartRateChartConfig get config => _config;
  List<ProcessedHeartRateData> get processedData => _processedData;
  ProcessedHeartRateData? get selectedData => _selectedData;

  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    // Sort data by date
    final sortedData = List<HeartRateData>.from(_data)
      ..sort((a, b) => a.date.compareTo(b.date));

    _processedData = HeartRateDataProcessor.processData(
      sortedData,
      _config.viewType,
      _config.startDate,
      _config.endDate,
      zoomLevel: _config.zoomLevel,
    );

    notifyListeners();
  }

  void updateConfig(HeartRateChartConfig newConfig) {
    if (_config == newConfig) return;
    _config = newConfig;
    _processData();
  }

  void updateData(List<HeartRateData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedHeartRateData? data) {
    if (_selectedData == data) return;
    _selectedData = data;
    notifyListeners();
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void dispose() {
    super.dispose();
  }
}

// Extension for calculating square root
extension DoubleExtension on double {
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double y = 1;
    double epsilon = 0.000001;
    while ((x - y) > epsilon) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
