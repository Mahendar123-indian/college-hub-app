// lib/presentation/screens/home/home_screen.dart

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/filter_provider.dart';
import '../../../providers/college_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/download_provider.dart';
// ✅ NEW: YouTube Provider
import '../../../providers/youtube_provider.dart';
import '../../../data/models/resource_model.dart';
// ✅ NEW: YouTube Video Model
import '../../../data/models/youtube_video_model.dart';
import 'widgets/my_college_screen.dart';
import 'widgets/analytics_dashboard_widget.dart';
import 'widgets/study_streak_widget.dart';
import 'widgets/subject_performance_widget.dart';
import 'widgets/quick_stats_card.dart';
import '../../../../presentation/widgets/trending_notes_widget.dart';

import '../bookmarks/bookmarks_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_screen.dart';
// ✅ NEW: YouTube Screens
import '../youtube/youtube_list_screen.dart';
import '../youtube/youtube_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _navController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _navController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _navController.forward();

    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final resourceProvider = Provider.of<ResourceProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final collegeProvider = Provider.of<CollegeProvider>(context, listen: false);
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);

        resourceProvider.init();
        collegeProvider.fetchAllColleges();
        resourceProvider.fetchFeaturedResources();
        resourceProvider.fetchTrendingResources();
        resourceProvider.fetchRecentResources();
        resourceProvider.fetchAllResources();

        if (authProvider.currentUser != null) {
          chatProvider.loadConversations(authProvider.currentUser!.id);
          analyticsProvider.initializeForUser(authProvider.currentUser!.id);
        }

        debugPrint('✅ Home screen initialized with analytics');
      } catch (e) {
        debugPrint('❌ Error loading: $e');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _navController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
      _fadeController.forward(from: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // ✅ UPDATED: Added YouTube Videos screen to bottom nav
    final List<Widget> screens = [
      const _HomeContent(),
      const BookmarksScreen(),
      const ChatListScreen(),
      const _YouTubeVideosScreen(), // ✅ NEW: YouTube tab
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) _onNavTap(0);
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(authProvider, chatProvider),
      ),
    );
  }

  Widget _buildBottomNav(AuthProvider authProvider, ChatProvider chatProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 0, 'Home'),
            _buildNavItem(Icons.bookmark_rounded, 1, 'Bookmarks'),
            _buildNavItem(
              Icons.chat_bubble_rounded,
              2,
              'Chats',
              badge: authProvider.currentUser != null
                  ? chatProvider.getTotalUnreadCount(authProvider.currentUser!.id)
                  : 0,
            ),
            // ✅ NEW: YouTube Videos Navigation Item
            _buildNavItem(
              Icons.play_circle_outline,
              3,
              'Videos',
            ),
            _buildNavItem(Icons.person_rounded, 4, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label, {int badge = 0}) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A90E2).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[600],
                    size: 22,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF4A90E2),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ NEW: YOUTUBE VIDEOS SCREEN
