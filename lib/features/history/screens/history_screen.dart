import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum HistoryFilter { all, warning, severe }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _activeFilter = HistoryFilter.all;

  final List<Map<String, dynamic>> _allHistory = List.generate(14, (index) {
    final date = DateTime.now().subtract(Duration(days: index));
    final double temp = 36.5 + (index % 4) * 0.55;
    final int spo2 = 91 + (index % 7);
    final int hr = 68 + (index * 7) % 65;
    return {
      'date': '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      'time': index % 2 == 0 ? '08:30 AM' : '08:00 PM',
      'temp': temp,
      'spo2': spo2,
      'hr': hr,
    };
  });

  List<Map<String, dynamic>> get _filtered {
    switch (_activeFilter) {
      case HistoryFilter.warning:
        return _allHistory.where((e) {
          final double t = e['temp'];
          final int s = e['spo2'];
          final int h = e['hr'];
          return _isWarning(t, s, h) && !_isSevere(t, s, h);
        }).toList();
      case HistoryFilter.severe:
        return _allHistory.where((e) {
          return _isSevere(e['temp'], e['spo2'], e['hr']);
        }).toList();
      default:
        return _allHistory;
    }
  }

  bool _isWarning(double t, int s, int h) {
    final tempW = (t >= 35.0 && t < 36.5) || (t > 37.5 && t <= 38.5);
    final spo2W = s >= 90 && s < 95;
    final hrW = (h >= 50 && h < 60) || (h > 100 && h <= 120);
    return tempW || spo2W || hrW;
  }

  bool _isSevere(double t, int s, int h) {
    return t < 35.0 || t > 38.5 || s < 90 || h < 50 || h > 120;
  }

  Color _overallColor(double t, int s, int h) {
    if (_isSevere(t, s, h)) return AppColors.severeStatus;
    if (_isWarning(t, s, h)) return AppColors.warningStatus;
    return AppColors.normalStatus;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Report exported successfully.'),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Scans', HistoryFilter.all, Icons.list_alt_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('Warnings', HistoryFilter.warning, Icons.warning_amber_outlined),
                  const SizedBox(width: 8),
                  _buildFilterChip('Severe', HistoryFilter.severe, Icons.dangerous_outlined),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              '${filtered.length} record${filtered.length == 1 ? '' : 's'} found',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No records found',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      final double t = entry['temp'];
                      final int s = entry['spo2'];
                      final int h = entry['hr'];
                      final Color statusColor = _overallColor(t, s, h);
                      return _buildHistoryCard(entry, statusColor, isDark, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, IconData icon) {
    final bool selected = _activeFilter == filter;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15,
              color: selected ? Colors.white : AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _activeFilter = filter),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      backgroundColor: AppColors.accent.withAlpha(20),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.accent.withAlpha(80)),
      showCheckmark: false,
    );
  }

  Widget _buildHistoryCard(
      Map<String, dynamic> entry, Color statusColor, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 15, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        entry['date'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          entry['time'],
                          style: TextStyle(
                            color: isDark ? AppColors.accent : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Temp', '${(entry['temp'] as double).toStringAsFixed(1)}°C',
                      Icons.thermostat_outlined, isDark),
                  _buildMetric('SpO2', '${entry['spo2']}%',
                      Icons.air_outlined, isDark),
                  _buildMetric('HR', '${entry['hr']} bpm',
                      Icons.favorite_outline, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
