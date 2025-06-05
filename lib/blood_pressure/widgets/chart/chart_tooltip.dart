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
  late Animation<double> _scaleAnimation;

  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;
    final isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    switch (widget.viewType) {
      case DateRangeType.day:
        // For single data point, show exact time from the original measurement
        if (widget.data.originalMeasurements.length == 1) {
          // Use the actual measurement time if available, not the processed data's start time
          final exactTime = widget.data.originalMeasurements.first.date;
          return DateFormat('MMM d, HH:mm').format(exactTime);
        }

        // For multiple data points on the same day, show time range
        if (isSameDay) {
          return '${DateFormat('MMM d').format(startDate)}, ${DateFormat('HH:mm').format(startDate)} - ${DateFormat('HH:mm').format(endDate)}';
        } else {
          // Across days (rare for day view)
          return '${DateFormat('MMM d, HH:mm').format(startDate)} - ${DateFormat('MMM d, HH:mm').format(endDate)}';
        }

      case DateRangeType.week:
        if (isSameDay) {
          return DateFormat('EEE, MMM d, yyyy').format(startDate);
        }
        return '${DateFormat('EEE, MMM d').format(startDate)} - ${DateFormat('EEE, MMM d, yyyy').format(endDate)}';

      case DateRangeType.month:
        if (isSameDay) {
          return DateFormat('MMM d, yyyy').format(startDate);
        }
        return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}';

      case DateRangeType.year:
        if (startDate.month == endDate.month &&
            startDate.year == endDate.year) {
          return DateFormat('MMMM yyyy').format(startDate);
        }
        if (startDate.year == endDate.year) {
          return '${DateFormat('MMM').format(startDate)} - ${DateFormat('MMM yyyy').format(endDate)}';
        }
        return '${DateFormat('MMM yyyy').format(startDate)} - ${DateFormat('MMM yyyy').format(endDate)}';
    }
  }

  Widget _buildMeasurementsList(BuildContext context) {
    final measurements = widget.data.originalMeasurements;
    if (measurements.isEmpty) return const SizedBox.shrink();

    // Only show the first 5 measurements if there are many

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, thickness: 1),
        Text(
          '${widget.style.measurementsLabels} (${measurements.length})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w500,
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
        if (widget.data.originalMeasurements.length > 1) ...[
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            widget.style.averageLabels,
            '${widget.data.avgSystolic.toStringAsFixed(1)}/${widget.data.avgDiastolic.toStringAsFixed(1)}',
            null,
            isAverage: true,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color? indicatorColor, {
    bool isAverage = false,
  }) {
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
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isAverage ? FontWeight.w500 : FontWeight.normal,
                    color: isAverage ? Colors.grey[800] : Colors.grey[700],
                  ),
            ),
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isAverage ? Theme.of(context).primaryColor : null,
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
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
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
      animation: _animationController,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 8 * _fadeAnimation.value,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () async {
                widget.onTooltipTap?.call(widget.data);
                await dismiss();
              },
              child: Container(
                width: 240,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.6,
                  maxWidth: widget.screenSize.width * 0.75,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[850],
                                        ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: dismiss,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(Icons.close,
                                          size: 16, color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSummarySection(context),
                            if (widget.data.originalMeasurements.isNotEmpty)
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
        ),
      ),
    );
  }
}
