import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/health_threshold.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/vital_record.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../widgets/vital_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();

  UserProfile? _userProfile;
  HealthThreshold? _threshold;
  VitalRecord? _latestRecord;
  List<VitalRecord> _recentRecords = [];
  bool _isLoading = true;
  StreamSubscription<List<VitalRecord>>? _streamSubscription;

  late AnimationController _headerController;
  late Animation<double> _headerFadeAnim;
  late Animation<Offset> _headerSlideAnim;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFadeAnim =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerController.forward();

    _loadData();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (!_supabase.isReady) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch user profile from auth or database
      final authUser = context.read<AuthProvider>().currentUser;
      final user = authUser ?? await _supabase.fetchUserProfile();
      final userId = user?.id;

      // 2. Fetch thresholds & records concurrently
      final threshold = await _supabase.fetchThresholds(userId);
      final latest = await _supabase.fetchLatestRecord(userId);
      final history = await _supabase.fetchHistory(userId, 10);

      if (mounted) {
        setState(() {
          _userProfile = user;
          _threshold = threshold;
          _latestRecord = latest;
          _recentRecords = history;
          _isLoading = false;
        });
      }

      // 3. Listen to real-time additions from ESP hardware device
      _streamSubscription?.cancel();
      _streamSubscription = _supabase.streamRecentRecords(userId, 10).listen((records) {
        if (mounted && records.isNotEmpty) {
          setState(() {
            _latestRecord = records.first;
            _recentRecords = records;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading Supabase data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getTempColor(double temp) {
    final maxT = _threshold?.maxTemp ?? 37.8;
    if (temp >= 36.5 && temp <= 37.5) return AppColors.normalStatus;
    if ((temp >= 35.0 && temp < 36.5) || (temp > 37.5 && temp <= maxT)) {
      return AppColors.warningStatus;
    }
    return AppColors.severeStatus;
  }

  Color _getSpO2Color(double spo2) {
    final minSp = _threshold?.minSpo2 ?? 94.00;
    if (spo2 >= minSp) return AppColors.normalStatus;
    if (spo2 >= 90.0 && spo2 < minSp) return AppColors.warningStatus;
    return AppColors.severeStatus;
  }

  Color _getHeartRateColor(double hr) {
    final minH = _threshold?.minHr ?? 50;
    final maxH = _threshold?.maxHr ?? 120;
    if (hr >= minH + 10 && hr <= maxH - 20) return AppColors.normalStatus;
    if ((hr >= minH && hr < minH + 10) || (hr > maxH - 20 && hr <= maxH)) {
      return AppColors.warningStatus;
    }
    return AppColors.severeStatus;
  }

  List<FlSpot> _getTempSpots() {
    if (_recentRecords.isEmpty) return const [FlSpot(0, 36.6)];
    final reversed = _recentRecords.reversed.toList();
    return List.generate(reversed.length, (i) => FlSpot(i.toDouble(), reversed[i].temperature));
  }

  List<FlSpot> _getSpo2Spots() {
    if (_recentRecords.isEmpty) return const [FlSpot(0, 98.0)];
    final reversed = _recentRecords.reversed.toList();
    return List.generate(reversed.length, (i) => FlSpot(i.toDouble(), reversed[i].spo2));
  }

  List<FlSpot> _getHrSpots() {
    if (_recentRecords.isEmpty) return const [FlSpot(0, 75.0)];
    final reversed = _recentRecords.reversed.toList();
    return List.generate(reversed.length, (i) => FlSpot(i.toDouble(), reversed[i].heartRate.toDouble()));
  }

  String _formatLastScanTime() {
    if (_latestRecord == null) return 'No scans recorded yet';
    final dt = _latestRecord!.recordedAt.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return 'Last scan: ${dt.day}/${dt.month}/${dt.year}, $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark ? Colors.grey[400]! : AppColors.primary.withAlpha(160);
    final headerBg = isDark ? const Color(0xFF1E1E1E) : AppColors.primary;

    final currentTemp = _latestRecord?.temperature ?? 0.0;
    final currentSpo2 = _latestRecord?.spo2 ?? 0.0;
    final currentHr = _latestRecord?.heartRate.toDouble() ?? 0.0;
    final userName = _userProfile?.fullName ?? 'User';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Collapsible gradient AppBar
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: headerBg,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF2A0A16), const Color(0xFF1E1E1E)]
                          : [AppColors.primary, const Color(0xFFB5274B)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: FadeTransition(
                        opacity: _headerFadeAnim,
                        child: SlideTransition(
                          position: _headerSlideAnim,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withAlpha(30),
                                child: const Icon(Icons.person, color: Colors.white, size: 34),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $userName',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatLastScanTime(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withAlpha(200),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Body content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!SupabaseConfig.isConfigured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(120)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Supabase credentials pending in supabase_config.dart. Add your URL and anon key to connect.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Section label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VITAL SIGNS SUMMARY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textSub,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_latestRecord == null && !_isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.withAlpha(50),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 48, color: AppColors.accent),
                          const SizedBox(height: 12),
                          const Text(
                            'No vital records found yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scans sent from your ESP device will appear here in real-time. You can also tap "Scan Now" to test a recording.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: textSub),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Vital cards displaying real data from database
                    VitalSummaryCard(
                      title: 'Temperature',
                      value: currentTemp,
                      unit: '°C',
                      max: 42.0,
                      color: currentTemp == 0 ? Colors.grey : _getTempColor(currentTemp),
                      history: _getTempSpots(),
                    ),
                    VitalSummaryCard(
                      title: 'Blood Oxygen',
                      value: currentSpo2,
                      unit: '% SpO2',
                      max: 100.0,
                      color: currentSpo2 == 0 ? Colors.grey : _getSpO2Color(currentSpo2),
                      history: _getSpo2Spots(),
                    ),
                    VitalSummaryCard(
                      title: 'Heart Rate',
                      value: currentHr,
                      unit: 'bpm',
                      max: 200.0,
                      color: currentHr == 0 ? Colors.grey : _getHeartRateColor(currentHr),
                      history: _getHrSpots(),
                      isHeartRate: true,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Dynamic Insight card based on real findings
                  if (_latestRecord != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _latestRecord!.isNormal
                            ? AppColors.normalStatus.withAlpha(20)
                            : AppColors.warningStatus.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _latestRecord!.isNormal
                              ? AppColors.normalStatus.withAlpha(80)
                              : AppColors.warningStatus.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _latestRecord!.isNormal
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: _latestRecord!.isNormal
                                ? AppColors.normalStatus
                                : AppColors.warningStatus,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _latestRecord!.isNormal
                                  ? 'All vital signs are within normal parameters. Keep up the healthy habits!'
                                  : 'One or more vital metrics exceeded standard threshold ranges. Consider resting.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.brown[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

