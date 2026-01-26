import 'package:cloud_firestore/cloud_firestore.dart';

/// Flashcard Model with Firebase Integration
/// Supports spaced repetition, difficulty tracking, and performance analytics
class FlashcardModel {
  final String id;
  final String userId;
  final String question;
  final String answer;
  final String? topic;
  final String? subject;
  final String? resourceId;
  final List<String> tags;
  final int difficultyLevel; // 1-5 (1=easiest, 5=hardest)
  final int reviewCount;
  final int correctCount;
  final int incorrectCount;
  final DateTime createdAt;
  final DateTime lastReviewedAt;
  final DateTime? nextReviewDate;
  final double masteryScore; // 0.0-1.0
  final bool isArchived;
  final bool isFavorite;
  final Map<String, dynamic>? metadata;

  FlashcardModel({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    this.topic,
    this.subject,
    this.resourceId,
    this.tags = const [],
    this.difficultyLevel = 3,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    required this.createdAt,
    required this.lastReviewedAt,
    this.nextReviewDate,
    this.masteryScore = 0.0,
    this.isArchived = false,
    this.isFavorite = false,
    this.metadata,
  });

  // ═══════════════════════════════════════════════════════════════
  // FIREBASE CONVERSION
  // ═══════════════════════════════════════════════════════════════

  /// Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'answer': answer,
      'topic': topic,
      'subject': subject,
      'resourceId': resourceId,
      'tags': tags,
      'difficultyLevel': difficultyLevel,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReviewedAt': Timestamp.fromDate(lastReviewedAt),
      'nextReviewDate': nextReviewDate != null ? Timestamp.fromDate(nextReviewDate!) : null,
      'masteryScore': masteryScore,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'metadata': metadata,
    };
  }

  /// Create from Firestore DocumentSnapshot
  factory FlashcardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashcardModel.fromMap(data);
  }

  /// Create from Map
  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      topic: map['topic'],
      subject: map['subject'],
      resourceId: map['resourceId'],
      tags: List<String>.from(map['tags'] ?? []),
      difficultyLevel: map['difficultyLevel'] ?? 3,
      reviewCount: map['reviewCount'] ?? 0,
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastReviewedAt: _parseDateTime(map['lastReviewedAt']) ?? DateTime.now(),
      nextReviewDate: _parseDateTime(map['nextReviewDate']),
      masteryScore: (map['masteryScore'] ?? 0.0).toDouble(),
      isArchived: map['isArchived'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      metadata: map['metadata'],
    );
  }

  /// Convert to Hive Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'answer': answer,
      'topic': topic,
      'subject': subject,
      'resourceId': resourceId,
      'tags': tags,
      'difficultyLevel': difficultyLevel,
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastReviewedAt': lastReviewedAt.millisecondsSinceEpoch,
      'nextReviewDate': nextReviewDate?.millisecondsSinceEpoch,
      'masteryScore': masteryScore,
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'metadata': metadata,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Calculate accuracy percentage
  double get accuracy {
    if (reviewCount == 0) return 0.0;
    return (correctCount / reviewCount) * 100;
  }

  /// Check if card needs review (spaced repetition)
  bool get needsReview {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!);
  }

  /// Get difficulty label
  String get difficultyLabel {
    switch (difficultyLevel) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Very Hard';
      default:
        return 'Medium';
    }
  }

  /// Calculate next review date based on spaced repetition algorithm
  DateTime calculateNextReview(bool answeredCorrectly) {
    // Spaced repetition intervals (in days)
    final intervals = [1, 3, 7, 14, 30, 60, 120];

    int intervalIndex = reviewCount.clamp(0, intervals.length - 1);

    if (!answeredCorrectly) {
      // Reset to first interval if answered incorrectly
      intervalIndex = 0;
    }

    return DateTime.now().add(Duration(days: intervals[intervalIndex]));
  }

  /// Update after review
  FlashcardModel copyWithReview({
    required bool answeredCorrectly,
    int? newDifficulty,
  }) {
    final newCorrectCount = correctCount + (answeredCorrectly ? 1 : 0);
    final newIncorrectCount = incorrectCount + (!answeredCorrectly ? 1 : 0);
    final newReviewCount = reviewCount + 1;
    final newMasteryScore = newReviewCount > 0
        ? (newCorrectCount / newReviewCount)
        : 0.0;

    return FlashcardModel(
      id: id,
      userId: userId,
      question: question,
      answer: answer,
      topic: topic,
      subject: subject,
      resourceId: resourceId,
      tags: tags,
      difficultyLevel: newDifficulty ?? difficultyLevel,
      reviewCount: newReviewCount,
      correctCount: newCorrectCount,
      incorrectCount: newIncorrectCount,
      createdAt: createdAt,
      lastReviewedAt: DateTime.now(),
      nextReviewDate: calculateNextReview(answeredCorrectly),
      masteryScore: newMasteryScore,
      isArchived: isArchived,
      isFavorite: isFavorite,
      metadata: metadata,
    );
  }

  /// CopyWith method
  FlashcardModel copyWith({
    String? id,
    String? userId,
    String? question,
    String? answer,
    String? topic,
    String? subject,
    String? resourceId,
    List<String>? tags,
    int? difficultyLevel,
    int? reviewCount,
    int? correctCount,
    int? incorrectCount,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    double? masteryScore,
    bool? isArchived,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      resourceId: resourceId ?? this.resourceId,
      tags: tags ?? this.tags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      masteryScore: masteryScore ?? this.masteryScore,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'FlashcardModel(id: $id, question: $question, mastery: ${(masteryScore * 100).toStringAsFixed(1)}%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FlashcardModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}