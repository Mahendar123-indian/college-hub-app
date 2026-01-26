import 'package:cloud_firestore/cloud_firestore.dart';
import 'youtube_video_model.dart';

class YouTubePlaylistModel {
  final String id;
  final String playlistId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final int videoCount;
  final String channelName;
  final String channelId;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related to resource
  final String? resourceId;
  final String? subject;
  final String? topic;
  final String? unit;

  YouTubePlaylistModel({
    required this.id,
    required this.playlistId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoCount,
    required this.channelName,
    required this.channelId,
    required this.videoIds,
    required this.createdAt,
    required this.updatedAt,
    this.resourceId,
    this.subject,
    this.topic,
    this.unit,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'playlistId': playlistId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoCount': videoCount,
      'channelName': channelName,
      'channelId': channelId,
      'videoIds': videoIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resourceId': resourceId,
      'subject': subject,
      'topic': topic,
      'unit': unit,
    };
  }

  // Convert to Map (with milliseconds)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlistId': playlistId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoCount': videoCount,
      'channelName': channelName,
      'channelId': channelId,
      'videoIds': videoIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'resourceId': resourceId,
      'subject': subject,
      'topic': topic,
      'unit': unit,
    };
  }

  // Create from Map
  factory YouTubePlaylistModel.fromMap(Map<String, dynamic> map) {
    return YouTubePlaylistModel(
      id: map['id'] ?? '',
      playlistId: map['playlistId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      videoCount: map['videoCount'] ?? 0,
      channelName: map['channelName'] ?? '',
      channelId: map['channelId'] ?? '',
      videoIds: List<String>.from(map['videoIds'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      resourceId: map['resourceId'],
      subject: map['subject'],
      topic: map['topic'],
      unit: map['unit'],
    );
  }

  // Helper to parse DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // Create from Firestore DocumentSnapshot
  factory YouTubePlaylistModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return YouTubePlaylistModel.fromMap(data);
  }

  // CopyWith method
  YouTubePlaylistModel copyWith({
    String? id,
    String? playlistId,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? videoCount,
    String? channelName,
    String? channelId,
    List<String>? videoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resourceId,
    String? subject,
    String? topic,
    String? unit,
  }) {
    return YouTubePlaylistModel(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoCount: videoCount ?? this.videoCount,
      channelName: channelName ?? this.channelName,
      channelId: channelId ?? this.channelId,
      videoIds: videoIds ?? this.videoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resourceId: resourceId ?? this.resourceId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'YouTubePlaylistModel(playlistId: $playlistId, title: $title, videoCount: $videoCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YouTubePlaylistModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}