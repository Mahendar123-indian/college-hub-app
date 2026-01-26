import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/smart_learning_provider.dart';
import 'dart:math' as math;

class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _chartController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;

  String _selectedPeriod = 'Week';
  final List<String> _periods = ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    context.read<SmartLearningProvider>().loadAnalytics();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _chartController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Consumer<SmartLearningProvider>(
              builder: (context, provider, _) {
                final analytics = provider.analytics;

                if (analytics == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.cyan,
                                      Colors.purple,
                                      Colors.pink,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Loading Analytics...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(child: _buildPeriodSelector()),
                    SliverToBoxAdapter(child: _buildStatsOverview(analytics)),
                    SliverToBoxAdapter(child: _buildProgressRing(analytics)),
                    SliverToBoxAdapter(child: _buildSubjectChart(analytics)),
                    SliverToBoxAdapter(child: _buildTimelineChart(analytics)),
                    SliverToBoxAdapter(child: _buildSubjectBreakdown(analytics)),
                    SliverToBoxAdapter(child: _buildAchievements(analytics)),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF0D47A1),
                  const Color(0xFF1A237E),
                  (math.sin(_waveController.value * 2 * math.pi) + 1) / 2,
                )!,
                Color.lerp(
                  const Color(0xFF4A148C),
                  const Color(0xFF311B92),
                  (math.cos(_waveController.value * 2 * math.pi) + 1) / 2,
                )!,
                Color.lerp(
                  const Color(0xFF01579B),
                  const Color(0xFF006064),
                  (math.sin(_waveController.value * 2 * math.pi + math.pi) + 1) / 2,
                )!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: WaveBackgroundPainter(_waveController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.cyanAccent,
                    Colors.purpleAccent,
                    Colors.white,
                  ],
                  stops: [
                    0.0,
                    _pulseController.value * 0.5,
                    _pulseController.value,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                '📊 Progress Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.cyan.shade700.withOpacity(0.8),
                Colors.purple.shade700.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [Colors.cyan, Colors.purple],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 16 : 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> analytics) {
    final stats = [
      StatItem(
        'Total Sessions',
        '${analytics['totalSessions'] ?? 0}',
        Icons.book_rounded,
        const Color(0xFF2196F3),
        'sessions',
      ),
      StatItem(
        'Total Minutes',
        '${analytics['totalMinutes'] ?? 0}',
        Icons.timer_rounded,
        const Color(0xFF4CAF50),
        'minutes',
      ),
      StatItem(
        'Avg Focus',
        '${(analytics['averageFocusScore'] ?? 0).toStringAsFixed(1)}%',
        Icons.psychology_rounded,
        const Color(0xFF9C27B0),
        'focus',
      ),
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          return _buildAnimatedStatCard(stats[index], index);
        },
      ),
    );
  }

  Widget _buildAnimatedStatCard(StatItem stat, int index) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final slideAnimation = CurvedAnimation(
          parent: _mainController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.elasticOut,
          ),
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - slideAnimation.value)),
          child: Opacity(
            opacity: slideAnimation.value,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (math.sin(_pulseController.value * 2 * math.pi + index) * 0.02),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          stat.color.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: stat.color.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stat.color.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CardGlowPainter(
                              _pulseController.value,
                              stat.color,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [stat.color, stat.color.withOpacity(0.7)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: stat.color.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(stat.icon, color: Colors.white, size: 28),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stat.value,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: stat.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressRing(Map<String, dynamic> analytics) {
    final focusScore = (analytics['averageFocusScore'] ?? 0.0) as num;
    final targetScore = 100.0;
    final progress = focusScore / targetScore;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎯 Overall Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _chartController,
            builder: (context, child) {
              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: ProgressRingPainter(
                    progress: progress * _chartController.value,
                    backgroundColor: Colors.grey.shade200,
                    progressColor: Colors.cyan,
                    strokeWidth: 20,
                    pulseAnimation: _pulseController.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(focusScore * _chartController.value).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                        const Text(
                          'Focus Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChart(Map<String, dynamic> analytics) {
    final subjectData = (analytics['subjectBreakdown'] as Map<String, dynamic>?) ?? {};
    if (subjectData.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];

    final total = subjectData.values.fold<num>(0, (sum, val) => sum + (val as num));
    final subjects = subjectData.entries.toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Subject Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _chartController,
            builder: (context, child) {
              return SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: BarChartPainter(
                    subjects: subjects,
                    total: total.toDouble(),
                    colors: colors,
                    animation: _chartController.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: subjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors[index % colors.length].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors[index % colors.length].withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subject.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(Map<String, dynamic> analytics) {
    // Generate sample timeline data
    final timelineData = List.generate(7, (index) {
      return TimelineData(
        day: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
        minutes: 30 + math.Random().nextInt(90),
      );
    });

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Weekly Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _chartController,
            builder: (context, child) {
              return SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: LineChartPainter(
                    data: timelineData,
                    animation: _chartController.value,
                    pulseAnimation: _pulseController.value,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(Map<String, dynamic> analytics) {
    final subjectData = (analytics['subjectBreakdown'] as Map<String, dynamic>?) ?? {};
    if (subjectData.isEmpty) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎓 Subject Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...subjectData.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final subject = entry.value;
            final color = colors[index % colors.length];

            return AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                final slideAnimation = CurvedAnimation(
                  parent: _mainController,
                  curve: Interval(
                    0.3 + index * 0.1,
                    0.7 + index * 0.1,
                    curve: Curves.easeOut,
                  ),
                );

                return Transform.translate(
                  offset: Offset(50 * (1 - slideAnimation.value), 0),
                  child: Opacity(
                    opacity: slideAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              subject.key[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject.key,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${subject.value} minutes studied',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${subject.value}m',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements(Map<String, dynamic> analytics) {
    final achievements = [
      Achievement('🔥', 'Study Streak', '7 Days', Colors.orange),
      Achievement('🏆', 'High Achiever', '90% Focus', Colors.amber),
      Achievement('📚', 'Book Worm', '50+ Sessions', Colors.blue),
      Achievement('⚡', 'Speed Learner', 'Fast Pace', Colors.purple),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.amber.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏅 Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  final slideAnimation = CurvedAnimation(
                    parent: _mainController,
                    curve: Interval(
                      0.5 + index * 0.1,
                      0.9 + index * 0.1,
                      curve: Curves.elasticOut,
                    ),
                  );

                  return Transform.scale(
                    scale: slideAnimation.value,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (math.sin(_pulseController.value * 2 * math.pi + index) * 0.03),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  achievements[index].color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: achievements[index].color.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: achievements[index].color.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  achievements[index].icon,
                                  style: const TextStyle(
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  achievements[index].title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievements[index].subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String unit;

  StatItem(this.title, this.value, this.icon, this.color, this.unit);
}

class Achievement {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  Achievement(this.icon, this.title, this.subtitle, this.color);
}

class TimelineData {
  final String day;
  final int minutes;

  TimelineData({required this.day, required this.minutes});
}

// Custom Painters
class WaveBackgroundPainter extends CustomPainter {
  final double animation;

  WaveBackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 30.0;
      final waveLength = size.width / 2;
      final offset = animation * waveLength + (i * waveLength / 3);

      path.moveTo(0, size.height / 2);

      for (double x = 0; x <= size.width; x += 1) {
        final y = size.height / 2 +
            math.sin((x + offset) / waveLength * 2 * math.pi) * waveHeight * (i + 1);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CardGlowPainter extends CustomPainter {
  final double animation;
  final Color color;

  CardGlowPainter(this.animation, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          color.withOpacity(0.1 * animation),
          Colors.transparent,
        ],
        stops: [
          animation - 0.3,
          animation,
          animation + 0.3,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final double pulseAnimation;

  ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: [
        progressColor,
        progressColor.withOpacity(0.7),
        progressColor,
      ],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth + (pulseAnimation * 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = progressColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth + 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<MapEntry<String, dynamic>> subjects;
  final double total;
  final List<Color> colors;
  final double animation;

  BarChartPainter({
    required this.subjects,
    required this.total,
    required this.colors,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (subjects.isEmpty) return;

    final barWidth = (size.width - (subjects.length - 1) * 12) / subjects.length;
    final maxHeight = size.height - 40;

    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final value = (subject.value as num).toDouble();
      final percentage = value / total;
      final barHeight = maxHeight * percentage * animation;
      final x = i * (barWidth + 12);
      final y = size.height - barHeight;

      // Bar gradient
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors[i % colors.length],
          colors[i % colors.length].withOpacity(0.6),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(12),
      );
      canvas.drawRRect(rrect, paint);

      // Glow effect
      final glowPaint = Paint()
        ..color = colors[i % colors.length].withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawRRect(rrect, glowPaint);

      // Value text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${value.toInt()}',
          style: TextStyle(
            color: colors[i % colors.length],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, y - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<TimelineData> data;
  final double animation;
  final double pulseAnimation;

  LineChartPainter({
    required this.data,
    required this.animation,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxMinutes = data.map((d) => d.minutes).reduce(math.max).toDouble();
    final spacing = size.width / (data.length - 1);
    final path = Path();
    final points = <Offset>[];

    // Calculate points
    for (int i = 0; i < data.length; i++) {
      final x = i * spacing;
      final normalizedValue = data[i].minutes / maxMinutes;
      final y = size.height - 40 - (normalizedValue * (size.height - 80) * animation);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Smooth curve
        final prevPoint = points[i - 1];
        final controlPoint1 = Offset(
          prevPoint.dx + spacing / 3,
          prevPoint.dy,
        );
        final controlPoint2 = Offset(
          x - spacing / 3,
          y,
        );
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          x,
          y,
        );
      }
    }

    // Draw gradient fill
    final gradientPath = Path.from(path);
    gradientPath.lineTo(size.width, size.height);
    gradientPath.lineTo(0, size.height);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4CAF50).withOpacity(0.3),
          const Color(0xFF4CAF50).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(gradientPath, gradientPaint);

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw points and labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Point glow
      final glowPaint = Paint()
        ..color = const Color(0xFF4CAF50).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        point,
        6 + (pulseAnimation * 2),
        glowPaint,
      );

      // Point
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 6, pointPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(point, 6, borderPaint);

      // Day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].day,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, size.height - 25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}