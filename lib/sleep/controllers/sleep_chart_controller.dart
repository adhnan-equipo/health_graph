// lib/sleep/controllers/sleep_chart_controller.dart
import '../../models/date_range_type.dart';
import '../../shared/controllers/base_chart_controller.dart';
import '../../utils/chart_view_config.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_data.dart';
import '../services/sleep_data_processor.dart';

class SleepChartController
    extends BaseChartController<SleepData, ProcessedSleepData> {
  SleepChartController({
    required List<SleepData> data,
    required ChartViewConfig config,
  }) : super(data: data, config: config);

  @override
  List<ProcessedSleepData> processDataImpl(
    List<SleepData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return SleepDataProcessor.processData(
      sortedData,
      viewType,
      startDate,
      endDate,
    );
  }

  @override
  DateTime getDataDate(SleepData data) {
    return data.createDate;
  }
}
