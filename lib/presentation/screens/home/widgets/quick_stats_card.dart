import 'package:flutter/material.dart';

/// Reusable quick stats card with animated counter
class QuickStatsCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const QuickStatsCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  State<QuickStatsCard> createState() => _QuickStatsCardState();
}

class _QuickStatsCardState extends State<QuickStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<int> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _counterAnimation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(QuickStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _counterAnimation = IntTween(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.8),
                widget.color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _counterAnimation,
                builder: (context, child) {
                  return Text(
                    _counterAnimation.value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of quick stats cards
class QuickStatsGrid extends StatelessWidget {
  final int totalViews;
  final int totalDownloads;
  final int totalBookmarks;
  final int studyTimeMinutes;

  const QuickStatsGrid({
    Key? key,
    required this.totalViews,
    required this.totalDownloads,
    required this.totalBookmarks,
    required this.studyTimeMinutes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickStatsCard(
                  icon: Icons.visibility_rounded,
                  label: 'Views',
                  value: totalViews,
                  color: const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickStatsCard(
                  icon: Icons.download_rounded,
                  label: 'Downloads',
                  value: totalDownloads,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickStatsCard(
                  icon: Icons.bookmark_rounded,
                  label: 'Bookmarks',
                  value: totalBookmarks,
                  color: const Color(0xFFFFA726),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickStatsCard(
                  icon: Icons.access_time_rounded,
                  label: 'Study Time',
                  value: studyTimeMinutes,
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal stats row
class QuickStatsRow extends StatelessWidget {
  final int views;
  final int downloads;
  final int studyTime;

  const QuickStatsRow({
    Key? key,
    required this.views,
    required this.downloads,
    required this.studyTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.visibility_rounded,
            value: views,
            color: const Color(0xFF4A90E2),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.download_rounded,
            value: downloads,
            color: const Color(0xFF4CAF50),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.access_time_rounded,
            value: studyTime,
            color: const Color(0xFF9C27B0),
            suffix: 'm',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required Color color,
    String suffix = '',
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '$value$suffix',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}