// lib/steps/widgets/step_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_step_data.dart';
import '../models/step_range.dart';
import '../styles/step_chart_style.dart';

class StepTooltip extends StatefulWidget {
  final ProcessedStepData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final StepChartStyle style;
  final Size screenSize;
  final Function(ProcessedStepData)? onTooltipTap;

  const StepTooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<StepTooltip> createState() => _StepTooltipState();
}

class _StepTooltipState extends State<StepTooltip>
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

    // For steps, show the TOTAL for this period, not just latest reading
    final totalStepsInPeriod = widget.data.totalStepsInPeriod;
    final periodLabel = _getPeriodLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              periodLabel, // e.g., "Daily Total", "Weekly Total"
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (measurements.isNotEmpty)
              Text(
                DateFormat('MMM d').format(widget.data.endDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        Center(
          child: Column(
            children: [
              Text(
                '${NumberFormat('#,###').format(totalStepsInPeriod)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(totalStepsInPeriod),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.style.stepsLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _getCategoryText(totalStepsInPeriod),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getCategoryColor(totalStepsInPeriod),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildGoalProgress(totalStepsInPeriod),

        // Show individual readings if there are multiple in this period
        if (measurements.length > 1) _buildIndividualReadings(),
      ],
    );
  }

  String _getPeriodLabel() {
    switch (widget.viewType) {
      case DateRangeType.day:
        return 'Daily Total';
      case DateRangeType.week:
        return 'Weekly Total';
      case DateRangeType.month:
        return 'Monthly Total';
      case DateRangeType.year:
        return 'Yearly Total';
    }
  }

  Widget _buildIndividualReadings() {
    final measurements = widget.data.originalMeasurements;
    if (measurements.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          'Individual Readings',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...measurements.take(3).map((measurement) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('HH:mm').format(measurement.createDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${NumberFormat('#,###').format(measurement.step)} steps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            )),
        if (measurements.length > 3)
          Text(
            '... and ${measurements.length - 3} more readings',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
      ],
    );
  }

  Widget _buildGoalProgress(int steps) {
    final progress = (steps / StepRange.recommendedDaily).clamp(0.0, 1.0);
    final isGoalMet = steps >= StepRange.recommendedDaily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.style.goalLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isGoalMet
                        ? widget.style.goalAchievedColor
                        : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isGoalMet
                ? widget.style.goalAchievedColor
                : widget.style.goalLineColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat('#,###').format(StepRange.recommendedDaily)} steps',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Color _getCategoryColor(int steps) {
    if (steps <= 4999) return widget.style.sedentaryColor;
    if (steps <= 7499) return widget.style.lightActiveColor;
    if (steps <= 9999) return widget.style.fairlyActiveColor;
    if (steps <= 12499) return widget.style.veryActiveColor;
    return widget.style.highlyActiveColor;
  }

  String _getCategoryText(int steps) {
    if (steps <= 4999) return widget.style.sedentaryLabel;
    if (steps <= 7499) return widget.style.lightActiveLabel;
    if (steps <= 9999) return widget.style.fairlyActiveLabel;
    if (steps <= 12499) return widget.style.veryActiveLabel;
    return widget.style.highlyActiveLabel;
  }

  Widget _buildHistoryInfo() {
    if (widget.data.dataPointCount <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 8),
        Text(
          'Summary',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHistoryStat(
              'Readings',
              widget.data.dataPointCount.toString(),
              Icons.analytics_outlined,
            ),
            _buildHistoryStat(
              'Average',
              NumberFormat('#,###').format(widget.data.avgSteps.round()),
              Icons.show_chart,
              _getCategoryColor(widget.data.avgSteps.round()),
            ),
            _buildHistoryStat(
              'Change',
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
    if (widget.data.originalMeasurements.length < 2) return "0";

    final latest = widget.data.originalMeasurements.last.step;
    final first = widget.data.originalMeasurements.first.step;
    final change = latest - first;

    final sign = change > 0 ? '+' : '';
    return '$sign${NumberFormat('#,###').format(change)}';
  }

  IconData _getChangeIcon() {
    if (widget.data.originalMeasurements.length < 2)
      return Icons.horizontal_rule;

    final latest = widget.data.originalMeasurements.last.step;
    final first = widget.data.originalMeasurements.first.step;
    final change = latest - first;

    if (change > 500) return Icons.arrow_upward;
    if (change < -500) return Icons.arrow_downward;
    return Icons.horizontal_rule;
  }

  Color _getChangeColor() {
    if (widget.data.originalMeasurements.length < 2) return Colors.grey;

    final latest = widget.data.originalMeasurements.last.step;
    final first = widget.data.originalMeasurements.first.step;
    final change = latest - first;

    // More steps is generally better
    return change > 0 ? Colors.green : Colors.red;
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
                        _buildLatestMeasurement(),
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
