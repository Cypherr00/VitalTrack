import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';

class VitalSummaryCard extends StatefulWidget {
  final String title;
  final double value;
  final String unit;
  final double max;
  final Color color;
  final List<FlSpot> history;
  final bool isHeartRate;

  const VitalSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.max,
    required this.color,
    required this.history,
    this.isHeartRate = false,
  });

  @override
  State<VitalSummaryCard> createState() => _VitalSummaryCardState();
}

class _VitalSummaryCardState extends State<VitalSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Gauge fill animation (0 → actual percent)
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final double targetPercent = (widget.value / widget.max).clamp(0.0, 1.0);
    _gaugeAnimation =
        Tween<double>(begin: 0.0, end: targetPercent).animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );
    _gaugeController.forward();

    // Pulse animation for heart rate only
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isHeartRate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.primary;
    final subtextColor = isDark ? Colors.grey[400]! : AppColors.primary.withAlpha(160);
    final trackColor = isDark
        ? Colors.white.withAlpha(20)
        : AppColors.accent.withAlpha(50);

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Animated Circular Gauge
              AnimatedBuilder(
                animation: _gaugeAnimation,
                builder: (context, child) {
                  return CircularPercentIndicator(
                    radius: 38.0,
                    lineWidth: 7.0,
                    percent: _gaugeAnimation.value,
                    center: widget.isHeartRate
                        ? ScaleTransition(
                            scale: _pulseAnimation,
                            child: Icon(Icons.favorite,
                                color: widget.color, size: 22),
                          )
                        : Text(
                            widget.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              color: textColor,
                            ),
                          ),
                    progressColor: widget.color,
                    backgroundColor: trackColor,
                    circularStrokeCap: CircularStrokeCap.round,
                  );
                },
              ),
              const SizedBox(width: 16),

              // Title, value, and unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: widget.color,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            widget.unit,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(widget.color),
                  ],
                ),
              ),

              // Sparkline
              SizedBox(
                width: 110,
                height: 55,
                child: LineChart(
                  LineChartData(
                    lineTouchData: const LineTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: _getMinY(widget.history),
                    maxY: _getMaxY(widget.history),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.history,
                        isCurved: true,
                        color: widget.color,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: widget.color.withAlpha(30),
                        ),
                      ),
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

  Widget _buildStatusBadge(Color color) {
    String label;
    Color bg;
    if (color == AppColors.normalStatus) {
      label = 'Normal';
      bg = AppColors.normalStatus;
    } else if (color == AppColors.warningStatus) {
      label = 'Warning';
      bg = AppColors.warningStatus;
    } else {
      label = 'Severe';
      bg = AppColors.severeStatus;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withAlpha(80), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: bg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    return spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.97;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    return spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.03;
  }
}
