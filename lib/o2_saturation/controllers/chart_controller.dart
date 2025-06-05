import '../../models/date_range_type.dart';
import '../../shared/controllers/base_chart_controller.dart';
import '../../utils/chart_view_config.dart';
import '../models/o2_saturation_data.dart';
import '../models/processed_o2_saturation_data.dart';
import '../services/o2_saturation_data_processor.dart';

class O2ChartController
    extends BaseChartController<O2SaturationData, ProcessedO2SaturationData> {
  O2ChartController({
    required List<O2SaturationData> data,
    required ChartViewConfig config,
  }) : super(data: data, config: config);

  @override
  List<ProcessedO2SaturationData> processDataImpl(
    List<O2SaturationData> sortedData,
    DateRangeType viewType,
    DateTime startDate,
    DateTime endDate,
  ) {
    return O2SaturationDataProcessor.processData(
      sortedData,
      viewType,
      startDate,
      endDate,
      zoomLevel: config.zoomLevel,
    );
  }

  @override
  DateTime getDataDate(O2SaturationData data) {
    return data.date;
  }
}
