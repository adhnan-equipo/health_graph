// lib/bmi/widgets/bmi_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_bmi_data.dart';
import '../styles/bmi_chart_style.dart';

class BMITooltip extends StatefulWidget {
  final ProcessedBMIData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final BMIChartStyle style;
  final Size screenSize;
  final Function(ProcessedBMIData)? onTooltipTap;

  const BMITooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<BMITooltip> createState() => _BMITooltipState();
}

class _BMITooltipState extends State<BMITooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    switch (widget.viewType) {
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

  Widget _buildLatestMeasurement() {
    final measurements = widget.data.originalMeasurements;
    if (measurements.isEmpty) return const SizedBox.shrink();

    // Get the latest measurement
    final latestMeasurement = measurements.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),

        // Show latest heading
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.style.lastReadingLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              DateFormat('MMM d, HH:mm').format(latestMeasurement.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // BMI value with big display
        Center(
          child: Column(
            children: [
              Text(
                latestMeasurement.bmi.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(latestMeasurement.bmi),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _getCategoryText(latestMeasurement.bmi),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getCategoryColor(latestMeasurement.bmi),
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Weight and height details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMeasurementDetail(
              widget.style.weight,
              '${latestMeasurement.weight.toStringAsFixed(1)} kg',
              Icons.monitor_weight_outlined,
            ),
            _buildMeasurementDetail(
              widget.style.height,
              '${latestMeasurement.height.toStringAsFixed(1)} cm',
              Icons.height_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Color _getCategoryColor(double bmi) {
    if (bmi < 18.5) return widget.style.underweightRangeColor;
    if (bmi < 25.0) return widget.style.normalRangeColor;
    if (bmi < 30.0) return widget.style.overweightRangeColor;
    return widget.style.obeseRangeColor;
  }

  String _getCategoryText(double bmi) {
    if (bmi < 18.5) return widget.style.underweightLabel;
    if (bmi < 25.0) return widget.style.normalLabel;
    if (bmi < 30.0) return widget.style.overweightLabel;
    return widget.style.obeseLabel;
  }

  Widget _buildHistoryInfo() {
    // Show a brief history summary if there are multiple readings
    if (widget.data.dataPointCount <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 8),
        Text(
          widget.style.summaryLabel ?? 'History',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHistoryStat(
              widget.style.readingLabel,
              widget.data.dataPointCount.toString(),
              Icons.analytics_outlined,
            ),
            _buildHistoryStat(
              widget.style.averageLabel,
              widget.data.avgBMI.toStringAsFixed(1),
              Icons.show_chart,
              _getCategoryColor(widget.data.avgBMI),
            ),
            _buildHistoryStat(
              widget.style.changeLabel,
              _calculateChange(),
              _getChangeIcon(),
              _getChangeColor(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryStat(String label, String value, IconData icon,
      [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey[700],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  String _calculateChange() {
    if (widget.data.originalMeasurements.length < 2) return "0.0";

    final latest = widget.data.originalMeasurements.last.bmi;
    final first = widget.data.originalMeasurements.first.bmi;
    final change = latest - first;

    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}';
  }

  IconData _getChangeIcon() {
    if (widget.data.originalMeasurements.length < 2)
      return Icons.horizontal_rule;

    final latest = widget.data.originalMeasurements.last.bmi;
    final first = widget.data.originalMeasurements.first.bmi;
    final change = latest - first;

    if (change > 0.5) return Icons.arrow_upward;
    if (change < -0.5) return Icons.arrow_downward;
    return Icons.horizontal_rule;
  }

  Color _getChangeColor() {
    if (widget.data.originalMeasurements.length < 2) return Colors.grey;

    final latest = widget.data.originalMeasurements.last.bmi;
    final first = widget.data.originalMeasurements.first.bmi;
    final change = latest - first;

    // Determine if change is good based on BMI category
    if (first < 18.5) {
      // Underweight: Gaining is good
      return change > 0 ? Colors.green : Colors.red;
    } else if (first > 25.0) {
      // Overweight/Obese: Losing is good
      return change < 0 ? Colors.green : Colors.red;
    } else {
      // Normal: Staying stable is good
      return change.abs() < 0.5
          ? Colors.green
          : (change > 0 ? Colors.orange : Colors.blue);
    }
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
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
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
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: GestureDetector(
              onTap: () {
                widget.onTooltipTap?.call(widget.data);
                dismiss();
              },
              child: Container(
                width: 280,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.6,
                ),
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
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: dismiss,
                            ),
                          ],
                        ),
                        // Show latest measurement prominently
                        _buildLatestMeasurement(),
                        // Show history information
                        _buildHistoryInfo(),
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
