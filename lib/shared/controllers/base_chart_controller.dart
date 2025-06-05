import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../../utils/chart_view_config.dart';

/// Base chart controller providing common functionality for all health metric charts
/// Generic implementation to reduce code duplication across chart controllers
abstract class BaseChartController<TData, TProcessedData>
    extends ChangeNotifier {
  List<TData> _data;
  ChartViewConfig _config;
  TProcessedData? _selectedData;
  List<TProcessedData> _processedData = [];
  double _baseScaleFactor = 1.0;

  BaseChartController({
    required List<TData> data,
    required ChartViewConfig config,
  })  : _data = data,
        _config = config {
    _processData();
  }

  // Getters
  ChartViewConfig get config => _config;

  List<TProcessedData> get processedData => _processedData;

  TProcessedData? get selectedData => _selectedData;

  /// Abstract method to be implemented by subclasses for data processing
  List<TProcessedData> processDataImpl(
    List<TData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  );

  /// Abstract method to get date from raw data for sorting
  DateTime getDataDate(TData data);

  /// Common data processing logic
  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    // Sort data by date
    final sortedData = List<TData>.from(_data)
      ..sort((a, b) => getDataDate(a).compareTo(getDataDate(b)));

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

    _processedData = processDataImpl(
      sortedData,
      _config.viewType,
      startDate,
      endDate,
    );

    notifyListeners();
  }

  /// Update chart configuration
  void updateConfig(ChartViewConfig newConfig) {
    if (_config == newConfig) return;
    _config = newConfig;
    _processData();
  }

  /// Update chart data
  void updateData(List<TData> newData) {
    if (_listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  /// Select data point for tooltip display
  void selectData(TProcessedData? data) {
    if (_selectedData == data) return;
    _selectedData = data;
    notifyListeners();
  }

  /// Handle scale/zoom start gesture
  void handleScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _config.zoomLevel;
  }

  /// Handle scale/zoom update gesture
  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) return;

    final newZoomLevel = (_baseScaleFactor * details.scale).clamp(1.0, 4.0);
    if (newZoomLevel != _config.zoomLevel) {
      updateConfig(_config.copyWith(zoomLevel: newZoomLevel));
    }
  }

  /// Generic list equality check
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Clear selected data
  void clearSelection() {
    selectData(null);
  }

  /// Refresh data processing
  void refreshData() {
    _processData();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
