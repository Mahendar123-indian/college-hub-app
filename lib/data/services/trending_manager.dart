import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TrendingManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ ADVANCED TRENDING CALCULATION
  // Factors: Downloads (40%), Views (30%), Recency (20%), Ratings (10%)
  Future<void> calculateTrendingScores() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Fetch recent active resources
      final snapshot = await _firestore
          .collection('resources')
          .where('isActive', isEqualTo: true)
          .where('uploadedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final downloads = (data['downloadCount'] as num?)?.toInt() ?? 0;
        final views = (data['viewCount'] as num?)?.toInt() ?? 0;
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final uploadedAt = (data['uploadedAt'] as Timestamp).toDate();

        // Calculate trending score
        final trendingScore = _calculateScore(
          downloads: downloads,
          views: views,
          rating: rating,
          uploadedAt: uploadedAt,
          now: now,
        );

        // Update trending status
        final isTrending = trendingScore > 50; // Threshold

        batch.update(doc.reference, {
          'trendingScore': trendingScore,
          'isTrending': isTrending,
          'lastTrendingUpdate': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Updated trending scores for ${snapshot.docs.length} resources');
    } catch (e) {
      debugPrint('❌ Trending calculation error: $e');
    }
  }

  double _calculateScore({
    required int downloads,
    required int views,
    required double rating,
    required DateTime uploadedAt,
    required DateTime now,
  }) {
    // Download score (0-40 points)
    final downloadScore = (downloads * 2).clamp(0, 40).toDouble();

    // View score (0-30 points)
    final viewScore = (views * 0.5).clamp(0, 30).toDouble();

    // Recency score (0-20 points) - Decays over 7 days
    final daysSinceUpload = now.difference(uploadedAt).inDays;
    final recencyScore = daysSinceUpload <= 7
        ? 20 - (daysSinceUpload * 2.85)
        : 0.0;

    // Rating score (0-10 points)
    final ratingScore = rating * 2;

    return downloadScore + viewScore + recencyScore + ratingScore;
  }

  // ✅ REAL-TIME TRENDING STREAM
  Stream<List<Map<String, dynamic>>> getTrendingStream() {
    return _firestore
        .collection('resources')
        .where('isTrending', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('trendingScore', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'subject': data['subject'] ?? '',
          'resourceType': data['resourceType'] ?? '',
          'downloadCount': data['downloadCount'] ?? 0,
          'viewCount': data['viewCount'] ?? 0,
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'trendingScore': (data['trendingScore'] as num?)?.toDouble() ?? 0.0,
          'uploadedAt': (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'fileUrl': data['fileUrl'] ?? '',
          'fileName': data['fileName'] ?? '',
          'fileExtension': data['fileExtension'] ?? '',
          'fileSize': data['fileSize'] ?? 0,
        };
      }).toList();
    });
  }

  // ✅ SCHEDULE PERIODIC UPDATES (Call from main.dart or a Cloud Function)
  Future<void> scheduleUpdates() async {
    // Run every 30 minutes
    await Future.doWhile(() async {
      await calculateTrendingScores();
      await Future.delayed(const Duration(minutes: 30));
      return true;
    });
  }
}