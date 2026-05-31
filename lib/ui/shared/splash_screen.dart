import 'dart:math' as math;
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A polished animated splash screen shown while the app initializes.
/// Automatically navigates to the appropriate screen once auth state resolves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _ringAnimation;
  late final Animation<double> _slideAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Fade in the logo and text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Pulse the icon gently
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Rotating ring around the icon
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _ringAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );
    _ringController.repeat();

    // Start fade in
    _fadeController.forward();

    // Listen for auth state to resolve
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitAndNavigate();
    });
  }

  Future<void> _waitAndNavigate() async {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Wait for session to finish loading (max 5 seconds safety)
    int waited = 0;
    while (session.isLoading && waited < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }

    // Ensure minimum splash display time of 2.2 seconds
    final elapsed = waited * 100;
    if (elapsed < 2200) {
      await Future.delayed(Duration(milliseconds: 2200 - elapsed));
    }

    if (!mounted || _navigated) return;
    _navigated = true;

    final route = session.isAuthenticated ? session.dashboardRoute : '/login';

    // Fade out then navigate
    await _fadeController.reverse();
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1E3D),
              Color(0xFF0F2850),
              Color(0xFF163566),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Animated logo with ring
                _buildAnimatedLogo(),
                const SizedBox(height: 36),
                // App name
                const Text(
                  'Daily Fitness',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Premium Gym Equipment & Supplements',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(flex: 3),
                // Loading indicator
                _buildLoadingIndicator(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating arc ring
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _ringAnimation.value,
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(140, 140),
              painter: _ArcRingPainter(color: const Color(0xFF4AB3F4)),
            ),
          ),
          // Pulsing icon container
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4AB3F4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4AB3F4).withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4AB3F4)),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Loading your experience...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white38,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the rotating arc ring around the logo
class _ArcRingPainter extends CustomPainter {
  final Color color;

  _ArcRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw two arcs for a balanced look
    canvas.drawArc(rect, 0, math.pi * 0.7, false, paint);
    canvas.drawArc(rect, math.pi, math.pi * 0.7, false, paint);

    // Subtle secondary arcs
    paint.color = color.withOpacity(0.2);
    paint.strokeWidth = 1.5;
    canvas.drawArc(rect, math.pi * 0.9, math.pi * 0.4, false, paint);
    canvas.drawArc(rect, math.pi * 1.9, math.pi * 0.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
