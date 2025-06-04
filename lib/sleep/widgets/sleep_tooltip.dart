// lib/sleep/widgets/sleep_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_sleep_data.dart';
import '../models/sleep_quality.dart';
import '../models/sleep_range.dart';
import '../models/sleep_stage.dart';
import '../styles/sleep_chart_style.dart';

class SleepTooltip extends StatefulWidget {
  final ProcessedSleepData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final SleepChartStyle style;
  final Size screenSize;
  final Function(ProcessedSleepData)? onTooltipTap;

  const SleepTooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<SleepTooltip> createState() => _SleepTooltipState();
}

class _SleepTooltipState extends State<SleepTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Map<String, String> _textMap;

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

  Widget _buildSleepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),

        // Main sleep display
        _buildMainSleepDisplay(),

        const SizedBox(height: 16),

        // Sleep stages breakdown (if available)
        if (widget.data.hasDetailedStages) ...[
          _buildSleepStagesBreakdown(),
          const SizedBox(height: 16),
        ],

        // Sleep quality and recommendation progress
        _buildSleepQualitySection(),

        const SizedBox(height: 12),

        // Sleep timing and efficiency (if available)
        if (widget.data.averageBedTime != null ||
            widget.data.averageEfficiency != null) ...[
          _buildTimingAndEfficiency(),
          const SizedBox(height: 12),
        ],

        // Additional stats based on view type
        _buildAdditionalStats(),
      ],
    );
  }

  Widget _buildMainSleepDisplay() {
    final displayValue = widget.data.displayValue;
    final displayLabel = _getDisplayLabel();
    final quality = widget.data.quality;
    final qualityColor = widget.style.getSleepQualityColor(quality);

    return Center(
      child: Column(
        children: [
          // Enhanced sleep duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  qualityColor.withOpacity(0.1),
                  qualityColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: qualityColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              widget.data.formattedDuration,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: qualityColor,
                    fontSize: 32,
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

          // Sleep quality badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  qualityColor.withOpacity(0.1),
                  qualityColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: qualityColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSleepQualityIcon(quality),
                  size: 18,
                  color: qualityColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _getSleepQualityLabel(quality),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: qualityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepStagesBreakdown() {
    final stagePercentages = widget.data.stagePercentages;
    final orderedStages = widget.data.orderedStages;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.style.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bedtime,
                size: 18,
                color: widget.style.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.style.sleepStagesTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.style.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sleep stages visual breakdown
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: orderedStages.map((entry) {
                  final stage = entry.key;
                  final percentage = stagePercentages[stage] ?? 0;
                  return Expanded(
                    flex: percentage.round(),
                    child: Container(
                      color: widget.style.getSleepStageColor(stage),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sleep stages list
          ...orderedStages.map((entry) {
            final stage = entry.key;
            final minutes = entry.value;
            final percentage = stagePercentages[stage] ?? 0;
            final stageColor = widget.style.getSleepStageColor(stage);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: stageColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getSleepStageLabel(stage),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    '${_formatDuration(minutes)} (${percentage.toInt()}%)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSleepQualitySection() {
    final displayValue = widget.data.displayValue;
    final progress = (displayValue / SleepRange.recommendedMax).clamp(0.0, 1.0);
    final meetsRecommendation = widget.data.meetsRecommendation;
    final quality = widget.data.quality;
    final qualityColor = widget.style.getSleepQualityColor(quality);

    String recommendationText;
    switch (widget.viewType) {
      case DateRangeType.day:
        recommendationText = widget.style.recommendedRangeDaily;
        break;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        recommendationText = widget.style.recommendedRangeAverage;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: meetsRecommendation
            ? widget.style.recommendationLineColor.withOpacity(0.1)
            : qualityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: meetsRecommendation
              ? widget.style.recommendationLineColor.withOpacity(0.3)
              : qualityColor.withOpacity(0.3),
          width: 1.5,
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
                  recommendationText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: qualityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[300],
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      qualityColor.withOpacity(0.7),
                      qualityColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (meetsRecommendation) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: widget.style.recommendationLineColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.style.goalAchievedMessage,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.style.recommendationLineColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getAdviceIcon(quality),
                  size: 16,
                  color: qualityColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getSleepAdvice(quality),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: qualityColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],

          // Sleep quality description
          const SizedBox(height: 8),
          Text(
            _getSleepQualityDescription(quality),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingAndEfficiency() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(
                widget.style.sleepPatternTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (widget.data.averageBedTime != null)
                _buildTimingItem(
                  widget.style.bedtimeLabel,
                  DateFormat('HH:mm').format(widget.data.averageBedTime!),
                  Icons.bedtime,
                ),
              if (widget.data.averageWakeTime != null)
                _buildTimingItem(
                  widget.style.wakeTimeLabel,
                  DateFormat('HH:mm').format(widget.data.averageWakeTime!),
                  Icons.wb_sunny,
                ),
              if (widget.data.averageEfficiency != null)
                _buildTimingItem(
                  widget.style.efficiencyLabel,
                  '${widget.data.averageEfficiency!.toInt()}%',
                  Icons.trending_up,
                ),
            ],
          ),
          if (widget.data.averageEfficiency != null) ...[
            const SizedBox(height: 12),
            Text(
              SleepRange.getEfficiencyDescription(
                  widget.data.averageEfficiency!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.blue[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimingItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.blue[600],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.blue[600],
              ),
          textAlign: TextAlign.center,
        ),
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
        return widget.style.sleepSummaryTitle;
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
        return widget.style.totalSleepLabel;
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        return widget.style.avgPerNightLabel;
    }
  }

  List<Widget> _buildStatsRow() {
    switch (widget.viewType) {
      case DateRangeType.day:
        return _buildDailyStats();
      case DateRangeType.week:
      case DateRangeType.month:
      case DateRangeType.year:
        return _buildPeriodStats();
    }
  }

  List<Widget> _buildDailyStats() {
    return [
      _buildStatItem(
        widget.style.totalSleepLabel,
        widget.data.formattedDuration,
        Icons.bedtime,
        widget.style.getSleepQualityColor(widget.data.quality),
      ),
      _buildStatItem(
        widget.style.recordingsLabel,
        widget.data.dataPointCount.toString(),
        Icons.analytics_outlined,
      ),
      _buildStatItem(
        widget.style.qualityLabel,
        _getSleepQualityLabel(widget.data.quality).split(' ').first,
        Icons.star,
        widget.style.getSleepQualityColor(widget.data.quality),
      ),
    ];
  }

  List<Widget> _buildPeriodStats() {
    final totalSleep = widget.data.totalSleepInPeriod;
    final avgDaily = widget.data.dailyAverage.round();
    final daysWithData = widget.data.dataPointCount;

    return [
      _buildStatItem(
        widget.style.totalSleepLabel,
        _formatDuration(totalSleep),
        Icons.bedtime,
      ),
      _buildStatItem(
        widget.style.avgPerNightLabel,
        _formatDuration(avgDaily),
        Icons.show_chart,
        widget.style.getSleepQualityColor(widget.data.quality),
      ),
      _buildStatItem(
        widget.style.sleepDaysLabel,
        daysWithData.toString(),
        Icons.calendar_today,
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

  // Helper methods for localized text
  String _getSleepQualityLabel(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return widget.style.poorSleepLabel;
      case SleepQuality.insufficient:
        return widget.style.insufficientSleepLabel;
      case SleepQuality.adequate:
        return widget.style.adequateSleepLabel;
      case SleepQuality.good:
        return widget.style.goodSleepLabel;
      case SleepQuality.excellent:
        return widget.style.excellentSleepLabel;
      case SleepQuality.excessive:
        return widget.style.excessiveSleepLabel;
    }
  }

  String _getSleepQualityDescription(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return widget.style.poorSleepDescription;
      case SleepQuality.insufficient:
        return widget.style.insufficientSleepDescription;
      case SleepQuality.adequate:
        return widget.style.adequateSleepDescription;
      case SleepQuality.good:
        return widget.style.goodSleepDescription;
      case SleepQuality.excellent:
        return widget.style.excellentSleepDescription;
      case SleepQuality.excessive:
        return widget.style.excessiveSleepDescription;
    }
  }

  String _getSleepAdvice(SleepQuality quality) {
    switch (quality) {
      case SleepQuality.poor:
        return widget.style.poorSleepAdvice;
      case SleepQuality.insufficient:
        return widget.style.insufficientSleepAdvice;
      case SleepQuality.adequate:
        return widget.style.adequateSleepAdvice;
      case SleepQuality.excessive:
        return widget.style.excessiveSleepAdvice;
      default:
        return widget.style.defaultSleepAdvice;
    }
  }

  String _getSleepStageLabel(SleepStage stage) {
    switch (stage) {
      case SleepStage.deep:
        return widget.style.deepSleepLabel;
      case SleepStage.rem:
        return widget.style.remSleepLabel;
      case SleepStage.light:
        return widget.style.lightSleepLabel;
      case SleepStage.awake:
        return widget.style.awakeSleepLabel;
      case SleepStage.awakeInBed:
        return widget.style.awakeInBedLabel;
      case SleepStage.unknown:
        return widget.style.unknownSleepLabel;
    }
  }

  // Helper methods
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  IconData _getSleepQualityIcon(quality) {
    switch (quality) {
      case SleepQuality.poor:
        return Icons.sentiment_very_dissatisfied;
      case SleepQuality.insufficient:
        return Icons.sentiment_dissatisfied;
      case SleepQuality.adequate:
        return Icons.sentiment_neutral;
      case SleepQuality.good:
        return Icons.sentiment_satisfied;
      case SleepQuality.excellent:
        return Icons.sentiment_very_satisfied;
      case SleepQuality.excessive:
        return Icons.sentiment_neutral;
      default:
        return Icons.bedtime;
    }
  }

  IconData _getAdviceIcon(quality) {
    switch (quality) {
      case SleepQuality.poor:
      case SleepQuality.insufficient:
        return Icons.trending_up;
      case SleepQuality.excessive:
        return Icons.trending_down;
      default:
        return Icons.info_outline;
    }
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
                width: 340,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.6,
                  minWidth: 300,
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
                                        color: widget.style.primaryColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.data.isHighest
                                            ? widget.style.bestSleepAnnotation
                                            : widget.style.leastSleepAnnotation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: widget.style.primaryColor,
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
                        _buildSleepContent(),
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
