import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  voice,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final List<String> readBy;
  final Map<String, dynamic>? reactions;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final int? voiceDuration;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? deletedAt;

  // ═══════════════════════════════════════════════════════════════
  // NEW ADVANCED FEATURES
  // ═══════════════════════════════════════════════════════════════
  final bool isPinned;
  final DateTime? pinnedAt;
  final bool isForwarded;
  final String? originalSender;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.readBy,
    this.reactions,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.voiceDuration,
    this.isDeleted = false,
    this.isEdited = false,
    this.deletedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.isForwarded = false,
    this.originalSender,
  });

  // ═══════════════════════════════════════════════════════════════
  // CONVERSION LOGIC (FIRESTORE SYNC)
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() {
    final data = {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'reactions': reactions ?? {},
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSenderName': replyToSenderName,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'voiceDuration': voiceDuration,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
      'isForwarded': isForwarded,
      'originalSender': originalSender,
    };

    return data;
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromMap({...data, 'id': doc.id});
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parseTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now(); // Fallback for stability
    }

    return MessageModel(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Explorer',
      senderPhotoUrl: map['senderPhotoUrl'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: parseTime(map['timestamp']),
      readBy: List<String>.from(map['readBy'] ?? []),
      reactions: map['reactions'] != null ? Map<String, dynamic>.from(map['reactions']) : {},
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSenderName: map['replyToSenderName'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      thumbnailUrl: map['thumbnailUrl'],
      voiceDuration: map['voiceDuration'],
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
      deletedAt: map['deletedAt'] != null ? parseTime(map['deletedAt']) : null,
      isPinned: map['isPinned'] ?? false,
      pinnedAt: map['pinnedAt'] != null ? parseTime(map['pinnedAt']) : null,
      isForwarded: map['isForwarded'] ?? false,
      originalSender: map['originalSender'],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  bool isMe(String currentUserId) => senderId == currentUserId;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool hasReaction(String userId) => reactions?.containsKey(userId) ?? false;

  String? getReaction(String userId) => reactions?[userId];

  int get reactionCount => reactions?.length ?? 0;

  MessageModel copyWith({
    MessageStatus? status,
    List<String>? readBy,
    Map<String, dynamic>? reactions,
    bool? isDeleted,
    bool? isEdited,
    String? content,
    bool? isPinned,
    DateTime? pinnedAt,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content ?? this.content,
      type: type,
      status: status ?? this.status,
      timestamp: timestamp,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      voiceDuration: voiceDuration,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      deletedAt: isDeleted == true ? DateTime.now() : deletedAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isForwarded: isForwarded,
      originalSender: originalSender,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EQUALITY LOGIC
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MessageModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}