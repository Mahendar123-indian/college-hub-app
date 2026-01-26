// lib/data/services/youtube_service.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/youtube_video_model.dart';
import '../models/youtube_playlist_model.dart';

/// 🎥 YOUTUBE SERVICE
/// Handles YouTube API integration, video search, caching, and Firestore persistence
class YouTubeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheBoxName = 'youtube_cache';

  // ✅ Load API key from .env file
  static String get _apiKey {
    final key = dotenv.env['YOUTUBE_API_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint('❌ ERROR: YOUTUBE_API_KEY not found in .env file!');
      throw Exception('YouTube API key not configured. Please add YOUTUBE_API_KEY to .env file');
    }
    return key;
  }

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  late Box _cacheBox;
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHOD TO SAFELY CAST MAPS
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _isInitialized = true;
      debugPrint('✅ YouTubeService initialized');
    } catch (e) {
      debugPrint('❌ YouTubeService init error: $e');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH VIDEOS BY TOPIC
  // ═══════════════════════════════════════════════════════════════

  Future<List<YouTubeVideoModel>> searchVideos({
    required String query,
    required String subject,
    String? topic,
    String? unit,
    int maxResults = 10,
    String? language = 'en',
  }) async {
    try {
      await _ensureInitialized();

      // Check cache first
      final cacheKey = 'search_${query}_${subject}_${topic}_${maxResults}';
      if (_cacheBox.containsKey(cacheKey)) {
        final cachedData = _cacheBox.get(cacheKey);
        if (cachedData is List) {
          final videos = cachedData
              .map((v) {
            try {
              final safeMap = _safeCastMap(v);
              return YouTubeVideoModel.fromMap(safeMap);
            } catch (e) {
              debugPrint('❌ Error parsing cached video: $e');
              return null;
            }
          })
              .whereType<YouTubeVideoModel>()
              .toList();
          debugPrint('✅ Loaded ${videos.length} videos from cache');
          return videos;
        }
      }

      // Build search query
      final searchQuery = _buildSearchQuery(query, subject, topic);

      // Make API request
      final url = Uri.parse(
        '$_baseUrl/search?'
            'key=$_apiKey&'
            'part=snippet&'
            'q=${Uri.encodeComponent(searchQuery)}&'
            'type=video&'
            'maxResults=$maxResults&'
            'relevanceLanguage=$language&'
            'order=relevance&'
            'videoDefinition=high&'
            'videoEmbeddable=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];

        if (items.isEmpty) {
          debugPrint('✅ No videos found for query: $searchQuery');
          return [];
        }

        // Get video IDs for additional details
        final videoIds = items
            .map((item) {
          try {
            final itemMap = _safeCastMap(item);
            final idMap = _safeCastMap(itemMap['id']);
            return idMap['videoId']?.toString() ?? '';
          } catch (e) {
            return '';
          }
        })
            .where((id) => id.isNotEmpty)
            .join(',');

        if (videoIds.isEmpty) {
          debugPrint('❌ No valid video IDs found');
          return [];
        }

        // Fetch video details (duration, view count, likes)
        final videos = await _getVideoDetails(videoIds, subject, topic, unit);

        // Cache the results
        try {
          await _cacheBox.put(
            cacheKey,
            videos.map((v) => v.toMap()).toList(),
          );
        } catch (e) {
          debugPrint('❌ Error caching videos: $e');
        }

        debugPrint('✅ Fetched ${videos.length} videos from YouTube API');
        return videos;
      } else if (response.statusCode == 403) {
        debugPrint('❌ YouTube API quota exceeded or invalid API key');
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        debugPrint('❌ YouTube API error: ${response.statusCode}');
        throw Exception('Failed to fetch videos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ searchVideos error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GET VIDEO DETAILS
  // ═══════════════════════════════════════════════════════════════

  Future<List<YouTubeVideoModel>> _getVideoDetails(
      String videoIds,
      String subject,
      String? topic,
      String? unit,
      ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/videos?'
            'key=$_apiKey&'
            'part=snippet,contentDetails,statistics&'
            'id=$videoIds',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];

        final videos = <YouTubeVideoModel>[];

        for (var item in items) {
          try {
            final itemMap = _safeCastMap(item);
            final snippet = _safeCastMap(itemMap['snippet']);
            final contentDetails = _safeCastMap(itemMap['contentDetails']);
            final statistics = _safeCastMap(itemMap['statistics']);
            final thumbnails = _safeCastMap(snippet['thumbnails']);
            final highThumb = _safeCastMap(thumbnails['high']);
            final mediumThumb = _safeCastMap(thumbnails['medium']);
            final defaultThumb = _safeCastMap(thumbnails['default']);

            final video = YouTubeVideoModel(
              id: itemMap['id']?.toString() ?? '',
              videoId: itemMap['id']?.toString() ?? '',
              title: snippet['title']?.toString() ?? 'Untitled',
              channelName: snippet['channelTitle']?.toString() ?? 'Unknown',
              channelId: snippet['channelId']?.toString() ?? '',
              thumbnailUrl: highThumb['url']?.toString() ??
                  mediumThumb['url']?.toString() ??
                  defaultThumb['url']?.toString() ??
                  '',
              duration: _formatDuration(contentDetails['duration']?.toString() ?? ''),
              description: snippet['description']?.toString() ?? '',
              viewCount: int.tryParse(statistics['viewCount']?.toString() ?? '0') ?? 0,
              publishedAt: _parseDateTime(snippet['publishedAt']),
              difficulty: 'Medium',
              suitableFor: 'First Time Learning',
              keyTopics: _extractKeyTopics(snippet['description']?.toString() ?? ''),
              timestamps: _generateTimestamps(snippet['description']?.toString() ?? ''),
              relevanceScore: 1.0,
              likeCount: int.tryParse(statistics['likeCount']?.toString() ?? '0') ?? 0,
              embedUrl: 'https://www.youtube.com/embed/${itemMap['id']}',
              subject: subject,
              topic: topic,
              unit: unit,
            );

            videos.add(video);
          } catch (e) {
            debugPrint('❌ Error parsing video item: $e');
            continue;
          }
        }

        return videos;
      } else {
        throw Exception('Failed to fetch video details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ _getVideoDetails error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE VIDEOS TO FIRESTORE (FOR PERSISTENCE)
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveVideosToFirestore({
    required String resourceId,
    required List<YouTubeVideoModel> videos,
  }) async {
    try {
      final batch = _firestore.batch();

      for (var video in videos) {
        final docRef = _firestore
            .collection('resources')
            .doc(resourceId)
            .collection('youtube_videos')
            .doc(video.videoId);

        batch.set(docRef, video.toFirestoreMap());
      }

      await batch.commit();
      debugPrint('✅ Saved ${videos.length} videos to Firestore');
    } catch (e) {
      debugPrint('❌ saveVideosToFirestore error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GET VIDEOS FROM FIRESTORE
  // ═══════════════════════════════════════════════════════════════

  Future<List<YouTubeVideoModel>> getVideosFromFirestore(String resourceId) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .doc(resourceId)
          .collection('youtube_videos')
          .orderBy('relevanceScore', descending: true)
          .get();

      final videos = snapshot.docs
          .map((doc) {
        try {
          return YouTubeVideoModel.fromDocument(doc);
        } catch (e) {
          debugPrint('❌ Error parsing Firestore document: $e');
          return null;
        }
      })
          .whereType<YouTubeVideoModel>()
          .toList();

      debugPrint('✅ Loaded ${videos.length} videos from Firestore');
      return videos;
    } catch (e) {
      debugPrint('❌ getVideosFromFirestore error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM VIDEOS FROM FIRESTORE
  // ═══════════════════════════════════════════════════════════════

  Stream<List<YouTubeVideoModel>> streamVideosFromFirestore(String resourceId) {
    return _firestore
        .collection('resources')
        .doc(resourceId)
        .collection('youtube_videos')
        .orderBy('relevanceScore', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
        try {
          return YouTubeVideoModel.fromDocument(doc);
        } catch (e) {
          debugPrint('❌ Error parsing Firestore document: $e');
          return null;
        }
      })
          .whereType<YouTubeVideoModel>()
          .toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  String _buildSearchQuery(String query, String subject, String? topic) {
    final parts = <String>[query, subject];
    if (topic != null && topic.isNotEmpty) {
      parts.add(topic);
    }
    parts.add('tutorial');
    parts.add('lecture');
    return parts.join(' ');
  }

  String _formatDuration(String isoDuration) {
    try {
      // Parse ISO 8601 duration (e.g., PT15M33S)
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(isoDuration);

      if (match == null) return '0:00';

      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;

      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '0:00';
    }
  }

  DateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    } catch (e) {
      debugPrint('❌ Error parsing date: $e');
      return DateTime.now();
    }
  }

  List<String> _extractKeyTopics(String description) {
    try {
      // Simple keyword extraction (can be improved with NLP)
      final keywords = <String>[];
      final commonWords = [
        'the', 'and', 'for', 'with', 'this', 'that', 'from',
        'will', 'can', 'are', 'you', 'your', 'have', 'how'
      ];

      final words = description.toLowerCase().split(RegExp(r'\s+'));
      final uniqueWords = words
          .toSet()
          .where((word) =>
      word.length > 3 &&
          !commonWords.contains(word) &&
          RegExp(r'^[a-z]+$').hasMatch(word))
          .take(5)
          .toList();

      keywords.addAll(uniqueWords);
      return keywords;
    } catch (e) {
      debugPrint('❌ Error extracting keywords: $e');
      return [];
    }
  }

  List<VideoTimestamp> _generateTimestamps(String description) {
    try {
      // Extract timestamps from description (format: 0:00, 1:23, etc.)
      final timestamps = <VideoTimestamp>[];
      final regex = RegExp(
        r'(\d{1,2}:\d{2}(?::\d{2})?)\s*[-–—]?\s*(.+?)(?=\n|\d{1,2}:\d{2}|$)',
        multiLine: true,
      );
      final matches = regex.allMatches(description);

      for (var match in matches) {
        final time = match.group(1) ?? '';
        final label = (match.group(2) ?? '').trim();

        if (time.isNotEmpty && label.isNotEmpty && label.length < 100) {
          timestamps.add(VideoTimestamp(
            time: time,
            label: label,
            description: label,
          ));
        }
      }

      return timestamps.take(5).toList();
    } catch (e) {
      debugPrint('❌ Error generating timestamps: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR CACHE
  // ═══════════════════════════════════════════════════════════════

  Future<void> clearCache() async {
    try {
      await _ensureInitialized();
      await _cacheBox.clear();
      debugPrint('✅ YouTube cache cleared');
    } catch (e) {
      debugPrint('❌ clearCache error: $e');
    }
  }
}