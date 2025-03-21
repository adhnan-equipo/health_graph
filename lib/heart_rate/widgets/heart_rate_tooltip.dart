import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../../utils/tooltip_position.dart';
import '../models/heart_rate_range.dart';
import '../models/processed_heart_rate_data.dart';
import '../styles/heart_rate_chart_style.dart';

class HeartRateTooltip extends StatefulWidget {
  final ProcessedHeartRateData data;
  final TooltipPosition position;
  final HeartRateChartStyle style;
  final VoidCallback onClose;
  final Function(ProcessedHeartRateData)? onTooltipTap;
  final DateRangeType viewType;

  const HeartRateTooltip({
    Key? key,
    required this.data,
    required this.position,
    required this.style,
    required this.onClose,
    this.onTooltipTap,
    required this.viewType,
  }) : super(key: key);

  @override
  State<HeartRateTooltip> createState() => _HeartRateTooltipState();
}

class _HeartRateTooltipState extends State<HeartRateTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Dismiss the tooltip with animation
  Future<void> dismiss() async {
    await _animationController.reverse();
    widget.onClose();
  }

  /// Format date range based on view type
  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    switch (widget.viewType) {
      case DateRangeType.day:
        if (startDate.hour == endDate.hour) {
          return DateFormat('h:mm a').format(startDate);
        }
        return '${DateFormat('h:mm a').format(startDate)} - ${DateFormat('h:mm a').format(endDate)}';

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

  /// Build summary section with heart rate values
  Widget _buildSummarySection(BuildContext context) {
    final zoneColor = widget.style.getZoneColor(widget.data.avgValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.style.summaryLabel,
          style: widget.style.effectiveSubHeaderStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _buildSummaryRow(
          context,
          widget.style.heartRateLabel,
          widget.data.isRangeData
              ? '${widget.data.minValue} - ${widget.data.maxValue}'
              : '${widget.data.avgValue.toInt()}',
          widget.style.primaryColor,
        ),
        if (widget.data.restingRate != null) ...[
          const SizedBox(height: 4),
          _buildSummaryRow(
            context,
            widget.style.restingRateLabel,
            '${widget.data.restingRate}',
            widget.style.restingRateColor,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.style.averageLabel,
              style: widget.style.effectiveAverageLabelStyle,
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.data.avgValue.toStringAsFixed(1)} ',
                    style: widget.style.effectiveValueLabelStyle,
                  ),
                  TextSpan(
                    text: widget.style.bpmLabel,
                    style: widget.style.effectiveAverageLabelStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: zoneColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: zoneColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: zoneColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                HeartRateRange.getZoneDescription(
                    widget.data.avgValue, widget.style),
                style: widget.style.effectiveZoneTextStyle.copyWith(
                  color: zoneColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build measurements list if multiple measurements exist
  Widget _buildMeasurementsList(BuildContext context) {
    final measurements = widget.data.originalMeasurements;
    if (measurements.isEmpty || measurements.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 8, thickness: 1),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${widget.style.measurementsLabel} (${measurements.length})',
            style: widget.style.effectiveSubHeaderStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build statistics section (HRV, Range, etc.)
  Widget _buildStatisticsSection(BuildContext context) {
    if (!widget.data.isRangeData && widget.data.hrv == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, thickness: 1),
        Text(
          widget.style.statisticsLabel,
          style: widget.style.effectiveSubHeaderStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (widget.data.isRangeData)
              Expanded(
                child: _buildStatItem(
                  context,
                  widget.style.rangeLabel,
                  '${widget.data.maxValue - widget.data.minValue} ${widget.style.bpmLabel}',
                  Icons.compare_arrows,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Build a summary row with label and value
  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color indicatorColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: widget.style.effectiveAverageLabelStyle,
            ),
          ],
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: widget.style.effectiveValueLabelStyle,
              ),
              TextSpan(
                text: widget.style.bpmLabel,
                style: widget.style.effectiveAverageLabelStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a statistic item with icon
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: widget.style.effectiveDateLabelStyle.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: widget.style.effectiveValueLabelStyle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build tooltip with animation
    return Positioned(
      left: widget.position.left,
      top: widget.position.top,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            if (widget.onTooltipTap != null) {
              widget.onTooltipTap!(widget.data);
            }
            dismiss();
          },
          child: Stack(
            children: [
              if (widget.position.alignLeft)
                Positioned(
                  top: 20,
                  right: -8,
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: widget.style.tooltipShadow,
                      ),
                    ),
                  ),
                ),
              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: widget.style.tooltipBorderRadius,
                ),
                child: Container(
                  width: 280,
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
                              style: widget.style.effectiveSubHeaderStyle,
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
                      const SizedBox(height: 4),
                      _buildSummarySection(context),
                      _buildStatisticsSection(context),
                      _buildMeasurementsList(context),
                    ],
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
