import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../../core/constants/app_constants.dart';
import '../services/firebase_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Create a new review
  Future<void> createReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(review.id)
          .set(review.toMap());

      if (kDebugMode) {
        print('✅ Review created successfully: ${review.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create review: $e');
      }
      rethrow;
    }
  }

  // Get all reviews (real-time stream)
  Stream<List<ReviewModel>> getAllReviewsStream() {
    try {
      return _firestore
          .collection(AppConstants.reviewsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReviewModel.fromDocument(doc);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get reviews stream: $e');
      }
      rethrow;
    }
  }

  // Get reviews by user ID
  Stream<List<ReviewModel>> getUserReviewsStream(String userId) {
    try {
      return _firestore
          .collection(AppConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReviewModel.fromDocument(doc);
        }).toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user reviews stream: $e');
      }
      rethrow;
    }
  }

  // Get review statistics
  Future<Map<String, dynamic>> getReviewStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      int totalReviews = snapshot.docs.length;
      double totalRating = 0.0;
      Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var doc in snapshot.docs) {
        final review = ReviewModel.fromDocument(doc);
        totalRating += review.rating;
        int ratingKey = review.rating.round();
        ratingDistribution[ratingKey] = (ratingDistribution[ratingKey] ?? 0) + 1;
      }

      double averageRating = totalRating / totalReviews;

      return {
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get review statistics: $e');
      }
      rethrow;
    }
  }

  // Update review
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(review.id)
          .update(review.toMap());

      if (kDebugMode) {
        print('✅ Review updated successfully: ${review.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update review: $e');
      }
      rethrow;
    }
  }

  // Delete review (soft delete)
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(reviewId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('✅ Review deleted successfully: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete review: $e');
      }
      rethrow;
    }
  }

  // Add admin reply to review
  Future<void> addAdminReply(String reviewId, String reply) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(reviewId)
          .update({
        'adminReply': reply,
        'adminRepliedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        print('✅ Admin reply added successfully: $reviewId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add admin reply: $e');
      }
      rethrow;
    }
  }

  // Check if user has already reviewed
  Future<bool> hasUserReviewed(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to check user review: $e');
      }
      return false;
    }
  }

  // Get user's existing review
  Future<ReviewModel?> getUserReview(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ReviewModel.fromDocument(snapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user review: $e');
      }
      return null;
    }
  }
}