import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class VitalSummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final double max;
  final Color color;
  final List<FlSpot> history;

  const VitalSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.max,
    required this.color,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    double percent = value / max;
    if (percent > 1.0) percent = 1.0;
    if (percent < 0.0) percent = 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Circular Indicator
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 7.0,
              percent: percent,
              center: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppColors.primary,
                ),
              ),
              progressColor: color,
              backgroundColor: AppColors.accent.withAlpha(50),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 16),
            // Title and Unit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
            // Sparkline (Mini Chart)
            SizedBox(
              width: 120,
              height: 60,
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: false), // Disable touch for summary
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: _getMinY(history),
                  maxY: _getMaxY(history),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withAlpha(40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.98; // Small padding below
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    return spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.02; // Small padding above
  }
}
