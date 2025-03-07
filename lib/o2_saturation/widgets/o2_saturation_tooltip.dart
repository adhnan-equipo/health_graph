// lib/o2_saturation/widgets/o2_saturation_tooltip.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/processed_o2_saturation_data.dart';
import '../styles/o2_saturation_chart_style.dart';

class O2SaturationTooltip extends StatefulWidget {
  final ProcessedO2SaturationData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final O2SaturationChartStyle style;
  final Size screenSize;
  final Function(ProcessedO2SaturationData)? onTooltipTap;

  const O2SaturationTooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<O2SaturationTooltip> createState() => _O2SaturationTooltipState();
}

class _O2SaturationTooltipState extends State<O2SaturationTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    switch (widget.viewType) {
      case DateRangeType.day:
        if (widget.data.dataPointCount <= 1) {
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

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.style.summaryLabel,
          style: widget.style.effectiveStatisticsLabelStyle,
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          widget.style.o2SaturationLabel,
          widget.data.dataPointCount > 1
              ? '${widget.data.minValue} - ${widget.data.maxValue}${widget.style.percentLabel}'
              : '${widget.data.minValue}${widget.style.percentLabel}',
          widget.style.primaryColor,
        ),
        const SizedBox(height: 8),
        if (widget.data.avgPulseRate != null)
          _buildSummaryRow(
            context,
            widget.style.pulseRateLabel,
            widget.data.dataPointCount > 1 &&
                    widget.data.minPulseRate != null &&
                    widget.data.maxPulseRate != null
                ? '${widget.data.minPulseRate} - ${widget.data.maxPulseRate} ${widget.style.bpmLabel}'
                : '${widget.data.avgPulseRate!.toStringAsFixed(0)} ${widget.style.bpmLabel}',
            widget.style.pulseRateColor,
          ),
        const SizedBox(height: 8),
        if (widget.data.dataPointCount > 1)
          _buildSummaryRow(
            context,
            widget.style.averageLabel,
            '${widget.data.avgValue.toStringAsFixed(1)}${widget.style.percentLabel}',
            null,
          ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color? indicatorColor,
  ) {
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
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: widget.style.effectiveTooltipTextStyle,
            ),
          ],
        ),
        Text(
          value,
          style: widget.style.effectiveValueLabelStyle,
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    if (widget.data.dataPointCount <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          widget.style.statisticsLabel,
          style: widget.style.effectiveStatisticsLabelStyle,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.style.standardDeviationLabel,
                  style: widget.style.effectiveTooltipTextStyle,
                ),
                Text(
                  widget.data.stdDev.toStringAsFixed(1),
                  style: widget.style.effectiveValueLabelStyle,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.style.readingsLabel,
                  style: widget.style.effectiveTooltipTextStyle,
                ),
                Text(
                  widget.data.dataPointCount.toString(),
                  style: widget.style.effectiveValueLabelStyle,
                ),
              ],
            ),
          ],
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
              borderRadius: widget.style.tooltipBorderRadius,
            ),
            child: InkWell(
              borderRadius: widget.style.tooltipBorderRadius,
              onTap: () async {
                widget.onTooltipTap?.call(widget.data);
                await dismiss();
              },
              child: Container(
                width: 280, // Fixed width for better layout consistency
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.6,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatTimeRange(),
                            style: widget.style.effectiveHeaderStyle
                                .copyWith(fontSize: 16),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: dismiss,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummarySection(context),
                    _buildStatisticsSection(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
