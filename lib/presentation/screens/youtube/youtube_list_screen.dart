import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/constants/color_constants.dart';
import '../../../data/models/youtube_video_model.dart';
import '../../../providers/youtube_provider.dart';
import '../../widgets/youtube/video_card.dart';
import '../../../config/routes.dart';

class YouTubeListScreen extends StatefulWidget {
  final String resourceId;
  final String resourceTitle;
  final String subject;
  final String? topic;
  final String? unit;

  const YouTubeListScreen({
    Key? key,
    required this.resourceId,
    required this.resourceTitle,
    required this.subject,
    this.topic,
    this.unit,
  }) : super(key: key);

  @override
  State<YouTubeListScreen> createState() => _YouTubeListScreenState();
}

class _YouTubeListScreenState extends State<YouTubeListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _headerAnimation;

  String _selectedDifficulty = 'All';
  String _selectedType = 'All';
  String _sortBy = 'relevance'; // relevance, views, date, rating
  bool _showFilters = false;

  final ScrollController _scrollController = ScrollController();
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController.addListener(_onScroll);
    _loadVideos();
    _headerAnimationController.forward();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _isHeaderExpanded) {
      setState(() => _isHeaderExpanded = false);
    } else if (_scrollController.offset <= 100 && !_isHeaderExpanded) {
      setState(() => _isHeaderExpanded = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final provider = Provider.of<YouTubeProvider>(context, listen: false);
    await provider.loadVideosForResource(widget.resourceId);
  }

  List<YouTubeVideoModel> _getSortedVideos(List<YouTubeVideoModel> videos) {
    var sorted = List<YouTubeVideoModel>.from(videos);

    switch (_sortBy) {
      case 'views':
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'date':
        sorted.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case 'rating':
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
      case 'relevance':
      default:
        sorted.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0F0F0F),
                  Colors.red.shade900.withOpacity(0.1),
                ],
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              _buildAnalyticsSummary(),
              _buildSortAndFilter(),
              _buildTabBar(),
              _buildVideoContent(),
            ],
          ),

          // Floating Action Buttons
          _buildFloatingActions(),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade700,
                Colors.red.shade900,
                const Color(0xFF0F0F0F),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Video Lectures',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<YouTubeProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        children: [
                          _buildStatChip(
                            icon: Icons.video_library,
                            label: '${provider.videos.length} Videos',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            icon: Icons.favorite,
                            label: '${provider.favorites.length} Saved',
                            color: Colors.pinkAccent,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(
                context,
                AppRoutes.youtubeSearch,
                arguments: {
                  'subject': widget.subject,
                  'topic': widget.topic,
                },
              );
            },
            color: Colors.white,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _loadVideos,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Consumer<YouTubeProvider>(
      builder: (context, provider, child) {
        if (provider.videos.isEmpty) return const SliverToBoxAdapter();

        final totalViews = provider.videos.fold<int>(
          0,
              (sum, video) => sum + video.viewCount,
        );

        final avgViews = totalViews ~/ provider.videos.length;
        final totalDuration = provider.videos.fold<int>(
          0,
              (sum, video) => sum + _parseDuration(video.duration),
        );

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade800.withOpacity(0.3),
                  Colors.red.shade900.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Collection Analytics',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticCard(
                        icon: Icons.visibility,
                        label: 'Total Views',
                        value: _formatNumber(totalViews),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticCard(
                        icon: Icons.trending_up,
                        label: 'Avg Views',
                        value: _formatNumber(avgViews),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticCard(
                        icon: Icons.access_time,
                        label: 'Total Duration',
                        value: _formatDuration(totalDuration),
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticCard(
                        icon: Icons.library_books,
                        label: 'Videos',
                        value: provider.videos.length.toString(),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortAndFilter() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSortButton(),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
              ],
            ),
            if (_showFilters) ...[
              const SizedBox(height: 16),
              _buildFilterSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSortOptions(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sort: ${_getSortLabel()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: _showFilters
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _showFilters
              ? Colors.red.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _showFilters = !_showFilters);
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difficulty Level',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Easy', 'Medium', 'Advanced']
                .map((level) => _buildChip(
              label: level,
              isSelected: _selectedDifficulty == level,
              onTap: () {
                setState(() => _selectedDifficulty = level);
                HapticFeedback.selectionClick();
              },
            ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Learning Type',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Exam Revision', 'First Time Learning', 'Quick Recap']
                .map((type) => _buildChip(
              label: type,
              isSelected: _selectedType == type,
              onTap: () {
                setState(() => _selectedType = type);
                HapticFeedback.selectionClick();
              },
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade900],
          )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.red.withOpacity(0.5)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library, size: 16),
                  const SizedBox(width: 6),
                  const Text('All'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 16),
                  const SizedBox(width: 6),
                  const Text('Favorites'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.watch_later, size: 16),
                  const SizedBox(width: 6),
                  const Text('Later'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return Consumer<YouTubeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.red.shade700,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading amazing videos...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.errorMessage != null) {
          return SliverFillRemaining(
            child: _buildErrorState(provider.errorMessage!),
          );
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoList(_getSortedVideos(provider.videos)),
                _buildVideoList(_getSortedVideos(provider.favorites)),
                _buildVideoList(_getSortedVideos(provider.watchLater)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoList(List<YouTubeVideoModel> videos) {
    // Apply filters
    var filteredVideos = videos;

    if (_selectedDifficulty != 'All') {
      filteredVideos = filteredVideos
          .where((v) => v.difficulty == _selectedDifficulty)
          .toList();
    }

    if (_selectedType != 'All') {
      filteredVideos = filteredVideos
          .where((v) => v.suitableFor == _selectedType)
          .toList();
    }

    if (filteredVideos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVideos.length,
      itemBuilder: (context, index) {
        final video = filteredVideos[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: VideoCard(
                  video: video,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    AppRoutes.navigateToYouTubePlayer(
                      context,
                      video: video,
                      relatedVideos: filteredVideos
                          .where((v) => v.videoId != video.videoId)
                          .toList(),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          Text(
            'No videos found',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'scroll_top',
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.arrow_upward, color: Colors.white),
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              {'value': 'relevance', 'label': 'Most Relevant', 'icon': Icons.auto_awesome},
              {'value': 'views', 'label': 'Most Viewed', 'icon': Icons.visibility},
              {'value': 'date', 'label': 'Newest First', 'icon': Icons.schedule},
              {'value': 'rating', 'label': 'Highest Rated', 'icon': Icons.star},
            ].map((option) => _buildSortOption(
              value: option['value'] as String,
              label: option['label'] as String,
              icon: option['icon'] as IconData,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.red : Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.red)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'views':
        return 'Most Viewed';
      case 'date':
        return 'Newest';
      case 'rating':
        return 'Highest Rated';
      default:
        return 'Most Relevant';
    }
  }

  int _parseDuration(String duration) {
    // Parse ISO 8601 duration (e.g., PT1H2M3S)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    if (match == null) return 0;

    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

    return hours * 3600 + minutes * 60 + seconds;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}