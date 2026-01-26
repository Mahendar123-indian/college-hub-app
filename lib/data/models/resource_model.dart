import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String college;
  final String department;
  final String semester;
  final String subject;
  final String resourceType;
  final String? year;
  final String fileUrl;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String? thumbnailUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int downloadCount;
  final int viewCount;
  final double rating;
  final int ratingCount;
  final bool isFeatured;
  final bool isTrending;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  // ✅ NEW: Trending fields
  final double? trendingScore;
  final DateTime? lastTrendingUpdate;

  // ✅ NEW: YouTube video IDs
  final List<String>? youtubeVideoIds;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.college,
    required this.department,
    required this.semester,
    required this.subject,
    required this.resourceType,
    this.year,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    this.thumbnailUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.updatedAt,
    this.tags = const [],
    this.downloadCount = 0,
    this.viewCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isFeatured = false,
    this.isTrending = false,
    this.isActive = true,
    this.metadata,
    // ✅ NEW: Trending fields
    this.trendingScore,
    this.lastTrendingUpdate,
    // ✅ NEW
    this.youtubeVideoIds,
  });

  // 🔥 FIXED: Separate methods for Firestore and Hive

  // Convert to Map for FIRESTORE (uses Timestamp)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'college': college,
      'department': department,
      'semester': semester,
      'subject': subject,
      'resourceType': resourceType,
      'year': year,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'isActive': isActive,
      'metadata': metadata,
      // ✅ NEW: Trending fields
      'trendingScore': trendingScore,
      'lastTrendingUpdate': lastTrendingUpdate != null
          ? Timestamp.fromDate(lastTrendingUpdate!)
          : null,
      // ✅ NEW
      'youtubeVideoIds': youtubeVideoIds,
    };
  }

  // Convert to Map for HIVE (uses millisecondsSinceEpoch)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'college': college,
      'department': department,
      'semester': semester,
      'subject': subject,
      'resourceType': resourceType,
      'year': year,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'tags': tags,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'isActive': isActive,
      'metadata': metadata,
      // ✅ NEW: Trending fields
      'trendingScore': trendingScore,
      'lastTrendingUpdate': lastTrendingUpdate?.millisecondsSinceEpoch,
      // ✅ NEW
      'youtubeVideoIds': youtubeVideoIds,
    };
  }

  // Create from Map (works with both Firestore and Hive)
  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      college: map['college'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      subject: map['subject'] ?? '',
      resourceType: map['resourceType'] ?? '',
      year: map['year'],
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileExtension: map['fileExtension'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'],
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: _parseDateTime(map['uploadedAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      downloadCount: map['downloadCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      isTrending: map['isTrending'] ?? false,
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] as Map<String, dynamic>?,
      // ✅ NEW: Trending fields
      trendingScore: (map['trendingScore'] as num?)?.toDouble(),
      lastTrendingUpdate: _parseDateTime(map['lastTrendingUpdate']),
      // ✅ NEW
      youtubeVideoIds: map['youtubeVideoIds'] != null
          ? List<String>.from(map['youtubeVideoIds'])
          : null,
    );
  }

  // Helper to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // Create from Firestore DocumentSnapshot
  factory ResourceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel.fromMap(data);
  }

  // CopyWith method
  ResourceModel copyWith({
    String? id,
    String? title,
    String? description,
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? resourceType,
    String? year,
    String? fileUrl,
    String? fileName,
    String? fileExtension,
    int? fileSize,
    String? thumbnailUrl,
    String? uploadedBy,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? downloadCount,
    int? viewCount,
    double? rating,
    int? ratingCount,
    bool? isFeatured,
    bool? isTrending,
    bool? isActive,
    Map<String, dynamic>? metadata,
    // ✅ NEW: Trending fields
    double? trendingScore,
    DateTime? lastTrendingUpdate,
    // ✅ NEW
    List<String>? youtubeVideoIds,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      college: college ?? this.college,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      subject: subject ?? this.subject,
      resourceType: resourceType ?? this.resourceType,
      year: year ?? this.year,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isTrending: isTrending ?? this.isTrending,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      // ✅ NEW: Trending fields
      trendingScore: trendingScore ?? this.trendingScore,
      lastTrendingUpdate: lastTrendingUpdate ?? this.lastTrendingUpdate,
      // ✅ NEW
      youtubeVideoIds: youtubeVideoIds ?? this.youtubeVideoIds,
    );
  }

  // Helper methods
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension.toLowerCase());
  bool get isDocument => ['doc', 'docx', 'txt', 'rtf'].contains(fileExtension.toLowerCase());

  // ✅ NEW: Helper method to check if resource has YouTube videos
  bool get hasYoutubeVideos => youtubeVideoIds != null && youtubeVideoIds!.isNotEmpty;

  @override
  String toString() {
    return 'ResourceModel(id: $id, title: $title, resourceType: $resourceType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResourceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}