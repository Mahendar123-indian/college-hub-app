import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { oneToOne, group }
enum ChatRequestStatus { pending, accepted, rejected }

class ConversationModel {
  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final Map<String, dynamic> participantDetails;
  final String lastMessage;
  final String lastMessageType;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final Map<String, ChatRequestStatus> chatRequests;
  final bool isActive;
  final DateTime createdAt;
  final List<String> mutedBy;
  final List<String> pinnedBy;

  // ═══════════════════════════════════════════════════════════════
  // GROUP CHAT SPECIFIC FIELDS
  // ═══════════════════════════════════════════════════════════════
  final String? groupName;
  final String? groupDescription;
  final String? groupPhoto;
  final List<String>? admins;
  final bool? onlyAdminsCanSend;

  ConversationModel({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantDetails,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.chatRequests,
    required this.isActive,
    required this.createdAt,
    required this.mutedBy,
    required this.pinnedBy,
    this.groupName,
    this.groupDescription,
    this.groupPhoto,
    this.admins,
    this.onlyAdminsCanSend,
  });

  // ═══════════════════════════════════════════════════════════════
  // CONVERSION LOGIC (FIRESTORE SYNC)
  // ═══════════════════════════════════════════════════════════════

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // ✅ CRITICAL: Force the document ID as the ID to prevent UI duplicates
    return ConversationModel.fromMap({...data, 'id': doc.id});
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    // Stability helper for Redmi 8 timestamp parsing
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return ConversationModel(
      id: map['id'] ?? '',
      type: map['type'] == 'group' ? ConversationType.group : ConversationType.oneToOne,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantDetails: Map<String, dynamic>.from(map['participantDetails'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: map['lastMessageType'] ?? 'text',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: parseTimestamp(map['lastMessageTime']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      chatRequests: (map['chatRequests'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
          k,
          ChatRequestStatus.values.firstWhere(
                (e) => e.name == v,
            orElse: () => ChatRequestStatus.pending,
          ),
        ),
      ) ?? {},
      // ✅ FIXED: Defaults to false so requests stay in the "Requests" tab first
      isActive: map['isActive'] ?? false,
      createdAt: parseTimestamp(map['createdAt']),
      mutedBy: List<String>.from(map['mutedBy'] ?? []),
      pinnedBy: List<String>.from(map['pinnedBy'] ?? []),
      // Group-specific fields
      groupName: map['groupName'],
      groupDescription: map['groupDescription'],
      groupPhoto: map['groupPhoto'],
      admins: map['admins'] != null ? List<String>.from(map['admins']) : null,
      onlyAdminsCanSend: map['onlyAdminsCanSend'],
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'participantDetails': participantDetails,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'chatRequests': chatRequests.map((k, v) => MapEntry(k, v.name)),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'mutedBy': mutedBy,
      'pinnedBy': pinnedBy,
    };

    // Add group-specific fields if they exist (only add non-null values)
    if (groupName != null) data['groupName'] = groupName!;
    if (groupDescription != null) data['groupDescription'] = groupDescription!;
    if (groupPhoto != null) data['groupPhoto'] = groupPhoto!;
    if (admins != null) data['admins'] = admins!;
    if (onlyAdminsCanSend != null) data['onlyAdminsCanSend'] = onlyAdminsCanSend!;

    return data;
  }

  // ═══════════════════════════════════════════════════════════════
  // EQUALITY LOGIC (STOPS DUPLICATE RENDERING)
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ConversationModel &&
              runtimeType == other.runtimeType &&
              id == other.id; // ✅ Only compare ID for identity

  @override
  int get hashCode => id.hashCode;

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS (DYNAMISM)
  // ═══════════════════════════════════════════════════════════════

  String getOtherParticipantId(String currentUserId) {
    try {
      return participantIds.firstWhere((id) => id != currentUserId);
    } catch (_) {
      return '';
    }
  }

  String getDisplayName(String currentUserId) {
    if (type == ConversationType.group) {
      return groupName ?? 'Group Chat';
    }
    final otherId = getOtherParticipantId(currentUserId);
    return participantDetails[otherId]?['name'] ?? 'User';
  }

  String? getDisplayPhoto(String currentUserId) {
    if (type == ConversationType.group) {
      return groupPhoto;
    }
    final otherId = getOtherParticipantId(currentUserId);
    return participantDetails[otherId]?['photoUrl'];
  }

  bool isPinnedBy(String userId) => pinnedBy.contains(userId);
  bool isMutedBy(String userId) => mutedBy.contains(userId);
  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  // Group-specific helper methods
  bool isAdmin(String userId) => admins?.contains(userId) ?? false;
  bool get isGroup => type == ConversationType.group;
  int get memberCount => participantIds.length;

  // Copy with method for updates
  ConversationModel copyWith({
    String? groupName,
    String? groupDescription,
    String? groupPhoto,
    List<String>? admins,
    bool? onlyAdminsCanSend,
    List<String>? mutedBy,
    List<String>? pinnedBy,
    bool? isActive,
    String? lastMessage,
    String? lastMessageType,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      participantIds: participantIds,
      participantDetails: participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      chatRequests: chatRequests,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      mutedBy: mutedBy ?? this.mutedBy,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupPhoto: groupPhoto ?? this.groupPhoto,
      admins: admins ?? this.admins,
      onlyAdminsCanSend: onlyAdminsCanSend ?? this.onlyAdminsCanSend,
    );
  }
}