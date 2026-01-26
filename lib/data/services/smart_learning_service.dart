import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/flashcard_model.dart';
import '../models/mind_map_model.dart';
import '../models/study_session_model.dart';
import '../models/pomodoro_session_model.dart';
import '../models/daily_goal_model.dart';
import '../models/study_plan_model.dart';

class SmartLearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String flashcardsCollection = 'flashcards';
  static const String mindMapsCollection = 'mindMaps';
  static const String studySessionsCollection = 'studySessions';
  static const String pomodoroSessionsCollection = 'pomodoroSessions';
  static const String dailyGoalsCollection = 'dailyGoals';
  static const String studyPlansCollection = 'studyPlans';

  // ═══════════════════════════════════════════════════════════════
  // FLASHCARDS OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<FlashcardModel>> getFlashcards(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(flashcardsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => FlashcardModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching flashcards: $e');
      return _getFlashcardsFromLocal();
    }
  }

  Future<void> saveFlashcard(FlashcardModel flashcard) async {
    try {
      await _firestore
          .collection(flashcardsCollection)
          .doc(flashcard.id)
          .set(flashcard.toFirestore());

      await _saveFlashcardToLocal(flashcard);
    } catch (e) {
      print('Error saving flashcard: $e');
      await _saveFlashcardToLocal(flashcard);
    }
  }

  Future<void> updateFlashcard(FlashcardModel flashcard) async {
    try {
      await _firestore
          .collection(flashcardsCollection)
          .doc(flashcard.id)
          .update(flashcard.toFirestore());

      await _saveFlashcardToLocal(flashcard);
    } catch (e) {
      print('Error updating flashcard: $e');
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _firestore.collection(flashcardsCollection).doc(flashcardId).delete();

      final box = await Hive.openBox('flashcards');
      await box.delete(flashcardId);
    } catch (e) {
      print('Error deleting flashcard: $e');
    }
  }

  Future<List<FlashcardModel>> generateFlashcardsFromText(String text, String subject) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 4000,
          'messages': [
            {
              'role': 'user',
              'content': '''Generate 10 high-quality flashcards from this text about $subject:

$text

Format each flashcard as JSON:
{
  "question": "Clear, concise question",
  "answer": "Detailed answer",
  "topic": "Specific topic",
  "difficulty": 1-5
}

Return ONLY a JSON array of flashcards, no other text.'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        final flashcardsJson = jsonDecode(content) as List;

        return flashcardsJson.map((json) {
          final now = DateTime.now();
          return FlashcardModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + flashcardsJson.indexOf(json).toString(),
            userId: '',
            question: json['question'],
            answer: json['answer'],
            topic: json['topic'],
            subject: subject,
            difficultyLevel: json['difficulty'] ?? 3,
            createdAt: now,
            lastReviewedAt: now,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error generating flashcards: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MIND MAPS OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<MindMapModel>> getMindMaps(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(mindMapsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => MindMapModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching mind maps: $e');
      return _getMindMapsFromLocal();
    }
  }

  Future<void> saveMindMap(MindMapModel mindMap) async {
    try {
      await _firestore
          .collection(mindMapsCollection)
          .doc(mindMap.id)
          .set(mindMap.toFirestore());

      await _saveMindMapToLocal(mindMap);
    } catch (e) {
      print('Error saving mind map: $e');
    }
  }

  Future<MindMapModel> generateMindMap(String topic, String subject) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 4000,
          'messages': [
            {
              'role': 'user',
              'content': '''Create a hierarchical mind map for: $topic (Subject: $subject)

Format as JSON with this structure:
{
  "title": "$topic",
  "nodes": [
    {
      "id": "1",
      "text": "Main concept",
      "level": 0,
      "parentId": null,
      "childrenIds": ["1.1", "1.2"],
      "color": "#6366F1"
    }
  ]
}

Create 3 levels: Main topic → Subtopics → Key points. Return ONLY JSON.'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        final mindMapJson = jsonDecode(content);

        final now = DateTime.now();
        return MindMapModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: '',
          title: mindMapJson['title'],
          topic: topic,
          subject: subject,
          nodes: (mindMapJson['nodes'] as List).map((n) => MindMapNodeModel.fromMap(n)).toList(),
          createdAt: now,
          updatedAt: now,
        );
      }
      throw Exception('Failed to generate mind map');
    } catch (e) {
      print('Error generating mind map: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY SESSIONS OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<StudySessionModel>> getStudySessions(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection(studySessionsCollection)
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.orderBy('startTime', descending: true).get();
      return snapshot.docs.map((doc) => StudySessionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching study sessions: $e');
      return [];
    }
  }

  Future<void> saveStudySession(StudySessionModel session) async {
    try {
      await _firestore
          .collection(studySessionsCollection)
          .doc(session.id)
          .set(session.toFirestore());

      final box = await Hive.openBox('studySessions');
      await box.put(session.id, session.toMap());
    } catch (e) {
      print('Error saving study session: $e');
    }
  }

  Future<void> updateStudySession(StudySessionModel session) async {
    try {
      await _firestore
          .collection(studySessionsCollection)
          .doc(session.id)
          .update(session.toFirestore());
    } catch (e) {
      print('Error updating study session: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // POMODORO OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<PomodoroSessionModel>> getPomodoroSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(pomodoroSessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => PomodoroSessionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching pomodoro sessions: $e');
      return [];
    }
  }

  Future<void> savePomodoroSession(PomodoroSessionModel session) async {
    try {
      await _firestore
          .collection(pomodoroSessionsCollection)
          .doc(session.id)
          .set(session.toFirestore());

      final box = await Hive.openBox('pomodoroSessions');
      await box.put(session.id, session.toMap());
    } catch (e) {
      print('Error saving pomodoro session: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DAILY GOALS OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<DailyGoalModel>> getDailyGoals(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(dailyGoalsCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) => DailyGoalModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching daily goals: $e');
      return [];
    }
  }

  Future<void> saveDailyGoal(DailyGoalModel goal) async {
    try {
      await _firestore
          .collection(dailyGoalsCollection)
          .doc(goal.id)
          .set(goal.toFirestore());

      final box = await Hive.openBox('dailyGoals');
      await box.put(goal.id, goal.toMap());
    } catch (e) {
      print('Error saving daily goal: $e');
    }
  }

  Future<void> updateDailyGoal(DailyGoalModel goal) async {
    try {
      await _firestore
          .collection(dailyGoalsCollection)
          .doc(goal.id)
          .update(goal.toFirestore());
    } catch (e) {
      print('Error updating daily goal: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY PLANS OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<StudyPlanModel>> getStudyPlans(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(studyPlansCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => StudyPlanModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching study plans: $e');
      return [];
    }
  }

  Future<void> saveStudyPlan(StudyPlanModel plan) async {
    try {
      await _firestore
          .collection(studyPlansCollection)
          .doc(plan.id)
          .set(plan.toFirestore());

      final box = await Hive.openBox('studyPlans');
      await box.put(plan.id, plan.toMap());
    } catch (e) {
      print('Error saving study plan: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOCAL STORAGE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Future<List<FlashcardModel>> _getFlashcardsFromLocal() async {
    try {
      final box = await Hive.openBox('flashcards');
      return box.values.map((v) => FlashcardModel.fromMap(v)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveFlashcardToLocal(FlashcardModel flashcard) async {
    try {
      final box = await Hive.openBox('flashcards');
      await box.put(flashcard.id, flashcard.toMap());
    } catch (e) {
      print('Error saving to local: $e');
    }
  }

  Future<List<MindMapModel>> _getMindMapsFromLocal() async {
    try {
      final box = await Hive.openBox('mindMaps');
      return box.values.map((v) => MindMapModel.fromMap(v)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveMindMapToLocal(MindMapModel mindMap) async {
    try {
      final box = await Hive.openBox('mindMaps');
      await box.put(mindMap.id, mindMap.toMap());
    } catch (e) {
      print('Error saving to local: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYTICS
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStudyAnalytics(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final sessions = await getStudySessions(userId, startDate: startDate, endDate: endDate);

      final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final avgFocusScore = sessions.isEmpty ? 0.0 : sessions.fold<int>(0, (sum, s) => sum + s.focusScore) / sessions.length;

      final subjectBreakdown = <String, int>{};
      for (var session in sessions) {
        subjectBreakdown[session.subject] = (subjectBreakdown[session.subject] ?? 0) + session.durationMinutes;
      }

      return {
        'totalSessions': sessions.length,
        'totalMinutes': totalMinutes,
        'averageFocusScore': avgFocusScore,
        'subjectBreakdown': subjectBreakdown,
        'completedSessions': sessions.where((s) => s.isCompleted).length,
      };
    } catch (e) {
      print('Error getting analytics: $e');
      return {};
    }
  }
}