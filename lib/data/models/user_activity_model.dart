import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks individual user activities for detailed analytics
class UserActivityModel {
  final String id;
  final String userId;
  final ActivityType type;
  final String resourceId;
  final String resourceTitle;
  final String resourceType;
  final String subject;
  final int durationSeconds;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.resourceId,
    required this.resourceTitle,
    required this.resourceType,
    required this.subject,
    this.durationSeconds = 0,
    required this.timestamp,
    this.metadata,
  });

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE CONVERSION
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'resourceType': resourceType,
      'subject': subject,
      'durationSeconds': durationSeconds,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory UserActivityModel.fromMap(Map<String, dynamic> map) {
    return UserActivityModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: ActivityType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ActivityType.view,
      ),
      resourceId: map['resourceId'] ?? '',
      resourceTitle: map['resourceTitle'] ?? '',
      resourceType: map['resourceType'] ?? '',
      subject: map['subject'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  factory UserActivityModel.fromDocument(DocumentSnapshot doc) {
    return UserActivityModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  String get formattedDuration {
    if (durationSeconds < 60) return '${durationSeconds}s';
    if (durationSeconds < 3600) {
      final minutes = durationSeconds ~/ 60;
      return '${minutes}m';
    }
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get activityIcon {
    switch (type) {
      case ActivityType.view:
        return '👁️';
      case ActivityType.download:
        return '⬇️';
      case ActivityType.bookmark:
        return '🔖';
      case ActivityType.search:
        return '🔍';
      case ActivityType.rating:
        return '⭐';
      case ActivityType.share:
        return '📤';
      case ActivityType.openPdf:
        return '📄';
    }
  }

  String get activityDescription {
    switch (type) {
      case ActivityType.view:
        return 'Viewed $resourceTitle';
      case ActivityType.download:
        return 'Downloaded $resourceTitle';
      case ActivityType.bookmark:
        return 'Bookmarked $resourceTitle';
      case ActivityType.search:
        return 'Searched for $resourceTitle';
      case ActivityType.rating:
        return 'Rated $resourceTitle';
      case ActivityType.share:
        return 'Shared $resourceTitle';
      case ActivityType.openPdf:
        return 'Opened $resourceTitle';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY TYPES
// ═══════════════════════════════════════════════════════════════

enum ActivityType {
  view,
  download,
  bookmark,
  search,
  rating,
  share,
  openPdf,
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY SUMMARY (for aggregated views)
// ═══════════════════════════════════════════════════════════════

class ActivitySummary {
  final String subject;
  final int totalActivities;
  final int totalMinutes;
  final Map<ActivityType, int> activityBreakdown;
  final DateTime lastActive;

  ActivitySummary({
    required this.subject,
    required this.totalActivities,
    required this.totalMinutes,
    required this.activityBreakdown,
    required this.lastActive,
  });

  String get formattedTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  int get viewCount => activityBreakdown[ActivityType.view] ?? 0;
  int get downloadCount => activityBreakdown[ActivityType.download] ?? 0;
  int get bookmarkCount => activityBreakdown[ActivityType.bookmark] ?? 0;
}