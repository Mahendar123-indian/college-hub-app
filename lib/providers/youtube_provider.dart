import 'package:flutter/foundation.dart';
import '../data/models/youtube_video_model.dart';
import '../data/services/youtube_service.dart';
import '../data/services/youtube_cache_service.dart';

class YouTubeProvider with ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final YouTubeCacheService _cacheService = YouTubeCacheService();

  List<YouTubeVideoModel> _videos = [];
  List<YouTubeVideoModel> _watchHistory = [];
  List<YouTubeVideoModel> _favorites = [];
  List<YouTubeVideoModel> _watchLater = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Current playing video
  YouTubeVideoModel? _currentVideo;
  int _currentVideoIndex = 0;

  // Getters
  List<YouTubeVideoModel> get videos => _videos;
  List<YouTubeVideoModel> get watchHistory => _watchHistory;
  List<YouTubeVideoModel> get favorites => _favorites;
  List<YouTubeVideoModel> get watchLater => _watchLater;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  YouTubeVideoModel? get currentVideo => _currentVideo;
  int get currentVideoIndex => _currentVideoIndex;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> init() async {
    try {
      await _youtubeService.init();
      await _cacheService.init();
      await loadWatchHistory();
      await loadFavorites();
      await loadWatchLater();
      debugPrint('✅ YouTubeProvider initialized');
    } catch (e) {
      debugPrint('❌ YouTubeProvider init error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH VIDEOS
  // ═══════════════════════════════════════════════════════════════

  Future<void> searchVideos({
    required String query,
    required String subject,
    String? topic,
    String? unit,
    int maxResults = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _videos = await _youtubeService.searchVideos(
        query: query,
        subject: subject,
        topic: topic,
        unit: unit,
        maxResults: maxResults,
      );

      debugPrint('✅ Loaded ${_videos.length} videos');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to search videos: $e';
      debugPrint('❌ searchVideos error: $e');
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD VIDEOS FOR RESOURCE
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadVideosForResource(String resourceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First try to load from Firestore
      _videos = await _youtubeService.getVideosFromFirestore(resourceId);

      if (_videos.isEmpty) {
        debugPrint('! No videos found for resource: $resourceId');
      }

      debugPrint('✅ Loaded ${_videos.length} videos for resource');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load videos: $e';
      debugPrint('❌ loadVideosForResource error: $e');
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ DIRECT VIDEO FETCH (NO PROVIDER STATE UPDATE)
  // ═══════════════════════════════════════════════════════════════

  /// Get videos directly without updating provider state
  /// This method is used by ResourceCard to avoid setState during build
  Future<List<YouTubeVideoModel>> getVideosForResourceDirect(String resourceId) async {
    try {
      // Get videos directly from Firestore without updating provider state
      final videos = await _youtubeService.getVideosFromFirestore(resourceId);
      debugPrint('✅ Direct fetch: ${videos.length} videos for resource $resourceId');
      return videos;
    } catch (e) {
      debugPrint('❌ getVideosForResourceDirect error: $e');
      return [];
    }
  }

  // ✅ NEW: Silent version for card loading (doesn't notify during build)
  Future<void> loadVideosForResourceSilent(String resourceId) async {
    try {
      // Load videos without triggering notifyListeners during initial load
      final videos = await _youtubeService.getVideosFromFirestore(resourceId);

      // Update internal state without notifying
      _videos = videos;

      if (_videos.isEmpty) {
        debugPrint('! No videos found for resource: $resourceId');
      } else {
        debugPrint('✅ Loaded ${_videos.length} videos for resource');
      }
    } catch (e) {
      debugPrint('❌ loadVideosForResourceSilent error: $e');
      _videos = [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE VIDEOS TO FIRESTORE (ADMIN FUNCTION)
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveVideosForResource({
    required String resourceId,
    required String resourceTitle,
    required String subject,
    String? topic,
    String? unit,
  }) async {
    try {
      // Search for videos
      await searchVideos(
        query: resourceTitle,
        subject: subject,
        topic: topic,
        unit: unit,
        maxResults: 5,
      );

      if (_videos.isNotEmpty) {
        // Save to Firestore
        await _youtubeService.saveVideosToFirestore(
          resourceId: resourceId,
          videos: _videos,
        );
        debugPrint('✅ Saved ${_videos.length} videos for resource');
      }
    } catch (e) {
      debugPrint('❌ saveVideosForResource error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PLAY VIDEO
  // ═══════════════════════════════════════════════════════════════

  void playVideo(YouTubeVideoModel video, int index) {
    _currentVideo = video;
    _currentVideoIndex = index;

    // Add to watch history
    _cacheService.addToWatchHistory(video);
    loadWatchHistory(); // Refresh watch history

    notifyListeners();
  }

  void playNextVideo() {
    if (_currentVideoIndex < _videos.length - 1) {
      _currentVideoIndex++;
      _currentVideo = _videos[_currentVideoIndex];

      // Add to watch history
      _cacheService.addToWatchHistory(_currentVideo!);

      notifyListeners();
    }
  }

  void playPreviousVideo() {
    if (_currentVideoIndex > 0) {
      _currentVideoIndex--;
      _currentVideo = _videos[_currentVideoIndex];

      // Add to watch history
      _cacheService.addToWatchHistory(_currentVideo!);

      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCH HISTORY
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadWatchHistory() async {
    try {
      _watchHistory = await _cacheService.getWatchHistory();
      debugPrint('✅ Loaded ${_watchHistory.length} videos from watch history');
    } catch (e) {
      debugPrint('❌ loadWatchHistory error: $e');
    }
  }

  Future<void> clearWatchHistory() async {
    try {
      await _cacheService.clearWatchHistory();
      _watchHistory = [];
      notifyListeners();
      debugPrint('✅ Watch history cleared');
    } catch (e) {
      debugPrint('❌ clearWatchHistory error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FAVORITES
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleFavorite(YouTubeVideoModel video) async {
    try {
      final isFav = await _cacheService.isFavorite(video.videoId);

      if (isFav) {
        await _cacheService.removeFromFavorites(video.videoId);
        debugPrint('✅ Removed from favorites: ${video.title}');
      } else {
        await _cacheService.addToFavorites(video);
        debugPrint('✅ Added to favorites: ${video.title}');
      }

      await loadFavorites();
    } catch (e) {
      debugPrint('❌ toggleFavorite error: $e');
    }
  }

  Future<bool> isFavorite(String videoId) async {
    try {
      return await _cacheService.isFavorite(videoId);
    } catch (e) {
      debugPrint('❌ isFavorite error: $e');
      return false;
    }
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await _cacheService.getFavorites();
      debugPrint('✅ Loaded ${_favorites.length} favorite videos');
    } catch (e) {
      debugPrint('❌ loadFavorites error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCH LATER
  // ═══════════════════════════════════════════════════════════════

  Future<void> toggleWatchLater(YouTubeVideoModel video) async {
    try {
      final isInWatchLater = await _cacheService.isInWatchLater(video.videoId);

      if (isInWatchLater) {
        await _cacheService.removeFromWatchLater(video.videoId);
        debugPrint('✅ Removed from watch later: ${video.title}');
      } else {
        await _cacheService.addToWatchLater(video);
        debugPrint('✅ Added to watch later: ${video.title}');
      }

      await loadWatchLater();
    } catch (e) {
      debugPrint('❌ toggleWatchLater error: $e');
    }
  }

  Future<bool> isInWatchLater(String videoId) async {
    try {
      return await _cacheService.isInWatchLater(videoId);
    } catch (e) {
      debugPrint('❌ isInWatchLater error: $e');
      return false;
    }
  }

  Future<void> loadWatchLater() async {
    try {
      _watchLater = await _cacheService.getWatchLater();
      debugPrint('✅ Loaded ${_watchLater.length} watch later videos');
    } catch (e) {
      debugPrint('❌ loadWatchLater error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearAllCache() async {
    try {
      await _cacheService.clearAll();
      await _youtubeService.clearCache();
      _watchHistory = [];
      _favorites = [];
      _watchLater = [];
      notifyListeners();
      debugPrint('✅ All YouTube cache cleared');
    } catch (e) {
      debugPrint('❌ clearAllCache error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _videos = [];
    _watchHistory = [];
    _favorites = [];
    _watchLater = [];
    _currentVideo = null;
    _currentVideoIndex = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}