// lib/blood_pressure/services/blood_pressure_data_processor_universal.dart
import 'dart:math' as math;

import '../../models/date_range_type.dart';
import '../../shared/services/base_data_processor.dart';
import '../models/blood_pressure_data.dart';
import '../models/processed_blood_pressure_data.dart';

/// Universal Blood Pressure data processor - uses shared base implementation
class BloodPressureDataProcessorUniversal {
  static List<ProcessedBloodPressureData> processData(
    List<BloodPressureData> data,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return BaseDataProcessor.processData<ProcessedBloodPressureData,
        BloodPressureData>(
      data,
      viewType,
      startDate,
      endDate,
      processDataGroup: (
        List<BloodPressureData> groupedData,
        DateTime startDate,
        DateTime endDate,
        DateRangeType viewType,
      ) {
        if (groupedData.isEmpty) {
          return ProcessedBloodPressureData.empty(startDate);
        }

        final systolicValues = groupedData
            .map((d) => d.systolic ?? 0)
            .where((v) => v > 0)
            .toList();
        final diastolicValues = groupedData
            .map((d) => d.diastolic ?? 0)
            .where((v) => v > 0)
            .toList();

        // Calculate standard deviations
        final systolicMean =
            systolicValues.reduce((a, b) => a + b) / systolicValues.length;
        final diastolicMean =
            diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;

        final systolicStdDev = groupedData.length > 1
            ? math.sqrt(systolicValues
                    .map((v) => math.pow(v - systolicMean, 2))
                    .reduce((a, b) => a + b) /
                (systolicValues.length - 1))
            : 0.0;

        final diastolicStdDev = groupedData.length > 1
            ? math.sqrt(diastolicValues
                    .map((v) => math.pow(v - diastolicMean, 2))
                    .reduce((a, b) => a + b) /
                (diastolicValues.length - 1))
            : 0.0;

        return ProcessedBloodPressureData(
          startDate: startDate,
          endDate: endDate,
          minSystolic: systolicValues.reduce((a, b) => a < b ? a : b),
          maxSystolic: systolicValues.reduce((a, b) => a > b ? a : b),
          avgSystolic: systolicMean,
          systolicStdDev: systolicStdDev,
          minDiastolic: diastolicValues.reduce((a, b) => a < b ? a : b),
          maxDiastolic: diastolicValues.reduce((a, b) => a > b ? a : b),
          avgDiastolic: diastolicMean,
          diastolicStdDev: diastolicStdDev,
          dataPointCount: groupedData.length,
          originalMeasurements: groupedData,
          isRangeData: groupedData.length > 1,
        );
      },
      createEmpty:
          (DateTime startDate, DateTime endDate, DateRangeType viewType) {
        return ProcessedBloodPressureData.empty(startDate);
      },
      getDataDate: (data) => data.date,
      aggregateData: (List<ProcessedBloodPressureData> data, int targetLength) {
        // Simple aggregation - take every nth element
        if (data.length <= targetLength) return data;

        final step = data.length / targetLength;
        final result = <ProcessedBloodPressureData>[];

        for (int i = 0; i < targetLength; i++) {
          final index = (i * step).round().clamp(0, data.length - 1);
          result.add(data[index]);
        }

        return result;
      },
    );
  }
}
