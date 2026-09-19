import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/vital_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data for latest statistics
  final double latestTemp = 38.0; // Slightly high (Yellow)
  final double latestSpO2 = 96.0; // Normal (Green)
  final double latestHeartRate = 130.0; // Severe (Red)

  // Determine color based on conditions
  Color _getTempColor(double temp) {
    if (temp >= 36.5 && temp <= 37.5) return AppColors.normalStatus;
    if ((temp >= 35.0 && temp < 36.5) || (temp > 37.5 && temp <= 38.5)) {
      return AppColors.warningStatus;
    }
    return AppColors.severeStatus;
  }

  Color _getSpO2Color(double spo2) {
    if (spo2 >= 95.0 && spo2 <= 100.0) return AppColors.normalStatus;
    if (spo2 >= 90.0 && spo2 < 95.0) return AppColors.warningStatus;
    return AppColors.severeStatus;
  }

  Color _getHeartRateColor(double hr) {
    if (hr >= 60 && hr <= 100) return AppColors.normalStatus;
    if ((hr >= 50 && hr < 60) || (hr > 100 && hr <= 120)) return AppColors.warningStatus;
    return AppColors.severeStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent.withAlpha(50),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello, User',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your latest health overview',
                      style: TextStyle(fontSize: 14, color: AppColors.primary.withAlpha(150)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Vital Signs Summary',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Modern Summary Cards
            VitalSummaryCard(
              title: 'Temperature',
              value: latestTemp,
              unit: '°C',
              max: 42.0,
              color: _getTempColor(latestTemp),
              history: _tempHistoricalData(),
            ),
            VitalSummaryCard(
              title: 'Blood Oxygen',
              value: latestSpO2,
              unit: '% SpO2',
              max: 100.0,
              color: _getSpO2Color(latestSpO2),
              history: _spo2HistoricalData(),
            ),
            VitalSummaryCard(
              title: 'Heart Rate',
              value: latestHeartRate,
              unit: 'bpm',
              max: 200.0,
              color: _getHeartRateColor(latestHeartRate),
              history: _hrHistoricalData(),
            ),
          ],
        ),
      ),
    );
  }

  // Mock Historical Data (last 7 days)
  List<FlSpot> _tempHistoricalData() {
    return const [
      FlSpot(1, 36.6),
      FlSpot(2, 36.7),
      FlSpot(3, 37.1),
      FlSpot(4, 37.5),
      FlSpot(5, 37.8),
      FlSpot(6, 38.2),
      FlSpot(7, 38.0),
    ];
  }

  List<FlSpot> _spo2HistoricalData() {
    return const [
      FlSpot(1, 98),
      FlSpot(2, 99),
      FlSpot(3, 98),
      FlSpot(4, 97),
      FlSpot(5, 96),
      FlSpot(6, 95),
      FlSpot(7, 96),
    ];
  }

  List<FlSpot> _hrHistoricalData() {
    return const [
      FlSpot(1, 72),
      FlSpot(2, 75),
      FlSpot(3, 80),
      FlSpot(4, 85),
      FlSpot(5, 110),
      FlSpot(6, 125),
      FlSpot(7, 130),
    ];
  }
}
