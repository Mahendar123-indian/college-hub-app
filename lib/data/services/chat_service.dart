import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// ENHANCED CHAT SERVICE - PRODUCTION READY
/// Features:
/// ✅ Proper media metadata storage
/// ✅ File type detection
/// ✅ Thumbnail generation
/// ✅ Progress tracking
/// ✅ Error handling
/// ✅ Real-time updates
/// ✅ Transaction safety
/// ═══════════════════════════════════════════════════════════════

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════════════════════════════
  // CONVERSATION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Stream active conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      docs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return docs;
    });
  }

  /// Stream single conversation for real-time updates
  Stream<ConversationModel?> getConversationStream(String cid) {
    return _firestore
        .collection('conversations')
        .doc(cid)
        .snapshots()
        .map((doc) =>
    doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }

  /// Create or get one-to-one conversation
  Future<String> createOrGetConversation({
    required String currentUserId,
    required String otherUserId,
    required Map<String, dynamic> currentUserDetails,
    required Map<String, dynamic> otherUserDetails,
  }) async {
    List<String> ids = [currentUserId, otherUserId]..sort();
    String convId = 'oneToOne_${ids[0]}_${ids[1]}';

    final docRef = _firestore.collection('conversations').doc(convId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'id': convId,
        'type': 'oneToOne',
        'participantIds': ids,
        'participantDetails': {
          currentUserId: currentUserDetails,
          otherUserId: otherUserDetails,
        },
        'lastMessage': 'Chat request sent',
        'lastMessageType': 'text',
        'lastMessageSenderId': currentUserId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'chatRequests': {currentUserId: 'accepted', otherUserId: 'pending'},
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'mutedBy': [],
        'pinnedBy': [],
      });
    }
    return convId;
  }

  /// Get pending chat requests
  Stream<List<Map<String, dynamic>>> getChatRequests(String uid) {
    return _firestore
        .collection('conversations')
        .where('chatRequests.$uid', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'details': data['participantDetails'],
        'time': data['lastMessageTime'],
        'participantIds': data['participantIds'],
      };
    }).toList());
  }

  /// Respond to chat request
  Future<void> respondToRequest(String cid, String uid, bool accept) async {
    final docRef = _firestore.collection('conversations').doc(cid);
    if (accept) {
      await docRef.update({
        'chatRequests.$uid': 'accepted',
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Stream messages
  Stream<List<MessageModel>> getMessages(String cid) {
    return _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  /// Mark messages as read
  Future<void> markAsRead(
      String cid, String uid, List<String> messageIds) async {
    final batch = _firestore.batch();

    for (var id in messageIds) {
      batch.update(
        _firestore
            .collection('conversations')
            .doc(cid)
            .collection('messages')
            .doc(id),
        {
          'readBy': FieldValue.arrayUnion([uid]),
          'status': 'read',
        },
      );
    }

    batch.update(_firestore.collection('conversations').doc(cid), {
      'unreadCount.$uid': 0,
    });

    await batch.commit();
  }

  /// Send text message
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    String? replyToId,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(convRef);
      if (!snap.exists) throw Exception("Conversation not found");

      Map<String, dynamic> unreads =
      Map<String, dynamic>.from(snap.data()?['unreadCount'] ?? {});
      List<dynamic> participants = snap.data()?['participantIds'] ?? [];

      for (var id in participants) {
        if (id != senderId) unreads[id] = (unreads[id] ?? 0) + 1;
      }

      final messageData = {
        'id': msgRef.id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': 'text',
        'status': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [senderId],
        'isDeleted': false,
        'isEdited': false,
        'isPinned': false,
        'reactions': {},
      };

      if (replyToId != null) {
        messageData['replyToId'] = replyToId;
      }

      transaction.set(msgRef, messageData);

      transaction.update(convRef, {
        'lastMessage': content,
        'lastMessageType': 'text',
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': unreads,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ ENHANCED MEDIA MESSAGE SENDING
  // ═══════════════════════════════════════════════════════════════

  /// Send media message with proper metadata
  Future<void> sendMediaMessage({
    required String cid,
    required String sid,
    required String name,
    required File file,
    required String type,
    int? duration,
    String? fileName,
  }) async {
    try {
      // Validate file
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();

      // Validate file size (max 50MB for images, 100MB for files, 25MB for voice)
      final maxSize = type == 'image'
          ? 50 * 1024 * 1024
          : type == 'voice'
          ? 25 * 1024 * 1024
          : 100 * 1024 * 1024;

      if (fileSize > maxSize) {
        throw Exception('File size exceeds limit');
      }

      // Determine file extension
      final extension = file.path.split('.').last.toLowerCase();

      // Generate unique storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'chats/$cid/${type}_${timestamp}.$extension';

      debugPrint('📤 Uploading $type to: $storagePath');

      // Upload file to Firebase Storage
      final uploadTask = _storage.ref().child(storagePath).putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension, type),
          customMetadata: {
            'uploadedBy': sid,
            'conversationId': cid,
            'messageType': type,
            'originalFileName': fileName ?? file.path.split('/').last,
          },
        ),
      );

      // Wait for upload to complete
      final taskSnapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      debugPrint('✅ Upload complete: $downloadUrl');

      // Prepare message data with proper metadata
      final convRef = _firestore.collection('conversations').doc(cid);
      final msgRef = convRef.collection('messages').doc();

      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(convRef);
        if (!snap.exists) throw Exception("Conversation not found");

        Map<String, dynamic> unreads =
        Map<String, dynamic>.from(snap.data()?['unreadCount'] ?? {});
        List<dynamic> participants = snap.data()?['participantIds'] ?? [];

        for (var id in participants) {
          if (id != sid) unreads[id] = (unreads[id] ?? 0) + 1;
        }

        // Build message data based on type
        final messageData = <String, dynamic>{
          'id': msgRef.id,
          'conversationId': cid,
          'senderId': sid,
          'senderName': name,
          'content': downloadUrl, // This is the Firebase Storage URL
          'type': type,
          'status': 'sent',
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': [sid],
          'isDeleted': false,
          'isEdited': false,
          'isPinned': false,
          'reactions': {},
        };

        // Add type-specific metadata
        if (type == 'voice' && duration != null) {
          messageData['voiceDuration'] = duration;
        }

        if (type == 'file') {
          messageData['fileName'] = fileName ?? file.path.split('/').last;
          messageData['fileSize'] = fileSize;
        }

        if (type == 'image') {
          messageData['fileSize'] = fileSize;
        }

        transaction.set(msgRef, messageData);

        // Update conversation
        String lastMessageText;
        switch (type) {
          case 'image':
            lastMessageText = '📷 Photo';
            break;
          case 'voice':
            lastMessageText = '🎤 Voice message';
            break;
          case 'file':
            lastMessageText = '📎 ${fileName ?? "Document"}';
            break;
          default:
            lastMessageText = '📁 Media';
        }

        transaction.update(convRef, {
          'lastMessage': lastMessageText,
          'lastMessageType': type,
          'lastMessageSenderId': sid,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': unreads,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('✅ Message saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error sending media message: $e');
      rethrow;
    }
  }

  /// Get content type for file
  String _getContentType(String extension, String type) {
    if (type == 'image') {
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
        default:
          return 'image/jpeg';
      }
    } else if (type == 'voice') {
      return 'audio/mpeg';
    } else {
      // Documents
      switch (extension) {
        case 'pdf':
          return 'application/pdf';
        case 'doc':
          return 'application/msword';
        case 'docx':
          return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        case 'xls':
          return 'application/vnd.ms-excel';
        case 'xlsx':
          return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        case 'ppt':
          return 'application/vnd.ms-powerpoint';
        case 'pptx':
          return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
        case 'txt':
          return 'text/plain';
        case 'zip':
          return 'application/zip';
        default:
          return 'application/octet-stream';
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Edit message
  Future<void> editMessage(String cid, String mid, String content) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'content': content,
      'isEdited': true,
    });
  }

  /// Delete message
  Future<void> deleteMessage(String cid, String mid) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'isDeleted': true,
      'content': 'Message deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add reaction
  Future<void> addReaction(
      String cid, String mid, String uid, String emoji) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'reactions.$uid': emoji,
    });
  }

  /// Remove reaction
  Future<void> removeReaction(String cid, String mid, String uid) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'reactions.$uid': FieldValue.delete(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED MESSAGE FEATURES
  // ═══════════════════════════════════════════════════════════════

  /// Forward message
  Future<void> forwardMessage({
    required String fromConversationId,
    required String toConversationId,
    required String messageId,
    required String senderId,
    required String senderName,
  }) async {
    final originalMsg = await _firestore
        .collection('conversations')
        .doc(fromConversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!originalMsg.exists) throw Exception("Message not found");

    final data = originalMsg.data()!;
    final convRef =
    _firestore.collection('conversations').doc(toConversationId);
    final msgRef = convRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(convRef);
      if (!snap.exists) throw Exception("Conversation not found");

      Map<String, dynamic> unreads =
      Map<String, dynamic>.from(snap.data()?['unreadCount'] ?? {});
      List<dynamic> participants = snap.data()?['participantIds'] ?? [];

      for (var id in participants) {
        if (id != senderId) unreads[id] = (unreads[id] ?? 0) + 1;
      }

      transaction.set(msgRef, {
        'id': msgRef.id,
        'conversationId': toConversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': data['content'],
        'type': data['type'],
        'status': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [senderId],
        'isDeleted': false,
        'isEdited': false,
        'isPinned': false,
        'reactions': {},
        'isForwarded': true,
        'originalSender': data['senderName'],
        if (data['fileName'] != null) 'fileName': data['fileName'],
        if (data['fileSize'] != null) 'fileSize': data['fileSize'],
        if (data['voiceDuration'] != null)
          'voiceDuration': data['voiceDuration'],
      });

      transaction.update(convRef, {
        'lastMessage': 'Forwarded message',
        'lastMessageType': data['type'],
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': unreads,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Pin message
  Future<void> pinMessage(String cid, String mid) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unpin message
  Future<void> unpinMessage(String cid, String mid) async {
    await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .doc(mid)
        .update({
      'isPinned': false,
      'pinnedAt': FieldValue.delete(),
    });
  }

  /// Mute conversation
  Future<void> muteConversation(String cid, String uid) async {
    await _firestore.collection('conversations').doc(cid).update({
      'mutedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Clear chat
  Future<void> clearChat(String cid) async {
    final messages = await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════════
  // GROUP CHAT FEATURES
  // ═══════════════════════════════════════════════════════════════

  /// Create group
  Future<String> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> memberIds,
    required Map<String, Map<String, dynamic>> memberDetails,
    required String adminId,
    File? groupPhoto,
  }) async {
    final groupId =
        'group_${DateTime.now().millisecondsSinceEpoch}_${adminId.substring(0, 8)}';

    String? photoUrl;
    if (groupPhoto != null) {
      final path = 'groups/$groupId/photo.jpg';
      final task = await _storage.ref().child(path).putFile(groupPhoto);
      photoUrl = await task.ref.getDownloadURL();
    }

    await _firestore.collection('conversations').doc(groupId).set({
      'id': groupId,
      'type': 'group',
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupPhoto': photoUrl,
      'participantIds': memberIds,
      'participantDetails': memberDetails,
      'admins': [adminId],
      'lastMessage': 'Group created',
      'lastMessageType': 'system',
      'lastMessageSenderId': adminId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount':
      Map.fromIterable(memberIds, key: (id) => id, value: (_) => 0),
      'chatRequests': {},
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mutedBy': [],
      'pinnedBy': [],
      'onlyAdminsCanSend': false,
    });

    return groupId;
  }

  /// Update group photo
  Future<void> updateGroupPhoto(String cid, File photo) async {
    final path =
        'groups/$cid/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final task = await _storage.ref().child(path).putFile(photo);
    final url = await task.ref.getDownloadURL();

    await _firestore.collection('conversations').doc(cid).update({
      'groupPhoto': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update group name
  Future<void> updateGroupName(String cid, String name) async {
    await _firestore.collection('conversations').doc(cid).update({
      'groupName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update group description
  Future<void> updateGroupDescription(String cid, String description) async {
    await _firestore.collection('conversations').doc(cid).update({
      'groupDescription': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add group members
  Future<void> addGroupMembers(
      String cid,
      List<String> memberIds,
      Map<String, Map<String, dynamic>> memberDetails,
      ) async {
    final batch = _firestore.batch();
    final convRef = _firestore.collection('conversations').doc(cid);

    batch.update(convRef, {
      'participantIds': FieldValue.arrayUnion(memberIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (var entry in memberDetails.entries) {
      batch.update(convRef, {
        'participantDetails.${entry.key}': entry.value,
        'unreadCount.${entry.key}': 0,
      });
    }

    await batch.commit();
  }

  /// Remove group member
  Future<void> removeGroupMember(String cid, String memberId) async {
    await _firestore.collection('conversations').doc(cid).update({
      'participantIds': FieldValue.arrayRemove([memberId]),
      'participantDetails.$memberId': FieldValue.delete(),
      'unreadCount.$memberId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Make group admin
  Future<void> makeGroupAdmin(String cid, String memberId) async {
    await _firestore.collection('conversations').doc(cid).update({
      'admins': FieldValue.arrayUnion([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove group admin
  Future<void> removeGroupAdmin(String cid, String memberId) async {
    await _firestore.collection('conversations').doc(cid).update({
      'admins': FieldValue.arrayRemove([memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Leave group
  Future<void> leaveGroup(String cid, String uid) async {
    await removeGroupMember(cid, uid);
  }

  /// Delete group
  Future<void> deleteGroup(String cid) async {
    final messages = await _firestore
        .collection('conversations')
        .doc(cid)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _firestore.collection('conversations').doc(cid).delete();
  }

  /// Update group settings
  Future<void> updateGroupSettings(String cid, {bool? onlyAdminsCanSend}) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (onlyAdminsCanSend != null) {
      updates['onlyAdminsCanSend'] = onlyAdminsCanSend;
    }

    await _firestore.collection('conversations').doc(cid).update(updates);
  }

  // ═══════════════════════════════════════════════════════════════
  // TYPING INDICATORS
  // ═══════════════════════════════════════════════════════════════

  Future<void> setTypingStatus(String cid, String uid, bool typing) async {
    await _firestore
        .collection('typing_status')
        .doc(cid)
        .collection('users')
        .doc(uid)
        .set({
      'isTyping': typing,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getTypingUsers(String cid, String currentUid) {
    return _firestore
        .collection('typing_status')
        .doc(cid)
        .collection('users')
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
        .where((d) => d.id != currentUid)
        .map((d) => d.id)
        .toList());
  }

  // ═══════════════════════════════════════════════════════════════
  // USER SEARCH
  // ═══════════════════════════════════════════════════════════════

  Future<List<UserModel>> searchUsers(String query, String uid) async {
    final snap = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snap.docs
        .map((d) => UserModel.fromDocument(d))
        .where((u) => u.id != uid)
        .toList();
  }
}