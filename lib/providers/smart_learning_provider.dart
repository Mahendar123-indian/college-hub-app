import 'package:flutter/material.dart';
import '../data/models/flashcard_model.dart';
import '../data/models/mind_map_model.dart';
import '../data/models/study_session_model.dart';
import '../data/models/pomodoro_session_model.dart';
import '../data/models/daily_goal_model.dart';
import '../data/models/study_plan_model.dart';
import '../data/services/smart_learning_service.dart';

class SmartLearningProvider with ChangeNotifier {
  final SmartLearningService _service = SmartLearningService();

  String? _userId;
  bool _isLoading = false;
  String? _error;

  // Flashcards
  List<FlashcardModel> _flashcards = [];
  FlashcardModel? _currentFlashcard;

  // Mind Maps
  List<MindMapModel> _mindMaps = [];
  MindMapModel? _currentMindMap;

  // Study Sessions
  List<StudySessionModel> _studySessions = [];
  StudySessionModel? _activeSession;

  // Pomodoro
  List<PomodoroSessionModel> _pomodoroSessions = [];
  PomodoroSessionModel? _activePomodoroSession;

  // Daily Goals
  List<DailyGoalModel> _dailyGoals = [];

  // Study Plans
  List<StudyPlanModel> _studyPlans = [];
  StudyPlanModel? _activeStudyPlan;

  // Analytics
  Map<String, dynamic>? _analytics;
  int _currentStreak = 0;
  int _totalStudyMinutes = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FlashcardModel> get flashcards => _flashcards;
  FlashcardModel? get currentFlashcard => _currentFlashcard;
  List<MindMapModel> get mindMaps => _mindMaps;
  MindMapModel? get currentMindMap => _currentMindMap;
  List<StudySessionModel> get studySessions => _studySessions;
  StudySessionModel? get activeSession => _activeSession;
  List<PomodoroSessionModel> get pomodoroSessions => _pomodoroSessions;
  PomodoroSessionModel? get activePomodoroSession => _activePomodoroSession;
  List<DailyGoalModel> get dailyGoals => _dailyGoals;
  List<StudyPlanModel> get studyPlans => _studyPlans;
  StudyPlanModel? get activeStudyPlan => _activeStudyPlan;
  Map<String, dynamic>? get analytics => _analytics;
  int get currentStreak => _currentStreak;
  int get totalStudyMinutes => _totalStudyMinutes;

