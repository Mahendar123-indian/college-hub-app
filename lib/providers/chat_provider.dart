import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/message_model.dart';
import '../data/models/conversation_model.dart';
import '../data/models/user_model.dart';
import '../data/services/chat_service.dart';
import '../core/utils/notification_triggers.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  List<UserModel> _searchResults = [];
  List<Map<String, dynamic>> _chatRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════
  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  List<UserModel> get searchResults => _searchResults;
  List<Map<String, dynamic>> get chatRequests => _chatRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ═══════════════════════════════════════════════════════════════
  // ✅ REAL-TIME STREAM LISTENERS - TYPING STATUS TRACKING
  // ═══════════════════════════════════════════════════════════════
  StreamSubscription? _convSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _requestSub;
  final Map<String, StreamSubscription> _typingSubscriptions = {};

  // ✅ ADDED: Cache for typing users (synchronized data)
  final Map<String, List<String>> _typingUsersCache = {};

  int getTotalUnreadCount(String userId) {
    return _conversations.fold(0, (sum, conv) => sum + (conv.unreadCount[userId] ?? 0));
  }

  void loadConversations(String uid) {
    _convSub?.cancel();
    _convSub = _chatService.getUserConversations(uid).listen((data) {
      final Map<String, ConversationModel> uniqueMap = {};
      for (var conv in data) {
        uniqueMap[conv.id] = conv;
      }
      _conversations = uniqueMap.values.toList();
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      notifyListeners();
    }, onError: (e) => debugPrint("Conv Stream Error: $e"));
  }

  void loadMessages(String cid) {
    _msgSub?.cancel();
    _msgSub = _chatService.getMessages(cid).listen((data) {
      _currentMessages = data;
      notifyListeners();
    }, onError: (e) => debugPrint("Msg Stream Error: $e"));
  }

  void loadChatRequests(String uid) {
    _requestSub?.cancel();
    _requestSub = _chatService.getChatRequests(uid).listen((data) {
      _chatRequests = data;
      notifyListeners();
    }, onError: (e) => debugPrint("Request Stream Error: $e"));
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM GETTERS (for real-time UI updates)
  // ═══════════════════════════════════════════════════════════════

  Stream<ConversationModel?> getConversationStream(String cid) {
    return _chatService.getConversationStream(cid);
  }

  Stream<int> getGroupMemberCount(String cid) {
    return _chatService.getConversationStream(cid).map(
          (conv) => conv?.participantIds.length ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ TYPING STATUS - BOTH STREAM AND SYNC METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Stream-based typing users (real-time)
  Stream<List<String>> getTypingUsers(String cid, String uid) {
    // Cancel existing subscription for this conversation if any
    _typingSubscriptions[cid]?.cancel();

    final stream = _chatService.getTypingUsers(cid, uid);

    // Track the subscription and update cache
    _typingSubscriptions[cid] = stream.listen((typingUsers) {
      _typingUsersCache[cid] = typingUsers;
      notifyListeners();
    }, onError: (e) {
      debugPrint("⚠️ Typing status stream error (expected during logout): $e");
      _typingUsersCache[cid] = [];
    });

    return stream;
  }

  /// ✅ SYNCHRONOUS method to get typing users from cache
  /// This is what chat_detail_screen_advanced.dart needs
  List<String> getTypingUsersSync(String conversationId, String currentUserId) {
    try {
      // Return cached typing users, excluding current user
      final typingUsers = _typingUsersCache[conversationId] ?? [];
      return typingUsers.where((userId) => userId != currentUserId).toList();
    } catch (e) {
      debugPrint("Error getting typing users sync: $e");
      return [];
    }
  }

  /// Set typing status for current user
  Future<void> setTypingStatus(String cid, String uid, bool typing) async {
    try {
      await _chatService.setTypingStatus(cid, uid, typing);
    } catch (e) {
      debugPrint("Set typing status error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ UNREAD COUNT LOGIC (WHATSAPP STYLE)
  // ═══════════════════════════════════════════════════════════════

  Future<void> markMessagesAsRead(String cid, String uid) async {
    // 1. Identify messages sent by others that I haven't read
    final unreadMessageIds = _currentMessages
        .where((msg) => msg.senderId != uid && !msg.readBy.contains(uid))
        .map((msg) => msg.id)
        .toList();

    // 2. Check if the badge needs clearing
    final conversation = _conversations.cast<ConversationModel?>().firstWhere(
          (c) => c?.id == cid,
      orElse: () => null,
    );

    bool needsBadgeClear = (conversation?.unreadCount[uid] ?? 0) > 0;

    if (unreadMessageIds.isNotEmpty || needsBadgeClear) {
      try {
        await _chatService.markAsRead(cid, uid, unreadMessageIds);

        // 3. Update local state immediately for instant UI response
        final index = _conversations.indexWhere((c) => c.id == cid);
        if (index != -1) {
          _conversations[index].unreadCount[uid] = 0;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("MarkAsRead Error: $e");
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ MESSAGE ACTIONS WITH NOTIFICATIONS - FIXED
  // ═══════════════════════════════════════════════════════════════

  Future<bool> sendTextMessage({
    required String cid,
    required String sid,
    required String name,
    required String content,
    String? replyToId,
  }) async {
    try {
      await _chatService.sendTextMessage(
        conversationId: cid,
        senderId: sid,
        senderName: name,
        content: content,
        replyToId: replyToId,
      );

      // ✅ FIXED: Get conversation details with proper data
      final conversation = _conversations.firstWhere(
            (c) => c.id == cid,
        orElse: () => _conversations.first,
      );

      // Get sender details from conversation participants
      final senderDetails = conversation.participantDetails[sid];
      final senderPhotoUrl = senderDetails?['photoUrl'] as String?;

      // Check if it's a group or direct message
      if (conversation.isGroup) {
        // Group message notification with complete data
        await NotificationTriggers.newGroupMessage(
          groupName: conversation.groupName ?? 'Group Chat',
          senderName: name,
          message: content,
          conversationId: cid,
        );
      } else {
        // Direct message notification - NOW WITH COMPLETE DATA
        await NotificationTriggers.newMessage(
          senderName: name,
          message: content,
          conversationId: cid,
          senderPhotoUrl: senderPhotoUrl,
        );
      }

      return true;
    } catch (e) {
      debugPrint("Send Error: $e");
      return false;
    }
  }

  Future<void> sendImageMessage(String cid, String sid, String name, File file) async {
    try {
      await _chatService.sendMediaMessage(cid: cid, sid: sid, name: name, file: file, type: 'image');

      final conversation = _conversations.firstWhere((c) => c.id == cid, orElse: () => _conversations.first);
      final senderPhotoUrl = conversation.participantDetails[sid]?['photoUrl'] as String?;

      if (conversation.isGroup) {
        await NotificationTriggers.newGroupMessage(
          groupName: conversation.groupName ?? 'Group Chat',
          senderName: name,
          message: '📷 Image',
          conversationId: cid,
        );
      } else {
        await NotificationTriggers.newMessage(
          senderName: name,
          message: '📷 Image',
          conversationId: cid,
          senderPhotoUrl: senderPhotoUrl,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendFileMessage(String cid, String sid, String name, File file, String fileName) async {
    try {
      await _chatService.sendMediaMessage(cid: cid, sid: sid, name: name, file: file, type: 'file', fileName: fileName);

      final conversation = _conversations.firstWhere((c) => c.id == cid, orElse: () => _conversations.first);
      final senderPhotoUrl = conversation.participantDetails[sid]?['photoUrl'] as String?;

      if (conversation.isGroup) {
        await NotificationTriggers.newGroupMessage(
          groupName: conversation.groupName ?? 'Group Chat',
          senderName: name,
          message: '📎 $fileName',
          conversationId: cid,
        );
      } else {
        await NotificationTriggers.newMessage(
          senderName: name,
          message: '📎 $fileName',
          conversationId: cid,
          senderPhotoUrl: senderPhotoUrl,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage(String cid, String sid, String name, File file, int duration) async {
    try {
      await _chatService.sendMediaMessage(cid: cid, sid: sid, name: name, file: file, type: 'voice', duration: duration);

      final conversation = _conversations.firstWhere((c) => c.id == cid, orElse: () => _conversations.first);
      final senderPhotoUrl = conversation.participantDetails[sid]?['photoUrl'] as String?;

      if (conversation.isGroup) {
        await NotificationTriggers.newGroupMessage(
          groupName: conversation.groupName ?? 'Group Chat',
          senderName: name,
          message: '🎤 Voice message',
          conversationId: cid,
        );
      } else {
        await NotificationTriggers.newMessage(
          senderName: name,
          message: '🎤 Voice message',
          conversationId: cid,
          senderPhotoUrl: senderPhotoUrl,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> editMessage(String cid, String mid, String newContent) async {
    try {
      await _chatService.editMessage(cid, mid, newContent);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addReaction(String cid, String mid, String uid, String emoji) async {
    try {
      await _chatService.addReaction(cid, mid, uid, emoji);
    } catch (e) {
      debugPrint("Reaction Error: $e");
    }
  }

  Future<void> deleteMessage(String cid, String mid) async {
    try {
      await _chatService.deleteMessage(cid, mid);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEW ADVANCED FEATURES
  // ═══════════════════════════════════════════════════════════════

  Future<void> forwardMessage({
    required String fromConversationId,
    required String toConversationId,
    required String messageId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      await _chatService.forwardMessage(
        fromConversationId: fromConversationId,
        toConversationId: toConversationId,
        messageId: messageId,
        senderId: senderId,
        senderName: senderName,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> pinMessage(String cid, String mid) async {
    try {
      await _chatService.pinMessage(cid, mid);
    } catch (e) {
      debugPrint("Pin Error: $e");
    }
  }

  Future<void> unpinMessage(String cid, String mid) async {
    try {
      await _chatService.unpinMessage(cid, mid);
    } catch (e) {
      debugPrint("Unpin Error: $e");
    }
  }

  Future<void> muteConversation(String cid, String uid) async {
    try {
      await _chatService.muteConversation(cid, uid);
      final index = _conversations.indexWhere((c) => c.id == cid);
      if (index != -1) {
        _conversations[index].mutedBy.add(uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Mute Error: $e");
    }
  }

  Future<void> clearChat(String cid) async {
    try {
      await _chatService.clearChat(cid);
    } catch (e) {
      debugPrint("Clear Chat Error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ GROUP CHAT FEATURES WITH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<String?> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> memberIds,
    required Map<String, Map<String, dynamic>> memberDetails,
    required String adminId,
    File? groupPhoto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final groupId = await _chatService.createGroup(
        groupName: groupName,
        groupDescription: groupDescription,
        memberIds: memberIds,
        memberDetails: memberDetails,
        adminId: adminId,
        groupPhoto: groupPhoto,
      );

      final adminName = memberDetails[adminId]?['name'] ?? 'Someone';
      for (final memberId in memberIds) {
        if (memberId != adminId) {
          await NotificationTriggers.groupInvite(
            groupName: groupName,
            inviterName: adminName,
            groupId: groupId!,
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return groupId;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateGroupPhoto(String cid, File photo) async {
    try {
      await _chatService.updateGroupPhoto(cid, photo);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateGroupName(String cid, String name) async {
    try {
      await _chatService.updateGroupName(cid, name);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateGroupDescription(String cid, String description) async {
    try {
      await _chatService.updateGroupDescription(cid, description);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addGroupMembers(
      String cid,
      List<String> memberIds,
      Map<String, Map<String, dynamic>> memberDetails,
      ) async {
    try {
      await _chatService.addGroupMembers(cid, memberIds, memberDetails);

      final conversation = _conversations.firstWhere((c) => c.id == cid);
      for (final memberId in memberIds) {
        await NotificationTriggers.groupInvite(
          groupName: conversation.groupName ?? 'Group Chat',
          inviterName: 'Group Admin',
          groupId: cid,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeGroupMember(String cid, String memberId) async {
    try {
      await _chatService.removeGroupMember(cid, memberId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> makeGroupAdmin(String cid, String memberId) async {
    try {
      await _chatService.makeGroupAdmin(cid, memberId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeGroupAdmin(String cid, String memberId) async {
    try {
      await _chatService.removeGroupAdmin(cid, memberId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveGroup(String cid, String uid) async {
    try {
      await _chatService.leaveGroup(cid, uid);
      _conversations.removeWhere((c) => c.id == cid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String cid) async {
    try {
      await _chatService.deleteGroup(cid);
      _conversations.removeWhere((c) => c.id == cid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateGroupSettings(String cid, {bool? onlyAdminsCanSend}) async {
    try {
      await _chatService.updateGroupSettings(cid, onlyAdminsCanSend: onlyAdminsCanSend);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CONVERSATION & REQUEST LOGIC
  // ═══════════════════════════════════════════════════════════════

  Future<void> respondToChatRequest(String cid, String uid, bool accept) async {
    try {
      await _chatService.respondToRequest(cid, uid, accept);
      _chatRequests.removeWhere((element) => element['id'] == cid);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<String?> createOrGetConversation({
    required String currentUserId,
    required String otherUserId,
    required Map<String, dynamic> currentUserDetails,
    required Map<String, dynamic> otherUserDetails,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cid = await _chatService.createOrGetConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserDetails: currentUserDetails,
        otherUserDetails: otherUserDetails,
      );
      _isLoading = false;
      notifyListeners();
      return cid;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> searchUsers(String query, String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _searchResults = await _chatService.searchUsers(query, uid);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ STREAM CANCELLATION - FIXED TO INCLUDE TYPING STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Cancel all active chat stream subscriptions and clear data
  Future<void> cancelStreams() async {
    try {
      // Cancel main subscriptions
      await _convSub?.cancel();
      await _msgSub?.cancel();
      await _requestSub?.cancel();

      // ✅ FIXED: Cancel all typing status subscriptions
      for (final subscription in _typingSubscriptions.values) {
        await subscription.cancel();
      }
      _typingSubscriptions.clear();
      _typingUsersCache.clear(); // ✅ Clear typing cache

      _convSub = null;
      _msgSub = null;
      _requestSub = null;

      // Clear all local data to prevent stale state
      _conversations = [];
      _currentMessages = [];
      _chatRequests = [];
      _searchResults = [];

      debugPrint('✅ ChatProvider streams cancelled and data cleared');
    } catch (e) {
      debugPrint('❌ Error cancelling chat streams: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 APP RESUME HANDLER
  // ═══════════════════════════════════════════════════════════════

  /// Reconnect chat listeners when app resumes from background
  Future<void> reconnect() async {
    try {
      debugPrint('🔄 Reconnecting chat streams on app resume...');
      // Typing status subscriptions will auto-reconnect when UI calls getTypingUsers
      debugPrint('✅ Chat reconnected successfully');
    } catch (e) {
      debugPrint('⚠️ Chat reconnect error: $e');
    }
  }

  @override
  void dispose() {
    _convSub?.cancel();
    _msgSub?.cancel();
    _requestSub?.cancel();

    // ✅ FIXED: Cancel typing subscriptions on dispose
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();
    _typingUsersCache.clear();

    super.dispose();
  }
}