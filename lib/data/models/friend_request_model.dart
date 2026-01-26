import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String senderEmail;
  final String? senderCollege;
  final String? senderDepartment;
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.senderEmail,
    this.senderCollege,
    this.senderDepartment,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'senderEmail': senderEmail,
      'senderCollege': senderCollege,
      'senderDepartment': senderDepartment,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhoto': receiverPhoto,
      'status': status.name,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  // Create from Firestore
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhoto: data['senderPhoto'],
      senderEmail: data['senderEmail'] ?? '',
      senderCollege: data['senderCollege'],
      senderDepartment: data['senderDepartment'],
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverPhoto: data['receiverPhoto'],
      status: RequestStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  FriendRequest copyWith({
    RequestStatus? status,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      senderEmail: senderEmail,
      senderCollege: senderCollege,
      senderDepartment: senderDepartment,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhoto: receiverPhoto,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}