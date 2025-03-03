import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../blood_pressure/models/blood_pressure_category.dart';
import '../../../blood_pressure/models/processed_blood_pressure_data.dart';
import '../../../models/date_range_type.dart';
import '../../styles/blood_pressure_chart_style.dart';

class ChartTooltip extends StatefulWidget {
  final ProcessedBloodPressureData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final BloodPressureChartStyle style;
  final Size screenSize;
  final List<ProcessedBloodPressureData>? dataContext;
  final Function(ProcessedBloodPressureData)? onTooltipTap;

  const ChartTooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    this.dataContext,
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

  // Tab state
  int _selectedTab = 0;
  final _tabNames = ['Overview', 'Details'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  String _formatTimeRange() {
    final startDate = widget.data.startDate;
    final endDate = widget.data.endDate;

    final isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    switch (widget.viewType) {
      case DateRangeType.day:
        if (isSameDay) {
          return DateFormat('MMM d, HH:mm').format(startDate);
        }
        return '${DateFormat('MMM d, HH:mm').format(startDate)} - ${DateFormat('HH:mm').format(endDate)}';

      case DateRangeType.week:
        if (isSameDay) {
          return DateFormat('EEE, MMM d').format(startDate);
        }
        return '${DateFormat('EEE, MMM d').format(startDate)} - ${DateFormat('EEE, MMM d').format(endDate)}';

      case DateRangeType.month:
        if (isSameDay) {
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

  Color _getCategoryColor() {
    return widget.style.getCategoryColor(widget.data.category);
  }

  String _getCategoryText() {
    switch (widget.data.category) {
      case BloodPressureCategory.normal:
        return 'Normal';
      case BloodPressureCategory.elevated:
        return 'Elevated';
      case BloodPressureCategory.high:
        return 'High';
      case BloodPressureCategory.crisis:
        return 'Crisis';
      case BloodPressureCategory.low:
        return 'Low';
    }
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        _getCategoryText(),
        style: TextStyle(
          color: _getCategoryColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: List.generate(
        _tabNames.length,
        (index) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _selectedTab == index
                        ? widget.style.selectedTabColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabNames[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedTab == index
                      ? widget.style.selectedTabColor
                      : Colors.grey,
                  fontWeight: _selectedTab == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.style.systolic,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.style.systolicColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.data.originalMeasurements.length > 1
                      ? '${widget.data.minSystolic}-${widget.data.maxSystolic}'
                      : widget.data.maxSystolic.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.style.diastolic,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.style.diastolicColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.data.originalMeasurements.length > 1
                      ? '${widget.data.minDiastolic}-${widget.data.maxDiastolic}'
                      : widget.data.minDiastolic.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.data.originalMeasurements.length > 1) ...[
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Average',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '${widget.data.avgSystolic.toStringAsFixed(1)}/${widget.data.avgDiastolic.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Readings',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                widget.data.dataPointCount.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsTab() {
    final measurements = widget.data.originalMeasurements;
    if (measurements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No detailed data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        for (final measurement in measurements.take(5)) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, HH:mm').format(measurement.date),
                  style: const TextStyle(fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      '${measurement.systolic ?? measurement.effectiveMaxSystolic}/',
                      style: TextStyle(
                        color: widget.style.systolicColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${measurement.diastolic ?? measurement.effectiveMaxDiastolic}',
                      style: TextStyle(
                        color: widget.style.diastolicColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (measurements.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${measurements.length - 5} more readings',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
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
            elevation: 8,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                widget.onTooltipTap?.call(widget.data);
                dismiss();
              },
              child: Container(
                width: 260,
                constraints: BoxConstraints(
                  maxHeight: widget.screenSize.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tooltip header with gradient background
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getCategoryColor().withOpacity(0.1),
                            _getCategoryColor().withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
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
                                  _formatTimeRange(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
                          const SizedBox(height: 8),
                          _buildCategoryBadge(),
                        ],
                      ),
                    ),
                    // Tab selector
                    _buildTabSelector(),
                    // Tab content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _selectedTab == 0
                              ? _buildOverviewTab()
                              : _buildDetailsTab(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
