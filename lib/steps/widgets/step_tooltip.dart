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

  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    switch (widget.viewType) {
      case DateRangeType.day:
        if (startDate.hour == endDate.hour) {
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

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),

        // Main step display
        _buildMainStepDisplay(),

        const SizedBox(height: 16),

        // Goal progress
        _buildGoalProgress(),

        const SizedBox(height: 12),

        // Additional stats based on view type
        _buildAdditionalStats(),
      ],
    );
  }

  Widget _buildMainStepDisplay() {
    final displayValue = widget.data.displayValue;
    final displayLabel = _getDisplayLabel();
    final isLowValue = displayValue < 1000;

    return Center(
      child: Column(
        children: [
          // Enhanced number display for low values
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLowValue ? 16 : 12,
              vertical: isLowValue ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor(displayValue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(displayValue).withValues(alpha: 0.3),
                width: isLowValue ? 2 : 1,
              ),
            ),
            child: Text(
              NumberFormat('#,###').format(displayValue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(displayValue),
                    fontSize:
                        isLowValue ? 32 : 28, // Larger font for low values
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),

          // Enhanced category badge for low values
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLowValue ? 16 : 12,
              vertical: isLowValue ? 6 : 4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCategoryColor(displayValue).withValues(alpha: 0.1),
                  _getCategoryColor(displayValue).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getCategoryColor(displayValue).withValues(alpha: 0.4),
                width: isLowValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(displayValue),
                  size: isLowValue ? 18 : 16,
                  color: _getCategoryColor(displayValue),
                ),
                const SizedBox(width: 6),
                Text(
                  _getCategoryText(displayValue),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getCategoryColor(displayValue),
                        fontWeight: FontWeight.w700,
                        fontSize: isLowValue ? 13 : 12,
                      ),
                ),
              ],
            ),
          ),

          // Progress indicator for low values
          if (isLowValue) ...[
            const SizedBox(height: 12),
            _buildLowValueProgressIndicator(displayValue),
          ],
        ],
      ),
    );
  }

  Widget _buildLowValueProgressIndicator(int steps) {
    final nextMilestone = _getNextMilestone(steps);
    final progress = steps / nextMilestone;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.style.nextMilestoneLabel}: ${NumberFormat('#,###').format(nextMilestone)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###').format(nextMilestone - steps)} ${widget.style.stepsToGoMessage}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  int _getNextMilestone(int currentSteps) {
    final milestones = [100, 250, 500, 1000, 2500, 5000, 7500, 10000];
    return milestones.firstWhere(
      (milestone) => milestone > currentSteps,
      orElse: () => ((currentSteps / 1000).ceil() + 1) * 1000,
    );
  }

  IconData _getCategoryIcon(int steps) {
    if (steps <= StepRange.sedentaryMax) {
      return Icons.airline_seat_individual_suite;
    }
    if (steps <= StepRange.lightActiveMax) return Icons.directions_walk;
    if (steps <= StepRange.fairlyActiveMax) return Icons.directions_run;
    if (steps <= StepRange.veryActiveMax) return Icons.fitness_center;
    return Icons.local_fire_department;
  }

  // Enhanced goal progress for low values
  Widget _buildGoalProgress() {
    final displayValue = widget.data.displayValue;
    final progress =
        (displayValue / StepRange.recommendedDaily).clamp(0.0, 1.0);
    final isGoalMet = displayValue >= StepRange.recommendedDaily;
    final isLowValue = displayValue < 1000;

    String goalText;
    switch (widget.viewType) {
      case DateRangeType.day:
        goalText =
            '${widget.style.dailyGoalLabel} (${NumberFormat('#,###').format(StepRange.recommendedDaily)})';
        break;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        goalText =
            '${widget.style.dailyGoalLabel} (${NumberFormat('#,###').format(StepRange.recommendedDaily)} ${widget.style.avgPerDayLabel})';
        break;
    }

    return Container(
      padding: EdgeInsets.all(isLowValue ? 16 : 12),
      decoration: BoxDecoration(
        color: isGoalMet
            ? widget.style.goalAchievedColor.withValues(alpha: 0.1)
            : (isLowValue
                ? Colors.orange.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoalMet
              ? widget.style.goalAchievedColor.withValues(alpha: 0.3)
              : (isLowValue
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2)),
          width: isLowValue ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goalText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isLowValue ? 13 : 12,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGoalMet
                      ? widget.style.goalAchievedColor.withValues(alpha: 0.2)
                      : (isLowValue
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isGoalMet
                            ? widget.style.goalAchievedColor
                            : (isLowValue
                                ? Colors.orange[700]
                                : Colors.grey[600]),
                        fontWeight: FontWeight.bold,
                        fontSize: isLowValue ? 12 : 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Enhanced progress bar for low values
          Container(
            height: isLowValue ? 8 : 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLowValue ? 4 : 3),
              color: Colors.grey[300],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isLowValue ? 4 : 3),
                  gradient: LinearGradient(
                    colors: isGoalMet
                        ? [
                            widget.style.goalAchievedColor
                                .withValues(alpha: 0.7),
                            widget.style.goalAchievedColor
                          ]
                        : (isLowValue
                            ? [
                                Colors.orange.withValues(alpha: 0.7),
                                Colors.orange
                              ]
                            : [
                                widget.style.goalLineColor
                                    .withValues(alpha: 0.7),
                                widget.style.goalLineColor
                              ]),
                  ),
                ),
              ),
            ),
          ),

          if (isGoalMet) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: widget.style.goalAchievedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.style.goalAchievedMessage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: widget.style.goalAchievedColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ] else if (isLowValue) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 6),
                Text(
                  widget.style.everyStepCountsMessage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          _getStatsTitle(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _buildStatsRow(),
        ),
      ],
    );
  }

  String _getStatsTitle() {
    switch (widget.viewType) {
      case DateRangeType.day:
        return widget.style.dailySummaryTitle;
      case DateRangeType.week:
        return widget.style.weekSummaryTitle;
      case DateRangeType.month:
        return widget.style.monthSummaryTitle;
      case DateRangeType.year:
        return widget.style.yearSummaryTitle;
    }
  }

  String _getDisplayLabel() {
    switch (widget.viewType) {
      case DateRangeType.day:
        return widget.style.totalStepsLabel;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        return widget.style.avgPerDayLabel;
    }
  }

  List<Widget> _buildStatsRow() {
    switch (widget.viewType) {
      case DateRangeType.day:
        return _buildDailyStats();
      case DateRangeType.week:
        return _buildWeeklyStats();
      case DateRangeType.month:
        return _buildMonthlyStats();
      case DateRangeType.year:
        return _buildYearlyStats();
    }
  }

  List<Widget> _buildDailyStats() {
    return [
      _buildStatItem(
        widget.style.totalStepsLabel,
        NumberFormat('#,###').format(widget.data.totalStepsInPeriod),
        Icons.directions_walk,
        _getCategoryColor(widget.data.totalStepsInPeriod),
      ),
      _buildStatItem(
        widget.style.readingsLabel,
        widget.data.dataPointCount.toString(),
        Icons.analytics_outlined,
      ),
      _buildStatItem(
        widget.style.activityLabel,
        _getCategoryText(widget.data.displayValue),
        Icons.local_fire_department,
        _getCategoryColor(widget.data.displayValue),
      ),
    ];
  }

  List<Widget> _buildWeeklyStats() {
    final totalSteps = widget.data.totalStepsInPeriod;
    final avgDaily = widget.data.dailyAverage.round();
    final daysWithData = widget.data.dataPointCount;

    return [
      _buildStatItem(
        widget.style.totalStepsLabel,
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        widget.style.avgPerDayLabel,
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      if (widget.viewType == DateRangeType.year)
        _buildStatItem(
          widget.style.activeDaysLabel,
          daysWithData.toString(),
          Icons.calendar_today,
        ),
    ];
  }

  List<Widget> _buildMonthlyStats() {
    final totalSteps = widget.data.totalStepsInPeriod;
    final avgDaily = widget.data.dailyAverage.round();
    final daysWithData = widget.data.dataPointCount;

    return [
      _buildStatItem(
        widget.style.totalStepsLabel,
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        widget.style.avgPerDayLabel,
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      _buildStatItem(
        widget.style.activeDaysLabel,
        daysWithData.toString(),
        Icons.calendar_today,
      ),
    ];
  }

  List<Widget> _buildYearlyStats() {
    final totalSteps = widget.data.totalStepsInPeriod;
    final avgDaily = widget.data.dailyAverage.round();
    final daysInPeriod =
        widget.data.endDate.difference(widget.data.startDate).inDays + 1;

    return [
      _buildStatItem(
        widget.style.totalStepsLabel,
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        widget.style.avgPerDayLabel,
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      _buildStatItem(
        widget.style.daysLabel,
        daysInPeriod.toString(),
        Icons.calendar_month,
      ),
    ];
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Colors.grey[800],
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getCategoryColor(int steps) {
    if (steps <= StepRange.sedentaryMax) return widget.style.sedentaryColor;
    if (steps <= StepRange.lightActiveMax) return widget.style.lightActiveColor;
    if (steps <= StepRange.fairlyActiveMax) {
      return widget.style.fairlyActiveColor;
    }
    if (steps <= StepRange.veryActiveMax) return widget.style.veryActiveColor;
    return widget.style.highlyActiveColor;
  }

  String _getCategoryText(int steps) {
    if (steps <= StepRange.sedentaryMax) {
      return widget.style.sedentaryLabel;
    }
    if (steps <= StepRange.lightActiveMax) {
      return widget.style.lightActiveLabel;
    }
    if (steps <= StepRange.fairlyActiveMax) {
      return widget.style.fairlyActiveLabel;
    }
    if (steps <= StepRange.veryActiveMax) {
      return widget.style.veryActiveLabel;
    }
    return widget.style.highlyActiveLabel;
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
            elevation: 12 * _fadeAnimation.value,
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
                width: 320,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.5,
                  minWidth: 280,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTimeRange(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (widget.data.hasAnnotation)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.style.highlightColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.data.isHighest
                                            ? widget
                                                .style.highestStepsAnnotation
                                            : widget
                                                .style.lowestStepsAnnotation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: dismiss,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),

                        // Main content
                        _buildStepContent(),
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
