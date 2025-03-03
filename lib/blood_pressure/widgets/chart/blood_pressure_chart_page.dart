import 'package:flutter/material.dart';

import '../../../models/date_range_type.dart';
import '../../controllers/chart_controller.dart';
import '../../models/blood_pressure_data.dart';
import '../../models/chart_view_config.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';
import 'blood_pressure_chart.dart';

class BloodPressureChartPage extends StatefulWidget {
  final List<BloodPressureData> data;
  final BloodPressureChartStyle style;
  final ChartViewConfig initialConfig;
  final Function(ProcessedBloodPressureData)? onDataPointSelected;

  const BloodPressureChartPage({
    Key? key,
    required this.data,
    this.style = const BloodPressureChartStyle(),
    required this.initialConfig,
    this.onDataPointSelected,
  }) : super(key: key);

  @override
  State<BloodPressureChartPage> createState() => _BloodPressureChartPageState();
}

class _BloodPressureChartPageState extends State<BloodPressureChartPage> {
  late ChartController _controller;
  late ChartViewConfig _config;
  ProcessedBloodPressureData? _selectedData;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _controller = ChartController(
      data: widget.data,
      config: _config,
    );
    _controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(BloodPressureChartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _controller.updateData(widget.data);
    }
    if (widget.initialConfig != oldWidget.initialConfig) {
      _controller.updateConfig(widget.initialConfig);
    }
  }

  void _handleControllerUpdate() {
    setState(() {
      _selectedData = _controller.selectedData;
    });
  }

  void _handleViewTypeChanged(DateRangeType viewType) {
    _controller.changeViewType(viewType);
  }

  void _handleDataSelected(ProcessedBloodPressureData? data) {
    setState(() {
      _selectedData = data;
    });
    if (data != null) {
      widget.onDataPointSelected?.call(data);
    }
  }

  String _getDateRangeTitle() {
    final startDate = _config.startDate;
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    switch (_config.viewType) {
      case DateRangeType.day:
        return '${months[startDate.month - 1]} ${startDate.day}, ${startDate.year}';
      case DateRangeType.week:
        final endDate = startDate.add(const Duration(days: 6));
        if (startDate.month == endDate.month) {
          return '${months[startDate.month - 1]} ${startDate.day}-${endDate.day}, ${startDate.year}';
        } else {
          return '${months[startDate.month - 1]} ${startDate.day} - ${months[endDate.month - 1]} ${endDate.day}, ${startDate.year}';
        }
      case DateRangeType.month:
        return '${months[startDate.month - 1]} ${startDate.year}';
      case DateRangeType.year:
        return '${startDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChartSection(),
            ),
            if (_selectedData != null) _buildDetailSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateNavigation(),
          const SizedBox(height: 16),
          _buildViewTypeToggle(),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _controller.navigateToPrevious(),
        ),
        Text(
          _getDateRangeTitle(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _controller.navigateToNext(),
        ),
      ],
    );
  }

  Widget _buildViewTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildViewTypeButton(DateRangeType.day, 'Day'),
          _buildViewTypeButton(DateRangeType.week, 'Week'),
          _buildViewTypeButton(DateRangeType.month, 'Month'),
          _buildViewTypeButton(DateRangeType.year, 'Year'),
        ],
      ),
    );
  }

  Widget _buildViewTypeButton(DateRangeType viewType, String label) {
    final isSelected = _config.viewType == viewType;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleViewTypeChanged(viewType),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected ? widget.style.selectedTabColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BloodPressureChart(
        data: widget.data,
        style: widget.style,
        initialConfig: _config,
        height: 300,
        onDataSelected: _handleDataSelected,
        onDataPointTap: (data) {
          // Additional tap handling if needed
        },
      ),
    );
  }

  Widget _buildDetailSection() {
    if (_selectedData == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedData!.dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedData = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildDataColumn(
                  'Systolic',
                  _selectedData!.maxSystolic.toString(),
                  widget.style.systolicColor,
                ),
                const SizedBox(width: 24),
                _buildDataColumn(
                  'Diastolic',
                  _selectedData!.maxDiastolic.toString(),
                  widget.style.diastolicColor,
                ),
                const SizedBox(width: 24),
                _buildDataColumn(
                  'Readings',
                  _selectedData!.dataPointCount.toString(),
                  Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }
}
