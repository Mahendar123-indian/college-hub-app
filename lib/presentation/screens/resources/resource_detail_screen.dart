import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core & Config
import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';

// Models & Providers
import '../../../data/models/resource_model.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/download_provider.dart';

// Notification
import '../../../core/utils/notification_triggers.dart';

// ✅ NEW: YouTube Imports
import '../../widgets/youtube/video_thumbnail_widget.dart';
import '../../../providers/youtube_provider.dart';
import '../../../data/models/youtube_video_model.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({Key? key, required this.resourceId}) : super(key: key);

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isBookmarked = false;

  // Review system
  double _userRating = 0.0;
  bool _hasUserReviewed = false;

  // Related resources
  List<ResourceModel> _relatedResources = [];

  // ✅ NEW: YouTube videos
  List<YouTubeVideoModel> _relatedVideos = [];
  bool _isLoadingVideos = false;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _initData();
  }

  Future<void> _initData() async {
    await _checkBookmarkStatus();
    await _loadUserReview();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final resourceProvider = Provider.of<ResourceProvider>(context, listen: false);
      resourceProvider.incrementViewCount(widget.resourceId);

      // Track view analytics
      final resource = await resourceProvider.getResourceById(widget.resourceId);
      if (resource != null) {
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
        await analyticsProvider.trackView(
          auth.currentUser!.id,
          resource.id,
          resource.title,
          resource.resourceType,
          resource.subject,
        );
      }

      _loadRelatedResources();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
      _slideController.forward();
    }

    // ✅ NEW: Load YouTube videos
    _loadYouTubeVideos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    final box = await Hive.openBox(AppConstants.bookmarksBox);
    if (mounted) {
      setState(() => _isBookmarked = box.containsKey(widget.resourceId));
    }
  }

  Future<void> _loadUserReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) return;

    final prefs = await Hive.openBox('userReviews');
    if (prefs.containsKey(widget.resourceId)) {
      setState(() {
        _userRating = prefs.get(widget.resourceId) as double;
        _hasUserReviewed = true;
      });
    }
  }

  Future<void> _loadRelatedResources() async {
    try {
      final provider = Provider.of<ResourceProvider>(context, listen: false);
      final currentResource = await provider.getResourceById(widget.resourceId);

      if (currentResource != null) {
        await provider.fetchResourcesByFilters(
          subject: currentResource.subject,
          department: currentResource.department,
        );

        final related = provider.resources
            .where((r) => r.id != widget.resourceId)
            .take(5)
            .toList();

        if (mounted) {
          setState(() => _relatedResources = related);
        }
      }
    } catch (e) {
      debugPrint('Error loading related resources: $e');
    }
  }

  // ✅ NEW: Load YouTube Videos
  Future<void> _loadYouTubeVideos() async {
    setState(() => _isLoadingVideos = true);

    try {
      final youtubeProvider = Provider.of<YouTubeProvider>(context, listen: false);
      await youtubeProvider.loadVideosForResource(widget.resourceId);

      if (mounted) {
        setState(() {
          _relatedVideos = youtubeProvider.videos.take(5).toList();
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading YouTube videos: $e');
      if (mounted) {
        setState(() => _isLoadingVideos = false);
      }
    }
  }

  Future<void> _submitRating(double rating) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) {
      _showSnack('Please login to rate resources', isError: true);
      return;
    }

    setState(() {
      _userRating = rating;
      _hasUserReviewed = true;
    });

    try {
      final prefs = await Hive.openBox('userReviews');
      await prefs.put(widget.resourceId, rating);

      await Provider.of<ResourceProvider>(context, listen: false)
          .rateResource(widget.resourceId, rating);

      _showSnack('Thank you for your rating! ⭐');
    } catch (e) {
      _showSnack('Failed to submit rating', isError: true);
    }
  }

  // ✅ DYNAMIC DOWNLOAD HANDLER WITH FULL INTEGRATION
  Future<void> _handleDownload(ResourceModel resource) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    // Check authentication
    if (authProvider.currentUser == null) {
      _showSnack('Please login to download resources', isError: true);
      return;
    }

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _showSnack("Check your internet connection", isError: true);
      return;
    }

    // Check if already downloaded
    if (downloadProvider.isResourceDownloaded(resource.id)) {
      _showSnack('File already downloaded', isError: false);
      return;
    }

    // Check if currently downloading
    if (downloadProvider.isResourceDownloading(resource.id)) {
      _showSnack('Download already in progress', isError: false);
      return;
    }

    try {
      // Show download started notification
      await NotificationTriggers.downloadStarted(resource.fileName);

      // Start download using DownloadProvider
      final taskId = await downloadProvider.startDownload(
        url: resource.fileUrl,
        fileName: resource.fileName,
        resourceId: resource.id,
        resourceTitle: resource.title,
        fileSize: resource.fileSize,
        userId: authProvider.currentUser!.id,
        fileExtension: resource.fileExtension,
      );

      if (taskId != null) {
        // Increment download count in Firestore
        await FirebaseFirestore.instance
            .collection('resources')
            .doc(resource.id)
            .update({
          'downloadCount': FieldValue.increment(1),
        });

        // Track download analytics
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
        await analyticsProvider.trackDownload(
          authProvider.currentUser!.id,
          resource.id,
          resource.title,
          resource.resourceType,
          resource.subject,
        );

        if (mounted) {
          _showSnack('Download started successfully! 🚀');
        }
      } else {
        if (mounted) {
          _showSnack(
            downloadProvider.error ?? 'Failed to start download',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Download failed: ${e.toString()}', isError: true);
      }
      debugPrint('❌ Download error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<ResourceModel?>(
      stream: Provider.of<ResourceProvider>(context, listen: false)
          .getResourceStream(widget.resourceId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final resource = snapshot.data!;

        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(resource),
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(resource),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(resource),
        );
      },
    );
  }

  Widget _buildAppBar(ResourceModel resource) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'resource_${resource.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.accentColor,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                _getFileIcon(resource.fileExtension),
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => Share.share(
            "Check out this resource: ${resource.title}\n${resource.fileUrl}",
          ),
          tooltip: 'Share',
        ),
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: _isBookmarked ? Colors.amber : null,
          ),
          onPressed: () => _toggleBookmark(resource),
          tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
        ),
      ],
    );
  }

  Widget _buildContent(ResourceModel resource) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _buildRatingSection(resource),
          const SizedBox(height: 20),

          _buildStats(resource),
          const SizedBox(height: 24),

          if (resource.description.isNotEmpty) ...[
            _buildSectionTitle('Description'),
            const SizedBox(height: 12),
            Text(
              resource.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          _buildSectionTitle('Details'),
          const SizedBox(height: 12),
          _buildDetailsCard(resource),
          const SizedBox(height: 24),

          // ✅ NEW: YouTube Videos Section
          if (_relatedVideos.isNotEmpty) ...[
            _buildSectionTitle('Related Video Lectures'),
            const SizedBox(height: 12),
            _buildYouTubeVideosSection(resource),
            const SizedBox(height: 24),
          ],

          _buildUserRatingSection(),
          const SizedBox(height: 24),

          if (_relatedResources.isNotEmpty) ...[
            _buildSectionTitle('Related Resources'),
            const SizedBox(height: 12),
            _buildRelatedResourcesList(),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ResourceModel resource) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < resource.rating.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 24,
          );
        }),
        const SizedBox(width: 8),
        Text(
          '${resource.rating.toStringAsFixed(1)} (${resource.ratingCount} reviews)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ResourceModel resource) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.accentColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn(
            Icons.remove_red_eye_rounded,
            "${resource.viewCount}",
            "Views",
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _statColumn(
            Icons.download_rounded,
            "${resource.downloadCount}",
            "Downloads",
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _statColumn(
            Icons.insert_drive_file_rounded,
            resource.fileSizeFormatted,
            "Size",
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _statColumn(IconData icon, String val, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          val,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(ResourceModel resource) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _buildDetailRow(Icons.school_rounded, "College", resource.college),
          const Divider(height: 24),
          _buildDetailRow(Icons.category_rounded, "Department", resource.department),
          const Divider(height: 24),
          _buildDetailRow(Icons.calendar_today_rounded, "Semester", resource.semester),
          const Divider(height: 24),
          _buildDetailRow(Icons.book_rounded, "Subject", resource.subject),
          if (resource.year != null) ...[
            const Divider(height: 24),
            _buildDetailRow(Icons.date_range_rounded, "Year", resource.year!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasUserReviewed ? 'Your Rating' : 'Rate This Resource',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => _submitRating((index + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _userRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_hasUserReviewed) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Thank you for your feedback!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedResourcesList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _relatedResources.length,
        itemBuilder: (context, index) {
          final resource = _relatedResources[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ResourceDetailScreen(resourceId: resource.id),
                ),
              );
            },
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getFileIcon(resource.fileExtension),
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resource.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        resource.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ NEW: YouTube Videos Section Widget
  Widget _buildYouTubeVideosSection(ResourceModel resource) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: _relatedVideos.length,
            itemBuilder: (context, index) {
              final video = _relatedVideos[index];
              return VideoThumbnailWidget(
                video: video,
                onTap: () {
                  AppRoutes.navigateToYouTubePlayer(
                    context,
                    video: video,
                    relatedVideos: _relatedVideos,
                  );
                },
                width: 220,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            AppRoutes.navigateToYouTubeList(
              context,
              resourceId: widget.resourceId,
              resourceTitle: resource.title,
              subject: resource.subject,
              topic: null,
              unit: null,
            );
          },
          icon: const Icon(Icons.video_library, size: 18),
          label: const Text('View All Videos'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ✅ DYNAMIC BOTTOM ACTION WITH REAL-TIME DOWNLOAD STATUS
  Widget _buildBottomAction(ResourceModel resource) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Consumer<DownloadProvider>(
          builder: (context, downloadProvider, _) {
            final isDownloaded = downloadProvider.isResourceDownloaded(resource.id);
            final isDownloading = downloadProvider.isResourceDownloading(resource.id);
            final progress = downloadProvider.getDownloadProgress(resource.id);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDownloading) ...[
                  LinearProgressIndicator(
                    value: progress ?? 0.0,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading... ${((progress ?? 0.0) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.pdfViewer,
                          arguments: {
                            'title': resource.title,
                            'url': resource.fileUrl,
                          },
                        ),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text("View"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (isDownloading || isDownloaded)
                            ? null
                            : () => _handleDownload(resource),
                        icon: Icon(
                          isDownloaded
                              ? Icons.check_circle
                              : isDownloading
                              ? Icons.downloading_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(
                          isDownloaded
                              ? "Downloaded"
                              : isDownloading
                              ? "${((progress ?? 0.0) * 100).toInt()}%"
                              : "Download",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDownloaded
                              ? Colors.green
                              : AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (ext.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (ext.contains('doc')) return Icons.description_rounded;
    if (ext.contains('xls')) return Icons.table_chart_rounded;
    if (ext.contains('ppt')) return Icons.slideshow_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _toggleBookmark(ResourceModel resource) async {
    final box = await Hive.openBox(AppConstants.bookmarksBox);

    setState(() => _isBookmarked = !_isBookmarked);

    if (_isBookmarked) {
      await box.put(resource.id, resource.toMap());
      await NotificationTriggers.resourceSaved(resource.title);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
        await analyticsProvider.trackBookmark(
          auth.currentUser!.id,
          resource.id,
          resource.title,
          resource.resourceType,
          resource.subject,
        );
      }

      _showSnack('Added to bookmarks');
    } else {
      await box.delete(resource.id);
      _showSnack('Removed from bookmarks');
    }

    HapticFeedback.mediumImpact();
  }
}