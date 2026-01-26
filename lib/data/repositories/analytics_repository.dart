import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/study_analytics_model.dart';
import '../models/user_activity_model.dart';
import '../models/study_streak_model.dart';

class AnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _analyticsCollection = 'study_analytics';
  static const String _activitiesCollection = 'user_activities';
  static const String _streaksCollection = 'study_streaks';

  // ═══════════════════════════════════════════════════════════════
  // STUDY ANALYTICS CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Get or create analytics for user
  Future<StudyAnalyticsModel> getOrCreateAnalytics(String userId) async {
    try {
      final doc = await _firestore
          .collection(_analyticsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return StudyAnalyticsModel.fromDocument(doc);
      }

      // Create new analytics
      final newAnalytics = StudyAnalyticsModel(
        id: userId,
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_analyticsCollection)
          .doc(userId)
          .set(newAnalytics.toFirestoreMap());

      debugPrint('✅ Created analytics for user: $userId');
      return newAnalytics;
    } catch (e) {
      debugPrint('❌ getOrCreateAnalytics error: $e');
      rethrow;
    }
  }

  /// Stream analytics for real-time updates
  /// ✅ FIXED: Added error handling to prevent permission denied errors
  Stream<StudyAnalyticsModel?> getAnalyticsStream(String userId) {
    return _firestore
        .collection(_analyticsCollection)
        .doc(userId)
        .snapshots()
        .handleError((error) {
      debugPrint('⚠️ Analytics stream error (expected during logout): $error');
      // Return null instead of throwing error during logout
      return null;
    }).map((doc) {
      if (!doc.exists) return null;
      return StudyAnalyticsModel.fromDocument(doc);
    });
  }

  /// Update analytics
  Future<void> updateAnalytics(StudyAnalyticsModel analytics) async {
    try {
      await _firestore
          .collection(_analyticsCollection)
          .doc(analytics.userId)
          .update(analytics.toFirestoreMap());

      debugPrint('✅ Updated analytics for: ${analytics.userId}');
    } catch (e) {
      debugPrint('❌ updateAnalytics error: $e');
      rethrow;
    }
  }

  /// Increment resource view
  Future<void> incrementResourceView(
      String userId,
      String resourceType,
      String subject,
      ) async {
    try {
      final docRef = _firestore.collection(_analyticsCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create new document
          final newAnalytics = StudyAnalyticsModel(
            id: userId,
            userId: userId,
            totalResourcesViewed: 1,
            resourceTypePreferences: {resourceType: 1},
            subjectPerformance: {
              subject: SubjectStats(
                subjectName: subject,
                resourcesViewed: 1,
                lastStudied: DateTime.now(),
              ),
            },
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          transaction.set(docRef, newAnalytics.toFirestoreMap());
        } else {
          transaction.update(docRef, {
            'totalResourcesViewed': FieldValue.increment(1),
            'resourceTypePreferences.$resourceType': FieldValue.increment(1),
            'subjectPerformance.$subject.resourcesViewed':
            FieldValue.increment(1),
            'subjectPerformance.$subject.lastStudied':
            FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('✅ Incremented view for $userId');
    } catch (e) {
      debugPrint('❌ incrementResourceView error: $e');
      rethrow;
    }
  }

  /// Increment download count
  Future<void> incrementDownload(
      String userId,
      String resourceType,
      String subject,
      ) async {
    try {
      final docRef = _firestore.collection(_analyticsCollection).doc(userId);

      await docRef.update({
        'totalResourcesDownloaded': FieldValue.increment(1),
        'resourceTypePreferences.$resourceType': FieldValue.increment(1),
        'subjectPerformance.$subject.resourcesDownloaded':
        FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Incremented download for $userId');
    } catch (e) {
      debugPrint('❌ incrementDownload error: $e');
    }
  }

  /// Add study time
  Future<void> addStudyTime(
      String userId,
      int minutes,
      String subject,
      ) async {
    try {
      final docRef = _firestore.collection(_analyticsCollection).doc(userId);
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await docRef.update({
        'totalStudyTimeMinutes': FieldValue.increment(minutes),
        'todayStudyTimeMinutes': FieldValue.increment(minutes),
        'weekStudyTimeMinutes': FieldValue.increment(minutes),
        'monthStudyTimeMinutes': FieldValue.increment(minutes),
        'subjectPerformance.$subject.totalMinutes': FieldValue.increment(minutes),
        'dailyActivities.$dateKey.studyMinutes': FieldValue.increment(minutes),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Added $minutes minutes for $userId');
    } catch (e) {
      debugPrint('❌ addStudyTime error: $e');
    }
  }

  /// Reset daily/weekly/monthly counters
  Future<void> resetCounters(String userId, String period) async {
    try {
      final docRef = _firestore.collection(_analyticsCollection).doc(userId);

      switch (period) {
        case 'daily':
          await docRef.update({
            'todayStudyTimeMinutes': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
        case 'weekly':
          await docRef.update({
            'weekStudyTimeMinutes': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
        case 'monthly':
          await docRef.update({
            'monthStudyTimeMinutes': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
      }

      debugPrint('✅ Reset $period counters for $userId');
    } catch (e) {
      debugPrint('❌ resetCounters error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER ACTIVITIES
  // ═══════════════════════════════════════════════════════════════

  /// Log user activity
  Future<void> logActivity(UserActivityModel activity) async {
    try {
      await _firestore
          .collection(_activitiesCollection)
          .doc(activity.id)
          .set(activity.toFirestoreMap());

      debugPrint('✅ Logged activity: ${activity.type.name}');
    } catch (e) {
      debugPrint('❌ logActivity error: $e');
    }
  }

  /// Get recent activities
  Future<List<UserActivityModel>> getRecentActivities(
      String userId, {
        int limit = 20,
      }) async {
    try {
      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs
          .map((doc) => UserActivityModel.fromDocument(doc))
          .toList();

      debugPrint('✅ Fetched ${activities.length} activities');
      return activities;
    } catch (e) {
      debugPrint('❌ getRecentActivities error: $e');
      return [];
    }
  }

  /// Get activities by date range
  Future<List<UserActivityModel>> getActivitiesByDateRange(
      String userId,
      DateTime start,
      DateTime end,
      ) async {
    try {
      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ getActivitiesByDateRange error: $e');
      return [];
    }
  }

  /// Get activities by subject
  Future<List<UserActivityModel>> getActivitiesBySubject(
      String userId,
      String subject, {
        int limit = 10,
      }) async {
    try {
      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .where('subject', isEqualTo: subject)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserActivityModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ getActivitiesBySubject error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY STREAKS
  // ═══════════════════════════════════════════════════════════════

  /// Get or create streak
  Future<StudyStreakModel> getOrCreateStreak(String userId) async {
    try {
      final doc =
      await _firestore.collection(_streaksCollection).doc(userId).get();

      if (doc.exists) {
        return StudyStreakModel.fromDocument(doc);
      }

      // Create new streak
      final newStreak = StudyStreakModel(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_streaksCollection)
          .doc(userId)
          .set(newStreak.toFirestoreMap());

      debugPrint('✅ Created streak for user: $userId');
      return newStreak;
    } catch (e) {
      debugPrint('❌ getOrCreateStreak error: $e');
      rethrow;
    }
  }

  /// Stream streak for real-time updates
  /// ✅ FIXED: Added error handling to prevent permission denied errors
  Stream<StudyStreakModel?> getStreakStream(String userId) {
    return _firestore
        .collection(_streaksCollection)
        .doc(userId)
        .snapshots()
        .handleError((error) {
      debugPrint('⚠️ Streak stream error (expected during logout): $error');
      // Return null instead of throwing error during logout
      return null;
    }).map((doc) {
      if (!doc.exists) return null;
      return StudyStreakModel.fromDocument(doc);
    });
  }

  /// Update streak
  Future<void> updateStreak(StudyStreakModel streak) async {
    try {
      await _firestore
          .collection(_streaksCollection)
          .doc(streak.userId)
          .update(streak.toFirestoreMap());

      debugPrint('✅ Updated streak for: ${streak.userId}');
    } catch (e) {
      debugPrint('❌ updateStreak error: $e');
      rethrow;
    }
  }

  /// Record study session (updates streak automatically)
  Future<void> recordStudySession(String userId) async {
    try {
      final currentStreak = await getOrCreateStreak(userId);
      final updatedStreak =
      StreakCalculator.updateStreak(currentStreak, DateTime.now());

      await updateStreak(updatedStreak);

      debugPrint('✅ Recorded study session for $userId');
    } catch (e) {
      debugPrint('❌ recordStudySession error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS QUERIES
  // ═══════════════════════════════════════════════════════════════

  /// Get top performing subjects
  Future<List<SubjectStats>> getTopSubjects(
      String userId, {
        int limit = 5,
      }) async {
    try {
      final analytics = await getOrCreateAnalytics(userId);
      final sorted = analytics.subjectPerformance.values.toList()
        ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint('❌ getTopSubjects error: $e');
      return [];
    }
  }

  /// Get study time for last 7 days
  Future<Map<String, int>> getLast7DaysStudyTime(String userId) async {
    try {
      final analytics = await getOrCreateAnalytics(userId);
      final result = <String, int>{};

      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        result[dateKey] =
            analytics.dailyActivities[dateKey]?.studyMinutes ?? 0;
      }

      return result;
    } catch (e) {
      debugPrint('❌ getLast7DaysStudyTime error: $e');
      return {};
    }
  }

  /// Calculate engagement score
  Future<double> calculateEngagementScore(String userId) async {
    try {
      final analytics = await getOrCreateAnalytics(userId);

      double score = 0;

      // Time-based score (40%)
      score += (analytics.weekStudyTimeMinutes / 300) * 40;

      // Interaction score (30%)
      final interactions = analytics.totalResourcesViewed +
          analytics.totalResourcesDownloaded +
          analytics.totalBookmarks;
      score += (interactions / 100) * 30;

      // Streak score (30%)
      final streak = await getOrCreateStreak(userId);
      score += (streak.currentStreak / 7) * 30;

      return score.clamp(0, 100);
    } catch (e) {
      debugPrint('❌ calculateEngagementScore error: $e');
      return 0;
    }
  }

  /// Get leaderboard (top users by study time)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_analyticsCollection)
          .orderBy('weekStudyTimeMinutes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
        'userId': doc.id,
        'studyTime': doc.data()['weekStudyTimeMinutes'] ?? 0,
      })
          .toList();
    } catch (e) {
      debugPrint('❌ getLeaderboard error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP & MAINTENANCE
  // ═══════════════════════════════════════════════════════════════

  /// Delete old activities (older than 90 days)
  Future<void> cleanupOldActivities() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${snapshot.docs.length} old activities');
    } catch (e) {
      debugPrint('❌ cleanupOldActivities error: $e');
    }
  }
}