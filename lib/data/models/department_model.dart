import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String? code; // ✅ ADDED
  final String? description;
  final String collegeId;
  final List<String> subjects;
  final int totalSemesters;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  DepartmentModel({
    required this.id,
    required this.name,
    this.code, // ✅ ADDED
    this.description,
    required this.collegeId,
    this.subjects = const [],
    this.totalSemesters = 8,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code, // ✅ ADDED
      'description': description,
      'collegeId': collegeId,
      'subjects': subjects,
      'totalSemesters': totalSemesters,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'], // ✅ ADDED
      description: map['description'],
      collegeId: map['collegeId'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      totalSemesters: map['totalSemesters'] ?? 8,

      // ✅ FIXED: Check for null before casting to Timestamp
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to current time if missing

      // ✅ FIXED: Check for null before casting to Timestamp
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to current time if missing

      isActive: map['isActive'] ?? true,
    );
  }

  factory DepartmentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // We add the document ID to the data map so it's included in the model
    data['id'] = doc.id;
    return DepartmentModel.fromMap(data);
  }

  DepartmentModel copyWith({
    String? id,
    String? name,
    String? code, // ✅ ADDED
    String? description,
    String? collegeId,
    List<String>? subjects,
    int? totalSemesters,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code, // ✅ ADDED
      description: description ?? this.description,
      collegeId: collegeId ?? this.collegeId,
      subjects: subjects ?? this.subjects,
      totalSemesters: totalSemesters ?? this.totalSemesters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}