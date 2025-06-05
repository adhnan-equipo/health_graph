// lib/bmi/controllers/bmi_chart_controller.dart
import '../../models/date_range_type.dart';
import '../../shared/controllers/base_chart_controller.dart';
import '../../utils/chart_view_config.dart';
import '../models/bmi_data.dart';
import '../models/processed_bmi_data.dart';
import '../services/bmi_data_processor_universal.dart';

class BMIChartController
    extends BaseChartController<BMIData, ProcessedBMIData> {
  BMIChartController({
    required List<BMIData> data,
    required ChartViewConfig config,
  }) : super(data: data, config: config);

  @override
  List<ProcessedBMIData> processDataImpl(
    List<BMIData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return BMIDataProcessorUniversal.processData(
      sortedData,
      viewType,
      startDate,
      endDate,
    );
  }

  @override
  DateTime getDataDate(BMIData data) {
    return data.date;
  }
}
