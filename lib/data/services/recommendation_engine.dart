import 'package:flutter/foundation.dart';
import '../models/study_analytics_model.dart';
import '../models/resource_model.dart';
import '../models/user_activity_model.dart';

/// AI-powered recommendation engine for personalized learning
class RecommendationEngine {
  /// Generate personalized resource recommendations
  static List<ResourceModel> getPersonalizedRecommendations(
      List<ResourceModel> allResources,
      StudyAnalyticsModel analytics,
      List<UserActivityModel> recentActivities, {
        int limit = 10,
      }) {
    if (allResources.isEmpty) return [];

    // Calculate scores for each resource
    final scoredResources = allResources.map((resource) {
      final score = _calculateRecommendationScore(
        resource,
        analytics,
        recentActivities,
      );
      return _ScoredResource(resource, score);
    }).toList();

    // Sort by score (highest first)
    scoredResources.sort((a, b) => b.score.compareTo(a.score));

    // Return top recommendations
    return scoredResources
        .take(limit)
        .map((sr) => sr.resource)
        .toList();
  }

  /// Calculate recommendation score for a resource
  static double _calculateRecommendationScore(
      ResourceModel resource,
      StudyAnalyticsModel analytics,
      List<UserActivityModel> recentActivities,
      ) {
    double score = 0;

    // 1. Subject preference (40%)
    score += _getSubjectPreferenceScore(resource, analytics) * 0.4;

    // 2. Resource type preference (20%)
    score += _getResourceTypeScore(resource, analytics) * 0.2;

    // 3. Popularity score (15%)
    score += _getPopularityScore(resource) * 0.15;

    // 4. Recency bonus (10%)
    score += _getRecencyScore(resource) * 0.1;

    // 5. Quality score (15%)
    score += _getQualityScore(resource) * 0.15;

    // Penalty for already viewed resources
    final hasViewed = recentActivities.any((a) => a.resourceId == resource.id);
    if (hasViewed) {
      score *= 0.5; // 50% penalty
    }

    return score;
  }

  /// Subject preference score based on user's study history
  static double _getSubjectPreferenceScore(
      ResourceModel resource,
      StudyAnalyticsModel analytics,
      ) {
    if (analytics.subjectPerformance.isEmpty) return 0.5;

    final subjectStats = analytics.subjectPerformance[resource.subject];
    if (subjectStats == null) return 0.3; // New subject, moderate score

    // More time spent = higher score
    final maxMinutes = analytics.subjectPerformance.values
        .map((s) => s.totalMinutes)
        .reduce((a, b) => a > b ? a : b);

    if (maxMinutes == 0) return 0.5;

    return (subjectStats.totalMinutes / maxMinutes).clamp(0.0, 1.0);
  }

  /// Resource type preference score
  static double _getResourceTypeScore(
      ResourceModel resource,
      StudyAnalyticsModel analytics,
      ) {
    if (analytics.resourceTypePreferences.isEmpty) return 0.5;

    final typeCount = analytics.resourceTypePreferences[resource.resourceType] ?? 0;
    final maxCount = analytics.resourceTypePreferences.values
        .reduce((a, b) => a > b ? a : b);

    if (maxCount == 0) return 0.5;

    return (typeCount / maxCount).clamp(0.0, 1.0);
  }

  /// Popularity score based on views and downloads
  static double _getPopularityScore(ResourceModel resource) {
    final totalInteractions = resource.viewCount + (resource.downloadCount * 2);

    // Normalize to 0-1 scale (assuming 1000 interactions is very popular)
    return (totalInteractions / 1000).clamp(0.0, 1.0);
  }

  /// Recency score (newer resources get higher scores)
  static double _getRecencyScore(ResourceModel resource) {
    final daysSinceUpload = DateTime.now().difference(resource.uploadedAt).inDays;

    // Exponential decay: newer = better
    if (daysSinceUpload <= 7) return 1.0;
    if (daysSinceUpload <= 30) return 0.8;
    if (daysSinceUpload <= 90) return 0.6;
    return 0.4;
  }

