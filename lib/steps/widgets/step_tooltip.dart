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
    final displayLabel = widget.data.displayLabel;

    return Center(
      child: Column(
        children: [
          Text(
            NumberFormat('#,###').format(displayValue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(displayValue),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            displayLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(displayValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(displayValue).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getCategoryText(displayValue),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getCategoryColor(displayValue),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress() {
    final displayValue = widget.data.displayValue;
    final progress =
        (displayValue / StepRange.recommendedDaily).clamp(0.0, 1.0);
    final isGoalMet = displayValue >= StepRange.recommendedDaily;

    String goalText;
    switch (widget.viewType) {
      case DateRangeType.day:
        goalText =
            'Daily Goal (${NumberFormat('#,###').format(StepRange.recommendedDaily)})';
        break;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        goalText =
            'Daily Goal (${NumberFormat('#,###').format(StepRange.recommendedDaily)} avg/day)';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              goalText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
          minHeight: 6,
        ),
        if (isGoalMet) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: widget.style.goalAchievedColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Goal Achieved!',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.style.goalAchievedColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ],
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
        return 'Daily Summary';
      case DateRangeType.week:
        return 'Week Summary';
      case DateRangeType.month:
        return 'Month Summary';
      case DateRangeType.year:
        return 'Year Summary';
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
        'Total Steps',
        NumberFormat('#,###').format(widget.data.totalStepsInPeriod),
        Icons.directions_walk,
        _getCategoryColor(widget.data.totalStepsInPeriod),
      ),
      _buildStatItem(
        'Readings',
        widget.data.dataPointCount.toString(),
        Icons.analytics_outlined,
      ),
      _buildStatItem(
        'Activity',
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
        'Total Steps',
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        'Avg/Day',
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      _buildStatItem(
        'Active Days',
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
        'Total Steps',
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        'Avg/Day',
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      _buildStatItem(
        'Active Days',
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
        'Total Steps',
        NumberFormat('#,###').format(totalSteps),
        Icons.directions_walk,
      ),
      _buildStatItem(
        'Avg/Day',
        NumberFormat('#,###').format(avgDaily),
        Icons.show_chart,
        _getCategoryColor(avgDaily),
      ),
      _buildStatItem(
        'Days',
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
    if (steps <= StepRange.fairlyActiveMax)
      return widget.style.fairlyActiveColor;
    if (steps <= StepRange.veryActiveMax) return widget.style.veryActiveColor;
    return widget.style.highlyActiveColor;
  }

  String _getCategoryText(int steps) {
    if (steps <= StepRange.sedentaryMax) return widget.style.sedentaryLabel;
    if (steps <= StepRange.lightActiveMax) return widget.style.lightActiveLabel;
    if (steps <= StepRange.fairlyActiveMax)
      return widget.style.fairlyActiveLabel;
    if (steps <= StepRange.veryActiveMax) return widget.style.veryActiveLabel;
    return widget.style.highlyActiveLabel;
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
                                        widget.data.annotationText,
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
