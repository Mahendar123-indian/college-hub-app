import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final double rating;
  final String reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String appVersion;
  final String? deviceInfo;
  final bool isActive;
  final String? adminReply;
  final DateTime? adminRepliedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    required this.appVersion,
    this.deviceInfo,
    this.isActive = true,
    this.adminReply,
    this.adminRepliedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'reviewText': reviewText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'isActive': isActive,
      'adminReply': adminReply,
      'adminRepliedAt': adminRepliedAt != null ? Timestamp.fromDate(adminRepliedAt!) : null,
    };
  }

  // Create from Firestore document
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewText: map['reviewText'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      appVersion: map['appVersion'] ?? '1.0.0',
      deviceInfo: map['deviceInfo'],
      isActive: map['isActive'] ?? true,
      adminReply: map['adminReply'],
      adminRepliedAt: map['adminRepliedAt'] != null
          ? (map['adminRepliedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory ReviewModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel.fromMap(data);
  }

  // Copy with method for updates
  ReviewModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    double? rating,
    String? reviewText,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? appVersion,
    String? deviceInfo,
    bool? isActive,
    String? adminReply,
    DateTime? adminRepliedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
      adminReply: adminReply ?? this.adminReply,
      adminRepliedAt: adminRepliedAt ?? this.adminRepliedAt,
    );
  }
}