import 'package:cloud_firestore/cloud_firestore.dart';

class PreviousYearPaperModel {
  final String id;
  final String title;
  final String description;
  final String examYear; // e.g., "2023", "2024"
  final String examType; // "Mid-Exam", "Semester Exam", "Annual Exam"
  final String college;
  final String department;
  final String semester;
  final String subject;
  final String? regulation; // e.g., "R18", "R20", "R22"

  // File Information
  final String fileUrl;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String? thumbnailUrl;

  // Uploader Information
  final String uploadedBy; // User ID
  final String uploaderName; // User's display name
  final String uploaderCollege; // Uploader's college
  final String uploaderDepartment; // Uploader's department
  final DateTime uploadedAt;
  final DateTime updatedAt;

  // Metadata
  final List<String> tags;
  final int downloadCount;
  final int viewCount;
  final double rating;
  final int ratingCount;

  // Moderation & Status
  final String status; // "pending", "approved", "rejected"
  final bool isActive;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy; // Admin user ID who approved

  // Additional metadata
  final Map<String, dynamic>? metadata;

  PreviousYearPaperModel({
    required this.id,
    required this.title,
    required this.description,
    required this.examYear,
    required this.examType,
    required this.college,
    required this.department,
    required this.semester,
    required this.subject,
    this.regulation,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    this.thumbnailUrl,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploaderCollege,
    required this.uploaderDepartment,
    required this.uploadedAt,
    required this.updatedAt,
    this.tags = const [],
    this.downloadCount = 0,
    this.viewCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.status = 'pending',
    this.isActive = true,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    this.metadata,
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'examYear': examYear,
      'examType': examType,
      'college': college,
      'department': department,
      'semester': semester,
      'subject': subject,
      'regulation': regulation,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploaderCollege': uploaderCollege,
      'uploaderDepartment': uploaderDepartment,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'status': status,
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'metadata': metadata,
    };
  }

  // Create from Map
  factory PreviousYearPaperModel.fromMap(Map<String, dynamic> map) {
    return PreviousYearPaperModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      examYear: map['examYear'] ?? '',
      examType: map['examType'] ?? '',
      college: map['college'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? '',
      subject: map['subject'] ?? '',
      regulation: map['regulation'],
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileExtension: map['fileExtension'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      thumbnailUrl: map['thumbnailUrl'],
      uploadedBy: map['uploadedBy'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploaderCollege: map['uploaderCollege'] ?? '',
      uploaderDepartment: map['uploaderDepartment'] ?? '',
      uploadedAt: _parseDateTime(map['uploadedAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      downloadCount: map['downloadCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      status: map['status'] ?? 'pending',
      isActive: map['isActive'] ?? true,
      rejectionReason: map['rejectionReason'],
      approvedAt: _parseDateTime(map['approvedAt']),
      approvedBy: map['approvedBy'],
      metadata: map['metadata'] as Map<String, dynamic>?,
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

  // Create from Firestore Document
  factory PreviousYearPaperModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PreviousYearPaperModel.fromMap(data);
  }

  // CopyWith method
  PreviousYearPaperModel copyWith({
    String? id,
    String? title,
    String? description,
    String? examYear,
    String? examType,
    String? college,
    String? department,
    String? semester,
    String? subject,
    String? regulation,
    String? fileUrl,
    String? fileName,
    String? fileExtension,
    int? fileSize,
    String? thumbnailUrl,
    String? uploadedBy,
    String? uploaderName,
    String? uploaderCollege,
    String? uploaderDepartment,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? downloadCount,
    int? viewCount,
    double? rating,
    int? ratingCount,
    String? status,
    bool? isActive,
    String? rejectionReason,
    DateTime? approvedAt,
    String? approvedBy,
    Map<String, dynamic>? metadata,
  }) {
    return PreviousYearPaperModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      examYear: examYear ?? this.examYear,
      examType: examType ?? this.examType,
      college: college ?? this.college,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      subject: subject ?? this.subject,
      regulation: regulation ?? this.regulation,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderCollege: uploaderCollege ?? this.uploaderCollege,
      uploaderDepartment: uploaderDepartment ?? this.uploaderDepartment,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      metadata: metadata ?? this.metadata,
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
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  @override
  String toString() {
    return 'PreviousYearPaperModel(id: $id, title: $title, examYear: $examYear, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreviousYearPaperModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}