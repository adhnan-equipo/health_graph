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

  // Cache to optimize performance
  String _dataHash = '';

  // Stats for UI display
  double? _avgSystolic;
  double? _avgDiastolic;
  int? _minSystolic;
  int? _maxSystolic;
  int? _minDiastolic;
  int? _maxDiastolic;

  ChartController({
    required List<BloodPressureData> data,
    required ChartViewConfig config,
  })  : _data = List.from(data),
        _config = config {
    _processData();
  }

  // Getters
  ChartViewConfig get config => _config;
  List<ProcessedBloodPressureData> get processedData => _processedData;
  ProcessedBloodPressureData? get selectedData => _selectedData;

  // Stats getters
  double get avgSystolic => _avgSystolic ?? 0;
  double get avgDiastolic => _avgDiastolic ?? 0;
  int get minSystolic => _minSystolic ?? 0;
  int get maxSystolic => _maxSystolic ?? 0;
  int get minDiastolic => _minDiastolic ?? 0;
  int get maxDiastolic => _maxDiastolic ?? 0;

  // Data processing methods
  void _processData() {
    if (_data.isEmpty) {
      _processedData = [];
      _resetStats();
      notifyListeners();
      return;
    }

    // Sort data by date for consistent processing
    final sortedData = List<BloodPressureData>.from(_data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate date range based on view type
    final (startDate, endDate) = _calculateDateRange();

    // Process the data with zoom level consideration
    _processedData = BloodPressureDataProcessor.processData(
      sortedData,
      _config.viewType,
      startDate,
      endDate,
      zoomLevel: _config.zoomLevel,
    );

    // Calculate overall statistics from processed data
    _calculateStats();

    notifyListeners();
  }

  void _resetStats() {
    _avgSystolic = null;
    _avgDiastolic = null;
    _minSystolic = null;
    _maxSystolic = null;
    _minDiastolic = null;
    _maxDiastolic = null;
  }

  void _calculateStats() {
    if (_processedData.isEmpty) {
      _resetStats();
      return;
    }

    // Filter out empty data points
    final validData = _processedData.where((d) => !d.isEmpty).toList();
    if (validData.isEmpty) {
      _resetStats();
      return;
    }

    // Calculate extremes
    _minSystolic =
        validData.map((d) => d.minSystolic).reduce((a, b) => a < b ? a : b);
    _maxSystolic =
        validData.map((d) => d.maxSystolic).reduce((a, b) => a > b ? a : b);
    _minDiastolic =
        validData.map((d) => d.minDiastolic).reduce((a, b) => a < b ? a : b);
    _maxDiastolic =
        validData.map((d) => d.maxDiastolic).reduce((a, b) => a > b ? a : b);

    // Calculate weighted averages
    int totalPoints = validData.fold(0, (sum, d) => sum + d.dataPointCount);
    if (totalPoints == 0) {
      _avgSystolic = null;
      _avgDiastolic = null;
    } else {
      _avgSystolic = validData.fold(
              0.0, (sum, d) => sum + (d.avgSystolic * d.dataPointCount)) /
          totalPoints;
      _avgDiastolic = validData.fold(
              0.0, (sum, d) => sum + (d.avgDiastolic * d.dataPointCount)) /
          totalPoints;
    }
  }

  (DateTime, DateTime) _calculateDateRange() {
    DateTime startDate;
    DateTime endDate;

    switch (_config.viewType) {
      case DateRangeType.day:
        startDate = DateTime(_config.startDate.year, _config.startDate.month,
            _config.startDate.day);
        endDate = DateTime(
            startDate.year, startDate.month, startDate.day, 23, 59, 59);
        break;

      case DateRangeType.week:
        startDate = _config.startDate;
        endDate =
            startDate.add(const Duration(days: 6, hours: 23, minutes: 59));
        break;

      case DateRangeType.month:
        startDate =
            DateTime(_config.startDate.year, _config.startDate.month, 1);
        endDate = DateTime(
            _config.startDate.year, _config.startDate.month + 1, 0, 23, 59, 59);
        break;

      case DateRangeType.year:
        startDate = DateTime(_config.startDate.year, 1, 1);
        endDate = DateTime(_config.startDate.year, 12, 31, 23, 59, 59);
        break;
    }

    return (startDate, endDate);
  }

  // Public methods
  void updateConfig(ChartViewConfig newConfig) {
    if (_config == newConfig) return;
    _config = newConfig;
    _processData();
  }

  void updateData(List<BloodPressureData> newData) {
    // Check if data is actually different
    final newHash = _calculateDataHash(newData);
    if (newHash == _dataHash) return;

    _dataHash = newHash;
    _data = List.from(newData);
    _processData();

    // Clear selection when data changes
    if (_selectedData != null) {
      _selectedData = null;
      notifyListeners();
    }
  }

  void selectData(ProcessedBloodPressureData? data) {
    // Only update and notify if selection actually changed
    final bool hasChanged = _selectedData?.startDate != data?.startDate ||
        _selectedData?.endDate != data?.endDate;

    if (hasChanged) {
      _selectedData = data;
      notifyListeners();
    }
  }

  // Helper methods
  String _calculateDataHash(List<BloodPressureData> data) {
    if (data.isEmpty) return 'empty';

    // Generate a simple hash based on first, middle and last items
    final buffer = StringBuffer();
    buffer.write(data.first.date.millisecondsSinceEpoch);

    if (data.length > 2) {
      final midIndex = data.length ~/ 2;
      buffer.write('_${data[midIndex].date.millisecondsSinceEpoch}');
    }

    buffer.write('_${data.last.date.millisecondsSinceEpoch}');
    buffer.write('_${data.length}');

    return buffer.toString();
  }

  // Time range navigation
  void navigateToNext() {
    DateTime newStartDate;

    switch (_config.viewType) {
      case DateRangeType.day:
        newStartDate = _config.startDate.add(const Duration(days: 1));
        break;
      case DateRangeType.week:
        newStartDate = _config.startDate.add(const Duration(days: 7));
        break;
      case DateRangeType.month:
        newStartDate = DateTime(
          _config.startDate.year,
          _config.startDate.month + 1,
          _config.startDate.day,
        );
        break;
      case DateRangeType.year:
        newStartDate = DateTime(
          _config.startDate.year + 1,
          _config.startDate.month,
          _config.startDate.day,
        );
        break;
    }

    DateTime newEndDate = _calculateEndDate(newStartDate, _config.viewType);

    updateConfig(_config.copyWith(
      startDate: newStartDate,
      endDate: newEndDate,
    ));
  }

  void navigateToPrevious() {
    DateTime newStartDate;

    switch (_config.viewType) {
      case DateRangeType.day:
        newStartDate = _config.startDate.subtract(const Duration(days: 1));
        break;
      case DateRangeType.week:
        newStartDate = _config.startDate.subtract(const Duration(days: 7));
        break;
      case DateRangeType.month:
        newStartDate = DateTime(
          _config.startDate.year,
          _config.startDate.month - 1,
          _config.startDate.day,
        );
        break;
      case DateRangeType.year:
        newStartDate = DateTime(
          _config.startDate.year - 1,
          _config.startDate.month,
          _config.startDate.day,
        );
        break;
    }

    DateTime newEndDate = _calculateEndDate(newStartDate, _config.viewType);

    updateConfig(_config.copyWith(
      startDate: newStartDate,
      endDate: newEndDate,
    ));
  }

  DateTime _calculateEndDate(DateTime startDate, DateRangeType viewType) {
    switch (viewType) {
      case DateRangeType.day:
        return DateTime(
            startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case DateRangeType.week:
        return startDate.add(const Duration(days: 6, hours: 23, minutes: 59));
      case DateRangeType.month:
        return DateTime(startDate.year, startDate.month + 1, 0, 23, 59, 59);
      case DateRangeType.year:
        return DateTime(startDate.year, 12, 31, 23, 59, 59);
    }
  }

  void changeViewType(DateRangeType newViewType) {
    if (_config.viewType == newViewType) return;

    final currentDate = _config.startDate;
    final newEndDate = _calculateEndDate(currentDate, newViewType);

    updateConfig(_config.copyWith(
      viewType: newViewType,
      endDate: newEndDate,
    ));
  }
}
