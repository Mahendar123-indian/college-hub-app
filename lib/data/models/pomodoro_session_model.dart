import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroSessionModel {
  final String id;
  final String userId;
  final String? subject;
  final String? task;
  final DateTime startTime;
  final DateTime? endTime;
  final int workDuration; // minutes (default 25)
  final int breakDuration; // minutes (default 5)
  final int cyclesCompleted;
  final int totalCycles; // usually 4
  final bool isActive;
  final bool isBreak;
  final bool isCompleted;
  final int distractionCount;

  PomodoroSessionModel({
    required this.id,
    required this.userId,
    this.subject,
    this.task,
    required this.startTime,
    this.endTime,
    this.workDuration = 25,
    this.breakDuration = 5,
    this.cyclesCompleted = 0,
    this.totalCycles = 4,
    this.isActive = true,
    this.isBreak = false,
    this.isCompleted = false,
    this.distractionCount = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'task': task,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'cyclesCompleted': cyclesCompleted,
      'totalCycles': totalCycles,
      'isActive': isActive,
      'isBreak': isBreak,
      'isCompleted': isCompleted,
      'distractionCount': distractionCount,
    };
  }

  factory PomodoroSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PomodoroSessionModel.fromMap(data);
  }

  factory PomodoroSessionModel.fromMap(Map<String, dynamic> map) {
    return PomodoroSessionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subject: map['subject'],
      task: map['task'],
      startTime: _parseDateTime(map['startTime']) ?? DateTime.now(),
      endTime: _parseDateTime(map['endTime']),
      workDuration: map['workDuration'] ?? 25,
      breakDuration: map['breakDuration'] ?? 5,
      cyclesCompleted: map['cyclesCompleted'] ?? 0,
      totalCycles: map['totalCycles'] ?? 4,
      isActive: map['isActive'] ?? true,
      isBreak: map['isBreak'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      distractionCount: map['distractionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'task': task,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'cyclesCompleted': cyclesCompleted,
      'totalCycles': totalCycles,
      'isActive': isActive,
      'isBreak': isBreak,
      'isCompleted': isCompleted,
      'distractionCount': distractionCount,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  PomodoroSessionModel copyWith({
    DateTime? endTime,
    int? cyclesCompleted,
    bool? isActive,
    bool? isBreak,
    bool? isCompleted,
    int? distractionCount,
  }) {
    return PomodoroSessionModel(
      id: id,
      userId: userId,
      subject: subject,
      task: task,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      workDuration: workDuration,
      breakDuration: breakDuration,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      totalCycles: totalCycles,
      isActive: isActive ?? this.isActive,
      isBreak: isBreak ?? this.isBreak,
      isCompleted: isCompleted ?? this.isCompleted,
      distractionCount: distractionCount ?? this.distractionCount,
    );
  }
}