  /// Quality score based on ratings
  static double _getQualityScore(ResourceModel resource) {
    if (resource.ratingCount == 0) return 0.5; // No ratings yet

    // Normalize rating to 0-1 scale
    return (resource.rating / 5.0).clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Generate study suggestions based on analytics
  static List<String> getStudySuggestions(StudyAnalyticsModel analytics) {
    final suggestions = <String>[];

    // Time-based suggestions
    if (analytics.todayStudyTimeMinutes == 0) {
      suggestions.add('📚 Start your study session today!');
    } else if (analytics.todayStudyTimeMinutes < 30) {
      suggestions.add('⏰ Study for 30 more minutes to reach your daily goal');
    }

    // Streak suggestions
    if (analytics.currentStreak == 0) {
      suggestions.add('🔥 Build a study streak! Study daily to unlock rewards');
    } else if (analytics.currentStreak >= 7) {
      suggestions.add('🎉 Amazing ${analytics.currentStreak}-day streak! Keep going!');
    }

    // Goal suggestions
    if (analytics.weekStudyTimeMinutes < analytics.weeklyGoalMinutes) {
      final remaining = analytics.weeklyGoalMinutes - analytics.weekStudyTimeMinutes;
      suggestions.add('🎯 ${remaining} minutes left to reach weekly goal');
    }

    // Subject diversity
    if (analytics.subjectPerformance.length == 1) {
      suggestions.add('🌟 Try exploring resources in other subjects');
    }

    // Resource type diversity
    if (analytics.resourceTypePreferences.length == 1) {
      suggestions.add('📖 Explore different types of resources for better learning');
    }

    return suggestions.take(3).toList();
  }

  /// Get subjects that need attention
  static List<String> getSubjectsNeedingAttention(StudyAnalyticsModel analytics) {
    if (analytics.subjectPerformance.isEmpty) return [];

    final avgMinutes = analytics.totalStudyTimeMinutes /
        analytics.subjectPerformance.length;

    return analytics.subjectPerformance.entries
        .where((entry) => entry.value.totalMinutes < avgMinutes * 0.5)
        .map((entry) => entry.key)
        .take(3)
        .toList();
  }

  /// Get optimal study time suggestions
  static String getOptimalStudyTime(StudyAnalyticsModel analytics) {
    if (analytics.dailyActivities.isEmpty) {
      return 'Try studying in the morning for better retention';
    }

    // Analyze most productive hours (simplified)
    final morningMinutes = analytics.dailyActivities.values
        .where((a) => a.date.hour < 12)
        .fold(0, (sum, a) => sum + a.studyMinutes);

    final afternoonMinutes = analytics.dailyActivities.values
        .where((a) => a.date.hour >= 12 && a.date.hour < 18)
        .fold(0, (sum, a) => sum + a.studyMinutes);

    final eveningMinutes = analytics.dailyActivities.values
        .where((a) => a.date.hour >= 18)
        .fold(0, (sum, a) => sum + a.studyMinutes);

    if (morningMinutes > afternoonMinutes && morningMinutes > eveningMinutes) {
      return 'You study best in the morning! 🌅';
    } else if (afternoonMinutes > eveningMinutes) {
      return 'Afternoons are your peak study time! ☀️';
    } else {
      return 'You prefer evening study sessions! 🌙';
    }
  }

  /// Generate weekly study plan
  static List<String> generateWeeklyPlan(
      StudyAnalyticsModel analytics,
      int targetMinutesPerDay,
      ) {
    final plan = <String>[];
    final topSubjects = analytics.topSubjects;

    if (topSubjects.isEmpty) {
      plan.add('Explore different subjects to build your plan');
      return plan;
    }

    // Distribute study time across subjects
    for (int day = 1; day <= 7; day++) {
      final subjectIndex = (day - 1) % topSubjects.length;
      final subject = topSubjects[subjectIndex];

      plan.add('Day $day: $subject - $targetMinutesPerDay minutes');
    }

    return plan;
  }

  /// Calculate learning velocity (resources per week)
  static double calculateLearningVelocity(StudyAnalyticsModel analytics) {
    if (analytics.activeDates.isEmpty) return 0;

    final daysSinceStart = DateTime.now()
        .difference(analytics.createdAt)
        .inDays
        .clamp(1, 365);

    final resourcesPerDay = analytics.totalResourcesViewed / daysSinceStart;
    return (resourcesPerDay * 7).clamp(0, 100); // Resources per week
  }

  /// Get achievement progress
  static List<Map<String, dynamic>> getAchievementProgress(
      StudyAnalyticsModel analytics,
      ) {
    return [
      {
        'title': '100 Resources',
        'current': analytics.totalResourcesViewed,
        'target': 100,
        'emoji': '📚',
      },
      {
        'title': '50 Downloads',
        'current': analytics.totalResourcesDownloaded,
        'target': 50,
        'emoji': '⬇️',
      },
      {
        'title': '10 Hours Study',
        'current': analytics.totalStudyTimeMinutes,
        'target': 600,
        'emoji': '⏰',
      },
      {
        'title': '7 Day Streak',
        'current': analytics.currentStreak,
        'target': 7,
        'emoji': '🔥',
      },
    ];
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER CLASS
// ═══════════════════════════════════════════════════════════════

class _ScoredResource {
  final ResourceModel resource;
  final double score;

  _ScoredResource(this.resource, this.score);
}