import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _floatingController;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Access Resources\nAnytime',
      description:
      'Download exam papers, notes, and study materials from any college, department, and semester',
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      primaryColor: Color(0xFF6C63FF),
      secondaryColor: Color(0xFF5B54E8),
    ),
    OnboardingItem(
      title: 'Smart Search\n& Filters',
      description:
      'Find exactly what you need with powerful search and filtering options tailored to your needs',
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      primaryColor: Color(0xFF00D4FF),
      secondaryColor: Color(0xFF0099CC),
    ),
    OnboardingItem(
      title: 'Bookmark &\nDownload',
      description:
      'Save your favorite resources and access them offline anytime, anywhere',
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      primaryColor: Color(0xFF7C4DFF),
      secondaryColor: Color(0xFF6200EA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _completeOnboarding() async {
    final appBox = Hive.box('app_data');
    await appBox.put('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentItem = _onboardingItems[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                color: currentItem.primaryColor.withOpacity(0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(currentItem),

                // Main Content with SingleChildScrollView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _onboardingItems.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_onboardingItems[index]);
                    },
                  ),
                ),

                // Bottom Section
                _buildBottomSection(currentItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo or Brand
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EduResources',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Skip Button
          GestureDetector(
            onTap: _completeOnboarding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.05),

                    // Floating Image Container
                    AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        final floatingValue = math.sin(_floatingController.value * math.pi * 2) * 10;

                        return Transform.translate(
                          offset: Offset(0, floatingValue),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: math.min(constraints.maxWidth * 0.7, 260),
                                  height: math.min(constraints.maxWidth * 0.7, 260),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    color: item.primaryColor.withOpacity(0.05),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.primaryColor.withOpacity(0.15),
                                        blurRadius: 40,
                                        offset: const Offset(0, 20),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Gradient Overlay Border
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(32),
                                            border: Border.all(
                                              color: item.primaryColor.withOpacity(0.1),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Image
                                      Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(28),
                                          child: Image.asset(
                                            item.imagePath,
                                            fit: BoxFit.contain,
                                            width: math.min(constraints.maxWidth * 0.6, 220),
                                            height: math.min(constraints.maxWidth * 0.6, 220),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: constraints.maxHeight * 0.08),

                    // Title
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Curves.easeOut,
                      )),
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[900],
                          height: 1.2,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: constraints.maxHeight * 0.03),

                    // Description
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Curves.easeOut,
                      )),
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          height: 1.6,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: constraints.maxHeight * 0.05),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(OnboardingItem item) {
    final isLastPage = _currentPage == _onboardingItems.length - 1;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingItems.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? item.primaryColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) {
              _scaleController.reverse();
              if (isLastPage) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              }
            },
            onTapCancel: () => _scaleController.reverse(),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.primaryColor, item.secondaryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Page Counter
          Text(
            '${_currentPage + 1} / ${_onboardingItems.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotSize = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}