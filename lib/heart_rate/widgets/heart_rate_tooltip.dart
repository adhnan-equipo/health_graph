// lib/widgets/heart_rate_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/processed_heart_rate_data.dart';
import '../styles/heart_rate_chart_style.dart';
import '../utils/heart_rate_utils.dart';

// lib/widgets/heart_rate_tooltip.dart
class HeartRateTooltip extends StatelessWidget {
  final ProcessedHeartRateData data;
  final Offset position;
  final Size screenSize;
  final HeartRateChartStyle style;
  final VoidCallback onClose;

  const HeartRateTooltip({
    Key? key,
    required this.data,
    required this.position,
    required this.screenSize,
    required this.style,
    required this.onClose,
  }) : super(key: key);

  Widget _buildMeasurementsList(BuildContext context) {
    if (data.dataPointCount <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          'Measurements (${data.dataPointCount})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            for (var measurement in data.originalMeasurements)
              Padding(
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
                          '${measurement.value} bpm',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (data.dataPointCount > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Average',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${data.avgValue.toStringAsFixed(1)} bpm',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
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
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Range',
                '${data.minValue}-${data.maxValue} bpm',
              ),
            ),
            const SizedBox(width: 16),
            if (data.hrv != null)
              Expanded(
                child: _buildStatItem(
                  context,
                  'HRV',
                  '${data.hrv!.toStringAsFixed(1)} ms',
                ),
              ),
          ],
        ),
        if (data.restingRate != null) ...[
          const SizedBox(height: 8),
          _buildStatItem(
            context,
            'Resting Rate',
            '${data.restingRate} bpm',
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
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
    const tooltipWidth = 250.0;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, HH:mm').format(data.startDate),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                ],
              ),
              _buildMeasurementsList(context),
              _buildStatistics(context),
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: HeartRateUtils.getZoneColor(data.avgValue)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: HeartRateUtils.getZoneColor(data.avgValue),
                  ),
                ),
                child: Text(
                  HeartRateUtils.getZoneText(data.avgValue),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: HeartRateUtils.getZoneColor(data.avgValue),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
