import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/health_threshold.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/vital_record.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/pdf_export_service.dart';
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

  UserProfile? _userProfile;
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
          _userProfile = user;
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

  String _getFilterLabel() {
    switch (_activeFilter) {
      case HistoryFilter.normal:
        return 'Normal Scans Only';
      case HistoryFilter.abnormal:
        return 'Abnormal / Alerts Only';
      case HistoryFilter.all:
        return 'All Scans';
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

  void _showExportSheet() {
    final authUser = context.read<AuthProvider>().currentUser;
    final user = _userProfile ?? authUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);

    if (_records.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('No vital records available to export.')),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    bool exportFilteredOnly = _activeFilter != HistoryFilter.all;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final recordsToExport = exportFilteredOnly ? _filtered : _records;
            final filterName = exportFilteredOnly ? _getFilterLabel() : 'All Scans';

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Vitals Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Patient: ${user?.fullName.isNotEmpty == true ? user!.fullName : "User"} (ID: ${user?.displayId ?? "N/A"})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Option to toggle scope if a filter is active
                  if (_activeFilter != HistoryFilter.all) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Export current filter only',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Only include $filterName (${_filtered.length} scans)',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: exportFilteredOnly,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => exportFilteredOnly = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats preview badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSheetMetric('Total Scans', '${recordsToExport.length}'),
                        _buildSheetMetric('Scope', filterName),
                        _buildSheetMetric('Format', 'PDF (A4)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.print_outlined, size: 20),
                    label: const Text(
                      'Preview & Save / Print PDF',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await PdfExportService.printOrSaveReport(
                          user: user,
                          records: recordsToExport,
                          threshold: _threshold,
                          filterLabel: filterName,
                        );
                      } catch (e) {
                        debugPrint('PDF Print Error: $e');
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to generate PDF: $e'),
                            backgroundColor: AppColors.severeStatus,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.primary,
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : AppColors.primary.withAlpha(120),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: const Text(
                      'Share PDF File',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await PdfExportService.shareReport(
                          user: user,
                          records: recordsToExport,
                          threshold: _threshold,
                          filterLabel: filterName,
                        );
                      } catch (e) {
                        debugPrint('PDF Share Error: $e');
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to share PDF: $e'),
                            backgroundColor: AppColors.severeStatus,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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
            onPressed: _showExportSheet,
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
                        ? 'Loading records...'
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

            // Records List
            Expanded(
              child: _isLoading && _records.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_outlined, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'No records found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scans from your ESP hardware will appear here.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(filtered[index], isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, IconData icon) {
    final isSelected = _activeFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : AppColors.primary),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeFilter = filter),
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.background,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white12 : AppColors.primary.withAlpha(50)),
        ),
      ),
    );
  }

  Widget _buildRecordCard(VitalRecord record, bool isDark) {
    final statusColor = _overallColor(record);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    String statusLabel = 'NORMAL';
    if (_isMetricSevere(record)) {
      statusLabel = 'CRITICAL';
    } else if (_isMetricWarning(record) || !record.isNormal) {
      statusLabel = 'ATTENTION';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(80),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : statusColor.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(record.recordedAt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(record.recordedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
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
