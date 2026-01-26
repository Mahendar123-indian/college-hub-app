import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPlanItemModel {
  final String id;
  final String topic;
  final String subject;
  final DateTime scheduledDate;
  final int durationMinutes;
  final bool isCompleted;
  final int priority;

  StudyPlanItemModel({
    required this.id,
    required this.topic,
    required this.subject,
    required this.scheduledDate,
    required this.durationMinutes,
    this.isCompleted = false,
    this.priority = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'subject': subject,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }

  factory StudyPlanItemModel.fromMap(Map<String, dynamic> map) {
    return StudyPlanItemModel(
      id: map['id'] ?? '',
      topic: map['topic'] ?? '',
      subject: map['subject'] ?? '',
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(map['scheduledDate'] ?? 0),
      durationMinutes: map['durationMinutes'] ?? 60,
      isCompleted: map['isCompleted'] ?? false,
      priority: map['priority'] ?? 2,
    );
  }
}

class StudyPlanModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final List<StudyPlanItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  StudyPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory StudyPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyPlanModel.fromMap(data);
  }

  factory StudyPlanModel.fromMap(Map<String, dynamic> map) {
    return StudyPlanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      startDate: _parseDateTime(map['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(map['endDate']) ?? DateTime.now(),
      items: (map['items'] as List<dynamic>?)?.map((i) => StudyPlanItemModel.fromMap(i)).toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  double get completionPercentage {
    if (items.isEmpty) return 0.0;
    final completed = items.where((i) => i.isCompleted).length;
    return (completed / items.length * 100);
  }

  StudyPlanModel copyWith({
    List<StudyPlanItemModel>? items,
    bool? isActive,
  }) {
    return StudyPlanModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      metadata: metadata,
    );
  }
}