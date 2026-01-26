import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/youtube_video_model.dart';

class YouTubeCacheService {
  static const String _watchHistoryBoxName = 'youtube_watch_history';
  static const String _favoritesBoxName = 'youtube_favorites';
  static const String _watchLaterBoxName = 'youtube_watch_later';

  late Box<dynamic> _watchHistoryBox;
  late Box<dynamic> _favoritesBox;
  late Box<dynamic> _watchLaterBox;
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _watchHistoryBox = await Hive.openBox(_watchHistoryBoxName);
      _favoritesBox = await Hive.openBox(_favoritesBoxName);
      _watchLaterBox = await Hive.openBox(_watchLaterBoxName);
      _isInitialized = true;
      debugPrint('✅ YouTubeCacheService initialized');
    } catch (e) {
      debugPrint('❌ YouTubeCacheService init error: $e');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCH HISTORY
  // ═══════════════════════════════════════════════════════════════

  Future<void> addToWatchHistory(YouTubeVideoModel video) async {
    try {
      await _ensureInitialized();

      final data = video.toMap();
      data['watchedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _watchHistoryBox.put(video.videoId, data);
      debugPrint('✅ Added to watch history: ${video.title}');
    } catch (e) {
      debugPrint('❌ addToWatchHistory error: $e');
    }
  }

  Future<List<YouTubeVideoModel>> getWatchHistory() async {
    try {
      await _ensureInitialized();

      final videos = <YouTubeVideoModel>[];
      for (var key in _watchHistoryBox.keys) {
        final data = _watchHistoryBox.get(key);
        if (data != null) {
          videos.add(YouTubeVideoModel.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      // Sort by watched date (newest first)
      videos.sort((a, b) {
        final aData = _watchHistoryBox.get(a.videoId);
        final bData = _watchHistoryBox.get(b.videoId);
        final aWatched = aData != null && aData is Map ? (aData['watchedAt'] ?? 0) : 0;
        final bWatched = bData != null && bData is Map ? (bData['watchedAt'] ?? 0) : 0;
        return bWatched.compareTo(aWatched);
      });

      debugPrint('✅ Loaded ${videos.length} videos from watch history');
      return videos;
    } catch (e) {
      debugPrint('❌ getWatchHistory error: $e');
      return [];
    }
  }

  Future<void> clearWatchHistory() async {
    try {
      await _ensureInitialized();
      await _watchHistoryBox.clear();
      debugPrint('✅ Watch history cleared');
    } catch (e) {
      debugPrint('❌ clearWatchHistory error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FAVORITES
  // ═══════════════════════════════════════════════════════════════

  Future<void> addToFavorites(YouTubeVideoModel video) async {
    try {
      await _ensureInitialized();

      final data = video.toMap();
      data['favoritedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _favoritesBox.put(video.videoId, data);
      debugPrint('✅ Added to favorites: ${video.title}');
    } catch (e) {
      debugPrint('❌ addToFavorites error: $e');
    }
  }

  Future<void> removeFromFavorites(String videoId) async {
    try {
      await _ensureInitialized();
      await _favoritesBox.delete(videoId);
      debugPrint('✅ Removed from favorites: $videoId');
    } catch (e) {
      debugPrint('❌ removeFromFavorites error: $e');
    }
  }

  Future<bool> isFavorite(String videoId) async {
    try {
      await _ensureInitialized();
      return _favoritesBox.containsKey(videoId);
    } catch (e) {
      debugPrint('❌ isFavorite error: $e');
      return false;
    }
  }

  Future<List<YouTubeVideoModel>> getFavorites() async {
    try {
      await _ensureInitialized();

      final videos = <YouTubeVideoModel>[];
      for (var key in _favoritesBox.keys) {
        final data = _favoritesBox.get(key);
        if (data != null) {
          videos.add(YouTubeVideoModel.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      // Sort by favorited date (newest first)
      videos.sort((a, b) {
        final aData = _favoritesBox.get(a.videoId);
        final bData = _favoritesBox.get(b.videoId);
        final aFavorited = aData != null && aData is Map ? (aData['favoritedAt'] ?? 0) : 0;
        final bFavorited = bData != null && bData is Map ? (bData['favoritedAt'] ?? 0) : 0;
        return bFavorited.compareTo(aFavorited);
      });

      debugPrint('✅ Loaded ${videos.length} favorite videos');
      return videos;
    } catch (e) {
      debugPrint('❌ getFavorites error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCH LATER
  // ═══════════════════════════════════════════════════════════════

  Future<void> addToWatchLater(YouTubeVideoModel video) async {
    try {
      await _ensureInitialized();

      final data = video.toMap();
      data['addedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _watchLaterBox.put(video.videoId, data);
      debugPrint('✅ Added to watch later: ${video.title}');
    } catch (e) {
      debugPrint('❌ addToWatchLater error: $e');
    }
  }

  Future<void> removeFromWatchLater(String videoId) async {
    try {
      await _ensureInitialized();
      await _watchLaterBox.delete(videoId);
      debugPrint('✅ Removed from watch later: $videoId');
    } catch (e) {
      debugPrint('❌ removeFromWatchLater error: $e');
    }
  }

  Future<bool> isInWatchLater(String videoId) async {
    try {
      await _ensureInitialized();
      return _watchLaterBox.containsKey(videoId);
    } catch (e) {
      debugPrint('❌ isInWatchLater error: $e');
      return false;
    }
  }

  Future<List<YouTubeVideoModel>> getWatchLater() async {
    try {
      await _ensureInitialized();

      final videos = <YouTubeVideoModel>[];
      for (var key in _watchLaterBox.keys) {
        final data = _watchLaterBox.get(key);
        if (data != null) {
          videos.add(YouTubeVideoModel.fromMap(Map<String, dynamic>.from(data)));
        }
      }

      // Sort by added date (newest first)
      videos.sort((a, b) {
        final aData = _watchLaterBox.get(a.videoId);
        final bData = _watchLaterBox.get(b.videoId);
        final aAdded = aData != null && aData is Map ? (aData['addedAt'] ?? 0) : 0;
        final bAdded = bData != null && bData is Map ? (bData['addedAt'] ?? 0) : 0;
        return bAdded.compareTo(aAdded);
      });

      debugPrint('✅ Loaded ${videos.length} watch later videos');
      return videos;
    } catch (e) {
      debugPrint('❌ getWatchLater error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR ALL DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _watchHistoryBox.clear();
      await _favoritesBox.clear();
      await _watchLaterBox.clear();
      debugPrint('✅ All YouTube cache cleared');
    } catch (e) {
      debugPrint('❌ clearAll error: $e');
    }
  }
}