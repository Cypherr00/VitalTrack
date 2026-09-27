import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/health_threshold.dart';
import '../../../core/models/vital_record.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';

enum HistoryFilter { all, normal, abnormal }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseService _supabase = SupabaseService();
  HistoryFilter _activeFilter = HistoryFilter.all;

  List<VitalRecord> _records = [];
  HealthThreshold? _threshold;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    if (!_supabase.isReady) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final authUser = context.read<AuthProvider>().currentUser;
      final user = authUser ?? await _supabase.fetchUserProfile();
      final threshold = await _supabase.fetchThresholds(user?.id);
      final history = await _supabase.fetchHistory(user?.id, 100);

      if (mounted) {
        setState(() {
          _threshold = threshold;
          _records = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<VitalRecord> get _filtered {
    switch (_activeFilter) {
      case HistoryFilter.normal:
        return _records.where((r) => r.isNormal && !_isMetricSevere(r)).toList();
      case HistoryFilter.abnormal:
        return _records.where((r) => !r.isNormal || _isMetricSevere(r) || _isMetricWarning(r)).toList();
      default:
        return _records;
    }
  }

  bool _isMetricWarning(VitalRecord r) {
    final maxT = _threshold?.maxTemp ?? 37.8;
    final minSp = _threshold?.minSpo2 ?? 94.00;
    final minH = _threshold?.minHr ?? 50;
    final maxH = _threshold?.maxHr ?? 120;

    final tempW = (r.temperature >= 35.0 && r.temperature < 36.5) ||
        (r.temperature > 37.5 && r.temperature <= maxT);
    final spo2W = r.spo2 >= 90 && r.spo2 < minSp;
    final hrW = (r.heartRate >= minH && r.heartRate < minH + 10) ||
        (r.heartRate > maxH - 20 && r.heartRate <= maxH);
    return tempW || spo2W || hrW;
  }

  bool _isMetricSevere(VitalRecord r) {
    final maxT = _threshold?.maxTemp ?? 37.8;
    final minH = _threshold?.minHr ?? 50;
    final maxH = _threshold?.maxHr ?? 120;

    return r.temperature < 35.0 ||
        r.temperature > (maxT + 0.7) ||
        r.spo2 < 90 ||
        r.heartRate < minH ||
        r.heartRate > maxH;
  }

  Color _overallColor(VitalRecord r) {
    if (_isMetricSevere(r)) return AppColors.severeStatus;
    if (_isMetricWarning(r) || !r.isNormal) return AppColors.warningStatus;
    return AppColors.normalStatus;
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    return '$d/$m/$y';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final min = local.minute.toString().padLeft(2, '0');
    final p = local.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$min $p';
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
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primary,
        child: Column(
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
                    _buildFilterChip('Normal', HistoryFilter.normal, Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    _buildFilterChip('Abnormal / Alerts', HistoryFilter.abnormal, Icons.warning_amber_outlined),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isLoading
                        ? 'Loading records from Supabase...'
                        : '${filtered.length} record${filtered.length == 1 ? '' : 's'} in database',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            if (!SupabaseConfig.isConfigured)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Set Supabase credentials in supabase_config.dart to query live records.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Records List
            Expanded(
              child: _isLoading && _records.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No records found in database',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'When the ESP hardware records a reading,\nit will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final record = filtered[index];
                            final Color statusColor = _overallColor(record);
                            return _buildHistoryCard(record, statusColor, isDark, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, IconData icon) {
    final bool selected = _activeFilter == filter;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? Colors.white : AppColors.primary),
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
      VitalRecord record, Color statusColor, bool isDark, int index) {
    final dateStr = _formatDate(record.recordedAt);
    final timeStr = _formatTime(record.recordedAt);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index < 10 ? index * 40 : 0)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
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
                        dateStr,
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
                          timeStr,
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
                  _buildMetric('Temp', '${record.temperature.toStringAsFixed(1)}°C',
                      Icons.thermostat_outlined, isDark),
                  _buildMetric('SpO2', '${record.spo2.toStringAsFixed(0)}%',
                      Icons.air_outlined, isDark),
                  _buildMetric('HR', '${record.heartRate} bpm',
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
