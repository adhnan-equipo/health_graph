// lib/blood_pressure/widgets/chart/chart_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/date_range_type.dart';
import '../../models/processed_blood_pressure_data.dart';
import '../../styles/blood_pressure_chart_style.dart';

class ChartTooltip extends StatefulWidget {
  final ProcessedBloodPressureData data;
  final List<ProcessedBloodPressureData> rangeData;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final BloodPressureChartStyle style;
  final Size screenSize;
  final Function(ProcessedBloodPressureData)? onTooltipTap;

  const ChartTooltip({
    Key? key,
    required this.data,
    required this.rangeData,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<ChartTooltip> createState() => _ChartTooltipState();
}

class _ChartTooltipState extends State<ChartTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    switch (widget.viewType) {
      case DateRangeType.day:
        if (widget.rangeData.length <= 1) {
          return DateFormat('MMM d, HH:mm').format(startDate);
        }
        return '${DateFormat('MMM d, HH:mm').format(startDate)} - ${DateFormat('HH:mm').format(endDate)}';

      case DateRangeType.week:
        if (startDate.day == endDate.day) {
          return DateFormat('EEE, MMM d').format(startDate);
        }
        return '${DateFormat('EEE, MMM d').format(startDate)} - ${DateFormat('EEE, MMM d').format(endDate)}';

      case DateRangeType.month:
        if (startDate.day == endDate.day) {
          return DateFormat('MMM d').format(startDate);
        }
        return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';

      case DateRangeType.year:
        if (startDate.month == endDate.month) {
          return DateFormat('MMMM yyyy').format(startDate);
        }
        return '${DateFormat('MMM').format(startDate)} - ${DateFormat('MMM yyyy').format(endDate)}';
    }
  }

  Widget _buildMeasurementsList(BuildContext context) {
    final measurements = widget.data.originalMeasurements;
    if (measurements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          '${widget.style.measurementsLabels} (${measurements.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.style.summaryLabels,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          widget.style.systolic,
          widget.data.originalMeasurements.length > 1
              ? '${widget.data.minSystolic} - ${widget.data.maxSystolic}'
              : '${widget.data.minSystolic}',
          widget.style.systolicColor,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          context,
          widget.style.diastolic,
          widget.data.originalMeasurements.length > 1
              ? '${widget.data.minDiastolic} - ${widget.data.maxDiastolic}'
              : '${widget.data.minDiastolic}',
          widget.style.diastolicColor,
        ),
        const SizedBox(height: 8),
        if (widget.data.originalMeasurements.length > 1)
          _buildSummaryRow(
            context,
            widget.style.averageLabels,
            '${widget.data.avgSystolic.toStringAsFixed(1)}/${widget.data.avgDiastolic.toStringAsFixed(1)}',
            null,
          ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color? indicatorColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (indicatorColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  Future<void> dismiss() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.scale(
          scale: 0.95 + (0.05 * _fadeAnimation.value),
          child: Card(
            elevation: 8 * _fadeAnimation.value,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () async {
                widget.onTooltipTap?.call(widget.data);
                await dismiss();
              },
              child: Container(
                width: 200,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.6,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _formatTimeRange(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: dismiss,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSummarySection(context),
                        if (widget.data.originalMeasurements.length > 1)
                          _buildMeasurementsList(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
