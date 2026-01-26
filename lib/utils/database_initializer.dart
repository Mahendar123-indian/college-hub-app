import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/seeders/college_seeder.dart';
import '../data/seeders/department_seeder.dart';
import '../data/seeders/resource_seeder.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Main entry point for app startup.
  Future<void> initialize() async {
    try {
      debugPrint('🔵 [DB Init] Checking initialization status...');

      final collegesSnapshot = await _firestore
          .collection('colleges')
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Firestore connection timed out.'),
      );

      if (collegesSnapshot.docs.isEmpty) {
        debugPrint('⚠️ [DB Init] Database empty. Checking auth...');
        final user = _auth.currentUser;
        if (user != null) {
          await _seedData();
        }
      } else {
        debugPrint('✅ [DB Init] Database ready (Data detected).');
      }
    } catch (e) {
      debugPrint('❌ [DB Init] Error: $e');
    }
  }

  /// Sequential seeding logic
  Future<void> _seedData() async {
    try {
      debugPrint('🌱 [Seeder] Sequence started...');

      await CollegeSeeder.seedColleges();
      debugPrint('✅ [Seeder] Colleges synced.');

      await DepartmentSeeder.seedDepartments();
      debugPrint('✅ [Seeder] Departments synced.');

      await ResourceSeeder.seedResources();
      debugPrint('✅ [Seeder] Resources synced.');

      debugPrint('🏁 [Seeder] Full database synchronization complete.');
    } catch (e) {
      _handleFirebaseError(e, 'Seeding');
    }
  }

  /// 🛡️ SECURE: Force reseed with Admin verification
  Future<bool> forceReseed() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      debugPrint('🚀 [Force Reseed] Initiated by: ${user.email}');

      final adminDoc = await _firestore.collection('users').doc(user.uid).get();
      final isAdmin = adminDoc.data()?['role'] == 'admin' || (adminDoc.data()?['isAdmin'] ?? false);

      if (!isAdmin && !kDebugMode) {
        debugPrint('🚫 [Security] Access Denied.');
        return false;
      }

      await _deleteCollectionInBatches('colleges');
      await _deleteCollectionInBatches('departments');
      await _deleteCollectionInBatches('resources');

      await _seedData();
      return true;
    } catch (e) {
      debugPrint('❌ [Force Reseed] Failed: $e');
      return false;
    }
  }

  /// 📦 SCALABLE: Batch deletion to avoid operation limits
  Future<void> _deleteCollectionInBatches(String collectionName) async {
    final collection = _firestore.collection(collectionName);
    final snapshot = await collection.get();

    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;

      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) await batch.commit();
    debugPrint('🗑️ Cleared: $collectionName');
  }

  /// ✅ FIXED: Missing getStats method for EnhancedSearchScreen
  Future<Map<String, int>> getStats() async {
    try {
      // Use parallel execution for high performance
      final results = await Future.wait([
        _firestore.collection('colleges').get(),
        _firestore.collection('departments').get(),
        _firestore.collection('resources').get(),
      ]);

      return {
        'colleges': results[0].docs.length,
        'departments': results[1].docs.length,
        'resources': results[2].docs.length,
      };
    } catch (e) {
      debugPrint('❌ [Stats] Error: $e');
      return {'colleges': 0, 'departments': 0, 'resources': 0};
    }
  }

  void _handleFirebaseError(Object e, String context) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      debugPrint('🚨 [Security] Permission Denied in $context.');
    }
    debugPrint('❌ [$context Error]: $e');
  }
}