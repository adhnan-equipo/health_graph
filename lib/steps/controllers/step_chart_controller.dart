// lib/steps/controllers/step_chart_controller.dart
import '../../models/date_range_type.dart';
import '../../shared/controllers/base_chart_controller.dart';
import '../../utils/chart_view_config.dart';
import '../models/processed_step_data.dart';
import '../models/step_data.dart';
import '../services/step_data_processor.dart';

class StepChartController
    extends BaseChartController<StepData, ProcessedStepData> {
  StepChartController({
    required List<StepData> data,
    required ChartViewConfig config,
  }) : super(data: data, config: config);

  @override
  List<ProcessedStepData> processDataImpl(
    List<StepData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return StepDataProcessor.processData(
      sortedData,
      viewType,
      startDate,
      endDate,
    );
  }

  @override
  DateTime getDataDate(StepData data) {
    return data.createDate;
  }
}
