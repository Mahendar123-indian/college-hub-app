import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive study analytics model tracking user behavior
class StudyAnalyticsModel {
  final String id;
  final String userId;

  // Time-based metrics
  final int totalStudyTimeMinutes;
  final int todayStudyTimeMinutes;
  final int weekStudyTimeMinutes;
  final int monthStudyTimeMinutes;

  // Resource interaction metrics
  final int totalResourcesViewed;
  final int totalResourcesDownloaded;
  final int totalBookmarks;
  final int totalSearches;

  // Subject-wise performance
  final Map<String, SubjectStats> subjectPerformance;

  // Streak tracking
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<DateTime> activeDates;

  // Resource type preferences
  final Map<String, int> resourceTypePreferences;

  // Daily activity breakdown
  final Map<String, DailyActivity> dailyActivities; // date -> activity

  // Engagement score (0-100)
  final double engagementScore;

  // Goals & achievements
  final int weeklyGoalMinutes;
  final int achievedGoals;
  final List<String> unlockedBadges;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyAnalyticsModel({
    required this.id,
    required this.userId,
    this.totalStudyTimeMinutes = 0,
    this.todayStudyTimeMinutes = 0,
    this.weekStudyTimeMinutes = 0,
    this.monthStudyTimeMinutes = 0,
    this.totalResourcesViewed = 0,
    this.totalResourcesDownloaded = 0,
    this.totalBookmarks = 0,
    this.totalSearches = 0,
    this.subjectPerformance = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.activeDates = const [],
    this.resourceTypePreferences = const {},
    this.dailyActivities = const {},
    this.engagementScore = 0.0,
    this.weeklyGoalMinutes = 300, // 5 hours default
    this.achievedGoals = 0,
    this.unlockedBadges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  double get weeklyGoalProgress {
    if (weeklyGoalMinutes == 0) return 0;
    return (weekStudyTimeMinutes / weeklyGoalMinutes).clamp(0.0, 1.0);
  }

  bool get isWeeklyGoalAchieved => weekStudyTimeMinutes >= weeklyGoalMinutes;

  String get studyLevel {
    if (totalStudyTimeMinutes < 300) return 'Beginner';
    if (totalStudyTimeMinutes < 1200) return 'Intermediate';
    if (totalStudyTimeMinutes < 3600) return 'Advanced';
    return 'Expert';
  }

  int get studyLevelProgress {
    const levels = [0, 300, 1200, 3600, 10000];
    for (int i = 0; i < levels.length - 1; i++) {
      if (totalStudyTimeMinutes >= levels[i] && totalStudyTimeMinutes < levels[i + 1]) {
        return ((totalStudyTimeMinutes - levels[i]) / (levels[i + 1] - levels[i]) * 100).toInt();
      }
    }
    return 100;
  }

  String get averageDailyStudyTime {
    if (activeDates.isEmpty) return '0h 0m';
    int avgMinutes = totalStudyTimeMinutes ~/ activeDates.length;
    int hours = avgMinutes ~/ 60;
    int minutes = avgMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  List<String> get topSubjects {
    final sorted = subjectPerformance.entries.toList()
      ..sort((a, b) => b.value.totalMinutes.compareTo(a.value.totalMinutes));
    return sorted.take(3).map((e) => e.key).toList();
  }

  String get mostUsedResourceType {
    if (resourceTypePreferences.isEmpty) return 'None';
    return resourceTypePreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE CONVERSION
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'totalStudyTimeMinutes': totalStudyTimeMinutes,
      'todayStudyTimeMinutes': todayStudyTimeMinutes,
      'weekStudyTimeMinutes': weekStudyTimeMinutes,
      'monthStudyTimeMinutes': monthStudyTimeMinutes,
      'totalResourcesViewed': totalResourcesViewed,
      'totalResourcesDownloaded': totalResourcesDownloaded,
      'totalBookmarks': totalBookmarks,
      'totalSearches': totalSearches,
      'subjectPerformance': subjectPerformance.map(
            (key, value) => MapEntry(key, value.toMap()),
      ),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'activeDates': activeDates.map((d) => Timestamp.fromDate(d)).toList(),
      'resourceTypePreferences': resourceTypePreferences,
      'dailyActivities': dailyActivities.map(
            (key, value) => MapEntry(key, value.toMap()),
      ),
      'engagementScore': engagementScore,
      'weeklyGoalMinutes': weeklyGoalMinutes,
      'achievedGoals': achievedGoals,
      'unlockedBadges': unlockedBadges,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StudyAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return StudyAnalyticsModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalStudyTimeMinutes: map['totalStudyTimeMinutes'] ?? 0,
      todayStudyTimeMinutes: map['todayStudyTimeMinutes'] ?? 0,
      weekStudyTimeMinutes: map['weekStudyTimeMinutes'] ?? 0,
      monthStudyTimeMinutes: map['monthStudyTimeMinutes'] ?? 0,
      totalResourcesViewed: map['totalResourcesViewed'] ?? 0,
      totalResourcesDownloaded: map['totalResourcesDownloaded'] ?? 0,
      totalBookmarks: map['totalBookmarks'] ?? 0,
      totalSearches: map['totalSearches'] ?? 0,
      subjectPerformance: (map['subjectPerformance'] as Map<String, dynamic>?)
          ?.map((key, value) =>
          MapEntry(key, SubjectStats.fromMap(value))) ??
          {},
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: _parseDateTime(map['lastActiveDate']),
      activeDates: (map['activeDates'] as List?)
          ?.map((e) => _parseDateTime(e)!)
          .toList() ??
          [],
      resourceTypePreferences:
      Map<String, int>.from(map['resourceTypePreferences'] ?? {}),
      dailyActivities: (map['dailyActivities'] as Map<String, dynamic>?)
          ?.map((key, value) =>
          MapEntry(key, DailyActivity.fromMap(value))) ??
          {},
      engagementScore: (map['engagementScore'] ?? 0).toDouble(),
      weeklyGoalMinutes: map['weeklyGoalMinutes'] ?? 300,
      achievedGoals: map['achievedGoals'] ?? 0,
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  factory StudyAnalyticsModel.fromDocument(DocumentSnapshot doc) {
    return StudyAnalyticsModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  StudyAnalyticsModel copyWith({
    int? totalStudyTimeMinutes,
    int? todayStudyTimeMinutes,
    int? weekStudyTimeMinutes,
    int? monthStudyTimeMinutes,
    int? totalResourcesViewed,
    int? totalResourcesDownloaded,
    int? totalBookmarks,
    int? totalSearches,
    Map<String, SubjectStats>? subjectPerformance,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<DateTime>? activeDates,
    Map<String, int>? resourceTypePreferences,
    Map<String, DailyActivity>? dailyActivities,
    double? engagementScore,
    int? weeklyGoalMinutes,
    int? achievedGoals,
    List<String>? unlockedBadges,
    DateTime? updatedAt,
  }) {
    return StudyAnalyticsModel(
      id: id,
      userId: userId,
      totalStudyTimeMinutes: totalStudyTimeMinutes ?? this.totalStudyTimeMinutes,
      todayStudyTimeMinutes: todayStudyTimeMinutes ?? this.todayStudyTimeMinutes,
      weekStudyTimeMinutes: weekStudyTimeMinutes ?? this.weekStudyTimeMinutes,
      monthStudyTimeMinutes: monthStudyTimeMinutes ?? this.monthStudyTimeMinutes,
      totalResourcesViewed: totalResourcesViewed ?? this.totalResourcesViewed,
      totalResourcesDownloaded: totalResourcesDownloaded ?? this.totalResourcesDownloaded,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      totalSearches: totalSearches ?? this.totalSearches,
      subjectPerformance: subjectPerformance ?? this.subjectPerformance,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      activeDates: activeDates ?? this.activeDates,
      resourceTypePreferences: resourceTypePreferences ?? this.resourceTypePreferences,
      dailyActivities: dailyActivities ?? this.dailyActivities,
      engagementScore: engagementScore ?? this.engagementScore,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      achievedGoals: achievedGoals ?? this.achievedGoals,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUBJECT STATISTICS
// ═══════════════════════════════════════════════════════════════

class SubjectStats {
  final String subjectName;
  final int totalMinutes;
  final int resourcesViewed;
  final int resourcesDownloaded;
  final double averageRating;
  final DateTime lastStudied;

  SubjectStats({
    required this.subjectName,
    this.totalMinutes = 0,
    this.resourcesViewed = 0,
    this.resourcesDownloaded = 0,
    this.averageRating = 0.0,
    required this.lastStudied,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'totalMinutes': totalMinutes,
      'resourcesViewed': resourcesViewed,
      'resourcesDownloaded': resourcesDownloaded,
      'averageRating': averageRating,
      'lastStudied': Timestamp.fromDate(lastStudied),
    };
  }

  factory SubjectStats.fromMap(Map<String, dynamic> map) {
    return SubjectStats(
      subjectName: map['subjectName'] ?? '',
      totalMinutes: map['totalMinutes'] ?? 0,
      resourcesViewed: map['resourcesViewed'] ?? 0,
      resourcesDownloaded: map['resourcesDownloaded'] ?? 0,
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      lastStudied: (map['lastStudied'] as Timestamp).toDate(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DAILY ACTIVITY
// ═══════════════════════════════════════════════════════════════

class DailyActivity {
  final DateTime date;
  final int studyMinutes;
  final int resourcesViewed;
  final int downloads;
  final List<String> subjectsStudied;

  DailyActivity({
    required this.date,
    this.studyMinutes = 0,
    this.resourcesViewed = 0,
    this.downloads = 0,
    this.subjectsStudied = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'studyMinutes': studyMinutes,
      'resourcesViewed': resourcesViewed,
      'downloads': downloads,
      'subjectsStudied': subjectsStudied,
    };
  }

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      date: (map['date'] as Timestamp).toDate(),
      studyMinutes: map['studyMinutes'] ?? 0,
      resourcesViewed: map['resourcesViewed'] ?? 0,
      downloads: map['downloads'] ?? 0,
      subjectsStudied: List<String>.from(map['subjectsStudied'] ?? []),
    );
  }
}