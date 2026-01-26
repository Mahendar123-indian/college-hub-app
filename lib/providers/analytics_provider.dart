import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/study_analytics_model.dart';
import '../data/models/user_activity_model.dart';
import '../data/models/study_streak_model.dart';
import '../data/repositories/analytics_repository.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsRepository _repository = AnalyticsRepository();

  StudyAnalyticsModel? _analytics;
  StudyStreakModel? _streak;
  List<UserActivityModel> _recentActivities = [];
  Map<String, int> _weeklyChart = {};
  List<SubjectStats> _topSubjects = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription? _analyticsSubscription;
  StreamSubscription? _streakSubscription;

  // Getters
  StudyAnalyticsModel? get analytics => _analytics;
  StudyStreakModel? get streak => _streak;
  List<UserActivityModel> get recentActivities => _recentActivities;
  Map<String, int> get weeklyChart => _weeklyChart;
  List<SubjectStats> get topSubjects => _topSubjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Quick access getters
  int get totalStudyTime => _analytics?.totalStudyTimeMinutes ?? 0;
  int get currentStreak => _streak?.currentStreak ?? 0;
  int get todayStudyTime => _analytics?.todayStudyTimeMinutes ?? 0;
  int get weekStudyTime => _analytics?.weekStudyTimeMinutes ?? 0;
  int get totalResources => _analytics?.totalResourcesViewed ?? 0;
  int get totalDownloads => _analytics?.totalResourcesDownloaded ?? 0;
  double get engagementScore => _analytics?.engagementScore ?? 0;
  bool get hasData => _analytics != null;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initializeForUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ FIXED: Cancel existing subscriptions FIRST
      await cancelStreams();

      // Start real-time streams with proper error handling
      _analyticsSubscription = _repository
          .getAnalyticsStream(userId)
          .listen(
        _onAnalyticsUpdate,
        onError: _onError,
        cancelOnError: false, // ✅ Don't cancel on error
      );

      _streakSubscription = _repository
          .getStreakStream(userId)
          .listen(
        _onStreakUpdate,
        onError: _onError,
        cancelOnError: false, // ✅ Don't cancel on error
      );

      // Load additional data
      await Future.wait([
        _loadRecentActivities(userId),
        _loadWeeklyChart(userId),
        _loadTopSubjects(userId),
      ]);

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ AnalyticsProvider initialized for $userId');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to initialize analytics: $e';
      debugPrint('❌ initializeForUser error: $e');
      notifyListeners();
    }
  }

  void _onAnalyticsUpdate(StudyAnalyticsModel? analytics) {
    _analytics = analytics;
    notifyListeners();
  }

  void _onStreakUpdate(StudyStreakModel? streak) {
    _streak = streak;
    notifyListeners();
  }

  void _onError(error) {
    // ✅ FIXED: Only log errors, don't update UI during logout
    if (error.toString().contains('permission-denied')) {
      debugPrint('⚠️ Analytics stream permission denied (expected during logout)');
    } else {
      _errorMessage = error.toString();
      debugPrint('❌ Stream error: $error');
      notifyListeners();
    }
  }

  Future<void> _loadRecentActivities(String userId) async {
    try {
      _recentActivities = await _repository.getRecentActivities(userId, limit: 10);
    } catch (e) {
      debugPrint('❌ _loadRecentActivities error: $e');
    }
  }

  Future<void> _loadWeeklyChart(String userId) async {
    try {
      _weeklyChart = await _repository.getLast7DaysStudyTime(userId);
    } catch (e) {
      debugPrint('❌ _loadWeeklyChart error: $e');
    }
  }

  Future<void> _loadTopSubjects(String userId) async {
    try {
      _topSubjects = await _repository.getTopSubjects(userId, limit: 3);
    } catch (e) {
      debugPrint('❌ _loadTopSubjects error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TRACK ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Track resource view
  Future<void> trackView(
      String userId,
      String resourceId,
      String resourceTitle,
      String resourceType,
      String subject,
      ) async {
    try {
      // Log activity
      final activity = UserActivityModel(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: ActivityType.view,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
        resourceType: resourceType,
        subject: subject,
        timestamp: DateTime.now(),
      );

      await _repository.logActivity(activity);

      // Update analytics
      await _repository.incrementResourceView(userId, resourceType, subject);

      // Update streak
      await _repository.recordStudySession(userId);

      debugPrint('✅ Tracked view for $resourceTitle');
    } catch (e) {
      debugPrint('❌ trackView error: $e');
    }
  }

  /// Track download
  Future<void> trackDownload(
      String userId,
      String resourceId,
      String resourceTitle,
      String resourceType,
      String subject,
      ) async {
    try {
      final activity = UserActivityModel(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: ActivityType.download,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
        resourceType: resourceType,
        subject: subject,
        timestamp: DateTime.now(),
      );

      await _repository.logActivity(activity);
      await _repository.incrementDownload(userId, resourceType, subject);

      debugPrint('✅ Tracked download for $resourceTitle');
    } catch (e) {
      debugPrint('❌ trackDownload error: $e');
    }
  }

  /// Track bookmark
  Future<void> trackBookmark(
      String userId,
      String resourceId,
      String resourceTitle,
      String resourceType,
      String subject,
      ) async {
    try {
      final activity = UserActivityModel(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: ActivityType.bookmark,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
        resourceType: resourceType,
        subject: subject,
        timestamp: DateTime.now(),
      );

      await _repository.logActivity(activity);

      debugPrint('✅ Tracked bookmark for $resourceTitle');
    } catch (e) {
      debugPrint('❌ trackBookmark error: $e');
    }
  }

  /// Track study time
  Future<void> trackStudyTime(
      String userId,
      int minutes,
      String subject,
      ) async {
    try {
      await _repository.addStudyTime(userId, minutes, subject);
      await _repository.recordStudySession(userId);

      debugPrint('✅ Tracked $minutes minutes for $subject');
    } catch (e) {
      debugPrint('❌ trackStudyTime error: $e');
    }
  }

  /// Track search
  Future<void> trackSearch(
      String userId,
      String query,
      ) async {
    try {
      final activity = UserActivityModel(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: ActivityType.search,
        resourceId: 'search',
        resourceTitle: query,
        resourceType: 'search',
        subject: 'general',
        timestamp: DateTime.now(),
      );

      await _repository.logActivity(activity);

      debugPrint('✅ Tracked search: $query');
    } catch (e) {
      debugPrint('❌ trackSearch error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // REFRESH DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> refreshAll(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadRecentActivities(userId),
        _loadWeeklyChart(userId),
        _loadTopSubjects(userId),
      ]);

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Refreshed analytics data');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to refresh: $e';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GOALS & ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> updateWeeklyGoal(String userId, int minutes) async {
    try {
      if (_analytics == null) return;

      final updated = _analytics!.copyWith(
        weeklyGoalMinutes: minutes,
        updatedAt: DateTime.now(),
      );

      await _repository.updateAnalytics(updated);

      debugPrint('✅ Updated weekly goal to $minutes minutes');
    } catch (e) {
      debugPrint('❌ updateWeeklyGoal error: $e');
    }
  }

  bool get isWeeklyGoalAchieved {
    if (_analytics == null) return false;
    return _analytics!.weekStudyTimeMinutes >= _analytics!.weeklyGoalMinutes;
  }

  double get weeklyGoalProgress {
    if (_analytics == null) return 0;
    return _analytics!.weeklyGoalProgress;
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  String formatStudyTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  String getStreakMessage() {
    if (_streak == null || _streak!.currentStreak == 0) {
      return 'Start your streak today!';
    }
    return _streak!.streakStatus;
  }

  List<String> getRecommendations() {
    final recommendations = <String>[];

    if (_analytics == null) return recommendations;

    // Based on study time
    if (_analytics!.todayStudyTimeMinutes == 0) {
      recommendations.add('Start studying today to maintain your streak!');
    } else if (_analytics!.weekStudyTimeMinutes < 60) {
      recommendations.add('Try to study at least 1 hour this week');
    }

    // Based on subjects
    if (_topSubjects.isEmpty) {
      recommendations.add('Explore resources in different subjects');
    } else if (_topSubjects.length == 1) {
      recommendations.add('Branch out to other subjects for balanced learning');
    }

    // Based on streak
    if (_streak != null && _streak!.currentStreak >= 3) {
      recommendations.add('Great streak! Keep it going!');
    }

    return recommendations;
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ CLEANUP - IMPROVED
  // ═══════════════════════════════════════════════════════════════

  /// Cancel all active stream subscriptions
  Future<void> cancelStreams() async {
    try {
      // ✅ FIXED: Cancel streams immediately without await
      _analyticsSubscription?.cancel();
      _streakSubscription?.cancel();

      _analyticsSubscription = null;
      _streakSubscription = null;

      debugPrint('✅ Analytics streams cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling streams: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all data (call on logout)
  void reset() {
    _analytics = null;
    _streak = null;
    _recentActivities = [];
    _weeklyChart = {};
    _topSubjects = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelStreams();
    super.dispose();
  }
}