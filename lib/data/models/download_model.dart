import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// DOWNLOAD STATUS ENUM
// ═══════════════════════════════════════════════════════════════

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
  cancelled;

  String get value {
    switch (this) {
      case DownloadStatus.pending:
        return 'pending';
      case DownloadStatus.downloading:
        return 'downloading';
      case DownloadStatus.completed:
        return 'completed';
      case DownloadStatus.failed:
        return 'failed';
      case DownloadStatus.paused:
        return 'paused';
      case DownloadStatus.cancelled:
        return 'cancelled';
    }
  }

  static DownloadStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'paused':
        return DownloadStatus.paused;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.pending;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// DOWNLOAD MODEL - COMPREHENSIVE & PERSISTENT
// ═══════════════════════════════════════════════════════════════

class DownloadModel {
  final String id; // Task ID from flutter_downloader
  final String? userId; // User who downloaded (null for guest users)
  final String resourceId; // Reference to the resource
  final String resourceTitle; // Display name
  final String filePath; // Local file path
  final String fileUrl; // Remote download URL
  final int fileSize; // Total file size in bytes
  final DownloadStatus status; // Current download status
  final double progress; // Progress 0.0 to 1.0
  final DateTime downloadedAt; // When download started
  final DateTime? completedAt; // When download completed
  final DateTime? pausedAt; // When download was paused
  final String? errorMessage; // Error details if failed
  final int? downloadSpeed; // Current download speed in bytes/sec
  final int? downloadedBytes; // Bytes downloaded so far
  final String? fileExtension; // File extension (pdf, docx, etc.)
  final String? mimeType; // File MIME type
  final String? resourceType; // Type of resource (Notes, Assignments, etc.)
  final String? college; // College name
  final String? department; // Department name
  final String? semester; // Semester
  final String? subject; // Subject name
  final Map<String, dynamic>? metadata; // Additional metadata

