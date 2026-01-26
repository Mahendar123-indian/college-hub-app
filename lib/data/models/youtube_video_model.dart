import 'package:cloud_firestore/cloud_firestore.dart';

class YouTubeVideoModel {
  final String id;
  final String videoId;
  final String title;
  final String channelName;
  final String channelId;
  final String thumbnailUrl;
  final String duration;
  final String description;
  final int viewCount;
  final DateTime publishedAt;
  final String difficulty; // Easy, Medium, Advanced
  final String suitableFor; // Exam Revision, First Time Learning, Quick Recap
  final List<String> keyTopics;
  final List<VideoTimestamp> timestamps;
  final double relevanceScore;
  final int likeCount;
  final String embedUrl;

  // Related to resource
  final String? resourceId;
  final String? subject;
  final String? topic;
  final String? unit;

  YouTubeVideoModel({
    required this.id,
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.channelId,
    required this.thumbnailUrl,
    required this.duration,
    required this.description,
    required this.viewCount,
    required this.publishedAt,
    required this.difficulty,
    required this.suitableFor,
    required this.keyTopics,
    required this.timestamps,
    required this.relevanceScore,
    required this.likeCount,
    required this.embedUrl,
    this.resourceId,
    this.subject,
    this.topic,
    this.unit,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'channelId': channelId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'description': description,
      'viewCount': viewCount,
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'difficulty': difficulty,
      'suitableFor': suitableFor,
      'keyTopics': keyTopics,
      'timestamps': timestamps.map((t) => t.toMap()).toList(),
      'relevanceScore': relevanceScore,
      'likeCount': likeCount,
      'embedUrl': embedUrl,
      'resourceId': resourceId,
      'subject': subject,
      'topic': topic,
      'unit': unit,
    };
  }

  // Convert to Map for Firestore (with Timestamp)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'channelName': channelName,
      'channelId': channelId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'description': description,
      'viewCount': viewCount,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'difficulty': difficulty,
      'suitableFor': suitableFor,
      'keyTopics': keyTopics,
      'timestamps': timestamps.map((t) => t.toMap()).toList(),
      'relevanceScore': relevanceScore,
      'likeCount': likeCount,
      'embedUrl': embedUrl,
      'resourceId': resourceId,
      'subject': subject,
      'topic': topic,
      'unit': unit,
    };
  }

  // Create from Map
  factory YouTubeVideoModel.fromMap(Map<String, dynamic> map) {
    return YouTubeVideoModel(
      id: map['id'] ?? '',
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? '',
      channelName: map['channelName'] ?? '',
      channelId: map['channelId'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      duration: map['duration'] ?? '',
      description: map['description'] ?? '',
      viewCount: map['viewCount'] ?? 0,
      publishedAt: _parseDateTime(map['publishedAt']) ?? DateTime.now(),
      difficulty: map['difficulty'] ?? 'Medium',
      suitableFor: map['suitableFor'] ?? 'First Time Learning',
      keyTopics: List<String>.from(map['keyTopics'] ?? []),
      timestamps: (map['timestamps'] as List<dynamic>?)
          ?.map((t) => VideoTimestamp.fromMap(t as Map<String, dynamic>))
          .toList() ??
          [],
      relevanceScore: (map['relevanceScore'] ?? 0.0).toDouble(),
      likeCount: map['likeCount'] ?? 0,
      embedUrl: map['embedUrl'] ?? '',
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
  factory YouTubeVideoModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return YouTubeVideoModel.fromMap(data);
  }

  // CopyWith method
  YouTubeVideoModel copyWith({
    String? id,
    String? videoId,
    String? title,
    String? channelName,
    String? channelId,
    String? thumbnailUrl,
    String? duration,
    String? description,
    int? viewCount,
    DateTime? publishedAt,
    String? difficulty,
    String? suitableFor,
    List<String>? keyTopics,
    List<VideoTimestamp>? timestamps,
    double? relevanceScore,
    int? likeCount,
    String? embedUrl,
    String? resourceId,
    String? subject,
    String? topic,
    String? unit,
  }) {
    return YouTubeVideoModel(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channelName: channelName ?? this.channelName,
      channelId: channelId ?? this.channelId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt ?? this.publishedAt,
      difficulty: difficulty ?? this.difficulty,
      suitableFor: suitableFor ?? this.suitableFor,
      keyTopics: keyTopics ?? this.keyTopics,
      timestamps: timestamps ?? this.timestamps,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      likeCount: likeCount ?? this.likeCount,
      embedUrl: embedUrl ?? this.embedUrl,
      resourceId: resourceId ?? this.resourceId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'YouTubeVideoModel(videoId: $videoId, title: $title, channelName: $channelName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YouTubeVideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Video Timestamp Model - UPDATED WITH NULLABLE DESCRIPTION
class VideoTimestamp {
  final String time;
  final String label;
  final String? description; // ✅ NOW NULLABLE

  VideoTimestamp({
    required this.time,
    required this.label,
    this.description, // ✅ OPTIONAL PARAMETER
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'label': label,
      'description': description ?? '', // ✅ HANDLE NULL
    };
  }

  factory VideoTimestamp.fromMap(Map<String, dynamic> map) {
    return VideoTimestamp(
      time: map['time'] ?? '',
      label: map['label'] ?? '',
      description: map['description'], // ✅ CAN BE NULL
    );
  }

  // Convert time string (HH:MM or MM:SS) to seconds
  int get timeInSeconds {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        // MM:SS
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      } else if (parts.length == 3) {
        // HH:MM:SS
        return int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            int.parse(parts[2]);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}