import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/vital_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Mock data
  final double latestTemp = 38.0;
  final double latestSpO2 = 96.0;
  final double latestHeartRate = 130.0;

  // Mock user ID (6-digit) — will come from Supabase later
  final String _userId = '482019';

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
    ).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

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
    if ((hr >= 50 && hr < 60) || (hr > 100 && hr <= 120)) {
      return AppColors.warningStatus;
    }
    return AppColors.severeStatus;
  }

  // Show Scan Now bottom sheet with user ID
  void _showScanSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanNowSheet(userId: _userId, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub =
        isDark ? Colors.grey[400]! : AppColors.primary.withAlpha(160);
    final headerBg = isDark ? const Color(0xFF1E1E1E) : AppColors.primary;

    return Scaffold(
      body: CustomScrollView(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 34),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hello, User',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last scan: Today, 08:30 AM',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                              ],
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
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Body content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── SCAN NOW BUTTON ──────────────────────────────────────
                _ScanNowButton(onTap: _showScanSheet),
                const SizedBox(height: 28),

                // Section label
                Text(
                  'VITAL SIGNS SUMMARY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textSub,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Vital cards
                VitalSummaryCard(
                  title: 'Temperature',
                  value: latestTemp,
                  unit: '°C',
                  max: 42.0,
                  color: _getTempColor(latestTemp),
                  history: _tempData(),
                ),
                VitalSummaryCard(
                  title: 'Blood Oxygen',
                  value: latestSpO2,
                  unit: '% SpO2',
                  max: 100.0,
                  color: _getSpO2Color(latestSpO2),
                  history: _spo2Data(),
                ),
                VitalSummaryCard(
                  title: 'Heart Rate',
                  value: latestHeartRate,
                  unit: 'bpm',
                  max: 200.0,
                  color: _getHeartRateColor(latestHeartRate),
                  history: _hrData(),
                  isHeartRate: true,
                ),
                const SizedBox(height: 8),

                // Insight card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningStatus.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.warningStatus.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warningStatus, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your temperature is slightly elevated. Consider resting and staying hydrated.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : Colors.brown[800],
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
    );
  }

  List<FlSpot> _tempData() => const [
        FlSpot(1, 36.6), FlSpot(2, 36.7), FlSpot(3, 37.1),
        FlSpot(4, 37.5), FlSpot(5, 37.8), FlSpot(6, 38.2), FlSpot(7, 38.0),
      ];

  List<FlSpot> _spo2Data() => const [
        FlSpot(1, 98), FlSpot(2, 99), FlSpot(3, 98),
        FlSpot(4, 97), FlSpot(5, 96), FlSpot(6, 95), FlSpot(7, 96),
      ];

  List<FlSpot> _hrData() => const [
        FlSpot(1, 72), FlSpot(2, 75), FlSpot(3, 80),
        FlSpot(4, 85), FlSpot(5, 110), FlSpot(6, 125), FlSpot(7, 130),
      ];
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
  final bool isDark;

  const _ScanNowSheet({required this.userId, required this.isDark});

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
    await Future.delayed(const Duration(seconds: 3));
    _scanCtrl.stop();
    _scanCtrl.reset();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _done = true;
      });
    }
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('User ID copied to clipboard'),
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
          // Handle
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
                  // Spaced 6-digit display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.userId.split('').asMap().entries.map((e) {
                      return Row(
                        children: [
                          Container(
                            width: 42,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withAlpha(60)),
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
                          if (e.key < widget.userId.length - 1)
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(160),
                        ),
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
              builder: (_, __) => SizedBox(
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
                    const Icon(Icons.sensors_rounded,
                        color: AppColors.primary, size: 28),
                  ],
                ),
              ),
            )
          else if (_done)
            Column(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.normalStatus, size: 56),
                const SizedBox(height: 8),
                Text('Scan complete!',
                    style: TextStyle(
                        color: AppColors.normalStatus,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
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
                backgroundColor: _done
                    ? AppColors.normalStatus
                    : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _isScanning
                    ? 'Scanning...'
                    : _done
                        ? 'Done'
                        : 'Start Scanning',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
