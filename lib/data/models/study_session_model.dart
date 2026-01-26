import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionModel {
  final String id;
  final String userId;
  final String subject;
  final String? topic;
  final String? resourceId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int breaksTaken;
  final int focusScore; // 0-100
  final bool isCompleted;
  final Map<String, dynamic>? notes;
  final List<String> tags;

  StudySessionModel({
    required this.id,
    required this.userId,
    required this.subject,
    this.topic,
    this.resourceId,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.breaksTaken = 0,
    this.focusScore = 100,
    this.isCompleted = false,
    this.notes,
    this.tags = const [],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'topic': topic,
      'resourceId': resourceId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'breaksTaken': breaksTaken,
      'focusScore': focusScore,
      'isCompleted': isCompleted,
      'notes': notes,
      'tags': tags,
    };
  }

  factory StudySessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySessionModel.fromMap(data);
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subject: map['subject'] ?? '',
      topic: map['topic'],
      resourceId: map['resourceId'],
      startTime: _parseDateTime(map['startTime']) ?? DateTime.now(),
      endTime: _parseDateTime(map['endTime']),
      durationMinutes: map['durationMinutes'] ?? 0,
      breaksTaken: map['breaksTaken'] ?? 0,
      focusScore: map['focusScore'] ?? 100,
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'topic': topic,
      'resourceId': resourceId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'breaksTaken': breaksTaken,
      'focusScore': focusScore,
      'isCompleted': isCompleted,
      'notes': notes,
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

  StudySessionModel copyWith({
    DateTime? endTime,
    int? durationMinutes,
    int? breaksTaken,
    int? focusScore,
    bool? isCompleted,
    Map<String, dynamic>? notes,
  }) {
    return StudySessionModel(
      id: id,
      userId: userId,
      subject: subject,
      topic: topic,
      resourceId: resourceId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      breaksTaken: breaksTaken ?? this.breaksTaken,
      focusScore: focusScore ?? this.focusScore,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      tags: tags,
    );
  }
}