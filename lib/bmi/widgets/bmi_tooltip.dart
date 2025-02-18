// lib/bmi/widgets/bmi_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';

class BMITooltip extends StatelessWidget {
  final ProcessedBMIData data;
  final DateRangeType viewType;
  final Offset position;
  final VoidCallback onClose;
  final BMIChartStyle style;
  final Size screenSize;
  final Function(ProcessedBMIData)? onTooltipTap;

  const BMITooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.position,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  String _formatTimeRange() {
    final startDate = data.startDate;
    final endDate = data.endDate;

    switch (viewType) {
      case DateRangeType.day:
        if (startDate == endDate) {
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
    final measurements = data.originalMeasurements;
    if (measurements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          'Measurements (${measurements.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(measurement.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'BMI: ${measurement.bmi.toStringAsFixed(1)} (${measurement.weight.toStringAsFixed(1)} kg)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
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
          'Summary',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
            context, 'Average BMI', data.avgBMI.toStringAsFixed(1)),
        if (data.dataPointCount > 1) ...[
          const SizedBox(height: 8),
          _buildSummaryRow(context, 'Range',
              '${data.minBMI.toStringAsFixed(1)} - ${data.maxBMI.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
              context, 'Standard Deviation', data.stdDev.toStringAsFixed(2)),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
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
  Widget build(BuildContext context) {
    const tooltipWidth = 280.0;
    double top = position.dy - 20;
    double left = position.dx - (tooltipWidth / 2);

    // Adjust position to keep tooltip on screen
    if (left < 12) left = 12;
    if (left + tooltipWidth > screenSize.width - 12) {
      left = screenSize.width - tooltipWidth - 12;
    }
    if (top < 12) top = position.dy + 20;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: tooltipWidth,
          constraints: BoxConstraints(
            maxHeight: screenSize.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
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
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSummarySection(context),
                  _buildMeasurementsList(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
