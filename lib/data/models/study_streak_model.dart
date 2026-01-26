import 'package:cloud_firestore/cloud_firestore.dart';

/// Study streak model for gamification
class StudyStreakModel {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final List<DateTime> streakDates;
  final int totalStudyDays;
  final Map<String, int> monthlyStreaks; // "2025-01" -> days
  final List<Achievement> unlockedAchievements;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyStreakModel({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    this.streakDates = const [],
    this.totalStudyDays = 0,
    this.monthlyStreaks = const {},
    this.unlockedAchievements = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  bool get isStreakActive {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastStudyDate!);
    return difference.inDays <= 1;
  }

  bool get studiedToday {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    return now.year == lastStudyDate!.year &&
        now.month == lastStudyDate!.month &&
        now.day == lastStudyDate!.day;
  }

  String get streakStatus {
    if (currentStreak == 0) return 'Start your streak!';
    if (currentStreak < 3) return 'Keep it up!';
    if (currentStreak < 7) return 'Great progress!';
    if (currentStreak < 14) return 'Amazing streak!';
    if (currentStreak < 30) return 'Incredible!';
    return 'Legendary!';
  }

  String get streakEmoji {
    if (currentStreak == 0) return '🌱';
    if (currentStreak < 3) return '🔥';
    if (currentStreak < 7) return '🔥🔥';
    if (currentStreak < 14) return '🔥🔥🔥';
    if (currentStreak < 30) return '⚡';
    return '👑';
  }

  int get daysUntilNextMilestone {
    const milestones = [3, 7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone - currentStreak;
      }
    }
    return 0;
  }

  String get nextMilestoneText {
    const milestones = [3, 7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return '$milestone days';
      }
    }
    return 'Legend';
  }

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE CONVERSION
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate':
      lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
      'streakDates': streakDates.map((d) => Timestamp.fromDate(d)).toList(),
      'totalStudyDays': totalStudyDays,
      'monthlyStreaks': monthlyStreaks,
      'unlockedAchievements':
      unlockedAchievements.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StudyStreakModel.fromMap(Map<String, dynamic> map) {
    return StudyStreakModel(
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastStudyDate: _parseDateTime(map['lastStudyDate']),
      streakDates: (map['streakDates'] as List?)
          ?.map((e) => _parseDateTime(e)!)
          .toList() ??
          [],
      totalStudyDays: map['totalStudyDays'] ?? 0,
      monthlyStreaks: Map<String, int>.from(map['monthlyStreaks'] ?? {}),
      unlockedAchievements: (map['unlockedAchievements'] as List?)
          ?.map((e) => Achievement.fromMap(e))
          .toList() ??
          [],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  factory StudyStreakModel.fromDocument(DocumentSnapshot doc) {
    return StudyStreakModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  StudyStreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    List<DateTime>? streakDates,
    int? totalStudyDays,
    Map<String, int>? monthlyStreaks,
    List<Achievement>? unlockedAchievements,
    DateTime? updatedAt,
  }) {
    return StudyStreakModel(
      userId: userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      streakDates: streakDates ?? this.streakDates,
      totalStudyDays: totalStudyDays ?? this.totalStudyDays,
      monthlyStreaks: monthlyStreaks ?? this.monthlyStreaks,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACHIEVEMENT MODEL
// ═══════════════════════════════════════════════════════════════

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '🏆',
      unlockedAt:
      (map['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PREDEFINED ACHIEVEMENTS
  // ═══════════════════════════════════════════════════════════════

  static Achievement firstDay() => Achievement(
    id: 'first_day',
    title: 'First Day',
    description: 'Started your learning journey',
    emoji: '🌱',
    unlockedAt: DateTime.now(),
  );

  static Achievement streak3Days() => Achievement(
    id: 'streak_3',
    title: '3 Day Streak',
    description: 'Studied for 3 consecutive days',
    emoji: '🔥',
    unlockedAt: DateTime.now(),
  );

  static Achievement streak7Days() => Achievement(
    id: 'streak_7',
    title: 'Week Warrior',
    description: 'Studied for 7 consecutive days',
    emoji: '⚡',
    unlockedAt: DateTime.now(),
  );

  static Achievement streak30Days() => Achievement(
    id: 'streak_30',
    title: 'Monthly Master',
    description: 'Studied for 30 consecutive days',
    emoji: '👑',
    unlockedAt: DateTime.now(),
  );

  static Achievement downloads50() => Achievement(
    id: 'downloads_50',
    title: 'Resource Hunter',
    description: 'Downloaded 50 resources',
    emoji: '📚',
    unlockedAt: DateTime.now(),
  );

  static Achievement studyTime10Hours() => Achievement(
    id: 'time_10h',
    title: 'Dedicated Learner',
    description: 'Studied for 10 hours total',
    emoji: '⏰',
    unlockedAt: DateTime.now(),
  );

  static Achievement perfectWeek() => Achievement(
    id: 'perfect_week',
    title: 'Perfect Week',
    description: 'Achieved weekly goal 4 weeks in a row',
    emoji: '💯',
    unlockedAt: DateTime.now(),
  );
}

// ═══════════════════════════════════════════════════════════════
// STREAK CALCULATOR HELPER
// ═══════════════════════════════════════════════════════════════

class StreakCalculator {
  static StudyStreakModel updateStreak(
      StudyStreakModel current,
      DateTime newDate,
      ) {
    final now = DateTime(newDate.year, newDate.month, newDate.day);

    // Check if already studied today
    if (current.lastStudyDate != null) {
      final last = DateTime(
        current.lastStudyDate!.year,
        current.lastStudyDate!.month,
        current.lastStudyDate!.day,
      );

      if (now.isAtSameMomentAs(last)) {
        // Already counted today
        return current;
      }
    }

    // Calculate new streak
    int newStreak = current.currentStreak;
    if (current.lastStudyDate == null) {
      newStreak = 1;
    } else {
      final daysDiff = now.difference(DateTime(
        current.lastStudyDate!.year,
        current.lastStudyDate!.month,
        current.lastStudyDate!.day,
      )).inDays;

      if (daysDiff == 1) {
        newStreak = current.currentStreak + 1;
      } else if (daysDiff > 1) {
        newStreak = 1; // Streak broken
      }
    }

    // Update monthly streaks
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthlyStreaks = Map<String, int>.from(current.monthlyStreaks);
    monthlyStreaks[monthKey] = (monthlyStreaks[monthKey] ?? 0) + 1;

    final newAchievements = List<Achievement>.from(current.unlockedAchievements);

    // Check for new achievements
    if (newStreak == 1 && current.currentStreak == 0) {
      newAchievements.add(Achievement.firstDay());
    } else if (newStreak == 3 &&
        !current.unlockedAchievements.any((a) => a.id == 'streak_3')) {
      newAchievements.add(Achievement.streak3Days());
    } else if (newStreak == 7 &&
        !current.unlockedAchievements.any((a) => a.id == 'streak_7')) {
      newAchievements.add(Achievement.streak7Days());
    } else if (newStreak == 30 &&
        !current.unlockedAchievements.any((a) => a.id == 'streak_30')) {
      newAchievements.add(Achievement.streak30Days());
    }

    return current.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > current.longestStreak
          ? newStreak
          : current.longestStreak,
      lastStudyDate: now,
      streakDates: [...current.streakDates, now],
      totalStudyDays: current.totalStudyDays + 1,
      monthlyStreaks: monthlyStreaks,
      unlockedAchievements: newAchievements,
      updatedAt: DateTime.now(),
    );
  }
}