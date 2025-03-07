// lib/heart_rate/controllers/heart_rate_chart_controller.dart
import 'package:flutter/material.dart';

import '../../models/date_range_type.dart';
import '../models/heart_rate_chart_config.dart';
import '../models/heart_rate_data.dart';
import '../models/processed_heart_rate_data.dart';
import '../services/heart_rate_data_processor.dart';
import '../utils/collection_utils.dart';

class HeartRateChartController extends ChangeNotifier {
  List<HeartRateData> _data;
  HeartRateChartConfig _config;
  ProcessedHeartRateData? _selectedData;
  List<ProcessedHeartRateData> _processedData = [];
  bool _isProcessing = false;

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

  bool get isProcessing => _isProcessing;

  // Flag to indicate if data should be reprocessed
  bool get shouldReprocessData {
    if (_processedData.isEmpty && _data.isNotEmpty) return true;
    return false;
  }

  Future<void> _processData() async {
    if (_data.isEmpty) {
      _processedData = [];
      notifyListeners();
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Process data in a separate isolate or microtask to avoid UI jank
      await Future.microtask(() {
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
      });
    } catch (e) {
      debugPrint('Error processing heart rate data: $e');
      _processedData = [];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void updateConfig(HeartRateChartConfig newConfig) {
    // Check if any properties that would affect data processing have changed
    bool requiresReprocessing = _config.viewType != newConfig.viewType ||
        _config.startDate != newConfig.startDate ||
        _config.endDate != newConfig.endDate ||
        _config.zoomLevel != newConfig.zoomLevel;

    if (_config == newConfig) return;

    _config = newConfig;

    if (requiresReprocessing) {
      _processData();
    } else {
      // Just notify listeners for UI updates if only display options changed
      notifyListeners();
    }
  }

  void updateData(List<HeartRateData> newData) {
    if (CollectionUtils.listEquals(_data, newData)) return;
    _data = newData;
    _processData();
  }

  void selectData(ProcessedHeartRateData? data) {
    if (_selectedData == data) return;
    _selectedData = data;
    notifyListeners();
  }

  void toggleOption(String optionName, bool value) {
    switch (optionName) {
      case 'showGrid':
        updateConfig(_config.copyWith(showGrid: value));
        break;
      case 'showLabels':
        updateConfig(_config.copyWith(showLabels: value));
        break;
      case 'showRanges':
        updateConfig(_config.copyWith(showRanges: value));
        break;
      case 'showAverage':
        updateConfig(_config.copyWith(showAverage: value));
        break;
      case 'showRestingRate':
        updateConfig(_config.copyWith(showRestingRate: value));
        break;
      case 'showHRV':
        updateConfig(_config.copyWith(showHRV: value));
        break;
      case 'showTrendLine':
        updateConfig(_config.copyWith(showTrendLine: value));
        break;
      case 'showZones':
        updateConfig(_config.copyWith(showZones: value));
        break;
      default:
        debugPrint('Unknown option: $optionName');
    }
  }

  void setDateRange(DateRangeType viewType, DateTime startDate) {
    final endDate = HeartRateChartConfig.calculateEndDate(startDate, viewType);
    updateConfig(_config.copyWith(
      viewType: viewType,
      startDate: startDate,
      endDate: endDate,
    ));
  }

  void zoomIn() {
    final newZoomLevel = (_config.zoomLevel * 1.25).clamp(0.5, 3.0);
    updateConfig(_config.copyWith(zoomLevel: newZoomLevel));
  }

  void zoomOut() {
    final newZoomLevel = (_config.zoomLevel / 1.25).clamp(0.5, 3.0);
    updateConfig(_config.copyWith(zoomLevel: newZoomLevel));
  }

  void resetZoom() {
    updateConfig(_config.copyWith(zoomLevel: 1.0));
  }

  // Get summary statistics for current data
  HeartRateSummary get summary {
    if (_processedData.isEmpty) {
      return HeartRateSummary.empty();
    }

    final validData = _processedData.where((d) => !d.isEmpty).toList();
    if (validData.isEmpty) {
      return HeartRateSummary.empty();
    }

    // Calculate average, min, max from all valid data points
    final avgValues = validData.map((d) => d.avgValue).toList();
    final minValues = validData.map((d) => d.minValue).toList();
    final maxValues = validData.map((d) => d.maxValue).toList();
    final restingValues = validData
        .where((d) => d.restingRate != null)
        .map((d) => d.restingRate!)
        .toList();
    final hrvValues =
        validData.where((d) => d.hrv != null).map((d) => d.hrv!).toList();

    // Calculate the average of all data points
    final avgHeartRate = avgValues.isEmpty
        ? 0
        : avgValues.reduce((a, b) => a + b) / avgValues.length;

    // Calculate min and max
    final minHeartRate =
        minValues.isEmpty ? 0 : minValues.reduce((a, b) => a < b ? a : b);
    final maxHeartRate =
        maxValues.isEmpty ? 0 : maxValues.reduce((a, b) => a > b ? a : b);

    // Calculate average resting rate and HRV if available
    final avgRestingRate = restingValues.isEmpty
        ? null
        : restingValues.reduce((a, b) => a + b) / restingValues.length;

    final avgHRV = hrvValues.isEmpty
        ? null
        : hrvValues.reduce((a, b) => a + b) / hrvValues.length;

    return HeartRateSummary(
      avgHeartRate: avgHeartRate.toDouble(),
      minHeartRate: minHeartRate,
      maxHeartRate: maxHeartRate,
      avgRestingRate: avgRestingRate,
      avgHRV: avgHRV,
      totalReadings: validData.fold(0, (sum, d) => sum + d.dataPointCount),
      latestReading: validData.isNotEmpty ? validData.last : null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void updateProcessedData(List<ProcessedHeartRateData> data) {
    _processedData = data;
    notifyListeners();
  }
}

class HeartRateSummary {
  final double avgHeartRate;
  final int minHeartRate;
  final int maxHeartRate;
  final double? avgRestingRate;
  final double? avgHRV;
  final int totalReadings;
  final ProcessedHeartRateData? latestReading;

  const HeartRateSummary({
    required this.avgHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    this.avgRestingRate,
    this.avgHRV,
    required this.totalReadings,
    this.latestReading,
  });

  factory HeartRateSummary.empty() {
    return const HeartRateSummary(
      avgHeartRate: 0,
      minHeartRate: 0,
      maxHeartRate: 0,
      totalReadings: 0,
    );
  }

  bool get isEmpty => totalReadings == 0;

  // Convenience getters
  String get formattedAvg => avgHeartRate.toStringAsFixed(1);

  String get formattedRange => '$minHeartRate-$maxHeartRate';

  String get formattedResting =>
      avgRestingRate != null ? avgRestingRate!.toStringAsFixed(1) : 'N/A';

  String get formattedHRV =>
      avgHRV != null ? avgHRV!.toStringAsFixed(1) : 'N/A';
}
