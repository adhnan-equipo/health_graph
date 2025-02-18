// lib/o2_saturation/widgets/o2_saturation_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';

class O2SaturationTooltip extends StatelessWidget {
  final ProcessedO2SaturationData data;
  final DateRangeType viewType;
  final Offset position;
  final VoidCallback onClose;
  final O2SaturationChartStyle style;
  final Size screenSize;
  final Function(ProcessedO2SaturationData)? onTooltipTap;

  const O2SaturationTooltip({
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
        if (data.dataPointCount <= 1) {
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(data.startDate),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...measurements.map((measurement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(measurement.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: style.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${measurement.o2Value}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (measurement.pulseRate != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: style.pulseRateColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${measurement.pulseRate} bpm',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: style.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'O2 Saturation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Text(
              data.minValue == data.maxValue
                  ? '${data.minValue}%'
                  : '${data.minValue} - ${data.maxValue}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (data.avgPulseRate != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: style.pulseRateColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pulse Rate',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(
                '${data.avgPulseRate!.toStringAsFixed(0)} bpm',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Average',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${data.avgValue.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    if (data.dataPointCount <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'Standard Deviation',
              data.stdDev.toStringAsFixed(1),
            ),
            _buildStatItem(
              context,
              'Readings',
              data.dataPointCount.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.bold),
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
                  _buildStatistics(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
