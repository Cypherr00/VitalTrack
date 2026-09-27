import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../main/screens/main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Track whether the minimum display time has passed
  bool _minDelayDone = false;
  // Track whether AuthProvider has finished restoring the session
  bool _authReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: scale up and fade in
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Tagline: fade + slide up, slightly after logo
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Minimum splash display time (let the animation breathe)
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        _minDelayDone = true;
        _tryNavigate();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth readiness on every rebuild
    final auth = context.read<AuthProvider>();
    if (!auth.isLoading && !_authReady) {
      _authReady = true;
      _tryNavigate();
    }
  }

  /// Navigate only when BOTH the min delay is done AND auth has resolved.
  void _tryNavigate() {
    if (!_minDelayDone || !_authReady) return;
    if (!mounted) return;

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            isAuthenticated ? const MainLayout() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reactively check if auth just finished while we're still on screen
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoading && !_authReady) {
      _authReady = true;
      // Schedule navigation after the current build frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A0009), const Color(0xFF2D0E1C), const Color(0xFF121212)]
                : [AppColors.primary, const Color(0xFFA01030), const Color(0xFFE58FA5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated logo block
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Logo icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Vital Track',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Animated tagline
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _taglineFade,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Your health, always in sight.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(200),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Bottom loader
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Opacity(
                    opacity: _taglineFade.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
