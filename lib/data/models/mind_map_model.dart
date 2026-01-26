import 'package:cloud_firestore/cloud_firestore.dart';

class MindMapNodeModel {
  final String id;
  final String text;
  final int level;
  final String? parentId;
  final List<String> childrenIds;
  final String color;
  final bool isExpanded;

  MindMapNodeModel({
    required this.id,
    required this.text,
    required this.level,
    this.parentId,
    this.childrenIds = const [],
    this.color = '#6366F1',
    this.isExpanded = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'level': level,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'color': color,
      'isExpanded': isExpanded,
    };
  }

  factory MindMapNodeModel.fromMap(Map<String, dynamic> map) {
    return MindMapNodeModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      level: map['level'] ?? 0,
      parentId: map['parentId'],
      childrenIds: List<String>.from(map['childrenIds'] ?? []),
      color: map['color'] ?? '#6366F1',
      isExpanded: map['isExpanded'] ?? true,
    );
  }
}

class MindMapModel {
  final String id;
  final String userId;
  final String title;
  final String? topic;
  final String? subject;
  final String? resourceId;
  final List<MindMapNodeModel> nodes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  MindMapModel({
    required this.id,
    required this.userId,
    required this.title,
    this.topic,
    this.subject,
    this.resourceId,
    this.nodes = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.tags = const [],
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'topic': topic,
      'subject': subject,
      'resourceId': resourceId,
      'nodes': nodes.map((n) => n.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory MindMapModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MindMapModel.fromMap(data);
  }

  factory MindMapModel.fromMap(Map<String, dynamic> map) {
    return MindMapModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      topic: map['topic'],
      subject: map['subject'],
      resourceId: map['resourceId'],
      nodes: (map['nodes'] as List<dynamic>?)?.map((n) => MindMapNodeModel.fromMap(n)).toList() ?? [],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isFavorite: map['isFavorite'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'topic': topic,
      'subject': subject,
      'resourceId': resourceId,
      'nodes': nodes.map((n) => n.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'tags': tags,
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

  MindMapModel copyWith({
    String? title,
    List<MindMapNodeModel>? nodes,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return MindMapModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      topic: topic,
      subject: subject,
      resourceId: resourceId,
      nodes: nodes ?? this.nodes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      metadata: metadata,
    );
  }
}