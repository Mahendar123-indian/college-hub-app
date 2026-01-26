import 'package:cloud_firestore/cloud_firestore.dart';
import 'college_seeder.dart';

class DepartmentSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. SPECIAL DEPARTMENTS FOR VJIT ---
  // Matches your VJIT-specific branch requirements precisely
  static final List<Map<String, String>> _vjitDepartments = [
    {'name': 'Computer Science Engineering', 'code': 'CSE'},
    {'name': 'CSE - Artificial Intelligence & Machine Learning', 'code': 'CSE (AI-ML)'},
    {'name': 'CSE - Artificial Intelligence & Data Science', 'code': 'CSE (AI-DS)'},
    {'name': 'CSE - Data Science', 'code': 'CSE (DS)'},
    {'name': 'Artificial Intelligence', 'code': 'AI'},
    {'name': 'Information Technology', 'code': 'IT'},
    {'name': 'Electronics & Communication Engineering', 'code': 'ECE'},
    {'name': 'Electrical & Electronics Engineering', 'code': 'EEE'},
    {'name': 'Mechanical Engineering', 'code': 'Mechanical'},
    {'name': 'Civil Engineering', 'code': 'Civil'},
  ];

  // --- 2. STANDARD DEPARTMENTS FOR OTHER COLLEGES ---
  static final List<Map<String, String>> _standardDepartments = [
    {'name': 'Computer Science Engineering', 'code': 'CSE'},
    {'name': 'Information Technology', 'code': 'IT'},
    {'name': 'Electronics & Communication Engineering', 'code': 'ECE'},
    {'name': 'Electrical & Electronics Engineering', 'code': 'EEE'},
    {'name': 'Mechanical Engineering', 'code': 'ME'},
    {'name': 'Civil Engineering', 'code': 'CE'},
    {'name': 'Artificial Intelligence & Machine Learning', 'code': 'AI&ML'},
    {'name': 'Data Science', 'code': 'DS'},
  ];

  static Future<void> seedDepartments() async {
    // Fetches the master college list from your CollegeSeeder
    final colleges = CollegeSeeder.telanganaColleges;

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    print("🚀 Starting robust department seeding...");

    try {
      for (var college in colleges) {
        final collegeId = college['id'] as String;

        // DYNAMIC LOGIC: Custom branches for VJIT, standard for others
        final List<Map<String, String>> deptsToSeed = (collegeId == 'ts_clg_vjit')
            ? _vjitDepartments
            : _standardDepartments;

        for (var dept in deptsToSeed) {
          final String code = dept['code'] ?? 'GENERIC';
          final String name = dept['name'] ?? 'General Department';

          // Clean the ID by removing special characters to ensure document safety
          final cleanCode = code.replaceAll(RegExp(r'[\s\(\)\-]'), "");
          final deptId = '${collegeId}_$cleanCode';

          final docRef = _firestore.collection('departments').doc(deptId);

          batch.set(docRef, {
            'id': deptId,
            'collegeId': collegeId,
            'name': name,
            'code': code,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Uses merge to update without deleting

          batchCount++;

          // SAFETY: Batch reset at 450 to stay under Firestore's 500 limit
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
            print("📦 Batch committed to Firestore...");
          }
        }
      }

      // Final commit for remaining items
      if (batchCount > 0) {
        await batch.commit();
      }

      print('✅ Successfully seeded departments for all colleges (Including VJIT Specials)');
    } catch (e) {
      print('❌ Error during department seeding: $e');
      rethrow;
    }
  }
}