  // Filtered getters
  List<FlashcardModel> get dueFlashcards => _flashcards.where((f) => f.needsReview).toList();
  List<FlashcardModel> get favoriteFlashcards => _flashcards.where((f) => f.isFavorite).toList();
  List<DailyGoalModel> get todayGoals => _dailyGoals.where((g) => _isSameDay(g.date, DateTime.now())).toList();
  List<DailyGoalModel> get completedGoals => _dailyGoals.where((g) => g.isCompleted).toList();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadAllData();
  }

  Future<void> loadAllData() async {
    if (_userId == null) return;

    _setLoading(true);
    try {
      await Future.wait([
        loadFlashcards(),
        loadMindMaps(),
        loadStudySessions(),
        loadPomodoroSessions(),
        loadDailyGoals(),
        loadStudyPlans(),
        calculateStreak(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Failed to load data: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FLASHCARDS
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadFlashcards() async {
    if (_userId == null) return;
    try {
      _flashcards = await _service.getFlashcards(_userId!);
      notifyListeners();
    } catch (e) {
      print('Error loading flashcards: $e');
    }
  }

  Future<void> addFlashcard(FlashcardModel flashcard) async {
    try {
      final newFlashcard = flashcard.copyWith(userId: _userId);
      await _service.saveFlashcard(newFlashcard);
      _flashcards.insert(0, newFlashcard);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add flashcard';
      notifyListeners();
    }
  }

  Future<void> updateFlashcard(FlashcardModel flashcard) async {
    try {
      await _service.updateFlashcard(flashcard);
      final index = _flashcards.indexWhere((f) => f.id == flashcard.id);
      if (index != -1) {
        _flashcards[index] = flashcard;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update flashcard';
      notifyListeners();
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _service.deleteFlashcard(flashcardId);
      _flashcards.removeWhere((f) => f.id == flashcardId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete flashcard';
      notifyListeners();
    }
  }

  Future<void> reviewFlashcard(FlashcardModel flashcard, bool answeredCorrectly) async {
    try {
      final updatedFlashcard = flashcard.copyWithReview(answeredCorrectly: answeredCorrectly);
      await updateFlashcard(updatedFlashcard);
    } catch (e) {
      _error = 'Failed to review flashcard';
      notifyListeners();
    }
  }

  Future<void> generateFlashcardsFromText(String text, String subject) async {
    _setLoading(true);
    try {
      final generated = await _service.generateFlashcardsFromText(text, subject);
      for (var flashcard in generated) {
        await addFlashcard(flashcard.copyWith(userId: _userId));
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to generate flashcards';
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentFlashcard(FlashcardModel? flashcard) {
    _currentFlashcard = flashcard;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // MIND MAPS
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadMindMaps() async {
    if (_userId == null) return;
    try {
      _mindMaps = await _service.getMindMaps(_userId!);
      notifyListeners();
    } catch (e) {
      print('Error loading mind maps: $e');
    }
  }

  Future<void> addMindMap(MindMapModel mindMap) async {
    try {
      final newMindMap = mindMap.copyWith();
      await _service.saveMindMap(newMindMap);
      _mindMaps.insert(0, newMindMap);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add mind map';
      notifyListeners();
    }
  }

  Future<void> generateMindMap(String topic, String subject) async {
    _setLoading(true);
    try {
      final mindMap = await _service.generateMindMap(topic, subject);
      final userMindMap = MindMapModel(
        id: mindMap.id,
        userId: _userId!,
        title: mindMap.title,
        topic: topic,
        subject: subject,
        nodes: mindMap.nodes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await addMindMap(userMindMap);
      _currentMindMap = userMindMap;
      _error = null;
    } catch (e) {
      _error = 'Failed to generate mind map';
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentMindMap(MindMapModel? mindMap) {
    _currentMindMap = mindMap;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY SESSIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadStudySessions() async {
    if (_userId == null) return;
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      _studySessions = await _service.getStudySessions(_userId!, startDate: startDate);
      _totalStudyMinutes = _studySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      notifyListeners();
    } catch (e) {
      print('Error loading study sessions: $e');
    }
  }

  Future<void> startStudySession(String subject, {String? topic, String? resourceId}) async {
    try {
      final now = DateTime.now();
      final session = StudySessionModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: _userId!,
        subject: subject,
        topic: topic,
        resourceId: resourceId,
        startTime: now,
        tags: [],
      );

      await _service.saveStudySession(session);
      _activeSession = session;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start session';
      notifyListeners();
    }
  }

  Future<void> endStudySession({int? focusScore, Map<String, dynamic>? notes}) async {
    if (_activeSession == null) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_activeSession!.startTime).inMinutes;

      final updatedSession = _activeSession!.copyWith(
        endTime: endTime,
        durationMinutes: duration,
        focusScore: focusScore ?? 100,
        isCompleted: true,
        notes: notes,
      );

      await _service.updateStudySession(updatedSession);
      _studySessions.insert(0, updatedSession);
      _totalStudyMinutes += duration;
      _activeSession = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end session';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // POMODORO
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadPomodoroSessions() async {
    if (_userId == null) return;
    try {
      _pomodoroSessions = await _service.getPomodoroSessions(_userId!);
      notifyListeners();
    } catch (e) {
      print('Error loading pomodoro sessions: $e');
    }
  }

  Future<void> startPomodoroSession({String? subject, String? task}) async {
    try {
      final now = DateTime.now();
      final session = PomodoroSessionModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: _userId!,
        subject: subject,
        task: task,
        startTime: now,
      );

      await _service.savePomodoroSession(session);
      _activePomodoroSession = session;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start pomodoro';
      notifyListeners();
    }
  }

  Future<void> completePomodoroSession() async {
    if (_activePomodoroSession == null) return;

    try {
      final updatedSession = _activePomodoroSession!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
      );

      await _service.savePomodoroSession(updatedSession);
      _pomodoroSessions.insert(0, updatedSession);
      _activePomodoroSession = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete pomodoro';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY GOALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadDailyGoals() async {
    if (_userId == null) return;
    try {
      _dailyGoals = await _service.getDailyGoals(_userId!, DateTime.now());
      notifyListeners();
    } catch (e) {
      print('Error loading daily goals: $e');
    }
  }

  Future<void> addDailyGoal(DailyGoalModel goal) async {
    try {
      await _service.saveDailyGoal(goal);
      _dailyGoals.add(goal);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add goal';
      notifyListeners();
    }
  }

  Future<void> updateGoalProgress(String goalId, int minutes) async {
    try {
      final goal = _dailyGoals.firstWhere((g) => g.id == goalId);
      final newMinutes = goal.completedMinutes + minutes;
      final isCompleted = newMinutes >= goal.targetMinutes;

      final updatedGoal = goal.copyWith(
        completedMinutes: newMinutes,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );

      await _service.updateDailyGoal(updatedGoal);

      final index = _dailyGoals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _dailyGoals[index] = updatedGoal;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update goal';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY PLANS
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadStudyPlans() async {
    if (_userId == null) return;
    try {
      _studyPlans = await _service.getStudyPlans(_userId!);
      _activeStudyPlan = _studyPlans.isNotEmpty ? _studyPlans.first : null;
      notifyListeners();
    } catch (e) {
      print('Error loading study plans: $e');
    }
  }

  Future<void> addStudyPlan(StudyPlanModel plan) async {
    try {
      await _service.saveStudyPlan(plan);
      _studyPlans.insert(0, plan);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add study plan';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS & STREAK
  // ═══════════════════════════════════════════════════════════════

  Future<void> calculateStreak() async {
    if (_userId == null) return;

    try {
      final sessions = _studySessions;
      if (sessions.isEmpty) {
        _currentStreak = 0;
        return;
      }

      int streak = 0;
      DateTime currentDate = DateTime.now();

      while (true) {
        final hasSession = sessions.any((s) => _isSameDay(s.startTime, currentDate));
        if (hasSession) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      _currentStreak = streak;
      notifyListeners();
    } catch (e) {
      print('Error calculating streak: $e');
    }
  }

  Future<void> loadAnalytics({DateTime? startDate, DateTime? endDate}) async {
    if (_userId == null) return;

    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      _analytics = await _service.getStudyAnalytics(_userId!, start, end);
      notifyListeners();
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }
}