import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showScanSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = _userProfile?.id ?? '000000';
    final displayId = _userProfile?.displayId ?? '482019';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanNowSheet(
        userId: userId,
        displayId: displayId,
        isDark: isDark,
        onScanComplete: () => _loadData(),
      ),
    );
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

                  // ── SCAN NOW BUTTON ──────────────────────────────────────
                  _ScanNowButton(onTap: _showScanSheet),
                  const SizedBox(height: 28),

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

// ── Scan Now inline button ───────────────────────────────────────────────────

class _ScanNowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanNowButton({required this.onTap});

  @override
  State<_ScanNowButton> createState() => _ScanNowButtonState();
}

class _ScanNowButtonState extends State<_ScanNowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFB5274B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(100),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Scan Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scan Now bottom sheet ────────────────────────────────────────────────────

class _ScanNowSheet extends StatefulWidget {
  final String userId;
  final String displayId;
  final bool isDark;
  final VoidCallback onScanComplete;

  const _ScanNowSheet({
    required this.userId,
    required this.displayId,
    required this.isDark,
    required this.onScanComplete,
  });

  @override
  State<_ScanNowSheet> createState() => _ScanNowSheetState();
}

class _ScanNowSheetState extends State<_ScanNowSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  bool _isScanning = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ring1 = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _ring2 = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _done = false;
    });
    _scanCtrl.repeat(reverse: true);

    // If Supabase is ready, insert a simulated scan to test the pipeline
    if (SupabaseService().isReady && widget.userId != '000000') {
      try {
        await SupabaseService().insertRecord(
          userId: widget.userId,
          temperature: 36.8,
          spo2: 98.0,
          heartRate: 74,
          isNormal: true,
        );
      } catch (e) {
        debugPrint('Insert test scan error: $e');
      }
    } else {
      await Future.delayed(const Duration(seconds: 2));
    }

    _scanCtrl.stop();
    _scanCtrl.reset();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _done = true;
      });
      widget.onScanComplete();
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.displayId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID (${widget.displayId}) copied to clipboard'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textCol = widget.isDark ? Colors.white : AppColors.primary;
    final subCol = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Ready to Scan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Present your ID to the Vital Track device,\nthen tap Start Scanning.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: subCol, height: 1.5),
          ),
          const SizedBox(height: 28),

          // User ID card
          GestureDetector(
            onTap: _copyId,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFB5274B)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR USER ID',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.displayId.split('').asMap().entries.map((e) {
                      return Row(
                        children: [
                          Container(
                            width: 42,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withAlpha(60)),
                            ),
                            child: Center(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (e.key < widget.displayId.length - 1)
                            const SizedBox(width: 8),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, color: Colors.white.withAlpha(160), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to copy',
                        style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Scan animation area
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanCtrl,
              builder: (context, child) => SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _ring2.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withAlpha(60),
                            width: 10,
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _ring1.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withAlpha(40),
                        ),
                      ),
                    ),
                    const Icon(Icons.sensors_rounded, color: AppColors.primary, size: 28),
                  ],
                ),
              ),
            )
          else if (_done)
            Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.normalStatus, size: 56),
                const SizedBox(height: 8),
                const Text(
                  'Scan recorded successfully!',
                  style: TextStyle(
                    color: AppColors.normalStatus,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isScanning
                  ? null
                  : _done
                      ? () => Navigator.pop(context)
                      : _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _done ? AppColors.normalStatus : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _isScanning
                    ? 'Scanning...'
                    : _done
                        ? 'Done'
                        : 'Start Scanning',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
