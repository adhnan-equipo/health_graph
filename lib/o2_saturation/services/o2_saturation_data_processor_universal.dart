// lib/o2_saturation/services/o2_saturation_data_processor_universal.dart
import 'dart:math' as math;

import '../../models/date_range_type.dart';
import '../../shared/services/base_data_processor.dart';
import '../models/o2_saturation_data.dart';
import '../models/processed_o2_saturation_data.dart';

/// Universal O2 Saturation data processor - uses shared base implementation
class O2SaturationDataProcessorUniversal {
  static List<ProcessedO2SaturationData> processData(
    List<O2SaturationData> data,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return BaseDataProcessor.processData<ProcessedO2SaturationData,
        O2SaturationData>(
      data,
      viewType,
      startDate,
      endDate,
      processDataGroup: (
        List<O2SaturationData> groupedData,
        DateTime startDate,
        DateTime endDate,
        DateRangeType viewType,
      ) {
        if (groupedData.isEmpty) {
          return ProcessedO2SaturationData.empty(startDate);
        }

        final oxygenValues = groupedData.map((d) => d.o2Value).toList();
        final pulseRates = groupedData
            .where((d) => d.pulseRate != null)
            .map((d) => d.pulseRate!)
            .toList();

        final mean = oxygenValues.reduce((a, b) => a + b) / oxygenValues.length;
        final stdDev = oxygenValues.length > 1
            ? math.sqrt(oxygenValues
                    .map((v) => math.pow(v - mean, 2))
                    .reduce((a, b) => a + b) /
                (oxygenValues.length - 1))
            : 0.0;

        return ProcessedO2SaturationData(
          startDate: startDate,
          endDate: endDate,
          minValue: oxygenValues.reduce((a, b) => a < b ? a : b),
          maxValue: oxygenValues.reduce((a, b) => a > b ? a : b),
          avgValue: mean,
          stdDev: stdDev,
          dataPointCount: groupedData.length,
          minPulseRate: pulseRates.isNotEmpty
              ? pulseRates.reduce((a, b) => a < b ? a : b)
              : null,
          maxPulseRate: pulseRates.isNotEmpty
              ? pulseRates.reduce((a, b) => a > b ? a : b)
              : null,
          avgPulseRate: pulseRates.isNotEmpty
              ? pulseRates.reduce((a, b) => a + b) / pulseRates.length
              : null,
          originalMeasurements: groupedData,
        );
      },
      createEmpty:
          (DateTime startDate, DateTime endDate, DateRangeType viewType) {
        return ProcessedO2SaturationData.empty(startDate);
      },
      getDataDate: (data) => data.date,
      aggregateData: (List<ProcessedO2SaturationData> data, int targetLength) {
        if (data.length <= targetLength) return data;

        final step = data.length / targetLength;
        final result = <ProcessedO2SaturationData>[];

        for (int i = 0; i < targetLength; i++) {
          final index = (i * step).round().clamp(0, data.length - 1);
          result.add(data[index]);
        }

        return result;
      },
    );
  }
}
