import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  // BASIC CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [UserRepository] getUserById Error: $e');
      rethrow;
    }
  }

  /// Create new user with Merge options for safety
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ [UserRepository] createUser Error: $e');
      rethrow;
    }
  }

  /// ✅ FIXED: Update user profile data
  /// This method is required by AuthProvider.updateUserProfile
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      debugPrint('❌ [UserRepository] updateUser Error: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('❌ [UserRepository] deleteUser Error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMIN & FILTER OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get all users (Admin only) - Scalable version with limit
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      debugPrint('❌ [UserRepository] getAllUsers Error: $e');
      rethrow;
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: role)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search users by name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update user status (Active/Inactive)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SCALABLE STATISTICS (Aggregation Queries)
  // ═══════════════════════════════════════════════════════════════

  /// ✅ HIGH PERFORMANCE: Count Aggregation
  /// Efficiently returns counts without downloading full documents.
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final collection = _firestore.collection(AppConstants.usersCollection);

      // Perform counts in parallel for optimized performance
      final results = await Future.wait([
        collection.count().get(),
        collection.where('isActive', isEqualTo: true).count().get(),
        collection.where('role', isEqualTo: 'student').count().get(),
        collection.where('role', isEqualTo: 'admin').count().get(),
      ]);

      return {
        'totalUsers': results[0].count ?? 0,
        'activeUsers': results[1].count ?? 0,
        'students': results[2].count ?? 0,
        'admins': results[3].count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ [UserRepository] Statistics Error: $e');
      return {'totalUsers': 0, 'activeUsers': 0, 'students': 0, 'admins': 0};
    }
  }
}