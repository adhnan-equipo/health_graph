import '../../models/date_range_type.dart';
import '../../shared/controllers/base_chart_controller.dart';
import '../../utils/chart_view_config.dart';
import '../models/blood_pressure_data.dart';
import '../models/processed_blood_pressure_data.dart';
import '../services/blood_pressure_data_processor_universal.dart';

class ChartController
    extends BaseChartController<BloodPressureData, ProcessedBloodPressureData> {
  ChartController({
    required List<BloodPressureData> data,
    required ChartViewConfig config,
  }) : super(data: data, config: config);

  @override
  List<ProcessedBloodPressureData> processDataImpl(
    List<BloodPressureData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return BloodPressureDataProcessorUniversal.processData(
      sortedData,
      viewType,
      startDate,
      endDate,
    );
  }

  @override
  DateTime getDataDate(BloodPressureData data) {
    return data.date;
  }
}