  DownloadModel({
    required this.id,
    this.userId,
    required this.resourceId,
    required this.resourceTitle,
    required this.filePath,
    required this.fileUrl,
    required this.fileSize,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    required this.downloadedAt,
    this.completedAt,
    this.pausedAt,
    this.errorMessage,
    this.downloadSpeed,
    this.downloadedBytes,
    this.fileExtension,
    this.mimeType,
    this.resourceType,
    this.college,
    this.department,
    this.semester,
    this.subject,
    this.metadata,
  });

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Convert to Map for FIRESTORE (uses Timestamp)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'status': status.value,
      'progress': progress,
      'downloadedAt': Timestamp.fromDate(downloadedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'errorMessage': errorMessage,
      'downloadSpeed': downloadSpeed,
      'downloadedBytes': downloadedBytes,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'resourceType': resourceType,
      'college': college,
      'department': department,
      'semester': semester,
      'subject': subject,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert to Map for HIVE (uses millisecondsSinceEpoch)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'resourceId': resourceId,
      'resourceTitle': resourceTitle,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'status': status.value,
      'progress': progress,
      'downloadedAt': downloadedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'pausedAt': pausedAt?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
      'downloadSpeed': downloadSpeed,
      'downloadedBytes': downloadedBytes,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'resourceType': resourceType,
      'college': college,
      'department': department,
      'semester': semester,
      'subject': subject,
      'metadata': metadata,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // DESERIALIZATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Create from Map (works with both Firestore and Hive)
  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'] ?? '',
      userId: map['userId'],
      resourceId: map['resourceId'] ?? '',
      resourceTitle: map['resourceTitle'] ?? 'Unknown',
      filePath: map['filePath'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      status: DownloadStatus.fromString(map['status'] ?? 'pending'),
      progress: (map['progress'] ?? 0.0).toDouble(),
      downloadedAt: _parseDateTime(map['downloadedAt']) ?? DateTime.now(),
      completedAt: _parseDateTime(map['completedAt']),
      pausedAt: _parseDateTime(map['pausedAt']),
      errorMessage: map['errorMessage'],
      downloadSpeed: map['downloadSpeed'],
      downloadedBytes: map['downloadedBytes'],
      fileExtension: map['fileExtension'],
      mimeType: map['mimeType'],
      resourceType: map['resourceType'],
      college: map['college'],
      department: map['department'],
      semester: map['semester'],
      subject: map['subject'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  /// Helper to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Create from Firestore Document
  factory DownloadModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DownloadModel.fromMap(data);
  }

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH METHOD
  // ═══════════════════════════════════════════════════════════════

  DownloadModel copyWith({
    String? id,
    String? userId,
    String? resourceId,
    String? resourceTitle,
    String? filePath,
    String? fileUrl,
    int? fileSize,
    DownloadStatus? status,
    double? progress,
    DateTime? downloadedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    String? errorMessage,
    int? downloadSpeed,
    int? downloadedBytes,
    String? fileExtension,
    String? mimeType,
    String? resourceType,
    String? college,
    String? department,
    String? semester,
    String? subject,
    Map<String, dynamic>? metadata,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      resourceId: resourceId ?? this.resourceId,
      resourceTitle: resourceTitle ?? this.resourceTitle,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      fileExtension: fileExtension ?? this.fileExtension,
      mimeType: mimeType ?? this.mimeType,
      resourceType: resourceType ?? this.resourceType,
      college: college ?? this.college,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      subject: subject ?? this.subject,
      metadata: metadata ?? this.metadata,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPending => status == DownloadStatus.pending;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isCancelled => status == DownloadStatus.cancelled;

  // ═══════════════════════════════════════════════════════════════
  // ACTION AVAILABILITY GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get canResume => isPaused || isFailed;
  bool get canPause => isDownloading;
  bool get canRetry => isFailed || isCancelled;
  bool get canDelete => true;
  bool get canOpen => isCompleted;
  bool get canCancel => isDownloading || isPending || isPaused;

  // ═══════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════

  /// Progress as percentage string
  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  /// Remaining bytes to download
  int get remainingBytes => fileSize - (downloadedBytes ?? 0);

  /// Estimated time remaining in seconds
  int? get estimatedTimeRemaining {
    if (downloadSpeed == null || downloadSpeed == 0 || !isDownloading) {
      return null;
    }
    return remainingBytes ~/ downloadSpeed!;
  }

  /// Formatted estimated time remaining
  String get estimatedTimeRemainingFormatted {
    final seconds = estimatedTimeRemaining;
    if (seconds == null) return 'Calculating...';

    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  /// Formatted download speed
  String get downloadSpeedFormatted {
    if (downloadSpeed == null || downloadSpeed == 0) {
      return '0 B/s';
    }

    final speed = downloadSpeed!;
    if (speed < 1024) {
      return '$speed B/s';
    } else if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Formatted file size
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Formatted downloaded bytes
  String get downloadedBytesFormatted {
    final bytes = downloadedBytes ?? 0;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Status display text
  String get statusDisplayText {
    switch (status) {
      case DownloadStatus.pending:
        return 'Waiting to start...';
      case DownloadStatus.downloading:
        return 'Downloading... $progressPercent';
      case DownloadStatus.completed:
        return 'Download complete';
      case DownloadStatus.failed:
        return errorMessage ?? 'Download failed';
      case DownloadStatus.paused:
        return 'Paused at $progressPercent';
      case DownloadStatus.cancelled:
        return 'Download cancelled';
    }
  }

  /// Download duration
  Duration get downloadDuration {
    if (completedAt != null) {
      return completedAt!.difference(downloadedAt);
    } else if (pausedAt != null) {
      return pausedAt!.difference(downloadedAt);
    } else {
      return DateTime.now().difference(downloadedAt);
    }
  }

  /// Formatted download duration
  String get downloadDurationFormatted {
    final duration = downloadDuration;

    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Get file name from path
  String get fileName {
    return filePath.split('/').last;
  }

  /// Check if file is a document
  bool get isDocument {
    final ext = fileExtension?.toLowerCase() ?? '';
    return ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'].contains(ext);
  }

  /// Check if file is an image
  bool get isImage {
    final ext = fileExtension?.toLowerCase() ?? '';
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  /// Check if file is a video
  bool get isVideo {
    final ext = fileExtension?.toLowerCase() ?? '';
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(ext);
  }

  /// Check if file is audio
  bool get isAudio {
    final ext = fileExtension?.toLowerCase() ?? '';
    return ['mp3', 'wav', 'ogg', 'aac', 'm4a'].contains(ext);
  }

  /// Check if file is an archive
  bool get isArchive {
    final ext = fileExtension?.toLowerCase() ?? '';
    return ['zip', 'rar', '7z', 'tar', 'gz'].contains(ext);
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDATION METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Validate if download model is valid
  bool get isValid {
    return id.isNotEmpty &&
        resourceId.isNotEmpty &&
        resourceTitle.isNotEmpty &&
        fileUrl.isNotEmpty &&
        fileSize > 0;
  }

  /// Check if download needs sync with Firestore
  bool get needsSync {
    return userId != null &&
        (isCompleted || isFailed || isCancelled);
  }

  // ═══════════════════════════════════════════════════════════════
  // OVERRIDE METHODS
  // ═══════════════════════════════════════════════════════════════

  @override
  String toString() {
    return 'DownloadModel('
        'id: $id, '
        'title: $resourceTitle, '
        'status: ${status.value}, '
        'progress: $progressPercent, '
        'size: $fileSizeFormatted'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadModel &&
        other.id == id &&
        other.resourceId == resourceId;
  }

  @override
  int get hashCode => Object.hash(id, resourceId);

  // ═══════════════════════════════════════════════════════════════
  // JSON SERIALIZATION (for API calls if needed)
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() => toMap();

  factory DownloadModel.fromJson(Map<String, dynamic> json) =>
      DownloadModel.fromMap(json);
}