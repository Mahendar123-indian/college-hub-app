import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/friend_request_model.dart';

class FriendRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FriendRequest> _receivedRequests = [];
  List<FriendRequest> _sentRequests = [];
  Map<String, String> _friendshipStatus = {}; // userId -> status
  bool _isLoading = false;

  List<FriendRequest> get receivedRequests => _receivedRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;

  int get pendingRequestCount =>
      _receivedRequests.where((r) => r.status == RequestStatus.pending).length;

  // Get friendship status with a user
  String getFriendshipStatus(String userId) {
    return _friendshipStatus[userId] ?? 'none';
  }

  // Check if users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        if ((data['senderId'] == userId1 && data['receiverId'] == userId2) ||
            (data['senderId'] == userId2 && data['receiverId'] == userId1)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking friendship: $e');
      return false;
    }
  }

  // Load friendship status for a specific user
  Future<void> loadFriendshipStatus(String currentUserId, String otherUserId) async {
    try {
      // Check sent request
      final sentQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .limit(1)
          .get();

      if (sentQuery.docs.isNotEmpty) {
        final status = sentQuery.docs.first.data()['status'];
        _friendshipStatus[otherUserId] = 'sent_$status';
        notifyListeners();
        return;
      }

      // Check received request
      final receivedQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (receivedQuery.docs.isNotEmpty) {
        final status = receivedQuery.docs.first.data()['status'];
        _friendshipStatus[otherUserId] = 'received_$status';
        notifyListeners();
        return;
      }

      _friendshipStatus[otherUserId] = 'none';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading friendship status: $e');
    }
  }

  // Load all received requests
  void loadReceivedRequests(String userId) {
    _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _receivedRequests = snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  // Load all sent requests
  void loadSentRequests(String userId) {
    _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _sentRequests = snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
      notifyListeners();
    });
  }

  // Send friend request
  Future<bool> sendFriendRequest({
    required String currentUserId,
    required String currentUserName,
    String? currentUserPhoto,
    required String currentUserEmail,
    String? currentUserCollege,
    String? currentUserDepartment,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if request already exists
      final existing = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      if (existing.docs.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new request
      final request = FriendRequest(
        id: '',
        senderId: currentUserId,
        senderName: currentUserName,
        senderPhoto: currentUserPhoto,
        senderEmail: currentUserEmail,
        senderCollege: currentUserCollege,
        senderDepartment: currentUserDepartment,
        receiverId: otherUserId,
        receiverName: otherUserName,
        receiverPhoto: otherUserPhoto,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('friendRequests').add(request.toMap());

      _friendshipStatus[otherUserId] = 'sent_pending';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Accept friend request
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
        'respondedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  // Reject friend request
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  // Cancel sent request
  Future<bool> cancelRequest(String otherUserId, String currentUserId) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      _friendshipStatus[otherUserId] = 'none';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error canceling request: $e');
      return false;
    }
  }

  // Unfriend user
  Future<bool> unfriend(String userId1, String userId2) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        if ((data['senderId'] == userId1 && data['receiverId'] == userId2) ||
            (data['senderId'] == userId2 && data['receiverId'] == userId1)) {
          await doc.reference.delete();
        }
      }

      _friendshipStatus[userId2] = 'none';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unfriending: $e');
      return false;
    }
  }

  // Get all friends
  Future<List<String>> getFriendIds(String userId) async {
    try {
      final query = await _firestore
          .collection('friendRequests')
          .where('status', isEqualTo: 'accepted')
          .get();

      List<String> friendIds = [];
      for (var doc in query.docs) {
        final data = doc.data();
        if (data['senderId'] == userId) {
          friendIds.add(data['receiverId']);
        } else if (data['receiverId'] == userId) {
          friendIds.add(data['senderId']);
        }
      }
      return friendIds;
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }
}