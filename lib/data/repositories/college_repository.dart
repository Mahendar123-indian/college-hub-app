import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/college_model.dart';
import '../models/department_model.dart';

class CollegeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collegesCollection = 'colleges';
  static const String _departmentsCollection = 'departments';

  // 🛡️ Robust: Uses the model's map logic with safety merge
  Future<void> createCollege(CollegeModel college) async {
    try {
      await _firestore
          .collection(_collegesCollection)
          .doc(college.id)
          .set(college.toMap(), SetOptions(merge: true));
    } catch (e) {
      _handleError(e, 'createCollege');
      rethrow;
    }
  }

  // 📦 Scalable: Handles batch operations with safety merge
  Future<void> batchCreateColleges(List<CollegeModel> colleges) async {
    try {
      final batch = _firestore.batch();
      for (var college in colleges) {
        final docRef = _firestore.collection(_collegesCollection).doc(college.id);
        batch.set(docRef, college.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      _handleError(e, 'batchCreateColleges');
      rethrow;
    }
  }

  // 🚀 Robust Fetch: Fetches active colleges and sorts in-memory to avoid Index errors
  Future<List<CollegeModel>> getAllColleges() async {
    try {
      final snapshot = await _firestore
          .collection(_collegesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final colleges = snapshot.docs
          .map((doc) => CollegeModel.fromDocument(doc))
          .toList();

      // Sort in memory to prevent "Missing Index" crash in Firestore
      colleges.sort((a, b) => a.name.compareTo(b.name));
      return colleges;
    } catch (e) {
      _handleError(e, 'getAllColleges');
      rethrow;
    }
  }

  // 🔍 Highly Dynamic Search: Searches Name, Location, and ID
  Future<List<CollegeModel>> searchColleges(String query) async {
    try {
      if (query.isEmpty) return [];
      final lowercaseQuery = query.toLowerCase();

      final snapshot = await _firestore
          .collection(_collegesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => CollegeModel.fromDocument(doc))
          .where((college) {
        final name = college.name.toLowerCase();
        final location = college.location?.toLowerCase() ?? '';
        final code = college.id.toLowerCase();
        return name.contains(lowercaseQuery) ||
            location.contains(lowercaseQuery) ||
            code.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      _handleError(e, 'searchColleges');
      rethrow;
    }
  }

  // 🎓 Robust Departments: Correctly fetches specialized branches (like VJIT AI-ML)
  Future<List<DepartmentModel>> getDepartmentsByCollege(String collegeId) async {
    try {
      final snapshot = await _firestore
          .collection(_departmentsCollection)
          .where('collegeId', isEqualTo: collegeId)
          .where('isActive', isEqualTo: true)
          .get();

      final departments = snapshot.docs
          .map((doc) => DepartmentModel.fromDocument(doc))
          .toList();

      departments.sort((a, b) => a.name.compareTo(b.name));
      return departments;
    } catch (e) {
      _handleError(e, 'getDepartmentsByCollege');
      rethrow;
    }
  }

  // ✅ FIXED: Missing Method added for CollegeProvider
  Future<DepartmentModel?> getDepartmentById(String departmentId) async {
    try {
      final doc = await _firestore
          .collection(_departmentsCollection)
          .doc(departmentId)
          .get();

      if (doc.exists) {
        return DepartmentModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      _handleError(e, 'getDepartmentById');
      rethrow;
    }
  }

  // 📊 Dynamic Stats: Parallel execution for faster response
  Future<Map<String, dynamic>> getCollegeStatistics() async {
    try {
      final results = await Future.wait([
        _firestore.collection(_collegesCollection).where('isActive', isEqualTo: true).get(),
        _firestore.collection(_departmentsCollection).where('isActive', isEqualTo: true).get(),
      ]);

      return {
        'totalColleges': results[0].docs.length,
        'totalDepartments': results[1].docs.length,
      };
    } catch (e) {
      _handleError(e, 'getCollegeStatistics');
      return {'totalColleges': 0, 'totalDepartments': 0};
    }
  }

  // Common Error Handler
  void _handleError(dynamic e, String method) {
    if (e.toString().contains('permission-denied')) {
      debugPrint('🚨 [Security] Permission denied in $method. Check Rules.');
    } else {
      debugPrint('❌ [Repository Error] $method: $e');
    }
  }

  // Get college by ID
  Future<CollegeModel?> getCollegeById(String collegeId) async {
    try {
      final doc = await _firestore.collection(_collegesCollection).doc(collegeId).get();
      return doc.exists ? CollegeModel.fromDocument(doc) : null;
    } catch (e) { rethrow; }
  }

  // Update college with Timestamp
  Future<void> updateCollege(CollegeModel college) async {
    try {
      await _firestore
          .collection(_collegesCollection)
          .doc(college.id)
          .update(college.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) { rethrow; }
  }
}