import 'package:cloud_firestore/cloud_firestore.dart';

class DailyGoalModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category; // study, exercise, reading, etc.
  final int targetMinutes;
  final int completedMinutes;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority; // 1-3 (1=high, 3=low)
  final List<String> tags;

  DailyGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.targetMinutes,
    this.completedMinutes = 0,
    required this.date,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.priority = 2,
    this.tags = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'targetMinutes': targetMinutes,
      'completedMinutes': completedMinutes,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'priority': priority,
      'tags': tags,
    };
  }

  factory DailyGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyGoalModel.fromMap(data);
  }

  factory DailyGoalModel.fromMap(Map<String, dynamic> map) {
    return DailyGoalModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'study',
      targetMinutes: map['targetMinutes'] ?? 60,
      completedMinutes: map['completedMinutes'] ?? 0,
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      priority: map['priority'] ?? 2,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'targetMinutes': targetMinutes,
      'completedMinutes': completedMinutes,
      'date': date.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'priority': priority,
      'tags': tags,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  double get progressPercentage {
    if (targetMinutes == 0) return 0.0;
    return (completedMinutes / targetMinutes * 100).clamp(0.0, 100.0);
  }

  DailyGoalModel copyWith({
    int? completedMinutes,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyGoalModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      targetMinutes: targetMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority,
      tags: tags,
    );
  }
}