// ═══════════════════════════════════════════════════════════════
class _YouTubeVideosScreen extends StatelessWidget {
  const _YouTubeVideosScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Video Lectures',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.youtubeSearch,
                              arguments: {
                                'subject': 'General',
                                'topic': null,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.video_library, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Educational Content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse by Subject',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject Categories
                  _buildSubjectGrid(context),

                  const SizedBox(height: 24),

                  const Text(
                    'Your Collections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Collections
                  _buildCollectionsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGrid(BuildContext context) {
    final subjects = [
      {'name': 'Mathematics', 'icon': Icons.calculate, 'color': const Color(0xFF4A90E2)},
      {'name': 'Physics', 'icon': Icons.science, 'color': const Color(0xFF9C27B0)},
      {'name': 'Chemistry', 'icon': Icons.biotech, 'color': const Color(0xFF4CAF50)},
      {'name': 'Computer Science', 'icon': Icons.computer, 'color': const Color(0xFFFF9800)},
      {'name': 'Engineering', 'icon': Icons.engineering, 'color': const Color(0xFFF44336)},
      {'name': 'Biology', 'icon': Icons.local_hospital, 'color': const Color(0xFF00BCD4)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.youtubeSearch,
              arguments: {
                'subject': subject['name'],
                'topic': null,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (subject['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      subject['icon'] as IconData,
                      color: subject['color'] as Color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    subject['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsSection(BuildContext context) {
    return Consumer<YouTubeProvider>(
      builder: (context, youtubeProvider, child) {
        return Column(
          children: [
            // Watch History
            _buildCollectionCard(
              context,
              icon: Icons.history,
              title: 'Watch History',
              count: youtubeProvider.watchHistory.length,
              color: const Color(0xFF4A90E2),
              onTap: () {
                _showCollectionBottomSheet(
                  context,
                  'Watch History',
                  youtubeProvider.watchHistory,
                );
              },
            ),
            const SizedBox(height: 12),

            // Favorites
            _buildCollectionCard(
              context,
              icon: Icons.favorite,
              title: 'Favorites',
              count: youtubeProvider.favorites.length,
              color: const Color(0xFFFF6B6B),
              onTap: () {
                _showCollectionBottomSheet(
                  context,
                  'Favorites',
                  youtubeProvider.favorites,
                );
              },
            ),
            const SizedBox(height: 12),

            // Watch Later
            _buildCollectionCard(
              context,
              icon: Icons.watch_later,
              title: 'Watch Later',
              count: youtubeProvider.watchLater.length,
              color: const Color(0xFF9C27B0),
              onTap: () {
                _showCollectionBottomSheet(
                  context,
                  'Watch Later',
                  youtubeProvider.watchLater,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollectionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required int count,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count video${count != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionBottomSheet(
      BuildContext context,
      String title,
      List<YouTubeVideoModel> videos,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: videos.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnailUrl,
                            width: 80,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          video.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          AppRoutes.navigateToYouTubePlayer(
                            context,
                            video: video,
                            relatedVideos: videos,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME CONTENT (EXISTING WITH YOUTUBE & ACADEMIC SEARCH ADDED)
// ═══════════════════════════════════════════════════════════════
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with TickerProviderStateMixin {
  int _unreadNotificationCount = 0;
  bool _showAnalytics = false;
  bool _isSpeedDialOpen = false;
  String? _selectedAnalyticsSection;
  late AnimationController _fabController;
  late AnimationController _speedDialController;
  late Animation<double> _fabRotation;
  late List<Animation<double>> _speedDialAnimations;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _speedDialController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fabRotation = Tween<double>(begin: 0, end: 0.875).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _speedDialAnimations = List.generate(4, (index) {
      final start = index * 0.08;
      final end = start + 0.4;
      return CurvedAnimation(
        parent: _speedDialController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
        analyticsProvider.initializeForUser(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _speedDialController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: authProvider.currentUser!.id)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() => _unreadNotificationCount = snapshot.docs.length);
      }
    });
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
        _fabController.forward();
      } else {
        _speedDialController.reverse();
        _fabController.reverse();
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
        _speedDialController.reverse();
      });
    }
  }

  void _navigateToAnalyticsSection(String section) {
    _closeSpeedDial();
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedAnalyticsSection == section) {
        _selectedAnalyticsSection = null;
        _showAnalytics = false;
      } else {
        _selectedAnalyticsSection = section;
        _showAnalytics = true;
        _fabController.forward();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _selectedAnalyticsSection == section
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _selectedAnalyticsSection == section
                    ? 'Showing $section'
                    : 'Hidden $section',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4A90E2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<ResourceProvider>(context, listen: false);
          final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);

          await Future.wait([
            provider.fetchFeaturedResources(),
            provider.fetchTrendingResources(),
            provider.fetchRecentResources(),
            if (user != null) analyticsProvider.initializeForUser(user.id),
          ]);
        },
        color: const Color(0xFF4A90E2),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(user),
            _buildSearchBar(context),
            _buildQuickActions(context),
            _buildResourcesGrid(context),
            _buildAIAssistant(context),

            // ✅ NEW: YouTube Section
            _buildYouTubeSection(context),

            _buildContinueStudying(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TrendingNotesWidget(),
              ),
            ),

            if (_showAnalytics) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'YOUR ANALYTICS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedAnalyticsSection != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getSectionColor(_selectedAnalyticsSection!),
                                _getSectionColor(_selectedAnalyticsSection!).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getSectionIcon(_selectedAnalyticsSection!),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedAnalyticsSection!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAnalyticsSection = null;
                              _showAnalytics = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_selectedAnalyticsSection == 'Analytics Dashboard')
                const SliverToBoxAdapter(child: AnalyticsDashboardWidget()),

              if (_selectedAnalyticsSection == 'Study Streaks')
                const SliverToBoxAdapter(child: StudyStreakWidget()),

              if (_selectedAnalyticsSection == 'Subject Performance')
                const SliverToBoxAdapter(child: SubjectPerformanceWidget()),

              if (_selectedAnalyticsSection == 'Study Insights') ...[
                const SliverToBoxAdapter(child: AnalyticsDashboardWidget()),
                const SliverToBoxAdapter(child: StudyStreakWidget()),
                const SliverToBoxAdapter(child: SubjectPerformanceWidget()),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isSpeedDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSpeedDial,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),

          ..._buildSpeedDialItems(),

          _buildMainFAB(),
        ],
      ),
    );
  }

  // ✅ NEW: YouTube Section Widget
  Widget _buildYouTubeSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(
              context,
              AppRoutes.youtubeSearch,
              arguments: {
                'subject': 'General',
                'topic': null,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0000).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Lectures',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Learn from YouTube tutorials',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<YouTubeProvider>(
                  builder: (context, youtubeProvider, child) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildYouTubeChip(
                            Icons.history,
                            'History (${youtubeProvider.watchHistory.length})',
                          ),
                          const SizedBox(width: 8),
                          _buildYouTubeChip(
                            Icons.favorite,
                            'Favorites (${youtubeProvider.favorites.length})',
                          ),
                          const SizedBox(width: 8),
                          _buildYouTubeChip(
                            Icons.watch_later,
                            'Watch Later (${youtubeProvider.watchLater.length})',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Browse Videos',
                        style: TextStyle(
                          color: Color(0xFFFF0000),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFFF0000),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
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

  List<Widget> _buildSpeedDialItems() {
    final items = [
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Dashboard',
        'color': const Color(0xFF4A90E2),
        'section': 'Analytics Dashboard'
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'label': 'Streaks',
        'color': const Color(0xFFFF6B6B),
        'section': 'Study Streaks'
      },
      {
        'icon': Icons.show_chart_rounded,
        'label': 'Performance',
        'color': const Color(0xFF4CAF50),
        'section': 'Subject Performance'
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Insights',
        'color': const Color(0xFF9C27B0),
        'section': 'Study Insights'
      },
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      final distance = 70.0 * (index + 1);

      return AnimatedBuilder(
        animation: _speedDialAnimations[index],
        builder: (context, child) {
          final value = _speedDialAnimations[index].value.clamp(0.0, 1.0);

          return Positioned(
            right: 16,
            bottom: 90 + distance * value,
            child: Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: _buildSpeedDialItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  color: item['color'] as Color,
                  onTap: () => _navigateToAnalyticsSection(item['section'] as String),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    return Positioned(
      right: 16,
      bottom: 90,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _isSpeedDialOpen
              ? [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ]
              : [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggleSpeedDial,
          backgroundColor: _isSpeedDialOpen
              ? const Color(0xFF667EEA)
              : const Color(0xFF4A90E2),
          elevation: 8,
          child: RotationTransition(
            turns: _fabRotation,
            child: Icon(
              _isSpeedDialOpen ? Icons.close_rounded : Icons.analytics_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF5BA3F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'College Hub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon:
                          const Icon(Icons.notifications_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                _unreadNotificationCount > 9
                                    ? '9+'
                                    : '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF4A90E2), size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hello, ${user?.name?.split(' ')[0] ?? 'Student'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'student@collegehub.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: Color(0xFF4A90E2), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search notes, exams, papers...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.mic_rounded, color: Colors.grey[400], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED: Quick Actions with Academic Search Button
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.school_rounded,
        'label': 'My College',
        'color': const Color(0xFF4A90E2),
        'route': 'my_college'
      },
      // ✅ NEW: Academic Search
      {
        'icon': Icons.search_rounded,
        'label': 'Academic',
        'color': const Color(0xFF8B5CF6),
        'route': AppRoutes.academicSearch,
        'badge': 'NEW'
      },
      {
        'icon': Icons.psychology_rounded,
        'label': 'Smart Hub',
        'color': const Color(0xFF6366F1),
        'route': AppRoutes.smartLearningHub,
      },
      {
        'icon': Icons.smart_toy_rounded,
        'label': 'AI Study',
        'color': const Color(0xFF9C27B0),
        'route': AppRoutes.aiAssistant
      },
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: actions.map((action) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (action['route'] == 'my_college') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyCollegeScreen(),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, action['route'] as String);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            action['label'] as String,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (action['badge'] != null)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              action['badge'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResourcesGrid(BuildContext context) {
    final resources = [
      {
        'name': 'Assignments',
        'type': 'Assignments',
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFF4A90E2)
      },
      {
        'name': 'Notes',
        'type': 'Class Notes',
        'icon': Icons.note_rounded,
        'color': const Color(0xFF4CAF50)
      },
      {
        'name': 'Lab Manuals',
        'type': 'Lab Manuals',
        'icon': Icons.science_rounded,
        'color': const Color(0xFF9C27B0)
      },
      {
        'name': 'Mid Exams',
        'type': 'Mid-Exam Papers',
        'icon': Icons.school_rounded,
        'color': const Color(0xFFFF9800)
      },
      {
        'name': 'Semester',
        'type': 'Semester Exam Papers',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFF44336)
      },
      {
        'name': 'Previous Years',
        'type': 'Previous Year Papers',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFF00BCD4)
      },
      {
        'name': 'Guides',
        'type': 'Study Guides',
        'icon': Icons.library_books_rounded,
        'color': const Color(0xFF3F51B5)
      },
      {
        'name': 'Syllabus',
        'type': 'Syllabus',
        'icon': Icons.list_alt_rounded,
        'color': const Color(0xFF009688)
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildResourceCard(
            context,
            resources[index]['name'] as String,
            resources[index]['type'] as String,
            resources[index]['icon'] as IconData,
            resources[index]['color'] as Color,
            index,
          ),
          childCount: resources.length,
        ),
      ),
    );
  }

  Widget _buildResourceCard(
      BuildContext context,
      String name,
      String type,
      IconData icon,
      Color color,
      int index,
      ) {
    String? badge;
    if (index == 3) badge = 'New!';
    if (index == 4) badge = 'New!';
    if (index == 5) badge = 'Hot';

    return Consumer<ResourceProvider>(
      builder: (context, resourceProvider, _) {
        final count = resourceProvider.resources
            .where((r) => r.resourceType == type)
            .length;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();

            if (type == 'Previous Year Papers') {
              Navigator.pushNamed(context, AppRoutes.previousYearPapers);
            } else {
              final filterProvider =
              Provider.of<FilterProvider>(context, listen: false);
              filterProvider.setResourceType(type);
              Navigator.pushNamed(
                context,
                AppRoutes.resourceList,
                arguments: {'category': type},
              );
            }
          },
          child: Container(
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
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const Spacer(),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$count Files',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge == 'New!' ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIAssistant(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Smart Learning Hub Card
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, AppRoutes.smartLearningHub);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Smart Learning Hub',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AI-Powered Study Tools',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFeatureChip(Icons.style, 'Flashcards'),
                          const SizedBox(width: 8),
                          _buildFeatureChip(Icons.account_tree, 'Mind Maps'),
                          const SizedBox(width: 8),
                          _buildFeatureChip(Icons.timer, 'Pomodoro'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Explore Smart Tools',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF6366F1),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Study Assistant Card
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(context, AppRoutes.aiAssistant);
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'AI Study Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Smart learning with AI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start',
                            style: TextStyle(
                              color: Color(0xFF667EEA),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF667EEA),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
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

  Widget _buildContinueStudying(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Continue Studying',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box(AppConstants.bookmarksBox).listenable(),
                  builder: (context, bookmarkBox, _) {
                    final bookmarkCount = bookmarkBox.length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStudyCard(
                            icon: Icons.download_rounded,
                            label: 'Downloads',
                            count: downloadProvider.totalDownloads,
                            color: const Color(0xFF4ADE80),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.downloads),
                            activeCount: downloadProvider.activeDownloads,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStudyCard(
                            icon: Icons.bookmark_rounded,
                            label: 'Bookmarks',
                            count: bookmarkCount,
                            color: const Color(0xFFFBBF24),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
    int activeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                if (activeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        activeCount > 9 ? '9+' : '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

  Color _getSectionColor(String section) {
    switch (section) {
      case 'Analytics Dashboard':
        return const Color(0xFF4A90E2);
      case 'Study Streaks':
        return const Color(0xFFFF6B6B);
      case 'Subject Performance':
        return const Color(0xFF4CAF50);
      case 'Study Insights':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'Analytics Dashboard':
        return Icons.bar_chart_rounded;
      case 'Study Streaks':
        return Icons.local_fire_department_rounded;
      case 'Subject Performance':
        return Icons.show_chart_rounded;
      case 'Study Insights':
        return Icons.insights_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }
}