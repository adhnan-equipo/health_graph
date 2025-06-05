import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/date_range_type.dart';
import '../models/base_chart_style.dart';
import '../models/base_processed_data.dart';

/// Generic tooltip widget for all health metric charts
/// Provides common tooltip structure and animations
class BaseTooltip<TData extends BaseProcessedData,
    TStyle extends BaseChartStyle> extends StatefulWidget {
  final TData data;
  final DateRangeType viewType;
  final VoidCallback onClose;
  final TStyle style;
  final Size screenSize;
  final Function(TData)? onTooltipTap;
  final Widget Function(TData) buildContent;
  final String title;

  const BaseTooltip({
    Key? key,
    required this.data,
    required this.viewType,
    required this.onClose,
    required this.style,
    required this.screenSize,
    required this.buildContent,
    required this.title,
    this.onTooltipTap,
  }) : super(key: key);

  @override
  State<BaseTooltip<TData, TStyle>> createState() =>
      _BaseTooltipState<TData, TStyle>();
}

class _BaseTooltipState<TData extends BaseProcessedData,
        TStyle extends BaseChartStyle> extends State<BaseTooltip<TData, TStyle>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.screenSize.width * 0.8,
                  maxHeight: widget.screenSize.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: widget.style.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.style.gridLineColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: widget.buildContent(widget.data),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.style.primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: widget.style.effectiveGridLabelStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: widget.style.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeRange(),
                  style: widget.style.effectiveDateLabelStyle.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _animationController.reverse().then((_) {
                widget.onClose();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for building common tooltip content sections
class TooltipContentBuilder {
  /// Build a statistics section with value pairs
  static Widget buildStatisticsSection(
    String title,
    List<({String label, String value, Color? valueColor})> stats,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: labelStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...stats.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stat.label, style: labelStyle),
                  Text(
                    stat.value,
                    style: valueStyle.copyWith(
                      color: stat.valueColor ?? valueStyle.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /// Build a section divider
  static Widget buildDivider() {
    return const Divider(height: 24);
  }

  /// Build an empty state message
  static Widget buildEmptyState(String message, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: style.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
