import 'package:flutter/material.dart';

import '../../../blood_pressure/models/blood_pressure_category.dart';
import '../../controllers/chart_controller.dart';
import '../../styles/blood_pressure_chart_style.dart';

class BloodPressureSummary extends StatefulWidget {
  final ChartController controller;
  final BloodPressureChartStyle style;

  const BloodPressureSummary({
    Key? key,
    required this.controller,
    required this.style,
  }) : super(key: key);

  @override
  State<BloodPressureSummary> createState() => _BloodPressureSummaryState();
}

class _BloodPressureSummaryState extends State<BloodPressureSummary> {
  bool _isSummaryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasData =
        widget.controller.processedData.where((d) => !d.isEmpty).isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSummaryExpanded ? 400 : 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildHeader(context, hasData),
          if (hasData) ...[
            Expanded(
              child: AnimatedCrossFade(
                firstChild: _buildCollapsedContent(context),
                secondChild: _buildExpandedContent(context),
                crossFadeState: _isSummaryExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Text(
                  'No data available for this period',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool hasData) {
    final numReadings = widget.controller.processedData
        .fold(0, (sum, d) => sum + (d.isEmpty ? 0 : d.dataPointCount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blood Pressure Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$numReadings readings',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (hasData)
            IconButton(
              icon: Icon(
                _isSummaryExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _isSummaryExpanded = !_isSummaryExpanded;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    final avgSystolic = widget.controller.avgSystolic.round();
    final avgDiastolic = widget.controller.avgDiastolic.round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAverageReading(
            context,
            widget.controller.avgSystolic.round(),
            widget.controller.avgDiastolic.round(),
          ),
          _buildCategoryIndicator(
            context,
            avgSystolic,
            avgDiastolic,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageReading(
      BuildContext context, int systolic, int diastolic) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Average',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$systolic',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.style.systolicColor,
              ),
            ),
            Text(
              '/',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$diastolic',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.style.diastolicColor,
              ),
            ),
            const Text(
              ' mmHg',
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryIndicator(
      BuildContext context, int systolic, int diastolic) {
    final category = _getBPCategory(systolic, diastolic);
    final categoryColor = widget.style.getCategoryColor(category);
    final categoryText = _getCategoryText(category);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: categoryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            categoryText,
            style: TextStyle(
              color: categoryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          _buildDetailRow(
            'Average',
            '${widget.controller.avgSystolic.round()}/${widget.controller.avgDiastolic.round()} mmHg',
          ),
          _buildDetailRow(
            'Systolic Range',
            '${widget.controller.minSystolic}-${widget.controller.maxSystolic} mmHg',
          ),
          _buildDetailRow(
            'Diastolic Range',
            '${widget.controller.minDiastolic}-${widget.controller.maxDiastolic} mmHg',
          ),
          _buildRangeIndicators(context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeIndicators(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Normal Ranges:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  _buildRangeBar(
                    context,
                    'Systolic',
                    90,
                    120,
                    widget.controller.minSystolic,
                    widget.controller.maxSystolic,
                    widget.controller.avgSystolic.round(),
                    widget.style.systolicColor,
                  ),
                  const SizedBox(width: 16),
                  _buildRangeBar(
                    context,
                    'Diastolic',
                    60,
                    80,
                    widget.controller.minDiastolic,
                    widget.controller.maxDiastolic,
                    widget.controller.avgDiastolic.round(),
                    widget.style.diastolicColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeBar(
    BuildContext context,
    String label,
    int normalMin,
    int normalMax,
    int actualMin,
    int actualMax,
    int avgValue,
    Color color,
  ) {
    // Calculate a reasonable scale for the visualization
    final visualMin = (actualMin * 0.9).floor().clamp(40, 200);
    final visualMax = (actualMax * 1.1).ceil().clamp(40, 200);
    final range = visualMax - visualMin;

    // Calculate positions as percentages
    final normalMinPos = ((normalMin - visualMin) / range).clamp(0.0, 1.0);
    final normalMaxPos = ((normalMax - visualMin) / range).clamp(0.0, 1.0);
    final actualMinPos = ((actualMin - visualMin) / range).clamp(0.0, 1.0);
    final actualMaxPos = ((actualMax - visualMin) / range).clamp(0.0, 1.0);
    final avgPos = ((avgValue - visualMin) / range).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: _RangeBarPainter(
                normalMinPos: normalMinPos,
                normalMaxPos: normalMaxPos,
                actualMinPos: actualMinPos,
                actualMaxPos: actualMaxPos,
                avgPos: avgPos,
                color: color,
                normalRangeColor: widget.style.normalRangeColor,
                normalMin: normalMin,
                normalMax: normalMax,
                actualMin: actualMin,
                actualMax: actualMax,
                avgValue: avgValue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BloodPressureCategory _getBPCategory(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return BloodPressureCategory.crisis;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureCategory.high;
    }
    if (systolic >= 130 || diastolic >= 80) {
      return BloodPressureCategory.elevated;
    }
    if (systolic < 90 || diastolic < 60) {
      return BloodPressureCategory.low;
    }
    return BloodPressureCategory.normal;
  }

  String _getCategoryText(BloodPressureCategory category) {
    switch (category) {
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
}

class _RangeBarPainter extends CustomPainter {
  final double normalMinPos;
  final double normalMaxPos;
  final double actualMinPos;
  final double actualMaxPos;
  final double avgPos;
  final Color color;
  final Color normalRangeColor;
  final int normalMin;
  final int normalMax;
  final int actualMin;
  final int actualMax;
  final int avgValue;

  _RangeBarPainter({
    required this.normalMinPos,
    required this.normalMaxPos,
    required this.actualMinPos,
    required this.actualMaxPos,
    required this.avgPos,
    required this.color,
    required this.normalRangeColor,
    required this.normalMin,
    required this.normalMax,
    required this.actualMin,
    required this.actualMax,
    required this.avgValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = size.height * 0.4;
    final barY = size.height * 0.3;

    // Draw background bar
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, size.width, barHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Draw normal range
    final normalPaint = Paint()
      ..color = normalRangeColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          normalMinPos * size.width,
          barY,
          (normalMaxPos - normalMinPos) * size.width,
          barHeight,
        ),
        const Radius.circular(4),
      ),
      normalPaint,
    );

    // Draw actual range
    final actualPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          actualMinPos * size.width,
          barY,
          (actualMaxPos - actualMinPos) * size.width,
          barHeight,
        ),
        const Radius.circular(4),
      ),
      actualPaint,
    );

    // Draw average line
    final avgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(avgPos * size.width, barY - 4),
      Offset(avgPos * size.width, barY + barHeight + 4),
      avgPaint,
    );

    // Draw labels
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Min label
    labelPaint
      ..text = TextSpan(
        text: actualMin.toString(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      )
      ..layout();

    labelPaint.paint(
      canvas,
      Offset(
        (actualMinPos * size.width) - (labelPaint.width / 2),
        barY + barHeight + 8,
      ),
    );

    // Max label
    labelPaint
      ..text = TextSpan(
        text: actualMax.toString(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      )
      ..layout();

    labelPaint.paint(
      canvas,
      Offset(
        (actualMaxPos * size.width) - (labelPaint.width / 2),
        barY + barHeight + 8,
      ),
    );

    // Average label
    labelPaint
      ..text = TextSpan(
        text: avgValue.toString(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      )
      ..layout();

    labelPaint.paint(
      canvas,
      Offset(
        (avgPos * size.width) - (labelPaint.width / 2),
        barY - labelPaint.height - 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RangeBarPainter oldDelegate) {
    return normalMinPos != oldDelegate.normalMinPos ||
        normalMaxPos != oldDelegate.normalMaxPos ||
        actualMinPos != oldDelegate.actualMinPos ||
        actualMaxPos != oldDelegate.actualMaxPos ||
        avgPos != oldDelegate.avgPos ||
        color != oldDelegate.color ||
        normalRangeColor != oldDelegate.normalRangeColor;
  }
}
