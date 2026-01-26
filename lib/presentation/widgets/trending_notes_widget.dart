import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../config/routes.dart';
import '../../providers/resource_provider.dart';
import '../../data/models/resource_model.dart';
import 'trending_card_shimmer.dart';

class TrendingNotesWidget extends StatefulWidget {
  const TrendingNotesWidget({Key? key}) : super(key: key);

  @override
  State<TrendingNotesWidget> createState() => _TrendingNotesWidgetState();
}

class _TrendingNotesWidgetState extends State<TrendingNotesWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildTrendingList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Animated fire icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (math.sin(_controller.value * 2 * math.pi) * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xFFFF6B6B),
                                const Color(0xFFFF8E53),
                                _controller.value,
                              )!,
                              Color.lerp(
                                const Color(0xFFFF8E53),
                                const Color(0xFFFFD93D),
                                _controller.value,
                              )!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trending Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Consumer<ResourceProvider>(
                        builder: (context, provider, _) {
                          return Text(
                            '${provider.trendingResources.length} hot resources',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(
                context,
                AppRoutes.resourceList,
                arguments: {'filters': {'isTrending': 'true'}},
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF5BA3F5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context) {
    return Consumer<ResourceProvider>(
      builder: (context, provider, _) {
        // Show shimmer while loading
        if (provider.isLoading && provider.trendingResources.isEmpty) {
          return const TrendingCardShimmer();
        }

        final trending = provider.trendingResources.take(8).toList();

        if (trending.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: trending.asMap().entries.map((entry) {
            final index = entry.key;
            final resource = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 80)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildTrendingCard(context, resource, index),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTrendingCard(BuildContext context, ResourceModel resource, int index) {
    final timeAgo = _getTimeAgo(resource.uploadedAt);
    final isTopThree = index < 3;

    final rankColors = [
      [const Color(0xFFFFD700), const Color(0xFFFFA500)], // Gold
      [const Color(0xFFC0C0C0), const Color(0xFF808080)], // Silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // Bronze
    ];

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        AppRoutes.navigateToResourceDetail(context, resource.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
        decoration: BoxDecoration(
          gradient: isTopThree
              ? LinearGradient(
            colors: [
              rankColors[index][0].withOpacity(0.08),
              rankColors[index][1].withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isTopThree ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTopThree
                ? rankColors[index][0].withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            width: isTopThree ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isTopThree
                  ? rankColors[index][0].withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isTopThree ? 12 : 8,
              offset: Offset(0, isTopThree ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated background gradient for top 3
            if (isTopThree)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rankColors[index][0].withOpacity(0.05),
                            rankColors[index][1].withOpacity(0.02),
                            Colors.transparent,
                          ],
                          stops: [
                            _controller.value - 0.3,
                            _controller.value,
                            _controller.value + 0.3,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  },
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Rank Badge
                  _buildRankBadge(index, rankColors),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                resource.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isTopThree ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Live indicator for trending
                            if (resource.isTrending)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: 0.5 + (0.5 * math.sin(_controller.value * 2 * math.pi)),
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Subject & Time
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getResourceIcon(resource.resourceType),
                                color: const Color(0xFF4A90E2),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                resource.subject,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Stats Row
                        Row(
                          children: [
                            _buildStatChip(
                              Icons.download_rounded,
                              resource.downloadCount.toString(),
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              Icons.visibility_rounded,
                              resource.viewCount.toString(),
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              Icons.star_rounded,
                              resource.rating.toStringAsFixed(1),
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int index, List<List<Color>> rankColors) {
    final isTopThree = index < 3;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
          colors: rankColors[index],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isTopThree ? null : const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isTopThree ? rankColors[index][0] : const Color(0xFF4A90E2))
                .withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isTopThree)
            Icon(
              index == 0
                  ? Icons.emoji_events_rounded
                  : Icons.military_tech_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 32,
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isTopThree)
                Text(
                  ['🥇', '🥈', '🥉'][index],
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.2),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Trending Notes Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Popular resources will appear here soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String type) {
    if (type.contains('Notes')) return Icons.description_rounded;
    if (type.contains('Exam')) return Icons.quiz_rounded;
    if (type.contains('Assignment')) return Icons.assignment_rounded;
    if (type.contains('Lab')) return Icons.science_rounded;
    return Icons.article_rounded;
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}