import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import 'dart:ui';

import '../../../config/routes.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _mainController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      const minSplashDuration = Duration(milliseconds: 2500);
      final startTime = DateTime.now();

      await authProvider.checkAuthState();

      final elapsedTime = DateTime.now().difference(startTime);
      final remainingTime = minSplashDuration - elapsedTime;

      if (remainingTime.inMilliseconds > 0) {
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;

      final appBox = Hive.box('app_data');
      final hasSeenOnboarding = appBox.get('hasSeenOnboarding', defaultValue: false);

      if (!hasSeenOnboarding) {
        debugPrint('📱 Navigating to: Onboarding');
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      } else if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        debugPrint('📱 Navigating to: Home (User: ${authProvider.currentUser!.name})');
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        debugPrint('📱 Navigating to: Login');
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('❌ Splash initialization error: $e');
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Deep gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF1A1F3A),
                  Color(0xFF0F1419),
                ],
              ),
            ),
          ),

          // Subtle grid pattern
          CustomPaint(
            size: Size.infinite,
            painter: GridPatternPainter(),
          ),

          // Orbital system with particles
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_orbitController, _pulseController, _glowController]),
              builder: (context, child) {
                return SizedBox(
                  width: 400,
                  height: 400,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Transform.scale(
                        scale: 1.0 + (_glowController.value * 0.1),
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF6C63FF).withOpacity(0.1 * _glowController.value),
                                const Color(0xFF6C63FF).withOpacity(0.05 * _glowController.value),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Orbital rings (3 layers)
                      ...List.generate(3, (ringIndex) {
                        final ringSize = 200.0 + (ringIndex * 40.0);
                        final speed = 1.0 + (ringIndex * 0.3);

                        return CustomPaint(
                          size: Size(ringSize, ringSize),
                          painter: OrbitRingPainter(
                            progress: (_orbitController.value * speed) % 1.0,
                            opacity: 0.3 - (ringIndex * 0.08),
                            ringIndex: ringIndex,
                          ),
                        );
                      }),

                      // Orbiting particles
                      ...List.generate(8, (index) {
                        final angle = ((_orbitController.value * 2 * math.pi) + (index * math.pi / 4));
                        final radius = 100.0 + (30 * math.sin(_orbitController.value * 2 * math.pi + index));
                        final x = math.cos(angle) * radius;
                        final y = math.sin(angle) * radius;

                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Container(
                            width: 8 + (index % 3) * 2,
                            height: 8 + (index % 3) * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  index % 2 == 0
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFF00D4FF),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (index % 2 == 0
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFF00D4FF)).withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Center core with pulsing effect
                      Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.15),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF6C63FF),
                                Color(0xFF5B54E8),
                                Color(0xFF4A47D6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Inner decorative ring
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 400),

                          // Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text(
                                  'COLLEGE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 6.0,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF00D4FF),
                                        Color(0xFF6C63FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Resource Hub',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      letterSpacing: -1.5,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6C63FF).withOpacity(0.1),
                                  const Color(0xFF00D4FF).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00D4FF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF00D4FF),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Study Smart. Learn Better.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom section with animated loading and version
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      // Custom loading animation
                      AnimatedBuilder(
                        animation: _orbitController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: List.generate(3, (index) {
                                final angle = (_orbitController.value * 2 * math.pi) +
                                    (index * 2 * math.pi / 3);
                                final radius = 20.0;
                                final x = math.cos(angle) * radius;
                                final y = math.sin(angle) * radius;

                                return Transform.translate(
                                  offset: Offset(x, y),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          index == 0
                                              ? const Color(0xFF6C63FF)
                                              : index == 1
                                              ? const Color(0xFF00D4FF)
                                              : const Color(0xFF7C4DFF),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (index == 0
                                              ? const Color(0xFF6C63FF)
                                              : index == 1
                                              ? const Color(0xFF00D4FF)
                                              : const Color(0xFF7C4DFF)).withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Version text
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for orbital rings
class OrbitRingPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final int ringIndex;

  OrbitRingPainter({
    required this.progress,
    required this.opacity,
    required this.ringIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        startAngle: progress * 2 * math.pi,
        endAngle: (progress * 2 * math.pi) + math.pi,
        colors: [
          Colors.transparent,
          Color(ringIndex == 0 ? 0xFF6C63FF : ringIndex == 1 ? 0xFF00D4FF : 0xFF7C4DFF)
              .withOpacity(opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Add dashed effect
    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(opacity * 0.2);

    const dashWidth = 5.0;
    const dashSpace = 10.0;
    double startAngle = 0;

    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashWidth / radius,
        false,
        dashedPaint,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(OrbitRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
          opacity != oldDelegate.opacity;
}

// Grid pattern painter
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}